// routes.js
let currentRoutes = [];
let currentFilter = 'all';

// Load routes
async function loadRoutes(status = null) {
    try {
        const endpoint = status ? `/routes?status=${status}` : '/routes';
        const routes = await apiCall(endpoint);
        currentRoutes = routes;
        displayRoutes(routes);
    } catch (error) {
        showError('Failed to load routes: ' + error.message);
        document.getElementById('routesList').innerHTML = '<p class="loading">Failed to load routes</p>';
    }
}

// Display routes
function displayRoutes(routes) {
    const container = document.getElementById('routesList');
    
    if (routes.length === 0) {
        container.innerHTML = '<p class="loading">No routes found</p>';
        return;
    }

    container.innerHTML = routes.map(route => `
        <div class="route-card" data-route-id="${route.routeId}">
            <div class="route-header">
                <div class="route-title">
                    <h3>${route.routeNumber} - ${route.routeName}</h3>
                    <p>${route.transportType.toUpperCase()}</p>
                </div>
                <div class="route-actions">
                    ${getStatusBadge(route.status)}
                    <button class="btn btn-small btn-info" onclick="viewRoute('${route.routeId}')">View</button>
                    <button class="btn btn-small btn-primary" onclick="editRoute('${route.routeId}')">Edit</button>
                    <button class="btn btn-small btn-danger" onclick="deleteRoute('${route.routeId}')">Delete</button>
                </div>
            </div>
            
            <div class="route-details">
                <div class="detail-item">
                    <strong>Origin</strong>
                    <span>${route.origin}</span>
                </div>
                <div class="detail-item">
                    <strong>Destination</strong>
                    <span>${route.destination}</span>
                </div>
                <div class="detail-item">
                    <strong>Distance</strong>
                    <span>${route.distance} km</span>
                </div>
                <div class="detail-item">
                    <strong>Duration</strong>
                    <span>${route.estimatedDuration} mins</span>
                </div>
                <div class="detail-item">
                    <strong>Base Price</strong>
                    <span>$${route.basePrice}</span>
                </div>
                <div class="detail-item">
                    <strong>Stops</strong>
                    <span>${route.stops.length} stops</span>
                </div>
            </div>
        </div>
    `).join('');
}

