# IMIC Robot — Pi Camera Stream

Stream snapshot JPEG từ camera Raspberry Pi, public hóa qua Cloudflare Tunnel (domain riêng) để nhúng vào dashboard.

## Cài đặt trên Pi mới (one-shot)

```bash
git clone https://github.com/DomainJin/imic-pi-camera.git
cd imic-pi-camera
chmod +x install.sh
./install.sh
```

Script sẽ tự động:

1. Cài `python3-picamera2`, `python3-flask`, `python3-opencv`, `cloudflared`
2. Đăng nhập Cloudflare (mở link, chọn domain của bạn trên Cloudflare)
3. Tạo tunnel, route DNS tới hostname bạn chọn (vd: `camera.domainjin.io.vn`)
4. Tạo và bật 2 service systemd: `cam_stream` (stream camera) và `cloudflared` (tunnel public)

Sau khi chạy xong, script sẽ in ra URL LAN và URL public.

## Yêu cầu trước khi cài

- Domain của bạn phải được quản lý qua Cloudflare DNS (nameserver trỏ về Cloudflare).
- Trên Cloudflare Dashboard, vào **Caching -> Cache Rules**, tạo rule bypass cache
  cho hostname camera (vd: `camera.domainjin.io.vn`), nếu không ảnh sẽ bị cache 4 giờ
  và không cập nhật.

## Cập nhật dashboard

Nếu hostname public mới khác với hostname cũ, cập nhật `SNAPSHOT_URL` trong
`dashboard/api/camera.js` (repo `IMIC-FINAL_PROJECT`) thành:

```
https://<hostname-moi>/snapshot.jpg
```

## Quản lý service

```bash
sudo systemctl status cam_stream
sudo systemctl status cloudflared
sudo systemctl restart cam_stream
sudo systemctl restart cloudflared
journalctl -u cam_stream -f
journalctl -u cloudflared -f
```
