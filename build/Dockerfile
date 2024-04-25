FROM python:3.10-slim

# Allow statements and log messages to immediately appear in the Knative logs
ENV PYTHONUNBUFFERED True

# Set working directory
WORKDIR /app

# Copy all files from the app2 directory to the app directory in the container
COPY app/* /app/

# Install any necessary Python packages
RUN pip install -r requirements.txt

# Expose port 8080 on the container
EXPOSE 8080

# Command to run the application
# Assumes that your main.py uses port 8080 for ui.run (default)
CMD ["python", "app.py"]