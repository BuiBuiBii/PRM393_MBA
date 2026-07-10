# KẾ HOẠCH NÂNG 3 TIÊU CHÍ CỐT LÕI LÊN 9/10

**App:** GitAnalyzer Flutter  
**Tiêu chí GV:** `Tieu_chi_cham_code_ung_dung_mobile.docx`  
**Mục tiêu:** 3 tiêu chí cốt lõi đều **≥ 9/10**

| Tiêu chí | Hiện tại | Mục tiêu |
|----------|----------|----------|
| 1. Cấu trúc project rõ ràng | 9/10 | **9/10** (giữ + củng cố) |
| 2. Tách UI thành widget nhỏ | 7.5/10 | **9/10** |
| 3. Tách logic khỏi UI | 7/10 | **9/10** |

**Có thể đạt 9/10 cả 3** — app đã có nền tốt; cần **hoàn tất refactor dở dang** (provider đã tách file nhưng screen vẫn import `app_providers.dart`).

**Ước tính thời gian:** 2–3 ngày làm việc (chia 3 phase).

---

## Tình trạng hiện tại (phát hiện quan trọng)

### ✅ Đã làm một phần nhưng CHƯA nối dây

Các file provider **đã tồn tại** trong từng feature:

```
features/repositories/providers/repository_provider.dart   (~358 dòng)
features/chat/providers/chat_provider.dart                 (~175 dòng)
features/roadmaps/providers/roadmap_provider.dart          (~387 dòng)
features/dashboard/providers/dashboard_provider.dart       (~33 dòng)
features/notifications/providers/notification_provider.dart (~58 dòng)
```

Nhưng **11 màn hình vẫn import** `features/app_providers.dart` (~900 dòng) — file “god” trùng logic.

Chỉ `roadmap_detail_screen.dart` dùng `../providers/roadmap_provider.dart`.

### ⚠️ File UI còn quá dài (kéo điểm tách widget)

| File | Dòng | Vấn đề |
|------|------|--------|
| `roadmaps_screen.dart` | 617 | List + filter + create sheet trong 1 file |
| `chat_screen.dart` | 580 | Có `part` widget nhưng screen vẫn nặng |
| `analysis_result_screen.dart` | 492 | Nhiều private widget trong cùng file |
| `roadmap_mobile_widgets.dart` | 504 | Widget file quá lớn |
| `main_shell.dart` | 329 | Drawer + nav logic lẫn UI |

---

## Tiêu chí 1: Cấu trúc project → 9/10 (giữ & củng cố)

**Điểm hiện tại 9/10** — không cần đại tu, chỉ cần **dọn dẹp cho nhất quán**.

### Việc cần làm

#### Phase 1A — Xóa `app_providers.dart`, chuyển import (ưu tiên cao)

| Bước | Hành động |
|------|-----------|
| 1 | Cập nhật import 11 file đang dùng `app_providers.dart` → import provider đúng feature |
| 2 | Xóa `lib/features/app_providers.dart` |
| 3 | (Tuỳ chọn) Tạo `lib/features/feature_providers.dart` chỉ **export** các provider — 1 dòng re-export mỗi feature |

**File cần đổi import:**

```
dashboard_screen.dart          → dashboard/providers/dashboard_provider.dart
notifications_screen.dart      → notifications/providers/notification_provider.dart
repositories_screen.dart       → repositories/providers/repository_provider.dart
repository_detail_screen.dart  → repositories/providers/repository_provider.dart
chat_screen.dart               → chat/providers/chat_provider.dart
roadmaps_screen.dart           → roadmaps/providers/roadmap_provider.dart
roadmap_mobile_widgets.dart    → repositories + roadmaps providers
analysis_result_screen.dart    → repositories/providers/repository_provider.dart
ai_feedback_dashboard_screen.dart
snapshot_select_repo_screen.dart
github_connect_screen.dart
```

#### Phase 1B — Chuẩn hoá cấu trúc mỗi feature

Mẫu GV thích (áp dụng cho feature lớn):

```
features/repositories/
  data/
    repository_repository.dart    ← NEW (tách API khỏi Notifier)
  providers/
    repository_provider.dart
  screens/
    repositories_screen.dart
    repository_detail_screen.dart
  widgets/
    repository_card.dart          ← NEW
    repository_sync_bar.dart      ← NEW
```

#### Phase 1C — Tài liệu cấu trúc (5 phút, cộng điểm khi GV review)

Thêm `lib/ARCHITECTURE.md` ngắn (~30 dòng): giải thích `core / features / shared` và luồng `Screen → Provider → Repository → Api`.

### Tiêu chí đạt 9/10 khi

- [ ] Không còn `app_providers.dart`
- [ ] Mỗi feature có `providers/` (và `data/` nếu gọi API)
- [ ] `main.dart` < 20 dòng, không logic nghiệp vụ
- [ ] GV mở project → tìm code theo feature trong < 30 giây

---

## Tiêu chí 2: Tách UI widget → 9/10

