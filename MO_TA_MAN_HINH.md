# Hướng dẫn từng trang — GitAnalyzer AI

> Bạn chưa biết gì về app này cũng đọc được. Tài liệu viết như đang kể cho bạn nghe: app này làm gì, từng trang có gì, bấm chỗ nào thì ra chỗ nào.

**App này là gì?**  
GitAnalyzer AI giúp bạn xem lại các dự án code trên GitHub, chấm điểm xem dự án ổn chưa, gợi ý nên học thêm gì và đi hướng nghề nào. Có cả chỗ chat hỏi AI như hỏi mentor vậy.

**Kết nối server:** App gọi API backend (mặc định BE deploy trên Render). Đăng nhập bằng **email + mật khẩu** hoặc **Đăng ký** tài khoản mới. Nút Google/GitHub cần cấu hình OAuth riêng trên điện thoại.

---

## Mục lục các trang

| STT | Tên trang | Ghi chú |
|-----|-----------|---------|
| 1 | Đăng nhập | |
| 2 | Đăng ký | |
| 3 | Khung menu chính | Thanh trên + dưới |
| 4 | Trang chủ | Dashboard |
| 5 | Giới thiệu | |
| 6 | Danh sách Repos | |
| 7 | Chi tiết Repo | |
| 8 | Kết quả phân tích | |
| 9 | Kết nối GitHub | |
| 10 | Chat AI Mentor | |
| 11 | Danh sách lộ trình | |
| 12 | Tạo lộ trình AI | |
| 13 | Chi tiết lộ trình | |
| 14 | Tiến độ học tập | |
| 15 | Thông báo | |
| **16** | **Profile / Hồ sơ của tôi** | **Trang riêng — xem & sửa hồ sơ sinh viên** |
| 17 | Cài đặt | Mật khẩu, giao diện, đăng xuất |
| 18 | Không tìm thấy | Lỗi 404 |
| 19 | Quản trị (Admin) | Chỉ tài khoản admin |

---

## 1. Trang Đăng nhập

### Để làm gì?
Cửa vào app — đăng nhập đúng mới xem được dự án GitHub và thông tin của mình.

### Khi vào trang này, bạn làm gì?
- Lần đầu mở app → tự vào trang này.
- Gõ **email** và **mật khẩu**, bấm **Đăng nhập**.
- Chưa có tài khoản? Bấm **Đăng ký**.
- Có thể thử **GitHub** / **Google** (cần cấu hình thêm trên Android).
- **Quên mật khẩu?** — hiện đang phát triển, liên hệ quản trị.

App kiểm tra email, mật khẩu có đúng với tài khoản trên server không.

**Đúng** → vào trang chủ.  
**Sai** → báo lỗi, ví dụ *"Email hoặc mật khẩu không đúng"*.

### Xong rồi thì sao?
- Thành công → trang chủ.
- Thất bại → ở lại, sửa và thử lại.

---

## 2. Trang Đăng ký

### Để làm gì?
Tạo tài khoản mới trên server.

### Khi vào trang này, bạn làm gì?
- Điền **họ tên**, **email**, **mật khẩu**, **gõ lại mật khẩu**.
- Tick **Điều khoản** và **Chính sách bảo mật**.
- Bấm **Tạo tài khoản**.
- Có thể đăng ký nhanh GitHub/Google (nếu đã cấu hình).

**Ổn** → vào trang chủ.  
**Chưa ổn** → báo lỗi cụ thể.

Đã có tài khoản? Bấm **Đăng nhập** quay lại.

---

## 3. Khung chính của app (menu trên & dưới)

### Để làm gì?
Khung bao quanh mọi trang sau khi đăng nhập — giúp nhảy giữa các chức năng.

### Bạn sẽ thấy gì?

**Phía trên (AppBar):**
| Nút | Vào đâu |
|-----|---------|
| Logo **GitAnalyzer** | Trang chủ |
| **Ảnh đại diện** | Hồ sơ của tôi |
| **Bánh răng** | Cài đặt |
| **Chuông** | Thông báo |

**Phía dưới — 4 tab + Thêm:**
| Nút | Vào đâu |
|-----|---------|
| **Trang chủ** | Tổng quan |
| **Repos** | Danh sách dự án GitHub |
| **Hồ sơ** | Thông tin cá nhân & sinh viên |
| **AI Mentor** | Chat hỏi AI |
| **Thêm** | Menu phụ (mở từ dưới lên) |

