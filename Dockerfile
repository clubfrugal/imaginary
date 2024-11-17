FROM golang:alpine AS build

# Installs libvips + required libraries
RUN set -ex; \
    apk add --no-cache \
        vips-dev \
        vips-magick \
        vips-heif \
        vips-jxl \
        vips-poppler \
        build-base;

# Copy imaginary sources
WORKDIR /app
COPY . .

RUN go build -o imaginary 

# Final image
FROM alpine

RUN set -ex; \
    apk upgrade --no-cache -a; \
    apk add --no-cache \
        tzdata \
        ca-certificates \
        netcat-openbsd \
        vips \
        vips-magick \
        vips-heif \
        vips-jxl \
        vips-poppler \
        ttf-dejavu \
        bash

WORKDIR /app

COPY --from=build /app/imaginary /app/imaginary

# Server port to listen
ENV PORT 9000
# https://github.com/h2non/imaginary#memory-issues
ENV MALLOC_ARENA_MAX=2

# Drop privileges for non-UID mapped environments
USER 65534

# Run the entrypoint command by default when the container starts.
ENTRYPOINT ["/app/imaginary"]

# Expose the server TCP port
EXPOSE ${PORT}

HEALTHCHECK CMD nc -z 127.0.0.1 "$PORT" || exit 1