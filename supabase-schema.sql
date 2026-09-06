-- ============================================================
-- QUẢN LÝ HỌC SINH THPT - SUPABASE SCHEMA / GIAI ĐOẠN 3
-- Chạy toàn bộ file này trong Supabase SQL Editor.
-- ============================================================
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null default 'teacher' check (role in ('admin','teacher')),
  created_at timestamptz not null default now()
);

create table if not exists public.academic_years (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  is_current boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  academic_year_id uuid not null references public.academic_years(id) on delete cascade,
  homeroom_teacher_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  unique(name, academic_year_id)
);

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  full_name text not null,
  class_id uuid references public.classes(id) on delete set null,
  gender text check (gender in ('Nam','Nữ')),
  phone text default '',
  date_of_birth date,
  address text default '',
  parent_name text default '',
  parent_phone text default '',
  created_at timestamptz not null default now(),
  unique(code)
);

create table if not exists public.grades (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  subject text not null,
  semester text not null check (semester in ('HK1','HK2')),
  regular numeric[] not null default '{}',
  mid numeric,
  final numeric,
  note text default '',
  updated_at timestamptz not null default now()
);

create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  attendance_date date not null,
  class_id uuid references public.classes(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  status text not null check (status in ('present','excused','unexcused')),
  note text default '',
  unique(attendance_date, student_id)
);

create table if not exists public.awards (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  award_date date not null default current_date,
  type text not null default 'Học tập',
  content text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.violations (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  violation_date date not null default current_date,
  type text not null default 'Nề nếp',
  severity text not null default 'Nhẹ' check (severity in ('Nhẹ','Trung bình','Nặng')),
  content text not null,
  handling text default '',
  created_at timestamptz not null default now()
);

create index if not exists idx_students_class on public.students(class_id);
create index if not exists idx_grades_student on public.grades(student_id);
create index if not exists idx_attendance_student_date on public.attendance(student_id, attendance_date);
create index if not exists idx_awards_student on public.awards(student_id);
create index if not exists idx_violations_student on public.violations(student_id);

alter table public.profiles enable row level security;
alter table public.academic_years enable row level security;
alter table public.classes enable row level security;
alter table public.students enable row level security;
alter table public.grades enable row level security;
alter table public.attendance enable row level security;
alter table public.awards enable row level security;
alter table public.violations enable row level security;

create or replace function public.current_role() returns text
language sql stable security definer set search_path = public
as $$ select coalesce((select role from public.profiles where id = auth.uid()), 'teacher') $$;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public
as $$ select public.current_role() = 'admin' $$;

-- Profile tự tạo khi người dùng đăng ký.
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public
as $$ begin
  insert into public.profiles(id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), 'teacher')
  on conflict (id) do nothing;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users for each row execute procedure public.handle_new_user();

-- Xóa policy cũ để script có thể chạy lại an toàn.
do $$ declare r record; begin
  for r in select schemaname, tablename, policyname from pg_policies where schemaname='public' and tablename in ('profiles','academic_years','classes','students','grades','attendance','awards','violations') loop
    execute format('drop policy if exists %I on %I.%I', r.policyname, r.schemaname, r.tablename);
  end loop;
end $$;

create policy profiles_select on public.profiles for select to authenticated using (id = auth.uid() or public.is_admin());
create policy profiles_update_admin on public.profiles for update to authenticated using (public.is_admin()) with check (public.is_admin());

create policy years_all on public.academic_years for all to authenticated using (true) with check (true);
create policy classes_all on public.classes for all to authenticated using (true) with check (true);
create policy students_all on public.students for all to authenticated using (true) with check (true);
create policy grades_all on public.grades for all to authenticated using (true) with check (true);
create policy attendance_all on public.attendance for all to authenticated using (true) with check (true);
create policy awards_all on public.awards for all to authenticated using (true) with check (true);
create policy violations_all on public.violations for all to authenticated using (true) with check (true);

-- Tạo năm học mặc định nếu chưa có.
insert into public.academic_years(name, is_current)
values ('2026-2027', true)
on conflict (name) do nothing;

-- Sau khi tạo tài khoản giáo viên đầu tiên trong Authentication,
-- có thể nâng tài khoản đó thành admin bằng:
-- update public.profiles set role='admin' where id='UUID_CUA_TAI_KHOAN';
