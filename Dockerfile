# Use official Python runtime as base image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive \
    OPENCV_IO_ENABLE_OPENEXR=1 \
    PORT=5000 \
    MODE=both

# Install complete system dependencies (including OpenCV requirements)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    libglib2.0-0 \
    libgl1 \
    libgl1-mesa-glx \
    libopencv-dev \
    curl \
    wget \
    imagemagick \
    fonts-liberation \
    fonts-dejavu-core \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Fix ImageMagick policy for MoviePy
RUN if [ -f /etc/ImageMagick-6/policy.xml ]; then \
        sed -i 's/pixel cache limit="1GiB"/pixel cache limit="2GiB"/' /etc/ImageMagick-6/policy.xml; \
        sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml; \
    elif [ -f /etc/ImageMagick-7/policy.xml ]; then \
        sed -i 's/pixel cache limit="1GiB"/pixel cache limit="2GiB"/' /etc/ImageMagick-7/policy.xml; \
        sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-7/policy.xml; \
    elif [ -f /etc/ImageMagick/policy.xml ]; then \
        sed -i 's/pixel cache limit="1GiB"/pixel cache limit="2GiB"/' /etc/ImageMagick/policy.xml; \
        sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick/policy.xml; \
    fi

# Copy requirements
COPY requirements.txt .

# Install ALL Python dependencies (including OpenCV to fix cv2 error)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    numpy==1.24.3 \
    pillow==10.1.0 \
    python-telegram-bot==20.7 \
    Flask==3.0.0 \
    Flask-SocketIO==5.3.4 \
    Flask-CORS==4.0.0 \
    gunicorn==21.2.0 \
    pymongo==4.6.0 \
    redis==5.0.1 \
    python-dotenv==1.0.0 \
    requests==2.31.0 \
    moviepy==1.0.3 \
    imageio==2.31.1 \
    imageio-ffmpeg==0.4.8 \
    pandas==2.0.3 \
    openpyxl==3.1.2 \
    opencv-python==4.8.1.78 \
    opencv-contrib-python==4.8.1.78 \
    psutil==5.9.5

# Verify OpenCV installation
RUN python -c "import cv2; print('✅ OpenCV version:', cv2.__version__)" && \
    python -c "import pandas; print('✅ pandas version:', pandas.__version__)" && \
    python -c "from moviepy.editor import VideoFileClip; print('✅ moviepy loaded')"

# Create directories
RUN mkdir -p temp uploads outputs logs static/css static/js templates fonts downloads

# Copy application
COPY . .

# Run auto_fix_all.py to fix all code issues
RUN if [ -f auto_fix_all.py ]; then \
        python auto_fix_all.py; \
    else \
        echo "auto_fix_all.py not found, skipping"; \
    fi

# Create user
RUN useradd -m -u 1000 -s /bin/bash kinva && \
    chown -R kinva:kinva /app

USER kinva

EXPOSE 5000

CMD ["gunicorn", "run:app", "--bind", "0.0.0.0:5000", "--timeout", "120", "--workers", "2", "--log-level", "info"]
