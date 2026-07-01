-- ============================================================
-- مكتب الهاشمي للعقار — إعداد قاعدة البيانات
-- انسخ هذا الملف بالكامل والصقه في Supabase Dashboard > SQL Editor
-- ثم اضغط Run لتنفيذه دفعة واحدة
-- ============================================================

-- 1) جدول العقارات
create table if not exists hashimi_properties (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  mahalla text not null,
  zuqaq text not null,
  area numeric,
  facade numeric,
  nizal text,
  listing_type text not null check (listing_type in ('بيع','ايجار')),
  status text not null default 'متاح' check (status in ('متاح','تم البيع','تم الايجار')),
  notes text,
  images text[] not null default '{}'
);

-- تحديث updated_at تلقائياً مع كل تعديل
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_hashimi_properties_updated_at on hashimi_properties;
create trigger trg_hashimi_properties_updated_at
before update on hashimi_properties
for each row execute function set_updated_at();

-- 2) تفعيل حماية الصفوف (Row Level Security)
alter table hashimi_properties enable row level security;

-- السماح لأي زائر بقراءة العقارات (صفحة الزوار)
drop policy if exists "public_read_properties" on hashimi_properties;
create policy "public_read_properties"
on hashimi_properties for select
to anon, authenticated
using (true);

-- السماح فقط للأدمن المسجل دخوله بالإضافة والتعديل والحذف
drop policy if exists "admin_insert_properties" on hashimi_properties;
create policy "admin_insert_properties"
on hashimi_properties for insert
to authenticated
with check (true);

drop policy if exists "admin_update_properties" on hashimi_properties;
create policy "admin_update_properties"
on hashimi_properties for update
to authenticated
using (true)
with check (true);

drop policy if exists "admin_delete_properties" on hashimi_properties;
create policy "admin_delete_properties"
on hashimi_properties for delete
to authenticated
using (true);

-- ============================================================
-- 3) تخزين الصور (Storage)
-- ============================================================
-- أنشئ Bucket باسم: hashimi-property-images
-- من القائمة الجانبية Storage > New bucket
-- فعّل خيار "Public bucket" عند الإنشاء (لضمان ظهور الصور للزوار)
--
-- بعدها نفّذ سياسات الوصول التالية:

drop policy if exists "public_read_property_images" on storage.objects;
create policy "public_read_property_images"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'hashimi-property-images');

drop policy if exists "admin_upload_property_images" on storage.objects;
create policy "admin_upload_property_images"
on storage.objects for insert
to authenticated
with check (bucket_id = 'hashimi-property-images');

drop policy if exists "admin_update_property_images" on storage.objects;
create policy "admin_update_property_images"
on storage.objects for update
to authenticated
using (bucket_id = 'hashimi-property-images');

drop policy if exists "admin_delete_property_images" on storage.objects;
create policy "admin_delete_property_images"
on storage.objects for delete
to authenticated
using (bucket_id = 'hashimi-property-images');

-- ============================================================
-- انتهى. الخطوة التالية: إنشاء مستخدم الأدمن من Authentication > Users
-- راجع ملف "دليل التنصيب.md" للتفاصيل الكاملة خطوة بخطوة
-- ============================================================
