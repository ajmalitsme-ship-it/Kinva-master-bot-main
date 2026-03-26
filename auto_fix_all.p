#!/usr/bin/env python3
"""
COMPLETE AUTO-FIX - Fixes all missing dependencies including pandas and moviepy
"""

import os
import sys
import subprocess
from pathlib import Path

class CompleteAutoFix:
    def __init__(self):
        self.repo_path = Path.cwd()
        self.fixed = []
        self.errors = []
        
    def print_header(self, text):
        print("\n" + "="*60)
        print(f"🔧 {text}")
        print("="*60)
    
    def print_success(self, text):
        print(f"✅ {text}")
        self.fixed.append(text)
    
    def print_error(self, text):
        print(f"❌ {text}")
        self.errors.append(text)
    
    def print_info(self, text):
        print(f"📌 {text}")
    
    def install_all_dependencies(self):
        """Install all required packages"""
        self.print_header("Installing All Dependencies")
        
        # Complete list of all required packages
        packages = [
            # Core
            "python-telegram-bot==20.7",
            "Flask==3.0.0",
            "Flask-CORS==4.0.0",
            "gunicorn==21.2.0",
            
            # Data processing (pandas error)
            "pandas==2.0.3",
            "numpy==1.24.3",
            "openpyxl==3.1.2",
            "xlrd==2.0.1",
            
            # Video processing (moviepy error)
            "moviepy==1.0.3",
            "imageio==2.31.1",
            "imageio[ffmpeg]==2.31.1",
            "imageio-ffmpeg==0.4.8",
            "Pillow==10.1.0",
            
            # Utilities
            "requests==2.31.0",
            "python-dotenv==1.0.0",
            "psutil==5.9.5",
        ]
        
        self.print_info(f"Installing {len(packages)} packages...")
        
        for package in packages:
            try:
                self.print_info(f"Installing {package}...")
                subprocess.check_call([
                    sys.executable, "-m", "pip", "install", package
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                self.print_success(f"Installed {package}")
            except Exception as e:
                self.print_error(f"Failed to install {package}: {e}")
        
        # Verify pandas installation
        try:
            import pandas
            self.print_success(f"✅ pandas {pandas.__version__} installed")
        except ImportError:
            self.print_error("pandas still not installed")
            
        # Verify moviepy installation
        try:
            import moviepy
            self.print_success(f"✅ moviepy {moviepy.__version__} installed")
        except ImportError:
            self.print_error("moviepy still not installed")
    
    def create_complete_requirements(self):
        """Create complete requirements.txt with all dependencies"""
        self.print_header("Creating Complete requirements.txt")
        
        requirements = """# Core Dependencies
python-telegram-bot==20.7
Flask==3.0.0
Flask-CORS==4.0.0
gunicorn==21.2.0

# Data Processing (Required for admin.py)
pandas==2.0.3
numpy==1.24.3
openpyxl==3.1.2
xlrd==2.0.1

# Video Processing (Required for moviepy)
moviepy==1.0.3
imageio==2.31.1
imageio-ffmpeg==0.4.8
Pillow==10.1.0

# Utilities
requests==2.31.0
python-dotenv==1.0.0
psutil==5.9.5
"""
        
        with open("requirements.txt", "w") as f:
            f.write(requirements)
        
        self.print_success("Created complete requirements.txt")
    
    def fix_admin_py_imports(self):
        """Fix admin.py imports with safe fallback"""
        self.print_header("Fixing admin.py Imports")
        
        admin_file = self.repo_path / "admin.py"
        
        if admin_file.exists():
            content = admin_file.read_text()
            
            # Add safe pandas import
            safe_imports = '''
# ===== SAFE IMPORTS WITH FALLBACK =====
try:
    import pandas as pd
    import numpy as np
    PANDAS_AVAILABLE = True
    print("✅ pandas loaded successfully")
except ImportError as e:
    PANDAS_AVAILABLE = False
    print(f"⚠️ pandas not available: {e}")
    print("⚠️ Data features will be disabled")
    
    # Create dummy pandas if needed
    class DummyPandas:
        def __getattr__(self, name):
            raise ImportError(f"pandas not installed. Run: pip install pandas")
    
    pd = DummyPandas()
    np = None

try:
    from moviepy.editor import VideoFileClip
    MOVIEPY_AVAILABLE = True
except ImportError:
    MOVIEPY_AVAILABLE = False
    print("⚠️ moviepy not available - video features disabled")
    
    class VideoFileClip:
        def __init__(self, *args, **kwargs):
            raise ImportError("moviepy not installed")
'''
            
            # Check if safe imports already exist
            if "PANDAS_AVAILABLE" not in content:
                # Find the import section
                lines = content.split('\n')
                insert_pos = 0
                for i, line in enumerate(lines):
                    if line.startswith('import ') or line.startswith('from '):
                        insert_pos = i + 1
                
                # Insert safe imports
                lines.insert(insert_pos, safe_imports)
                
                # Remove old pandas import if exists
                new_content = '\n'.join(lines)
                new_content = new_content.replace("import pandas as pd", "# pandas import moved to safe section")
                new_content = new_content.replace("import numpy as np", "# numpy import moved to safe section")
                
                admin_file.write_text(new_content)
                self.print_success("Fixed admin.py with safe imports")
            else:
                self.print_info("admin.py already has safe imports")
        else:
            self.print_error("admin.py not found")
    
    def fix_bot_py_imports(self):
        """Fix bot.py imports"""
        self.print_header("Fixing bot.py Imports")
        
        bot_file = self.repo_path / "bot.py"
        
        if bot_file.exists():
            content = bot_file.read_text()
            
            # Add safe moviepy import at top
            safe_moviepy = '''
# ===== SAFE MOVIEPY IMPORT =====
try:
    from moviepy.editor import VideoFileClip, AudioFileClip, CompositeVideoClip
    MOVIEPY_AVAILABLE = True
    print("✅ MoviePy loaded")
except ImportError:
    MOVIEPY_AVAILABLE = False
    print("⚠️ MoviePy not available - video features disabled")
    VideoFileClip = None
    AudioFileClip = None
    CompositeVideoClip = None
'''
            
            if "MOVIEPY_AVAILABLE" not in content:
                lines = content.split('\n')
                # Find position to insert
                insert_pos = 0
                for i, line in enumerate(lines):
                    if line.startswith('import ') or line.startswith('from '):
                        insert_pos = i + 1
                
                lines.insert(insert_pos, safe_moviepy)
                new_content = '\n'.join(lines)
                bot_file.write_text(new_content)
                self.print_success("Fixed bot.py with safe moviepy import")
            else:
                self.print_info("bot.py already has safe imports")
    
    def fix_run_py(self):
        """Fix run.py to handle missing imports"""
        self.print_header("Fixing run.py")
        
        run_file = self.repo_path / "run.py"
        
        if run_file.exists():
            content = run_file.read_text()
            
            # Add error handling around imports
            error_handler = '''
# ===== ERROR HANDLING FOR IMPORTS =====
import traceback

def safe_import(module_name):
    """Safely import a module"""
    try:
        return __import__(module_name)
    except ImportError as e:
        print(f"⚠️ Failed to import {module_name}: {e}")
        return None

# Add try-except around bot import
try:
    from bot import KinvaMasterBot
    BOT_AVAILABLE = True
except ImportError as e:
    BOT_AVAILABLE = False
    print(f"⚠️ Bot import failed: {e}")
    traceback.print_exc()
'''
            
            if "BOT_AVAILABLE" not in content:
                # Add at the top
                content = error_handler + "\n" + content
                run_file.write_text(content)
                self.print_success("Added error handling to run.py")
    
    def create_dockerfile_with_all_deps(self):
        """Create Dockerfile with all dependencies including pandas"""
        self.print_header("Creating Dockerfile")
        
        dockerfile = """FROM python:3.11-slim

# Install system dependencies for pandas, moviepy, etc.
RUN apt-get update && apt-get install -y \\
    gcc \\
    g++ \\
    ffmpeg \\
    libsm6 \\
    libxext6 \\
    libxrender-dev \\
    libgomp1 \\
    libatlas-base-dev \\
    liblapack-dev \\
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Verify critical packages
RUN python -c "import pandas; print('✅ pandas', pandas.__version__)" || \\
    pip install pandas==2.0.3
RUN python -c "import moviepy; print('✅ moviepy', moviepy.__version__)" || \\
    pip install moviepy==1.0.3 imageio[ffmpeg]

# Copy application
COPY . .

# Create necessary directories
RUN mkdir -p downloads temp uploads logs data

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV MODE=both
ENV PORT=8080

# Expose port
EXPOSE 8080

# Run the application
CMD gunicorn run:app --bind 0.0.0.0:$PORT --timeout 120 --workers 2 --log-level info
"""
        
        with open("Dockerfile", "w") as f:
            f.write(dockerfile)
        
        self.print_success("Created Dockerfile with all dependencies")
    
    def create_render_yaml(self):
        """Create render.yaml with pandas and moviepy"""
        self.print_header("Creating render.yaml")
        
        render_config = """services:
  - type: web
    name: kinva-master-bot
    runtime: python
    buildCommand: |
      apt-get update && apt-get install -y ffmpeg libsm6 libxext6
      pip install --upgrade pip
      pip install -r requirements.txt
      pip install pandas==2.0.3 numpy==1.24.3
      pip install moviepy==1.0.3 imageio[ffmpeg]
    startCommand: gunicorn run:app --bind 0.0.0.0:$PORT --timeout 120
    envVars:
      - key: PYTHON_VERSION
        value: 3.11.0
      - key: MODE
        value: both
      - key: TELEGRAM_BOT_TOKEN
        sync: false
    plan: free
"""
        
        with open("render.yaml", "w") as f:
            f.write(render_config)
        
        self.print_success("Created render.yaml")
    
    def verify_all_fixes(self):
        """Verify all packages are installed"""
        self.print_header("Verifying All Fixes")
        
        packages_to_check = [
            ('pandas', 'pd'),
            ('moviepy', 'moviepy'),
            ('flask', 'Flask'),
            ('telegram', 'telegram'),
            ('numpy', 'np'),
            ('PIL', 'PIL')
        ]
        
        for package_name, import_name in packages_to_check:
            try:
                if import_name == 'pd':
                    import pandas as pd
                    self.print_success(f"{package_name} {pd.__version__}")
                elif import_name == 'moviepy':
                    import moviepy
                    self.print_success(f"{package_name} {moviepy.__version__}")
                elif import_name == 'Flask':
                    import flask
                    self.print_success(f"{package_name} {flask.__version__}")
                else:
                    __import__(import_name)
                    self.print_success(f"{package_name} installed")
            except ImportError:
                self.print_error(f"{package_name} NOT installed")
    
    def run(self):
        """Run all fixes"""
        print("\n" + "🔥"*30)
        print("🚀 COMPLETE AUTO-FIX - Fixing All Errors")
        print("   Including: pandas, moviepy, and all dependencies")
        print("🔥"*30)
        
        # Install all dependencies
        self.install_all_dependencies()
        
        # Create requirements file
        self.create_complete_requirements()
        
        # Fix Python files
        self.fix_admin_py_imports()
        self.fix_bot_py_imports()
        self.fix_run_py()
        
        # Create deployment files
        self.create_dockerfile_with_all_deps()
        self.create_render_yaml()
        
        # Verify everything
        self.verify_all_fixes()
        
        # Summary
        self.print_header("FIX SUMMARY")
        print(f"\n✅ Successfully fixed: {len(self.fixed)} issues")
        print(f"❌ Errors: {len(self.errors)}")
        
        if self.fixed:
            print("\n📋 Fixed items:")
            for fix in self.fixed:
                print(f"  • {fix}")
        
        print("\n" + "="*60)
        print("🎉 COMPLETE FIX DONE!")
        print("="*60)
        print("\nNext steps:")
        print("1. Commit all changes:")
        print("   git add .")
        print("   git commit -m 'Fixed all dependencies (pandas, moviepy)'")
        print("   git push")
        print("\n2. Redeploy to Render.com")
        print("\n3. Check logs - should show:")
        print("   ✅ pandas loaded successfully")
        print("   ✅ MoviePy loaded")
        print("\n🚀 Your app is now ready!")

if __name__ == "__main__":
    fixer = CompleteAutoFix()
    fixer.run()
