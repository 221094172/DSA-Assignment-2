// API Base URL
const API_BASE_URL = 'http://localhost:9095/api/tickets';

// Current user
let currentUser = null;

// DOM Elements
const loginSection = document.getElementById('loginSection');
const mainContent = document.getElementById('mainContent');
const loginForm = document.getElementById('loginForm');
const purchaseForm = document.getElementById('purchaseForm');
const validateForm = document.getElementById('validateForm');
const logoutBtn = document.getElementById('logoutBtn');
const userName = document.getElementById('userName');
const purchaseResult = document.getElementById('purchaseResult');
const validateResult = document.getElementById('validateResult');
const ticketsList = document.getElementById('ticketsList');

// Tab Management
const tabBtns = document.querySelectorAll('.tab-btn');
const tabContents = document.querySelectorAll('.tab-content');

tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
        const tabName = btn.dataset.tab;
        
        // Update active tab button
        tabBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        
        // Update active tab content
        tabContents.forEach(content => {
            content.classList.remove('active');
            content.style.display = 'none';
        });
        
        const activeTab = document.getElementById(`${tabName}Tab`);
        activeTab.classList.add('active');
        activeTab.style.display = 'block';
        
        // Load data for specific tabs
        if (tabName === 'myTickets') {
            loadMyTickets();
        }
    });
});

// Filter Management
const filterBtns = document.querySelectorAll('.filter-btn');

filterBtns.forEach(btn => {
    btn.addEventListener('click', () => {
        filterBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        
        const status = btn.dataset.status;
        loadMyTickets(status === 'all' ? null : status);
    });
});

// Login Form
loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const passengerId = document.getElementById('passengerId').value;
    
    try {
        // Verify passenger exists (call Passenger Service)
        const response = await fetch(`http://localhost:9091/api/passengers/${passengerId}`);
        
        if (response.ok) {
            const passenger = await response.json();
            currentUser = passenger;
            
            // Show main content
            loginSection.style.display = 'none';
            mainContent.classList.remove('hidden');
            userName.textContent = `Welcome, ${passenger.username}!`;
            
            showNotification('Login successful!', 'success');
            loadMyTickets();
        } else {
            showNotification('Passenger not found. Please check your ID.', 'error');
        }
    } catch (error) {
        console.error('Login error:', error);
        showNotification('Login failed. Please try again.', 'error');
    }
});

// Logout
logoutBtn.addEventListener('click', () => {
    currentUser = null;
    loginSection.style.display = 'block';
    mainContent.classList.add('hidden');
    loginForm.reset();
    showNotification('Logged out successfully', 'info');
});

// Purchase Ticket Form
purchaseForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    if (!currentUser) {
        showNotification('Please login first', 'error');
        return;
    }
    
    const tripId = document.getElementById('tripId').value;
    const ticketType = document.getElementById('ticketType').value;
    const paymentMethod = document.getElementById('paymentMethod').value;
    
    const purchaseData = {
        passengerId: currentUser.passengerId,
        tripId: tripId,
        ticketType: ticketType,
        paymentMethod: paymentMethod
    };
    
    try {
        showResult(purchaseResult, 'Processing your ticket purchase...', 'info');
        
        const response = await fetch(API_BASE_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(purchaseData)
        });
        
        const result = await response.json();
        
        if (response.ok) {
            showResult(purchaseResult, `
                <h3>✅ Ticket Purchased Successfully!</h3>
                <p><strong>Ticket ID:</strong> ${result.ticketId}</p>
                <p><strong>QR Code:</strong> ${result.qrCode}</p>
                <p><strong>Price:</strong> $${result.price}</p>
                <p><strong>Status:</strong> ${result.status}</p>
                <p>${result.message}</p>
            `, 'success');
            
            purchaseForm.reset();
            showNotification('Ticket purchased successfully!', 'success');
            
            // Refresh tickets list
            setTimeout(() => loadMyTickets(), 2000);
        } else {
            showResult(purchaseResult, `
                <h3>❌ Purchase Failed</h3>
                <p>${result.message || 'Unknown error occurred'}</p>
            `, 'error');
            showNotification('Purchase failed', 'error');
        }
    } catch (error) {
        console.error('Purchase error:', error);
        showResult(purchaseResult, `
            <h3>❌ Purchase Failed</h3>
            <p>Network error. Please try again.</p>
        `, 'error');
        showNotification('Purchase failed', 'error');
    }
});

