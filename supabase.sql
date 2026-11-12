-- Estudos Bacen: tabelas e segurança. Cole tudo no SQL Editor do Supabase e clique em Run.

create table if not exists public.horas (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  data date not null,
  materia smallint not null check (materia between 0 and 10),
  tipo text not null,
  minutos integer not null check (minutos > 0)
);

create table if not exists public.questoes (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  data date not null,
  materia smallint not null check (materia between 0 and 10),
  conteudo text not null default '',
  feitas integer not null check (feitas > 0),
  acertos integer not null check (acertos >= 0 and acertos <= feitas),
  obs text not null default ''
);

create table if not exists public.topicos_feitos (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  chave text not null,
  primary key (user_id, chave)
);

create index if not exists horas_user_data on public.horas (user_id, data);
create index if not exists questoes_user_data on public.questoes (user_id, data);

-- Segurança: cada pessoa logada só enxerga e altera os próprios dados.
alter table public.horas enable row level security;
alter table public.questoes enable row level security;
alter table public.topicos_feitos enable row level security;

drop policy if exists "somente o dono" on public.horas;
create policy "somente o dono" on public.horas for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists "somente o dono" on public.questoes;
create policy "somente o dono" on public.questoes for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists "somente o dono" on public.topicos_feitos;
create policy "somente o dono" on public.topicos_feitos for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
