// script.js

const API_BASE_URL = '/api/admin';
let currentAdmin = null;

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    // Mock admin login for demo
    currentAdmin = {
        username: 'admin',
        role: 'ADMIN',
        permissions: ['manage_routes', 'manage_trips', 'view_reports', 'manage_disruptions']
    };

    document.getElementById('adminUsername').textContent = currentAdmin.username;

    // Navigation
    setupNavigation();

    // Load initial dashboard
    loadDashboard();

    // Setup forms
    setupForms();

    // Auto-refresh dashboard every 30 seconds
    setInterval(refreshDashboard, 30000);
});

// Setup Navigation
function setupNavigation() {
    const navItems = document.querySelectorAll('.nav-item');
    const sections = document.querySelectorAll('.content-section');

    navItems.forEach(item => {
        item.addEventListener('click', () => {
            const targetSection = item.getAttribute('data-section');

            // Update active nav item
            navItems.forEach(nav => nav.classList.remove('active'));
            item.classList.add('active');

            // Update active section
            sections.forEach(section => section.classList.remove('active'));
            document.getElementById(`${targetSection}-section`).classList.add('active');

            // Load section data
            loadSectionData(targetSection);
        });
    });
}

// Load Section Data
function loadSectionData(section) {
    switch (section) {
        case 'dashboard':
            loadDashboard();
            break;
        case 'routes':
            loadRoutes();
            break;
        case 'trips':
            loadTrips();
            break;
        case 'passengers':
            loadPassengers();
            break;
        case 'tickets':
            loadTickets();
            break;
        case 'payments':
            loadPayments();
            break;
        case 'notifications':
            loadNotifications();
            break;
    }
}

// Setup Forms
function setupForms() {
    // Create Route Form
    document.getElementById('createRouteForm').addEventListener('submit', createRoute);

    // Create Trip Form
    document.getElementById('createTripForm').addEventListener('submit', createTrip);

    // Sales Report Form
    document.getElementById('salesReportForm').addEventListener('submit', generateSalesReport);

    // Disruption Form
    document.getElementById('disruptionForm').addEventListener('submit', publishDisruption);

    // Notification Form
    document.getElementById('notificationForm').addEventListener('submit', sendNotification);

    // Logout
    document.getElementById('btnLogout').addEventListener('click', logout);
}

// Load Dashboard
async function loadDashboard() {
    try {
        showNotification('Loading dashboard...', 'info');

        const response = await fetch(`${API_BASE_URL}/stats`);
        const stats = await response.json();

        if (response.ok) {
            updateDashboardStats(stats);
            showNotification('Dashboard loaded', 'success');
        } else {
            throw new Error('Failed to load dashboard');
        }
    } catch (error) {
        console.error('Dashboard error:', error);
        showNotification('Failed to load dashboard', 'error');
    }
}

// Update Dashboard Stats
function updateDashboardStats(stats) {
    // Passenger Stats
    document.getElementById('totalPassengers').textContent = stats.passengers.totalPassengers;
    document.getElementById('activePassengers').textContent = stats.passengers.activePassengers;

    // Route Stats
    document.getElementById('totalRoutes').textContent = stats.routes.totalRoutes;
    document.getElementById('activeRoutes').textContent = stats.routes.activeRoutes;

    // Trip Stats
    document.getElementById('totalTrips').textContent = stats.routes.totalTrips;
    document.getElementById('activeTrips').textContent = stats.routes.activeTrips;

    // Payment Stats
    document.getElementById('totalRevenue').textContent = `$${stats.payments.totalRevenue.toFixed(2)}`;
    document.getElementById('todayRevenue').textContent = stats.payments.todayRevenue.toFixed(2);
    document.getElementById('totalPayments').textContent = stats.payments.totalPayments;
    document.getElementById('successRate').textContent = stats.payments.successRate.toFixed(1);

    // Notification Stats
    document.getElementById('totalNotifications').textContent = stats.totalNotifications;
    document.getElementById('totalValidations').textContent = stats.totalValidations;

    // Load recent activity
    loadRecentActivity();
}

