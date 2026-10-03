# DimDim API — 2º Checkpoint de DevOps Tools & Cloud Computing

**Grupo:** CloudOps

| Nome | RM |
|---|---|
| Felipe Furlanetto (representante) | 562766 |
| João Victor Caetano | 562074 |
| João Victor Bueno Castelini da Silva | 564115 |
| Ryan Vetoriano | 565667 |
| Raul Rezende Iemini Aguiar | 564002 |

**Disciplina:** DevOps Tools & Cloud Computing — FIAP

API REST em **Java 17 + Spring Boot 3** no **Azure Web App**, com **Azure SQL Database (PaaS)** e **Application Insights**. Tudo é criado pelo **Azure CLI** com um único script (`deploy.ps1`).

**URL da API:** https://app-dimdim-cloudops-562766.azurewebsites.net

## Arquivos do repositório

| Arquivo | O que é |
|---|---|
| `src/` | Código-fonte (Java) |
| `database/schema.sql` | DDL das tabelas |
| `deploy.ps1` | Script do Azure CLI (cria os recursos e faz o deploy) |
| `requests/operacoes.json` | JSON de GET, POST, PUT e DELETE |
| `requests/testar-api.ps1` | Roteiro automático das 10 operações |
| `pom.xml` | Build do Maven |

## DDL (2 tabelas com chave estrangeira)

```sql
CREATE TABLE dbo.cliente (
    id     BIGINT        IDENTITY(1,1) NOT NULL,
    nome   VARCHAR(100)  NOT NULL,
    email  VARCHAR(150)  NOT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (id),
    CONSTRAINT uq_cliente_email UNIQUE (email)
);

CREATE TABLE dbo.transacao (
    id          BIGINT         IDENTITY(1,1) NOT NULL,
    descricao   VARCHAR(200)   NOT NULL,
    valor       DECIMAL(12,2)  NOT NULL,
    data_hora   DATETIME2      NOT NULL,
    cliente_id  BIGINT         NOT NULL,
    CONSTRAINT pk_transacao PRIMARY KEY (id),
    CONSTRAINT fk_transacao_cliente FOREIGN KEY (cliente_id) REFERENCES dbo.cliente (id)
);
```

Arquivo completo: [`database/schema.sql`](database/schema.sql). A aplicação cria as tabelas sozinha ao subir.

## How to — como rodar

**Pré-requisitos:** Azure CLI (`az --version`), JDK 17 (`java -version`), Maven ou Eclipse, PowerShell e uma conta Azure.

1. Baixe o projeto e abra o PowerShell na pasta dele.
2. Gere o `target\app.jar`:
   - Maven: `mvn clean package -DskipTests`
   - Eclipse: botão direito no projeto → `Run As → Maven build...` → Goals: `clean package -DskipTests` → Run (deve aparecer **BUILD SUCCESS**).
3. Rode o deploy:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\deploy.ps1
   ```
4. Faça login com a conta dona da assinatura e responda `s` na confirmação. Leva de 10 a 15 minutos e termina com **PRONTO!**.
5. Abra a URL da API e `/clientes` (deve mostrar `[]`). Se aparecer a página azul "Hey, Java developers!", espere 2 minutos e use Ctrl+F5.

**O que o `deploy.ps1` executa:** `az login` → `az provider register` → `az group create` → `az sql server create` → `az sql db create` → `az sql server firewall-rule create` → `az monitor log-analytics workspace create` → `az monitor app-insights component create` → `az appservice plan create` → `az webapp create` → `az webapp config appsettings set` → `az webapp deploy`.

## Rotas e JSON

| Método | Rota | Descrição |
|---|---|---|
| GET | `/clientes` | Lista clientes |
| GET | `/clientes/{id}` | Busca um cliente |
| POST | `/clientes` | Cria cliente |
| PUT | `/clientes/{id}` | Atualiza cliente |
| DELETE | `/clientes/{id}` | Apaga cliente (409 se tiver transações) |
| GET | `/clientes/{id}/transacoes` | Transações do cliente |
| GET | `/transacoes` | Lista transações |
| GET | `/transacoes/{id}` | Busca transação |
| POST | `/transacoes` | Cria transação |
| PUT | `/transacoes/{id}` | Atualiza transação |
| DELETE | `/transacoes/{id}` | Apaga transação |

`POST /clientes`
```json
{ "nome": "Maria Silva", "email": "maria@dimdim.com" }
```

`PUT /clientes/1`
```json
{ "nome": "Maria Souza", "email": "maria@dimdim.com" }
```

`POST /transacoes`
```json
{ "descricao": "Pagamento Pix", "valor": 150.75, "cliente": { "id": 1 } }
```

`PUT /transacoes/1`
```json
{ "descricao": "Pagamento Pix (corrigido)", "valor": 200.00, "cliente": { "id": 1 } }
```

Todos os exemplos (inclusive GET e DELETE) estão em [`requests/operacoes.json`](requests/operacoes.json).

## Ver o banco

Portal Azure → `rg-dimdim-cp2-cloudops` → `sql-dimdim-cloudops-562766` → `dimdimdb` → **Query editor** (login `sqladmin`; se pedir, use **Allowlist IP**):

```sql
SELECT * FROM dbo.cliente;
SELECT * FROM dbo.transacao;
```

## Application Insights

Portal Azure → `rg-dimdim-cp2-cloudops` → `appi-dimdim-cloudops` → **Live metrics** ou **Transaction search**. Os dados podem levar de 2 a 5 minutos para aparecer.

## Apagar tudo depois da avaliação

```powershell
az group delete --name rg-dimdim-cp2-cloudops --yes --no-wait
```

---

# Roteiro da apresentação (só comandos)

Use sempre o PowerShell **na pasta do projeto**.

## Antes de começar

```powershell
az login
az webapp show --resource-group rg-dimdim-cp2-cloudops --name app-dimdim-cloudops-562766 --query state -o tsv
```
O resultado deve ser `Running`. Se for `Stopped`:
```powershell
az webapp start --resource-group rg-dimdim-cp2-cloudops --name app-dimdim-cloudops-562766
```
Abra no navegador `https://app-dimdim-cloudops-562766.azurewebsites.net/clientes` (deve mostrar `[]`).

