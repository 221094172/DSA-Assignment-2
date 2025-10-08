// database.bal
import ballerinax/mongodb;
import ballerina/log;
import ballerina/time;

configurable string mongoHost = ?;
configurable int mongoPort = ?;
configurable string mongoDatabase = ?;

mongodb:Client mongoClient = check new ({
    connection: {
        serverAddress: {
            host: mongoHost,
            port: mongoPort
        }
    }
});

// Get database
public function getDatabase() returns mongodb:Database|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    return db;
}

// ===== ROUTE OPERATIONS =====

// Create route
public function createRoute(Route route) returns error? {
    mongodb:Database db = check getDatabase();
    mongodb:Collection routesCollection = check db->getCollection("routes");
    check routesCollection->insertOne(route);
    log:printInfo("Route created: " + route.routeId);
}

// Find route by ID
public function findRouteById(string routeId) returns Route?|error {
    mongodb:Database db = check getDatabase();
    mongodb:Collection routesCollection = check db->getCollection("routes");
    map<json> filter = {"routeId": routeId};
    stream<Route, error?> resultStream = check routesCollection->find(filter);
    
    record {|Route value;|}? result = check resultStream.next();
    check resultStream.close();
    
    if result is record {|Route value;|} {
        return result.value;
    }
    return ();
}

// Find route by route number
public function findRouteByNumber(string routeNumber) returns Route?|error {
    mongodb:Database db = check getDatabase();
    mongodb:Collection routesCollection = check db->getCollection("routes");
    map<json> filter = {"routeNumber": routeNumber};
    stream<Route, error?> resultStream = check routesCollection->find(filter);
    
    record {|Route value;|}? result = check resultStream.next();
    check resultStream.close();
    
    if result is record {|Route value;|} {
        return result.value;
    }
    return ();
}

// Get all routes
public function getAllRoutes(string? status = ()) returns Route[]|error {
    mongodb:Database db = check getDatabase();
    mongodb:Collection routesCollection = check db->getCollection("routes");
    map<json> filter = {};
    
    if status is string {
        filter = {"status": status};
    }
    
    stream<Route, error?> resultStream = check routesCollection->find(filter);
    
    Route[] routes = [];
    check from Route route in resultStream
        do {
            routes.push(route);
        };
    
    check resultStream.close();
    return routes;
}

// Update route
public function updateRoute(string routeId, map<json> updates) returns error? {
    mongodb:Database db = check getDatabase();
    mongodb:Collection routesCollection = check db->getCollection("routes");
    map<json> filter = {"routeId": routeId};
    mongodb:Update update = {set: updates};
    _ = check routesCollection->updateOne(filter, update);
    log:printInfo("Route updated: " + routeId);
}

// Delete route
public function deleteRoute(string routeId) returns error? {
    mongodb:Database db = check getDatabase();
    mongodb:Collection routesCollection = check db->getCollection("routes");
    map<json> filter = {"routeId": routeId};
    _ = check routesCollection->deleteOne(filter);
    log:printInfo("Route deleted: " + routeId);
}

// ===== TRIP OPERATIONS =====

// Create trip
public function createTrip(Trip trip) returns error? {
    mongodb:Database db = check getDatabase();
    mongodb:Collection tripsCollection = check db->getCollection("trips");
    check tripsCollection->insertOne(trip);
    log:printInfo("Trip created: " + trip.tripId);
}

// Find trip by ID
public function findTripById(string tripId) returns Trip?|error {
    mongodb:Database db = check getDatabase();
    mongodb:Collection tripsCollection = check db->getCollection("trips");
    map<json> filter = {"tripId": tripId};
    stream<Trip, error?> resultStream = check tripsCollection->find(filter);
    
    record {|Trip value;|}? result = check resultStream.next();
    check resultStream.close();
    
    if result is record {|Trip value;|} {
        return result.value;
    }
    return ();
}

