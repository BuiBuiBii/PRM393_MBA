# KẾ HOẠCH MIGRATION DEV2VEC — FLUTTER

**App:** GitAnalyzer Flutter  
**Tham chiếu:** Dev2Vec FE Migration Notes (BE spec)  
**Đối chiếu Web:** `Web_Project` (đã pull `483e20c..e4dd188`)  
**Mục tiêu:** Flutter khớp flow Dev2Vec — không tự tính role/score, dùng API làm nguồn sự thật.

**Ước tính:** 2–3 ngày làm việc (4 phase).

---

## 1. Tóm tắt Dev2Vec cho FE

| Nội dung | Quy tắc |
|----------|---------|
| Role model | Chỉ 5 role: `backend`, `frontend`, `mobile`, `devops`, `data_scientist` |
| Role matches | Tối đa **3** — lấy từ `data.matches[]`, không tự thêm |
| Fullstack / AI Engineer | **Không** dùng trong flow role-match mới |
| Flow chính | Analyze → `POST /role-matches` → chọn match → `POST /roadmaps/generate` |
| Score | Hiển thị `matchScore` BE trả về — **không tự tính** |
| `contextSource` | Chat có thể là `dev2vec` — không chỉ check `skillVector` |
| Error codes | `DEV2VEC_*` cần message rõ cho user |

---

## 2. Tình trạng Flutter hiện tại

### ✅ Đã ổn (không cần đổi gấp)

| Mục | File | Ghi chú |
|-----|------|---------|
| Analyze repo | `lib/core/network/app_api.dart` | `POST /analysis/repositories/:id` |
| Role match UI cơ bản | `lib/features/analysis/widgets/role_match_card.dart` | Render score, skills, other roles |
| AI Feedback fields | `lib/shared/models/app_models.dart` | `summary`, `strengthFeedback`, … |
| Chat contract | `lib/core/network/app_api.dart` | Không phụ thuộc `contextSource` → không crash |
| Response unwrap | `lib/core/network/api_utils.dart` | `success`, `message`, `data` |

### ❌ Lệch spec — cần sửa

| # | Vấn đề | File hiện tại | Rủi ro |
|---|--------|---------------|--------|
| 1 | Hard-code 8 role cũ (Fullstack, AI/ML…) | `lib/core/config/app_config.dart` | User chọn role BE không hỗ trợ |
| 2 | Tự tính role từ text phân tích | `lib/features/roadmaps/utils/roadmap_recommendation.dart` | Score/role không khớp Dev2Vec |
| 3 | Dùng GET legacy role-matches | `lib/core/network/app_api.dart` L73–90 | Thiếu `sourceMode`, multi-repo |
| 4 | Generate roadmap thiếu `roleId`, `useRoleMatching` | `lib/core/network/app_api.dart` L223–239 | Roadmap không cá nhân hóa đúng |
| 5 | `RoleMatchItem` thiếu `roleId` | `lib/shared/models/app_models.dart` L624–661 | Không gửi đúng body generate |
| 6 | Parse skill field cũ | `app_models.dart` | BE gửi `matchedSkillNames` — có thể miss data |
| 7 | Dropdown tự merge role ngoài API | `lib/features/roadmaps/widgets/roadmap_mobile_widgets.dart` L291–299 | Hiện Fullstack/AI trong UI |
| 8 | Không xử lý error `DEV2VEC_*` | `lib/core/network/api_utils.dart` | User thấy lỗi chung chung |
| 9 | Chưa có catalog API | — | Dropdown/filter không đồng bộ BE |
| 10 | Analyze không có `view=detail` | `app_api.dart` | Thiếu `scoreBreakdown`, readiness fields |

---

## 3. Role ID chuẩn (Dev2Vec)

| roleId | roleName |
|--------|----------|
| `backend` | Backend Developer |
| `frontend` | Frontend Developer |
| `mobile` | Mobile Developer |
| `devops` | DevOps Engineer |
| `data_scientist` | Data Scientist |

**Alias cũ** (`backend-developer`, `fullstack-developer`, `ai-engineer`) — chỉ hiển thị nếu có trong data cũ, **không đưa vào flow tạo mới**.

---

## 4. Kế hoạch theo phase

### Phase 1 — API & Models (ưu tiên cao, ~0.5–1 ngày)

**Mục tiêu:** Layer dữ liệu khớp BE trước khi đụng UI.

#### 1A. Cập nhật models

**File:** `lib/shared/models/app_models.dart`

```dart
class RoleMatchItem {
  final String roleId;      // NEW: backend, frontend, ...
  final String role;        // roleName
  final String? scoringMethod;
  // ...
}
```

