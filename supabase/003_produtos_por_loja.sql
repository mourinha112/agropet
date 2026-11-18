-- =====================================================================
-- AGROPET - cada loja com os PROPRIOS produtos
--
-- Rode este arquivo INTEIRO no Supabase (SQL Editor > New query > Run),
-- DEPOIS do 002_multilojas.sql. Pode rodar de novo sem duplicar nada.
--
-- O que faz:
--   * products ganha loja_id. Os produtos de hoje ficam na loja 1 (01ST).
--   * Copia cada produto da loja 1 para a 02MG e para a Santa Cruz, com o
--     mesmo cadastro e preco. Depois disso cada loja muda o seu preco sem
--     mexer nas outras.
--   * O estoque que as lojas 2 e 3 ja lancaram (tabela estoque_loja) vai
--     para a copia do produto daquela loja. Sem lancamento = estoque zero.
--   * A loja online continua mostrando os produtos da loja 1.
-- =====================================================================

alter table public.products add column if not exists loja_id   bigint not null default 1 references public.lojas(id);
alter table public.products add column if not exists origem_id bigint;  -- de qual produto da loja 1 veio a copia
create index if not exists products_loja_idx on public.products (loja_id);
create unique index if not exists products_loja_origem_uniq on public.products (loja_id, origem_id) where origem_id is not null;

do $$
declare
  colunas text;
  loja    bigint;
begin
  -- todas as colunas do produto, menos as que a copia define por conta propria
  select string_agg(quote_ident(column_name), ', ' order by ordinal_position)
    into colunas
    from information_schema.columns
   where table_schema = 'public' and table_name = 'products'
     and column_name not in ('id', 'loja_id', 'origem_id', 'estoque_kg', 'estoque_unidade', 'created_at', 'updated_at');

  foreach loja in array array[2, 3]::bigint[]
  loop
    execute format($f$
      insert into public.products (%1$s, loja_id, origem_id, estoque_kg, estoque_unidade)
      select %2$s, %3$s, p.id,
             coalesce(e.estoque_kg, 0), coalesce(e.estoque_unidade, 0)
        from public.products p
        left join public.estoque_loja e on e.product_id = p.id and e.loja_id = %3$s
       where p.loja_id = 1
         and p.ativo = 1
         and not exists (
           select 1 from public.products c where c.loja_id = %3$s and c.origem_id = p.id
         )
    $f$, colunas, 'p.' || replace(colunas, ', ', ', p.'), loja);
  end loop;
end $$;

-- Movimentacoes de estoque que as lojas 2 e 3 ja fizeram passam a apontar
-- para a copia do produto delas.
update public.stock_movements m
   set product_id = c.id
  from public.products c
 where c.origem_id = m.product_id
   and c.loja_id   = m.loja_id
   and m.loja_id  <> 1;

-- Itens de vendas ja feitas nas lojas 2 e 3 idem (para relatorio e custo).
update public.sale_items i
   set product_id = c.id
  from public.sales s, public.products c
 where s.id = i.sale_id
   and s.loja_id <> 1
   and c.origem_id = i.product_id
   and c.loja_id   = s.loja_id;

-- Conferencia: quantos produtos ativos cada loja tem
select l.codigo as loja, count(p.id) as produtos
  from public.lojas l
  left join public.products p on p.loja_id = l.id and p.ativo = 1
 group by l.id, l.codigo
 order by l.id;
