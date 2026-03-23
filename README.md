# LifeDashboard (WIP)

A personal dashboard system built with Perl (Dancer2) designed to track daily life metrics such as goals, running, gym activity and reminders — with a long-term vision of integrating with low-power embedded devices (ESP32 + e-ink displays).

# What it is

LifeDashboard is a web application that centralizes personal data into a single system:
*  🏃 running tracking
* 🏋️ gym progress
* 🎯 objectives
* ⏰ reminders

The system is designed to act as a data source for external devices, not just a traditional web UI.

# 🔌 Vision (the real goal)

The long-term goal is to use this backend as a lightweight personal data hub, where: an ESP32 device fetches data periodically, renders dashboards and alerts on an e-ink display, operates with low power consumption and minimal interaction. turning this into a custom physical “life dashboard” device

# Key ideas

* backend-first system (UI is secondary)
* simple API layer for embedded consumption
* separation between data storage and visualization
* designed for low-resource clients (ESP32)

# Stack 
* Perl (Dancer2)
* PostgreSQL
* Docker (optional deployment)

# Running the project
### Local
Install dependencies
`cpanm --installdeps .`

### Configure environment variables

```export DB_URL_DEV="localhost"
export DB_USER_DEV="your_username"
export DB_PASSWORD_DEV="your_password"
export DANCER_ENVIRONMENT="development"
```
### Run

```plackup bin/app.psgi
Docker
docker build -t lifedashboard .
docker run -d \
  --name lifedashboard \
  -p 5000:5000 \
  -e DANCER_ENVIRONMENT=production \
  -e DB_URL=your_db_host \
  -e DB_USER=your_username \
  -e DB_PASSWORD=your_password \
  lifedashboard
```
  
# Why this exists

This project started as a way to learn and explore Perl (Dancer2) in a practical scenario, instead of just studying syntax in isolation.
At the same time, it became a playground to experiment with:
personal data tracking
backend system design
integration with embedded devices (ESP32 + e-ink)

 # Future directions

* REST/JSON endpoints optimized for embedded clients
* ESP32 client for periodic sync
* e-ink dashboard rendering (low refresh / low power)
* alert system (events → notifications on device)

# 🤝 Contribution
Feel free to fork, experiment or extend the project.