**Menu Thêm gồm:**
- Lộ trình
- Cài đặt
- Giới thiệu
- Tiến độ
- GitHub
- Thông báo

Chạm tab hoặc menu là chuyển trang. **Đăng xuất** nằm trong **Cài đặt**.

---

## 4. Trang chủ (Tổng quan)

### Để làm gì?
Bảng tin cá nhân — mở app là biết tình hình GitHub và việc cần làm tiếp.

### Khi vào trang này, bạn thấy gì?
- Dòng chào + **ảnh đại diện** — **chạm vào** để vào **Hồ sơ**.
- **4 ô số:** số dự án, đã phân tích, GitHub đã kết nối chưa, điểm tổng.
- **Phân tích gần đây** — chạm dự án → xem kết quả chấm điểm.
- **Thao tác nhanh:**
  - Kết nối GitHub
  - Đồng bộ / phân tích repository
  - Hỏi AI Mentor
  - Cài đặt tài khoản

Chưa có dự án? App nhắc kết nối GitHub và đồng bộ trước.

---

## 5. Trang Giới thiệu

### Để làm gì?
Giải thích app giúp gì cho người mới.

### Nội dung chính
- App giúp xem dự án GitHub, chấm điểm, gợi ý học và nghề.
- Nút **Kết nối GitHub**, **Xem repositories**.
- Ví dụ phân tích gần đây.
- 3 tính năng: chấm điểm, lộ trình, chat AI.

Vào từ menu **Thêm → Giới thiệu**.

---

## 6. Trang Danh sách dự án (Repositories)

### Để làm gì?
Xem các dự án GitHub đã đồng bộ — chọn dự án để chấm điểm.

> **Repository** = một dự án code trên GitHub.

### Khi vào trang này, bạn làm gì?
- Bấm **Đồng bộ** lấy danh sách mới từ GitHub.
- Gõ **Tìm repository** để lọc.

Mỗi dự án hiện: tên, mô tả, ngôn ngữ, star/fork, đã phân tích chưa.

Với từng dự án:
- Chạm **tên** → chi tiết
- **Phân tích** / **Phân tích lại** → AI chấm điểm
- **Xem phân tích** → kết quả cũ
- **Mở GitHub** → mở trên web

---

## 7. Trang Chi tiết một dự án

### Để làm gì?
Xem kỹ **một** dự án trước khi chấm điểm.

### Thao tác
- Đọc thông tin dự án.
- **Phân tích repository** — bắt đầu chấm
- **Xem kết quả phân tích** — nếu đã chấm
- **Mở trên GitHub**
- **Quay lại** → danh sách

---

## 8. Trang Kết quả chấm điểm

### Để làm gì?
Bảng điểm AI — dự án tốt/yếu chỗ nào, nên sửa gì.

### Bạn thấy gì?
- **Điểm tổng** (0–100)
- Loại dự án, công nghệ dùng
- Điểm chi tiết: kiến trúc, hoàn thiện, commit, tài liệu, quy ước code
- Điểm mạnh, điểm yếu, đề xuất
- Hướng nghề nghiệp (nếu có)
- **Hỏi AI Mentor** → sang chat

Chưa chấm? Nút **Chạy phân tích**.

---

## 9. Trang Kết nối GitHub

### Để làm gì?
Liên kết GitHub với app để đồng bộ và chấm dự án.

### Khi vào trang này
**Chưa kết nối:**
- Bấm **Kết nối GitHub** → đăng nhập GitHub, đồng ý quyền → quay lại app.

**Đã kết nối:**
- Tên GitHub (@tenban)
- **Làm mới**, **Ngắt kết nối**
- **Tải cache** / **Đồng bộ repositories**
- **Mở repositories**
- Chạm tên dự án → chi tiết

Vào từ: Trang chủ, Cài đặt, menu **Thêm → GitHub**.

---

## 10. Trang Chat AI Mentor

### Để làm gì?
Hỏi đáp với AI về dự án, học gì tiếp, hướng nghề, portfolio…

### Khi vào trang này
- Tab **AI Mentor** ở dưới, hoặc từ kết quả phân tích.

Gợi ý câu hỏi sẵn, hoặc tự gõ → **gửi**.

Icon **lịch sử** (góc trên):
- Xem chat cũ
- **Tạo cuộc trò chuyện mới**
- Tóm tắt: GitHub, số repo, số lần phân tích

