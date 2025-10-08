const PASSENGER_API = 'http://localhost:9091/api/passengers';
const TRANSPORT_API = 'http://localhost:9092/api/transport';
const TICKET_API = 'http://localhost:9095/api/tickets';
const PAYMENT_API = 'http://localhost:9094/api/payments';

if (window.location.pathname.includes('dashboard.html')) {
    loadTickets();
    loadAvailableTrips();

    const filterButtons = document.querySelectorAll('.filter-btn');
    filterButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            filterButtons.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');

            const filter = btn.getAttribute('data-filter');
            filterTickets(filter);
        });
    });

    const bookingForm = document.getElementById('bookTicketForm');
    if (bookingForm) {
        bookingForm.addEventListener('submit', handleBookTicket);
    }
}

async function loadAvailableTrips() {
    try {
        const response = await fetch(`${TRANSPORT_API}/trips?status=scheduled`);

        if (!response.ok) {
            throw new Error('Failed to load trips');
        }

        const trips = await response.json();
        displayAvailableTrips(trips);

    } catch (error) {
        console.error('Error loading trips:', error);
    }
}

function displayAvailableTrips(trips) {
    const tripSelect = document.getElementById('tripSelect');
    if (!tripSelect) return;

    if (trips.length === 0) {
        tripSelect.innerHTML = '<option value="">No trips available</option>';
        return;
    }

    tripSelect.innerHTML = '<option value="">Select a trip</option>' +
        trips.map(trip => {
            const departure = formatDateTime(trip.scheduledDeparture);
            return `<option value="${trip.tripId}" data-price="${trip.currentPrice}">${trip.tripId} - ${departure} - $${trip.currentPrice} (${trip.availableSeats} seats)</option>`;
        }).join('');
}