// Validate Ticket Form
validateForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const ticketId = document.getElementById('validateTicketId').value;
    const qrCode = document.getElementById('validateQRCode').value;
    const validatorId = document.getElementById('validatorId').value;
    
    const validationData = {
        ticketId: ticketId,
        qrCode: qrCode,
        validatorId: validatorId
    };
    
    try {
        showResult(validateResult, 'Validating ticket...', 'info');
        
        const response = await fetch(`${API_BASE_URL}/${ticketId}/validate`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(validationData)
        });
        
        const result = await response.json();
        
        if (response.ok && result.isValid) {
            showResult(validateResult, `
                <h3>✅ Ticket Validated Successfully!</h3>
                <p><strong>Ticket ID:</strong> ${result.ticketId}</p>
                <p><strong>Passenger ID:</strong> ${result.passengerId}</p>
                <p><strong>Validated At:</strong> ${new Date(result.validatedAt).toLocaleString()}</p>
                <p>${result.message}</p>
            `, 'success');
            
            validateForm.reset();
            showNotification('Ticket validated successfully!', 'success');
        } else {
            showResult(validateResult, `
                <h3>❌ Validation Failed</h3>
                <p>${result.message || 'Ticket is not valid'}</p>
            `, 'error');
            showNotification('Validation failed', 'error');
        }
    } catch (error) {
        console.error('Validation error:', error);
        showResult(validateResult, `
            <h3>❌ Validation Failed</h3>
            <p>Network error. Please try again.</p>
        `, 'error');
        showNotification('Validation failed', 'error');
    }
});

// Load My Tickets
async function loadMyTickets(status = null) {
    if (!currentUser) {
        return;
    }
    
    ticketsList.innerHTML = '<p class="loading">Loading tickets...</p>';
    
    try {
        let url = `${API_BASE_URL}/passenger/${currentUser.passengerId}`;
        if (status) {
            url += `?status=${status}`;
        }
        
        const response = await fetch(url);
        
        if (response.ok) {
            const tickets = await response.json();
            displayTickets(tickets);
        } else {
            ticketsList.innerHTML = '<p class="loading">Failed to load tickets</p>';
        }
    } catch (error) {
        console.error('Load tickets error:', error);
        ticketsList.innerHTML = '<p class="loading">Network error. Please try again.</p>';
    }
}

// Display Tickets
function displayTickets(tickets) {
    if (tickets.length === 0) {
        ticketsList.innerHTML = '<p class="loading">No tickets found</p>';
        return;
    }
    
    ticketsList.innerHTML = '';
    
    tickets.forEach(ticket => {
        const ticketCard = createTicketCard(ticket);
        ticketsList.appendChild(ticketCard);
    });
}

// Create Ticket Card
function createTicketCard(ticket) {
    const card = document.createElement('div');
    card.className = 'ticket-card';
    
    const statusColor = getStatusColor(ticket.status);
    card.style.background = statusColor;
    
    card.innerHTML = `
        <div class="ticket-header">
            <div class="ticket-id">ID: ${ticket.ticketId.substring(0, 8)}...</div>
            <div class="ticket-status">${ticket.status}</div>
        </div>
        <div class="ticket-body">
            <div class="ticket-route">${ticket.routeName}</div>
            <div class="ticket-details">
                <div>📍 Route: ${ticket.routeNumber}</div>
                <div>🎫 Type: ${ticket.ticketType}</div>
                <div>💰 Price: $${ticket.price}</div>
                <div>📅 Valid: ${new Date(ticket.validFrom).toLocaleDateString()}</div>
                <div>⏰ Until: ${new Date(ticket.validUntil).toLocaleString()}</div>
            </div>
        </div>
        <div class="ticket-qr">
            🔲 ${ticket.qrCode}
        </div>
        <div class="ticket-actions">
            <button onclick="viewTicketDetails('${ticket.ticketId}')">View Details</button>
            ${ticket.status === 'PAID' ? `<button onclick="cancelTicket('${ticket.ticketId}')">Cancel</button>` : ''}
        </div>
    `;
    
    return card;
}

