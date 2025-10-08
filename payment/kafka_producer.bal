// kafka_producer.bal
import ballerina/log;
import ballerinax/kafka;

// Kafka configuration
configurable string paymentsProcessedTopic = "payments-processed";
configurable string paymentRefundsTopic = "payment-refunds";

// Kafka producer configuration
kafka:ProducerConfiguration producerConfig = {
    clientId: "payment-service-producer",
    acks: kafka:ACKS_ALL,
    retryCount: 3
};

// Initialize Kafka producer
final kafka:Producer kafkaProducer = check new (kafkaBootstrapServers, producerConfig);

// Publish payment response to Kafka
public function publishPaymentResponse(PaymentResponse response) returns error? {
    json responseJson = response.toJson();
    
    check kafkaProducer->send({
        topic: paymentsProcessedTopic,
        value: responseJson.toJsonString().toBytes()
    });
    
    log:printInfo(string `📤 Published payment response: ${response.paymentId} - ${response.status}`);
}

// Publish payment refund to Kafka
public function publishPaymentRefund(RefundResponse refund) returns error? {
    json refundJson = refund.toJson();
    
    check kafkaProducer->send({
        topic: paymentRefundsTopic,
        value: refundJson.toJsonString().toBytes()
    });
    
    log:printInfo(string `📤 Published payment refund: ${refund.refundId} - ${refund.status}`);
}