$GRUPO    = "cloudops"
$RM       = "562766"
$RGLOC    = "brazilsouth"
$REGIOES  = @("francecentral","southcentralus","mexicocentral","southafricanorth")

$RG       = "rg-dimdim-cp2-$GRUPO"
$SQLSRV   = "sql-dimdim-$GRUPO-$RM"
$DB       = "dimdimdb"
$SQLUSER  = "sqladmin"
$SQLPASS  = "DimDimCp2Azure2026x9"
$LAW      = "law-dimdim-$GRUPO"
$INSIGHTS = "appi-dimdim-$GRUPO"
$PLAN     = "plan-dimdim-$GRUPO"
$WEBAPP   = "app-dimdim-$GRUPO-$RM"

function Check {
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO no passo anterior. Leia a mensagem acima e corrija antes de continuar." -ForegroundColor Red
        exit 1
    }
}

Write-Host "== Login no Azure (use a conta do Felipe) ==" -ForegroundColor Cyan
az logout 2>$null
az login; Check
$CONTA = az account show --query "{usuario:user.name, assinatura:name}" -o tsv; Check
Write-Host ""
Write-Host "Conta logada / assinatura:" -ForegroundColor Yellow
Write-Host $CONTA
$RESP = Read-Host "Esta e a conta do Felipe? (s/n)"
if ($RESP -ne "s") {
    Write-Host "Cancelado. Rode de novo e entre com a conta do Felipe." -ForegroundColor Red
    exit 1
}

az config set extension.use_dynamic_install=yes_without_prompt extension.dynamic_install_allow_preview=true --only-show-errors
az extension add --name application-insights --upgrade --only-show-errors

Write-Host "== Ativando servicos na assinatura (pode levar 1 a 3 minutos) ==" -ForegroundColor Cyan
foreach ($NS in @("Microsoft.Sql","Microsoft.Web","Microsoft.Insights","Microsoft.OperationalInsights","Microsoft.AlertsManagement")) {
    Write-Host "Registrando $NS ..." -ForegroundColor Yellow
    az provider register --namespace $NS --wait; Check
}

Write-Host "== Resource Group ==" -ForegroundColor Cyan
az group create --name $RG --location $RGLOC; Check

Write-Host "== SQL Server e Banco ==" -ForegroundColor Cyan
$LOCATION = $null
$ESTADO = az sql server show --resource-group $RG --name $SQLSRV --query state -o tsv 2>$null
if ($ESTADO -eq "Ready") {
    $LOCATION = az sql server show --resource-group $RG --name $SQLSRV --query location -o tsv
} elseif ($ESTADO) {
    Write-Host "Apagando SQL Server incompleto de tentativa anterior ..." -ForegroundColor Yellow
    az sql server delete --resource-group $RG --name $SQLSRV --yes 2>$null
    Start-Sleep -Seconds 20
}
if (-not $LOCATION) {
    foreach ($R in $REGIOES) {
        Write-Host "Tentando criar o SQL Server em $R ..." -ForegroundColor Yellow
        az sql server create --resource-group $RG --name $SQLSRV --location $R --admin-user $SQLUSER --admin-password $SQLPASS
        if ($LASTEXITCODE -eq 0) { $LOCATION = $R; break }
        az sql server delete --resource-group $RG --name $SQLSRV --yes 2>$null
        Start-Sleep -Seconds 20
    }
}
if (-not $LOCATION) {
    Write-Host "Nenhuma regiao aceitou criar o SQL Server. Me mande as mensagens de erro acima." -ForegroundColor Red
    exit 1
}
Write-Host "SQL Server na regiao: $LOCATION" -ForegroundColor Green
az sql db create --resource-group $RG --server $SQLSRV --name $DB --service-objective Basic; Check

az sql server firewall-rule create --resource-group $RG --server $SQLSRV --name AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0; Check

$MEUIP = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
az sql server firewall-rule create --resource-group $RG --server $SQLSRV --name MeuIP --start-ip-address $MEUIP --end-ip-address $MEUIP; Check

Write-Host "== Application Insights ==" -ForegroundColor Cyan
az monitor log-analytics workspace create --resource-group $RG --workspace-name $LAW --location $LOCATION; Check
$LAWID = az monitor log-analytics workspace show --resource-group $RG --workspace-name $LAW --query id -o tsv; Check
az monitor app-insights component create --app $INSIGHTS --resource-group $RG --location $LOCATION --kind web --application-type web --workspace $LAWID; Check
$AICONN = az monitor app-insights component show --app $INSIGHTS --resource-group $RG --query connectionString -o tsv; Check

Write-Host "== App Service Plan e Web App ==" -ForegroundColor Cyan
az appservice plan create --name $PLAN --resource-group $RG --location $LOCATION --is-linux --sku B1; Check
az webapp create --name $WEBAPP --resource-group $RG --plan $PLAN --runtime "JAVA:17-java17"; Check

Write-Host "== Configuracoes (App settings) ==" -ForegroundColor Cyan
$JDBC = "jdbc:sqlserver://$SQLSRV.database.windows.net:1433;database=$DB;encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"
az webapp config appsettings set --name $WEBAPP --resource-group $RG --settings "SPRING_DATASOURCE_URL=$JDBC" "SPRING_DATASOURCE_USERNAME=$SQLUSER" "SPRING_DATASOURCE_PASSWORD=$SQLPASS" "WEBSITES_PORT=8080" "APPLICATIONINSIGHTS_CONNECTION_STRING=$AICONN" "ApplicationInsightsAgent_EXTENSION_VERSION=~3" | Out-Null; Check

Write-Host "== Build (Maven) ==" -ForegroundColor Cyan
if (Get-Command mvn -ErrorAction SilentlyContinue) {
    mvn clean package -DskipTests; Check
} elseif (Test-Path "target\app.jar") {
    Write-Host "mvn nao encontrado: usando o target\app.jar que ja existe." -ForegroundColor Yellow
} else {
    Write-Host "Maven nao encontrado e target\app.jar nao existe. No Eclipse: Run As > Maven build... > clean package -DskipTests." -ForegroundColor Red
    exit 1
}

Write-Host "== Deploy do .jar ==" -ForegroundColor Cyan
az webapp deploy --resource-group $RG --name $WEBAPP --src-path target\app.jar --type jar; Check

Write-Host ""
Write-Host "PRONTO!" -ForegroundColor Green
Write-Host "URL da API : https://$WEBAPP.azurewebsites.net"
Write-Host "Teste      : https://$WEBAPP.azurewebsites.net/clientes"
Write-Host "Banco      : portal Azure > $SQLSRV > $DB > Query editor (usuario $SQLUSER)"
Write-Host "Insights   : portal Azure > $INSIGHTS"
Write-Host "Para apagar tudo no fim: az group delete --name $RG --yes --no-wait"
