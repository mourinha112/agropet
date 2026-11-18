-- =====================================================================
-- AGROPET - varias lojas no mesmo sistema
--
-- Rode este arquivo INTEIRO no Supabase (SQL Editor > New query > Run),
-- DEPOIS do 001_agropet_completo.sql. Pode rodar de novo sem estragar nada.
--
-- O que muda:
--   * Produtos (cadastro, precos, fotos) continuam UMA tabela so, igual
--     para todas as lojas.
--   * Vendas, caixa, clientes, despesas, custos fixos, movimentacoes e
--     ESTOQUE passam a ser separados por loja.
--   * Tudo o que ja existe fica na loja 1 (01ST).
--   * A loja online (site + painel de pedidos) continua sendo da loja 1.
--
-- Logins:
--   01ST  / Agro1234     -> loja 1 (a de hoje)
--   02MG  / AgroMg1234   -> loja 2
--   03ST  / Agrost1234   -> loja 3 (Santa Cruz)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Lojas
-- ---------------------------------------------------------------------
create table if not exists public.lojas (
  id         bigint primary key,
  codigo     text not null unique,
  nome       text not null,
  created_at timestamptz not null default now()
);

insert into public.lojas (id, codigo, nome) values
  (1, '01ST', 'Agropet 01ST'),
  (2, '02MG', 'Agropet 02MG'),
  (3, '03ST', 'Agropet Santa Cruz')
on conflict (id) do update
  set codigo = excluded.codigo,
      nome   = excluded.nome;

-- ---------------------------------------------------------------------
-- 2. Coluna loja_id nas tabelas que passam a ser de cada loja.
--    O que ja existe vai para a loja 1 (default 1).
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array[
    'users','clients','sales','stock_movements','fixed_costs',
    'expenses','cash_sessions','orders'
  ]
  loop
    execute format(
      'alter table public.%I add column if not exists loja_id bigint not null default 1 references public.lojas(id)', t);
    execute format(
      'create index if not exists %I on public.%I (loja_id)', t || '_loja_idx', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 3. Estoque das lojas 2 e 3.
--    A loja 1 continua usando estoque_kg / estoque_unidade da tabela
--    products (e o estoque que a loja online mostra). As outras lojas
--    guardam o proprio estoque aqui, um registro por produto.
--    Produto sem registro aqui = estoque zero naquela loja.
-- ---------------------------------------------------------------------
create table if not exists public.estoque_loja (
  product_id      bigint  not null references public.products(id) on delete cascade,
  loja_id         bigint  not null references public.lojas(id),
  estoque_kg      numeric not null default 0,
  estoque_unidade integer not null default 0,
  updated_at      timestamptz not null default now(),
  primary key (product_id, loja_id)
);

create index if not exists estoque_loja_loja_idx on public.estoque_loja (loja_id);

-- Mesma postura de acesso das outras tabelas (ver 001_agropet_completo.sql)
alter table public.lojas        enable row level security;
alter table public.estoque_loja enable row level security;
drop policy if exists lojas_tudo        on public.lojas;
drop policy if exists estoque_loja_tudo on public.estoque_loja;
create policy lojas_tudo        on public.lojas        for all to anon, authenticated using (true) with check (true);
create policy estoque_loja_tudo on public.estoque_loja for all to anon, authenticated using (true) with check (true);

-- ---------------------------------------------------------------------
-- 4. Logins (senha guardada como sha256 em hex)
-- ---------------------------------------------------------------------
update public.users set loja_id = 1 where login = '01ST';

insert into public.users (nome, login, senha_hash, role, loja_id) values
  ('Agropet 02MG',       '02MG', 'b20a81db83c99b4d2f0c960c65a9126e2e9c0cfee6b906637f35c4c8ab38e2e8', 'admin', 2),
  ('Agropet Santa Cruz', '03ST', 'fb4731f641f514f5a60a2d046ffcb6ceea2723b11eafe4fff82ccf4f632759bd', 'admin', 3)
on conflict (login) do update
  set nome       = excluded.nome,
      senha_hash = excluded.senha_hash,
      role       = excluded.role,
      loja_id    = excluded.loja_id;

-- Conferencia: deve listar os 3 logins, cada um com a sua loja
select u.login, u.nome, l.codigo as loja, l.nome as nome_loja
from public.users u
join public.lojas l on l.id = u.loja_id
order by l.id;
