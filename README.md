# Agropet

Loja online, painel da loja e sistema de gestão (PDV) num único deploy.
Tema: verde escuro e dourado, tirados da logomarca.

| Endereço | O que é | Login |
|---|---|---|
| `/` | Catálogo público: o cliente monta o pedido e manda pelo WhatsApp | não |
| `/painel` | Painel da loja: pedidos online, vitrine, kits, resumo, configurações | sim |
| `/admin` | Sistema completo: PDV, produtos, estoque, caixa, clientes, despesas, relatórios, marketing | sim |

Acesso do administrador: login `01ST`, senha `Agro1234` (criado pelo SQL abaixo; troque depois).

---

## Subir do zero (uns 15 minutos)

### 1. Supabase

1. Em [supabase.com](https://supabase.com), **New project**. Guarde a senha do banco.
2. **SQL Editor → New query** → cole o conteúdo inteiro de
   `supabase/001_agropet_completo.sql` → **Run**.
   Cria todas as tabelas, o balde das fotos, as configurações e o usuário admin.
   O banco começa vazio: sem produtos, vendas ou clientes.
3. **Project Settings → API**: anote a **Project URL** e a chave **anon public**.

### 2. Vercel

1. **Add New → Project**, escolha o repositório `mourinha112/agropet`. Vite é detectado sozinho.
2. Em **Environment Variables** cadastre, antes do deploy:

| Nome | Valor |
|---|---|
| `VITE_SUPABASE_URL` | Project URL |
| `VITE_SUPABASE_ANON_KEY` | chave anon |
| `SUPABASE_URL` | Project URL |
| `SUPABASE_ANON_KEY` | chave anon |

3. **Deploy**. Depois aponte o domínio da loja para esse projeto.

### 3. Primeiro uso

1. Entre em `/admin` com `01ST` / `Agro1234`.
2. **Configurações → Loja online**: WhatsApp da loja (sem ele o botão de WhatsApp não aparece para o cliente), endereço, frete.
3. **Produtos**: cadastre os produtos e marque o que aparece no catálogo (**Loja online** no painel).
4. Mande o link da loja para os clientes.

---

## Rodar no computador

```bash
cp .env.example .env     # chaves do Supabase
npm install
npm run dev              # loja em http://localhost:3000, API em :3001
```

## Estrutura

```
api/            função serverless única (Vercel) + servidor Express para desenvolvimento
src/loja/       catálogo público (/)
src/painel/     painel da loja (/painel)
src/pages/      sistema de gestão (/admin)
supabase/       001 = banco completo
public/         logo.png (cabeçalho), favicon.png, logo-grande.png (arte original)
```
