# My First Docker Project

A simple containerized web application that demonstrates the basics of Docker by serving a static HTML website using nginx. I used Claude to create a simple backend webserver and HTML/CSS for the front end for me to test my docker file. I did the rest myself.

# What I learned/take aways
This was my first time working with Nginx and I can see how it can be used to build very simple websites. Interesting point I ran into, I changed the Expose to port 90 to see what happened and it created a page where the text was still correct but the format is way off/deleted. What this taught me was that the Docker image is basically just documentation/instructions and doesnt change the default port to 90. It will always be 80 unless I decide to create a file with the explicit purpose of changing the port. Also, when testing to try to change the port for NGinx I found that I had to delete the entire container and start a new one with the new port to test even if I saved the file while the container was running. 

To make adjustments to the code in the container, the current container must be stopped and and new one created with the changes. This is what immutable means


Used:

FROM: nginx:alpine is the official image for Nginx. This is what allowed me to use HTTP and build a frontend to show that I successfully created a docker file

COPY: Brings in the CSS and HTTPS.

EXPOSE is where it listed the port I connect to (80)

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
- **index.html**: Built a simple HTML page with information about Docker accomplishments using Claude
- **style.css**: Added modern styling with gradient background and card layout using Claude

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
- Initialized git repository and used Github for changes through out building the project

## What I Learned

 -How to create a Dockerfile from scratch  
 -Understanding base images and layers  
 -Copying files into containers  
 -Port mapping between host and container  
 -Using nginx to serve static content  
 -Docker build and run commands  
 -Container lifecycle management  

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
