# My First Docker Project 🐳

A simple containerized web application that demonstrates the basics of Docker by serving a static HTML website using nginx.

## What This Project Does

This project creates a "Hello, Docker World!" website that runs inside a Docker container. It showcases fundamental Docker concepts including:
- Creating a Dockerfile
- Building Docker images
- Running containers
- Port mapping
- Static file serving with nginx

## Project Structure

```
docker-hello-world/
├── Dockerfile          # Container configuration
├── index.html          # Main HTML page
├── style.css           # Styling for the website
└── README.md           # This file
```

## Steps I Took to Complete This Project

### 1. Created the Website Files
- **index.html**: Built a simple HTML page with information about Docker accomplishments
- **style.css**: Added modern styling with gradient background and card layout

### 2. Wrote the Dockerfile
- Used `nginx:alpine` as the base image for lightweight deployment
- Copied HTML and CSS files to nginx's default directory (`/usr/share/nginx/html/`)
- Exposed port 80 for web traffic
- Leveraged nginx's automatic startup (no custom CMD needed)

### 3. Key Docker Commands Used
```bash
# Build the Docker image
docker build -t my-first-docker-app .

# Run the container with port mapping
docker run -p 8080:80 my-first-docker-app
```

### 4. Version Control
- Initialized git repository
- Committed the project with message: "this is my intro to containers"

## What I Learned

 How to create a Dockerfile from scratch  
 Understanding base images and layers  
 Copying files into containers  
 Port mapping between host and container  
 Using nginx to serve static content  
 Docker build and run commands  
 Container lifecycle management  

## How to Run This Project

1. **Prerequisites**: Make sure Docker is installed on your system

2. **Clone/Download**: Get this project on your local machine

3. **Build the image**:
   ```bash
   docker build -t my-first-docker-app .
   ```

4. **Run the container**:
   ```bash
   docker run -p 8080:80 my-first-docker-app
   ```

5. **View the website**: Open your browser and go to `http://localhost:8080`

## Next Steps

This project laid the foundation for understanding Docker. Future improvements could include:
- Adding a backend API
- Using multi-stage builds
- Implementing Docker Compose for multi-container applications
- Adding environment variables
- Setting up automated builds

---

*This was my introduction to containerization technology - a stepping stone into the world of modern application deployment! 🚀*
