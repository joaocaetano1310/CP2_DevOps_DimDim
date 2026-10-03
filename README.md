# DimDim API — 2º Checkpoint de DevOps Tools & Cloud Computing

**Grupo:** CloudOps
**Integrantes:**

| Nome | RM |
|---|---|
| Felipe Furlanetto (representante) | 562766 |
| João _(completar o sobrenome)_ | 562074 |
| João Victor Bueno Castelini da Silva | 564115 |
| Ryan Vetoriano | 565667 |
| Raul Rezende Iemini Aguiar | 564002 |

**Disciplina:** DevOps Tools & Cloud Computing — FIAP (TDS)

API REST em **Java 17 + Spring Boot 3** publicada no **Azure App Service (Web App)**, com persistência em **Azure SQL Database (SQL Server PaaS)** e monitoramento no **Application Insights**. Todos os recursos são criados e o deploy é feito pelo **Azure CLI**, com um único script (`deploy.ps1`).

---

## 1. O que o projeto faz

A API cadastra **clientes** e as **transações** de cada cliente (tema DimDim, pagamentos). São duas tabelas relacionadas por chave estrangeira (master-detail):

```
cliente (1) ───< transacao (N)
  id  PK            id          PK
  nome              descricao
  email (único)     valor
                    data_hora
                    cliente_id  FK → cliente.id
```

O DDL completo está em [`database/schema.sql`](database/schema.sql). As tabelas são criadas automaticamente na primeira vez que a aplicação sobe.

## 2. O que existe no repositório

| Arquivo / pasta | Para que serve |
|---|---|
| `src/main/java/br/com/dimdim/webapp/` | Código-fonte da aplicação (controllers, models, repositories) |
| `src/main/resources/application.properties` | Configuração da aplicação (lê o banco de variáveis de ambiente) |
| `src/main/resources/schema.sql` | Cópia do DDL que a aplicação executa ao subir |
| `database/schema.sql` | **DDL das tabelas** (tabelas, colunas, PK, FK) |
| `database/consultas.sql` | Consultas para mostrar o banco depois de cada operação |
| `deploy.ps1` | **Script do Azure CLI**: cria os recursos e faz o deploy |
| `requests/operacoes.json` | **JSON das operações** GET, POST, PUT e DELETE |
| `requests/testar-api.ps1` | Roteiro de teste passo a passo (pausa a cada operação) |
| `pom.xml` | Configuração do Maven (dependências e build) |

## 3. Pré-requisitos

Instale e confira cada item **antes** de começar:

| Ferramenta | Como conferir | Observação |
|---|---|---|
| **Azure CLI** | `az --version` | https://learn.microsoft.com/cli/azure/install-azure-cli |
| **JDK 17 ou mais novo** | `java -version` | Precisa ser JDK, não só JRE |
| **Maven** ou **Eclipse** | `mvn -v` | O Eclipse tem Maven embutido; serve para gerar o `.jar` |
| **PowerShell** | já vem no Windows | O script é feito para PowerShell |
| **Conta Azure** | login no portal | Com permissão para criar recursos na assinatura |

> **Importante:** a conta usada no login do script é a dona dos recursos e dos créditos. No nosso grupo, o deploy é feito na conta do representante.

## 4. Passo a passo

### Passo 1 — Baixar o projeto
Clone o repositório ou baixe o `.zip` e descompacte, por exemplo em `C:\Users\<usuario>\Downloads\dimdim-webapp`.

### Passo 2 — Gerar o arquivo `app.jar`
O deploy envia o arquivo `target\app.jar`. Gere-o de um destes jeitos:

**Pelo Eclipse**
1. `File → Import → Maven → Existing Maven Projects` e escolha a pasta do projeto.
2. Espere o Eclipse terminar de carregar (barra "Building" no canto inferior direito).
3. Botão direito no projeto → `Run As → Maven build...`.
4. Em **Goals**, escreva `clean package -DskipTests` e clique em **Run**.
5. No Console, deve aparecer **BUILD SUCCESS**.

**Pelo terminal (se o Maven estiver instalado)**
```powershell
cd C:\Users\<usuario>\Downloads\dimdim-webapp
mvn clean package -DskipTests
```

Confira que o arquivo `target\app.jar` existe.

### Passo 3 — (Opcional) Ajustar os nomes no `deploy.ps1`
No topo do script há as variáveis:

