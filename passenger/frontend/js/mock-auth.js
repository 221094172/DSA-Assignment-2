// Mock API for demo without backend
const MOCK_MODE = true;

const mockUsers = [
  {
    passengerId: 'pass-001',
    username: 'demo',
    email: 'demo@example.com',
    password: 'demo123',
    firstName: 'Demo',
    lastName: 'User',
    phoneNumber: '1234567890',
    status: 'active',
    createdAt: new Date().toISOString()
  }
];

const mockTrips = [
  {
    tripId: 'trip-001',
    routeId: 'route-001',
    vehicleId: 'VEH-101',
    driverId: 'DRV-201',
    scheduledDeparture: { year: 2025, month: 10, day: 10, hour: 10, minute: 0 },
    scheduledArrival: { year: 2025, month: 10, day: 10, hour: 12, minute: 30 },
    status: 'scheduled',
    availableSeats: 45,
    totalSeats: 50,
    currentPrice: 25.50
  },
  {
    tripId: 'trip-002',
    routeId: 'route-002',
    vehicleId: 'VEH-102',
    driverId: 'DRV-202',
    scheduledDeparture: { year: 2025, month: 10, day: 10, hour: 14, minute: 30 },
    scheduledArrival: { year: 2025, month: 10, day: 10, hour: 16, minute: 0 },
    status: 'scheduled',
    availableSeats: 30,
    totalSeats: 40,
    currentPrice: 18.00
  },
  {
    tripId: 'trip-003',
    routeId: 'route-003',
    vehicleId: 'VEH-103',
    driverId: 'DRV-203',
    scheduledDeparture: { year: 2025, month: 10, day: 11, hour: 9, minute: 0 },
    scheduledArrival: { year: 2025, month: 10, day: 11, hour: 11, minute: 45 },
    status: 'scheduled',
    availableSeats: 25,
    totalSeats: 35,
    currentPrice: 32.00
  }
];

let mockTickets = [];

// Mock API wrapper
async function mockFetch(url, options = {}) {
  await new Promise(resolve => setTimeout(resolve, 300));

  const method = options.method || 'GET';
  const body = options.body ? JSON.parse(options.body) : null;

  if (url.includes('/register')) {
    if (method === 'POST') {
      const existingUser = mockUsers.find(u => u.username === body.username);
      if (existingUser) {
        return {
          ok: false,
          json: async () => ({ message: 'Username already exists' })
        };
      }

      const newUser = {
        passengerId: 'pass-' + Date.now(),
        username: body.username,
        email: body.email,
        password: body.password,
        firstName: body.firstName,
        lastName: body.lastName,
        phoneNumber: body.phoneNumber,
        status: 'active',
        createdAt: new Date().toISOString()
      };
      mockUsers.push(newUser);

      return {
        ok: true,
        json: async () => ({ ...newUser, password: undefined })
      };
    }
  }

  if (url.includes('/login')) {
    if (method === 'POST') {
      const user = mockUsers.find(u => u.username === body.username && u.password === body.password);
      if (!user) {
        return {
          ok: false,
          json: async () => ({ message: 'Invalid username or password' })
        };
      }

      return {
        ok: true,
        json: async () => ({
          token: 'mock-jwt-token-' + Date.now(),
          passengerId: user.passengerId,
          username: user.username,
          email: user.email,
          message: 'Login successful'
        })
      };
    }
  }

  if (url.match(/\/api\/passengers\/[^/]+$/)) {
    const passengerId = url.split('/').pop();
    const user = mockUsers.find(u => u.passengerId === passengerId);
    if (user) {
      return {
        ok: true,
        json: async () => ({ ...user, password: undefined })
      };
    }
  }

  if (url.includes('/api/transport/trips') && method === 'GET') {
    return {
      ok: true,
      json: async () => mockTrips
    };
  }

  if (url.includes('/api/tickets') && method === 'POST') {
    const newTicket = {
      ticketId: 'ticket-' + Date.now(),
      passengerId: body.passengerId,
      tripId: body.tripId,
      seatNumber: body.seatNumber,
      ticketType: body.ticketType,
      price: mockTrips.find(t => t.tripId === body.tripId)?.currentPrice || 25.00,
      status: 'CREATED',
      purchaseDate: new Date().toISOString(),
      validUntil: new Date(Date.now() + 24*60*60*1000).toISOString(),
      qrCode: 'QR-' + Math.random().toString(36).substring(7).toUpperCase()
    };
    mockTickets.push(newTicket);

    return {
      ok: true,
      json: async () => newTicket
    };
  }

  if (url.match(/\/api\/tickets\/passenger\/[^/]+$/)) {
    const passengerId = url.split('/').pop().split('?')[0];
    const userTickets = mockTickets.filter(t => t.passengerId === passengerId);
    return {
      ok: true,
      json: async () => userTickets
    };
  }

  if (url.match(/\/api\/tickets\/[^/]+$/) && method === 'DELETE') {
    const ticketId = url.split('/').pop();
    const ticketIndex = mockTickets.findIndex(t => t.ticketId === ticketId);
    if (ticketIndex !== -1) {
      mockTickets[ticketIndex].status = 'CANCELLED';
      return {
        ok: true,
        json: async () => ({ success: true, message: 'Ticket cancelled successfully' })
      };
    }
  }

  return {
    ok: false,
    json: async () => ({ message: 'Not found' })
  };
}

// Override fetch for mock mode
if (MOCK_MODE) {
  const originalFetch = window.fetch;
  window.fetch = function(url, options) {
    // Only mock our API calls
    if (url.includes('/api/')) {
      console.log('🎭 MOCK MODE: Intercepting', options?.method || 'GET', url);
      return mockFetch(url, options);
    }
    return originalFetch(url, options);
  };

  console.log('🎭 MOCK MODE ENABLED - Backend not required!');
  console.log('💡 Demo credentials: username="demo", password="demo123"');
}
