// kafka_consumer.bal
import ballerina/log;
import ballerinax/kafka;

// Kafka configuration
configurable string kafkaBootstrapServers = "kafka:9092";
configurable string kafkaGroupId = "ticketing-service-group";
configurable string paymentsProcessedTopic = "payments-processed";

// Kafka consumer configuration
kafka:ConsumerConfiguration consumerConfig = {
    groupId: kafkaGroupId,
    topics: [paymentsProcessedTopic],
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    autoCommit: true
};

// Initialize Kafka consumer
final kafka:Consumer kafkaConsumer = check new (kafkaBootstrapServers, consumerConfig);

// Consume payment processed events from Kafka
public function consumePaymentEvents() returns error? {
    log:printInfo(string `🎧 Ticketing Service - Listening to topic: ${paymentsProcessedTopic}`);
    
    while true {
        kafka:AnydataConsumerRecord[] records = check kafkaConsumer->poll(1);
        
        foreach kafka:AnydataConsumerRecord kafkaRecord in records {
            PaymentResponse response = check kafkaRecord.value.cloneWithType();
            log:printInfo(string `📨 Received payment response: ${response.ticketId} - ${response.status}`);
            
            // Process payment response asynchronously
            _ = start processPaymentResponse(response);
        }
    }
}

// Process payment response
function processPaymentResponse(PaymentResponse response) {
    error? result = handlePaymentResponse(response);
    
    if result is error {
        log:printError(string `❌ Failed to process payment response: ${response.ticketId}`, 'error = result);
    }
}

// Handle payment response
function handlePaymentResponse(PaymentResponse response) returns error? {
    if response.status == "success" {
        // Update ticket status to PAID
        check updateTicketStatus(
            response.ticketId,
            "PAID",
            response.paymentId,
            response?.transactionReference
        );
        
        log:printInfo(string `✅ Ticket ${response.ticketId} marked as PAID`);
        
        // Get ticket details
        Ticket ticket = check getTicketById(response.ticketId);
        
        // Publish ticket created event
        check publishTicketCreated({
            ticketId: ticket.ticketId,
            passengerId: ticket.passengerId,
            tripId: ticket.tripId,
            routeId: ticket.routeId,
            price: ticket.price,
            createdAt: ticket.createdAt
        });
        
    } else {
        // Payment failed - update ticket status
        check updateTicketStatus(response.ticketId, "CANCELLED");
        
        log:printWarn(string `⚠️ Ticket ${response.ticketId} cancelled due to payment failure`);
    }
}