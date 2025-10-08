// service.bal
import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;

configurable int servicePort = ?;
configurable string serviceHost = ?;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        maxAge: 84900
    }
}

service /api/transport on new http:Listener(servicePort) {

    // Health check
    resource function get health() returns json {
        time:Utc currentTime = time:utcNow();
        string|time:Error timestamp = time:utcToString(currentTime);
        return {
            status: "UP",
            "service": "transport-service",
            timestamp: timestamp is string ? timestamp : "N/A"
        };
    }

    // ===== ROUTE ENDPOINTS =====

    // Create route
    resource function post routes(@http:Payload CreateRouteRequest request) 
            returns RouteResponse|ErrorResponse|error {
        log:printInfo("Create route request received: " + request.routeNumber);

        // Validate
        if request.routeNumber.length() == 0 {
            return <ErrorResponse>{
                message: "Route number is required",
                'error: "VALIDATION_ERROR",
                statusCode: 400
            };
        }

        // Check if route number exists
        Route? existingRoute = check findRouteByNumber(request.routeNumber);
        if existingRoute is Route {
            return <ErrorResponse>{
                message: "Route number already exists",
                'error: "DUPLICATE_ROUTE",
                statusCode: 409
            };
        }

        // Create route
        time:Civil now = time:utcToCivil(time:utcNow());
        string routeId = uuid:createType1AsString();

        Route route = {
            routeId: routeId,
            routeNumber: request.routeNumber,
            routeName: request.routeName,
            transportType: request.transportType,
            origin: request.origin,
            destination: request.destination,
            stops: request.stops,
            distance: request.distance,
            estimatedDuration: request.estimatedDuration,
            basePrice: request.basePrice,
            status: "active",
            createdAt: now,
            updatedAt: now
        };

        check createRoute(route);

        // Publish event
        json eventPayload = {
            routeId: routeId,
            routeNumber: request.routeNumber,
            routeName: request.routeName,
            transportType: request.transportType
        };
        check publishRouteEvent("ROUTE_CREATED", routeId, eventPayload);

        return mapRouteToResponse(route);
    }

    // Get all routes
    resource function get routes(string? status = ()) returns RouteResponse[]|ErrorResponse|error {
        log:printInfo("Get routes request received");

        Route[] routes = check getAllRoutes(status);
        
        RouteResponse[] response = routes.map(route => mapRouteToResponse(route));
        return response;
    }

    // Get route by ID
    resource function get routes/[string routeId]() returns RouteResponse|ErrorResponse|error {
        log:printInfo("Get route request: " + routeId);

        Route? route = check findRouteById(routeId);
        
        if route is () {
            return <ErrorResponse>{
                message: "Route not found",
                'error: "NOT_FOUND",
                statusCode: 404
            };
        }

        return mapRouteToResponse(route);
    }

    // Update route
    resource function put routes/[string routeId](@http:Payload UpdateRouteRequest request) 
            returns RouteResponse|ErrorResponse|error {
        log:printInfo("Update route request: " + routeId);

        Route? existingRoute = check findRouteById(routeId);
        
        if existingRoute is () {
            return <ErrorResponse>{
                message: "Route not found",
                'error: "NOT_FOUND",
                statusCode: 404
            };
        }

        // Build update map
        time:Civil updateTime = time:utcToCivil(time:utcNow());
        string|time:Error updateTimeStr = time:civilToString(updateTime);
        
        map<json> updates = {
            "updatedAt": updateTimeStr is string ? updateTimeStr : ""
        };

        if request.routeName is string {
            updates["routeName"] = request.routeName;
        }
        if request.stops is string[] {
            updates["stops"] = request.stops;
        }
        if request.distance is decimal {
            updates["distance"] = request.distance;
        }
        if request.estimatedDuration is int {
            updates["estimatedDuration"] = request.estimatedDuration;
        }
        if request.basePrice is decimal {
            updates["basePrice"] = request.basePrice;
        }
        if request.status is string {
            updates["status"] = request.status;
        }

        check updateRoute(routeId, updates);

        // Publish event
        json eventPayload = {
            routeId: routeId,
            updates: updates
        };
        check publishRouteEvent("ROUTE_UPDATED", routeId, eventPayload);

        Route? updatedRoute = check findRouteById(routeId);
        if updatedRoute is Route {
            return mapRouteToResponse(updatedRoute);
        }

        return <ErrorResponse>{
            message: "Failed to retrieve updated route",
            'error: "INTERNAL_ERROR",
            statusCode: 500
        };
    }

    // Delete route
    resource function delete routes/[string routeId]() returns SuccessResponse|ErrorResponse|error {
        log:printInfo("Delete route request: " + routeId);

        Route? route = check findRouteById(routeId);
        
        if route is () {
            return <ErrorResponse>{
                message: "Route not found",
                'error: "NOT_FOUND",
                statusCode: 404
            };
        }

        check deleteRoute(routeId);

        // Publish event
        json eventPayload = {
            routeId: routeId,
            routeNumber: route.routeNumber
        };
        check publishRouteEvent("ROUTE_DELETED", routeId, eventPayload);

        return <SuccessResponse>{
            message: "Route deleted successfully",
            data: {"routeId": routeId}
        };
    }

    // ===== TRIP ENDPOINTS =====

    // Create trip
    resource function post trips(@http:Payload CreateTripRequest request) 
            returns TripResponse|ErrorResponse|error {
        log:printInfo("Create trip request for route: " + request.routeId);

        // Validate route exists
        Route? route = check findRouteById(request.routeId);
        if route is () {
            return <ErrorResponse>{
                message: "Route not found",
                'error: "ROUTE_NOT_FOUND",
                statusCode: 404
            };
        }

        // Parse datetime
        time:Civil scheduledDeparture = check time:civilFromString(request.scheduledDeparture);
        time:Civil scheduledArrival = check time:civilFromString(request.scheduledArrival);

        // Create trip
        time:Civil now = time:utcToCivil(time:utcNow());
        string tripId = uuid:createType1AsString();

        decimal price = request.currentPrice is decimal ? 
            <decimal>request.currentPrice : route.basePrice;

        Trip trip = {
            tripId: tripId,
            routeId: request.routeId,
            vehicleId: request.vehicleId,
            driverId: request.driverId,
            scheduledDeparture: scheduledDeparture,
            scheduledArrival: scheduledArrival,
            status: "scheduled",
            availableSeats: request.totalSeats,
            totalSeats: request.totalSeats,
            currentPrice: price,
            createdAt: now,
            updatedAt: now
        };

        check createTrip(trip);

        return mapTripToResponse(trip);
    }

    // Get all trips
    resource function get trips(string? routeId = (), string? status = ()) 
            returns TripResponse[]|ErrorResponse|error {
        log:printInfo("Get trips request");

        Trip[] trips = check getAllTrips(routeId, status);
        
        TripResponse[] response = trips.map(trip => mapTripToResponse(trip));
        return response;
    }

    // Get trip by ID
    resource function get trips/[string tripId]() returns TripResponse|ErrorResponse|error {
        log:printInfo("Get trip request: " + tripId);

        Trip? trip = check findTripById(tripId);
        
        if trip is () {
            return <ErrorResponse>{
                message: "Trip not found",
                'error: "NOT_FOUND",
                statusCode: 404
            };
        }

        return mapTripToResponse(trip);
    }

    // Update trip status
    resource function put trips/[string tripId]/status(@http:Payload UpdateTripStatusRequest request) 
            returns TripResponse|ErrorResponse|error {
        log:printInfo("Update trip status: " + tripId + " to " + request.status);

        Trip? existingTrip = check findTripById(tripId);
        
        if existingTrip is () {
            return <ErrorResponse>{
                message: "Trip not found",
                'error: "NOT_FOUND",
                statusCode: 404
            };
        }

        // Build updates
        time:Civil updateTime = time:utcToCivil(time:utcNow());
        string|time:Error updateTimeStr = time:civilToString(updateTime);
        
        map<json> updates = {
            "status": request.status,
            "updatedAt": updateTimeStr is string ? updateTimeStr : ""
        };

        if request.delayReason is string {
            updates["delayReason"] = request.delayReason;
        }
        if request.delayMinutes is int {
            updates["delayMinutes"] = request.delayMinutes;
        }
        if request.actualDeparture is string {
            time:Civil actualDep = check time:civilFromString(<string>request.actualDeparture);
            string|time:Error actualDepStr = time:civilToString(actualDep);
            updates["actualDeparture"] = actualDepStr is string ? actualDepStr : "";
        }
        if request.actualArrival is string {
            time:Civil actualArr = check time:civilFromString(<string>request.actualArrival);
            string|time:Error actualArrStr = time:civilToString(actualArr);
            updates["actualArrival"] = actualArrStr is string ? actualArrStr : "";
        }

        check updateTrip(tripId, updates);

        // Publish schedule update for delays/cancellations
        if request.status == "delayed" || request.status == "cancelled" {
            string eventType = request.status == "delayed" ? 
                "TRIP_DELAYED" : "TRIP_CANCELLED";
            
            string|time:Error scheduledDepStr = time:civilToString(existingTrip.scheduledDeparture);
            
            json metadata = {
                "tripId": tripId,
                "routeId": existingTrip.routeId,
                "scheduledDeparture": scheduledDepStr is string ? scheduledDepStr : "",
                "oldStatus": existingTrip.status
            };

            check publishScheduleUpdate(
                eventType,
                tripId,
                existingTrip.routeId,
                request.status,
                request.delayReason,
                request.delayMinutes,
                metadata
            );
        }

        Trip? updatedTrip = check findTripById(tripId);
        if updatedTrip is Trip {
            return mapTripToResponse(updatedTrip);
        }

        return <ErrorResponse>{
            message: "Failed to retrieve updated trip",
            'error: "INTERNAL_ERROR",
            statusCode: 500
        };
    }

    // Get upcoming trips for a route
    resource function get routes/[string routeId]/trips/upcoming() 
            returns TripResponse[]|ErrorResponse|error {
        log:printInfo("Get upcoming trips for route: " + routeId);

        Route? route = check findRouteById(routeId);
        if route is () {
            return <ErrorResponse>{
                message: "Route not found",
                'error: "NOT_FOUND",
                statusCode: 404
            };
        }

        Trip[] trips = check getUpcomingTrips(routeId);
        
        TripResponse[] response = trips.map(trip => mapTripToResponse(trip));
        return response;
    }

    // Delete trip
    resource function delete trips/[string tripId]() returns SuccessResponse|ErrorResponse|error {
        log:printInfo("Delete trip request: " + tripId);

        Trip? trip = check findTripById(tripId);
        
        if trip is () {
            return <ErrorResponse>{
                message: "Trip not found",
                'error: "NOT_FOUND",
                statusCode: 404
            };
        }

        check deleteTrip(tripId);

        return <SuccessResponse>{
            message: "Trip deleted successfully",
            data: {"tripId": tripId}
        };
    }

    // ===== STATISTICS ENDPOINTS =====

    // Get route statistics
    resource function get statistics/routes() returns RouteStatistics|ErrorResponse|error {
        log:printInfo("Get route statistics");
        return check getRouteStatistics();
    }

    // Get trip statistics
    resource function get statistics/trips() returns TripStatistics|ErrorResponse|error {
        log:printInfo("Get trip statistics");
        return check getTripStatistics();
    }
}

