// service.bal
import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;

configurable int serverPort = 9096;

listener http:Listener httpListener = new (serverPort);

// Admin Service
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"],
        maxAge: 3600
    }
}
service /api/admin on httpListener {
    
    // Health check
    resource function get health() returns json {
        return {
            status: "UP",
            'service: "admin-service",
            timestamp: time:utcNow()
        };
    }
    
    // ========== DASHBOARD ==========
    
    // Get dashboard statistics
    resource function get dashboard/stats() returns SystemStats|http:InternalServerError {
        SystemStats|error stats = getSystemStatistics();
        
        if stats is error {
            log:printError("Error getting system statistics", stats);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to retrieve system statistics",
                    'error: stats.message()
                }
            };
        }
        
        return stats;
    }
    
    // ========== REPORTS ==========
    
    // Get sales report
    resource function get reports/sales(string startDate, string endDate) 
            returns SalesReport|http:BadRequest|http:InternalServerError {
        
        time:Civil|error startResult = time:civilFromString(startDate);
        time:Civil|error endResult = time:civilFromString(endDate);
        
        if startResult is error || endResult is error {
            return <http:BadRequest>{
                body: {
                    message: "Invalid date format. Use YYYY-MM-DD"
                }
            };
        }
        
        SalesReport|error report = generateSalesReport(startResult, endResult);
        
        if report is error {
            log:printError("Error generating sales report", report);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to generate sales report",
                    'error: report.message()
                }
            };
        }
        
        return report;
    }
    
    // Get passenger report
    resource function get reports/passengers() returns PassengerStats|http:InternalServerError {
        PassengerStats|error stats = getPassengerStatistics();
        
        if stats is error {
            log:printError("Error generating passenger report", stats);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to generate passenger report",
                    'error: stats.message()
                }
            };
        }
        
        return stats;
    }
    
    // Get route report
    resource function get reports/routes() returns RouteStats|http:InternalServerError {
        RouteStats|error stats = getRouteStatistics();
        
        if stats is error {
            log:printError("Error generating route report", stats);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to generate route report",
                    'error: stats.message()
                }
            };
        }
        
        return stats;
    }
    
    // Get payment report
    resource function get reports/payments() returns PaymentStats|http:InternalServerError {
        PaymentStats|error stats = getPaymentStatistics();
        
        if stats is error {
            log:printError("Error generating payment report", stats);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to generate payment report",
                    'error: stats.message()
                }
            };
        }
        
        return stats;
    }
    
    // ========== ROUTE MANAGEMENT ==========
    
    // Create route
    resource function post routes(@http:Payload json request) 
            returns json|http:BadRequest|http:InternalServerError {
        
        json|error result = callTransportService("/api/transport/routes", "POST", request);
        
        if result is error {
            log:printError("Error creating route", result);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to create route",
                    'error: result.message()
                }
            };
        }
        
        // Publish system event
        error? eventError = publishSystemEvent("route_created", result);
        if eventError is error {
            log:printError("Error publishing route created event", eventError);
        }
        
        return result;
    }
    
    // Get all routes
    resource function get routes() returns json|http:InternalServerError {
        json|error result = callTransportService("/api/transport/routes");
        
        if result is error {
            log:printError("Error getting routes", result);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to retrieve routes",
                    'error: result.message()
                }
            };
        }
        
        return result;
    }
    
    // Update route
    resource function put routes/[string routeId](@http:Payload json request) 
            returns json|http:BadRequest|http:InternalServerError {
        
        json|error result = callTransportService(string `/api/transport/routes/${routeId}`, "PUT", request);
        
        if result is error {
            log:printError("Error updating route", result);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to update route",
                    'error: result.message()
                }
            };
        }
        
        // Publish system event
        error? eventError = publishSystemEvent("route_updated", result);
        if eventError is error {
            log:printError("Error publishing route updated event", eventError);
        }
        
        return result;
    }
    
    // Delete route
    resource function delete routes/[string routeId]() returns json|http:InternalServerError {
        json|error result = callTransportService(string `/api/transport/routes/${routeId}`, "DELETE");
        
        if result is error {
            log:printError("Error deleting route", result);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to delete route",
                    'error: result.message()
                }
            };
        }
        
        // Publish system event
        error? eventError = publishSystemEvent("route_deleted", {routeId: routeId});
        if eventError is error {
            log:printError("Error publishing route deleted event", eventError);
        }
        
        return result;
    }
    
    // ========== TRIP MANAGEMENT ==========
    
    // Create trip
    resource function post trips(@http:Payload TripRequest request) 
            returns json|http:BadRequest|http:InternalServerError {
        
        json|error result = callTransportService("/api/transport/trips", "POST", request.toJson());
        
        if result is error {
            log:printError("Error creating trip", result);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to create trip",
                    'error: result.message()
                }
            };
        }
        
        // Publish system event
        error? eventError = publishSystemEvent("trip_created", result);
        if eventError is error {
            log:printError("Error publishing trip created event", eventError);
        }
        
        return result;
    }
    
    // Get all trips
    resource function get trips(string? routeId = (), string? status = ()) 
            returns json|http:InternalServerError {
        
        string path = "/api/transport/trips";
        string[] queryParams = [];
        
        if routeId is string {
            queryParams.push(string `routeId=${routeId}`);
        }
        if status is string {
            queryParams.push(string `status=${status}`);
        }
        
        if queryParams.length() > 0 {
            path = path + "?" + string:'join("&", ...queryParams);
        }
        
        json|error result = callTransportService(path);
        
        if result is error {
            log:printError("Error getting trips", result);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to retrieve trips",
                    'error: result.message()
                }
            };
        }
        
        return result;
    }
    
    // Update trip
    resource function put trips/[string tripId](@http:Payload json request) 
            returns json|http:BadRequest|http:InternalServerError {
        
        json|error result = callTransportService(string `/api/transport/trips/${tripId}`, "PUT", request);
        
        if result is error {
            log:printError("Error updating trip", result);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to update trip",
                    'error: result.message()
                }
            };
        }
        
        // Publish system event
        error? eventError = publishSystemEvent("trip_updated", result);
        if eventError is error {
            log:printError("Error publishing trip updated event", eventError);
        }
        
        return result;
    }
    
    // Cancel trip
    resource function put trips/[string tripId]/cancel() returns json|http:InternalServerError {
        json|error result = callTransportService(string `/api/transport/trips/${tripId}/cancel`, "PUT");
        
        if result is error {
            log:printError("Error cancelling trip", result);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to cancel trip",
                    'error: result.message()
                }
            };
        }
        
        // Publish schedule update
        ScheduleUpdateEvent event = {
            eventId: uuid:createType1AsString(),
            eventType: "cancellation",
            tripId: tripId,
            message: "Trip has been cancelled",
            timestamp: time:utcToCivil(time:utcNow())
        };
        
        error? eventError = publishScheduleUpdate(event);
        if eventError is error {
            log:printError("Error publishing schedule update", eventError);
        }
        
        return result;
    }
    
    // ========== DISRUPTIONS ==========
    
    // Publish disruption
    resource function post disruptions(@http:Payload DisruptionRequest request) 
            returns json|http:BadRequest|http:InternalServerError {
        
        Disruption disruption = {
            disruptionId: uuid:createType1AsString(),
            title: request.title,
            affectedRoutes: request.affectedRoutes ?: [],
            affectedTrips: request.affectedTrips ?: [],
            severity: request.severity,
            description: request.description,
            startTime: time:utcToCivil(time:utcNow()),
            endTime: request?.endTime,
            status: "active",
            createdAt: time:utcToCivil(time:utcNow()),
            createdBy: "admin"
        };
        
        error? publishError = publishDisruption(disruption);
        
        if publishError is error {
            log:printError("Error publishing disruption", publishError);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to publish disruption",
                    'error: publishError.message()
                }
            };
        }
        
        log:printInfo(string `📢 Disruption published: ${disruption.disruptionId}`);
        
        return disruption.toJson();
    }
    
    // ========== PASSENGERS ==========
    
    // Get all passengers
    resource function get passengers() returns json|http:InternalServerError {
        json|error result = callPassengerService("/api/passengers");
        
        if result is error {
            log:printError("Error getting passengers", result);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to retrieve passengers",
                    'error: result.message()
                }
            };
        }
        
        return result;
    }
    
    // Get passenger by ID
    resource function get passengers/[string passengerId]() returns json|http:InternalServerError {
        json|error result = callPassengerService(string `/api/passengers/${passengerId}`);
        
        if result is error {
            log:printError("Error getting passenger", result);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to retrieve passenger",
                    'error: result.message()
                }
            };
        }
        
        return result;
    }
    
    // ========== TICKETS ==========
    
    // Get all tickets
    resource function get tickets(string? status = ()) returns json|http:InternalServerError {
        string path = "/api/tickets";
        if status is string {
            path = path + string `?status=${status}`;
        }
        
        json|error result = callTicketingService(path);
        
        if result is error {
            log:printError("Error getting tickets", result);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to retrieve tickets",
                    'error: result.message()
                }
            };
        }
        
        return result;
    }
    
    // Get ticket statistics
    resource function get tickets/stats() returns json|http:InternalServerError {
        json|error result = callTicketingService("/api/tickets/stats");
        
        if result is error {
            log:printError("Error getting ticket statistics", result);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to retrieve ticket statistics",
                    'error: result.message()
                }
            };
        }
        
        return result;
    }
    
    // ========== PAYMENTS ==========
    
    // Get all payments
    resource function get payments() returns json|http:InternalServerError {
        json|error result = callPaymentService("/api/payments");
        
        if result is error {
            log:printError("Error getting payments", result);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to retrieve payments",
                    'error: result.message()
                }
            };
        }
        
        return result;
    }
    
    // Get payment statistics
    resource function get payments/stats() returns json|http:InternalServerError {
        json|error result = callPaymentService("/api/payments/stats");
        
        if result is error {
            log:printError("Error getting payment statistics", result);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to retrieve payment statistics",
                    'error: result.message()
                }
            };
        }
        
        return result;
    }
    
    // ========== NOTIFICATIONS ==========
    
    // Get all notifications
    resource function get notifications() returns json|http:InternalServerError {
        json|error result = callNotificationService("/api/notifications");
        
        if result is error {
            log:printError("Error getting notifications", result);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to retrieve notifications",
                    'error: result.message()
                }
            };
        }
        
        return result;
    }
    
    // Send notification
    resource function post notifications(@http:Payload json request) 
            returns json|http:BadRequest|http:InternalServerError {
        
        json|error result = callNotificationService("/api/notifications", "POST", request);
        
        if result is error {
            log:printError("Error sending notification", result);
            return <http:InternalServerError>{
                body: {
                    message: "Failed to send notification",
                    'error: result.message()
                }
            };
        }
        
        return result;
    }
    
}

// Separate service for serving frontend static files
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    }
}
service / on httpListener {
    resource function get .() returns http:Response|error {
        http:Response response = new;
        response.setFileAsPayload("frontend/index.html", contentType = "text/html");
        return response;
    }
    
    resource function get [string... paths]() returns http:Response|error {
        string filePath = string:'join("/", "frontend", ...paths);
        http:Response response = new;
        
        if filePath.endsWith(".css") {
            response.setFileAsPayload(filePath, contentType = "text/css");
        } else if filePath.endsWith(".js") {
            response.setFileAsPayload(filePath, contentType = "application/javascript");
        } else if filePath.endsWith(".png") {
            response.setFileAsPayload(filePath, contentType = "image/png");
        } else if filePath.endsWith(".jpg") || filePath.endsWith(".jpeg") {
            response.setFileAsPayload(filePath, contentType = "image/jpeg");
        } else {
            response.setFileAsPayload(filePath);
        }
        
        return response;
    }
}