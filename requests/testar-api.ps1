# Roteiro de teste da API, passo a passo (pausa a cada operacao para voce mostrar o banco).
# Uso:  .\requests\testar-api.ps1 -Base https://SEU-WEBAPP.azurewebsites.net
# Local: .\requests\testar-api.ps1 -Base http://localhost:8080
param([Parameter(Mandatory = $true)][string]$Base)

function Passo($titulo, $metodo, $url, $corpo) {
    Write-Host ""
    Write-Host "=== $titulo ($metodo $url) ===" -ForegroundColor Cyan
    try {
        if ($corpo) {
            $json = $corpo | ConvertTo-Json -Depth 5
            Write-Host $json
            $r = Invoke-RestMethod -Method $metodo -Uri "$Base$url" -ContentType "application/json" -Body $json
        } else {
            $r = Invoke-RestMethod -Method $metodo -Uri "$Base$url"
        }
        if ($r) { $r | ConvertTo-Json -Depth 5 }
        else { Write-Host "(sem corpo - operacao concluida)" }
    } catch {
        Write-Host "ERRO: $($_.Exception.Message)" -ForegroundColor Red
    }
    Read-Host "Confira o banco (SELECT * FROM cliente / transacao) e aperte ENTER para continuar"
}

Passo "Listar clientes"        "GET"    "/clientes"            $null
Passo "Criar cliente"          "POST"   "/clientes"            @{ nome = "Maria Silva"; email = "maria@dimdim.com" }
Passo "Buscar cliente"         "GET"    "/clientes/1"          $null
Passo "Atualizar cliente"      "PUT"    "/clientes/1"          @{ nome = "Maria Souza"; email = "maria@dimdim.com" }
Passo "Criar transacao"        "POST"   "/transacoes"          @{ descricao = "Pagamento Pix"; valor = 150.75; cliente = @{ id = 1 } }
Passo "Listar transacoes"      "GET"    "/transacoes"          $null
Passo "Transacoes do cliente"  "GET"    "/clientes/1/transacoes" $null
Passo "Atualizar transacao"    "PUT"    "/transacoes/1"        @{ descricao = "Pagamento Pix (corrigido)"; valor = 200.00; cliente = @{ id = 1 } }
Passo "Apagar transacao"       "DELETE" "/transacoes/1"        $null
Passo "Apagar cliente"         "DELETE" "/clientes/1"          $null
Write-Host "Fim do roteiro." -ForegroundColor Green
