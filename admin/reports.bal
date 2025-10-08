// reports.bal

import ballerina/time;
import ballerinax/mongodb;

// Generate sales report
public function generateSalesReport(time:Civil startDate, time:Civil endDate) returns SalesReport|error {
    mongodb:Database db = check getTicketsCollection();
    mongodb:Collection collection = check db->getCollection("tickets");
    
    // Query tickets in date range
    map<json> query = {
        "purchaseDate": {
            "$gte": startDate.toString(),
            "$lte": endDate.toString()
        }
    };
    
    stream<map<json>, error?> ticketsStream = check collection->find(query);
    
    int totalTickets = 0;
    decimal totalRevenue = 0.0;
    map<int> ticketsByType = {};
    map<decimal> revenueByType = {};
    map<int> ticketsByRoute = {};
    map<int> ticketsByStatus = {};
    
    check from map<json> ticket in ticketsStream
        do {
            totalTickets += 1;
            
            decimal price = check parseDecimal(ticket["price"].toString());
            totalRevenue += price;
            
            string ticketType = ticket["ticketType"].toString();
            ticketsByType[ticketType] = (ticketsByType[ticketType] ?: 0) + 1;
            revenueByType[ticketType] = (revenueByType[ticketType] ?: 0.0) + price;
            
            string routeId = ticket["routeId"].toString();
            ticketsByRoute[routeId] = (ticketsByRoute[routeId] ?: 0) + 1;
            
            string status = ticket["status"].toString();
            ticketsByStatus[status] = (ticketsByStatus[status] ?: 0) + 1;
        };
    
    decimal averageTicketPrice = totalTickets > 0 ? totalRevenue / <decimal>totalTickets : 0.0;
    
    return {
        periodStart: startDate,
        periodEnd: endDate,
        totalTickets: totalTickets,
        totalRevenue: totalRevenue,
        ticketsByType: ticketsByType,
        revenueByType: revenueByType,
        ticketsByRoute: ticketsByRoute,
        ticketsByStatus: ticketsByStatus,
        averageTicketPrice: averageTicketPrice
    };
}

// Get passenger statistics
public function getPassengerStatistics() returns PassengerStats|error {
    mongodb:Database db = check getPassengersCollection();
    mongodb:Collection collection = check db->getCollection("passengers");
    
    // Count total passengers
    int totalPassengers = check collection->countDocuments();
    
    // Count active passengers (logged in last 30 days)
    time:Utc thirtyDaysAgo = time:utcAddSeconds(time:utcNow(), -30 * 24 * 60 * 60);
    int activePassengers = check collection->countDocuments({
        "lastLogin": {"$gte": thirtyDaysAgo.toString()}
    });
    
    // Count new passengers today
    time:Civil today = time:utcToCivil(time:utcNow());
    today.hour = 0;
    today.minute = 0;
    today.second = 0;
    
    int newPassengersToday = check collection->countDocuments({
        "createdAt": {"$gte": today.toString()}
    });
    
    // Count new passengers this week
    time:Utc weekAgo = time:utcAddSeconds(time:utcNow(), -7 * 24 * 60 * 60);
    int newPassengersThisWeek = check collection->countDocuments({
        "createdAt": {"$gte": weekAgo.toString()}
    });
    
    // Count new passengers this month
    time:Utc monthAgo = time:utcAddSeconds(time:utcNow(), -30 * 24 * 60 * 60);
    int newPassengersThisMonth = check collection->countDocuments({
        "createdAt": {"$gte": monthAgo.toString()}
    });
    
    return {
        totalPassengers: totalPassengers,
        activePassengers: activePassengers,
        newPassengersToday: newPassengersToday,
        newPassengersThisWeek: newPassengersThisWeek,
        newPassengersThisMonth: newPassengersThisMonth
    };
}

// Get route statistics
public function getRouteStatistics() returns RouteStats|error {
    mongodb:Database db = check getRoutesCollection();
    mongodb:Collection routesCollection = check db->getCollection("routes");
    
    int totalRoutes = check routesCollection->countDocuments();
    int activeRoutes = check routesCollection->countDocuments({"status": "active"});
    
    mongodb:Database tripsDb = check getTripsCollection();
    mongodb:Collection tripsCollection = check tripsDb->getCollection("trips");
    int totalTrips = check tripsCollection->countDocuments();
    int activeTrips = check tripsCollection->countDocuments({"status": "scheduled"});
    
    // Get trips by route
    stream<map<json>, error?> tripsStream = check tripsCollection->find();
    
    map<int> tripsByRoute = {};
    
    check from map<json> trip in tripsStream
        do {
            string routeId = trip["routeId"].toString();
            tripsByRoute[routeId] = (tripsByRoute[routeId] ?: 0) + 1;
        };
    
    return {
        totalRoutes: totalRoutes,
        activeRoutes: activeRoutes,
        totalTrips: totalTrips,
        activeTrips: activeTrips,
        tripsByRoute: tripsByRoute
    };
}

