# IMIC Robot — Pi Camera Stream

Stream MJPEG từ camera Raspberry Pi, public hóa qua ngrok (static domain) để nhúng vào dashboard.

## Cài đặt trên Pi mới (one-shot)

```bash
git clone https://github.com/DomainJin/imic-pi-camera.git
cd imic-pi-camera
chmod +x install.sh
./install.sh
```

Script sẽ tự động:

1. Cài `python3-picamera2`, `python3-flask`, `python3-opencv`, `ngrok`
2. Hỏi **ngrok authtoken** và **static domain** (xem bên dưới cách lấy)
3. Tạo và bật 2 service systemd: `cam_stream` (stream camera) và `ngrok` (tunnel public)

Sau khi chạy xong, script sẽ in ra URL LAN và URL public.

## Lấy ngrok authtoken & static domain

1. Tạo tài khoản tại https://ngrok.com (có thể đăng nhập bằng Google)
2. Vào **Dashboard -> Your Authtoken**, copy token
3. Vào **Dashboard -> Domains -> + Create Domain**, tạo 1 static domain miễn phí (vd: `xxxx.ngrok-free.dev`)

## Cập nhật dashboard

Nếu domain public mới khác với domain cũ, cập nhật `CAMERA_STREAM_URL` trong
`dashboard/index.html` (repo `IMIC-FINAL_PROJECT`) thành:

```
https://<domain-moi>/stream.mjpg
```

## Quản lý service

```bash
sudo systemctl status cam_stream
sudo systemctl status ngrok
sudo systemctl restart cam_stream
sudo systemctl restart ngrok
journalctl -u cam_stream -f
journalctl -u ngrok -f
```

3Ezso4K7KMmzZqFIwk0JMYtUWfz_6xxPDU5gd4gcFBrj5S6Wk
http --url=swimmable-abstract-dreamboat.ngrok-free.dev 8080
swimmable-abstract-dreamboat
