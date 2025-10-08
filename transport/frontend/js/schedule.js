// schedule.js
let scheduleData = [];
let filterRoute = '';
let filterStatus = '';

// Load schedule
async function loadSchedule() {
    try {
        const date = document.getElementById('scheduleDate').value;
        const trips = await apiCall('/trips');
        
        // Filter by date if selected
        if (date) {
            const selectedDate = new Date(date).toDateString();
            scheduleData = trips.filter(trip => {
                const tripDate = new Date(trip.scheduledDeparture).toDateString();
                return tripDate === selectedDate;
            });
        } else {
            scheduleData = trips;
        }
        
        applyFilters();
    } catch (error) {
        showError('Failed to load schedule: ' + error.message);
        document.getElementById('scheduleGrid').innerHTML = '<p class="loading">Failed to load schedule</p>';
    }
}

// Load routes for filter
async function loadRoutesForFilter() {
    try {
        const routes = await apiCall('/routes');
        const select = document.getElementById('filterRoute');
        select.innerHTML = '<option value="">All Routes</option>' +
            routes.map(route => `
                <option value="${route.routeId}">
                    ${route.routeNumber} - ${route.routeName}
                </option>
            `).join('');
    } catch (error) {
        console.error('Failed to load routes:', error);
    }
}

// Apply filters
function applyFilters() {
    let filtered = [...scheduleData];
    
    if (filterRoute) {
        filtered = filtered.filter(trip => trip.routeId === filterRoute);
    }
    
    if (filterStatus) {
        filtered = filtered.filter(trip => trip.status === filterStatus);
    }
    
    // Sort by departure time
    filtered.sort((a, b) => {
        return new Date(a.scheduledDeparture) - new Date(b.scheduledDeparture);
    });
    
    displaySchedule(filtered);
}

// Display schedule
function displaySchedule(trips) {
    const container = document.getElementById('scheduleGrid');
    
    if (trips.length === 0) {
        container.innerHTML = '<p class="loading">No trips scheduled</p>';
        return;
    }

    container.innerHTML = trips.map(trip => `
        <div class="schedule-item">
            <div class="schedule-time">
                <div class="time-badge">${formatTime(trip.scheduledDeparture)}</div>
                <div class="route-info">
                    <h4>Route ${trip.routeId.substring(0, 8)}</h4>
                    <p class="route-path">
                        ${formatTime(trip.scheduledDeparture)} → ${formatTime(trip.scheduledArrival)}
                    </p>
                </div>
                ${getStatusBadge(trip.status)}
            </div>
            
            <div class="trip-details">
                <div class="detail-item">
                    <strong>Seats</strong>
                    <span>${trip.availableSeats} / ${trip.totalSeats}</span>
                </div>
                <div class="detail-item">
                    <strong>Price</strong>
                    <span>$${trip.currentPrice}</span>
                </div>
                ${trip.delayMinutes ? `
                <div class="detail-item">
                    <strong>Delay</strong>
                    <span>${trip.delayMinutes} mins</span>
                </div>
                ` : ''}
                <div class="detail-item">
                    <button class="btn btn-small btn-info" onclick="viewTrip('${trip.tripId}')">Details</button>
                </div>
            </div>
        </div>
    `).join('');
}

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    // Set today's date
    const today = new Date().toISOString().split('T')[0];
    document.getElementById('scheduleDate').value = today;
    
    // Load data
    loadSchedule();
    loadRoutesForFilter();

    // Refresh button
    document.getElementById('refreshSchedule').addEventListener('click', loadSchedule);

    // Date change
    document.getElementById('scheduleDate').addEventListener('change', loadSchedule);

    // Route filter
    document.getElementById('filterRoute').addEventListener('change', function() {
        filterRoute = this.value;
        applyFilters();
    });

    // Status filter
    document.getElementById('filterStatus').addEventListener('change', function() {
        filterStatus = this.value;
        applyFilters();
    });
});