from flask import Flask, Response
from flask_cors import CORS
import cv2

app = Flask(__name__)
CORS(app)


camera = cv2.VideoCapture(0)


zoom_level = 1.0 
pan = 0
tilt = 0

if not camera.isOpened():
    print("Error: Could not open camera")
else:
    print(f"Camera opened successfully. Initial zoom level: {zoom_level}")

def generate_frames():
    global camera, zoom_level
    while True:
        success, frame = camera.read()
        if not success:
            print("Failed to read frame from camera")
            break

        height, width = frame.shape[:2]
        
        if zoom_level != 1.0:
            print(f"Applying zoom: {zoom_level:.1f}x")

        if zoom_level > 1.01: 
            center_x, center_y = width // 2, height // 2
            new_w, new_h = int(width / zoom_level), int(height / zoom_level)
            x1 = max(center_x - new_w // 2, 0)
            y1 = max(center_y - new_h // 2, 0)
            x2 = min(center_x + new_w // 2, width)
            y2 = min(center_y + new_h // 2, height)

            frame = frame[y1:y2, x1:x2]
            frame = cv2.resize(frame, (width, height))  

        ret, buffer = cv2.imencode('.jpg', frame)
        if not ret:
            print("Failed to encode frame")
            continue

        frame_bytes = buffer.tobytes()
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')

@app.route('/video_feed')
def video_feed():
    """Video streaming route."""
    print(f"Serving video feed with zoom level: {zoom_level}")
    return Response(generate_frames(),
                    mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/reset_zoom')
def reset_zoom():
    global zoom_level
    zoom_level = 1.0
    print(f"Zoom reset to: {zoom_level}")
    return "OK"

@app.route('/control/<action>')
def control(action):
    global zoom_level, pan, tilt

    if action == "up":
        tilt += 10
        print("Move up (prototype)")
    elif action == "down":
        tilt -= 10
        print("Move down (prototype)")
    elif action == "left":
        pan -= 10
        print("Move left (prototype)")
    elif action == "right":
        pan += 10
        print("Move right (prototype)")
    elif action == "zoom_in":
        zoom_level = min(zoom_level + 0.2, 3.0)
        print(f"Zoom in: {zoom_level:.1f}x")
    elif action == "zoom_out":
        zoom_level = max(zoom_level - 0.2, 1.0)
        print(f"Zoom out: {zoom_level:.1f}x")
    else:
        print("Unknown action:", action)

    return "OK"

if __name__ == "__main__":
    print("Starting server with default zoom level: 1.0 (no zoom)")
    app.run(host="0.0.0.0", port=5001, debug=True)