Deixe abertas: o `deploy.ps1` no editor, o portal no Query editor (já logado) e o `appi-dimdim-cloudops`.

## Passo 1 — Mostrar o código do Azure CLI

Abra o `deploy.ps1` e desça pelos blocos: login, `az group create`, `az sql server create`, `az sql db create`, firewall, Application Insights, `az appservice plan create`, `az webapp create`, `az webapp config appsettings set`, `az webapp deploy`.

## Passo 2 — Mostrar os recursos

Portal → Resource Group `rg-dimdim-cp2-cloudops`: SQL Server, banco, Application Insights, plano e Web App.

## Passo 3 — Mostrar o DDL

Abra `database/schema.sql`. No Query editor:
```sql
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('cliente', 'transacao')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
```

## Passo 4 — Operações (rodar o banco depois de cada uma)

```powershell
$BASE = "https://app-dimdim-cloudops-562766.azurewebsites.net"
```

Depois de **cada** comando abaixo, rode no Query editor:
```sql
SELECT * FROM dbo.cliente;
SELECT * FROM dbo.transacao;
```

1. GET clientes
```powershell
Invoke-RestMethod -Uri "$BASE/clientes"
```
2. POST cliente
```powershell
$c = Invoke-RestMethod -Method Post -Uri "$BASE/clientes" -ContentType "application/json" -Body '{"nome":"Maria Silva","email":"maria@dimdim.com"}'
$c
```
3. GET cliente por id
```powershell
Invoke-RestMethod -Uri "$BASE/clientes/$($c.id)"
```
4. PUT cliente
```powershell
Invoke-RestMethod -Method Put -Uri "$BASE/clientes/$($c.id)" -ContentType "application/json" -Body '{"nome":"Maria Souza","email":"maria@dimdim.com"}'
```
5. POST transação
```powershell
$corpo = @{ descricao = "Pagamento Pix"; valor = 150.75; cliente = @{ id = $c.id } } | ConvertTo-Json
$t = Invoke-RestMethod -Method Post -Uri "$BASE/transacoes" -ContentType "application/json" -Body $corpo
$t
```
6. GET transações
```powershell
Invoke-RestMethod -Uri "$BASE/transacoes"
Invoke-RestMethod -Uri "$BASE/clientes/$($c.id)/transacoes"
```
7. PUT transação
```powershell
$corpo = @{ descricao = "Pagamento Pix (corrigido)"; valor = 200.00; cliente = @{ id = $c.id } } | ConvertTo-Json
Invoke-RestMethod -Method Put -Uri "$BASE/transacoes/$($t.id)" -ContentType "application/json" -Body $corpo
```
8. DELETE transação
```powershell
Invoke-RestMethod -Method Delete -Uri "$BASE/transacoes/$($t.id)"
```
9. DELETE cliente
```powershell
Invoke-RestMethod -Method Delete -Uri "$BASE/clientes/$($c.id)"
```

**Alternativa em um comando só** (pausa a cada operação; aperte Enter para seguir):
```powershell
.\requests\testar-api.ps1 -Base $BASE
```

## Passo 5 — Application Insights

Faça algumas chamadas e mostre **Live metrics** e **Transaction search** no `appi-dimdim-cloudops`.

## Passo 6 — GitHub

Mostre: `database/schema.sql`, `src/`, `deploy.ps1`, `README.md` e `requests/operacoes.json`.

## Se der problema

```powershell
az webapp restart --resource-group rg-dimdim-cp2-cloudops --name app-dimdim-cloudops-562766
```
Espere 1 minuto e tente de novo. Se o Query editor não conectar, use **Allowlist IP** no aviso.
