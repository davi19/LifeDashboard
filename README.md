# LifeDashboard

A web application built with Dancer2 (Perl) for managing a personal dashboard.

## Requirements

### Local Environment
- Perl 5.x or higher
- PostgreSQL
- cpanm (Perl module manager)

### Docker Environment
- Docker
- Docker Compose (optional)

## Environment Variables

### Development
- `DB_URL_DEV` - PostgreSQL server URL (e.g., `localhost` or `db.example.com`)
- `DB_USER_DEV` - Database user
- `DB_PASSWORD_DEV` - Database password

### Production
- `DB_URL` - PostgreSQL server URL
- `DB_USER` - Database user
- `DB_PASSWORD` - Database password

### Optional
- `DANCER_ENVIRONMENT` - Execution environment (`development` or `production`, default: `production`)
- `DANCER_PORT` - Application port (default: `5000`)

## Local Installation

### 1. Install dependencies
```bash
cpanm --installdeps .

```

### 2. Configure environment variables
```bash
export DB_URL_DEV="localhost"
export DB_USER_DEV="your_username"
export DB_PASSWORD_DEV="your_password"
export DANCER_ENVIRONMENT="development"
```

### 3. Run the application
```bash
# Development mode
plackup bin/app.psgi

```

The application will be available at `http://localhost:5000`

## Installation with Docker

### 1. Build the image
```bash
docker build -t lifedashboard .

```

### 2. Run the container

#### Development
```bash
docker run -d \

--name lifedashboard \

-p 5000:5000 \

-e DANCER_ENVIRONMENT=development \

-e DB_URL_DEV=your_db_host \

-e DB_USER_DEV=your_username \

-e DB_PASSWORD_DEV=your_password \

lifedashboard
```

#### Production
```bash
docker run -d \

--name lifedashboard \

-p 5000:5000 \

-e DANCER_ENVIRONMENT=production \

-e DB_URL=your_db_host \

-e DB_USER=your_username \

-e DB_PASSWORD=your_password \

lifedashboard


### 3. Docker Compose (optional)

Create a `docker-compose.yml` file:

`yaml
version: '3.8'

services:

app:

build: .

ports: 
- "5000:5000" 
environment: 
- DANCER_ENVIRONMENT=production 
- DB_URL=postgres 
- DB_USER=lifedashboard 
- DB_PASSWORD=secure_password 
depends_on: 
- postgres 
restart: unless-stopped 

postgres: 
image: postgres:15-alpine 
environment: 
- POSTGRES_DB=defaultdb 
- POSTGRES_USER=lifedashboard 
- POSTGRES_PASSWORD=safe_password 
volumes: 
- postgres_data:/var/lib/postgresql/data 
restart: unless-stopped

volumes: 
postgres_data:
```

Run with:
```bash
docker-compose up -d
```

## Project Structure

```
LifeDashboard/
├──bin/
│ └── app.psgi # Application entry point
├── environments/
│ ├── development.yml # Development configurations
│ └── production.yml # Production configurations
├── lib/
│ └── LifeDashboard.pm # Main application module
├── public/ # Static files (CSS, JS, images)
├── views/ # Templates
├── config.yml # Main configuration
├── Dockerfile # Docker configuration
├── Makefile.PL # Perl dependencies
└── README.md # This file

## Logs

- **Development**: Logs are displayed in the console (STDOUT)

- **Production**: Logs are saved to files in the `logs/` directory

## Troubleshooting

### Database connection error
Check if:

1. Environment variables are correctly configured
2. PostgreSQL is running and accessible
3. Credentials are correct
4. Port 15560 is accessible (default port configured)

### Container does not start
```bash
# View container logs docker logs lifedashboard

# Check environment variables docker inspect lifedashboard

```

## Development

To contribute to the project:

1. Clone the repository
2. Create a branch for your feature
3. Make your changes
4. Run the tests (if available)
5. Submit a pull request

## License

Perl License (same as Perl)
