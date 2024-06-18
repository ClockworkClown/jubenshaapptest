# Use the official Flutter Docker image with stable channel
FROM google/dart:latest

# Set environment variables
ENV FLUTTER_HOME /opt/flutter
ENV PATH $FLUTTER_HOME/bin:$PATH

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y git unzip && \
    apt-get clean

# Clone your Flutter web app repository
RUN git clone https://github.com/your-username/jubenshaapptest.git /app

WORKDIR /app/frontend

# Install Flutter dependencies
RUN flutter pub get

# Build Flutter web app
RUN flutter build web

# Expose the port your app runs on
EXPOSE 8080

# Run your Flutter web app when the container starts
CMD ["flutter", "run", "-d", "web"]