---

## 11. Trang Danh sách lộ trình học

### Để làm gì?
Chọn kế hoạch học có sẵn hoặc để AI tạo riêng.

> **Lộ trình** = các bước nên học (Java → Spring → project…).

### Khi vào trang này
- Vào từ menu **Thêm → Lộ trình**.
- **Tạo roadmap AI** — AI gợi ý lộ trình cá nhân.
- Tìm kiếm, lọc **Danh mục** (Backend, Frontend…).

Hai nhóm: **Nổi bật** và **Đề xuất bởi AI**.  
Chạm lộ trình → chi tiết từng bài.

---

## 12. Trang Tạo lộ trình bằng AI

### Để làm gì?
AI phân tích GitHub → gợi ý mạnh/yếu/thiếu và lộ trình phù hợp.

### Nội dung
- Độ tin cậy, tóm tắt, hướng đề xuất
- Điểm mạnh, điểm yếu, kỹ năng thiếu
- **Tạo lại** hoặc **Xem roadmap đề xuất**

---

## 13. Trang Chi tiết lộ trình

### Để làm gì?
Xem từng chương/bài, đánh dấu đã học xong.

### Thao tác
- Thanh **% hoàn thành**
- Từng **bài**: chưa làm / đang làm / xong
- **Đánh dấu hoàn thành**
- **Quay lại** danh sách
- Có thể **Lưu trữ** lộ trình (archive)

---

## 14. Trang Tiến độ học tập

### Để làm gì?
Theo dõi tiến bộ theo thời gian — XP, kỹ năng, biểu đồ.

### Vào từ
- Menu **Thêm → Tiến độ**
- **Cài đặt → Tiến độ học tập**

### Nội dung
- 4 số nhanh: tăng trưởng, mục tiêu, kỹ năng cải thiện, giờ học
- Level, XP, streak, bài hoàn thành
- Thanh từng kỹ năng
- Biểu đồ điểm theo thời gian

Chủ yếu để **xem**, không cần nhập.

---

## 15. Trang Thông báo

### Để làm gì?
Nhắc chấm GitHub, học lộ trình, cập nhật dự án…

### Thao tác
- Icon **chuông** trên AppBar, hoặc menu **Thông báo**
- Số **chưa đọc**
- **Chỉ hiện chưa đọc**
- **Đánh dấu đã đọc**, **Xóa**

---

## 16. Trang Profile (Hồ sơ của tôi)

> **Đường dẫn trong app:** `/profile`  
> **Khác với Cài đặt:** Profile = xem/sửa thông tin cá nhân & sinh viên. Cài đặt = đổi mật khẩu, theme, đăng xuất.

### Để làm gì?
Trang **Profile** giúp bạn:
- Xem ảnh đại diện, tên, email, trạng thái GitHub
- Xem hồ sơ sinh viên (trường, ngành, năm, hướng nghề, kỹ năng)
- **Chỉnh sửa** và **lưu** hồ sơ lên server (`GET/PATCH /api/profiles/me`)

Đây là trang **riêng**, không gộp chung Cài đặt nữa.

### Vào Profile bằng cách nào? (4 cách)
| Cách | Bấm ở đâu |
|------|-----------|
| 1 | Tab **Hồ sơ** — thanh menu dưới cùng (cạnh Repos, AI Mentor) |
| 2 | **Ảnh đại diện** — góc phải AppBar (trên cùng) |
| 3 | Dòng **"Chào mừng, …"** — trên Trang chủ |
| 4 | **Cài đặt** → thẻ "Xem và chỉnh sửa hồ sơ sinh viên" |

### Khi mở Profile — chế độ XEM (mặc định)

**Phần đầu — thẻ cá nhân:**
- Ảnh đại diện (lớn, giữa màn hình)
- Họ tên
- Email
- Badge **GitHub đã kết nối** / **chưa kết nối**
- Badge **@github_username** (nếu có)

**Thẻ "Thông tin học tập":**
| Trường | Ví dụ |
|--------|-------|
| Trường | Đại học ABC |
| Ngành | Công nghệ thông tin |
| Năm học | Năm 3 |
| Hướng nghề nghiệp | Backend Developer |

Chưa điền → hiện dấu **—**

