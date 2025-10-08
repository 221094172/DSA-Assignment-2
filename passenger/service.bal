// service.bal
import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerina/crypto;
import ballerina/jwt;
import ballerina/time;

configurable int servicePort = ?;
configurable string serviceHost = ?;

// JWT issuer configuration
const string JWT_ISSUER = "transport-ticketing-system";
const string JWT_AUDIENCE = "passenger-service";
const string JWT_SECRET = "your-secret-key-change-in-production-min-32-chars-long!";

// CORS configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        maxAge: 84900
    }
}
service /api/passengers on new http:Listener(servicePort) {

    // Health check endpoint
    resource function get health() returns json {
        return {
            status: "UP",
            "service": "passenger-service",
            timestamp: time:utcNow()
        };
    }

    // Register new passenger
    resource function post register(@http:Payload RegisterRequest request) returns PassengerResponse|ErrorResponse|error {
        log:printInfo("Registration request received for username: " + request.username);

        // Validate input
        if request.username.length() < 3 {
            return <ErrorResponse>{
                message: "Username must be at least 3 characters long",
                'error: "VALIDATION_ERROR",
                statusCode: 400
            };
        }

        if request.password.length() < 6 {
            return <ErrorResponse>{
                message: "Password must be at least 6 characters long",
                'error: "VALIDATION_ERROR",
                statusCode: 400
            };
        }

        // Check if username already exists
        Passenger? existingUser = check findPassengerByUsername(request.username);
        if existingUser is Passenger {
            return <ErrorResponse>{
                message: "Username already exists",
                'error: "DUPLICATE_USERNAME",
                statusCode: 409
            };
        }

        // Check if email already exists
        Passenger? existingEmail = check findPassengerByEmail(request.email);
        if existingEmail is Passenger {
            return <ErrorResponse>{
                message: "Email already registered",
                'error: "DUPLICATE_EMAIL",
                statusCode: 409
            };
        }

        // Hash password
        byte[] passwordBytes = request.password.toBytes();
        byte[] hashedPassword = crypto:hashSha256(passwordBytes);
        string passwordHash = hashedPassword.toBase16();

        // Create passenger
        time:Civil now = time:utcToCivil(time:utcNow());
        string passengerId = uuid:createType1AsString();

        Passenger passenger = {
            passengerId: passengerId,
            username: request.username,
            email: request.email,
            passwordHash: passwordHash,
            firstName: request.firstName,
            lastName: request.lastName,
            phoneNumber: request.phoneNumber,
            createdAt: now,
            updatedAt: now,
            status: "active"
        };

        // Save to database
        check createPassenger(passenger);

        // Publish event to Kafka
        json eventPayload = {
            passengerId: passengerId,
            username: request.username,
            email: request.email
        };
        check publishPassengerEvent("PASSENGER_REGISTERED", passengerId, eventPayload);

        // Return response
        string createdAtStr = check time:civilToString(passenger.createdAt);
        return <PassengerResponse>{
            passengerId: passenger.passengerId,
            username: passenger.username,
            email: passenger.email,
            firstName: passenger.firstName,
            lastName: passenger.lastName,
            phoneNumber: passenger.phoneNumber,
            status: passenger.status,
            createdAt: createdAtStr
        };
    }

    // Login passenger
    resource function post login(@http:Payload LoginRequest request) returns LoginResponse|ErrorResponse|error {
        log:printInfo("Login request received for username: " + request.username);

        // Find passenger
        Passenger? passenger = check findPassengerByUsername(request.username);
        if passenger is () {
            return <ErrorResponse>{
                message: "Invalid username or password",
                'error: "AUTHENTICATION_FAILED",
                statusCode: 401
            };
        }

        // Verify password
        byte[] passwordBytes = request.password.toBytes();
        byte[] hashedPassword = crypto:hashSha256(passwordBytes);
        string passwordHash = hashedPassword.toBase16();

        if passenger.passwordHash != passwordHash {
            return <ErrorResponse>{
                message: "Invalid username or password",
                'error: "AUTHENTICATION_FAILED",
                statusCode: 401
            };
        }

        // Check if passenger is active
        if passenger.status != "active" {
            return <ErrorResponse>{
                message: "Account is not active",
                'error: "ACCOUNT_INACTIVE",
                statusCode: 403
            };
        }

        // Generate JWT token
        jwt:IssuerConfig issuerConfig = {
            username: passenger.username,
            issuer: JWT_ISSUER,
            audience: JWT_AUDIENCE,
            expTime: 86400,
            signatureConfig: {
                config: JWT_SECRET
            },
            customClaims: {
                "passengerId": passenger.passengerId,
                "email": passenger.email
            }
        };

        string token = check jwt:issue(issuerConfig);

        // Publish login event
        json eventPayload = {
            passengerId: passenger.passengerId,
            username: passenger.username,
            loginTime: time:utcNow()
        };
        check publishPassengerEvent("PASSENGER_LOGGED_IN", passenger.passengerId, eventPayload);

        return <LoginResponse>{
            token: token,
            passengerId: passenger.passengerId,
            username: passenger.username,
            email: passenger.email,
            message: "Login successful"
        };
    }

    // Get passenger profile
    resource function get [string passengerId](@http:Header string? Authorization) returns PassengerResponse|ErrorResponse|error {
        // Verify JWT token
        string|ErrorResponse authResult = check verifyToken(Authorization);
        if authResult is ErrorResponse {
            return authResult;
        }

        // Find passenger
        Passenger? passenger = check findPassengerById(passengerId);
        if passenger is () {
            return <ErrorResponse>{
                message: "Passenger not found",
                'error: "NOT_FOUND",
                statusCode: 404
            };
        }

        string createdAtStr = check time:civilToString(passenger.createdAt);
        return <PassengerResponse>{
            passengerId: passenger.passengerId,
            username: passenger.username,
            email: passenger.email,
            firstName: passenger.firstName,
            lastName: passenger.lastName,
            phoneNumber: passenger.phoneNumber,
            status: passenger.status,
            createdAt: createdAtStr
        };
    }

    // Get passenger tickets
    resource function get [string passengerId]/tickets(@http:Header string? Authorization) returns Ticket[]|ErrorResponse|error {
        // Verify JWT token
        string|ErrorResponse authResult = check verifyToken(Authorization);
        if authResult is ErrorResponse {
            return authResult;
        }

        // Find passenger
        Passenger? passenger = check findPassengerById(passengerId);
        if passenger is () {
            return <ErrorResponse>{
                message: "Passenger not found",
                'error: "NOT_FOUND",
                statusCode: 404
            };
        }

        // Get tickets
        Ticket[] tickets = check getPassengerTickets(passengerId);
        return tickets;
    }
}

// Verify JWT token
function verifyToken(string? authHeader) returns string|ErrorResponse|error {
    if authHeader is () {
        return <ErrorResponse>{
            message: "Authorization header is required",
            'error: "UNAUTHORIZED",
            statusCode: 401
        };
    }

    if !authHeader.startsWith("Bearer ") {
        return <ErrorResponse>{
            message: "Invalid authorization header format",
            'error: "UNAUTHORIZED",
            statusCode: 401
        };
    }

    string token = authHeader.substring(7);

    jwt:ValidatorConfig validatorConfig = {
        issuer: JWT_ISSUER,
        audience: JWT_AUDIENCE,
        signatureConfig: {
            secret: JWT_SECRET
        }
    };

    jwt:Payload|error payload = jwt:validate(token, validatorConfig);
    if payload is error {
        return <ErrorResponse>{
            message: "Invalid or expired token",
            'error: "UNAUTHORIZED",
            statusCode: 401
        };
    }

    return "authorized";
}