| Variável | Valor atual | Para que serve |
|---|---|---|
| `$GRUPO` | `cloudops` | Nome do grupo (minúsculo, sem espaço) |
| `$RM` | `562766` | Número que deixa os nomes únicos no Azure |
| `$REGIOES` | `francecentral, southcentralus, mexicocentral, southafricanorth` | Regiões que a assinatura permite; o script tenta uma por vez |
| `$SQLPASS` | `DimDimCp2Azure2026x9` | Senha do administrador do SQL Server |

Se for rodar em **outra assinatura**, troque `$RM` (os nomes precisam ser únicos no mundo todo) e confira quais regiões ela permite.

### Passo 4 — Rodar o deploy
Abra o **PowerShell na pasta do projeto** e rode:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\deploy.ps1
```

O que vai acontecer:
1. O navegador abre para o **login do Azure**. Entre com a conta dona da assinatura.
2. O script mostra a conta e a assinatura e pergunta **"Esta e a conta do Felipe? (s/n)"**. Confira e responda `s`.
3. Ele executa, em ordem:

| Etapa | Comando principal |
|---|---|
| Ativa os serviços da assinatura | `az provider register` (Sql, Web, Insights, OperationalInsights, AlertsManagement) |
| Resource Group | `az group create` |
| SQL Server (tenta as regiões da lista) | `az sql server create` |
| Banco de dados | `az sql db create` |
| Firewall do SQL (serviços do Azure e o IP de quem roda) | `az sql server firewall-rule create` |
| Application Insights | `az monitor log-analytics workspace create` e `az monitor app-insights component create` |
| Plano e Web App Java 17 | `az appservice plan create` e `az webapp create` |
| Configurações do Web App (banco e Insights) | `az webapp config appsettings set` |
| Envio do `.jar` | `az webapp deploy` |

Leva de **10 a 15 minutos**. Termina com **PRONTO!** em verde e mostra a URL da API. **Não feche a janela** antes disso.

### Passo 5 — Conferir que subiu
No navegador, abra (a primeira chamada pode levar até 1 minuto):

- `https://app-dimdim-cloudops-562766.azurewebsites.net/` → deve mostrar `{"app":"DimDim API","status":"ok",...}`
- `https://app-dimdim-cloudops-562766.azurewebsites.net/clientes` → deve mostrar `[]` (lista vazia)

Se aparecer a página azul "Hey, Java developers!", a aplicação ainda está iniciando: espere 2 minutos e atualize com **Ctrl+F5**.

## 5. Comandos usados e o que cada um faz (todos testados)

Todos os comandos desta seção foram **executados de verdade e funcionaram** no deploy do grupo. Estão na ordem em que aparecem. A parte C é executada pelo `deploy.ps1`; as demais, você digita.

### A. Preparar o terminal

**Comando A1 — Conferir que o Azure CLI está instalado**
```powershell
az --version
```
- **O que faz:** mostra a versão do Azure CLI.
- **Resultado esperado:** uma lista com `azure-cli 2.x` e a frase `Your CLI is up-to-date`.

**Comando A2 — Entrar na pasta do projeto**
```powershell
cd C:\Users\<usuario>\Downloads\dimdim-webapp
```
- **O que faz:** muda o terminal para a pasta do projeto, onde estão o `deploy.ps1` e o `pom.xml`. Todos os comandos seguintes são rodados dentro dela.
- **Resultado esperado:** o prompt passa a mostrar o caminho da pasta.

**Comando A3 — Liberar a execução de scripts nesta janela**
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
- **O que faz:** o Windows bloqueia scripts `.ps1` por padrão. Este comando libera **só nesta janela do PowerShell** e deixa de valer quando ela é fechada.
- **Resultado esperado:** nenhuma mensagem. A linha em branco é normal.

### B. Gerar o arquivo `app.jar`

**Comando B1 — Compilar e empacotar o projeto**
```powershell
mvn clean package -DskipTests
```
(No Eclipse: botão direito no projeto → `Run As → Maven build...` → em **Goals**, `clean package -DskipTests` → **Run**.)
- **O que faz:** apaga o `target` antigo (`clean`), compila o código Java e empacota tudo em `target\app.jar` (`package`). O `-DskipTests` pula os testes, que o projeto não tem.
- **Resultado esperado:** `BUILD SUCCESS` e a linha `Building jar: ...\target\app.jar`.

### C. Deploy no Azure (`.\deploy.ps1`)

