# Use an official Dart image with Flutter SDK installed
FROM cirrusci/flutter:stable

# Set the working directory
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install dependencies
RUN flutter pub get

# Build the Flutter web app
RUN flutter build web

# Expose the web directory as a volume to be used by the host system
VOLUME ["/app/build/web"]

# Set the entrypoint to a bash shell to keep the container running
ENTRYPOINT ["bash"]
