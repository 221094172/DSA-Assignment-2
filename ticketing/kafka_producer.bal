// kafka_producer.bal
import ballerina/log;
import ballerinax/kafka;

// Kafka configuration
configurable string ticketRequestsTopic = "ticket-requests";
configurable string ticketCreatedTopic = "ticket-created";
configurable string ticketValidatedTopic = "ticket-validated";

// Kafka producer configuration
kafka:ProducerConfiguration producerConfig = {
    clientId: "ticketing-service-producer",
    acks: kafka:ACKS_ALL,
    retryCount: 3
};

// Initialize Kafka producer
final kafka:Producer kafkaProducer = check new (kafkaBootstrapServers, producerConfig);

// Publish payment request to Kafka
public function publishPaymentRequest(PaymentRequest request) returns error? {
    json requestJson = request.toJson();
    
    check kafkaProducer->send({
        topic: ticketRequestsTopic,
        value: requestJson.toJsonString().toBytes()
    });
    
    log:printInfo(string `📤 Published payment request: ${request.ticketId}`);
}

// Publish ticket created event
public function publishTicketCreated(TicketCreatedEvent event) returns error? {
    json eventJson = event.toJson();
    
    check kafkaProducer->send({
        topic: ticketCreatedTopic,
        value: eventJson.toJsonString().toBytes()
    });
    
    log:printInfo(string `📤 Published ticket created event: ${event.ticketId}`);
}

// Publish ticket validated event
public function publishTicketValidated(TicketValidatedEvent event) returns error? {
    json eventJson = event.toJson();
    
    check kafkaProducer->send({
        topic: ticketValidatedTopic,
        value: eventJson.toJsonString().toBytes()
    });
    
    log:printInfo(string `📤 Published ticket validated event: ${event.ticketId}`);
}