// kafka_producer.bal
import ballerinax/kafka;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;

configurable string kafkaBootstrapServers = ?;
configurable string passengerEventsTopic = ?;

// Kafka producer configuration
kafka:ProducerConfiguration producerConfig = {
    clientId: "passenger-service-producer",
    acks: "all",
    retryCount: 3
};

final kafka:Producer kafkaProducer = check new (kafkaBootstrapServers, producerConfig);

// Publish passenger event to Kafka
public function publishPassengerEvent(string eventType, string passengerId, json payload) returns error? {
    PassengerEvent event = {
        eventId: uuid:createType1AsString(),
        eventType: eventType,
        passengerId: passengerId,
        timestamp: time:utcToCivil(time:utcNow()),
        payload: payload
    };
    
    string eventJson = event.toJsonString();
    
    check kafkaProducer->send({
        topic: passengerEventsTopic,
        value: eventJson.toBytes()
    });
    
    log:printInfo("Published event: " + eventType + " for passenger: " + passengerId);
}