# ==============================================================================
# Configurações do Ambiente
# ==============================================================================
$TenantId     = ""
$ClientId     = ""
$ClientSecret = ""
$ZabbixServer = "127.0.0.1"
$ZabbixHost   = "Exchange365"
$TempFile     = "/tmp/zabbix_exchange_payload.txt"

# ==============================================================================
# 1. Autenticação na Microsoft Graph API via App-Only
# ==============================================================================
$Body = @{
    client_id     = $ClientId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $ClientSecret
    grant_type    = "client_credentials"
}

$TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Method Post -Body $Body
$Token = $TokenResponse.access_token

if (-not $Token) {
    Write-Error "Falha ao autenticar na API da Microsoft."
    exit 1
}

$Headers = @{
    "Authorization" = "Bearer $Token"
}

# ==============================================================================
# 2. Coleta de Dados (Relatório de Uso de Caixas de Correio)
# ==============================================================================
$ReportUri = "https://graph.microsoft.com/v1.0/reports/getMailboxUsageDetail(period='D7')"
$CsvData = Invoke-RestMethod -Uri $ReportUri -Headers $Headers -Method Get

$CsvLines = $CsvData -split "`n"
$LLDArray = @()
$SenderData = @()

for ($i = 1; $i -lt$CsvLines.Count; $i++) {$Line = $CsvLines[$i].Trim()
    if ([string]::IsNullOrWhiteSpace($Line)) { continue }

    $Columns = $Line -split ',(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)'
    
    if ($Columns.Count -ge 11) {
        $Email =$Columns[1].Trim('"')
        $DisplayName =$Columns[2].Trim('"')
        $StorageUsed =$Columns[10].Trim('"')

        if (-not [string]::IsNullOrEmpty($Email) -and$StorageUsed -match '^\d+$') {$LLDArray += [PSCustomObject]@{
                "{#MAILBOX}" = $Email
                "{#NOME}"    = $DisplayName
            }

            $SenderData += "$ZabbixHost exchange.mailbox.size[$Email]$StorageUsed"
        }
    }
}

# ==============================================================================
# 3. Montagem do Payload para o Zabbix
# ==============================================================================
$JSONDescoberta = @{ data =$LLDArray } | ConvertTo-Json -Depth 3 -Compress

$Payload = "$ZabbixHost exchange.discovery $JSONDescoberta" + "`r`n" + ($SenderData -join "`r`n")
$Payload \vert{} Out-File -FilePath$TempFile -Encoding utf8 -Force

# ==============================================================================
# 4. Envio via zabbix_sender e Limpeza
# ==============================================================================
zabbix_sender -z $ZabbixServer -i$TempFile
Remove-Item -Path $TempFile -Force
