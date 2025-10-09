const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Transport Ticketing System</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 20px;
        }
        .container {
          max-width: 1200px;
          width: 100%;
          background: white;
          border-radius: 20px;
          box-shadow: 0 20px 60px rgba(0,0,0,0.3);
          overflow: hidden;
        }
        header {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 40px;
          text-align: center;
        }
        header h1 {
          font-size: 2.5rem;
          margin-bottom: 10px;
        }
        header p {
          font-size: 1.2rem;
          opacity: 0.9;
        }
        .apps-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
          gap: 30px;
          padding: 40px;
        }
        .app-card {
          background: #f8f9fa;
          border-radius: 15px;
          padding: 30px;
          text-align: center;
          transition: all 0.3s;
          border: 2px solid transparent;
        }
        .app-card:hover {
          transform: translateY(-5px);
          box-shadow: 0 10px 30px rgba(0,0,0,0.15);
          border-color: #667eea;
        }
        .app-icon {
          font-size: 4rem;
          margin-bottom: 20px;
        }
        .app-card h2 {
          font-size: 1.5rem;
          margin-bottom: 10px;
          color: #333;
        }
        .app-card p {
          color: #666;
          margin-bottom: 20px;
          line-height: 1.6;
        }
        .btn {
          display: inline-block;
          padding: 12px 30px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          text-decoration: none;
          border-radius: 25px;
          font-weight: 600;
          transition: all 0.3s;
        }
        .btn:hover {
          transform: scale(1.05);
          box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        .info-section {
          padding: 40px;
          background: #f8f9fa;
          border-top: 2px solid #e9ecef;
        }
        .info-section h3 {
          color: #333;
          margin-bottom: 20px;
          font-size: 1.5rem;
        }
        .features {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
          gap: 20px;
          margin-top: 20px;
        }
        .feature {
          background: white;
          padding: 20px;
          border-radius: 10px;
          border-left: 4px solid #667eea;
        }
        .feature h4 {
          color: #667eea;
          margin-bottom: 10px;
        }
        .feature p {
          color: #666;
          font-size: 0.9rem;
        }
        .warning {
          background: #fff3cd;
          border: 2px solid #ffc107;
          padding: 20px;
          margin: 20px 40px;
          border-radius: 10px;
          color: #856404;
        }
        .warning strong {
          display: block;
          margin-bottom: 10px;
          font-size: 1.1rem;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <header>
          <h1>🚌 Transport Ticketing System</h1>
          <p>Complete Multi-Service Transport Management Platform</p>
        </header>

        <div class="warning">
          <strong>⚠️ Important: Backend Services Required</strong>
          The frontend applications require Ballerina backend services to be running. To start the services, run the Docker containers for each service (passenger, transport, ticketing, payment, admin) or run the Ballerina services individually.
        </div>

        <div class="apps-grid">
          <div class="app-card">
            <div class="app-icon">👤</div>
            <h2>Passenger Portal</h2>
            <p>Register, login, browse trips, book tickets, and manage your bookings</p>
            <a href="/passenger/login.html" class="btn">Open Passenger Portal</a>
          </div>

          <div class="app-card">
            <div class="app-icon">🚌</div>
            <h2>Transport Management</h2>
            <p>Manage routes, schedule trips, track vehicles, and update trip statuses</p>
            <a href="/transport/index.html" class="btn">Open Transport System</a>
          </div>

          <div class="app-card">
            <div class="app-icon">⚙️</div>
            <h2>Admin Dashboard</h2>
            <p>Monitor system, manage all services, generate reports, and send notifications</p>
            <a href="/admin/index.html" class="btn">Open Admin Dashboard</a>
          </div>
        </div>

        <div class="info-section">
          <h3>✨ System Features</h3>
          <div class="features">
            <div class="feature">
              <h4>🎫 Ticket Booking</h4>
              <p>Complete booking workflow with trip selection and seat assignment</p>
            </div>
            <div class="feature">
              <h4>💳 Payment Processing</h4>
              <p>Integrated payment system with transaction tracking</p>
            </div>
            <div class="feature">
              <h4>🛣️ Route Management</h4>
              <p>Create and manage routes with stops, pricing, and schedules</p>
            </div>
            <div class="feature">
              <h4>📊 Analytics & Reports</h4>
              <p>Real-time statistics and comprehensive sales reports</p>
            </div>
            <div class="feature">
              <h4>🔔 Notifications</h4>
              <p>Real-time alerts for passengers about trips and disruptions</p>
            </div>
            <div class="feature">
              <h4>⚠️ Disruption Management</h4>
              <p>Publish and manage service disruptions across routes</p>
            </div>
          </div>
        </div>
      </div>
    </body>
    </html>
  `);
});

app.use('/passenger', express.static(path.join(__dirname, 'passenger/frontend')));
app.use('/transport', express.static(path.join(__dirname, 'transport/frontend')));
app.use('/admin', express.static(path.join(__dirname, 'admin/frontend')));
app.use('/ticketing', express.static(path.join(__dirname, 'ticketing/frontend')));

console.log('🚀 Transport Ticketing System Frontend Server');
console.log('================================================');
console.log('');
console.log('🌐 Server running on: http://localhost:' + PORT);
console.log('');
console.log('📱 Available Applications:');
console.log('  👤 Passenger Portal:      http://localhost:' + PORT + '/passenger/login.html');
console.log('  🚌 Transport Management:  http://localhost:' + PORT + '/transport/index.html');
console.log('  ⚙️  Admin Dashboard:       http://localhost:' + PORT + '/admin/index.html');
console.log('');
console.log('⚠️  Note: Backend services must be running for full functionality');
console.log('================================================');

app.listen(PORT, () => {
  console.log('\n✅ Server started successfully!\n');
});