// ===== HELPER FUNCTIONS =====

function mapRouteToResponse(Route route) returns RouteResponse {
    string|time:Error createdAtStr = time:civilToString(route.createdAt);
    string|time:Error updatedAtStr = time:civilToString(route.updatedAt);
    
    return {
        routeId: route.routeId,
        routeNumber: route.routeNumber,
        routeName: route.routeName,
        transportType: route.transportType,
        origin: route.origin,
        destination: route.destination,
        stops: route.stops,
        distance: route.distance,
        estimatedDuration: route.estimatedDuration,
        basePrice: route.basePrice,
        status: route.status,
        createdAt: createdAtStr is string ? createdAtStr : "",
        updatedAt: updatedAtStr is string ? updatedAtStr : ""
    };
}

function mapTripToResponse(Trip trip) returns TripResponse {
    string|time:Error scheduledDepStr = time:civilToString(trip.scheduledDeparture);
    string|time:Error scheduledArrStr = time:civilToString(trip.scheduledArrival);
    string|time:Error createdAtStr = time:civilToString(trip.createdAt);
    
    string? actualDepartureStr = ();
    if trip?.actualDeparture is time:Civil {
        string|time:Error result = time:civilToString(<time:Civil>trip?.actualDeparture);
        actualDepartureStr = result is string ? result : ();
    }
    
    string? actualArrivalStr = ();
    if trip?.actualArrival is time:Civil {
        string|time:Error result = time:civilToString(<time:Civil>trip?.actualArrival);
        actualArrivalStr = result is string ? result : ();
    }

    return {
        tripId: trip.tripId,
        routeId: trip.routeId,
        vehicleId: trip.vehicleId,
        driverId: trip.driverId,
        scheduledDeparture: scheduledDepStr is string ? scheduledDepStr : "",
        scheduledArrival: scheduledArrStr is string ? scheduledArrStr : "",
        actualDeparture: actualDepartureStr,
        actualArrival: actualArrivalStr,
        status: trip.status,
        availableSeats: trip.availableSeats,
        totalSeats: trip.totalSeats,
        currentPrice: trip.currentPrice,
        delayReason: trip?.delayReason,
        delayMinutes: trip?.delayMinutes,
        createdAt: createdAtStr is string ? createdAtStr : ""
    };
}