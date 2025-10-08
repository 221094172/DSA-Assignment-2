// models.bal
import ballerina/time;

// Admin User
public type AdminUser record {|
    string username;
    string role;
    string[] permissions;
|};

// Disruption
public type Disruption record {|
    string disruptionId;
    string title;
    string description;
    string severity; // low, medium, high, critical
    string[] affectedRoutes;
    string[] affectedTrips;
    time:Civil startTime;
    time:Civil? endTime?;
    string status; // active, resolved
    string createdBy;
    time:Civil createdAt;
|};

// Sales Report
public type SalesReport record {|
    time:Civil periodStart;
    time:Civil periodEnd;
    int totalTickets;
    decimal totalRevenue;
    map<int> ticketsByType;
    map<decimal> revenueByType;
    map<int> ticketsByRoute;
    map<int> ticketsByStatus;
    decimal averageTicketPrice;
|};

// Passenger Statistics
public type PassengerStats record {|
    int totalPassengers;
    int activePassengers;
    int newPassengersToday;
    int newPassengersThisWeek;
    int newPassengersThisMonth;
|};

// Route Statistics
public type RouteStats record {|
    int totalRoutes;
    int activeRoutes;
    int totalTrips;
    int activeTrips;
    map<int> tripsByRoute;
|};

// Payment Statistics
public type PaymentStats record {|
    decimal totalRevenue;
    decimal todayRevenue;
    decimal weekRevenue;
    decimal monthRevenue;
    int totalPayments;
    int successfulPayments;
    int failedPayments;
    decimal successRate;
    map<decimal> revenueByPaymentMethod;
|};

// System Statistics
public type SystemStats record {|
    PassengerStats passengers;
    RouteStats routes;
    PaymentStats payments;
    int totalNotifications;
    int totalValidations;
    time:Civil lastUpdated;
|};

// Route Management
public type RouteRequest record {|
    string routeNumber;
    string routeName;
    string origin;
    string destination;
    string[] stops;
    decimal basePrice;
    string transportType;
|};

// Trip Management
public type TripRequest record {|
    string routeId;
    time:Civil scheduledDeparture;
    time:Civil scheduledArrival;
    int availableSeats;
|};

// Disruption Request
public type DisruptionRequest record {|
    string title;
    string description;
    string severity;
    string[] affectedRoutes?;
    string[] affectedTrips?;
    time:Civil? endTime?;
|};

// Schedule Update Event
public type ScheduleUpdateEvent record {|
    string eventId;
    string eventType; // delay, cancellation, route_change
    string? routeId?;
    string? tripId?;
    string message;
    int delayMinutes?;
    time:Civil timestamp;
|};