// service.bal
import ballerina/http;
import ballerina/log;
import ballerina/time;

// Service configuration
configurable int port = 9095;

// HTTP listener
listener http:Listener httpListener = new (port);

// REST API Service
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"],
        maxAge: 84900
    }
}
service /api/tickets on httpListener {
    
    // Health check endpoint
    resource function get health() returns json {
        log:printInfo("Health check requested");
        return {
            "status": "healthy",
            "service": "ticketing-service",
            "timestamp": time:utcNow()
        };
    }
    
    // Purchase ticket
    resource function post .(@http:Payload TicketPurchaseRequest request) 
        returns TicketPurchaseResponse|http:BadRequest|http:InternalServerError {
        
        log:printInfo(string `🎫 Purchase ticket request for passenger: ${request.passengerId}`);
        
        TicketPurchaseResponse|error response = purchaseTicket(request);
        
        if response is error {
            log:printError("Ticket purchase failed", 'error = response);
            return <http:BadRequest>{
                body: {
                    "error": "Ticket purchase failed",
                    "message": response.message()
                }
            };
        }
        
        return response;
    }
    
    // Get ticket by ID
    resource function get [string ticketId]() returns Ticket|http:NotFound|http:InternalServerError {
        log:printInfo(string `Getting ticket: ${ticketId}`);
        
        Ticket|error ticket = getTicketById(ticketId);
        
        if ticket is error {
            log:printError(string `Ticket not found: ${ticketId}`, 'error = ticket);
            return <http:NotFound>{
                body: {
                    "error": "Ticket not found",
                    "message": ticket.message()
                }
            };
        }
        
        return ticket;
    }
    
    // Validate ticket
    resource function put [string ticketId]/validate(@http:Payload TicketValidationRequest request) 
        returns TicketValidationResponse|http:BadRequest|http:InternalServerError {
        
        log:printInfo(string `Validating ticket: ${ticketId}`);
        
        TicketValidationResponse|error response = validateTicketForBoarding(request);
        
        if response is error {
            log:printError("Ticket validation failed", 'error = response);
            return <http:BadRequest>{
                body: {
                    "error": "Ticket validation failed",
                    "message": response.message()
                }
            };
        }
        
        return response;
    }
    
    // Get tickets by passenger
    resource function get passenger/[string passengerId](string? status = null) 
        returns Ticket[]|http:InternalServerError {
        
        log:printInfo(string `Getting tickets for passenger: ${passengerId}`);
        
        Ticket[]|error tickets = getTicketsByPassenger(passengerId, status);
        
        if tickets is error {
            log:printError(string `Failed to get tickets for passenger: ${passengerId}`, 'error = tickets);
            return <http:InternalServerError>{
                body: {
                    "error": "Failed to retrieve tickets",
                    "message": tickets.message()
                }
            };
        }
        
        return tickets;
    }
    
    // Get tickets by trip
    resource function get trip/[string tripId]() returns Ticket[]|http:InternalServerError {
        log:printInfo(string `Getting tickets for trip: ${tripId}`);
        
        Ticket[]|error tickets = getTicketsByTrip(tripId);
        
        if tickets is error {
            log:printError(string `Failed to get tickets for trip: ${tripId}`, 'error = tickets);
            return <http:InternalServerError>{
                body: {
                    "error": "Failed to retrieve tickets",
                    "message": tickets.message()
                }
            };
        }
        
        return tickets;
    }
    
    // Get ticket statistics
    resource function get stats() returns TicketStats|http:InternalServerError {
        log:printInfo("Getting ticket statistics");
        
        TicketStats|error stats = getTicketStatistics();
        
        if stats is error {
            log:printError("Failed to get ticket statistics", 'error = stats);
            return <http:InternalServerError>{
                body: {
                    "error": "Failed to retrieve statistics",
                    "message": stats.message()
                }
            };
        }
        
        return stats;
    }
    
    // Cancel ticket
    resource function delete [string ticketId]() returns json|http:BadRequest|http:InternalServerError {
        log:printInfo(string `Cancelling ticket: ${ticketId}`);
        
        error? result = cancelTicket(ticketId);
        
        if result is error {
            log:printError("Ticket cancellation failed", 'error = result);
            return <http:BadRequest>{
                body: {
                    "error": "Ticket cancellation failed",
                    "message": result.message()
                }
            };
        }
        
        return {
            "success": true,
            "message": "Ticket cancelled successfully"
        };
    }
    
    // Verify ticket (called by Payment Service)
    resource function post verify(@http:Payload VerifyTicketRequest request) 
        returns VerifyTicketResponse|http:InternalServerError {
        
        log:printInfo(string `Verifying ticket: ${request.ticketId} for payment`);
        
        Ticket|error ticket = getTicketById(request.ticketId);
        
        if ticket is error {
            return {
                isValid: false,
                status: "NOT_FOUND",
                message: "Ticket not found"
            };
        }
        
        // Check if ticket belongs to passenger
        if ticket.passengerId != request.passengerId {
            return {
                isValid: false,
                status: "INVALID",
                message: "Ticket does not belong to this passenger"
            };
        }
        
        // Check ticket status
        if ticket.status != "CREATED" {
            return {
                isValid: false,
                status: ticket.status,
                message: string `Ticket is already ${ticket.status}`
            };
        }
        
        return {
            isValid: true,
            status: ticket.status,
            amount: ticket.price,
            message: "Ticket is valid for payment"
        };
    }
    
    // Update ticket payment status (called by Payment Service)
    resource function put payment\-status(@http:Payload UpdateTicketPaymentRequest request) 
        returns UpdateTicketPaymentResponse|http:InternalServerError {
        
        log:printInfo(string `Updating payment status for ticket: ${request.ticketId}`);
        
        string newStatus = request.paymentStatus == "completed" ? "PAID" : "CANCELLED";
        
        error? result = updateTicketStatus(
            request.ticketId,
            newStatus,
            request.paymentId,
            request?.transactionReference
        );
        
        if result is error {
            log:printError("Failed to update ticket payment status", 'error = result);
            return <http:InternalServerError>{
                body: {
                    "success": false,
                    "message": result.message()
                }
            };
        }
        
        return {
            success: true,
            message: string `Ticket status updated to ${newStatus}`
        };
    }
}

// Serve static frontend files
service / on httpListener {
    resource function get .() returns http:Response|error {
        http:Response response = new;
        response.setFileAsPayload("./frontend/index.html", contentType = "text/html");
        return response;
    }
    
    resource function get [string... paths]() returns http:Response|error {
        string filePath = string `./frontend/${string:'join("/", ...paths)}`;
        http:Response response = new;
        
        // Determine content type
        string contentType = "text/plain";
        if filePath.endsWith(".html") {
            contentType = "text/html";
        } else if filePath.endsWith(".css") {
            contentType = "text/css";
        } else if filePath.endsWith(".js") {
            contentType = "application/javascript";
        } else if filePath.endsWith(".png") {
            contentType = "image/png";
        } else if filePath.endsWith(".jpg") || filePath.endsWith(".jpeg") {
            contentType = "image/jpeg";
        }
        
        response.setFileAsPayload(filePath, contentType = contentType);
        return response;
    }

    function init() {
    // Start Kafka consumer in a separate worker
    worker kafkaWorker {
        error? result = consumePaymentEvents();
        if result is error {
            log:printError("Kafka consumer failed", 'error = result);
        }
    }
    
    // Start periodic ticket expiration checker
    worker expirationWorker {
        while true {
            // Use a loop with smaller delays instead of sleep
            int count = 0;
            while count < 300 {
                // This is a workaround - the worker will check every second
                count = count + 1;
            }
            int|error expired = expireOldTickets();
            if expired is error {
                log:printError("Failed to expire old tickets", 'error = expired);
            }
        }
    }
}

}