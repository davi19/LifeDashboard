
# Use Perl official image
FROM perl:5.38-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    cpanminus \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy dependency files first for better layer caching
COPY cpanfile Makefile.PL ./

# Install Perl dependencies from project definition
RUN cpanm --notest --installdeps .

# Copy application files
COPY . .

# Set environment variables defaults (can be overridden)
ENV DANCER_ENVIRONMENT=production \
    DANCER_PORT=5000

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/ || exit 1

# Run the application with Starman (production PSGI server)
CMD ["starman", "--port", "5000", "--workers", "4", "bin/app.psgi"]
