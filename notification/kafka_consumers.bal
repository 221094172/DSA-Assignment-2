// kafka_consumers.bal
import ballerina/log;
import ballerinax/kafka;
import ballerina/lang.value;

// Kafka configuration
configurable string kafkaBootstrapServers = "kafka:9092";
configurable string kafkaGroupId = "notification-service-group";
configurable string scheduleUpdatesTopic = "schedule-updates";
configurable string ticketValidatedTopic = "ticket-validated";
configurable string paymentsProcessedTopic = "payments-processed";
configurable string ticketCreatedTopic = "ticket-created";

// Kafka consumers
final kafka:Consumer scheduleUpdatesConsumer = check initializeScheduleUpdatesConsumer();
final kafka:Consumer ticketValidatedConsumer = check initializeTicketValidatedConsumer();
final kafka:Consumer paymentsProcessedConsumer = check initializePaymentsProcessedConsumer();
final kafka:Consumer ticketCreatedConsumer = check initializeTicketCreatedConsumer();

// Initialize schedule updates consumer
function initializeScheduleUpdatesConsumer() returns kafka:Consumer|error {
    kafka:Consumer consumer = check new (
        kafka:DEFAULT_URL,
        {
            groupId: kafkaGroupId + "-schedule",
            topics: [scheduleUpdatesTopic],
            offsetReset: kafka:OFFSET_RESET_EARLIEST,
            autoCommit: true
        }
    );
    
    log:printInfo(string `Schedule updates consumer initialized: ${scheduleUpdatesTopic}`);
    return consumer;
}

// Initialize ticket validated consumer
function initializeTicketValidatedConsumer() returns kafka:Consumer|error {
    kafka:Consumer consumer = check new (
        kafka:DEFAULT_URL,
        {
            groupId: kafkaGroupId + "-validation",
            topics: [ticketValidatedTopic],
            offsetReset: kafka:OFFSET_RESET_EARLIEST,
            autoCommit: true
        }
    );
    
    log:printInfo(string `Ticket validated consumer initialized: ${ticketValidatedTopic}`);
    return consumer;
}

// Initialize payments processed consumer
function initializePaymentsProcessedConsumer() returns kafka:Consumer|error {
    kafka:Consumer consumer = check new (
        kafka:DEFAULT_URL,
        {
            groupId: kafkaGroupId + "-payment",
            topics: [paymentsProcessedTopic],
            offsetReset: kafka:OFFSET_RESET_EARLIEST,
            autoCommit: true
        }
    );
    
    log:printInfo(string `Payments processed consumer initialized: ${paymentsProcessedTopic}`);
    return consumer;
}

// Initialize ticket created consumer
function initializeTicketCreatedConsumer() returns kafka:Consumer|error {
    kafka:Consumer consumer = check new (
        kafka:DEFAULT_URL,
        {
            groupId: kafkaGroupId + "-ticket",
            topics: [ticketCreatedTopic],
            offsetReset: kafka:OFFSET_RESET_EARLIEST,
            autoCommit: true
        }
    );
    
    log:printInfo(string `Ticket created consumer initialized: ${ticketCreatedTopic}`);
    return consumer;
}

// Consume schedule updates
public function consumeScheduleUpdates() returns error? {
    log:printInfo("Starting to consume schedule updates...");
    
    while true {
        kafka:BytesConsumerRecord[] records = check scheduleUpdatesConsumer->poll(1);
        
        foreach kafka:BytesConsumerRecord kafkaRecord in records {
            byte[] messageContent = kafkaRecord.value;
            string message = check string:fromBytes(messageContent);
            
            log:printInfo(string `Received schedule update: ${message}`);
            
            // Parse event
            json eventJson = check value:fromJsonString(message);
            ScheduleUpdateEvent event = check eventJson.cloneWithType(ScheduleUpdateEvent);
            
            // Handle schedule update
            error? result = handleScheduleUpdate(event);
            
            if result is error {
                log:printError("Failed to handle schedule update", 'error = result);
            }
        }
    }
}

// Consume ticket validated events
public function consumeTicketValidated() returns error? {
    log:printInfo("Starting to consume ticket validated events...");
    
    while true {
        kafka:BytesConsumerRecord[] records = check ticketValidatedConsumer->poll(1);
        
        foreach kafka:BytesConsumerRecord kafkaRecord in records {
            byte[] messageContent = kafkaRecord.value;
            string message = check string:fromBytes(messageContent);
            
            log:printInfo(string `Received ticket validated: ${message}`);
            
            // Parse event
            json eventJson = check value:fromJsonString(message);
            TicketValidatedEvent event = check eventJson.cloneWithType(TicketValidatedEvent);
            
            // Handle ticket validation
            error? result = handleTicketValidated(event);
            
            if result is error {
                log:printError("Failed to handle ticket validated", 'error = result);
            }
        }
    }
}

// Consume payments processed events
public function consumePaymentsProcessed() returns error? {
    log:printInfo("Starting to consume payments processed events...");
    
    while true {
        kafka:BytesConsumerRecord[] records = check paymentsProcessedConsumer->poll(1);
        
        foreach kafka:BytesConsumerRecord kafkaRecord in records {
            byte[] messageContent = kafkaRecord.value;
            string message = check string:fromBytes(messageContent);
            
            log:printInfo(string `Received payment processed: ${message}`);
            
            // Parse event
            json eventJson = check value:fromJsonString(message);
            PaymentProcessedEvent event = check eventJson.cloneWithType(PaymentProcessedEvent);
            
            // Handle payment processed
            error? result = handlePaymentProcessed(event);
            
            if result is error {
                log:printError("Failed to handle payment processed", 'error = result);
            }
        }
    }
}

// Consume ticket created events
public function consumeTicketCreated() returns error? {
    log:printInfo("Starting to consume ticket created events...");
    
    while true {
        kafka:BytesConsumerRecord[] records = check ticketCreatedConsumer->poll(1);
        
        foreach kafka:BytesConsumerRecord kafkaRecord in records {
            byte[] messageContent = kafkaRecord.value;
            string message = check string:fromBytes(messageContent);
            
            log:printInfo(string `Received ticket created: ${message}`);
            
            // Parse event
            json eventJson = check value:fromJsonString(message);
            TicketCreatedEvent event = check eventJson.cloneWithType(TicketCreatedEvent);
            
            // Handle ticket created
            error? result = handleTicketCreated(event);
            
            if result is error {
                log:printError("Failed to handle ticket created", 'error = result);
            }
        }
    }
}