- Parse thêm: `roleId`, `matchedSkillNames`, `weakSkillNames`, `missingSkillNames`
- Giữ fallback alias cũ: `matchedSkills` → `matchedSkillNames`
- `RoleMatchModel`: thêm `analysisSource?`, `sourceStats?` (optional)

#### 1B. Thêm API methods

**File:** `lib/core/network/app_api.dart`

| Method | Endpoint | Body/Query |
|--------|----------|------------|
| `calculateRoleMatches` | `POST /analysis/role-matches` | `sourceMode`, `repoId`/`repoIds`, `limit: 3` |
| `getRoleCatalog` | `GET /roles/catalog` | — |
| `getSkillCatalog` | `GET /skills/catalog` | — |
| `analyzeRepository` | `POST /analysis/repositories/:id` | `view=summary\|detail`, `includeEvidence` |
| `generateRoadmap` | `POST /roadmaps/generate` | Xem mục 5 |

**Giữ** `GET /analysis/repositories/:id/role-matches` làm fallback tạm (deprecated), gỡ ở Phase 4.

#### 1C. Cập nhật repository layer

| File | Thay đổi |
|------|----------|
| `lib/features/repositories/data/repository_repository.dart` | `calculateRoleMatches(sourceMode, repoId, repoIds, limit)` |
| `lib/features/repositories/providers/repository_provider.dart` | `fetchRoleMatches` → gọi POST mới |
| `lib/features/roadmaps/data/roadmap_repository.dart` | `generateRoadmap` nhận `roleId`, `sourceMode`, `useRoleMatching` |
| `lib/features/roadmaps/providers/roadmap_provider.dart` | Truyền `roleId` + `roleName` từ selected match |

#### 1D. Error handling Dev2Vec

**File:** `lib/core/network/api_utils.dart`

```dart
// Map error code → message tiếng Việt
DEV2VEC_MODEL_UNAVAILABLE     → "Hệ thống phân tích role tạm thời không khả dụng..."
DEV2VEC_INFERENCE_FAILED        → "Không thể phân tích role lúc này..."
DEV2VEC_INVALID_OUTPUT          → "Kết quả phân tích không hợp lệ..."
DEV2VEC_ANALYSIS_REQUIRED       → "Vui lòng phân tích repository trước..."
```

Parse từ `data.code` hoặc `error.code` trong response body.

#### Checklist Phase 1

- [ ] `RoleMatchItem` có `roleId`
- [ ] `POST /analysis/role-matches` hoạt động
- [ ] `generateRoadmap` gửi `roleId` + `useRoleMatching: true`
- [ ] Error `DEV2VEC_*` hiển thị đúng
- [ ] Unit test parse `RoleMatchItem.fromJson` với payload mẫu BE

---

### Phase 2 — Flow Role Match & Generate Roadmap (~0.5–1 ngày)

**Mục tiêu:** User chỉ chọn role từ API, không tự thêm.

#### 2A. Bỏ hard-code role cũ

**File:** `lib/core/config/app_config.dart`

```dart
// TRƯỚC (xóa):
static const List<String> targetRoles = [
  'Frontend Developer', 'Backend Developer', 'Fullstack Developer', ...
];

// SAU:
static const List<Dev2VecRole> dev2VecRoles = [
  Dev2VecRole(id: 'backend', name: 'Backend Developer'),
  Dev2VecRole(id: 'frontend', name: 'Frontend Developer'),
  // ...
];
// Hoặc fetch từ GET /roles/catalog khi app khởi động
```

#### 2B. Refactor `roadmap_recommendation.dart`

| Hàm | Hành động |
|-----|-----------|
| `recommendRoadmapRole` | **Deprecate** — chỉ fallback khi chưa có role match API |
| `recommendJobReadinessRoadmaps` | **Deprecate** — không gợi ý Fullstack/AI |
| `buildSkillInsight` | Giữ — dùng `strengths`/`weaknesses` từ analysis, không tính role |

#### 2C. Cập nhật create roadmap sheet

**File:** `lib/features/roadmaps/widgets/roadmap_mobile_widgets.dart`

**Trước:**
- Merge `AppConfig.targetRoles` vào dropdown
- Gọi `onGenerate(match.role)` — chỉ roleName

**Sau:**
- Chỉ hiện tối đa 3 card từ `roleMatch.matches[]`
- Mỗi card: `roleName`, `matchScore`, `matchLevelLabel`, skill chips
- Tap card → `onGenerate(roleId: match.roleId, targetRole: match.role)`
- Không có dropdown role tự thêm (hoặc dropdown chỉ từ catalog API)
- Nếu `matches` rỗng → CTA "Phân tích repository trước" thay vì gợi ý Fullstack