async function handleBookTicket(e) {
    e.preventDefault();

    const tripSelect = document.getElementById('tripSelect');
    const selectedOption = tripSelect.options[tripSelect.selectedIndex];
    const tripId = selectedOption.value;
    const seatNumber = document.getElementById('seatNumber').value;

    if (!tripId) {
        showError('Please select a trip');
        return;
    }

    const passengerId = localStorage.getItem('passengerId');
    const token = localStorage.getItem('authToken');

    if (!passengerId || !token) {
        showError('Please log in first');
        return;
    }

    const submitButton = e.target.querySelector('button[type="submit"]');
    submitButton.disabled = true;
    submitButton.textContent = 'Booking...';

    try {
        const ticketRequest = {
            passengerId: passengerId,
            tripId: tripId,
            seatNumber: seatNumber || 'A1',
            ticketType: 'standard'
        };

        const response = await fetch(`${TICKET_API}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(ticketRequest)
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || 'Failed to book ticket');
        }

        const ticketData = await response.json();

        showSuccess('Ticket booked successfully! Ticket ID: ' + ticketData.ticketId);

        e.target.reset();

        await loadTickets();

    } catch (error) {
        console.error('Error booking ticket:', error);
        showError(error.message || 'Failed to book ticket. Please try again.');
    } finally {
        submitButton.disabled = false;
        submitButton.textContent = 'Book Ticket';
    }
}

async function loadTickets() {
    const passengerId = localStorage.getItem('passengerId');
    const token = localStorage.getItem('authToken');

    if (!passengerId || !token) return;

    try {
        const response = await fetch(`${TICKET_API}/passenger/${passengerId}`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        if (!response.ok) {
            throw new Error('Failed to load tickets');
        }

        const tickets = await response.json();
        displayTickets(tickets);

        window.allTickets = tickets;

    } catch (error) {
        console.error('Error loading tickets:', error);
        const ticketsList = document.getElementById('ticketsList');
        if (ticketsList) {
            ticketsList.innerHTML = '<p class="error-message">Failed to load tickets. Please try again later.</p>';
        }
    }
}

function displayTickets(tickets) {
    const ticketsList = document.getElementById('ticketsList');
    if (!ticketsList) return;

    if (tickets.length === 0) {
        ticketsList.innerHTML = '<p class="info-message">You don\'t have any tickets yet. Book your first ticket now!</p>';
        return;
    }

    ticketsList.innerHTML = tickets.map(ticket => `
        <div class="ticket-card" data-status="${ticket.status}">
            <div class="ticket-header">
                <span class="ticket-icon">🎫</span>
                <span class="ticket-status-badge status-${ticket.status.toLowerCase()}">${ticket.status}</span>
            </div>
            <div class="ticket-info">
                <div class="ticket-row">
                    <span class="label">Ticket ID:</span>
                    <span class="value">${ticket.ticketId}</span>
                </div>
                <div class="ticket-row">
                    <span class="label">Trip ID:</span>
                    <span class="value">${ticket.tripId}</span>
                </div>
                <div class="ticket-row">
                    <span class="label">Seat:</span>
                    <span class="value">${ticket.seatNumber}</span>
                </div>
                <div class="ticket-row">
                    <span class="label">Price:</span>
                    <span class="value price">$${ticket.price}</span>
                </div>
                <div class="ticket-row">
                    <span class="label">Purchased:</span>
                    <span class="value">${formatDateTime(ticket.purchaseDate)}</span>
                </div>
                ${ticket.validUntil ? `
                <div class="ticket-row">
                    <span class="label">Valid Until:</span>
                    <span class="value">${formatDateTime(ticket.validUntil)}</span>
                </div>
                ` : ''}
                ${ticket.qrCode ? `
                <div class="ticket-row">
                    <span class="label">QR Code:</span>
                    <span class="value code">${ticket.qrCode}</span>
                </div>
                ` : ''}
            </div>
            ${ticket.status === 'CREATED' || ticket.status === 'PAID' ? `
            <div class="ticket-actions">
                <button class="btn btn-danger btn-sm" onclick="cancelTicket('${ticket.ticketId}')">Cancel Ticket</button>
            </div>
            ` : ''}
        </div>
    `).join('');
}

async function cancelTicket(ticketId) {
    if (!confirm('Are you sure you want to cancel this ticket?')) {
        return;
    }

    const token = localStorage.getItem('authToken');

    try {
        const response = await fetch(`${TICKET_API}/${ticketId}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        if (!response.ok) {
            throw new Error('Failed to cancel ticket');
        }

        showSuccess('Ticket cancelled successfully');
        await loadTickets();

    } catch (error) {
        console.error('Error cancelling ticket:', error);
        showError('Failed to cancel ticket. Please try again.');
    }
}

function filterTickets(filter) {
    const tickets = window.allTickets || [];

    if (filter === 'all') {
        displayTickets(tickets);
    } else {
        const statusMap = {
            'active': ['CREATED', 'PAID'],
            'used': ['VALIDATED'],
            'expired': ['EXPIRED'],
            'cancelled': ['CANCELLED']
        };

        const statuses = statusMap[filter] || [filter.toUpperCase()];
        const filtered = tickets.filter(t => statuses.includes(t.status));
        displayTickets(filtered);
    }
}

function formatDateTime(dateString) {
    if (!dateString) return 'N/A';

    if (typeof dateString === 'object') {
        const { year, month, day, hour = 0, minute = 0 } = dateString;
        const date = new Date(year, month - 1, day, hour, minute);
        return date.toLocaleString();
    }

    const date = new Date(dateString);
    return date.toLocaleString();
}

function showError(message) {
    const errorDiv = document.getElementById('errorMessage');
    if (errorDiv) {
        errorDiv.textContent = message;
        errorDiv.style.display = 'block';

        setTimeout(() => {
            errorDiv.style.display = 'none';
        }, 5000);
    } else {
        alert(message);
    }
}

function showSuccess(message) {
    const successDiv = document.getElementById('successMessage');
    if (successDiv) {
        successDiv.textContent = message;
        successDiv.style.display = 'block';

        setTimeout(() => {
            successDiv.style.display = 'none';
        }, 5000);
    } else {
        alert(message);
    }
}