// Get payment statistics
public function getPaymentStatistics() returns PaymentStats|error {
    mongodb:Database db = check getPaymentsCollection();
    mongodb:Collection collection = check db->getCollection("payments");
    
    int totalPayments = check collection->countDocuments();
    int successfulPayments = check collection->countDocuments({"status": "completed"});
    int failedPayments = check collection->countDocuments({"status": "failed"});
    
    decimal successRate = totalPayments > 0 ? 
        (<decimal>successfulPayments / <decimal>totalPayments) * 100.0 : 0.0;
    
    // Calculate revenue
    stream<map<json>, error?> paymentsStream = check collection->find({"status": "completed"});
    
    decimal totalRevenue = 0.0;
    decimal todayRevenue = 0.0;
    decimal weekRevenue = 0.0;
    decimal monthRevenue = 0.0;
    map<decimal> revenueByPaymentMethod = {};
    
    time:Civil today = time:utcToCivil(time:utcNow());
    today.hour = 0;
    today.minute = 0;
    today.second = 0;
    
    time:Utc weekAgo = time:utcAddSeconds(time:utcNow(), -7 * 24 * 60 * 60);
    time:Utc monthAgo = time:utcAddSeconds(time:utcNow(), -30 * 24 * 60 * 60);
    
    check from map<json> payment in paymentsStream
        do {
            decimal amount = check parseDecimal(payment["amount"].toString());
            totalRevenue += amount;
            
            string paymentDate = payment["processedAt"].toString();
            time:Civil paymentCivil = check time:civilFromString(paymentDate);
            
            if (paymentCivil.year == today.year && 
                paymentCivil.month == today.month && 
                paymentCivil.day == today.day) {
                todayRevenue += amount;
            }
            
            time:Utc paymentUtc = check time:utcFromCivil(paymentCivil);
            decimal weekDiff = time:utcDiffSeconds(time:utcNow(), paymentUtc);
            if (weekDiff <= <decimal>(7 * 24 * 60 * 60)) {
                weekRevenue += amount;
            }
            
            decimal monthDiff = time:utcDiffSeconds(time:utcNow(), paymentUtc);
            if (monthDiff <= <decimal>(30 * 24 * 60 * 60)) {
                monthRevenue += amount;
            }
            
            string method = payment["paymentMethod"].toString();
            revenueByPaymentMethod[method] = (revenueByPaymentMethod[method] ?: 0.0) + amount;
        };
    
    return {
        totalRevenue: totalRevenue,
        todayRevenue: todayRevenue,
        weekRevenue: weekRevenue,
        monthRevenue: monthRevenue,
        totalPayments: totalPayments,
        successfulPayments: successfulPayments,
        failedPayments: failedPayments,
        successRate: successRate,
        revenueByPaymentMethod: revenueByPaymentMethod
    };
}

// Get system statistics
public function getSystemStatistics() returns SystemStats|error {
    PassengerStats passengers = check getPassengerStatistics();
    RouteStats routes = check getRouteStatistics();
    PaymentStats payments = check getPaymentStatistics();
    
    mongodb:Database notifDb = check getNotificationsCollection();
    mongodb:Collection notifCollection = check notifDb->getCollection("notifications");
    int totalNotifications = check notifCollection->countDocuments();
    
    mongodb:Database validDb = check getValidationsCollection();
    mongodb:Collection validCollection = check validDb->getCollection("validations");
    int totalValidations = check validCollection->countDocuments();
    
    return {
        passengers: passengers,
        routes: routes,
        payments: payments,
        totalNotifications: totalNotifications,
        totalValidations: totalValidations,
        lastUpdated: time:utcToCivil(time:utcNow())
    };
}

// Helper function to parse decimal
function parseDecimal(string value) returns decimal|error {
    return check decimal:fromString(value);
}