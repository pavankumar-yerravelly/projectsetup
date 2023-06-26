#!/bin/bash

# Usage: sh setup.sh start/stop
# Function to start Docker services and set up the MySQL database
function start_services() {
    # Update the system packages, install Docker, install Docker Compose, configure permissions, and add the user to the Docker group for convenient Docker usage
    sudo yum update -y

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        sudo yum install docker
    else
        echo "Docker is already installed"
    fi

    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo "Docker Compose is already installed"
    fi

    # Check if Docker group membership is already set
    if ! groups | grep -q '\bdocker\b'; then
        sudo gpasswd -a $USER docker
        newgrp docker
    else
        echo "User is already a member of the Docker group"
    fi

    # Check if Docker is not active
    if ! sudo systemctl is-active docker &> /dev/null; then
        # Start Docker
        sudo systemctl start docker

        # Check if Docker started successfully
        if sudo systemctl is-active docker &> /dev/null; then
            echo "Docker started successfully."
        else
            echo "Failed to start Docker."
            exit 1
        fi
    else
        echo "Docker is already running."
    fi

    # Check if the Docker Compose services are already running
    if docker-compose ps | grep "Up" > /dev/null; then
        echo "Services are already running."
        sleep 20
        docker exec -i ra_mysql sh -c "bash dbcreation.sh"
        echo "MySQL Db set up completed."
        exit
        exit
        exit 0
    fi

    # Start Docker Compose services
    docker-compose up -d

    # Check if the services started successfully
    if docker-compose ps | grep -v "Up" > /dev/null; then
        echo "Services started successfully."
        sleep 20
        docker exec -i ra_mysql sh -c "bash dbcreation.sh"
        echo "MySQL Db set up completed."
        exit
        exit
        exit 0
    else
        echo "Failed to start Docker Compose services."
        exit 1
    fi
}

# Function to stop Docker services
function stop_services() {
    # Check if Docker Compose services are running
    if docker-compose ps | grep "Up" > /dev/null; then
        # Stop Docker Compose services
        docker-compose down
        echo "Services stopped successfully."
    else
        echo "No running services found."
    fi
}

# Check the input parameter
if [[ "$1" == "start" ]]; then
    start_services
elif [[ "$1" == "stop" ]]; then
    stop_services
else
    echo "Invalid parameter. Please use 'start' or 'stop'."
    exit 1
fi
