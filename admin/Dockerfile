FROM ballerina/ballerina:2201.8.0

WORKDIR /app

# Copy backend files
COPY backend/*.bal ./
COPY backend/*.toml ./

# Build the Ballerina project
RUN bal build

# Copy frontend files
COPY frontend/ ./frontend/

EXPOSE 9096

CMD ["bal", "run"]