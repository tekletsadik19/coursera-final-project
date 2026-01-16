FROM python:3.11-slim

WORKDIR /app

# Copy application code
COPY . /app

# Install dependencies
RUN python -m pip install --upgrade pip && \
    pip install flake8 nose

# Expose port
EXPOSE 8080

# Run the application
CMD ["python", "-m", "http.server", "8080"]
