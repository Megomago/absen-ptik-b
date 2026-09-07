-- ABSEN PTIK B — full setup (jalankan sekali di Supabase > SQL Editor > New Query > Run)
-- Mode: sync global tanpa login (anon key). Idempotent: aman di-Run ulang.

-- 1) Tabel
create table if not exists students (
  id text primary key,
  nim text not null,
  nama text not null,
  jk text
);
create table if not exists courses (
  name text primary key,
  meetings int not null default 16
);
create table if not exists attendance (
  course text not null references courses(name) on delete cascade,
  student_id text not null references students(id) on delete cascade,
  meeting int not null,
  status text not null check (status in ('H','S','A')),
  primary key (course, student_id, meeting)
);

-- index biar realtime + render cepat
create index if not exists idx_att_course on attendance(course);
create index if not exists idx_att_student on attendance(student_id);

-- 2) RLS + policy terbuka (tanpa login)
alter table students enable row level security;
alter table courses enable row level security;
alter table attendance enable row level security;

drop policy if exists "open all" on students;
drop policy if exists "open all" on courses;
drop policy if exists "open all" on attendance;

create policy "open all" on students for all using (true) with check (true);
create policy "open all" on courses for all using (true) with check (true);
create policy "open all" on attendance for all using (true) with check (true);

-- 3) Realtime full (attendance + students + courses)
-- kalau sudah ditambahkan sebelumnya, block ini tidak error
do $$
begin
  begin alter publication supabase_realtime add table students; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table courses; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table attendance; exception when duplicate_object then null; end;
end $$;
