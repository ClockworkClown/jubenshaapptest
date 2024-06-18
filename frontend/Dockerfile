# Use an official Flutter image as a base
FROM ubuntu:latest

# Set up necessary dependencies
RUN apt-get update \
    && apt-get install -y curl git unzip xz-utils zip \
    && apt-get clean

# Set up environment variables
ENV PATH "$PATH:/flutter/bin"

# Download and install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH "$PATH:/flutter/bin/cache/dart-sdk/bin"

# Run flutter doctor to install additional dependencies
RUN flutter doctor

# Copy the rest of your Flutter app code to the container
COPY . /frontend/
WORKDIR /frontend

# Install Flutter dependencies
RUN flutter pub get

# Build Flutter web app
RUN flutter build web

# Specify the build directory
EXPOSE 8080
CMD ["flutter", "run", "--release", "--no-sound-null-safety", "-d", "web"]
