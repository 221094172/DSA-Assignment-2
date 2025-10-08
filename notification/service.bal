// models.bal
import ballerina/time;

// Notification model
public type Notification record {|
    string notificationId;
    string passengerId;
    string 'type; // schedule_update, ticket_validated, payment_success, payment_failed, ticket_created
    string channel; // email, sms, push, console
    string subject;
    string message;
    string status; // pending, sent, failed, read
    json? metadata?;
    time:Civil createdAt;
    time:Civil? sentAt?;
    time:Civil? readAt?;
|};

// Schedule update event
public type ScheduleUpdateEvent record {|
    string tripId;
    string routeId;
    string routeNumber?;
    string routeName?;
    string status; // delayed, cancelled, on_time
    string? delayReason?;
    int? delayMinutes?;
    string? cancellationReason?;
    time:Civil scheduledDeparture;
    time:Civil? newDeparture?;
    time:Civil timestamp;
|};

// Ticket validated event
public type TicketValidatedEvent record {|
    string validationId;
    string ticketId;
    string passengerId;
    string tripId;
    string routeId?;
    string routeName?;
    string validationResult; // success, failed
    string? failureReason?;
    time:Civil validatedAt;
|};

// Payment processed event
public type PaymentProcessedEvent record {|
    string paymentId;
    string ticketId;
    string passengerId;
    decimal amount;
    string status; // success, failed
    string? transactionReference?;
    string? failureReason?;
    time:Civil processedAt;
|};

// Ticket created event
public type TicketCreatedEvent record {|
    string ticketId;
    string passengerId;
    string? tripId?;
    string ticketType;
    decimal price;
    time:Civil validFrom;
    time:Civil validUntil;
    time:Civil createdAt;
|};

// Notification statistics
public type NotificationStats record {|
    int totalNotifications;
    int sentNotifications;
    int pendingNotifications;
    int failedNotifications;
    int readNotifications;
    map<int> notificationsByType;
    map<int> notificationsByChannel;
|};