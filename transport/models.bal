// models.bal
import ballerina/time;

// Route model
public type Route record {|
    string routeId;
    string routeNumber;
    string routeName;
    string transportType; // bus, train, metro
    string origin;
    string destination;
    Stop[] stops;
    decimal distance; // in kilometers
    int estimatedDuration; // in minutes
    decimal basePrice;
    string status; // active, inactive, suspended
    time:Civil createdAt;
    time:Civil updatedAt;
|};

// Stop model
public type Stop record {|
    string stopId;
    string stopName;
    decimal latitude;
    decimal longitude;
    int sequence;
    int arrivalOffset; // minutes from origin
|};

// Trip model
public type Trip record {|
    string tripId;
    string routeId;
    string vehicleId?;
    string driverId?;
    time:Civil scheduledDeparture;
    time:Civil scheduledArrival;
    time:Civil? actualDeparture?;
    time:Civil? actualArrival?;
    string status; // scheduled, in-progress, completed, delayed, cancelled
    int availableSeats;
    int totalSeats;
    decimal currentPrice;
    string? delayReason?;
    int? delayMinutes?;
    time:Civil createdAt;
    time:Civil updatedAt;
|};

// Route request
public type CreateRouteRequest record {|
    string routeNumber;
    string routeName;
    string transportType;
    string origin;
    string destination;
    Stop[] stops;
    decimal distance;
    int estimatedDuration;
    decimal basePrice;
|};

// Update route request
public type UpdateRouteRequest record {|
    string? routeName;
    Stop[]? stops;
    decimal? distance;
    int? estimatedDuration;
    decimal? basePrice;
    string? status;
|};

// Trip request
public type CreateTripRequest record {|
    string routeId;
    string? vehicleId;
    string? driverId;
    string scheduledDeparture; // ISO 8601 format
    string scheduledArrival;
    int totalSeats;
    decimal? currentPrice;
|};

// Update trip status request
public type UpdateTripStatusRequest record {|
    string status;
    string? delayReason;
    int? delayMinutes;
    string? actualDeparture;
    string? actualArrival;
|};

// Route response
public type RouteResponse record {|
    string routeId;
    string routeNumber;
    string routeName;
    string transportType;
    string origin;
    string destination;
    Stop[] stops;
    decimal distance;
    int estimatedDuration;
    decimal basePrice;
    string status;
    string createdAt;
    string updatedAt;
|};

// Trip response
public type TripResponse record {|
    string tripId;
    string routeId;
    string? vehicleId;
    string? driverId;
    string scheduledDeparture;
    string scheduledArrival;
    string? actualDeparture;
    string? actualArrival;
    string status;
    int availableSeats;
    int totalSeats;
    decimal currentPrice;
    string? delayReason;
    int? delayMinutes;
    string createdAt;
|};

// Schedule update event
public type ScheduleUpdateEvent record {|
    string eventId;
    string eventType; // TRIP_DELAYED, TRIP_CANCELLED, TRIP_RESCHEDULED
    string tripId;
    string routeId;
    time:Civil timestamp;
    string status;
    string? reason;
    int? delayMinutes;
    json metadata;
|};

// Route event
public type RouteEvent record {|
    string eventId;
    string eventType; // ROUTE_CREATED, ROUTE_UPDATED, ROUTE_DELETED
    string routeId;
    time:Civil timestamp;
    json payload;
|};

// Statistics response
public type RouteStatistics record {|
    int totalRoutes;
    int activeRoutes;
    int inactiveRoutes;
    string mostPopularRoute;
|};

public type TripStatistics record {|
    int totalTrips;
    int scheduledTrips;
    int completedTrips;
    int delayedTrips;
    int cancelledTrips;
    decimal averageDelayMinutes;
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