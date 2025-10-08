// kafka_producer.bal
import ballerinax/kafka;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;

configurable string kafkaBootstrapServers = ?;
configurable string scheduleUpdatesTopic = ?;
configurable string routeEventsTopic = ?;

kafka:ProducerConfiguration producerConfig = {
    clientId: "transport-service-producer",
    acks: "all",
    retryCount: 3
};

final kafka:Producer kafkaProducer = check new (kafkaBootstrapServers, producerConfig);

// Publish schedule update event
public function publishScheduleUpdate(string eventType, string tripId, string routeId, 
                                     string status, string? reason, int? delayMinutes, 
                                     json metadata) returns error? {
    ScheduleUpdateEvent event = {
        eventId: uuid:createType1AsString(),
        eventType: eventType,
        tripId: tripId,
        routeId: routeId,
        timestamp: time:utcToCivil(time:utcNow()),
        status: status,
        reason: reason,
        delayMinutes: delayMinutes,
        metadata: metadata
    };
    
    string eventJson = event.toJsonString();
    
    check kafkaProducer->send({
        topic: scheduleUpdatesTopic,
        value: eventJson.toBytes()
    });
    
    log:printInfo("Published schedule update: " + eventType + " for trip: " + tripId);
}

// Publish route event
public function publishRouteEvent(string eventType, string routeId, json payload) returns error? {
    RouteEvent event = {
        eventId: uuid:createType1AsString(),
        eventType: eventType,
        routeId: routeId,
        timestamp: time:utcToCivil(time:utcNow()),
        payload: payload
    };
    
    string eventJson = event.toJsonString();
    
    check kafkaProducer->send({
        topic: routeEventsTopic,
        value: eventJson.toBytes()
    });
    
    log:printInfo("Published route event: " + eventType + " for route: " + routeId);
}