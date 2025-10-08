// trips.js
let currentTrips = [];
let availableRoutes = [];

// Load trips
async function loadTrips(status = null) {
    try {
        const endpoint = status ? `/trips?status=${status}` : '/trips';
        const trips = await apiCall(endpoint);
        currentTrips = trips;
        displayTrips(trips);
    } catch (error) {
        showError('Failed to load trips: ' + error.message);
        document.getElementById('tripsList').innerHTML = '<p class="loading">Failed to load trips</p>';
    }
}

// Load routes for dropdown
async function loadRoutesForDropdown() {
    try {
        const routes = await apiCall('/routes?status=active');
        availableRoutes = routes;
        
        const select = document.getElementById('routeSelect');
        select.innerHTML = '<option value="">Select a route</option>' +
            routes.map(route => `
                <option value="${route.routeId}" data-price="${route.basePrice}">
                    ${route.routeNumber} - ${route.routeName}
                </option>
            `).join('');
    } catch (error) {
        console.error('Failed to load routes:', error);
    }
}

// Display trips
function displayTrips(trips) {
    const container = document.getElementById('tripsList');
    
    if (trips.length === 0) {
        container.innerHTML = '<p class="loading">No trips found</p>';
        return;
    }

    container.innerHTML = trips.map(trip => `
        <div class="trip-card" data-trip-id="${trip.tripId}">
            <div class="trip-header">
                <div class="trip-title">
                    <h3>Trip ${trip.tripId.substring(0, 8)}</h3>
                    <p>Route: ${trip.routeId.substring(0, 8)}</p>
                </div>
                <div class="trip-actions">
                    ${getStatusBadge(trip.status)}
                    <button class="btn btn-small btn-info" onclick="viewTrip('${trip.tripId}')">View</button>
                    <button class="btn btn-small btn-warning" onclick="openStatusModal('${trip.tripId}')">Update Status</button>
                </div>
            </div>
            
            <div class="trip-details">
                <div class="detail-item">
                    <strong>Departure</strong>
                    <span>${formatDate(trip.scheduledDeparture)}</span>
                </div>
                <div class="detail-item">
                    <strong>Arrival</strong>
                    <span>${formatDate(trip.scheduledArrival)}</span>
                </div>
                <div class="detail-item">
                    <strong>Available Seats</strong>
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
                ${trip.delayReason ? `
                <div class="detail-item">
                    <strong>Reason</strong>
                    <span>${trip.delayReason}</span>
                </div>
                ` : ''}
            </div>
        </div>
    `).join('');
}

