// models.bal
import ballerina/time;

// Payment model
public type Payment record {|
    string paymentId;
    string ticketId;
    string passengerId;
    decimal amount;
    string currency = "USD";
    string paymentMethod; // credit_card, debit_card, mobile_wallet, cash
    string status; // pending, processing, completed, failed, refunded
    string? transactionReference?;
    string? failureReason?;
    time:Civil? processedAt?;
    time:Civil createdAt;
    time:Civil updatedAt;
|};

// Payment request from Kafka
public type PaymentRequest record {|
    string ticketId;
    string passengerId;
    string? tripId?;
    decimal amount;
    string paymentMethod;
    string requestId;
|};

// Payment response to Kafka
public type PaymentResponse record {|
    string paymentId;
    string ticketId;
    string passengerId;
    decimal amount;
    string status; // success, failed
    string? transactionReference?;
    string? failureReason?;
    time:Civil processedAt;
|};

// Payment refund request
public type RefundRequest record {|
    string paymentId;
    string ticketId;
    string passengerId;
    decimal amount;
    string reason;
|};

// Payment refund response
public type RefundResponse record {|
    string refundId;
    string paymentId;
    string ticketId;
    string status; // success, failed
    string? failureReason?;
    time:Civil refundedAt;
|};

// HTTP request/response models for Ticketing Service communication

// Verify ticket request
public type VerifyTicketRequest record {|
    string ticketId;
    string passengerId;
|};

// Verify ticket response
public type VerifyTicketResponse record {|
    boolean isValid;
    string status;
    decimal? amount?;
    string? message?;
|};

// Update ticket payment status request
public type UpdateTicketPaymentRequest record {|
    string ticketId;
    string paymentId;
    string paymentStatus; // completed, failed
    string? transactionReference?;
|};

// Update ticket payment status response
public type UpdateTicketPaymentResponse record {|
    boolean success;
    string message;
|};

// Payment statistics
public type PaymentStats record {|
    int totalPayments;
    int successfulPayments;
    int failedPayments;
    int refundedPayments;
    decimal totalAmount;
    decimal successfulAmount;
    decimal refundedAmount;
    map<int> paymentsByMethod;
|};

// Payment history
public type PaymentHistory record {|
    string passengerId;
    Payment[] payments;
    int totalPayments;
    decimal totalAmount;
|};

// HTTP Response wrapper
public type HttpResponse record {|
    int status;
    string message;
    json? data?;
|};