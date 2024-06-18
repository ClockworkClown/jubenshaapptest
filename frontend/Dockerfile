# Use an official Dart image with Flutter SDK installed
FROM cirrusci/flutter:stable

# Set the working directory inside the container
WORKDIR /app

# Copy the entire project directory into the container
COPY . .

# Install dependencies as non-root user
RUN adduser --disabled-password --gecos '' flutteruser \
    && chown -R flutteruser /app \
    && su flutteruser -c 'flutter pub get'

# Build the Flutter web app
RUN su flutteruser -c 'flutter build web'

# Expose the web directory as a volume to be used by the host system
VOLUME ["/app/build/web"]

# Set the entrypoint to a bash shell to keep the container running
ENTRYPOINT ["bash"]
