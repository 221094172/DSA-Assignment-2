// database.bal
import ballerina/log;
import ballerina/time;
import ballerinax/mongodb;

// MongoDB configuration
configurable string mongoHost = "mongodb";
configurable int mongoPort = 27017;
configurable string mongoDatabase = "transport_ticketing_system";

// MongoDB client
final mongodb:Client mongoClient = check initializeMongoDB();

function initializeMongoDB() returns mongodb:Client|error {
    mongodb:Client mongoDb = check new ({
        connection: {
            serverAddress: {
                host: mongoHost,
                port: mongoPort
            }
        }
    });
    
    log:printInfo("Connected to MongoDB successfully");
    return mongoDb;
}

// Save notification to database
public function saveNotification(Notification notification) returns error? {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection notificationsCollection = check db->getCollection("notifications");
    
    check notificationsCollection->insertOne(notification);
    log:printInfo(string `Notification saved: ${notification.notificationId} - ${notification.'type}`);
}

// Update notification status
public function updateNotificationStatus(string notificationId, string status, 
                                        time:Civil? sentAt = (), 
                                        time:Civil? readAt = ()) returns error? {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection notificationsCollection = check db->getCollection("notifications");
    
    map<json> filter = {
        "notificationId": notificationId
    };
    
    map<json> updateData = {
        "status": status
    };
    
    if sentAt is time:Civil {
        string|time:Error sentAtStr = time:civilToString(sentAt);
        if sentAtStr is string {
            updateData["sentAt"] = sentAtStr;
        }
    }
    
    if readAt is time:Civil {
        string|time:Error readAtStr = time:civilToString(readAt);
        if readAtStr is string {
            updateData["readAt"] = readAtStr;
        }
    }
    
    mongodb:Update update = {
        set: updateData
    };
    
    mongodb:UpdateResult updateResult = check notificationsCollection->updateOne(filter, update);
    
    if updateResult.modifiedCount > 0 {
        log:printInfo(string `Notification ${notificationId} updated to ${status}`);
    }
}

// Get notifications by passenger
public function getNotificationsByPassenger(string passengerId, int 'limit = 50) returns Notification[]|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection notificationsCollection = check db->getCollection("notifications");
    
    map<json> filter = {
        "passengerId": passengerId
    };
    
    map<json> sort = {
        "createdAt": -1
    };
    
    stream<Notification, error?> notificationStream = check notificationsCollection->find(
        filter, 
        {sort: sort, 'limit: 'limit}
    );
    
    Notification[] notifications = check from Notification notification in notificationStream
                                         select notification;
    
    return notifications;
}

// Get unread notifications
public function getUnreadNotifications(string passengerId) returns Notification[]|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection notificationsCollection = check db->getCollection("notifications");
    
    map<json> filter = {
        "passengerId": passengerId,
        "status": {"$in": ["pending", "sent"]}
    };
    
    map<json> sort = {
        "createdAt": -1
    };
    
    stream<Notification, error?> notificationStream = check notificationsCollection->find(
        filter,
        {sort: sort}
    );
    
    Notification[] notifications = check from Notification notification in notificationStream
                                         select notification;
    
    return notifications;
}

// Mark notification as read
public function markAsRead(string notificationId) returns error? {
    check updateNotificationStatus(notificationId, "read", readAt = time:utcToCivil(time:utcNow()));
}

// Get passenger email (from passengers collection)
public function getPassengerEmail(string passengerId) returns string|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection passengersCollection = check db->getCollection("passengers");
    
    map<json> filter = {
        "passengerId": passengerId
    };
    
    map<json>? passenger = check passengersCollection->findOne(filter);
    
    if passenger is () {
        return error(string `Passenger not found: ${passengerId}`);
    }
    
    return passenger.get("email").toString();
}

// Get notification statistics
public function getNotificationStatistics() returns NotificationStats|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection notificationsCollection = check db->getCollection("notifications");
    
    // Get all notifications
    stream<Notification, error?> allNotifications = check notificationsCollection->find({});
    Notification[] notifications = check from Notification notification in allNotifications
                                         select notification;
    
    int totalNotifications = notifications.length();
    int sentNotifications = 0;
    int pendingNotifications = 0;
    int failedNotifications = 0;
    int readNotifications = 0;
    
    map<int> notificationsByType = {};
    map<int> notificationsByChannel = {};
    
    foreach Notification notification in notifications {
        // Count by status
        if notification.status == "sent" {
            sentNotifications += 1;
        } else if notification.status == "pending" {
            pendingNotifications += 1;
        } else if notification.status == "failed" {
            failedNotifications += 1;
        } else if notification.status == "read" {
            readNotifications += 1;
        }
        
        // Count by type
        string notifType = notification.'type;
        if notificationsByType.hasKey(notifType) {
            notificationsByType[notifType] = <int>notificationsByType.get(notifType) + 1;
        } else {
            notificationsByType[notifType] = 1;
        }
        
        // Count by channel
        string channel = notification.channel;
        if notificationsByChannel.hasKey(channel) {
            notificationsByChannel[channel] = <int>notificationsByChannel.get(channel) + 1;
        } else {
            notificationsByChannel[channel] = 1;
        }
    }
    
    return {
        totalNotifications,
        sentNotifications,
        pendingNotifications,
        failedNotifications,
        readNotifications,
        notificationsByType,
        notificationsByChannel
    };
}