from flask import Flask, Response, request
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


@app.route("/stream.mjpg", methods=["GET", "OPTIONS"])
def stream():
    if request.method == "OPTIONS":
        resp = app.make_default_options_response()
    else:
        resp = Response(gen_frames(), mimetype="multipart/x-mixed-replace; boundary=frame")

    resp.headers["Access-Control-Allow-Origin"] = "*"
    resp.headers["Access-Control-Allow-Headers"] = "ngrok-skip-browser-warning"
    resp.headers["Access-Control-Allow-Methods"] = "GET, OPTIONS"
    return resp


@app.route("/snapshot.jpg", methods=["GET", "OPTIONS"])
def snapshot():
    if request.method == "OPTIONS":
        resp = app.make_default_options_response()
    else:
        frame = picam2.capture_array()
        _, buf = cv2.imencode(".jpg", frame)
        resp = Response(buf.tobytes(), mimetype="image/jpeg")

    resp.headers["Access-Control-Allow-Origin"] = "*"
    resp.headers["Access-Control-Allow-Headers"] = "ngrok-skip-browser-warning"
    resp.headers["Access-Control-Allow-Methods"] = "GET, OPTIONS"
    return resp


@app.route("/")
def index():
    return '<img src="/stream.mjpg" style="width:100%">'


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
