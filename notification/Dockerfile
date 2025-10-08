FROM ballerina/ballerina:2201.8.0

WORKDIR /app

# Copy Ballerina files
COPY backend/*.bal ./
COPY backend/Ballerina.toml ./
COPY backend/Config.toml ./

# Build the Ballerina project
RUN bal build

# Run the service
CMD bal run