**Comando C0 — Executar o script**
```powershell
.\deploy.ps1
```
- **O que faz:** roda, em ordem, todos os comandos C1 a C16 abaixo. Leva de 10 a 15 minutos.
- **Resultado esperado:** termina com **PRONTO!** em verde e mostra a URL da API.

Os comandos que o script executa, com os valores reais do grupo:

**C1 — Login no Azure e escolha da assinatura**
```powershell
az login
```
- **O que faz:** abre o navegador para o login e depois pede a assinatura (digite o número ou aperte Enter para a padrão).
- **Resultado esperado:** `Subscription: 2026-2TDSPF-Felipe Furlanetto-RM5627566`.

**C2 — Mostrar a conta logada**
```powershell
az account show --query "{usuario:user.name, assinatura:name}" -o tsv
```
- **O que faz:** exibe o usuário e a assinatura em uso. O script pergunta **"Esta e a conta do Felipe? (s/n)"** e só segue com `s`. Isso evita criar recursos na conta errada.
- **Resultado esperado:** `RM562766@fiap.com.br   2026-2TDSPF-Felipe Furlanetto-RM5627566`.

**C3 — Preparar a extensão do Application Insights**
```powershell
az config set extension.use_dynamic_install=yes_without_prompt extension.dynamic_install_allow_preview=true --only-show-errors
az extension add --name application-insights --upgrade --only-show-errors
```
- **O que faz:** permite que o Azure CLI instale sozinho a extensão necessária para criar o Application Insights.

**C4 — Ativar os serviços na assinatura**
```powershell
az provider register --namespace Microsoft.Sql --wait
az provider register --namespace Microsoft.Web --wait
az provider register --namespace Microsoft.Insights --wait
az provider register --namespace Microsoft.OperationalInsights --wait
az provider register --namespace Microsoft.AlertsManagement --wait
```
- **O que faz:** liga na assinatura os serviços de SQL, Web App e monitoramento. Sem isso, o Azure responde `MissingSubscriptionRegistration`.
- **Resultado esperado:** uma linha `Registrando Microsoft.... ...` para cada serviço. Leva de 1 a 3 minutos.

**C5 — Criar o Resource Group**
```powershell
az group create --name rg-dimdim-cp2-cloudops --location brazilsouth
```
- **O que faz:** cria o grupo de recursos, a "pasta" que reúne tudo e permite apagar tudo de uma vez.
- **Resultado esperado:** `"provisioningState": "Succeeded"`.

**C6 — Criar o SQL Server (PaaS)**
```powershell
az sql server create --resource-group rg-dimdim-cp2-cloudops --name sql-dimdim-cloudops-562766 --location mexicocentral --admin-user sqladmin --admin-password <senha>
```
- **O que faz:** cria o servidor SQL gerenciado pelo Azure. O script tenta as regiões permitidas da lista, uma por vez (`francecentral`, `southcentralus`, `mexicocentral`, `southafricanorth`), e fica com a primeira que aceitar. No deploy do grupo, quem aceitou foi o `mexicocentral`.
- **Resultado esperado:** `"state": "Ready"` e a mensagem verde `SQL Server na regiao: mexicocentral`.

**C7 — Criar o banco de dados**
```powershell
az sql db create --resource-group rg-dimdim-cp2-cloudops --server sql-dimdim-cloudops-562766 --name dimdimdb --service-objective Basic
```
- **O que faz:** cria o banco `dimdimdb` no plano Basic, o mais barato.
- **Resultado esperado:** `"status": "Online"`.

**C8 — Liberar os serviços do Azure no firewall do SQL**
```powershell
az sql server firewall-rule create --resource-group rg-dimdim-cp2-cloudops --server sql-dimdim-cloudops-562766 --name AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
```
- **O que faz:** permite que o Web App (um serviço do Azure) acesse o banco.
- **Resultado esperado:** `"name": "AllowAzureServices"`.

**C9 — Liberar o IP de quem está rodando o script**
```powershell
az sql server firewall-rule create --resource-group rg-dimdim-cp2-cloudops --server sql-dimdim-cloudops-562766 --name MeuIP --start-ip-address <seu-ip> --end-ip-address <seu-ip>
```
- **O que faz:** libera o seu IP para você consultar o banco no Query editor do portal. O script descobre o IP sozinho.
- **Resultado esperado:** `"name": "MeuIP"`.