// View trip details
async function viewTrip(tripId) {
    try {
        const trip = await apiCall(`/trips/${tripId}`);
        
        const modalContent = `
            <div class="modal show" id="viewTripModal">
                <div class="modal-content">
                    <span class="close" onclick="closeModal('viewTripModal')">&times;</span>
                    <h2>Trip Details</h2>
                    
                    <div class="trip-details">
                        <div class="detail-item">
                            <strong>Trip ID</strong>
                            <span>${trip.tripId}</span>
                        </div>
                        <div class="detail-item">
                            <strong>Route ID</strong>
                            <span>${trip.routeId}</span>
                        </div>
                        <div class="detail-item">
                            <strong>Status</strong>
                            <span>${getStatusBadge(trip.status)}</span>
                        </div>
                        <div class="detail-item">
                            <strong>Scheduled Departure</strong>
                            <span>${formatDate(trip.scheduledDeparture)}</span>
                        </div>
                        <div class="detail-item">
                            <strong>Scheduled Arrival</strong>
                            <span>${formatDate(trip.scheduledArrival)}</span>
                        </div>
                        ${trip.actualDeparture ? `
                        <div class="detail-item">
                            <strong>Actual Departure</strong>
                            <span>${formatDate(trip.actualDeparture)}</span>
                        </div>
                        ` : ''}
                        ${trip.actualArrival ? `
                        <div class="detail-item">
                            <strong>Actual Arrival</strong>
                            <span>${formatDate(trip.actualArrival)}</span>
                        </div>
                        ` : ''}
                        <div class="detail-item">
                            <strong>Total Seats</strong>
                            <span>${trip.totalSeats}</span>
                        </div>
                        <div class="detail-item">
                            <strong>Available Seats</strong>
                            <span>${trip.availableSeats}</span>
                        </div>
                        <div class="detail-item">
                            <strong>Price</strong>
                            <span>$${trip.currentPrice}</span>
                        </div>
                        ${trip.vehicleId ? `
                        <div class="detail-item">
                            <strong>Vehicle ID</strong>
                            <span>${trip.vehicleId}</span>
                        </div>
                        ` : ''}
                        ${trip.driverId ? `
                        <div class="detail-item">
                            <strong>Driver ID</strong>
                            <span>${trip.driverId}</span>
                        </div>
                        ` : ''}
                        ${trip.delayMinutes ? `
                        <div class="detail-item">
                            <strong>Delay</strong>
                            <span>${trip.delayMinutes} minutes</span>
                        </div>
                        ` : ''}
                        ${trip.delayReason ? `
                        <div class="detail-item">
                            <strong>Delay Reason</strong>
                            <span>${trip.delayReason}</span>
                        </div>
                        ` : ''}
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', modalContent);
    } catch (error) {
        showError('Failed to load trip details: ' + error.message);
    }
}

// Open status modal
function openStatusModal(tripId) {
    document.getElementById('statusTripId').value = tripId;
    document.getElementById('tripStatus').value = 'scheduled';
    document.getElementById('delayReason').value = '';
    document.getElementById('delayMinutes').value = '';
    document.getElementById('delayFields').style.display = 'none';
    openModal('statusModal');
}

// Submit trip form
async function submitTripForm(e) {
    e.preventDefault();

    const formData = {
        routeId: document.getElementById('routeSelect').value,
        vehicleId: document.getElementById('vehicleId').value || null,
        driverId: document.getElementById('driverId').value || null,
        scheduledDeparture: new Date(document.getElementById('scheduledDeparture').value).toISOString(),
        scheduledArrival: new Date(document.getElementById('scheduledArrival').value).toISOString(),
        totalSeats: parseInt(document.getElementById('totalSeats').value),
        currentPrice: parseFloat(document.getElementById('currentPrice').value) || null
    };

    try {
        await apiCall('/trips', 'POST', formData);
        showSuccess('Trip scheduled successfully');
        closeModal('tripModal');
        document.getElementById('tripForm').reset();
        loadTrips();
    } catch (error) {
        showError('Failed to schedule trip: ' + error.message);
    }
}

// Submit status form
async function submitStatusForm(e) {
    e.preventDefault();

    const tripId = document.getElementById('statusTripId').value;
    const formData = {
        status: document.getElementById('tripStatus').value,
        delayReason: document.getElementById('delayReason').value || null,
        delayMinutes: parseInt(document.getElementById('delayMinutes').value) || null
    };

    try {
        await apiCall(`/trips/${tripId}/status`, 'PUT', formData);
        showSuccess('Trip status updated successfully');
        closeModal('statusModal');
        document.getElementById('statusForm').reset();
        loadTrips();
    } catch (error) {
        showError('Failed to update trip status: ' + error.message);
    }
}

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    // Load data
    loadTrips();
    loadRoutesForDropdown();

    // Filter buttons
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            
            const filter = this.dataset.filter;
            
            if (filter === 'all') {
                loadTrips();
            } else {
                loadTrips(filter);
            }
        });
    });

    // Add trip button
    const addBtn = document.getElementById('addTripBtn');
    if (addBtn) {
        addBtn.addEventListener('click', function() {
            document.getElementById('tripForm').reset();
            openModal('tripModal');
        });
    }

    // Route select change - auto-fill price
    const routeSelect = document.getElementById('routeSelect');
    if (routeSelect) {
        routeSelect.addEventListener('change', function() {
            const selectedOption = this.options[this.selectedIndex];
            const price = selectedOption.dataset.price;
            if (price) {
                document.getElementById('currentPrice').value = price;
            }
        });
    }

    // Trip status change
    const tripStatus = document.getElementById('tripStatus');
    if (tripStatus) {
        tripStatus.addEventListener('change', function() {
            const delayFields = document.getElementById('delayFields');
            if (this.value === 'delayed' || this.value === 'cancelled') {
                delayFields.style.display = 'block';
            } else {
                delayFields.style.display = 'none';
            }
        });
    }

    // Form submits
    const tripForm = document.getElementById('tripForm');
    if (tripForm) {
        tripForm.addEventListener('submit', submitTripForm);
    }

    const statusForm = document.getElementById('statusForm');
    if (statusForm) {
        statusForm.addEventListener('submit', submitStatusForm);
    }

    // Cancel buttons
    const cancelTripBtn = document.getElementById('cancelTripBtn');
    if (cancelTripBtn) {
        cancelTripBtn.addEventListener('click', () => closeModal('tripModal'));
    }

    const cancelStatusBtn = document.getElementById('cancelStatusBtn');
    if (cancelStatusBtn) {
        cancelStatusBtn.addEventListener('click', () => closeModal('statusModal'));
    }
});