#### 2D. Cập nhật analysis result screen

**File:** `lib/features/analysis/screens/analysis_result_screen.dart`

- Gọi `calculateRoleMatches(sourceMode: 'single_repo', repoId, limit: 3)`
- Truyền full `RoleMatchItem` (có `roleId`) vào create sheet
- Nút "Tạo Roadmap" disabled nếu chưa analyze / chưa có matches

#### 2E. Cập nhật roadmaps screen (multi-repo)

**File:** `lib/features/roadmaps/screens/roadmaps_screen.dart`

- Create sheet hỗ trợ `sourceMode`:
  - `single_repo` — chọn 1 repo đã analyze
  - `all_analyzed_repos` — tất cả repo đã analyze
  - `selected_repos` — multi-select repo
- Gọi `POST /role-matches` trước khi hiện role cards
- Loading state + error Dev2Vec

#### Checklist Phase 2

- [ ] Không còn Fullstack/AI trong dropdown tạo roadmap
- [ ] Generate gửi `roleId` từ selected match
- [ ] Create sheet chỉ render từ `matches[]` (≤3)
- [ ] Roadmaps screen hỗ trợ `sourceMode`
- [ ] Fallback khi chưa analyze → message rõ, không tự chọn role

---

### Phase 3 — UI bổ sung & parity Web (~0.5–1 ngày)

**Mục tiêu:** Hiển thị đủ field Dev2Vec, gần Web mới.

#### 3A. Role Match Card nâng cấp

**File:** `lib/features/analysis/widgets/role_match_card.dart`

Thêm (theo Web `RoleMatchPanel.tsx`):
- Coverage % / matched skill count (nếu BE trả)
- "Ưu tiên tiếp theo" callout từ `recommendedNextSkills`
- Tap other role chip → chọn làm role generate
- Badge `scoringMethod` (optional, nhỏ)

#### 3B. Analysis result — field mới

**File:** `lib/features/analysis/screens/analysis_result_screen.dart`  
**Model:** `lib/shared/models/app_models.dart` — mở rộng `AnalysisModel`

| Field BE | UI |
|----------|-----|
| `summary.userReadinessScore` | Stat card readiness |
| `summary.userLevel` | Badge level |
| `summary.careerDirection` | Text định hướng |
| `topSkills`, `missingSkills` | Chip lists |
| `scoreBreakdown` (view=detail) | Section breakdown điểm |
| `recommendations[]` | Card title + description |

Gọi analyze với `view=detail` khi vào màn kết quả.

#### 3C. Roadmap detail — Dev2Vec metadata

**File:** `lib/features/roadmaps/widgets/roadmap_detail_sections.dart`

- Card "Cá nhân hóa theo role match" — `roleMatchInfo`, `skillGapSummary`
- Hiển thị `roadmapSource.scoringMethod`, `modelVersion` (caption nhỏ)
- Nút "Reset tiến độ" nếu BE có API

#### 3D. Repository card — readiness preview

**File:** `lib/features/repositories/widgets/repository_card.dart`

- Badge readiness / overall score từ analysis summary (nếu đã analyze)
- Không tự tính — lấy từ `state.analyses`

#### Checklist Phase 3

- [ ] Analysis result hiện readiness, top/missing skills
- [ ] Role match card có thể chọn role khác trong 3 matches
- [ ] Roadmap detail hiện role match metadata
- [ ] Repository card hiện score đã analyze

---

### Phase 4 — Dọn dẹp & đồng bộ Web (~0.5 ngày)

#### 4A. Gỡ code legacy

| Việc | File |
|------|------|
| Xóa `GET role-matches` fallback | `app_api.dart` |
| Xóa/deprecate `recommendRoadmapRole` scoring | `roadmap_recommendation.dart` |
| Cập nhật mock data role cũ | `roadmap_mock_data.dart`, `demo_data.dart` |
| Cập nhật `categoryFromTargetRole` | `normalizers.dart` — map 5 role mới |

#### 4B. Catalog từ API

- Provider `roleCatalogProvider` — fetch `GET /roles/catalog` lúc login/dashboard
- Dùng cho filter roadmaps, label UI — không hard-code

#### 4C. Chat & AI Feedback — defensive

| Mục | Hành động |
|-----|-----------|
| Chat `contextSource: dev2vec` | Không filter/check cứng — OK hiện tại |
| AI Feedback `metadata.analysisSource` | Parse optional, không crash |
| `skillScoreSummary` | Bỏ qua hoặc hiện debug-only |

#### 4D. Docs & test

- [ ] Cập nhật `lib/ARCHITECTURE.md` — flow Dev2Vec
- [ ] Test `test/role_match_model_test.dart` — parse JSON mẫu BE
- [ ] Test integration: analyze → role-matches → generate (demo mode hoặc mock)