**C10 — Criar o Log Analytics (base do Application Insights)**
```powershell
az monitor log-analytics workspace create --resource-group rg-dimdim-cp2-cloudops --workspace-name law-dimdim-cloudops --location mexicocentral
az monitor log-analytics workspace show --resource-group rg-dimdim-cp2-cloudops --workspace-name law-dimdim-cloudops --query id -o tsv
```
- **O que faz:** cria o espaço onde ficam guardados os registros e guarda o `id` dele para o próximo passo.
- **Resultado esperado:** `"provisioningState": "Succeeded"`.

**C11 — Criar o Application Insights**
```powershell
az monitor app-insights component create --app appi-dimdim-cloudops --resource-group rg-dimdim-cp2-cloudops --location mexicocentral --kind web --application-type web --workspace <id-do-workspace>
az monitor app-insights component show --app appi-dimdim-cloudops --resource-group rg-dimdim-cp2-cloudops --query connectionString -o tsv
```
- **O que faz:** cria o recurso de monitoramento e pega a *connection string*, que a aplicação usa para enviar os dados.
- **Resultado esperado:** `"name": "appi-dimdim-cloudops"`.

**C12 — Criar o plano do App Service**
```powershell
az appservice plan create --name plan-dimdim-cloudops --resource-group rg-dimdim-cp2-cloudops --location mexicocentral --is-linux --sku B1
```
- **O que faz:** cria a máquina Linux (plano B1) onde o Web App roda.
- **Resultado esperado:** `"status": "Ready"`.

**C13 — Criar o Web App com Java 17**
```powershell
az webapp create --name app-dimdim-cloudops-562766 --resource-group rg-dimdim-cp2-cloudops --plan plan-dimdim-cloudops --runtime "JAVA:17-java17"
```
- **O que faz:** cria o Web App, ainda vazio, preparado para rodar Java 17.
- **Resultado esperado:** `"state": "Running"`.

**C14 — Configurar a conexão com o banco e o Insights**
```powershell
az webapp config appsettings set --name app-dimdim-cloudops-562766 --resource-group rg-dimdim-cp2-cloudops --settings "SPRING_DATASOURCE_URL=<jdbc-do-sql>" "SPRING_DATASOURCE_USERNAME=sqladmin" "SPRING_DATASOURCE_PASSWORD=<senha>" "WEBSITES_PORT=8080" "APPLICATIONINSIGHTS_CONNECTION_STRING=<connection-string>" "ApplicationInsightsAgent_EXTENSION_VERSION=~3"
```
- **O que faz:** define as variáveis de ambiente do Web App. A aplicação lê daí o endereço e a senha do banco (a senha não fica no código) e a chave do Insights. `WEBSITES_PORT=8080` diz ao Azure em qual porta a aplicação escuta.

**C15 — Gerar o `.jar`**
```powershell
mvn clean package -DskipTests
```
- **O que faz:** o mesmo comando B1. Se o `mvn` não existir no PowerShell, o script usa o `target\app.jar` que o Eclipse já gerou.

**C16 — Enviar o `.jar` para o Web App**
```powershell
az webapp deploy --resource-group rg-dimdim-cp2-cloudops --name app-dimdim-cloudops-562766 --src-path target\app.jar --type jar
```
- **O que faz:** envia o `app.jar` ao Azure e inicia a aplicação.
- **Resultado esperado:** `Deployment has completed successfully` e `"status": "RuntimeSuccessful"`.

### D. Conferir no navegador

**Comando D1 — Página inicial da API**
```
https://app-dimdim-cloudops-562766.azurewebsites.net/
```
- **O que faz:** testa se a aplicação subiu. Na primeira chamada pode demorar até 1 minuto.
- **Resultado esperado:** `{"app":"DimDim API","status":"ok",...}`. A página azul "Hey, Java developers!" significa que ainda está iniciando (espere 2 minutos e use Ctrl+F5).

**Comando D2 — Listar clientes**
```
https://app-dimdim-cloudops-562766.azurewebsites.net/clientes
```
- **O que faz:** consulta o banco pela API.
- **Resultado esperado:** `[]` (lista vazia). Isso prova que a API conectou no SQL Server e criou as tabelas.

### E. Testar as 10 operações

**Comando E1 — Roteiro automático**
```powershell
.\requests\testar-api.ps1 -Base https://app-dimdim-cloudops-562766.azurewebsites.net
```
- **O que faz:** executa as 10 operações abaixo, uma por vez, e **pausa** em cada uma para você mostrar o banco. Aperte Enter para seguir.

