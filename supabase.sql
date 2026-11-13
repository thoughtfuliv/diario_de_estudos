-- Estudos Bacen: aba de Materiais (PDFs + anotações à caneta).
-- Cole tudo no SQL Editor do Supabase e clique em Run. Pode rodar mais de uma vez sem problema.

-- 1) Lista de PDFs, organizada por matéria
create table if not exists public.materiais (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  materia smallint not null check (materia between 0 and 10),
  nome text not null,
  caminho text not null,
  tamanho bigint not null default 0,
  criado_em timestamptz not null default now()
);

-- 2) Rabiscos: uma linha por página de cada PDF (os traços ficam em JSON)
create table if not exists public.anotacoes (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  material_id bigint not null references public.materiais(id) on delete cascade,
  pagina integer not null check (pagina > 0),
  tracos jsonb not null default '[]'::jsonb,
  atualizado_em timestamptz not null default now(),
  primary key (material_id, pagina)
);

-- Ordem dos PDFs dentro de cada matéria (para reorganizar na interface)
alter table public.materiais add column if not exists ordem integer not null default 0;

create index if not exists materiais_user_materia on public.materiais (user_id, materia);
create index if not exists anotacoes_user on public.anotacoes (user_id);

-- 3) Segurança das tabelas: cada pessoa só enxerga e altera os próprios dados
alter table public.materiais enable row level security;
alter table public.anotacoes enable row level security;

drop policy if exists "somente o dono" on public.materiais;
create policy "somente o dono" on public.materiais for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists "somente o dono" on public.anotacoes;
create policy "somente o dono" on public.anotacoes for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- 4) Armazenamento dos arquivos: bucket privado, só PDF, até 50 MB por arquivo
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('materiais', 'materiais', false, 52428800, array['application/pdf'])
on conflict (id) do nothing;

-- Cada pessoa só acessa a própria pasta (a primeira pasta do caminho é o id do usuário)
drop policy if exists "materiais: somente o dono" on storage.objects;
create policy "materiais: somente o dono" on storage.objects for all to authenticated
  using (bucket_id = 'materiais' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'materiais' and (storage.foldername(name))[1] = (select auth.uid())::text);