// Load Recent Activity
async function loadRecentActivity() {
    const activityList = document.getElementById('activityList');
    activityList.innerHTML = '<p class="loading">Loading activity...</p>';

    try {
        // Mock activity data (in production, fetch from backend)
        const activities = [
            { time: new Date(), text: 'New passenger registered' },
            { time: new Date(Date.now() - 300000), text: 'Route BUS-101 updated' },
            { time: new Date(Date.now() - 600000), text: 'Trip scheduled for tomorrow' },
            { time: new Date(Date.now() - 900000), text: 'Payment received: $45.00' },
            { time: new Date(Date.now() - 1200000), text: 'Disruption resolved on Route TRAIN-5' }
        ];

        activityList.innerHTML = activities.map(activity => `
            <div class="activity-item">
                <div class="activity-time">${formatTime(activity.time)}</div>
                <div class="activity-text">${activity.text}</div>
            </div>
        `).join('');
    } catch (error) {
        console.error('Activity error:', error);
        activityList.innerHTML = '<p class="error-text">Failed to load activity</p>';
    }
}

// Refresh Dashboard
async function refreshDashboard() {
    await loadDashboard();
}

// Create Route
async function createRoute(e) {
    e.preventDefault();

    const routeData = {
        routeNumber: document.getElementById('routeNumber').value,
        routeName: document.getElementById('routeName').value,
        origin: document.getElementById('routeOrigin').value,
        destination: document.getElementById('routeDestination').value,
        stops: document.getElementById('routeStops').value.split(',').map(s => s.trim()).filter(s => s),
        basePrice: parseFloat(document.getElementById('routePrice').value),
        transportType: document.getElementById('routeTransportType').value
    };

    try {
        const response = await fetch(`${API_BASE_URL}/routes`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(routeData)
        });

        const result = await response.json();

        if (response.ok) {
            showNotification('Route created successfully!', 'success');
            document.getElementById('createRouteForm').reset();
            loadRoutes();
        } else {
            showNotification(result.message || 'Failed to create route', 'error');
        }
    } catch (error) {
        console.error('Create route error:', error);
        showNotification('Failed to create route', 'error');
    }
}

// Load Routes
async function loadRoutes() {
    const routesList = document.getElementById('routesList');
    routesList.innerHTML = '<p class="loading">Loading routes...</p>';

    try {
        const response = await fetch(`${API_BASE_URL}/routes`);
        const routes = await response.json();

        if (response.ok && routes.length > 0) {
            routesList.innerHTML = routes.map(route => `
                <div class="data-item">
                    <h4>${route.routeNumber} - ${route.routeName}</h4>
                    <p><strong>Route ID:</strong> ${route.routeId}</p>
                    <p><strong>From:</strong> ${route.origin} <strong>To:</strong> ${route.destination}</p>
                    <p><strong>Type:</strong> ${route.transportType}</p>
                    <p><strong>Base Price:</strong> $${route.basePrice.toFixed(2)}</p>
                    <p><strong>Stops:</strong> ${route.stops.join(', ')}</p>
                    <span class="status ${route.status}">${route.status}</span>
                    <div class="action-buttons">
                        <button class="btn-small btn-edit" onclick="editRoute('${route.routeId}')">Edit</button>
                        <button class="btn-small btn-delete" onclick="deleteRoute('${route.routeId}')">Delete</button>
                    </div>
                </div>
            `).join('');
        } else {
            routesList.innerHTML = '<p class="error-text">No routes found</p>';
        }
    } catch (error) {
        console.error('Load routes error:', error);
        routesList.innerHTML = '<p class="error-text">Failed to load routes</p>';
    }
}

// Create Trip
async function createTrip(e) {
    e.preventDefault();

    const departureDateTime = document.getElementById('tripDeparture').value;
    const arrivalDateTime = document.getElementById('tripArrival').value;

    const tripData = {
        routeId: document.getElementById('tripRouteId').value,
        scheduledDeparture: parseDateTimeToCivil(departureDateTime),
        scheduledArrival: parseDateTimeToCivil(arrivalDateTime),
        availableSeats: parseInt(document.getElementById('tripSeats').value)
    };

    try {
        const response = await fetch(`${API_BASE_URL}/trips`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(tripData)
        });

        const result = await response.json();

        if (response.ok) {
            showNotification('Trip created successfully!', 'success');
            document.getElementById('createTripForm').reset();
            loadTrips();
        } else {
            showNotification(result.message || 'Failed to create trip', 'error');
        }
    } catch (error) {
        console.error('Create trip error:', error);
        showNotification('Failed to create trip', 'error');
    }
}

