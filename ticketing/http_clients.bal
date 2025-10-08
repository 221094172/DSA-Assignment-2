// http_clients.bal
import ballerina/http;
import ballerina/log;

// Service configurations
configurable string passengerServiceHost = "passenger-service";
configurable int passengerServicePort = 9091;
configurable string transportServiceHost = "transport-service";
configurable int transportServicePort = 9092;
configurable string paymentServiceHost = "payment-service";
configurable int paymentServicePort = 9094;

// HTTP clients
final http:Client passengerServiceClient = check new (string `http://${passengerServiceHost}:${passengerServicePort}`);
final http:Client transportServiceClient = check new (string `http://${transportServiceHost}:${transportServicePort}`);
final http:Client paymentServiceClient = check new (string `http://${paymentServiceHost}:${paymentServicePort}`);

// Get passenger by ID from Passenger Service
public function getPassengerById(string passengerId) returns Passenger|error {
    log:printInfo(string `🔍 Fetching passenger: ${passengerId} from Passenger Service`);
    
    http:Response response = check passengerServiceClient->/api/passengers/[passengerId].get();
    
    if response.statusCode != 200 {
        return error(string `Failed to fetch passenger: ${response.statusCode}`);
    }
    
    json payload = check response.getJsonPayload();
    Passenger passenger = check payload.cloneWithType(Passenger);
    
    log:printInfo(string `✅ Passenger fetched: ${passenger.username}`);
    
    return passenger;
}

// Get trip by ID from Transport Service
public function getTripById(string tripId) returns Trip|error {
    log:printInfo(string `🔍 Fetching trip: ${tripId} from Transport Service`);
    
    http:Response response = check transportServiceClient->/api/trips/[tripId].get();
    
    if response.statusCode != 200 {
        return error(string `Failed to fetch trip: ${response.statusCode}`);
    }
    
    json payload = check response.getJsonPayload();
    Trip trip = check payload.cloneWithType(Trip);
    
    log:printInfo(string `✅ Trip fetched: ${trip.routeNumber} - ${trip.origin} to ${trip.destination}`);
    
    return trip;
}

// Verify payment with Payment Service (called by Payment Service)
public function verifyPayment(string paymentId) returns boolean|error {
    log:printInfo(string `🔍 Verifying payment: ${paymentId} with Payment Service`);
    
    http:Response response = check paymentServiceClient->/api/payments/[paymentId].get();
    
    if response.statusCode == 404 {
        return false;
    }
    
    if response.statusCode != 200 {
        return error(string `Failed to verify payment: ${response.statusCode}`);
    }
    
    json paymentJson = check response.getJsonPayload();
    string status = check paymentJson.status;
    
    return status == "completed";
}