from flask import Flask, Response
from picamera2 import Picamera2
import cv2

app = Flask(__name__)

picam2 = Picamera2()
picam2.configure(picam2.create_video_configuration(main={"size": (640, 480)}))
picam2.start()


def gen_frames():
    while True:
        frame = picam2.capture_array()
        _, buf = cv2.imencode(".jpg", frame)
        yield (
            b"--frame\r\n"
            b"Content-Type: image/jpeg\r\n\r\n" + buf.tobytes() + b"\r\n"
        )


@app.route("/stream.mjpg")
def stream():
    return Response(gen_frames(), mimetype="multipart/x-mixed-replace; boundary=frame")


@app.route("/")
def index():
    return '<img src="/stream.mjpg" style="width:100%">'


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
