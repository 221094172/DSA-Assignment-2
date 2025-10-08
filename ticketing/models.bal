// models.bal
import ballerina/time;

// Ticket model
public type Ticket record {|
    string ticketId;
    string passengerId;
    string tripId;
    string routeId;
    string routeNumber;
    string routeName;
    decimal price;
    string ticketType; // single, return, pass
    string status; // CREATED, PAID, VALIDATED, EXPIRED, CANCELLED
    string qrCode;
    string? paymentId?;
    string? transactionReference?;
    time:Civil purchaseDate;
    time:Civil validFrom;
    time:Civil validUntil;
    time:Civil? validatedAt?;
    string? validatedBy?;
    time:Civil createdAt;
    time:Civil updatedAt;
|};

// Ticket purchase request
public type TicketPurchaseRequest record {|
    string passengerId;
    string tripId;
    string ticketType;
    string paymentMethod;
|};

// Ticket purchase response
public type TicketPurchaseResponse record {|
    string ticketId;
    string qrCode;
    decimal price;
    string status;
    string message;
|};

// Ticket validation request
public type TicketValidationRequest record {|
    string ticketId;
    string qrCode;
    string validatorId; // Staff member who validates
|};

// Ticket validation response
public type TicketValidationResponse record {|
    boolean isValid;
    string message;
    string? ticketId?;
    string? passengerId?;
    time:Civil? validatedAt?;
|};

// Payment request to Kafka
public type PaymentRequest record {|
    string ticketId;
    string passengerId;
    string? tripId?;
    decimal amount;
    string paymentMethod;
    string requestId;
|};

// Payment response from Kafka
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

// Payment Service HTTP models
public type VerifyTicketRequest record {|
    string ticketId;
    string passengerId;
|};

public type VerifyTicketResponse record {|
    boolean isValid;
    string status;
    decimal? amount?;
    string? message?;
|};

public type UpdateTicketPaymentRequest record {|
    string ticketId;
    string paymentId;
    string paymentStatus;
    string? transactionReference?;
|};

public type UpdateTicketPaymentResponse record {|
    boolean success;
    string message;
|};

// Passenger Service models
public type Passenger record {|
    string passengerId;
    string username;
    string email;
    string? phone?;
|};

// Transport Service models
public type Trip record {|
    string tripId;
    string routeId;
    string routeNumber;
    string routeName;
    string origin;
    string destination;
    decimal price;
    time:Civil scheduledDeparture;
    time:Civil scheduledArrival;
    string status;
    int availableSeats;
|};

// Ticket statistics
public type TicketStats record {|
    int totalTickets;
    int createdTickets;
    int paidTickets;
    int validatedTickets;
    int expiredTickets;
    int cancelledTickets;
    decimal totalRevenue;
    map<int> ticketsByType;
    map<int> ticketsByRoute;
|};

// Ticket event for Kafka
public type TicketCreatedEvent record {|
    string ticketId;
    string passengerId;
    string tripId;
    string routeId;
    decimal price;
    time:Civil createdAt;
|};

public type TicketValidatedEvent record {|
    string ticketId;
    string passengerId;
    string tripId;
    string routeId;
    time:Civil validatedAt;
    string validatedBy;
|};