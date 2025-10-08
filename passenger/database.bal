// database.bal
import ballerina/log;
import ballerinax/mongodb;

// MongoDB configuration
configurable string mongoHost = ?;
configurable int mongoPort = ?;
configurable string mongoDatabase = ?;

// MongoDB client
final mongodb:Client mongoClient = check initializeMongoDB();

// Initialize MongoDB connection
function initializeMongoDB() returns mongodb:Client|error {
    mongodb:Client mongoDb = check new ({
        connection: {
            serverAddress: {
                host: mongoHost,
                port: mongoPort
            }
        }
    });

    log:printInfo("Connected to MongoDB successfully");
    return mongoDb;
}

// Create passenger
function createPassenger(Passenger passenger) returns error? {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection passengersCollection = check db->getCollection("passengers");
    check passengersCollection->insertOne(passenger);
    log:printInfo("Passenger created: " + passenger.passengerId);
}

// Find passenger by username
function findPassengerByUsername(string username) returns Passenger?|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection passengersCollection = check db->getCollection("passengers");
    
    map<json> filter = {"username": username};
    stream<Passenger, error?> result = check passengersCollection->find(filter);
    
    record {|Passenger value;|}? passenger = check result.next();
    check result.close();
    
    if passenger is record {|Passenger value;|} {
        return passenger.value;
    }
    return ();
}

// Find passenger by email
function findPassengerByEmail(string email) returns Passenger?|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection passengersCollection = check db->getCollection("passengers");
    
    map<json> filter = {"email": email};
    stream<Passenger, error?> result = check passengersCollection->find(filter);
    
    record {|Passenger value;|}? passenger = check result.next();
    check result.close();
    
    if passenger is record {|Passenger value;|} {
        return passenger.value;
    }
    return ();
}

// Find passenger by ID
function findPassengerById(string passengerId) returns Passenger?|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection passengersCollection = check db->getCollection("passengers");
    
    map<json> filter = {"passengerId": passengerId};
    stream<Passenger, error?> result = check passengersCollection->find(filter);
    
    record {|Passenger value;|}? passenger = check result.next();
    check result.close();
    
    if passenger is record {|Passenger value;|} {
        return passenger.value;
    }
    return ();
}

// Get passenger tickets
function getPassengerTickets(string passengerId) returns Ticket[]|error {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection ticketsCollection = check db->getCollection("tickets");
    
    map<json> filter = {"passengerId": passengerId};
    stream<Ticket, error?> result = check ticketsCollection->find(filter);
    
    Ticket[] tickets = [];
    check from Ticket ticket in result
        do {
            tickets.push(ticket);
        };
    check result.close();
    
    return tickets;
}

// Update passenger
function updatePassenger(string passengerId, map<json> updates) returns error? {
    mongodb:Database db = check mongoClient->getDatabase(mongoDatabase);
    mongodb:Collection passengersCollection = check db->getCollection("passengers");
    
    map<json> filter = {"passengerId": passengerId};
    mongodb:Update updateDoc = {set: updates};
    
    _ = check passengersCollection->updateOne(filter, updateDoc);
    log:printInfo("Passenger updated: " + passengerId);
}