**Mục tiêu:** Không file screen nào > **~250 dòng**; `build()` mỗi widget < **~60 dòng**.

### Phase 2A — Roadmaps (impact cao nhất)

**Tách từ `roadmaps_screen.dart` (617 dòng):**

```
features/roadmaps/widgets/
  roadmap_list_header.dart       ← search + filter chips
  roadmap_filter_sheet.dart      ← bottom sheet lọc
  roadmap_create_sheet.dart      ← tạo roadmap
  roadmap_list_tile.dart         ← 1 item trong list
  roadmap_empty_state.dart       ← empty + CTA
```

**Sau tách — `roadmaps_screen.dart` chỉ còn:**

```dart
// ~80–120 dòng: scaffold + AsyncListBody + gọi widget con
@override
Widget build(BuildContext context) {
  final state = ref.watch(roadmapProvider);
  return Scaffold(
    body: AsyncListBody(
      isLoading: state.isLoading,
      isEmpty: state.roadmaps.isEmpty,
      onRetry: () => ref.read(roadmapProvider.notifier).loadRoadmaps(),
      child: RoadmapListView(...),
    ),
  );
}
```

**Tách từ `roadmap_mobile_widgets.dart` (504 dòng):**

```
roadmap_stat_row.dart
roadmap_phase_card.dart
roadmap_task_checkbox.dart
roadmap_progress_header.dart
```

### Phase 2B — Chat

`chat_screen_widgets.dart` đang là `part of chat_screen.dart` → **tách thành file riêng**:

```
features/chat/widgets/
  chat_header.dart
  chat_message_bubble.dart
  chat_prompt_chips.dart
  chat_input_bar.dart
  chat_session_drawer.dart
```

`chat_screen.dart` mục tiêu: **~150 dòng**.

### Phase 2C — Analysis result

```
features/analysis/widgets/
  analysis_score_card.dart
  analysis_skill_section.dart
  role_match_card.dart          ← chuyển từ _RoleMatchCard
  role_match_skill_list.dart
```

`analysis_result_screen.dart` mục tiêu: **~180 dòng**.

### Phase 2D — Shell & màn phụ

| File | Tách ra |
|------|---------|
| `main_shell.dart` | `app_drawer.dart`, `drawer_nav_item.dart` |
| `profile_screen.dart` | `profile_form_section.dart` |
| `settings_screen.dart` | `settings_account_tile.dart` |

### Quy tắc khi tách (để GV chấm 9)

1. Widget con **public** nếu dùng lại; `_Private` nếu chỉ 1 màn
2. Truyền data qua **constructor**, không `ref.read` sâu trong widget lá (trừ ConsumerWidget cần thiết)
3. Không copy-paste UI — dùng lại `AppCard`, `PrimaryButton`, `AsyncListBody`
4. Mỗi widget 1 trách nhiệm (header / list / form / empty)

### Tiêu chí đạt 9/10 khi

- [ ] 0 file `screens/*.dart` > 300 dòng
- [ ] `build()` dài nhất < 80 dòng
- [ ] Có thư mục `widgets/` trong ≥ 5 feature
- [ ] GV đọc 1 màn hình hiểu layout trong 2 phút

---

## Tiêu chí 3: Tách logic khỏi UI → 9/10

**Mục tiêu:** Screen **không gọi API**; **không validate nghiệp vụ**; chỉ `ref.read(provider.notifier).action()`.

### Phase 3A — Hoàn tất tách Provider (bắt buộc)

| Việc | Chi tiết |
|------|----------|
| Xóa duplicate | `app_providers.dart` vs file feature — giữ 1 nguồn |
| Cập nhật import | Toàn bộ screen dùng provider feature |
| Tách `RepositoryNotifier` | Chỉ quản lý repo list + selected; không ôm analysis + feedback + packages nếu có thể |

**Gợi ý tách `RepositoryNotifier` (nếu muốn 9+):**

```
repository_provider.dart     → list, sync, select repo
analysis_provider.dart       → analyze, role match, my analyses
ai_feedback_provider.dart    → generate feedback
```

*(Có thể giữ 1 notifier nếu thời gian gấp — nhưng tách file khỏi `app_providers` là tối thiểu.)*

### Phase 3B — Thêm Repository layer (giống Auth)

**Mẫu chuẩn đã có — `auth/`:**

```
AuthApi → AuthRepository → AuthNotifier → LoginScreen
```

**Áp dụng cho feature còn lại:**

```
features/repositories/data/repository_repository.dart
features/roadmaps/data/roadmap_repository.dart
features/chat/data/chat_repository.dart
```

**Provider chỉ:**

```dart
Future<void> loadRoadmaps() async {
  state = state.copyWith(isLoading: true);
  try {
    final items = await _repository.getRoadmaps();
    state = state.copyWith(roadmaps: items, isLoading: false);
  } catch (e) {
    state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
  }
}
```

**Screen chỉ:**

```dart
onPressed: () => ref.read(roadmapProvider.notifier).loadRoadmaps(),
```

### Phase 3C — Dọn logic còn trong UI

