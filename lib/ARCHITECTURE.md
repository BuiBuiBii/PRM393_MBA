# Kiến trúc Flutter — GitAnalyzer

```
lib/
  main.dart              # Khởi động app, ProviderScope
  app.dart               # Theme, router, bootstrap
  core/                  # Hạ tầng dùng chung
    config/              # API URL, env
    constants/           # Strings, routes, sizes
    network/             # Dio, AppApi, repositories provider
    router/              # go_router
    theme/
    auth/                # OAuth services
    storage/
  features/              # Theo domain nghiệp vụ
    auth/
      data/              # AuthRepository
      providers/
      screens/
    repositories/
      data/              # RepositoryRepository
      providers/
      screens/
      widgets/
    roadmaps/
      providers/
      screens/
      widgets/
    ...
  shared/
    models/
    widgets/
    utils/
```

## Luồng dữ liệu (chuẩn)

```
Screen  →  Provider (Notifier)  →  Repository  →  AppApi / Dio  →  Backend
```

- **Screen:** UI + sự kiện người dùng (`onPressed` gọi notifier).
- **Provider:** state (loading / error / data), gọi repository.
- **Repository:** map JSON → model, không biết widget.
- **AppApi:** HTTP endpoints.

## Import providers

```dart
import '../../feature_providers.dart';
// hoặc import trực tiếp feature/providers/...
```
