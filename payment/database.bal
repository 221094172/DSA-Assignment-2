// database.bal
import ballerina/log;
import ballerinax/mongodb;

// MongoDB configuration
configurable string mongoHost = "mongodb";
configurable int mongoPort = 27017;
configurable string mongoDatabase = "transport_ticketing_system";

// MongoDB client
final mongodb:Client mongoClient = check initializeMongoDB();

function initializeMongoDB() returns mongodb:Client|error {
    mongodb:Client mongoDb = check new ({
        connection: {
            serverAddress: {
                host: mongoHost,
                port: mongoPort
            }
        }
    });
    
    log:printInfo("✅ Payment Service - Connected to MongoDB successfully");
    return mongoDb;
}

// Save payment to database
public function savePayment(Payment payment) returns error? {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection paymentsCollection = check db->getCollection("payments");
    
    check paymentsCollection->insertOne(payment);
    log:printInfo(string `💾 Payment saved: ${payment.paymentId} - ${payment.status}`);
}

// Update payment status
public function updatePaymentStatus(string paymentId, string status, 
                                    string? transactionReference = null,
                                    string? failureReason = null) returns error? {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection paymentsCollection = check db->getCollection("payments");
    
    map<json> filter = {
        "paymentId": paymentId
    };
    
    map<json> updateData = {
        "status": status,
        "updatedAt": {
            "year": 2024,
            "month": 12,
            "day": 20,
            "hour": 10,
            "minute": 30
        }
    };
    
    if status == "completed" {
        updateData["processedAt"] = {
            "year": 2024,
            "month": 12,
            "day": 20,
            "hour": 10,
            "minute": 30
        };
    }
    
    if transactionReference is string {
        updateData["transactionReference"] = transactionReference;
    }
    
    if failureReason is string {
        updateData["failureReason"] = failureReason;
    }
    
    mongodb:Update update = {
        set: updateData
    };
    
    mongodb:UpdateResult updateResult = check paymentsCollection->updateOne(filter, update);
    
    if updateResult.modifiedCount > 0 {
        log:printInfo(string `✅ Payment ${paymentId} updated to ${status}`);
    }
}

// Get payment by ID
public function getPaymentById(string paymentId) returns Payment|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection paymentsCollection = check db->getCollection("payments");
    
    map<json> filter = {
        "paymentId": paymentId
    };
    
    Payment? payment = check paymentsCollection->findOne(filter);
    
    if payment is () {
        return error(string `Payment not found: ${paymentId}`);
    }
    
    return payment;
}

// Get payment by ticket ID
public function getPaymentByTicketId(string ticketId) returns Payment|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection paymentsCollection = check db->getCollection("payments");
    
    map<json> filter = {
        "ticketId": ticketId
    };
    
    map<json> sort = {
        "createdAt": -1
    };
    
    stream<Payment, error?> paymentStream = check paymentsCollection->find(
        filter,
        {sort: sort, 'limit: 1}
    );
    
    Payment[] payments = check from Payment payment in paymentStream
                               select payment;
    
    if payments.length() == 0 {
        return error(string `Payment not found for ticket: ${ticketId}`);
    }
    
    return payments[0];
}

// Get payments by passenger ID
public function getPaymentsByPassenger(string passengerId) returns Payment[]|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection paymentsCollection = check db->getCollection("payments");
    
    map<json> filter = {
        "passengerId": passengerId
    };
    
    map<json> sort = {
        "createdAt": -1
    };
    
    stream<Payment, error?> paymentStream = check paymentsCollection->find(
        filter,
        {sort: sort}
    );
    
    Payment[] payments = check from Payment payment in paymentStream
                               select payment;
    
    return payments;
}

// Get payment statistics
public function getPaymentStatistics() returns PaymentStats|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection paymentsCollection = check db->getCollection("payments");
    
    // Get all payments
    stream<Payment, error?> allPayments = check paymentsCollection->find({});
    Payment[] payments = check from Payment payment in allPayments
                               select payment;
    
    int totalPayments = payments.length();
    int successfulPayments = 0;
    int failedPayments = 0;
    int refundedPayments = 0;
    decimal totalAmount = 0.0;
    decimal successfulAmount = 0.0;
    decimal refundedAmount = 0.0;
    
    map<int> paymentsByMethod = {};
    
    foreach Payment payment in payments {
        totalAmount += payment.amount;
        
        // Count by status
        if payment.status == "completed" {
            successfulPayments += 1;
            successfulAmount += payment.amount;
        } else if payment.status == "failed" {
            failedPayments += 1;
        } else if payment.status == "refunded" {
            refundedPayments += 1;
            refundedAmount += payment.amount;
        }
        
        // Count by payment method
        string method = payment.paymentMethod;
        if paymentsByMethod.hasKey(method) {
            paymentsByMethod[method] = <int>paymentsByMethod.get(method) + 1;
        } else {
            paymentsByMethod[method] = 1;
        }
    }
    
    return {
        totalPayments,
        successfulPayments,
        failedPayments,
        refundedPayments,
        totalAmount,
        successfulAmount,
        refundedAmount,
        paymentsByMethod
    };
}

// Get payment history for a passenger
public function getPaymentHistory(string passengerId) returns PaymentHistory|error {
    Payment[] payments = check getPaymentsByPassenger(passengerId);
    
    decimal totalAmount = 0.0;
    foreach Payment payment in payments {
        if payment.status == "completed" {
            totalAmount += payment.amount;
        }
    }
    
    return {
        passengerId,
        payments,
        totalPayments: payments.length(),
        totalAmount
    };
}