| # | Operação | Rota | Resultado confirmado |
|---|---|---|---|
| 1 | GET | `/clientes` | Lista de clientes |
| 2 | POST | `/clientes` | Cliente criado, com `id` gerado pelo banco |
| 3 | GET | `/clientes/{id}` | Cliente encontrado |
| 4 | PUT | `/clientes/{id}` | Nome atualizado |
| 5 | POST | `/transacoes` | Transação criada, ligada ao cliente (FK) |
| 6 | GET | `/transacoes` | Lista de transações |
| 7 | GET | `/clientes/{id}/transacoes` | Transações do cliente |
| 8 | PUT | `/transacoes/{id}` | Descrição e valor atualizados |
| 9 | DELETE | `/transacoes/{id}` | Transação apagada |
| 10 | DELETE | `/clientes/{id}` | Cliente apagado |

### F. Diagnóstico

**Comando F1 — Ver em quais regiões a assinatura permite criar recursos**
```powershell
az policy assignment list --query "[].{nome:displayName, regioes:parameters.listOfAllowedLocations.value}" -o json
```
- **O que faz:** lista a política de regiões da assinatura. É o comando que mostrou por que o `brazilsouth` era recusado.
- **Resultado esperado:** `southafricanorth`, `francecentral`, `southcentralus`, `mexicocentral` e `eastus`.

## 6. Testar as operações (GET, POST, PUT, DELETE)

### Roteiro automático (recomendado para a apresentação)
```powershell
.\requests\testar-api.ps1 -Base https://app-dimdim-cloudops-562766.azurewebsites.net
```
Executa 10 operações em ordem e **pausa em cada uma** para você mostrar o banco. Aperte Enter para seguir.

### Rotas

| Método | Rota | Descrição |
|---|---|---|
| GET | `/clientes` | Lista clientes |
| GET | `/clientes/{id}` | Busca um cliente |
| POST | `/clientes` | Cria cliente |
| PUT | `/clientes/{id}` | Atualiza cliente |
| DELETE | `/clientes/{id}` | Apaga cliente (retorna 409 se ainda tiver transações) |
| GET | `/clientes/{id}/transacoes` | Transações de um cliente |
| GET | `/transacoes` | Lista transações |
| GET | `/transacoes/{id}` | Busca uma transação |
| POST | `/transacoes` | Cria transação (precisa de `cliente.id` existente) |
| PUT | `/transacoes/{id}` | Atualiza transação |
| DELETE | `/transacoes/{id}` | Apaga transação |

### Exemplos de JSON

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

Todos os exemplos, incluindo GET e DELETE, estão em [`requests/operacoes.json`](requests/operacoes.json). Também funcionam no Postman: use a URL base acima.

## 7. Mostrar o banco depois de cada operação

1. Abra https://portal.azure.com com a conta dona da assinatura.
2. `Resource groups → rg-dimdim-cp2-cloudops → sql-dimdim-cloudops-562766 → dimdimdb`.
3. Menu da esquerda: **Query editor (preview)**.
4. Login com **SQL server authentication**: usuário `sqladmin` e a senha do `$SQLPASS`.
5. Se pedir para liberar o IP, aceite a opção **Allowlist IP**.
6. Rode, a cada operação:
```sql
SELECT * FROM dbo.cliente;
SELECT * FROM dbo.transacao;
```

## 8. Application Insights

1. No portal: `rg-dimdim-cp2-cloudops → appi-dimdim-cloudops`.
2. Veja em **Live metrics**, **Transaction search** ou **Performance**.
3. Os dados aparecem depois de algumas chamadas à API e podem levar de 2 a 5 minutos para chegar.

## 9. Roteiro de apresentação (passo a passo)

Roteiro pronto para a avaliação em sala. O enunciado pede: **mostrar o banco depois de cada operação** e **todo o código do Azure CLI** que cria o Web App e faz o deploy. Siga a ordem abaixo.

### 9.1 Antes da aula (na véspera ou de manhã)

Faça tudo isto com calma, para não ter surpresa na hora.

1. **Entrar no Azure com a conta dona da assinatura** (PowerShell):
```powershell
az login
az account show --query "{usuario:user.name, assinatura:name}" -o table
```
2. **Conferir que os recursos existem e o Web App está rodando:**
```powershell
az group list -o table
az webapp show --resource-group rg-dimdim-cp2-cloudops --name app-dimdim-cloudops-562766 --query state -o tsv
```
O resultado do segundo comando deve ser `Running`. Se aparecer `Stopped`, ligue:
```powershell
az webapp start --resource-group rg-dimdim-cp2-cloudops --name app-dimdim-cloudops-562766
```
3. **Conferir que a API responde** (no navegador, e use Ctrl+F5 para limpar o cache). A primeira chamada pode demorar até 1 minuto:
   - `https://app-dimdim-cloudops-562766.azurewebsites.net/`
   - `https://app-dimdim-cloudops-562766.azurewebsites.net/clientes`