// View route details
async function viewRoute(routeId) {
    try {
        const route = await apiCall(`/routes/${routeId}`);
        
        // Create modal content
        const modalContent = `
            <div class="modal show" id="viewRouteModal">
                <div class="modal-content">
                    <span class="close" onclick="closeModal('viewRouteModal')">&times;</span>
                    <h2>${route.routeNumber} - ${route.routeName}</h2>
                    
                    <div class="route-details">
                        <div class="detail-item">
                            <strong>Transport Type</strong>
                            <span>${route.transportType.toUpperCase()}</span>
                        </div>
                        <div class="detail-item">
                            <strong>Status</strong>
                            <span>${getStatusBadge(route.status)}</span>
                        </div>
                        <div class="detail-item">
                            <strong>Origin</strong>
                            <span>${route.origin}</span>
                        </div>
                        <div class="detail-item">
                            <strong>Destination</strong>
                            <span>${route.destination}</span>
                        </div>
                        <div class="detail-item">
                            <strong>Distance</strong>
                            <span>${route.distance} km</span>
                        </div>
                        <div class="detail-item">
                            <strong>Duration</strong>
                            <span>${route.estimatedDuration} mins</span>
                        </div>
                        <div class="detail-item">
                            <strong>Base Price</strong>
                            <span>$${route.basePrice}</span>
                        </div>
                    </div>
                    
                    <h3 class="mt-20">Stops (${route.stops.length})</h3>
                    <div class="stops-list">
                        ${route.stops.map(stop => `
                            <div class="stop-item">
                                <span>${stop.sequence}. ${stop.stopName}</span>
                                <span>${stop.arrivalOffset} mins</span>
                            </div>
                        `).join('')}
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', modalContent);
    } catch (error) {
        showError('Failed to load route details: ' + error.message);
    }
}

// Edit route
async function editRoute(routeId) {
    try {
        const route = await apiCall(`/routes/${routeId}`);
        
        // Fill form
        document.getElementById('routeId').value = route.routeId;
        document.getElementById('routeNumber').value = route.routeNumber;
        document.getElementById('routeName').value = route.routeName;
        document.getElementById('transportType').value = route.transportType;
        document.getElementById('origin').value = route.origin;
        document.getElementById('destination').value = route.destination;
        document.getElementById('distance').value = route.distance;
        document.getElementById('estimatedDuration').value = route.estimatedDuration;
        document.getElementById('basePrice').value = route.basePrice;
        
        // Fill stops
        const stopsContainer = document.getElementById('stopsContainer');
        stopsContainer.innerHTML = route.stops.map(stop => `
            <div class="stop-item">
                <input type="text" class="stop-name" placeholder="Stop name" value="${stop.stopName}">
                <input type="number" class="stop-sequence" placeholder="Sequence" value="${stop.sequence}">
                <input type="number" class="stop-offset" placeholder="Minutes from origin" value="${stop.arrivalOffset}">
                <button type="button" class="remove-stop" onclick="this.parentElement.remove()">×</button>
            </div>
        `).join('');
        
        document.getElementById('modalTitle').textContent = 'Edit Route';
        openModal('routeModal');
    } catch (error) {
        showError('Failed to load route: ' + error.message);
    }
}

// Delete route
async function deleteRoute(routeId) {
    if (!confirm('Are you sure you want to delete this route?')) {
        return;
    }

    try {
        await apiCall(`/routes/${routeId}`, 'DELETE');
        showSuccess('Route deleted successfully');
        loadRoutes();
    } catch (error) {
        showError('Failed to delete route: ' + error.message);
    }
}

// Submit route form
async function submitRouteForm(e) {
    e.preventDefault();

    const routeId = document.getElementById('routeId').value;
    const formData = {
        routeNumber: document.getElementById('routeNumber').value,
        routeName: document.getElementById('routeName').value,
        transportType: document.getElementById('transportType').value,
        origin: document.getElementById('origin').value,
        destination: document.getElementById('destination').value,
        distance: parseFloat(document.getElementById('distance').value),
        estimatedDuration: parseInt(document.getElementById('estimatedDuration').value),
        basePrice: parseFloat(document.getElementById('basePrice').value),
        stops: []
    };

    // Get stops
    const stopItems = document.querySelectorAll('.stop-item');
    stopItems.forEach((item, index) => {
        const name = item.querySelector('.stop-name').value;
        const sequence = item.querySelector('.stop-sequence').value;
        const offset = item.querySelector('.stop-offset').value;

        if (name && sequence && offset) {
            formData.stops.push({
                stopId: `stop-${Date.now()}-${index}`,
                stopName: name,
                latitude: 0.0,
                longitude: 0.0,
                sequence: parseInt(sequence),
                arrivalOffset: parseInt(offset)
            });
        }
    });

    try {
        if (routeId) {
            // Update existing route
            await apiCall(`/routes/${routeId}`, 'PUT', formData);
            showSuccess('Route updated successfully');
        } else {
            // Create new route
            await apiCall('/routes', 'POST', formData);
            showSuccess('Route created successfully');
        }

        closeModal('routeModal');
        document.getElementById('routeForm').reset();
        document.getElementById('routeId').value = '';
        loadRoutes();
    } catch (error) {
        showError('Failed to save route: ' + error.message);
    }
}

// Add stop field
function addStopField() {
    const container = document.getElementById('stopsContainer');
    const stopItem = document.createElement('div');
    stopItem.className = 'stop-item';
    stopItem.innerHTML = `
        <input type="text" class="stop-name" placeholder="Stop name">
        <input type="number" class="stop-sequence" placeholder="Sequence">
        <input type="number" class="stop-offset" placeholder="Minutes from origin">
        <button type="button" class="remove-stop" onclick="this.parentElement.remove()">×</button>
    `;
    container.appendChild(stopItem);
}

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    // Load routes
    loadRoutes();

    // Filter buttons
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            
            const filter = this.dataset.filter;
            currentFilter = filter;
            
            if (filter === 'all') {
                loadRoutes();
            } else {
                loadRoutes(filter);
            }
        });
    });

    // Add route button
    const addBtn = document.getElementById('addRouteBtn');
    if (addBtn) {
        addBtn.addEventListener('click', function() {
            document.getElementById('routeForm').reset();
            document.getElementById('routeId').value = '';
            document.getElementById('modalTitle').textContent = 'Add New Route';
            
            // Reset stops container
            const stopsContainer = document.getElementById('stopsContainer');
            stopsContainer.innerHTML = `
                <div class="stop-item">
                    <input type="text" class="stop-name" placeholder="Stop name">
                    <input type="number" class="stop-sequence" placeholder="Sequence">
                    <input type="number" class="stop-offset" placeholder="Minutes from origin">
                </div>
            `;
            
            openModal('routeModal');
        });
    }

    // Add stop button
    const addStopBtn = document.getElementById('addStopBtn');
    if (addStopBtn) {
        addStopBtn.addEventListener('click', addStopField);
    }

    // Form submit
    const routeForm = document.getElementById('routeForm');
    if (routeForm) {
        routeForm.addEventListener('submit', submitRouteForm);
    }

    // Cancel button
    const cancelBtn = document.getElementById('cancelBtn');
    if (cancelBtn) {
        cancelBtn.addEventListener('click', () => closeModal('routeModal'));
    }
});