# RE Shopping Cart - Deployment Guide

Hướng dẫn chi tiết để deploy ứng dụng RE Shopping Cart lên AWS EC2 với CI/CD tự động.

---

## 📋 Mục lục

1. [Yêu cầu](#yêu-cầu)
2. [Cấu hình Database (Aiven MySQL)](#1-cấu-hình-database-aiven-mysql)
3. [Cấu hình DockerHub](#2-cấu-hình-dockerhub)
4. [Cấu hình AWS EC2](#3-cấu-hình-aws-ec2)
5. [Cấu hình GitHub Secrets](#4-cấu-hình-github-secrets)
6. [Deploy ứng dụng](#5-deploy-ứng-dụng)
7. [Kiểm tra và xác minh](#6-kiểm-tra-và-xác-minh)
8. [Troubleshooting](#7-troubleshooting)

---

## Yêu cầu

Trước khi bắt đầu, bạn cần:

- ✅ Tài khoản GitHub (đã có repository)
- ✅ Tài khoản DockerHub (miễn phí)
- ✅ Tài khoản AWS (có free tier)
- ✅ Tài khoản Aiven (có free tier)
- ✅ Docker đã cài đặt trên máy local (để test)

---

## 1. Cấu hình Database (Aiven MySQL)

### Bước 1.1: Tạo tài khoản Aiven

1. Truy cập: https://aiven.io
2. Click **"Sign up"** và đăng ký tài khoản miễn phí
3. Xác nhận email

### Bước 1.2: Tạo MySQL Database

1. Sau khi đăng nhập, click **"Create service"**
2. Chọn **MySQL**
3. Chọn plan **"Free"** (Hobbyist - Free)
4. Chọn Cloud provider: **AWS**
5. Chọn Region gần nhất (ví dụ: **Singapore** hoặc **Tokyo**)
6. Đặt tên service: `re-shopping-cart-db`
7. Click **"Create service"**

### Bước 1.3: Đợi database khởi động

- Database sẽ mất khoảng 5-10 phút để khởi động
- Trạng thái sẽ chuyển từ "Rebuilding" → "Running"

### Bước 1.4: Lấy thông tin kết nối

Khi database đã chạy:

1. Click vào service `re-shopping-cart-db`
2. Vào tab **"Overview"**
3. Lưu lại các thông tin sau:

```
Service URI: mysql://avnadmin:password@host:port/defaultdb?ssl-mode=REQUIRED
Host: xxx-xxx.aivencloud.com
Port: 12345
User: avnadmin
Password: xxxxxxxxxx
Database: defaultdb
```

4. Tạo database cho ứng dụng:
   - Vào tab **"Query Editor"**
   - Chạy lệnh SQL:
   ```sql
   CREATE DATABASE shopping_cart;
   ```

### Bước 1.5: Tạo URL kết nối cho Spring Boot

Format URL:
```
jdbc:mysql://<host>:<port>/shopping_cart?ssl-mode=REQUIRED
```

Ví dụ:
```
jdbc:mysql://re-shopping-cart-db-xxx.aivencloud.com:12345/shopping_cart?ssl-mode=REQUIRED
```

**Lưu lại thông tin này để dùng sau!**

---

## 2. Cấu hình DockerHub

### Bước 2.1: Tạo tài khoản DockerHub

1. Truy cập: https://hub.docker.com
2. Click **"Sign up"** và tạo tài khoản
3. Xác nhận email

### Bước 2.2: Tạo Access Token

1. Đăng nhập vào DockerHub
2. Click vào avatar → **"Account Settings"**
3. Vào tab **"Security"**
4. Click **"New Access Token"**
5. Đặt tên: `github-actions`
6. Chọn permissions: **Read, Write, Delete**
7. Click **"Generate"**
8. **Lưu lại token này** (chỉ hiển thị 1 lần!)

### Bước 2.3: Tạo Repository

1. Vào trang chủ DockerHub
2. Click **"Create Repository"**
3. Đặt tên: `re-shopping-cart`
4. Chọn **Public** (hoặc Private nếu muốn)
5. Click **"Create"**

**Lưu lại:**
- DockerHub Username: `your-username`
- Access Token: `dckr_pat_xxxxxxxxxxxxx`

---

## 3. Cấu hình AWS EC2

### Bước 3.1: Tạo EC2 Instance

1. Đăng nhập AWS Console: https://console.aws.amazon.com
2. Vào **EC2 Dashboard**
3. Click **"Launch Instance"**

**Cấu hình:**

- **Name**: `re-shopping-cart-server`
- **AMI**: Ubuntu Server 22.04 LTS (Free tier eligible)
- **Instance type**: `t2.micro` (Free tier eligible)
- **Key pair**:
  - Click "Create new key pair"
  - Name: `re-shopping-cart-key`
  - Type: RSA
  - Format: `.pem`
  - **Download và lưu file .pem này!**

- **Network settings**:
  - Click "Edit"
  - Auto-assign public IP: **Enable**
  - Firewall (Security groups): Create new
    - Name: `re-shopping-cart-sg`
    - Add rules:
      - SSH (22) - Source: My IP
      - HTTP (80) - Source: Anywhere
      - Custom TCP (8080) - Source: Anywhere

- **Storage**: 8 GB gp3 (Free tier)

4. Click **"Launch instance"**

### Bước 3.2: Kết nối vào EC2

Sau khi instance chạy:

1. Lấy **Public IP** của instance (ví dụ: `54.123.45.67`)
2. Mở terminal và kết nối:

```bash
# Đặt quyền cho key file
chmod 400 re-shopping-cart-key.pem

# SSH vào EC2
ssh -i re-shopping-cart-key.pem ubuntu@54.123.45.67
```

### Bước 3.3: Cài đặt Docker trên EC2

Sau khi SSH vào EC2, chạy các lệnh sau:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker ubuntu

# Logout and login again for group changes
exit
```

Kết nối lại:
```bash
ssh -i re-shopping-cart-key.pem ubuntu@54.123.45.67
```

Kiểm tra Docker:
```bash
docker --version
docker ps
```

### Bước 3.4: Tạo file .env trên EC2

```bash
# Tạo file .env
nano .env
```

Thêm nội dung (thay thế bằng thông tin thực của bạn):
```bash
DB_URL=jdbc:mysql://your-aiven-host.aivencloud.com:12345/shopping_cart?ssl-mode=REQUIRED
DB_USERNAME=avnadmin
DB_PASSWORD=your-database-password
DOCKERHUB_USERNAME=your-dockerhub-username
```

Lưu file: `Ctrl + X` → `Y` → `Enter`

**Lưu lại:**
- EC2 Public IP: `54.123.45.67`
- EC2 Username: `ubuntu`
- Private Key: nội dung file `.pem`

---

## 4. Cấu hình GitHub Secrets

### Bước 4.1: Thêm Secrets vào GitHub

1. Vào repository GitHub của bạn
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**

Thêm các secrets sau:

| Secret Name | Value | Mô tả |
|------------|-------|-------|
| `DOCKERHUB_USERNAME` | `your-dockerhub-username` | Username DockerHub |
| `DOCKERHUB_TOKEN` | `dckr_pat_xxxxx` | Access token từ DockerHub |
| `EC2_HOST` | `54.123.45.67` | Public IP của EC2 |
| `EC2_USERNAME` | `ubuntu` | Username SSH (thường là ubuntu) |
| `EC2_SSH_KEY` | Nội dung file `.pem` | Private key để SSH vào EC2 |
| `DB_URL` | `jdbc:mysql://...` | URL kết nối MySQL từ Aiven |
| `DB_USERNAME` | `avnadmin` | Username MySQL |
| `DB_PASSWORD` | `your-password` | Password MySQL |

### Bước 4.2: Lấy nội dung SSH Key

```bash
# Trên máy local
cat re-shopping-cart-key.pem
```

Copy toàn bộ nội dung (bao gồm `-----BEGIN RSA PRIVATE KEY-----` và `-----END RSA PRIVATE KEY-----`)

---

## 5. Deploy ứng dụng

### Bước 5.1: Test Docker build local (Optional)

```bash
# Tại thư mục dự án
cd /Users/hungpori/Documents/GitHub/re-shopping-cart-website

# Tạo file .env từ template
cp .env.example .env

# Sửa file .env với thông tin thực
nano .env

# Build Docker image
docker build -t re-shopping-cart:test .

# Test chạy container
docker run -p 8080:8080 --env-file .env re-shopping-cart:test
```

Truy cập: http://localhost:8080

Nếu chạy thành công, dừng container: `Ctrl + C`

### Bước 5.2: Push code lên GitHub

```bash
# Add tất cả file mới
git add .

# Commit
git commit -m "Add Docker and CI/CD configuration"

# Push lên GitHub
git push origin main
```

### Bước 5.3: Theo dõi GitHub Actions

1. Vào repository GitHub
2. Click tab **"Actions"**
3. Xem workflow **"Deploy RE Shopping Cart"** đang chạy
4. Click vào workflow để xem chi tiết

Workflow sẽ:
- ✅ Build ứng dụng với Gradle
- ✅ Build Docker image
- ✅ Push lên DockerHub
- ✅ Deploy lên EC2
- ✅ Verify deployment

### Bước 5.4: Kiểm tra trên EC2

SSH vào EC2:
```bash
ssh -i re-shopping-cart-key.pem ubuntu@54.123.45.67
```

Kiểm tra container:
```bash
# Xem container đang chạy
docker ps

# Xem logs
docker logs re-shopping-cart

# Xem logs realtime
docker logs -f re-shopping-cart
```

---

## 6. Kiểm tra và xác minh

### Bước 6.1: Truy cập ứng dụng

Mở trình duyệt và truy cập:
```
http://<EC2_PUBLIC_IP>:8080
```

Ví dụ: `http://54.123.45.67:8080`

### Bước 6.2: Test các chức năng

- [ ] Trang chủ hiển thị đúng
- [ ] Xem danh sách sản phẩm
- [ ] Thêm sản phẩm vào giỏ hàng
- [ ] Xem giỏ hàng
- [ ] Cập nhật số lượng
- [ ] Xóa sản phẩm khỏi giỏ

### Bước 6.3: Kiểm tra database

SSH vào EC2 và kiểm tra kết nối database:
```bash
docker logs re-shopping-cart | grep -i "database\|mysql\|connection"
```

Nếu thấy "HikariPool" và không có lỗi → Database kết nối thành công!

---

## 7. Troubleshooting

### Lỗi: Container không start

```bash
# Xem logs chi tiết
docker logs re-shopping-cart

# Xem logs lỗi
docker logs re-shopping-cart 2>&1 | grep -i error
```

**Nguyên nhân thường gặp:**
- Database connection failed → Kiểm tra DB_URL, DB_USERNAME, DB_PASSWORD
- Port 8080 đã được sử dụng → Dừng container cũ: `docker stop re-shopping-cart`

### Lỗi: Không truy cập được ứng dụng

1. **Kiểm tra Security Group:**
   - Vào EC2 Console → Security Groups
   - Đảm bảo port 8080 đã mở cho 0.0.0.0/0

2. **Kiểm tra container:**
   ```bash
   docker ps | grep re-shopping-cart
   ```

3. **Kiểm tra port:**
   ```bash
   sudo netstat -tlnp | grep 8080
   ```

### Lỗi: GitHub Actions failed

1. **Kiểm tra Secrets:**
   - Vào Settings → Secrets → Actions
   - Đảm bảo tất cả secrets đã được thêm đúng

2. **Kiểm tra logs:**
   - Vào Actions tab
   - Click vào workflow failed
   - Xem step nào bị lỗi

### Lỗi: SSH connection failed

```bash
# Kiểm tra SSH key permissions
chmod 400 re-shopping-cart-key.pem

# Test SSH connection
ssh -v -i re-shopping-cart-key.pem ubuntu@<EC2_IP>
```

### Lỗi: Database connection timeout

1. **Kiểm tra Aiven database đang chạy:**
   - Vào Aiven Console
   - Đảm bảo service status = "Running"

2. **Kiểm tra SSL mode:**
   - URL phải có `?ssl-mode=REQUIRED`

3. **Test kết nối từ EC2:**
   ```bash
   # Install MySQL client
   sudo apt install -y mysql-client

   # Test connection
   mysql -h <aiven-host> -P <port> -u avnadmin -p
   ```

---

## 🎉 Hoàn thành!

Bây giờ bạn đã có:

✅ Ứng dụng chạy trên EC2
✅ CI/CD tự động với GitHub Actions
✅ Docker image trên DockerHub
✅ Database trên Aiven MySQL

**Mỗi lần push code lên GitHub, ứng dụng sẽ tự động deploy!**

---

## 📚 Tài liệu tham khảo

- [Spring Boot Docker Guide](https://spring.io/guides/gs/spring-boot-docker/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [Aiven MySQL Documentation](https://docs.aiven.io/docs/products/mysql)

---

## 🔄 Cập nhật ứng dụng

Để cập nhật ứng dụng:

1. Sửa code trên máy local
2. Commit và push lên GitHub:
   ```bash
   git add .
   git commit -m "Update feature"
   git push origin main
   ```
3. GitHub Actions sẽ tự động deploy!

Hoặc deploy thủ công trên EC2:
```bash
ssh -i re-shopping-cart-key.pem ubuntu@<EC2_IP>
./deploy.sh
```
