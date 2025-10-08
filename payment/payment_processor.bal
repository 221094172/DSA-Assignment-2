// payment_processor.bal
import ballerina/log;
import ballerina/uuid;
import ballerina/time;
import ballerina/lang.runtime;
import ballerina/http;

// Payment configuration
configurable int processingDelayMin = 1000;
configurable int processingDelayMax = 2000;
configurable float failureRate = 0.05;

// Ticketing service configuration
configurable string ticketingServiceHost = "ticketing-service";
configurable int ticketingServicePort = 9095;

// HTTP client for Ticketing Service
final http:Client ticketingServiceClient = check new (string `http://${ticketingServiceHost}:${ticketingServicePort}`);

// Process payment request
public function processPayment(PaymentRequest request) returns error? {
    log:printInfo(string `🔄 Processing payment for ticket: ${request.ticketId}`);
    
    // Step 1: Verify ticket with Ticketing Service
    VerifyTicketResponse verifyResponse = check verifyTicketWithTicketingService(
        request.ticketId,
        request.passengerId
    );
    
    if !verifyResponse.isValid {
        string errorMsg = verifyResponse?.message ?: "Unknown error";
        log:printError(string `❌ Ticket verification failed: ${errorMsg}`);
        string failMsg = verifyResponse?.message ?: "Invalid ticket";
        return error(string `Ticket verification failed: ${failMsg}`);
    }
    
    // Step 2: Create payment record
    string paymentId = uuid:createType1AsString();
    time:Civil now = time:utcToCivil(time:utcNow());
    
    Payment payment = {
        paymentId: paymentId,
        ticketId: request.ticketId,
        passengerId: request.passengerId,
        amount: request.amount,
        paymentMethod: request.paymentMethod,
        status: "processing",
        createdAt: now,
        updatedAt: now
    };
    
    check savePayment(payment);
    
    // Step 3: Simulate payment processing delay
    int delay = processingDelayMin + <int>((processingDelayMax - processingDelayMin) * (check randomFloat()));
    runtime:sleep(<decimal>delay / 1000.0);
    
    // Step 4: Simulate payment success/failure
    float random = check randomFloat();
    boolean isSuccess = random > failureRate;
    
    string transactionRef = string `TXN-${paymentId.substring(0, 8)}`;
    
    if isSuccess {
        // Payment successful
        check updatePaymentStatus(paymentId, "completed", transactionRef);
        
        log:printInfo(string `✅ Payment successful: ${paymentId} - Amount: $${request.amount}`);
        
        // Step 5: Update ticket payment status in Ticketing Service
        UpdateTicketPaymentResponse updateResponse = check updateTicketPaymentStatus(
            request.ticketId,
            paymentId,
            "completed",
            transactionRef
        );
        
        if !updateResponse.success {
            log:printWarn(string `⚠️ Failed to update ticket payment status: ${updateResponse.message}`);
        }
        
        // Step 6: Publish success response to Kafka
        check publishPaymentResponse({
            paymentId: paymentId,
            ticketId: request.ticketId,
            passengerId: request.passengerId,
            amount: request.amount,
            status: "success",
            transactionReference: transactionRef,
            processedAt: time:utcToCivil(time:utcNow())
        });
        
    } else {
        // Payment failed
        string failureReason = "Payment declined by bank";
        check updatePaymentStatus(paymentId, "failed", failureReason = failureReason);
        
        log:printWarn(string `⚠️ Payment failed: ${paymentId} - Reason: ${failureReason}`);
        
        // Update ticket payment status in Ticketing Service
        UpdateTicketPaymentResponse updateResponse = check updateTicketPaymentStatus(
            request.ticketId,
            paymentId,
            "failed",
            ()
        );
        
        if !updateResponse.success {
            log:printWarn(string `⚠️ Failed to update ticket payment status: ${updateResponse.message}`);
        }
        
        // Publish failure response to Kafka
        check publishPaymentResponse({
            paymentId: paymentId,
            ticketId: request.ticketId,
            passengerId: request.passengerId,
            amount: request.amount,
            status: "failed",
            failureReason: failureReason,
            processedAt: time:utcToCivil(time:utcNow())
        });
    }
}

// Process refund request
public function processRefund(RefundRequest refundRequest) returns RefundResponse|error {
    log:printInfo(string `🔄 Processing refund for payment: ${refundRequest.paymentId}`);
    
    // Get original payment
    Payment payment = check getPaymentById(refundRequest.paymentId);
    
    if payment.status != "completed" {
        return error(string `Cannot refund payment with status: ${payment.status}`);
    }
    
    // Update payment status to refunded
    check updatePaymentStatus(payment.paymentId, "refunded");
    
    string refundId = uuid:createType1AsString();
    time:Civil now = time:utcToCivil(time:utcNow());
    
    log:printInfo(string `✅ Refund processed: ${refundId} - Amount: $${refundRequest.amount}`);
    
    RefundResponse response = {
        refundId: refundId,
        paymentId: refundRequest.paymentId,
        ticketId: refundRequest.ticketId,
        status: "success",
        refundedAt: now
    };
    
    // Publish refund to Kafka
    check publishPaymentRefund(response);
    
    return response;
}

// HTTP call to verify ticket with Ticketing Service
function verifyTicketWithTicketingService(string ticketId, string passengerId) 
    returns VerifyTicketResponse|error {
    
    log:printInfo(string `🔍 Verifying ticket ${ticketId} with Ticketing Service`);
    
    VerifyTicketRequest verifyRequest = {
        ticketId: ticketId,
        passengerId: passengerId
    };
    
    http:Response response = check ticketingServiceClient->/api/tickets/verify.post(verifyRequest);
    
    if response.statusCode != 200 {
        return error(string `Ticketing Service returned error: ${response.statusCode}`);
    }
    
    json payload = check response.getJsonPayload();
    VerifyTicketResponse verifyResponse = check payload.cloneWithType(VerifyTicketResponse);
    
    log:printInfo(string `✅ Ticket verification result: ${verifyResponse.isValid}`);
    
    return verifyResponse;
}

// HTTP call to update ticket payment status in Ticketing Service
function updateTicketPaymentStatus(string ticketId, string paymentId, 
                                   string paymentStatus, string? transactionReference) 
    returns UpdateTicketPaymentResponse|error {
    
    log:printInfo(string `📝 Updating ticket ${ticketId} payment status to ${paymentStatus}`);
    
    UpdateTicketPaymentRequest updateRequest = {
        ticketId: ticketId,
        paymentId: paymentId,
        paymentStatus: paymentStatus,
        transactionReference: transactionReference
    };
    
    http:Response response = check ticketingServiceClient->/api/tickets/payment\-status.put(updateRequest);
    
    if response.statusCode != 200 {
        return error(string `Ticketing Service returned error: ${response.statusCode}`);
    }
    
    json payload = check response.getJsonPayload();
    UpdateTicketPaymentResponse updateResponse = check payload.cloneWithType(UpdateTicketPaymentResponse);
    
    log:printInfo(string `✅ Ticket payment status updated: ${updateResponse.success}`);
    
    return updateResponse;
}

// Helper function to generate random float
function randomFloat() returns float|error {
    // Simple random number generation (for demo purposes)
    time:Utc now = time:utcNow();
    decimal nanos = <decimal>now[1];
    int nanosInt = <int>nanos;
    return <float>(nanosInt % 100000) / 100000.0;
}