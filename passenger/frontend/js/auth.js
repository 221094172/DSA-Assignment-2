// auth.js
const API_BASE_URL = 'http://localhost:9091/api/passengers';

// Check if user is logged in
function checkAuth() {
    const token = localStorage.getItem('authToken');
    const currentPage = window.location.pathname.split('/').pop();
    
    if (!token && currentPage === 'dashboard.html') {
        window.location.href = 'login.html';
        return false;
    }
    
    if (token && (currentPage === 'login.html' || currentPage === 'register.html')) {
        window.location.href = 'dashboard.html';
        return false;
    }
    
    return true;
}

// Register form handler
if (document.getElementById('registerForm')) {
    document.getElementById('registerForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const formData = {
            username: document.getElementById('username').value,
            email: document.getElementById('email').value,
            password: document.getElementById('password').value,
            firstName: document.getElementById('firstName').value || undefined,
            lastName: document.getElementById('lastName').value || undefined,
            phoneNumber: document.getElementById('phoneNumber').value || undefined
        };
        
        const confirmPassword = document.getElementById('confirmPassword').value;
        
        // Validate passwords match
        if (formData.password !== confirmPassword) {
            showError('Passwords do not match');
            return;
        }
        
        try {
            const response = await fetch(`${API_BASE_URL}/register`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(formData)
            });
            
            const data = await response.json();
            
            if (!response.ok) {
                throw new Error(data.message || 'Registration failed');
            }
            
            showSuccess('Registration successful! Redirecting to login...');
            setTimeout(() => {
                window.location.href = 'login.html';
            }, 2000);
            
        } catch (error) {
            showError(error.message);
        }
    });
}

// Login form handler
if (document.getElementById('loginForm')) {
    document.getElementById('loginForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const formData = {
            username: document.getElementById('username').value,
            password: document.getElementById('password').value
        };
        
        try {
            const response = await fetch(`${API_BASE_URL}/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(formData)
            });
            
            const data = await response.json();
            
            if (!response.ok) {
                throw new Error(data.message || 'Login failed');
            }
            
            // Store auth data
            localStorage.setItem('authToken', data.token);
            localStorage.setItem('passengerId', data.passengerId);
            localStorage.setItem('username', data.username);
            localStorage.setItem('email', data.email);
            
            // Redirect to dashboard
            window.location.href = 'dashboard.html';
            
        } catch (error) {
            showError(error.message);
        }
    });
}

// Logout handler
if (document.getElementById('logoutBtn')) {
    document.getElementById('logoutBtn').addEventListener('click', () => {
        localStorage.clear();
        window.location.href = 'login.html';
    });
}

// Load user info in dashboard
if (window.location.pathname.includes('dashboard.html')) {
    checkAuth();
    
    const username = localStorage.getItem('username');
    if (username && document.getElementById('userWelcome')) {
        document.getElementById('userWelcome').textContent = `Welcome, ${username}!`;
    }
    
    loadProfile();
}

// Load profile
async function loadProfile() {
    const passengerId = localStorage.getItem('passengerId');
    const token = localStorage.getItem('authToken');
    
    if (!passengerId || !token) return;
    
    try {
        const response = await fetch(`${API_BASE_URL}/${passengerId}`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        
        if (!response.ok) {
            throw new Error('Failed to load profile');
        }
        
        const profile = await response.json();
        displayProfile(profile);
        
    } catch (error) {
        console.error('Error loading profile:', error);
        if (document.getElementById('profileInfo')) {
            document.getElementById('profileInfo').innerHTML = 
                `<p class="error-message">Failed to load profile</p>`;
        }
    }
}

// Display profile
function displayProfile(profile) {
    const profileInfo = document.getElementById('profileInfo');
    if (!profileInfo) return;
    
    profileInfo.innerHTML = `
        <p><strong>Username:</strong> <span>${profile.username}</span></p>
        <p><strong>Email:</strong> <span>${profile.email}</span></p>
        ${profile.firstName ? `<p><strong>First Name:</strong> <span>${profile.firstName}</span></p>` : ''}
        ${profile.lastName ? `<p><strong>Last Name:</strong> <span>${profile.lastName}</span></p>` : ''}
        ${profile.phoneNumber ? `<p><strong>Phone:</strong> <span>${profile.phoneNumber}</span></p>` : ''}
        <p><strong>Status:</strong> <span class="ticket-status ${profile.status}">${profile.status}</span></p>
        <p><strong>Member Since:</strong> <span>${new Date(profile.createdAt).toLocaleDateString()}</span></p>
    `;
}

// Show error message
function showError(message) {
    const errorDiv = document.getElementById('errorMessage');
    if (errorDiv) {
        errorDiv.textContent = message;
        errorDiv.style.display = 'block';
        
        setTimeout(() => {
            errorDiv.style.display = 'none';
        }, 5000);
    }
}

// Show success message
function showSuccess(message) {
    const successDiv = document.getElementById('successMessage');
    if (successDiv) {
        successDiv.textContent = message;
        successDiv.style.display = 'block';
        
        setTimeout(() => {
            successDiv.style.display = 'none';
        }, 5000);
    }
}