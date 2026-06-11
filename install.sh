#!/bin/bash
set -e

WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_USER="$(whoami)"

echo "=== 1/4: Cài dependency hệ thống ==="
sudo apt update
sudo apt install -y python3-picamera2 python3-flask python3-opencv curl

echo "=== 2/4: Cài ngrok (nếu chưa có) ==="
if ! command -v ngrok >/dev/null 2>&1; then
    case "$(uname -m)" in
        armv6l|armv7l) NGROK_ARCH="arm" ;;
        aarch64)       NGROK_ARCH="arm64" ;;
        x86_64)        NGROK_ARCH="amd64" ;;
        *) echo "Kiến trúc $(uname -m) chưa hỗ trợ tự động, cài ngrok thủ công."; exit 1 ;;
    esac

    curl -sSL "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-${NGROK_ARCH}.tgz" -o /tmp/ngrok.tgz
    sudo tar -xzf /tmp/ngrok.tgz -C /usr/local/bin
    rm -f /tmp/ngrok.tgz
else
    echo "ngrok đã có sẵn, bỏ qua."
fi

echo "=== 3/4: Cấu hình ngrok ==="
read -rp "Nhập ngrok authtoken (Dashboard -> Your Authtoken): " NGROK_TOKEN
ngrok config add-authtoken "$NGROK_TOKEN"

read -rp "Nhập ngrok static domain (vd: xxxx.ngrok-free.dev, tạo ở Dashboard -> Domains): " NGROK_DOMAIN

echo "=== 4/4: Cài đặt service tự khởi động ==="
sed -e "s|__USER__|$RUN_USER|g" -e "s|__WORKDIR__|$WORKDIR|g" \
    "$WORKDIR/cam_stream.service.template" | sudo tee /etc/systemd/system/cam_stream.service >/dev/null

sed -e "s|__USER__|$RUN_USER|g" -e "s|__DOMAIN__|$NGROK_DOMAIN|g" \
    "$WORKDIR/ngrok.service.template" | sudo tee /etc/systemd/system/ngrok.service >/dev/null

sudo systemctl daemon-reload
sudo systemctl enable --now cam_stream.service
sudo systemctl enable --now ngrok.service

echo
echo "=== Hoàn tất ==="
echo "Stream LAN:    http://$(hostname -I | awk '{print $1}'):8080/stream.mjpg"
echo "Stream public: https://${NGROK_DOMAIN}/stream.mjpg"
echo
echo "Nếu domain public khác với domain hiện tại trong dashboard,"
echo "cần cập nhật CAMERA_STREAM_URL trong dashboard/index.html."
echo
echo "Xem log:"
echo "  journalctl -u cam_stream -f"
echo "  journalctl -u ngrok -f"
