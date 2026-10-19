-- =====================================================================
--  edm.frames  |  Supabase setup  (sirf EK baar chalana hai)
--  Supabase dashboard -> SQL Editor -> New query -> ye poora paste -> Run
-- =====================================================================

-- 1) Sirf TUMHARA email edit kar sakta hai.
--    Agar kisi aur email se login karna ho to neeche email badal do.
create or replace function public.is_admin()
returns boolean language sql stable as $$
  select coalesce((auth.jwt() ->> 'email') = 'lodhi.satyam5869@gmail.com', false)
$$;

-- 2) Tables
create table if not exists public.photos (
  id          uuid primary key default gen_random_uuid(),
  url         text not null,
  alt         text not null default '',
  tag         text not null default '',
  sort_order  int  not null default 0,
  hero_big    boolean not null default false,
  hero_small  boolean not null default false,
  story       boolean not null default false,
  created_at  timestamptz not null default now()
);

create table if not exists public.settings (
  key        text primary key,
  value      text not null default '',
  updated_at timestamptz not null default now()
);

-- 3) Security: sab dekh sakte hain, badal sirf admin sakta hai
alter table public.photos   enable row level security;
alter table public.settings enable row level security;

drop policy if exists "photos public read"  on public.photos;
drop policy if exists "photos admin write"  on public.photos;
drop policy if exists "settings public read" on public.settings;
drop policy if exists "settings admin write" on public.settings;

create policy "photos public read"   on public.photos   for select using (true);
create policy "photos admin write"   on public.photos   for all    using (public.is_admin()) with check (public.is_admin());
create policy "settings public read" on public.settings for select using (true);
create policy "settings admin write" on public.settings for all    using (public.is_admin()) with check (public.is_admin());

-- 4) Photos ka storage (nayi upload ki hui photos yahan jaati hain)
insert into storage.buckets (id, name, public)
values ('site-images', 'site-images', true)
on conflict (id) do update set public = true;

drop policy if exists "site-images admin insert" on storage.objects;
drop policy if exists "site-images admin update" on storage.objects;
drop policy if exists "site-images admin delete" on storage.objects;
drop policy if exists "site-images admin select" on storage.objects;

create policy "site-images admin select" on storage.objects for select to authenticated
  using (bucket_id = 'site-images' and public.is_admin());
create policy "site-images admin insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'site-images' and public.is_admin());
create policy "site-images admin update" on storage.objects for update to authenticated
  using (bucket_id = 'site-images' and public.is_admin());
create policy "site-images admin delete" on storage.objects for delete to authenticated
  using (bucket_id = 'site-images' and public.is_admin());

-- 5) Abhi wali 19 photos pehle se daal do (sirf tab jab table khali ho)
insert into public.photos (url, alt, tag, sort_order, hero_big, hero_small, story)
select * from (values
  ('images/p01.jpg','Radio on a log, Hindi caption','Street',1,true,false,false),
  ('images/p02.jpg','Temple tower with flags','Heritage',2,false,false,true),
  ('images/p03.jpg','Orange and white temple domes','Heritage',3,true,false,false),
  ('images/p04.jpg','Rain and sunset on a village street','Rain',4,false,true,true),
  ('images/p05.jpg','Wet rose leaves','Rain',5,false,false,false),
  ('images/p06.jpg','Man walking with an umbrella','Rain',6,false,false,true),
  ('images/p07.jpg','Child smiling through a box hole','Street',7,false,false,true),
  ('images/p08.jpg','Old gateway at dusk','Heritage',8,false,false,false),
  ('images/p09.jpg','Window in a mud wall','Heritage',9,false,false,true),
  ('images/p10.jpg','Bare tree at sunset','Skies',10,false,false,true),
  ('images/p11.jpg','Tower against the dusk','Skies',11,false,true,true),
  ('images/p12.jpg','Temple domes and sky','Heritage',12,false,false,false),
  ('images/p13.jpg','Single cloud','Skies',13,false,true,true),
  ('images/p14.jpg','Old Bajaj scooter','Street',14,true,false,false),
  ('images/p15.jpg','Museum wall of old photographs','Heritage',15,false,true,false),
  ('images/p16.jpg','Musafir Cafe book in hand','Street',16,false,false,true),
  ('images/p17.jpg','Sunset over the station','Skies',17,false,true,false),
  ('images/p18.jpg','Ambassador car under trees','Street',18,false,false,true),
  ('images/p19.jpg','Old mansion at night','Heritage',19,true,false,false)
) as v(url, alt, tag, sort_order, hero_big, hero_small, story)
where not exists (select 1 from public.photos);