---

## 5. Body API chuẩn (tham chiếu implement)

### POST /api/analysis/role-matches

```json
{
  "sourceMode": "single_repo",
  "repoId": "<repoId>",
  "limit": 3
}
```

Multi-repo:
```json
{
  "sourceMode": "selected_repos",
  "repoIds": ["id1", "id2"],
  "limit": 3
}
```

### POST /api/roadmaps/generate

```json
{
  "sourceMode": "single_repo",
  "repoId": "<repoId>",
  "roleId": "backend",
  "targetRole": "Backend Developer",
  "level": "beginner",
  "durationWeeks": 6,
  "language": "vi",
  "useRoleMatching": true
}
```

**Flutter phải lấy `roleId` + `targetRole` từ `matches[i]` user chọn — không tự đặt.**

---

## 6. File cần sửa (tổng hợp)

### Core / Network

```
lib/core/config/app_config.dart
lib/core/network/app_api.dart
lib/core/network/api_utils.dart
lib/core/network/normalizers.dart
lib/shared/models/app_models.dart
```

### Repositories feature

```
lib/features/repositories/data/repository_repository.dart
lib/features/repositories/providers/repository_provider.dart
```

### Roadmaps feature

```
lib/features/roadmaps/data/roadmap_repository.dart
lib/features/roadmaps/providers/roadmap_provider.dart
lib/features/roadmaps/utils/roadmap_recommendation.dart
lib/features/roadmaps/widgets/roadmap_mobile_widgets.dart
lib/features/roadmaps/screens/roadmaps_screen.dart
lib/features/roadmaps/widgets/roadmap_detail_sections.dart
```

### Analysis feature

```
lib/features/analysis/screens/analysis_result_screen.dart
lib/features/analysis/widgets/role_match_card.dart
```

### Repositories UI

```
lib/features/repositories/widgets/repository_card.dart
```

### Test

```
test/role_match_model_test.dart          (mới)
test/roadmap_generate_request_test.dart  (mới, optional)
```

---

## 7. Thứ tự thực hiện (khuyến nghị)

```
Phase 1 (API + Models)
    ↓
Phase 2 (Flow role match + generate)  ← quan trọng nhất cho đúng BE
    ↓
Phase 3 (UI parity)
    ↓
Phase 4 (Cleanup + test)
```

**Nếu chỉ có 1 ngày:** làm Phase 1 + Phase 2 — đủ để app không gửi role sai lên BE.

---

## 8. Test plan

| # | Scenario | Kỳ vọng |
|---|----------|---------|
| 1 | Analyze repo chưa có | Role match → `DEV2VEC_ANALYSIS_REQUIRED` |
| 2 | Analyze xong → role matches | Hiện ≤3 role, có `roleId` |
| 3 | Chọn Backend → generate | Body có `roleId: "backend"`, `useRoleMatching: true` |
| 4 | Create sheet không có match | Không hiện Fullstack/AI trong dropdown |
| 5 | Multi-repo sourceMode | `POST role-matches` với `repoIds` |
| 6 | Dev2Vec tắt | Message `DEV2VEC_MODEL_UNAVAILABLE` rõ ràng |
| 7 | Roadmap detail | Hiện `roleMatchInfo` từ response generate |
| 8 | Chat sau analyze | Không crash khi `contextSource: dev2vec` |

---

## 9. Không nằm trong scope migration này

Các mục **UI gap vs Web** (làm riêng sau Dev2Vec):

- `RepositoryProgressPage` (`/progress`) — trang tiến độ tổng
- `SkillLearningDetailPage` — màn học kỹ năng trong roadmap
- Báo cáo dự án form trên repository detail
- Notifications phân loại + pagination server-side

Xem thêm: so sánh Web pull `483e20c..e4dd188` khi cần parity UI đầy đủ.

---

## 10. Tiến độ (cập nhật khi làm)

| Phase | Trạng thái | Ghi chú |
|-------|------------|---------|
| Phase 1 — API & Models | ✅ Hoàn thành | roleId, POST role-matches, generate params, DEV2VEC errors |
| Phase 2 — Flow Role Match | ✅ Hoàn thành | create_roadmap_sheet, bỏ hard-code role |
| Phase 3 — UI parity | ✅ Hoàn thành | readiness section, role card, repo card, roadmap meta |
| Phase 4 — Cleanup & test | ✅ Hoàn thành | Tách widget, test parse, roadmap_mobile_widgets gọn hơn |

---

*Tạo: 2026-07-10 — Dev2Vec FE Migration Plan cho Flutter*
