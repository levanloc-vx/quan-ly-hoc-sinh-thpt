# Quản lý học sinh THPT

Ứng dụng web dành cho giáo viên THPT: học sinh, lớp học, điểm số, điểm danh, khen thưởng, vi phạm và báo cáo.

## Giai đoạn 3
- Đăng nhập giáo viên bằng Supabase Auth.
- Hồ sơ và vai trò `admin` / `teacher`.
- Cơ sở dữ liệu PostgreSQL qua Supabase.
- Đồng bộ dữ liệu trực tuyến; vẫn có bản lưu cục bộ để chạy thử.
- Quản lý năm học.
- Sao lưu JSON và xuất CSV.
- RLS bảo vệ dữ liệu bằng tài khoản đăng nhập.

## Cài đặt Supabase
1. Tạo một Project trên Supabase.
2. Mở **SQL Editor**, chạy toàn bộ `supabase-schema.sql`.
3. Mở **Project Settings → API**, lấy Project URL và anon/public key.
4. Điền hai giá trị vào `config.js` (không dùng `service_role`).
5. Trong Supabase Authentication, tạo tài khoản giáo viên hoặc đăng ký ngay trên ứng dụng.
6. Để cấp quyền quản trị cho tài khoản đầu tiên, lấy UUID người dùng trong Authentication rồi chạy:

```sql
update public.profiles set role='admin' where id='UUID_CUA_TAI_KHOAN';
```

## Chạy trên GitHub Pages
Vào **Settings → Pages → Deploy from branch → main → /(root)**. Sau khi triển khai, mở địa chỉ GitHub Pages của repository.

> Lưu ý: `anon/public key` có thể xuất hiện trong frontend khi RLS được cấu hình đúng. Tuyệt đối không đưa `service_role key` lên GitHub.

## Cấu trúc
- `index.html`: trang ứng dụng.
- `app-v3.js`: giao diện và logic Giai đoạn 3.
- `style.css`: giao diện responsive.
- `config.js`: cấu hình Supabase cục bộ.
- `config.example.js`: mẫu cấu hình.
- `supabase-schema.sql`: cấu trúc CSDL + trigger + RLS.
