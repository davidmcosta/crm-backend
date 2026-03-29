# Backend — Sistema de Gestão de Encomendas

API REST construída com **Node.js + Fastify + Prisma + PostgreSQL**.

---

## Pré-requisitos

- [Node.js](https://nodejs.org/) v18 ou superior
- [PostgreSQL](https://www.postgresql.org/) (local ou na cloud)
- npm ou pnpm

---

## Instalação e Setup

### 1. Instalar dependências

```bash
npm install
```

### 2. Configurar variáveis de ambiente

```bash
cp .env.example .env
```

Edita o ficheiro `.env` com os teus valores:

```env
DATABASE_URL="postgresql://postgres:password@localhost:5432/order_management"
JWT_SECRET="uma_chave_secreta_muito_longa_e_aleatoria_aqui"
JWT_REFRESH_SECRET="outra_chave_secreta_diferente_para_refresh"
```

### 3. Criar a base de dados e executar migrations

```bash
# Cria as tabelas na base de dados
npm run db:migrate

# Gera o cliente Prisma
npm run db:generate
```

### 4. Popular com dados iniciais (opcional mas recomendado)

```bash
npm run db:seed
```

Isto cria:
- **Admin**: `admin@empresa.pt` / `admin123`
- **Operador**: `operador@empresa.pt` / `operador123`
- 2 clientes de exemplo

⚠️ Muda as passwords após o primeiro login!

### 5. Arrancar o servidor

```bash
# Desenvolvimento (com hot-reload)
npm run dev

# Produção
npm run build && npm start
```

O servidor fica disponível em `http://localhost:3000`

---

## Endpoints da API

### Autenticação
| Método | Rota | Descrição |
|---|---|---|
| POST | `/api/auth/login` | Login com email e password |
| POST | `/api/auth/refresh` | Renovar access token |
| POST | `/api/auth/logout` | Logout |
| GET | `/api/auth/me` | Dados do utilizador atual |

### Encomendas
| Método | Rota | Descrição | Permissão mínima |
|---|---|---|---|
| GET | `/api/orders` | Listar encomendas | VIEWER |
| GET | `/api/orders/:id` | Detalhe da encomenda | VIEWER |
| GET | `/api/orders/:id/history` | Histórico de estados | VIEWER |
| POST | `/api/orders` | Criar encomenda | OPERATOR |
| PUT | `/api/orders/:id` | Editar encomenda | OPERATOR |
| PATCH | `/api/orders/:id/status` | Atualizar estado | OPERATOR |
| DELETE | `/api/orders/:id` | Cancelar encomenda | MANAGER |

### Clientes
| Método | Rota | Descrição | Permissão mínima |
|---|---|---|---|
| GET | `/api/customers` | Listar clientes | VIEWER |
| GET | `/api/customers/:id` | Detalhe do cliente | VIEWER |
| GET | `/api/customers/:id/orders` | Encomendas do cliente | VIEWER |
| POST | `/api/customers` | Criar cliente | OPERATOR |
| PUT | `/api/customers/:id` | Editar cliente | OPERATOR |

### Utilizadores (só ADMIN)
| Método | Rota | Descrição |
|---|---|---|
| GET | `/api/users` | Listar utilizadores |
| GET | `/api/users/:id` | Detalhe do utilizador |
| POST | `/api/users` | Criar utilizador |
| PUT | `/api/users/:id` | Editar utilizador |
| PATCH | `/api/users/:id/role` | Alterar perfil |
| DELETE | `/api/users/:id` | Desativar utilizador |
| PATCH | `/api/users/me/password` | Alterar a minha password |

---

## Exemplos de Pedidos

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@empresa.pt", "password": "admin123"}'
```

### Criar encomenda
```bash
curl -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  -d '{
    "customerId": "uuid-do-cliente",
    "notes": "Entregar urgente",
    "items": [
      {
        "productName": "Produto A",
        "quantity": 2,
        "unitPrice": 29.99
      }
    ]
  }'
```

### Atualizar estado
```bash
curl -X PATCH http://localhost:3000/api/orders/UUID-DA-ENCOMENDA/status \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  -d '{"status": "CONFIRMED", "notes": "Confirmado pelo cliente"}'
```

---

## Perfis de Utilizador

| Perfil | Descrição |
|---|---|
| `ADMIN` | Acesso total, gere utilizadores |
| `MANAGER` | Gere encomendas e clientes, pode cancelar |
| `OPERATOR` | Cria e atualiza encomendas e clientes |
| `VIEWER` | Apenas consulta (só leitura) |

---

## Ferramentas úteis

```bash
# Abrir interface visual da base de dados
npm run db:studio

# Criar nova migration após alterações ao schema
npm run db:migrate
```
