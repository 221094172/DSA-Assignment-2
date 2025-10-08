// notification_handler.bal
import ballerina/log;
import ballerina/uuid;
import ballerina/time;
import ballerina/io;
import ballerinax/mongodb;

// Notification configuration
configurable boolean enableConsoleOutput = true;
configurable boolean enableEmailSimulation = true;
configurable boolean enableSmsSimulation = true;

// Handle schedule update notification
public function handleScheduleUpdate(ScheduleUpdateEvent event) returns error? {
    log:printInfo(string `Processing schedule update: ${event.tripId} - ${event.status}`);
    
    // Get affected passengers (those with tickets for this trip)
    string[] passengerIds = check getPassengersForTrip(event.tripId);
    
    foreach string passengerId in passengerIds {
        // Create notification message
        string subject = "";
        string message = "";
        
        if event.status == "delayed" {
            subject = string `Trip Delayed - ${event?.routeName ?: event?.routeNumber ?: "Your Route"}`;
            message = string `Your trip on ${event?.routeName ?: event?.routeNumber ?: "route"} has been delayed by ${event?.delayMinutes ?: 0} minutes.`;
            
            string? delayReason = event?.delayReason;
            if delayReason is string {
                message += string ` Reason: ${delayReason}`;
            }
            
            time:Civil? newDeparture = event?.newDeparture;
            if newDeparture is time:Civil {
                string|time:Error newDepartureStr = time:civilToString(newDeparture);
                if newDepartureStr is string {
                    message += string ` New departure time: ${newDepartureStr}`;
                }
            }
        } else if event.status == "cancelled" {
            subject = string `Trip Cancelled - ${event?.routeName ?: event?.routeNumber ?: "Your Route"}`;
            message = string `Your trip on ${event?.routeName ?: event?.routeNumber ?: "route"} has been cancelled.`;
            
            string? cancellationReason = event?.cancellationReason;
            if cancellationReason is string {
                message += string ` Reason: ${cancellationReason}`;
            }
            
            message += " Please contact customer service for a refund or rebooking.";
        } else {
            subject = string `Trip Update - ${event?.routeName ?: event?.routeNumber ?: "Your Route"}`;
            message = string `Your trip on ${event?.routeName ?: event?.routeNumber ?: "route"} is now on time.`;
        }
        
        // Send notification
        string|time:Error scheduledDepartureStr = time:civilToString(event.scheduledDeparture);
        json metadata = scheduledDepartureStr is string ? {
            "tripId": event.tripId,
            "routeId": event.routeId,
            "status": event.status,
            "delayMinutes": event?.delayMinutes,
            "scheduledDeparture": scheduledDepartureStr
        } : {
            "tripId": event.tripId,
            "routeId": event.routeId,
            "status": event.status,
            "delayMinutes": event?.delayMinutes
        };
        
        check sendNotification(
            passengerId,
            "schedule_update",
            subject,
            message,
            metadata
        );
    }
}

// Handle ticket validated notification
public function handleTicketValidated(TicketValidatedEvent event) returns error? {
    log:printInfo(string `Processing ticket validation: ${event.ticketId} - ${event.validationResult}`);
    
    string subject = "";
    string message = "";
    
    if event.validationResult == "success" {
        subject = "Ticket Validated Successfully";
        string|time:Error validatedAtStr = time:civilToString(event.validatedAt);
        if validatedAtStr is string {
            message = string `Your ticket has been validated for ${event?.routeName ?: "your trip"} at ${validatedAtStr}.`;
        } else {
            message = string `Your ticket has been validated for ${event?.routeName ?: "your trip"}.`;
        }
        message += " Have a pleasant journey!";
    } else {
        subject = "Ticket Validation Failed";
        message = string `Ticket validation failed for ${event?.routeName ?: "your trip"}.`;
        
        string? failureReason = event?.failureReason;
        if failureReason is string {
            message += string ` Reason: ${failureReason}`;
        }
        
        message += " Please contact customer service for assistance.";
    }
    
    // Send notification
    string|time:Error validatedAtStr = time:civilToString(event.validatedAt);
    json metadata = validatedAtStr is string ? {
        "ticketId": event.ticketId,
        "tripId": event.tripId,
        "validationResult": event.validationResult,
        "validatedAt": validatedAtStr
    } : {
        "ticketId": event.ticketId,
        "tripId": event.tripId,
        "validationResult": event.validationResult
    };
    
    check sendNotification(
        event.passengerId,
        "ticket_validated",
        subject,
        message,
        metadata
    );
}

// Handle payment processed notification
public function handlePaymentProcessed(PaymentProcessedEvent event) returns error? {
    log:printInfo(string `Processing payment notification: ${event.paymentId} - ${event.status}`);
    
    string subject = "";
    string message = "";
    string notificationType = "";
    
    if event.status == "success" {
        subject = "Payment Successful";
        message = string `Your payment of $${event.amount} has been processed successfully.`;
        
        string? transactionReference = event?.transactionReference;
        if transactionReference is string {
            message += string ` Transaction reference: ${transactionReference}`;
        }
        
        message += " Your ticket is now ready for use.";
        notificationType = "payment_success";
    } else {
        subject = "Payment Failed";
        message = string `Your payment of $${event.amount} could not be processed.`;
        
        string? failureReason = event?.failureReason;
        if failureReason is string {
            message += string ` Reason: ${failureReason}`;
        }
        
        message += " Please try again or use a different payment method.";
        notificationType = "payment_failed";
    }
    
    // Send notification
    string|time:Error processedAtStr = time:civilToString(event.processedAt);
    json metadata = processedAtStr is string ? {
        "paymentId": event.paymentId,
        "ticketId": event.ticketId,
        "amount": event.amount,
        "status": event.status,
        "processedAt": processedAtStr
    } : {
        "paymentId": event.paymentId,
        "ticketId": event.ticketId,
        "amount": event.amount,
        "status": event.status
    };
    
    check sendNotification(
        event.passengerId,
        notificationType,
        subject,
        message,
        metadata
    );
}

