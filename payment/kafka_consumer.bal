// kafka_consumer.bal
import ballerina/log;
import ballerinax/kafka;
import ballerina/lang.runtime;

// Kafka configuration
configurable string kafkaBootstrapServers = "kafka:9092";
configurable string kafkaGroupId = "payment-service-group";
configurable string ticketRequestsTopic = "ticket-requests";

// Kafka consumer configuration
kafka:ConsumerConfiguration consumerConfig = {
    groupId: kafkaGroupId,
    topics: [ticketRequestsTopic],
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    autoCommit: true
};

// Initialize Kafka consumer
final kafka:Consumer kafkaConsumer = check new (kafkaBootstrapServers, consumerConfig);

// Consume payment requests from Kafka
public function consumePaymentRequests() returns error? {
    log:printInfo(string `🎧 Payment Service - Listening to topic: ${ticketRequestsTopic}`);
    
    while true {
        kafka:AnydataConsumerRecord[] records = check kafkaConsumer->poll(1);
        
        foreach kafka:AnydataConsumerRecord kafkaRecord in records {
            anydata messageValue = kafkaRecord.value;
            byte[] messageBytes = <byte[]>messageValue;
            string messageStr = check string:fromBytes(messageBytes);
            PaymentRequest request = check messageStr.fromJsonStringWithType();
            
            log:printInfo(string `📨 Received payment request: ${request.ticketId}`);
            
            // Process payment asynchronously
            _ = start processPaymentRequest(request);
        }
        
        // Small delay to prevent tight loop
        runtime:sleep(0.1);
    }
}

// Process individual payment request
function processPaymentRequest(PaymentRequest request) {
    error? result = processPayment(request);
    
    if result is error {
        log:printError(string `❌ Payment processing failed: ${request.ticketId}`, 'error = result);
        
        // Send failure response
        error? publishResult = publishPaymentResponse({
            paymentId: "",
            ticketId: request.ticketId,
            passengerId: request.passengerId,
            amount: request.amount,
            status: "failed",
            failureReason: result.message(),
            processedAt: {
                year: 2024,
                month: 12,
                day: 20,
                hour: 10,
                minute: 30
            }
        });
        
        if publishResult is error {
            log:printError("Failed to publish payment failure", 'error = publishResult);
        }
    }
}