| File | Logic cần chuyển ra Provider |
|------|------------------------------|
| `login_screen.dart` | `_submit()` OK nhưng validation form giữ ở UI — chấp nhận được |
| `roadmaps_screen.dart` | `_openCreateSheet`, filter logic → `RoadmapNotifier` |
| `chat_screen.dart` | `_scrollToBottom`, gửi tin → `ChatNotifier.sendMessage()` |
| `auth_provider.dart` | `fetchProfile`, `saveProfile`, GitHub → `ProfileRepository` |
| `github_connect_screen.dart` | Gọi `authProvider.connectGitHub()` — đã OK |

### Phase 3D — Không gọi API trong widget

Kiểm tra grep trước khi nộp:

```bash
# Không được có trong screens/
rg "ref\.read\(appApiProvider\)" lib/features/**/screens/
rg "_api\." lib/features/**/screens/
```

Chỉ `providers/` và `data/` được gọi API.

### Tiêu chí đạt 9/10 khi

- [ ] Không còn `app_providers.dart`
- [ ] Auth + ≥ 2 feature khác có `data/*_repository.dart`
- [ ] 0 API call trong `screens/`
- [ ] `onPressed` / `onSubmit` ≤ 3 dòng (gọi notifier)
- [ ] Provider có xử lý loading / error / empty thống nhất

---

## Lộ trình thực hiện (đề xuất 3 phase)

```
Phase 1 (4–6h)  ──► Cấu trúc 9/10 + Logic 7→8.5
  └─ Xóa app_providers, cập nhật import, ARCHITECTURE.md

Phase 2 (6–8h)  ──► Widget 7.5→9
  └─ Tách roadmaps + chat + analysis widgets

Phase 3 (4–6h)  ──► Logic 8.5→9
  └─ Repository layer + tách RepositoryNotifier (tuỳ chọn)
```

### Thứ tự ưu tiên nếu thiếu thời gian

1. **Phase 1** — impact lớn nhất, ít rủi ro
2. **Phase 2A** (roadmaps) — file dài nhất GV dễ thấy
3. **Phase 3B** repository cho `repositories` + `roadmaps`
4. Phần còn lại

---

## Dự đoán điểm sau từng phase

| Phase | Cấu trúc | Tách widget | Tách logic |
|-------|----------|-------------|------------|
| Hiện tại | 9.0 | 7.5 | 7.0 |
| Sau Phase 1 | **9.0** | 7.5 | **8.5** |
| Sau Phase 2 | 9.0 | **9.0** | 8.5 |
| Sau Phase 3 | **9.0** | **9.0** | **9.0** |

**Tổng điểm project:** ~82 → **~88–90/100**

---

## Checklist nộp bài — 3 tiêu chí cốt lõi

### 1. Cấu trúc project
- [ ] `lib/core/`, `lib/features/`, `lib/shared/` đầy đủ
- [ ] Không có `app_providers.dart` god file
- [ ] Mỗi feature: `screens/` + `providers/` (+ `widgets/`, `data/`)
- [ ] `lib/ARCHITECTURE.md` có sơ đồ thư mục

### 2. Tách UI widget
- [ ] Không screen > 300 dòng
- [ ] Có `features/*/widgets/` với ≥ 15 widget file mới
- [ ] Dùng `AsyncListBody`, `ErrorState`, `AppCard` thống nhất
- [ ] Test overflow emulator nhỏ (360×640)

### 3. Tách logic khỏi UI
- [ ] Luồng `Screen → Provider → Repository → Api` rõ
- [ ] Không API trong `build()` và `screens/`
- [ ] Auth + repositories có `data/*_repository.dart`
- [ ] `flutter analyze` → 0 error, 0 warning

---

## Rủi ro & lưu ý

| Rủi ro | Cách tránh |
|--------|------------|
| Tách provider gây lỗi import | Làm từng feature, chạy `flutter analyze` sau mỗi bước |
| UI tách quá nhỏ, khó đọc | Mỗi widget ≥ 20 dòng có nghĩa; không tách 1 `Text` thành file |
| Trùng code giữa provider cũ/mới | Xóa `app_providers.dart` ngay sau khi migrate xong |
| Regression chức năng | Test thủ công 6 luồng trong `DANH_GIA_CODE_THEO_TIEU_CHI.md` |

---

## Kết luận

**Có thể lên 9/10 cả 3 tiêu chí** vì:

1. **Cấu trúc** đã 9 — chỉ cần dọn `app_providers.dart`
2. **Widget** — cần tách 3–4 màn lớn (roadmaps, chat, analysis)
3. **Logic** — provider đã viết sẵn từng file, chỉ chưa wire + thêm repository layer

**Bước tiếp theo:** Bạn đọc plan này → xác nhận → mình bắt đầu **Phase 1** (xóa `app_providers.dart` + cập nhật import), sau đó Phase 2 tách UI roadmaps/chat.

---

*File plan — chưa thực hiện code. Cập nhật sau khi hoàn thành từng phase.*
