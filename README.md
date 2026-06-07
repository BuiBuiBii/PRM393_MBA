# GitAnalyzer Flutter

App mobile **Flutter** thay the phien ban React + Capacitor.

## Cau truc

```
flutter_app/
├── lib/
│   ├── main.dart                 # Entry point
│   ├── app.dart                  # MaterialApp + Provider overrides
│   ├── core/                     # Config, network, router, theme
│   ├── features/
│   │   ├── auth/                 # Login, register, JWT
│   │   ├── dashboard/            # Trang chu
│   │   └── shell/                # Bottom navigation
│   └── shared/                   # Models, widgets dung chung
└── pubspec.yaml
```

## Yeu cau

1. Cai [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (>= 3.3)
2. Cai Android Studio + Android SDK
3. Backend GitAnalyzer dang chay (mac dinh `http://localhost:5000/api`)

## Cai dat lan dau

```powershell
cd d:\PRM\Mobile_Project\flutter_app

# Tao folder android/ios (chi chay 1 lan)
flutter create . --org com.gitanalyzer.app --project-name gitanalyzer_flutter

# Cai dependencies
flutter pub get

# Kiem tra moi truong
flutter doctor
```

## Chay app

```powershell
# Android emulator: localhost backend = 10.0.2.2
flutter run

# Doi API URL neu can
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000/api
```

## Map voi app React cu

| React (Capacitor) | Flutter (moi) |
|-------------------|---------------|
| `src/main.tsx` | `lib/main.dart` |
| `src/app/routes.tsx` | `lib/core/router/app_router.dart` |
| `src/app/stores/authStore.ts` | `lib/features/auth/providers/auth_provider.dart` |
| `src/app/services/apis/apiClient.ts` | `lib/core/network/dio_client.dart` |
| `src/app/pages/*` | `lib/features/*/screens/*` (dang port dan) |

## Da lam

- [x] Scaffold project Flutter
- [x] API client (Dio) + JWT storage
- [x] Auth: login, register, logout, bootstrap
- [x] Router + bottom nav (5 tab)
- [x] Dashboard co ban

## Can port tiep (tu React)

- [ ] Repositories + Analysis
- [ ] Chat AI Mentor
- [ ] Roadmaps
- [ ] GitHub OAuth
- [ ] Notifications, Progress, Settings day du

## Luu y API URL

- **Android Emulator**: dung `http://10.0.2.2:5000/api` (mac dinh trong `AppConfig`)
- **May that**: dung IP LAN cua may chay backend, vi du `http://192.168.x.x:5000/api`
- **iOS Simulator**: dung `http://localhost:5000/api`

## Quan he voi project cu

- `Mobile_Project/src/` — React FE cu (van giu de tham khao)
- `Mobile_Project/android/` — Capacitor Android cu (co the bo khi Flutter xong)
- `Mobile_Project/flutter_app/` — **Project Flutter moi**
