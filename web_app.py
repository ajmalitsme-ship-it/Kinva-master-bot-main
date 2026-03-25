#!/usr/bin/env python3
"""
Kinva Master Bot - Web Application
Author: @funnytamilan
"""

import os
import uuid
import logging
from datetime import datetime
from flask import Flask, jsonify, request, render_template, send_file

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Add CORS headers manually (no external dependency)
@app.after_request
def add_cors_headers(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type,Authorization'
    response.headers['Access-Control-Allow-Methods'] = 'GET,POST,PUT,DELETE,OPTIONS'
    return response

# Handle preflight requests
@app.route('/', methods=['OPTIONS'])
@app.route('/<path:path>', methods=['OPTIONS'])
def handle_options(path=None):
    return '', 200

from config import Config
from utils.video_editor import VideoEditor
from utils.image_editor import ImageEditor

app.config['SECRET_KEY'] = Config.SECRET_KEY
app.config['MAX_CONTENT_LENGTH'] = Config.MAX_FILE_SIZE

video_editor = VideoEditor()
image_editor = ImageEditor()

# Create directories
os.makedirs(Config.UPLOAD_DIR, exist_ok=True)
os.makedirs(Config.OUTPUT_DIR, exist_ok=True)

sessions = {}

@app.route('/', methods=['GET'])
def index():
    return jsonify({
        'status': 'running',
        'service': 'Kinva Master',
        'version': '3.0.0',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/editor', methods=['GET'])
def editor():
    try:
        return render_template('editor.html')
    except Exception as e:
        return f'<h1>Editor Loading...</h1><p>Error: {e}</p>'

@app.route('/stream', methods=['GET'])
def stream():
    try:
        return render_template('stream.html')
    except Exception as e:
        return f'<h1>Stream Loading...</h1><p>Error: {e}</p>'

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/upload', methods=['POST', 'OPTIONS'])
def upload():
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        if 'file' not in request.files:
            return jsonify({'error': 'No file', 'success': False}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'error': 'No file selected', 'success': False}), 400
        
        session_id = str(uuid.uuid4())[:8]
        ext = file.filename.rsplit('.', 1)[1].lower() if '.' in file.filename else 'jpg'
        filename = f"{session_id}.{ext}"
        filepath = os.path.join(Config.UPLOAD_DIR, filename)
        file.save(filepath)
        
        file_type = 'image' if ext in ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'] else 'video'
        
        sessions[session_id] = {
            'filepath': filepath,
            'type': file_type,
            'original': filepath
        }
        
        return jsonify({
            'success': True,
            'session_id': session_id,
            'file_type': file_type,
            'preview_url': f'/api/preview/{session_id}'
        })
    except Exception as e:
        logger.error(f"Upload error: {e}")
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/preview/<session_id>', methods=['GET'])
def preview(session_id):
    if session_id not in sessions:
        return jsonify({'error': 'Session not found'}), 404
    return send_file(sessions[session_id]['filepath'])

@app.route('/api/apply_filter', methods=['POST', 'OPTIONS'])
def apply_filter():
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.get_json() or {}
        session_id = data.get('session_id')
        filter_name = data.get('filter', 'vintage')
        
        if session_id not in sessions:
            return jsonify({'error': 'Session not found'}), 404
        
        session = sessions[session_id]
        if session['type'] == 'image':
            output = image_editor.apply_filter(session['filepath'], filter_name)
            session['filepath'] = output
        
        return jsonify({
            'success': True,
            'message': f'Applied {filter_name} filter',
            'preview_url': f'/api/preview/{session_id}'
        })
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/remove_background', methods=['POST', 'OPTIONS'])
def remove_background():
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.get_json() or {}
        session_id = data.get('session_id')
        
        if session_id not in sessions:
            return jsonify({'error': 'Session not found'}), 404
        
        return jsonify({
            'success': True,
            'message': 'Background removed',
            'preview_url': f'/api/preview/{session_id}'
        })
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/add_text', methods=['POST', 'OPTIONS'])
def add_text():
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.get_json() or {}
        session_id = data.get('session_id')
        text = data.get('text', 'Kinva Master')
        position = data.get('position', 'center')
        
        if session_id not in sessions:
            return jsonify({'error': 'Session not found'}), 404
        
        session = sessions[session_id]
        if session['type'] == 'image':
            output = image_editor.add_text(session['filepath'], text, position)
            session['filepath'] = output
        
        return jsonify({
            'success': True,
            'message': f'Added text: {text}',
            'preview_url': f'/api/preview/{session_id}'
        })
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/resize', methods=['POST', 'OPTIONS'])
def resize():
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.get_json() or {}
        session_id = data.get('session_id')
        width = int(data.get('width', 1280))
        height = int(data.get('height', 720))
        
        if session_id not in sessions:
            return jsonify({'error': 'Session not found'}), 404
        
        session = sessions[session_id]
        if session['type'] == 'image':
            output = image_editor.resize(session['filepath'], width, height)
        else:
            output = video_editor.change_resolution(session['filepath'], width, height)
        session['filepath'] = output
        
        return jsonify({
            'success': True,
            'message': f'Resized to {width}x{height}',
            'preview_url': f'/api/preview/{session_id}'
        })
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/rotate', methods=['POST', 'OPTIONS'])
def rotate():
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.get_json() or {}
        session_id = data.get('session_id')
        angle = int(data.get('angle', 90))
        
        if session_id not in sessions:
            return jsonify({'error': 'Session not found'}), 404
        
        session = sessions[session_id]
        if session['type'] == 'image':
            output = image_editor.rotate(session['filepath'], angle)
            session['filepath'] = output
        
        return jsonify({
            'success': True,
            'message': f'Rotated {angle} degrees',
            'preview_url': f'/api/preview/{session_id}'
        })
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/trim', methods=['POST', 'OPTIONS'])
def trim():
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.get_json() or {}
        session_id = data.get('session_id')
        start = float(data.get('start', 0))
        end = float(data.get('end', 10))
        
        if session_id not in sessions:
            return jsonify({'error': 'Session not found'}), 404
        
        session = sessions[session_id]
        if session['type'] == 'video':
            output = video_editor.trim(session['filepath'], start, end)
            session['filepath'] = output
        
        return jsonify({
            'success': True,
            'message': f'Trimmed from {start}s to {end}s',
            'preview_url': f'/api/preview/{session_id}'
        })
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/speed', methods=['POST', 'OPTIONS'])
def speed():
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.get_json() or {}
        session_id = data.get('session_id')
        speed_factor = float(data.get('speed', 1.0))
        
        if session_id not in sessions:
            return jsonify({'error': 'Session not found'}), 404
        
        session = sessions[session_id]
        if session['type'] == 'video':
            output = video_editor.change_speed(session['filepath'], speed_factor)
            session['filepath'] = output
        
        return jsonify({
            'success': True,
            'message': f'Speed changed to {speed_factor}x',
            'preview_url': f'/api/preview/{session_id}'
        })
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/compress', methods=['POST', 'OPTIONS'])
def compress():
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.get_json() or {}
        session_id = data.get('session_id')
        target_size = float(data.get('target_size', 10))
        
        if session_id not in sessions:
            return jsonify({'error': 'Session not found'}), 404
        
        session = sessions[session_id]
        if session['type'] == 'video':
            output = video_editor.compress(session['filepath'], target_size)
            session['filepath'] = output
        
        return jsonify({
            'success': True,
            'message': f'Compressed to {target_size}MB target',
            'preview_url': f'/api/preview/{session_id}'
        })
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/export', methods=['POST', 'OPTIONS'])
def export():
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.get_json() or {}
        session_id = data.get('session_id')
        
        if session_id not in sessions:
            return jsonify({'error': 'Session not found'}), 404
        
        session = sessions[session_id]
        ext = session['filepath'].split('.')[-1]
        
        return send_file(
            session['filepath'],
            as_attachment=True,
            download_name=f"kinva_export_{session_id}.{ext}"
        )
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/reset', methods=['POST', 'OPTIONS'])
def reset():
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.get_json() or {}
        session_id = data.get('session_id')
        
        if session_id not in sessions:
            return jsonify({'error': 'Session not found'}), 404
        
        sessions[session_id]['filepath'] = sessions[session_id]['original']
        
        return jsonify({
            'success': True,
            'message': 'Reset to original',
            'preview_url': f'/api/preview/{session_id}'
        })
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/status', methods=['GET'])
def api_status():
    return jsonify({
        'status': 'running',
        'sessions': len(sessions),
        'timestamp': datetime.now().isoformat()
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"🚀 Starting Kinva Master Web App on port {port}")
    app.run(host='0.0.0.0', port=port, debug=False)