4. **Deixar abertas, em abas separadas do navegador:**
   - Portal Azure → `rg-dimdim-cp2-cloudops` (lista dos recursos).
   - Portal Azure → `dimdimdb` → **Query editor**, **já logado** (`sqladmin`). Teste uma consulta na véspera.
   - Portal Azure → `appi-dimdim-cloudops` (Application Insights) → **Live metrics**.
5. **Deixar abertos no computador:** o `deploy.ps1` e o `database/schema.sql` em um editor (VS Code ou Eclipse), e um PowerShell dentro da pasta do projeto.
6. **Se o Query editor reclamar de IP:** use **Allowlist IP** no aviso (o IP da sala será diferente do de casa).
7. **Se o app estiver quebrado**, rode o deploy de novo (15 minutos) ou reinicie:
```powershell
az webapp restart --resource-group rg-dimdim-cp2-cloudops --name app-dimdim-cloudops-562766
```

### 9.2 Parte 1 — Mostrar o código do Azure CLI

Abra o `deploy.ps1` e vá descendo pelos blocos. Em cada um, diga o que ele faz:

| Bloco no script | O que dizer |
|---|---|
| Variáveis do topo | Nomes dos recursos, regiões permitidas e usuário do SQL |
| `az login` + confirmação de conta | Login na conta dona da assinatura e conferência antes de criar qualquer coisa |
| `az provider register` | Ativa na assinatura os serviços que vamos usar (SQL, Web, Insights) |
| `az group create` | Cria o Resource Group, a "pasta" que agrupa todos os recursos |
| `az sql server create` + `az sql db create` | Cria o SQL Server e o banco **PaaS** (gerenciado pelo Azure) |
| `az sql server firewall-rule create` | Libera o acesso ao banco para os serviços do Azure e para o nosso IP |
| `az monitor log-analytics ...` + `az monitor app-insights ...` | Cria o Application Insights, para monitorar a aplicação |
| `az appservice plan create` | Cria o plano (a máquina Linux B1 onde o app roda) |
| `az webapp create` | Cria o Web App com Java 17 |
| `az webapp config appsettings set` | Configura a conexão com o banco e o Insights por variáveis de ambiente (a senha não fica no código da aplicação) |
| `az webapp deploy` | Envia o `app.jar` para o Web App |

### 9.3 Parte 2 — Mostrar os recursos no Azure

No portal, na aba do Resource Group `rg-dimdim-cp2-cloudops`, mostre a lista: SQL Server, banco `dimdimdb`, Application Insights, plano e Web App. Clique no Web App e mostre a URL.

### 9.4 Parte 3 — Mostrar o DDL e as tabelas (master-detail com FK)

1. Mostre o arquivo `database/schema.sql` (duas tabelas, PK e FK).
2. No **Query editor**, mostre as colunas das tabelas:
```sql
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('cliente', 'transacao')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
```
3. Mostre a chave estrangeira:
```sql
SELECT fk.name AS fk,
       OBJECT_NAME(fk.parent_object_id) AS tabela_filha,
       COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS coluna,
       OBJECT_NAME(fk.referenced_object_id) AS tabela_pai
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id;
```
Resultado esperado: `fk_transacao_cliente`, tabela `transacao`, coluna `cliente_id`, apontando para `cliente`.

### 9.5 Parte 4 — Operações com o banco depois de cada uma

No PowerShell, na pasta do projeto, defina a URL base **uma vez**:
```powershell
$BASE = "https://app-dimdim-cloudops-562766.azurewebsites.net"
```
Depois de **cada** comando abaixo, vá ao Query editor e rode:
```sql
SELECT * FROM dbo.cliente;
SELECT * FROM dbo.transacao;
```

> Os comandos usam variáveis (`$c`, `$t`) para pegar o `id` gerado, então funcionam mesmo que os ids não comecem do 1.

**1. GET — listar clientes**
```powershell
Invoke-RestMethod -Uri "$BASE/clientes"
```

**2. POST — criar cliente**
```powershell
$c = Invoke-RestMethod -Method Post -Uri "$BASE/clientes" -ContentType "application/json" -Body '{"nome":"Maria Silva","email":"maria@dimdim.com"}'
$c
```
→ No banco: aparece uma linha em `cliente`.