// Load Trips
async function loadTrips() {
    const tripsList = document.getElementById('tripsList');
    tripsList.innerHTML = '<p class="loading">Loading trips...</p>';

    const statusFilter = document.getElementById('tripStatusFilter').value;
    let url = `${API_BASE_URL}/trips`;
    if (statusFilter) {
        url += `?status=${statusFilter}`;
    }

    try {
        const response = await fetch(url);
        const trips = await response.json();

        if (response.ok && trips.length > 0) {
            tripsList.innerHTML = trips.map(trip => `
                <div class="data-item">
                    <h4>Trip ${trip.tripId}</h4>
                    <p><strong>Route ID:</strong> ${trip.routeId}</p>
                    <p><strong>Departure:</strong> ${formatDateTime(trip.scheduledDeparture)}</p>
                    <p><strong>Arrival:</strong> ${formatDateTime(trip.scheduledArrival)}</p>
                    <p><strong>Available Seats:</strong> ${trip.availableSeats}</p>
                    <span class="status ${trip.status}">${trip.status}</span>
                    <div class="action-buttons">
                        <button class="btn-small btn-edit" onclick="updateTripStatus('${trip.tripId}', 'cancelled')">Cancel</button>
                        <button class="btn-small btn-view" onclick="viewTripDetails('${trip.tripId}')">View Details</button>
                    </div>
                </div>
            `).join('');
        } else {
            tripsList.innerHTML = '<p class="error-text">No trips found</p>';
        }
    } catch (error) {
        console.error('Load trips error:', error);
        tripsList.innerHTML = '<p class="error-text">Failed to load trips</p>';
    }
}

// Load Passengers
async function loadPassengers() {
    const passengersList = document.getElementById('passengersList');
    passengersList.innerHTML = '<p class="loading">Loading passengers...</p>';

    try {
        const response = await fetch(`${API_BASE_URL}/passengers`);
        const passengers = await response.json();

        if (response.ok && passengers.length > 0) {
            passengersList.innerHTML = passengers.map(passenger => `
                <div class="data-item">
                    <h4>${passenger.firstName} ${passenger.lastName}</h4>
                    <p><strong>Passenger ID:</strong> ${passenger.passengerId}</p>
                    <p><strong>Email:</strong> ${passenger.email}</p>
                    <p><strong>Phone:</strong> ${passenger.phoneNumber}</p>
                    <p><strong>Registered:</strong> ${formatDateTime(passenger.createdAt)}</p>
                    <div class="action-buttons">
                        <button class="btn-small btn-view" onclick="viewPassengerDetails('${passenger.passengerId}')">View Details</button>
                    </div>
                </div>
            `).join('');
        } else {
            passengersList.innerHTML = '<p class="error-text">No passengers found</p>';
        }
    } catch (error) {
        console.error('Load passengers error:', error);
        passengersList.innerHTML = '<p class="error-text">Failed to load passengers</p>';
    }
}

// Load Tickets
async function loadTickets() {
    const ticketsList = document.getElementById('ticketsList');
    ticketsList.innerHTML = '<p class="loading">Loading tickets...</p>';

    const statusFilter = document.getElementById('ticketStatusFilter').value;
    let url = `${API_BASE_URL}/tickets`;
    if (statusFilter) {
        url += `?status=${statusFilter}`;
    }

    try {
        const response = await fetch(url);
        const tickets = await response.json();

        if (response.ok && tickets.length > 0) {
            ticketsList.innerHTML = tickets.map(ticket => `
                <div class="data-item">
                    <h4>Ticket ${ticket.ticketId}</h4>
                    <p><strong>Passenger ID:</strong> ${ticket.passengerId}</p>
                    <p><strong>Trip ID:</strong> ${ticket.tripId}</p>
                    <p><strong>Type:</strong> ${ticket.ticketType}</p>
                    <p><strong>Price:</strong> $${ticket.price.toFixed(2)}</p>
                    <p><strong>QR Code:</strong> ${ticket.qrCode}</p>
                    <p><strong>Purchased:</strong> ${formatDateTime(ticket.purchaseDate)}</p>
                    <span class="status ${ticket.status}">${ticket.status}</span>
                </div>
            `).join('');
        } else {
            ticketsList.innerHTML = '<p class="error-text">No tickets found</p>';
        }
    } catch (error) {
        console.error('Load tickets error:', error);
        ticketsList.innerHTML = '<p class="error-text">Failed to load tickets</p>';
    }
}

