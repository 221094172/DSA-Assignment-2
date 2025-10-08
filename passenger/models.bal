// models.bal
import ballerina/time;

// Passenger model
public type Passenger record {|
    string passengerId;
    string username;
    string email;
    string passwordHash;
    string firstName?;
    string lastName?;
    string phoneNumber?;
    time:Civil createdAt;
    time:Civil updatedAt;
    string status; // active, suspended, deleted
|};

// Registration request
public type RegisterRequest record {|
    string username;
    string email;
    string password;
    string firstName?;
    string lastName?;
    string phoneNumber?;
|};

// Login request
public type LoginRequest record {|
    string username;
    string password;
|};

// Login response
public type LoginResponse record {|
    string token;
    string passengerId;
    string username;
    string email;
    string message;
|};

// Passenger response (without password)
public type PassengerResponse record {|
    string passengerId;
    string username;
    string email;
    string firstName?;
    string lastName?;
    string phoneNumber?;
    string status;
    string createdAt;
|};

// Ticket model
public type Ticket record {|
    string ticketId;
    string passengerId;
    string ticketType; // single, return, day-pass, weekly-pass, monthly-pass
    string status; // active, used, expired, cancelled
    string routeId?;
    string tripId?;
    decimal price;
    string qrCode;
    time:Civil purchasedAt;
    time:Civil? validFrom;
    time:Civil? validUntil;
    time:Civil? usedAt?;
|};

// Error response
public type ErrorResponse record {|
    string message;
    string 'error;
    int statusCode;
|};

// Success response
public type SuccessResponse record {|
    string message;
    json data?;
|};

// Kafka event
public type PassengerEvent record {|
    string eventId;
    string eventType; // PASSENGER_REGISTERED, PASSENGER_LOGGED_IN, PASSENGER_UPDATED
    string passengerId;
    time:Civil timestamp;
    json payload;
|};