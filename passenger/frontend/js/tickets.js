// tickets.js
const API_BASE_URL = 'http://localhost:9091/api/passengers';

// Load tickets when dashboard loads
if (window.location.pathname.includes('dashboard.html')) {
    loadTickets();
    
    // Filter buttons
    const filterButtons = document.querySelectorAll('.filter-btn');
    filterButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            filterButtons.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            
            const filter = btn.getAttribute('data-filter');
            filterTickets(filter);
        });
    });
}

// Load tickets
async function loadTickets() {
    const passengerId = localStorage.getItem('passengerId');
    const token = localStorage.getItem('authToken');
    
    if (!passengerId || !token) return;
    
    try {
        const response = await fetch(`${API_BASE_URL}/${passengerId}/tickets`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        
        if (!response.ok) {
            throw new Error('Failed to load tickets');
        }
        
        const tickets = await response.json();
        displayTickets(tickets);
        
        // Store tickets globally for filtering
        window.allTickets = tickets;
        
    } catch (error) {
        console.error('Error loading tickets:', error);
        const ticketsList = document.getElementById('ticketsList');
        if (ticketsList) {
            ticketsList.innerHTML = '<p class="error-message">Failed to load tickets. Please try again later.</p>';
        }
    }
}

// Display tickets
function displayTickets(tickets) {
    const ticketsList = document.getElementById('ticketsList');
    if (!ticketsList) return;
    
    if (tickets.length === 0) {
        ticketsList.innerHTML = '<p class="info-message">You don\'t have any tickets yet. Book your first ticket now!</p>';
        return;
    }
    
    ticketsList.innerHTML = tickets.map(ticket => `
        <div class="ticket-card" data-status="${ticket.status}">
            <div class="ticket-icon">🎫</div>
            <div class="ticket-info">
                <h3>${formatTicketType(ticket.ticketType)}</h3>
                <p><strong>Ticket ID:</strong> ${ticket.ticketId}</p>
                <p><strong>Price:</strong> $${ticket.price}</p>
                <p><strong>Purchased:</strong> ${formatDate(ticket.purchasedAt)}</p>
                ${ticket.validFrom ? `<p><strong>Valid From:</strong> ${formatDate(ticket.validFrom)}</p>` : ''}
                ${ticket.validUntil ? `<p><strong>Valid Until:</strong> ${formatDate(ticket.validUntil)}</p>` : ''}
                ${ticket.usedAt ? `<p><strong>Used At:</strong> ${formatDate(ticket.usedAt)}</p>` : ''}
                <p><strong>QR Code:</strong> ${ticket.qrCode}</p>
            </div>
            <div class="ticket-status ${ticket.status}">${ticket.status}</div>
        </div>
    `).join('');
}

// Filter tickets
function filterTickets(filter) {
    const tickets = window.allTickets || [];
    
    if (filter === 'all') {
        displayTickets(tickets);
    } else {
        const filtered = tickets.filter(t => t.status === filter);
        displayTickets(filtered);
    }
}

// Format ticket type
function formatTicketType(type) {
    const types = {
        'single': 'Single Ride',
        'return': 'Return Ticket',
        'day-pass': 'Day Pass',
        'weekly-pass': 'Weekly Pass',
        'monthly-pass': 'Monthly Pass'
    };
    return types[type] || type;
}

// Format date
function formatDate(dateString) {
    if (!dateString) return 'N/A';
    
    // Handle Civil time format from Ballerina
    if (typeof dateString === 'object') {
        const { year, month, day, hour = 0, minute = 0 } = dateString;
        const date = new Date(year, month - 1, day, hour, minute);
        return date.toLocaleString();
    }
    
    const date = new Date(dateString);
    return date.toLocaleString();
}