// Load Payments
async function loadPayments() {
    const paymentsList = document.getElementById('paymentsList');
    paymentsList.innerHTML = '<p class="loading">Loading payments...</p>';

    try {
        const response = await fetch(`${API_BASE_URL}/payments`);
        const payments = await response.json();

        if (response.ok && payments.length > 0) {
            // Update payment stats
            let todayRevenue = 0, weekRevenue = 0, monthRevenue = 0;
            const today = new Date();
            const weekAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
            const monthAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);

            payments.forEach(payment => {
                if (payment.status === 'completed') {
                    const paymentDate = new Date(payment.processedAt);
                    if (paymentDate.toDateString() === today.toDateString()) {
                        todayRevenue += payment.amount;
                    }
                    if (paymentDate >= weekAgo) {
                        weekRevenue += payment.amount;
                    }
                    if (paymentDate >= monthAgo) {
                        monthRevenue += payment.amount;
                    }
                }
            });

            document.getElementById('paymentTodayRevenue').textContent = `$${todayRevenue.toFixed(2)}`;
            document.getElementById('paymentWeekRevenue').textContent = `$${weekRevenue.toFixed(2)}`;
            document.getElementById('paymentMonthRevenue').textContent = `$${monthRevenue.toFixed(2)}`;

            paymentsList.innerHTML = payments.map(payment => `
                <div class="data-item">
                    <h4>Payment ${payment.paymentId}</h4>
                    <p><strong>Ticket ID:</strong> ${payment.ticketId}</p>
                    <p><strong>Passenger ID:</strong> ${payment.passengerId}</p>
                    <p><strong>Amount:</strong> $${payment.amount.toFixed(2)}</p>
                    <p><strong>Method:</strong> ${payment.paymentMethod}</p>
                    <p><strong>Reference:</strong> ${payment.transactionReference}</p>
                    <p><strong>Processed:</strong> ${formatDateTime(payment.processedAt)}</p>
                    <span class="status ${payment.status}">${payment.status}</span>
                </div>
            `).join('');
        } else {
            paymentsList.innerHTML = '<p class="error-text">No payments found</p>';
        }
    } catch (error) {
        console.error('Load payments error:', error);
        paymentsList.innerHTML = '<p class="error-text">Failed to load payments</p>';
    }
}

// Generate Sales Report
async function generateSalesReport(e) {
    e.preventDefault();

    const startDate = document.getElementById('reportStartDate').value;
    const endDate = document.getElementById('reportEndDate').value;

    try {
        const response = await fetch(`${API_BASE_URL}/reports/sales?startDate=${startDate}&endDate=${endDate}`);
        const report = await response.json();

        if (response.ok) {
            displaySalesReport(report);
            showNotification('Report generated successfully!', 'success');
        } else {
            showNotification('Failed to generate report', 'error');
        }
    } catch (error) {
        console.error('Generate report error:', error);
        showNotification('Failed to generate report', 'error');
    }
}

// Display Sales Report
function displaySalesReport(report) {
    const reportResult = document.getElementById('reportResult');
    reportResult.className = 'result-box success';
    reportResult.innerHTML = `
        <h3>📊 Sales Report</h3>
        <p><strong>Period:</strong> ${report.periodStart} to ${report.periodEnd}</p>
        <p><strong>Total Tickets Sold:</strong> ${report.totalTickets}</p>
        <p><strong>Total Revenue:</strong> $${report.totalRevenue.toFixed(2)}</p>
        <p><strong>Average Ticket Price:</strong> $${report.averageTicketPrice.toFixed(2)}</p>
        
        <h4 style="margin-top: 1rem;">Tickets by Type:</h4>
        ${Object.entries(report.ticketsByType).map(([type, count]) => 
            `<p>${type}: ${count} tickets</p>`
        ).join('')}
        
        <h4 style="margin-top: 1rem;">Revenue by Type:</h4>
        ${Object.entries(report.revenueByType).map(([type, revenue]) => 
            `<p>${type}: $${revenue.toFixed(2)}</p>`
        ).join('')}
        
        <h4 style="margin-top: 1rem;">Tickets by Status:</h4>
        ${Object.entries(report.ticketsByStatus).map(([status, count]) => 
            `<p>${status}: ${count} tickets</p>`
        ).join('')}
    `;
}

// Publish Disruption
async function publishDisruption(e) {
    e.preventDefault();

    const disruptionData = {
        title: document.getElementById('disruptionTitle').value,
        description: document.getElementById('disruptionDescription').value,
        severity: document.getElementById('disruptionSeverity').value,
        affectedRoutes: document.getElementById('disruptionRoutes').value
            .split(',').map(s => s.trim()).filter(s => s),
        affectedTrips: document.getElementById('disruptionTrips').value
            .split(',').map(s => s.trim()).filter(s => s)
    };

    try {
        const response = await fetch(`${API_BASE_URL}/disruptions`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(disruptionData)
        });

        const result = await response.json();

        if (response.ok) {
            showDisruptionResult(result, 'success');
            showNotification('Disruption published successfully!', 'success');
            document.getElementById('disruptionForm').reset();
        } else {
            showNotification(result.message || 'Failed to publish disruption', 'error');
        }
    } catch (error) {
        console.error('Publish disruption error:', error);
        showNotification('Failed to publish disruption', 'error');
    }
}

