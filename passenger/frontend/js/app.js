// app.js
// Navigation handler for dashboard
if (window.location.pathname.includes('dashboard.html')) {
    const navItems = document.querySelectorAll('.nav-item');
    const sections = document.querySelectorAll('.content-section');
    
    navItems.forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            
            // Remove active class from all nav items and sections
            navItems.forEach(nav => nav.classList.remove('active'));
            sections.forEach(section => section.classList.remove('active'));
            
            // Add active class to clicked nav item
            item.classList.add('active');
            
            // Show corresponding section
            const sectionId = item.getAttribute('data-section') + 'Section';
            const section = document.getElementById(sectionId);
            if (section) {
                section.classList.add('active');
            }
        });
    });
}

// Check API health on page load
async function checkAPIHealth() {
    try {
        const response = await fetch('http://localhost:9091/api/passengers/health');
        const health = await response.json();
        console.log('API Health:', health);
    } catch (error) {
        console.error('API is not available:', error);
    }
}

// Run health check
checkAPIHealth();