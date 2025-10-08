// http_clients.bal
import ballerina/http;


configurable string passengerServiceHost = "passenger-service";
configurable int passengerServicePort = 9091;

configurable string transportServiceHost = "transport-service";
configurable int transportServicePort = 9092;

configurable string paymentServiceHost = "payment-service";
configurable int paymentServicePort = 9094;

configurable string ticketingServiceHost = "ticketing-service";
configurable int ticketingServicePort = 9095;

configurable string notificationServiceHost = "notification-service";
configurable int notificationServicePort = 9097;

// HTTP Clients
final http:Client passengerClient = check new (string `http://${passengerServiceHost}:${passengerServicePort}`);
final http:Client transportClient = check new (string `http://${transportServiceHost}:${transportServicePort}`);
final http:Client paymentClient = check new (string `http://${paymentServiceHost}:${paymentServicePort}`);
final http:Client ticketingClient = check new (string `http://${ticketingServiceHost}:${ticketingServicePort}`);
final http:Client notificationClient = check new (string `http://${notificationServiceHost}:${notificationServicePort}`);

// Call Passenger Service
public function callPassengerService(string path, string method = "GET", json? payload = ()) returns json|error {
    http:Response response;
    
    if method == "GET" {
        response = check passengerClient->get(path);
    } else if method == "POST" {
        response = check passengerClient->post(path, payload);
    } else if method == "PUT" {
        response = check passengerClient->put(path, payload);
    } else if method == "DELETE" {
        response = check passengerClient->delete(path);
    } else {
        return error("Unsupported HTTP method");
    }
    
    return check response.getJsonPayload();
}

// Call Transport Service
public function callTransportService(string path, string method = "GET", json? payload = ()) returns json|error {
    http:Response response;
    
    if method == "GET" {
        response = check transportClient->get(path);
    } else if method == "POST" {
        response = check transportClient->post(path, payload);
    } else if method == "PUT" {
        response = check transportClient->put(path, payload);
    } else if method == "DELETE" {
        response = check transportClient->delete(path);
    } else {
        return error("Unsupported HTTP method");
    }
    
    return check response.getJsonPayload();
}

// Call Payment Service
public function callPaymentService(string path, string method = "GET", json? payload = ()) returns json|error {
    http:Response response;
    
    if method == "GET" {
        response = check paymentClient->get(path);
    } else if method == "POST" {
        response = check paymentClient->post(path, payload);
    } else if method == "PUT" {
        response = check paymentClient->put(path, payload);
    } else if method == "DELETE" {
        response = check paymentClient->delete(path);
    } else {
        return error("Unsupported HTTP method");
    }
    
    return check response.getJsonPayload();
}

// Call Ticketing Service
public function callTicketingService(string path, string method = "GET", json? payload = ()) returns json|error {
    http:Response response;
    
    if method == "GET" {
        response = check ticketingClient->get(path);
    } else if method == "POST" {
        response = check ticketingClient->post(path, payload);
    } else if method == "PUT" {
        response = check ticketingClient->put(path, payload);
    } else if method == "DELETE" {
        response = check ticketingClient->delete(path);
    } else {
        return error("Unsupported HTTP method");
    }
    
    return check response.getJsonPayload();
}

// Call Notification Service
public function callNotificationService(string path, string method = "GET", json? payload = ()) returns json|error {
    http:Response response;
    
    if method == "GET" {
        response = check notificationClient->get(path);
    } else if method == "POST" {
        response = check notificationClient->post(path, payload);
    } else if method == "PUT" {
        response = check notificationClient->put(path, payload);
    } else if method == "DELETE" {
        response = check notificationClient->delete(path);
    } else {
        return error("Unsupported HTTP method");
    }
    
    return check response.getJsonPayload();
}