// Show Disruption Result
function showDisruptionResult(result, type) {
    const disruptionResult = document.getElementById('disruptionResult');
    disruptionResult.className = `result-box ${type}`;
    disruptionResult.innerHTML = `
        <h3>${type === 'success' ? '✅' : '❌'} Disruption ${type === 'success' ? 'Published' : 'Failed'}</h3>
        <p><strong>Disruption ID:</strong> ${result.disruptionId}</p>
        <p><strong>Title:</strong> ${result.title}</p>
        <p><strong>Severity:</strong> ${result.severity}</p>
        <p><strong>Status:</strong> ${result.status}</p>
        <p>${result.message}</p>
    `;
}

// Send Notification
async function sendNotification(e) {
    e.preventDefault();

    const notificationData = {
        passengerId: document.getElementById('notifPassengerId').value || null,
        type: document.getElementById('notifType').value,
        title: document.getElementById('notifTitle').value,
        message: document.getElementById('notifMessage').value
    };

    try {
        const response = await fetch(`${API_BASE_URL}/notifications`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(notificationData)
        });

        const result = await response.json();

        if (response.ok) {
            showNotification('Notification sent successfully!', 'success');
            document.getElementById('notificationForm').reset();
            loadNotifications();
        } else {
            showNotification(result.message || 'Failed to send notification', 'error');
        }
    } catch (error) {
        console.error('Send notification error:', error);
        showNotification('Failed to send notification', 'error');
    }
}

// Load Notifications
async function loadNotifications() {
    const notificationsList = document.getElementById('notificationsList');
    notificationsList.innerHTML = '<p class="loading">Loading notifications...</p>';

    try {
        const response = await fetch(`${API_BASE_URL}/notifications`);
        const notifications = await response.json();

        if (response.ok && notifications.length > 0) {
            notificationsList.innerHTML = notifications.map(notif => `
                <div class="data-item">
                    <h4>${notif.title}</h4>
                    <p><strong>Type:</strong> ${notif.type}</p>
                    <p><strong>Message:</strong> ${notif.message}</p>
                    <p><strong>Recipient:</strong> ${notif.passengerId || 'All Passengers'}</p>
                    <p><strong>Sent:</strong> ${formatDateTime(notif.createdAt)}</p>
                    <span class="status ${notif.status}">${notif.status}</span>
                </div>
            `).join('');
        } else {
            notificationsList.innerHTML = '<p class="error-text">No notifications found</p>';
        }
    } catch (error) {
        console.error('Load notifications error:', error);
        notificationsList.innerHTML = '<p class="error-text">Failed to load notifications</p>';
    }
}

// Helper Functions
function showNotification(message, type) {
    const notification = document.getElementById('notification');
    notification.textContent = message;
    notification.className = `notification ${type}`;
    
    setTimeout(() => {
        notification.classList.add('hidden');
    }, 3000);
}

function formatDateTime(dateString) {
    const date = new Date(dateString);
    return date.toLocaleString();
}

function formatTime(date) {
    const now = new Date();
    const diff = Math.floor((now - date) / 1000);

    if (diff < 60) return `${diff} seconds ago`;
    if (diff < 3600) return `${Math.floor(diff / 60)} minutes ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)} hours ago`;
    return date.toLocaleDateString();
}

function parseDateTimeToCivil(dateTimeString) {
    const date = new Date(dateTimeString);
    return {
        year: date.getFullYear(),
        month: date.getMonth() + 1,
        day: date.getDate(),
        hour: date.getHours(),
        minute: date.getMinutes(),
        second: date.getSeconds()
    };
}

function logout() {
    currentAdmin = null;
    window.location.reload();
}

// Placeholder functions for buttons
function editRoute(routeId) {
    showNotification(`Edit route ${routeId} - Feature coming soon`, 'info');
}

function deleteRoute(routeId) {
    if (confirm(`Are you sure you want to delete route ${routeId}?`)) {
        showNotification(`Delete route ${routeId} - Feature coming soon`, 'info');
    }
}

function updateTripStatus(tripId, status) {
    if (confirm(`Are you sure you want to ${status} trip ${tripId}?`)) {
        showNotification(`Update trip ${tripId} to ${status} - Feature coming soon`, 'info');
    }
}

function viewTripDetails(tripId) {
    showNotification(`View details for trip ${tripId} - Feature coming soon`, 'info');
}

function viewPassengerDetails(passengerId) {
    showNotification(`View details for passenger ${passengerId} - Feature coming soon`, 'info');
}