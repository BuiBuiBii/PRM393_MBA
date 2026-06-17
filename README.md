# PRM393_MBA — GitAnalyzer Flutter

GitHub Learning Mentor Mobile App — phiên bản **Flutter**.

## Cấu trúc

```
├── lib/
│   ├── main.dart                 # Entry point
│   ├── app.dart                  # MaterialApp + Provider overrides
│   ├── core/                     # Config, network, router, theme, demo
│   ├── features/
│   │   ├── auth/                 # Login, register, JWT
│   │   ├── dashboard/            # Trang chủ
│   │   └── shell/                # Bottom navigation
│   └── shared/                   # Models, widgets dùng chung
└── pubspec.yaml
```

## Yêu cầu

1. Cài [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (>= 3.3)
2. Cài Android Studio + Android SDK
3. Backend GitAnalyzer (mặc định dùng API Render production, hoặc BE local khi develop)

## Cài đặt lần đầu

```powershell
git clone https://github.com/BuiBuiBii/PRM393_MBA.git
cd PRM393_MBA

# Tạo folder android/ios (chỉ chạy 1 lần)
flutter create . --org com.gitanalyzer.app --project-name gitanalyzer_flutter

# Cài dependencies
flutter pub get

# Kiểm tra môi trường
flutter doctor
```

## Chạy app trên Android

### Cách nhanh nhất (API thật — mặc định)

```powershell
cd flutter_app
.\scripts\run_android.ps1
```

Hoặc trong **VS Code / Cursor**: chọn **"Android — BE Render (mặc định)"** rồi bấm Run.

- **API mặc định**: `https://career-roadmap-api-zs7y.onrender.com/api`
- Đăng nhập bằng **tài khoản đã đăng ký** trên BE, hoặc **Đăng ký** / **Google** / **GitHub**
- `DEMO_MODE=false` (mặc định) — không dùng dữ liệu giả

### Các chế độ khác

```powershell
# BE chạy local trên máy (port 5000) — phải `npm run dev` trong folder BE trước
.\scripts\run_android.ps1 -Mode Local

# Demo offline (chỉ khi cần test không có mạng/BE)
.\scripts\run_android.ps1 -Mode Demo
```

### Lưu ý

- **Đã từng chạy demo**: gỡ cài app hoặc Đăng xuất để xóa token demo cũ
- **Connection refused** (Local): BE chưa chạy hoặc sai URL
- **Build lỗi `jni` / `RECORD_NOT_SET` / APK invalid**: chạy `.\scripts\fix_android_build.ps1` rồi build lại
- **Google `ApiException: 10`**: chưa cấu hình SHA-1 OAuth trên Google Cloud → dùng đăng nhập email/demo.
- **Android Emulator + BE local**: dùng `http://10.0.2.2:5000/api` (không dùng `localhost`).
- **Máy thật**: dùng IP LAN của máy chạy backend, ví dụ `http://192.168.x.x:5000/api`
- **iOS Simulator**: dùng `http://localhost:5000/api`
