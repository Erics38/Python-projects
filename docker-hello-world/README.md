# Docker Hello World

A simple Docker project demonstrating containerization with nginx serving static content.

## Original Project

This started as a basic Docker hello world application with:
- Static HTML website served by nginx
- Simple Dockerfile for containerization
- Basic CSS styling

## 🆕 Guestbook Enhancement

**NEW ADDITION:** Extended the original project to include a multi-container guestbook application with database persistence.

### Architecture

The enhanced application now includes:
- **Frontend**: Original nginx container + guestbook form
- **Backend API**: Node.js/Express server for guestbook operations
- **Database**: PostgreSQL for persistent storage
- **Docker Compose**: Orchestrates all three containers

### New Files Added

```
📁 Original files:
├── Dockerfile              (nginx container)
├── index.html              (enhanced with guestbook form)
├── style.css               (original styling)

📁 Guestbook additions:
├── docker-compose.yml      (multi-container orchestration)
├── Dockerfile.backend      (Node.js API container)
├── nginx.conf              (proxy configuration)
└── backend/
    ├── package.json        (Node.js dependencies)
    └── server.js           (API endpoints & database logic)
```

### Features Added

- **Interactive Guestbook**: Visitors can sign with name and message
- **Persistent Storage**: Messages stored in PostgreSQL database
- **Real-time Updates**: New entries appear immediately
- **REST API**: Backend provides `/api/guestbook` endpoints
- **Reverse Proxy**: Nginx forwards API calls to backend

## Quick Start

### Original Docker Setup
```bash
docker build -t hello-world .
docker run -p 80:80 hello-world
```

### New Multi-Container Setup
```bash
# Start all services
docker-compose up --build -d

# Wait for database initialization, then restart backend
sleep 15
docker-compose restart backend

# Open http://localhost
```

### Stop Services
```bash
docker-compose down
```

## Technical Details

### Container Communication
- nginx (port 80) → backend (port 3000) → postgres (port 5432)
- Services communicate via Docker network using service names
- Volume mounted for PostgreSQL data persistence

### Database Schema
```sql
CREATE TABLE guestbook (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
- `GET /api/guestbook` - Retrieve all entries
- `POST /api/guestbook` - Add new entry

## Learning Outcomes

This project demonstrates:
- ✅ Basic Docker containerization
- ✅ Multi-container applications with Docker Compose
- ✅ Container networking and service discovery
- ✅ Database integration and persistence
- ✅ Reverse proxy configuration
- ✅ Full-stack development (Frontend + Backend + Database)