**3. GET — buscar o cliente criado**
```powershell
Invoke-RestMethod -Uri "$BASE/clientes/$($c.id)"
```

**4. PUT — atualizar o cliente**
```powershell
Invoke-RestMethod -Method Put -Uri "$BASE/clientes/$($c.id)" -ContentType "application/json" -Body '{"nome":"Maria Souza","email":"maria@dimdim.com"}'
```
→ No banco: o nome mudou para "Maria Souza".

**5. POST — criar transação (liga ao cliente pela FK)**
```powershell
$corpo = @{ descricao = "Pagamento Pix"; valor = 150.75; cliente = @{ id = $c.id } } | ConvertTo-Json
$t = Invoke-RestMethod -Method Post -Uri "$BASE/transacoes" -ContentType "application/json" -Body $corpo
$t
```
→ No banco: aparece uma linha em `transacao`, com `cliente_id` igual ao id do cliente.

**6. GET — listar transações e transações do cliente**
```powershell
Invoke-RestMethod -Uri "$BASE/transacoes"
Invoke-RestMethod -Uri "$BASE/clientes/$($c.id)/transacoes"
```

**7. PUT — atualizar a transação**
```powershell
$corpo = @{ descricao = "Pagamento Pix (corrigido)"; valor = 200.00; cliente = @{ id = $c.id } } | ConvertTo-Json
Invoke-RestMethod -Method Put -Uri "$BASE/transacoes/$($t.id)" -ContentType "application/json" -Body $corpo
```
→ No banco: descrição e valor mudaram.

**8. Provar que a FK protege os dados (opcional, impressiona)**
Tente apagar o cliente que ainda tem transação. Deve dar erro **409 Conflict**:
```powershell
Invoke-RestMethod -Method Delete -Uri "$BASE/clientes/$($c.id)"
```
→ O banco recusa porque a transação depende do cliente. As duas linhas continuam lá.

**9. DELETE — apagar a transação e depois o cliente**
```powershell
Invoke-RestMethod -Method Delete -Uri "$BASE/transacoes/$($t.id)"
Invoke-RestMethod -Method Delete -Uri "$BASE/clientes/$($c.id)"
```
→ No banco: as linhas somem (confira depois de cada DELETE).

**Alternativa em um comando só:** o roteiro automático faz essas operações com uma pausa a cada passo para você mostrar o banco:
```powershell
.\requests\testar-api.ps1 -Base $BASE
```

### 9.6 Parte 5 — Mostrar o Application Insights

1. Faça algumas chamadas à API (as operações acima já servem).
2. Na aba do `appi-dimdim-cloudops`, mostre **Live metrics** (chamadas em tempo real) e **Transaction search** ou **Performance** (as requisições registradas). Os dados podem levar alguns minutos para aparecer.

### 9.7 Parte 6 — Mostrar o GitHub

Abra o repositório e mostre os itens exigidos: DDL (`database/schema.sql`), código-fonte (`src/`), script do CLI (`deploy.ps1`), How to (`README.md`) e JSON das operações (`requests/operacoes.json`).

### 9.8 Se algo der errado na hora

| Problema | O que fazer |
|---|---|
| A API demora muito na primeira chamada | Normal, o app "acorda". Espere até 1 minuto e tente de novo |
| `Invoke-RestMethod` dá erro 500 ou 503 | `az webapp restart --resource-group rg-dimdim-cp2-cloudops --name app-dimdim-cloudops-562766` e espere 1 minuto |
| Query editor não conecta | Use **Allowlist IP** no aviso do portal e tente de novo |
| Ver o que a aplicação está dizendo | `az webapp log tail --resource-group rg-dimdim-cp2-cloudops --name app-dimdim-cloudops-562766` (Ctrl+C para sair) |
| O PowerShell bloqueia o script | `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` |

### 9.9 Perguntas que podem aparecer (e respostas curtas)

