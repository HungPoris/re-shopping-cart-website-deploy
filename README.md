# 🛒 RE Shopping Cart

Ứng dụng giỏ hàng mua sắm được xây dựng với **Spring Boot 4.0.1**, **Java 21**, và **MySQL**.

## 🏗️ Kiến trúc

```
Local Computer → GitHub → GitHub Actions → DockerHub → AWS EC2 + Aiven MySQL
```

## 🚀 Deployment

Dự án này được cấu hình để tự động deploy lên AWS EC2 thông qua GitHub Actions.

### Yêu cầu

- ✅ Tài khoản GitHub
- ✅ Tài khoản DockerHub
- ✅ Tài khoản AWS (EC2)
- ✅ Tài khoản Aiven (MySQL)

### Quick Start

1. **Xem hướng dẫn chi tiết:** [DEPLOYMENT.md](DEPLOYMENT.md)

2. **Cấu hình GitHub Secrets:**
   - `DOCKERHUB_USERNAME`
   - `DOCKERHUB_TOKEN`
   - `EC2_HOST`
   - `EC2_USERNAME`
   - `EC2_SSH_KEY`
   - `DB_URL`
   - `DB_USERNAME`
   - `DB_PASSWORD`

3. **Push code lên GitHub:**
   ```bash
   git add .
   git commit -m "Deploy application"
   git push origin main
   ```

4. **Ứng dụng sẽ tự động deploy!** 🎉

## 🛠️ Development

### Chạy local với Docker

```bash
# Copy environment template
cp .env.example .env

# Sửa file .env với thông tin database của bạn
nano .env

# Build và chạy
docker-compose up --build
```

Truy cập: http://localhost:8080

### Chạy local với Gradle

```bash
# Build
./gradlew build

# Run
./gradlew bootRun
```

## 📁 Cấu trúc dự án

```
re-shopping-cart-website/
├── src/
│   ├── main/
│   │   ├── java/          # Source code
│   │   └── resources/     # Configuration & templates
│   └── test/              # Tests
├── .github/
│   └── workflows/
│       └── deploy.yml     # CI/CD pipeline
├── Dockerfile             # Docker configuration
├── docker-compose.yml     # Local development
├── deploy.sh              # EC2 deployment script
├── DEPLOYMENT.md          # Hướng dẫn deploy chi tiết
└── build.gradle           # Gradle configuration
```

## 🔧 Technologies

- **Backend:** Spring Boot 4.0.1
- **Language:** Java 21
- **Template Engine:** Thymeleaf
- **Database:** MySQL (Aiven)
- **ORM:** Spring Data JPA
- **Build Tool:** Gradle
- **Containerization:** Docker
- **CI/CD:** GitHub Actions
- **Hosting:** AWS EC2

## 📝 Environment Variables

Tạo file `.env` từ `.env.example`:

```bash
DB_URL=jdbc:mysql://your-host:port/database?ssl-mode=REQUIRED
DB_USERNAME=your-username
DB_PASSWORD=your-password
SPRING_PROFILES_ACTIVE=prod
```

## 🔄 CI/CD Pipeline

Workflow tự động khi push lên `main`:

1. ✅ Build ứng dụng với Gradle
2. ✅ Build Docker image
3. ✅ Push image lên DockerHub
4. ✅ Deploy lên EC2
5. ✅ Verify deployment

## 📚 Documentation

- [Hướng dẫn Deployment chi tiết](DEPLOYMENT.md)
- [Spring Boot Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/)

## 🤝 Contributing

1. Fork repository
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is created for educational purposes.

## 👨‍💻 Author

Rikkei Academy - Rikkei Education

---

**Happy Coding! 🚀**
