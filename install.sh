#!/bin/bash
set -e

# Cài dependency
sudo apt update
sudo apt install -y python3-picamera2 python3-flask python3-opencv

# Đăng ký service tự khởi động
sudo cp cam_stream.service /etc/systemd/system/cam_stream.service
sudo systemctl daemon-reload
sudo systemctl enable --now cam_stream.service

echo "Stream chạy tại: http://$(hostname -I | awk '{print $1}'):8080/stream.mjpg"
echo "Xem log: journalctl -u cam_stream -f"
