# Use the official Flutter Docker image with stable channel
FROM google/dart:latest

# Set environment variables
ENV FLUTTER_HOME /opt/flutter
ENV PATH $FLUTTER_HOME/bin:$PATH

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    unzip \
    curl \
    gnupg2 \
    && apt-get clean

# Add GPG key for Dart repository
RUN curl https://storage.googleapis.com/download.dartlang.org/linux/debian/gpg | apt-key add -

# Add Dart repository to apt sources
RUN echo "deb https://storage.googleapis.com/download.dartlang.org/linux/debian/ stable main" > /etc/apt/sources.list.d/dart_stable.list

# Update apt and install Dart SDK
RUN apt-get update && \
    apt-get install -y dart

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
