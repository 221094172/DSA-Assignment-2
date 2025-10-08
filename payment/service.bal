// service.bal
import ballerina/http;
import ballerina/log;
import ballerina/lang.runtime;
import ballerina/time;

// Service configuration
configurable int port = 9094;

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
service /api/payments on httpListener {
    
    // Health check endpoint
    resource function get health() returns json {
        log:printInfo("Health check requested");
        return {
            "status": "healthy",
            "service": "payment-service",
            "timestamp": time:utcNow()
        };
    }
    
    // Get payment by ID
    resource function get [string paymentId]() returns Payment|http:NotFound|http:InternalServerError {
        log:printInfo(string `Getting payment: ${paymentId}`);
        
        Payment|error payment = getPaymentById(paymentId);
        
        if payment is error {
            log:printError(string `Payment not found: ${paymentId}`, 'error = payment);
            return <http:NotFound>{
                body: {
                    "error": "Payment not found",
                    "message": payment.message()
                }
            };
        }
        
        return payment;
    }
    
    // Get payment by ticket ID
    resource function get ticket/[string ticketId]() returns Payment|http:NotFound|http:InternalServerError {
        log:printInfo(string `Getting payment for ticket: ${ticketId}`);
        
        Payment|error payment = getPaymentByTicketId(ticketId);
        
        if payment is error {
            log:printError(string `Payment not found for ticket: ${ticketId}`, 'error = payment);
            return <http:NotFound>{
                body: {
                    "error": "Payment not found",
                    "message": payment.message()
                }
            };
        }
        
        return payment;
    }
    
    // Get payments by passenger
    resource function get passenger/[string passengerId]() returns Payment[]|http:InternalServerError {
        log:printInfo(string `Getting payments for passenger: ${passengerId}`);
        
        Payment[]|error payments = getPaymentsByPassenger(passengerId);
        
        if payments is error {
            log:printError(string `Failed to get payments for passenger: ${passengerId}`, 'error = payments);
            return <http:InternalServerError>{
                body: {
                    "error": "Failed to retrieve payments",
                    "message": payments.message()
                }
            };
        }
        
        return payments;
    }
    
    // Get payment history for passenger
    resource function get history/[string passengerId]() returns PaymentHistory|http:InternalServerError {
        log:printInfo(string `Getting payment history for passenger: ${passengerId}`);
        
        PaymentHistory|error history = getPaymentHistory(passengerId);
        
        if history is error {
            log:printError(string `Failed to get payment history: ${passengerId}`, 'error = history);
            return <http:InternalServerError>{
                body: {
                    "error": "Failed to retrieve payment history",
                    "message": history.message()
                }
            };
        }
        
        return history;
    }
    
    // Get payment statistics
    resource function get stats() returns PaymentStats|http:InternalServerError {
        log:printInfo("Getting payment statistics");
        
        PaymentStats|error stats = getPaymentStatistics();
        
        if stats is error {
            log:printError("Failed to get payment statistics", 'error = stats);
            return <http:InternalServerError>{
                body: {
                    "error": "Failed to retrieve statistics",
                    "message": stats.message()
                }
            };
        }
        
        return stats;
    }
    
    // Process refund (called by Ticketing Service)
    resource function post refund(@http:Payload RefundRequest refundRequest) 
        returns RefundResponse|http:BadRequest|http:InternalServerError {
        
        log:printInfo(string `Processing refund request for payment: ${refundRequest.paymentId}`);
        
        RefundResponse|error response = processRefund(refundRequest);
        
        if response is error {
            log:printError("Refund processing failed", 'error = response);
            return <http:BadRequest>{
                body: {
                    "error": "Refund processing failed",
                    "message": response.message()
                }
            };
        }
        
        return response;
    }
}

// Main function - Start Kafka consumer and HTTP service
public function main() returns error? {
    log:printInfo("╔═══════════════════════════════════════════════════════════════╗");
    log:printInfo("║           PAYMENT SERVICE STARTING                            ║");
    log:printInfo("╚═══════════════════════════════════════════════════════════════╝");
    
    log:printInfo(string `🌐 HTTP Server started on port ${port}`);
    log:printInfo(string `🎧 Kafka Consumer listening to: ${ticketRequestsTopic}`);
    log:printInfo(string `📤 Kafka Producer publishing to: ${paymentsProcessedTopic}`);
    
    // Start Kafka consumer in a separate worker
    worker kafkaWorker {
        error? result = consumePaymentRequests();
        if result is error {
            log:printError("Kafka consumer failed", 'error = result);
        }
    }
    
    // Keep main thread alive
    runtime:sleep(999999);
    
    return;
}