// ticket_manager.bal
import ballerina/log;
import ballerina/uuid;
import ballerina/time;
import ballerina/crypto;

// Ticket configuration
configurable int ticketValidityHours = 24;
configurable int qrCodeLength = 16;

// Purchase ticket
public function purchaseTicket(TicketPurchaseRequest request) returns TicketPurchaseResponse|error {
    log:printInfo(string `🎫 Processing ticket purchase for passenger: ${request.passengerId}`);
    
    // Step 1: Validate passenger exists
    Passenger passenger = check getPassengerById(request.passengerId);
    log:printInfo(string `✅ Passenger validated: ${passenger.username}`);
    
    // Step 2: Validate trip exists
    Trip trip = check getTripById(request.tripId);
    log:printInfo(string `✅ Trip validated: ${trip.routeNumber}`);
    
    // Step 3: Check seat availability
    if trip.availableSeats <= 0 {
        return error("No seats available for this trip");
    }
    
    // Step 4: Create ticket
    string ticketId = uuid:createType1AsString();
    string qrCode = generateQRCode(ticketId);
    time:Civil now = time:utcToCivil(time:utcNow());
    time:Civil validUntil = check addHours(now, ticketValidityHours);
    
    Ticket ticket = {
        ticketId: ticketId,
        passengerId: request.passengerId,
        tripId: request.tripId,
        routeId: trip.routeId,
        routeNumber: trip.routeNumber,
        routeName: trip.routeName,
        price: trip.price,
        ticketType: request.ticketType,
        status: "CREATED",
        qrCode: qrCode,
        purchaseDate: now,
        validFrom: now,
        validUntil: validUntil,
        createdAt: now,
        updatedAt: now
    };
    
    // Step 5: Save ticket to database
    check saveTicket(ticket);
    log:printInfo(string `💾 Ticket created: ${ticketId}`);
    
    // Step 6: Send payment request to Payment Service via Kafka
    PaymentRequest paymentRequest = {
        ticketId: ticketId,
        passengerId: request.passengerId,
        tripId: request.tripId,
        amount: trip.price,
        paymentMethod: request.paymentMethod,
        requestId: string `req-${ticketId.substring(0, 8)}`
    };
    
    check publishPaymentRequest(paymentRequest);
    log:printInfo(string `📤 Payment request sent for ticket: ${ticketId}`);
    
    return {
        ticketId: ticketId,
        qrCode: qrCode,
        price: trip.price,
        status: "CREATED",
        message: "Ticket created successfully. Payment processing..."
    };
}

// Validate ticket for boarding
public function validateTicketForBoarding(TicketValidationRequest request) returns TicketValidationResponse|error {
    log:printInfo(string `🎫 Validating ticket: ${request.ticketId}`);
    
    // Get ticket by QR code
    Ticket ticket = check getTicketByQRCode(request.qrCode);
    
    // Check if ticket matches request
    if ticket.ticketId != request.ticketId {
        return {
            isValid: false,
            message: "Ticket ID does not match QR code"
        };
    }
    
    // Check ticket status
    if ticket.status != "PAID" {
        return {
            isValid: false,
            message: string `Ticket is ${ticket.status}. Only PAID tickets can be validated.`
        };
    }
    
    // Check validity period
    time:Civil now = time:utcToCivil(time:utcNow());
    
    if !isDateInRange(now, ticket.validFrom, ticket.validUntil) {
        return {
            isValid: false,
            message: "Ticket is outside validity period"
        };
    }
    
    // Validate ticket
    check validateTicket(ticket.ticketId, request.validatorId);
    
    // Publish ticket validated event
    check publishTicketValidated({
        ticketId: ticket.ticketId,
        passengerId: ticket.passengerId,
        tripId: ticket.tripId,
        routeId: ticket.routeId,
        validatedAt: now,
        validatedBy: request.validatorId
    });
    
    log:printInfo(string `✅ Ticket validated successfully: ${ticket.ticketId}`);
    
    return {
        isValid: true,
        message: "Ticket validated successfully",
        ticketId: ticket.ticketId,
        passengerId: ticket.passengerId,
        validatedAt: now
    };
}

// Generate QR code (simplified - just a unique string)
function generateQRCode(string ticketId) returns string {
    byte[] data = ticketId.toBytes();
    byte[] hash = crypto:hashSha256(data);
    string hashString = hash.toBase16();
    
    // Return first N characters as QR code
    return hashString.substring(0, qrCodeLength);
}

// Add hours to a date
function addHours(time:Civil date, int hours) returns time:Civil|error {
    time:Utc utc = check time:utcFromCivil(date);
    decimal seconds = <decimal>hours * 3600.0d;
    time:Utc newUtc = time:utcAddSeconds(utc, seconds);
    return time:utcToCivil(newUtc);
}

// Check if date is in range
function isDateInRange(time:Civil date, time:Civil startDate, time:Civil endDate) returns boolean {
    time:Utc|error dateUtc = time:utcFromCivil(date);
    time:Utc|error startUtc = time:utcFromCivil(startDate);
    time:Utc|error endUtc = time:utcFromCivil(endDate);
    
    if dateUtc is error || startUtc is error || endUtc is error {
        return false;
    }
    
    decimal dateDiff = time:utcDiffSeconds(dateUtc, startUtc);
    decimal endDiff = time:utcDiffSeconds(endUtc, dateUtc);
    
    return dateDiff >= 0.0d && endDiff >= 0.0d;
}