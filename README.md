# IMIC Robot — Pi Camera Stream

Stream MJPEG từ camera Raspberry Pi, public hóa qua Cloudflare Tunnel để nhúng vào dashboard.

## Cài đặt trên Pi

```bash
git clone <repo-url> imic-pi-camera
cd imic-pi-camera
chmod +x install.sh
./install.sh
```

Sau khi chạy, stream có tại `http://<pi-ip>:8080/stream.mjpg` (LAN).

## Public hóa bằng Cloudflare Tunnel

```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm -o cloudflared
chmod +x cloudflared && sudo mv cloudflared /usr/local/bin/
cloudflared tunnel --url http://localhost:8080
```

Copy URL `https://xxxx-xxxx.trycloudflare.com` được in ra, dùng URL này (`+ /stream.mjpg`) trong dashboard.

### Chạy tunnel nền vĩnh viễn (tuỳ chọn)
Để URL không đổi mỗi lần restart, đăng nhập Cloudflare account và tạo named tunnel:

```bash
cloudflared tunnel login
cloudflared tunnel create imic-pi-camera
cloudflared tunnel route dns imic-pi-camera camera.yourdomain.com
cloudflared tunnel run imic-pi-camera
```

## Quản lý service

```bash
sudo systemctl status cam_stream
sudo systemctl restart cam_stream
journalctl -u cam_stream -f
```