// Handle ticket created notification
public function handleTicketCreated(TicketCreatedEvent event) returns error? {
    log:printInfo(string `Processing ticket creation: ${event.ticketId}`);
    
    string subject = "Ticket Purchased Successfully";
    string message = string `Your ${event.ticketType} ticket has been created successfully.`;
    message += string ` Price: $${event.price}`;
    
    string|time:Error validFromStr = time:civilToString(event.validFrom);
    if validFromStr is string {
        message += string ` Valid from: ${validFromStr}`;
    }
    
    string|time:Error validUntilStr = time:civilToString(event.validUntil);
    if validUntilStr is string {
        message += string ` Valid until: ${validUntilStr}`;
    }
    
    message += " Your ticket is ready to use. Have a great journey!";
    
    // Send notification
    string|time:Error validFromStr2 = time:civilToString(event.validFrom);
    string|time:Error validUntilStr2 = time:civilToString(event.validUntil);
    
    json metadata = (validFromStr2 is string && validUntilStr2 is string) ? {
        "ticketId": event.ticketId,
        "ticketType": event.ticketType,
        "price": event.price,
        "validFrom": validFromStr2,
        "validUntil": validUntilStr2
    } : {
        "ticketId": event.ticketId,
        "ticketType": event.ticketType,
        "price": event.price
    };
    
    check sendNotification(
        event.passengerId,
        "ticket_created",
        subject,
        message,
        metadata
    );
}

// Send notification (multi-channel)
function sendNotification(string passengerId, string notificationType, 
                         string subject, string message, json? metadata = null) returns error? {
    string notificationId = uuid:createType1AsString();
    time:Civil now = time:utcToCivil(time:utcNow());
    
    // Get passenger email
    string|error email = getPassengerEmail(passengerId);
    
    // Send via console
    if enableConsoleOutput {
        check sendConsoleNotification(notificationId, passengerId, subject, message);
        
        Notification consoleNotification = {
            notificationId: notificationId + "-console",
            passengerId: passengerId,
            'type: notificationType,
            channel: "console",
            subject: subject,
            message: message,
            status: "sent",
            metadata: metadata,
            createdAt: now,
            sentAt: now
        };
        
        check saveNotification(consoleNotification);
    }
    
    // Send via email simulation
    if enableEmailSimulation && email is string {
        check sendEmailNotification(notificationId, email, subject, message);
        
        Notification emailNotification = {
            notificationId: notificationId + "-email",
            passengerId: passengerId,
            'type: notificationType,
            channel: "email",
            subject: subject,
            message: message,
            status: "sent",
            metadata: metadata,
            createdAt: now,
            sentAt: now
        };
        
        check saveNotification(emailNotification);
    }
    
    // Send via SMS simulation
    if enableSmsSimulation {
        check sendSmsNotification(notificationId, passengerId, message);
        
        Notification smsNotification = {
            notificationId: notificationId + "-sms",
            passengerId: passengerId,
            'type: notificationType,
            channel: "sms",
            subject: subject,
            message: message,
            status: "sent",
            metadata: metadata,
            createdAt: now,
            sentAt: now
        };
        
        check saveNotification(smsNotification);
    }
}

// Console notification
function sendConsoleNotification(string notificationId, string passengerId, 
                                string subject, string message) returns error? {
    io:println("╔═══════════════════════════════════════════════════════════════╗");
    io:println(string `║ NOTIFICATION: ${notificationId}`);
    io:println("╠═══════════════════════════════════════════════════════════════╣");
    io:println(string `║ To: Passenger ${passengerId}`);
    io:println(string `║ Subject: ${subject}`);
    io:println("╠═══════════════════════════════════════════════════════════════╣");
    io:println(string `║ ${message}`);
    io:println("╚═══════════════════════════════════════════════════════════════╝");
    io:println("");
    
    log:printInfo(string `Console notification sent to ${passengerId}`);
}

// Email notification simulation
function sendEmailNotification(string notificationId, string email, 
                              string subject, string message) returns error? {
    log:printInfo("─────────────────────────────────────────");
    log:printInfo(string `📧 EMAIL NOTIFICATION`);
    log:printInfo(string `ID: ${notificationId}`);
    log:printInfo(string `To: ${email}`);
    log:printInfo(string `Subject: ${subject}`);
    log:printInfo(string `Message: ${message}`);
    log:printInfo("─────────────────────────────────────────");
}

// SMS notification simulation
function sendSmsNotification(string notificationId, string passengerId, 
                            string message) returns error? {
    log:printInfo("─────────────────────────────────────────");
    log:printInfo(string `📱 SMS NOTIFICATION`);
    log:printInfo(string `ID: ${notificationId}`);
    log:printInfo(string `To: Passenger ${passengerId}`);
    log:printInfo(string `Message: ${message}`);
    log:printInfo("─────────────────────────────────────────");
}

// Get passengers for a trip (helper function)
function getPassengersForTrip(string tripId) returns string[]|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection ticketsCollection = check db->getCollection("tickets");
    
    map<json> filter = {
        "tripId": tripId,
        "status": {"$in": ["active", "pending"]}
    };
    
    stream<map<json>, error?> ticketStream = check ticketsCollection->find(filter);
    
    string[] passengerIds = [];
    
    check from map<json> ticket in ticketStream
          do {
              string passengerId = ticket.get("passengerId").toString();
              if passengerIds.indexOf(passengerId) is () {
                  passengerIds.push(passengerId);
              }
          };
    
    return passengerIds;
}