// Get Status Color
function getStatusColor(status) {
    switch (status) {
        case 'CREATED':
            return 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)';
        case 'PAID':
            return 'linear-gradient(135deg, #48bb78 0%, #38a169 100%)';
        case 'VALIDATED':
            return 'linear-gradient(135deg, #4299e1 0%, #3182ce 100%)';
        case 'EXPIRED':
            return 'linear-gradient(135deg, #a0aec0 0%, #718096 100%)';
        case 'CANCELLED':
            return 'linear-gradient(135deg, #f56565 0%, #e53e3e 100%)';
        default:
            return 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)';
    }
}

// View Ticket Details
async function viewTicketDetails(ticketId) {
    try {
        const response = await fetch(`${API_BASE_URL}/${ticketId}`);
        
        if (response.ok) {
            const ticket = await response.json();
            
            const details = `
                Ticket Details:
                
                ID: ${ticket.ticketId}
                Passenger: ${ticket.passengerId}
                Route: ${ticket.routeName} (${ticket.routeNumber})
                Type: ${ticket.ticketType}
                Price: $${ticket.price}
                Status: ${ticket.status}
                QR Code: ${ticket.qrCode}
                
                Purchase Date: ${new Date(ticket.purchaseDate).toLocaleString()}
                Valid From: ${new Date(ticket.validFrom).toLocaleString()}
                Valid Until: ${new Date(ticket.validUntil).toLocaleString()}
                
                ${ticket.validatedAt ? `Validated At: ${new Date(ticket.validatedAt).toLocaleString()}` : ''}
                ${ticket.paymentId ? `Payment ID: ${ticket.paymentId}` : ''}
                ${ticket.transactionReference ? `Transaction: ${ticket.transactionReference}` : ''}
            `;
            
            alert(details);
        } else {
            showNotification('Failed to load ticket details', 'error');
        }
    } catch (error) {
        console.error('View details error:', error);
        showNotification('Network error', 'error');
    }
}

// Cancel Ticket
async function cancelTicket(ticketId) {
    if (!confirm('Are you sure you want to cancel this ticket?')) {
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE_URL}/${ticketId}/cancel`, {
            method: 'PUT'
        });
        
        if (response.ok) {
            showNotification('Ticket cancelled successfully', 'success');
            loadMyTickets();
        } else {
            const error = await response.json();
            showNotification(error.message || 'Failed to cancel ticket', 'error');
        }
    } catch (error) {
        console.error('Cancel ticket error:', error);
        showNotification('Network error', 'error');
    }
}

// Show Result
function showResult(element, message, type) {
    element.innerHTML = message;
    element.className = `result-box ${type}`;
    element.classList.remove('hidden');
    
    // Auto-hide after 10 seconds
    setTimeout(() => {
        element.classList.add('hidden');
    }, 10000);
}

// Show Notification Toast
function showNotification(message, type = 'info') {
    const notification = document.getElementById('notification');
    notification.textContent = message;
    notification.className = `notification ${type}`;
    notification.classList.remove('hidden');
    
    // Auto-hide after 3 seconds
    setTimeout(() => {
        notification.classList.add('hidden');
    }, 3000);
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    // Set initial tab display
    tabContents.forEach((content, index) => {
        if (index !== 0) {
            content.style.display = 'none';
        }
    });
});