// Get all trips
public function getAllTrips(string? routeId = (), string? status = ()) returns Trip[]|error {
    mongodb:Database db = check getDatabase();
    mongodb:Collection tripsCollection = check db->getCollection("trips");
    map<json> filter = {};
    
    if routeId is string {
        filter["routeId"] = routeId;
    }
    
    if status is string {
        filter["status"] = status;
    }
    
    stream<Trip, error?> resultStream = check tripsCollection->find(filter);
    
    Trip[] trips = [];
    check from Trip trip in resultStream
        do {
            trips.push(trip);
        };
    
    check resultStream.close();
    return trips;
}

// Get trips by route
public function getTripsByRoute(string routeId) returns Trip[]|error {
    return getAllTrips(routeId);
}

// Get upcoming trips
public function getUpcomingTrips(string routeId) returns Trip[]|error {
    mongodb:Database db = check getDatabase();
    mongodb:Collection tripsCollection = check db->getCollection("trips");
    
    // Get current time
    time:Utc now = time:utcNow();
    time:Civil currentTime = time:utcToCivil(now);
    
    map<json> filter = {
        "routeId": routeId,
        "status": {"$in": ["scheduled", "in-progress"]}
    };
    
    stream<Trip, error?> resultStream = check tripsCollection->find(filter);
    
    Trip[] trips = [];
    check from Trip trip in resultStream
        do {
            trips.push(trip);
        };
    
    check resultStream.close();
    return trips;
}

// Update trip
public function updateTrip(string tripId, map<json> updates) returns error? {
    mongodb:Database db = check getDatabase();
    mongodb:Collection tripsCollection = check db->getCollection("trips");
    map<json> filter = {"tripId": tripId};
    mongodb:Update update = {set: updates};
    _ = check tripsCollection->updateOne(filter, update);
    log:printInfo("Trip updated: " + tripId);
}

// Update trip seats
public function updateTripSeats(string tripId, int seatsToBook) returns error? {
    mongodb:Database db = check getDatabase();
    mongodb:Collection tripsCollection = check db->getCollection("trips");
    map<json> filter = {"tripId": tripId};
    mongodb:Update update = {inc: {"availableSeats": -seatsToBook}};
    _ = check tripsCollection->updateOne(filter, update);
    log:printInfo("Trip seats updated: " + tripId);
}

// Delete trip
public function deleteTrip(string tripId) returns error? {
    mongodb:Database db = check getDatabase();
    mongodb:Collection tripsCollection = check db->getCollection("trips");
    map<json> filter = {"tripId": tripId};
    _ = check tripsCollection->deleteOne(filter);
    log:printInfo("Trip deleted: " + tripId);
}

// ===== STATISTICS =====

// Get route statistics
public function getRouteStatistics() returns RouteStatistics|error {
    Route[] allRoutes = check getAllRoutes();
    Route[] activeRoutes = check getAllRoutes("active");
    Route[] inactiveRoutes = check getAllRoutes("inactive");
    
    return {
        totalRoutes: allRoutes.length(),
        activeRoutes: activeRoutes.length(),
        inactiveRoutes: inactiveRoutes.length(),
        mostPopularRoute: allRoutes.length() > 0 ? allRoutes[0].routeNumber : "N/A"
    };
}

// Get trip statistics
public function getTripStatistics() returns TripStatistics|error {
    Trip[] allTrips = check getAllTrips();
    Trip[] scheduledTrips = check getAllTrips(status = "scheduled");
    Trip[] completedTrips = check getAllTrips(status = "completed");
    Trip[] delayedTrips = check getAllTrips(status = "delayed");
    Trip[] cancelledTrips = check getAllTrips(status = "cancelled");
    
    // Calculate average delay
    decimal totalDelay = 0.0;
    int delayCount = 0;
    
    foreach Trip trip in delayedTrips {
        int? delayMinutes = trip?.delayMinutes;
        if delayMinutes is int {
            totalDelay += <decimal>delayMinutes;
            delayCount += 1;
        }
    }
    
    decimal avgDelay = delayCount > 0 ? totalDelay / <decimal>delayCount : 0.0;
    
    return {
        totalTrips: allTrips.length(),
        scheduledTrips: scheduledTrips.length(),
        completedTrips: completedTrips.length(),
        delayedTrips: delayedTrips.length(),
        cancelledTrips: cancelledTrips.length(),
        averageDelayMinutes: avgDelay
    };
}