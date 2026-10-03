-- Fresh lesson_chunks for INT6137 L04.
-- Paste this whole file into the SQL Editor. Click in the editor so nothing
-- is highlighted, then Run.
-- This drops the previous table and the previous match_lesson_chunks.
-- Rows do not survive. Afterwards, click 写入三句 on the demo page.
-- Success looks like: Success. No rows returned.

create extension if not exists vector with schema extensions;

drop function if exists public.match_lesson_chunks(extensions.vector, int);
drop table if exists public.lesson_chunks;

create table public.lesson_chunks (
  id text primary key,
  content text not null,
  source text not null,
  embedding extensions.vector(1024) not null
);

alter table public.lesson_chunks enable row level security;

create policy lesson_chunks_select
  on public.lesson_chunks for select
  to anon, authenticated
  using (true);

create policy lesson_chunks_insert
  on public.lesson_chunks for insert
  to anon, authenticated
  with check (true);

create policy lesson_chunks_update
  on public.lesson_chunks for update
  to anon, authenticated
  using (true)
  with check (true);

create policy lesson_chunks_delete
  on public.lesson_chunks for delete
  to anon, authenticated
  using (true);

create index lesson_chunks_embedding_hnsw
  on public.lesson_chunks
  using hnsw (embedding extensions.vector_cosine_ops);

create function public.match_lesson_chunks (
  query_embedding extensions.vector(1024),
  match_count int default 3
)
returns table (
  id text,
  content text,
  source text,
  similarity float
)
language sql
stable
as $$
  select
    lesson_chunks.id,
    lesson_chunks.content,
    lesson_chunks.source,
    1 - (lesson_chunks.embedding <=> query_embedding) as similarity
  from public.lesson_chunks
  order by lesson_chunks.embedding <=> query_embedding
  limit least(match_count, 10);
$$;

grant execute on function public.match_lesson_chunks(extensions.vector, int) to anon, authenticated;

grant select, insert, update, delete on public.lesson_chunks to anon, authenticated;

notify pgrst, 'reload schema';
