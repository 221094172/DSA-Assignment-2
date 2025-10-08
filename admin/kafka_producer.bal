// kafka_producer.bal
import ballerina/log;
import ballerinax/kafka;
import ballerina/uuid;
import ballerina/time;

configurable string kafkaBootstrapServers = "kafka:9092";
configurable string scheduleUpdatesTopic = "schedule-updates";
configurable string disruptionsTopic = "disruptions";
configurable string systemEventsTopic = "system-events";

final kafka:Producer kafkaProducer = check initKafkaProducer();

function initKafkaProducer() returns kafka:Producer|error {
    kafka:ProducerConfiguration config = {
        clientId: "admin-service-producer",
        acks: kafka:ACKS_ALL,
        retryCount: 3
    };
    
    kafka:Producer producer = check new (kafkaBootstrapServers, config);
    log:printInfo("Kafka producer initialized successfully");
    return producer;
}

// Publish schedule update
public function publishScheduleUpdate(ScheduleUpdateEvent event) returns error? {
    json payload = event.toJson();
    
    check kafkaProducer->send({
        topic: scheduleUpdatesTopic,
        value: payload.toJsonString().toBytes()
    });
    
    log:printInfo(string `Published schedule update: ${event.eventType}`);
}

// Publish disruption
public function publishDisruption(Disruption disruption) returns error? {
    json payload = disruption.toJson();
    
    check kafkaProducer->send({
        topic: disruptionsTopic,
        value: payload.toJsonString().toBytes()
    });
    
    log:printInfo(string `Published disruption: ${disruption.title}`);
}

// Publish system event
public function publishSystemEvent(string eventType, json eventData) returns error? {
    json payload = {
        eventId: uuid:createType1AsString(),
        eventType: eventType,
        data: eventData,
        timestamp: time:utcNow()
    };
    
    check kafkaProducer->send({
        topic: systemEventsTopic,
        value: payload.toJsonString().toBytes()
    });
    
    log:printInfo(string `Published system event: ${eventType}`);
}