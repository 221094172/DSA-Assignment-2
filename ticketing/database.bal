// database.bal
import ballerina/log;
import ballerinax/mongodb;
import ballerina/time;

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
    
    log:printInfo("✅ Ticketing Service - Connected to MongoDB successfully");
    return mongoDb;
}

// Save ticket to database
public function saveTicket(Ticket ticket) returns error? {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection ticketsCollection = check db->getCollection("tickets");
    
    check ticketsCollection->insertOne(ticket);
    log:printInfo(string `💾 Ticket saved: ${ticket.ticketId} - ${ticket.status}`);
}

// Update ticket status
public function updateTicketStatus(string ticketId, string status, 
                                   string? paymentId = null,
                                   string? transactionReference = null) returns error? {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection ticketsCollection = check db->getCollection("tickets");
    
    map<json> filter = {
        "ticketId": ticketId
    };
    
    time:Civil now = time:utcToCivil(time:utcNow());
    
    map<json> updateData = {
        "status": status,
        "updatedAt": now.toJson()
    };
    
    if paymentId is string {
        updateData["paymentId"] = paymentId;
    }
    
    if transactionReference is string {
        updateData["transactionReference"] = transactionReference;
    }
    
    mongodb:Update update = {
        set: updateData
    };
    
    mongodb:UpdateResult result = check ticketsCollection->updateOne(filter, update);
    
    if result.modifiedCount > 0 {
        log:printInfo(string `✅ Ticket ${ticketId} updated to ${status}`);
    }
}

// Validate ticket
public function validateTicket(string ticketId, string validatorId) returns error? {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection ticketsCollection = check db->getCollection("tickets");
    
    map<json> filter = {
        "ticketId": ticketId
    };
    
    time:Civil now = time:utcToCivil(time:utcNow());
    
    mongodb:Update update = {
        set: {
            "status": "VALIDATED",
            "validatedAt": now.toJson(),
            "validatedBy": validatorId,
            "updatedAt": now.toJson()
        }
    };
    
    mongodb:UpdateResult result = check ticketsCollection->updateOne(filter, update);
    
    if result.modifiedCount > 0 {
        log:printInfo(string `✅ Ticket ${ticketId} validated by ${validatorId}`);
    } else {
        return error("Ticket not found or already validated");
    }
}

// Get ticket by ID
public function getTicketById(string ticketId) returns Ticket|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection ticketsCollection = check db->getCollection("tickets");
    
    map<json> filter = {
        "ticketId": ticketId
    };
    
    Ticket? ticket = check ticketsCollection->findOne(filter);
    
    if ticket is () {
        return error(string `Ticket not found: ${ticketId}`);
    }
    
    return ticket;
}

// Get ticket by QR code
public function getTicketByQRCode(string qrCode) returns Ticket|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection ticketsCollection = check db->getCollection("tickets");
    
    map<json> filter = {
        "qrCode": qrCode
    };
    
    Ticket? ticket = check ticketsCollection->findOne(filter);
    
    if ticket is () {
        return error(string `Ticket not found with QR code: ${qrCode}`);
    }
    
    return ticket;
}

// Get tickets by passenger
public function getTicketsByPassenger(string passengerId, string? status = null) returns Ticket[]|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection ticketsCollection = check db->getCollection("tickets");
    
    map<json> filter = {
        "passengerId": passengerId
    };
    
    if status is string {
        filter["status"] = status;
    }
    
    map<json> sort = {
        "createdAt": -1
    };
    
    stream<Ticket, error?> ticketStream = check ticketsCollection->find(filter, {sort: sort});
    
    Ticket[] tickets = check from Ticket ticket in ticketStream
                             select ticket;
    
    return tickets;
}

// Get tickets by trip
public function getTicketsByTrip(string tripId) returns Ticket[]|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection ticketsCollection = check db->getCollection("tickets");
    
    map<json> filter = {
        "tripId": tripId
    };
    
    stream<Ticket, error?> ticketStream = check ticketsCollection->find(filter);
    
    Ticket[] tickets = check from Ticket ticket in ticketStream
                             select ticket;
    
    return tickets;
}

// Get ticket statistics
public function getTicketStatistics() returns TicketStats|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection ticketsCollection = check db->getCollection("tickets");
    
    stream<Ticket, error?> allTickets = check ticketsCollection->find({});
    Ticket[] tickets = check from Ticket ticket in allTickets
                             select ticket;
    
    int totalTickets = tickets.length();
    int createdTickets = 0;
    int paidTickets = 0;
    int validatedTickets = 0;
    int expiredTickets = 0;
    int cancelledTickets = 0;
    decimal totalRevenue = 0.0;
    
    map<int> ticketsByType = {};
    map<int> ticketsByRoute = {};
    
    foreach Ticket ticket in tickets {
        // Count by status
        match ticket.status {
            "CREATED" => {
                createdTickets += 1;
            }
            "PAID" => {
                paidTickets += 1;
                totalRevenue += ticket.price;
            }
            "VALIDATED" => {
                validatedTickets += 1;
                totalRevenue += ticket.price;
            }
            "EXPIRED" => {
                expiredTickets += 1;
            }
            "CANCELLED" => {
                cancelledTickets += 1;
            }
        }
        
        // Count by type
        string ticketType = ticket.ticketType;
        if ticketsByType.hasKey(ticketType) {
            ticketsByType[ticketType] = <int>ticketsByType.get(ticketType) + 1;
        } else {
            ticketsByType[ticketType] = 1;
        }
        
        // Count by route
        string routeNumber = ticket.routeNumber;
        if ticketsByRoute.hasKey(routeNumber) {
            ticketsByRoute[routeNumber] = <int>ticketsByRoute.get(routeNumber) + 1;
        } else {
            ticketsByRoute[routeNumber] = 1;
        }
    }
    
    return {
        totalTickets,
        createdTickets,
        paidTickets,
        validatedTickets,
        expiredTickets,
        cancelledTickets,
        totalRevenue,
        ticketsByType,
        ticketsByRoute
    };
}

// Cancel ticket
public function cancelTicket(string ticketId) returns error? {
    return updateTicketStatus(ticketId, "CANCELLED");
}

// Expire old tickets
public function expireOldTickets() returns int|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection ticketsCollection = check db->getCollection("tickets");
    
    time:Civil now = time:utcToCivil(time:utcNow());
    
    map<json> filter = {
        "status": {"$in": ["CREATED", "PAID"]},
        "validUntil": {"$lt": now.toJson()}
    };
    
    mongodb:Update update = {
        set: {
            "status": "EXPIRED",
            "updatedAt": now.toJson()
        }
    };
    
    mongodb:UpdateResult result = check ticketsCollection->updateMany(filter, update);
    
    int expiredCount = <int>result.modifiedCount;
    if expiredCount > 0 {
        log:printInfo(string `⏰ Expired ${expiredCount} old tickets`);
    }
    
    return expiredCount;
}