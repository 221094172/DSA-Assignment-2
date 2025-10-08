FROM ballerina/ballerina:2201.8.0

WORKDIR /app

# Copy backend files
COPY backend/*.toml ./
COPY backend/*.bal ./

# Copy frontend files
COPY frontend/ ./frontend/

# Build the Ballerina application
RUN bal build

# Expose port
EXPOSE 9095

# Run the service
CMD ["bal", "run", "service.bal"]