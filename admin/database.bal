// database.bal
import ballerina/log;
import ballerinax/mongodb;

configurable string mongoHost = "mongodb";
configurable int mongoPort = 27017;
configurable string mongoDatabase = "transport_ticketing_system";

final mongodb:Client mongoClient = check initMongoClient();

function initMongoClient() returns mongodb:Client|error {
    mongodb:Client mongoClient = check new ({
        connection: {
            serverAddress: {
                host: mongoHost,
                port: mongoPort
            }
        }
    });
    log:printInfo("Connected to MongoDB successfully");
    return mongoClient;
}

// Get passengers collection
function getPassengersCollection() returns mongodb:Database|error {
    return mongoClient->getDatabase(mongoDatabase);
}

// Get routes collection
function getRoutesCollection() returns mongodb:Database|error {
    return mongoClient->getDatabase(mongoDatabase);
}

// Get trips collection
function getTripsCollection() returns mongodb:Database|error {
    return mongoClient->getDatabase(mongoDatabase);
}

// Get tickets collection
function getTicketsCollection() returns mongodb:Database|error {
    return mongoClient->getDatabase(mongoDatabase);
}

// Get payments collection
function getPaymentsCollection() returns mongodb:Database|error {
    return mongoClient->getDatabase(mongoDatabase);
}

// Get notifications collection
function getNotificationsCollection() returns mongodb:Database|error {
    return mongoClient->getDatabase(mongoDatabase);
}

// Get validations collection
function getValidationsCollection() returns mongodb:Database|error {
    return mongoClient->getDatabase(mongoDatabase);
}