#!/bin/bash
set -e

WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_USER="$(whoami)"

echo "=== 1/5: Cài dependency hệ thống ==="
sudo apt update
sudo apt install -y python3-picamera2 python3-flask python3-opencv curl

echo "=== 2/5: Cài cloudflared (nếu chưa có) ==="
if ! command -v cloudflared >/dev/null 2>&1; then
    case "$(uname -m)" in
        armv6l|armv7l) CF_ARCH="armhf" ;;
        aarch64)       CF_ARCH="arm64" ;;
        x86_64)        CF_ARCH="amd64" ;;
        *) echo "Kiến trúc $(uname -m) chưa hỗ trợ tự động, cài cloudflared thủ công."; exit 1 ;;
    esac

    curl -L "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}.deb" -o /tmp/cloudflared.deb
    sudo dpkg -i /tmp/cloudflared.deb
    rm -f /tmp/cloudflared.deb
else
    echo "cloudflared đã có sẵn, bỏ qua."
fi

echo "=== 3/5: Đăng nhập Cloudflare ==="
echo "Một đường link sẽ hiện ra, mở bằng browser và chọn domain của bạn để cấp quyền."
cloudflared tunnel login

echo "=== 4/5: Tạo tunnel ==="
read -rp "Đặt tên cho tunnel (vd: imic-pi-camera): " TUNNEL_NAME
cloudflared tunnel create "$TUNNEL_NAME"

TUNNEL_ID=$(cloudflared tunnel list -o json | python3 -c "import json,sys; data=json.load(sys.stdin); print([t['id'] for t in data if t['name']=='$TUNNEL_NAME'][0])")
CRED_FILE="/home/$RUN_USER/.cloudflared/${TUNNEL_ID}.json"

read -rp "Nhập hostname public cho camera (vd: camera.domainjin.io.vn): " CF_HOSTNAME
cloudflared tunnel route dns "$TUNNEL_NAME" "$CF_HOSTNAME"

cat > "/home/$RUN_USER/.cloudflared/config.yml" << EOF
tunnel: $TUNNEL_ID
credentials-file: $CRED_FILE

ingress:
  - hostname: $CF_HOSTNAME
    service: http://localhost:8080
  - service: http_status:404
EOF

sudo mkdir -p /etc/cloudflared
sudo cp "/home/$RUN_USER/.cloudflared/config.yml" /etc/cloudflared/config.yml
sudo cp "$CRED_FILE" /etc/cloudflared/
sudo cp "/home/$RUN_USER/.cloudflared/cert.pem" /etc/cloudflared/
sudo sed -i "s|$CRED_FILE|/etc/cloudflared/${TUNNEL_ID}.json|" /etc/cloudflared/config.yml

echo "=== 5/5: Cài đặt service tự khởi động ==="
sed -e "s|__USER__|$RUN_USER|g" -e "s|__WORKDIR__|$WORKDIR|g" \
    "$WORKDIR/cam_stream.service.template" | sudo tee /etc/systemd/system/cam_stream.service >/dev/null

sudo systemctl daemon-reload
sudo systemctl enable --now cam_stream.service

sudo cloudflared service install
sudo systemctl enable --now cloudflared

echo
echo "=== Hoàn tất ==="
echo "Stream LAN:    http://$(hostname -I | awk '{print $1}'):8080/snapshot.jpg"
echo "Stream public: https://${CF_HOSTNAME}/snapshot.jpg"
echo
echo "Nếu hostname public khác với hostname hiện tại trong dashboard,"
echo "cần cập nhật SNAPSHOT_URL trong dashboard/api/camera.js."
echo
echo "Lưu ý: tạo Cache Rule trên Cloudflare (Caching -> Cache Rules) để"
echo "bypass cache cho ${CF_HOSTNAME}, nếu không ảnh sẽ bị cache 4 giờ."
echo
echo "Xem log:"
echo "  journalctl -u cam_stream -f"
echo "  journalctl -u cloudflared -f"