**Thẻ "Kỹ năng hiện có":**
- Danh sách kỹ năng dạng badge (Java, React, SQL…)
- Chưa có → *"Chưa cập nhật kỹ năng"*

**Thẻ "Tài khoản":**
- Email
- Ngày tham gia (kiểu "3 ngày trước")
- GitHub username hoặc *"Chưa liên kết"*

Góc trên có nút **Chỉnh sửa**.

### Khi bấm Chỉnh sửa — chế độ SỬA

Form hiện các ô:
- **Họ tên**
- **Trường**
- **Ngành**
- **Hướng nghề nghiệp**
- **Kỹ năng** — gõ cách nhau bằng dấu phẩy, ví dụ: `Java, React, SQL`
- **GitHub username**
- **Năm học** — chọn Năm 1 → Năm 5

Hai nút:
- **Lưu hồ sơ** — gửi lên server, quay về chế độ xem, báo *"Đã lưu hồ sơ"*
- **Hủy** (nút Chỉnh sửa đổi thành Hủy khi đang sửa) — bỏ thay đổi, quay lại dữ liệu cũ

### Bạn cần chuẩn bị gì?
- Đã đăng nhập
- Thông tin trường/ngành/kỹ năng muốn cập nhật (nếu sửa)

### Xong rồi thì sao?
- Hồ sơ được lưu trên server → AI lộ trình & mentor có thể dùng thông tin này gợi ý chính xác hơn
- Quay lại các trang khác bằng tab menu hoặc nút back hệ thống

---

## 17. Trang Cài đặt

### Để làm gì?
Bảo mật, giao diện, shortcut — **không** chỉnh hồ sơ sinh viên ở đây nữa (đã chuyển sang **Hồ sơ**).

### Vào từ
- Icon **bánh răng** AppBar
- Menu **Thêm → Cài đặt**

### Nội dung
**Thẻ hồ sơ (shortcut)** — chạm → sang trang Hồ sơ.

**Giao diện** — chọn **Light** hoặc **Dark**.

**Đổi mật khẩu:**
- Mật khẩu hiện tại, mới, xác nhận
- **Đổi mật khẩu**

**Các nút:**
- Tiến độ học tập
- Kết nối GitHub
- **Đăng xuất** → về trang đăng nhập

---

## 18. Trang Không tìm thấy

### Để làm gì?
Bạn vào URL/route không tồn tại.

Hiện thông báo lỗi + nút **Về Dashboard**.

---

## 19. Khu vực Quản trị (Admin)

> Chỉ tài khoản **admin** mới vào được. Sinh viên thường không thấy.

### Các trang admin
| Trang | Làm gì |
|-------|--------|
| **Tổng quan admin** | Thống kê hệ thống |
| **Người dùng** | Xem danh sách, chi tiết, đổi role/trạng thái |
| **Báo cáo** | Xem báo cáo người dùng gửi, cập nhật trạng thái |
| **Repositories** | Xem repo trên hệ thống |
| **Phân tích** | Xem snapshot phân tích |
| **AI Feedback** | Xem feedback AI |
| **Roadmaps** | Quản lý lộ trình, đổi trạng thái |

Vào sai quyền → trang **Không có quyền truy cập**.

---

## Dùng app từ đầu — gợi ý nhanh

```
1. Mở app
2. Đăng ký (lần đầu) hoặc Đăng nhập (email + mật khẩu)
3. Vào Hồ sơ → điền thông tin sinh viên → Lưu
4. Trang chủ → Kết nối GitHub
5. Repos → Đồng bộ → Chọn dự án → Phân tích
6. Đọc kết quả → Hỏi AI / Tạo lộ trình (menu Thêm)
7. Theo dõi Tiến độ, Thông báo; Cài đặt đổi mật khẩu / giao diện
```

---

## Bản đồ điều hướng nhanh

```
Đăng nhập / Đăng ký
        ↓
   [Khung chính]
   ┌─────────────────────────────────────┐
   │ AppBar: Hồ sơ | Cài đặt | Thông báo │
   ├─────────────────────────────────────┤
   │ Trang chủ | Repos | Hồ sơ | AI | Thêm│
   └─────────────────────────────────────┘
        Thêm → Lộ trình, Cài đặt, Giới thiệu,
               Tiến độ, GitHub, Thông báo
```

---

*Viết cho người dùng GitAnalyzer AI — PRM393_MBA. Cập nhật theo app Flutter hiện tại.*