| Pergunta | Resposta |
|---|---|
| O que é PaaS? | O Azure gerencia o servidor, o sistema e as atualizações. Nós só cuidamos da aplicação e dos dados |
| Por que o banco é PaaS e não instalado numa máquina? | Não precisamos administrar o SQL Server: backup, atualização e disponibilidade ficam com o Azure |
| O que é a chave estrangeira aqui? | `transacao.cliente_id` aponta para `cliente.id`. O banco impede criar transação de cliente inexistente e apagar cliente que ainda tem transação |
| Como a aplicação sabe a senha do banco? | Pelas *App settings* do Web App (variáveis de ambiente), configuradas pelo script. O código lê de `application.properties` |
| Como as tabelas foram criadas? | A aplicação executa o `schema.sql` ao subir. O mesmo DDL está em `database/schema.sql` |
| O que o Application Insights faz? | Monitora a aplicação: requisições, tempo de resposta e falhas |
| Como foi feito o deploy? | Pelo Azure CLI: o script cria os recursos e `az webapp deploy` envia o `app.jar` |
| Por que tentou várias regiões? | A assinatura só permite algumas regiões e algumas estão sem capacidade para SQL Server. O script tenta uma por vez |

## 10. Recursos criados no Azure

| Recurso | Nome |
|---|---|
| Resource Group | `rg-dimdim-cp2-cloudops` |
| SQL Server | `sql-dimdim-cloudops-562766` |
| Banco de dados | `dimdimdb` |
| Application Insights | `appi-dimdim-cloudops` |
| Log Analytics Workspace | `law-dimdim-cloudops` |
| Plano do App Service (Linux, B1) | `plan-dimdim-cloudops` |
| Web App (Java 17) | `app-dimdim-cloudops-562766` |

## 11. Problemas comuns

| O que aparece | Causa | O que fazer |
|---|---|---|
| `não pode ser carregado porque a execução de scripts foi desabilitada` | Política do PowerShell | Rode `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` e tente de novo |
| `RequestDisallowedByAzure ... disallowed by Azure` | A assinatura só permite certas regiões | Veja as permitidas com `az policy assignment list --query "[].{nome:displayName, regioes:parameters.listOfAllowedLocations.value}" -o json` e ajuste `$REGIOES` |
| `MissingSubscriptionRegistration ... Microsoft.Sql` | Serviço desligado na assinatura | O script já ativa; se falhar por permissão, peça ao responsável pela assinatura |
| `RegionDoesNotAllowProvisioning ... not accepting creation of new SQL servers` | A região está sem capacidade | O script tenta a próxima região da lista sozinho |
| `InvalidResourceLocation ... already exists in location` | Sobrou um SQL Server incompleto de tentativa anterior | O script apaga e tenta de novo; se persistir: `az sql server delete -g rg-dimdim-cp2-cloudops -n sql-dimdim-cloudops-562766 --yes` |
| `Maven nao encontrado e target\app.jar nao existe` | O `.jar` não foi gerado | Faça o Passo 2 |
| Página azul "Hey, Java developers!" | A aplicação ainda está iniciando | Espere 2 minutos e use Ctrl+F5 |
| Erro ao abrir o Query editor | O IP não está liberado no firewall do SQL | Use **Allowlist IP** no aviso do portal, ou rode de novo o `deploy.ps1` |
| Ver o log da aplicação | — | `az webapp log tail --resource-group rg-dimdim-cp2-cloudops --name app-dimdim-cloudops-562766` (Ctrl+C para sair) |

## 12. Rodar localmente (opcional, não é necessário para o deploy)

A aplicação precisa de um SQL Server. Defina as variáveis de ambiente e rode pelo Eclipse ou pelo Maven:

```powershell
$env:SPRING_DATASOURCE_URL = "jdbc:sqlserver://<servidor>:1433;database=<banco>;encrypt=true;trustServerCertificate=true"
$env:SPRING_DATASOURCE_USERNAME = "<usuario>"
$env:SPRING_DATASOURCE_PASSWORD = "<senha>"
mvn spring-boot:run
```

Sem essas variáveis a aplicação não sobe (erro `URL must start with 'jdbc'`). No Azure elas são configuradas pelo `deploy.ps1`.

## 13. Custo e como apagar tudo

Enquanto os recursos existem, eles consomem créditos da assinatura (estimativa: cerca de US$ 0,60 por dia com tudo ligado; confirme em *Cost Management* no portal). Depois da avaliação, apague tudo:

```powershell
az group delete --name rg-dimdim-cp2-cloudops --yes --no-wait
```

Para recriar depois, basta rodar `.\deploy.ps1` de novo (leva uns 15 minutos).

## 14. Tecnologias

Java 17 · Spring Boot 3.3 · Spring Data JPA · Bean Validation · Maven · Azure CLI · Azure App Service (Linux, Java 17) · Azure SQL Database (SQL Server PaaS) · Application Insights
