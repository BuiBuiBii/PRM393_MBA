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
3. Backend GitAnalyzer đang chạy (mặc định `http://localhost:5000/api`) — hoặc dùng **demo mode**

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

## Chạy app

```powershell
# Android emulator: localhost backend = 10.0.2.2
flutter run

# Demo mode (mặc định bật, không cần backend)
# Tài khoản: demo@gitanalyzer.vn / demo123

# Đổi API URL nếu cần
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000/api

# Tắt demo mode
flutter run --dart-define=DEMO_MODE=false
```

## Lưu ý API URL

- **Android Emulator**: dùng `http://10.0.2.2:5000/api` (mặc định trong `AppConfig`)
- **Máy thật**: dùng IP LAN của máy chạy backend, ví dụ `http://192.168.x.x:5000/api`
- **iOS Simulator**: dùng `http://localhost:5000/api`
