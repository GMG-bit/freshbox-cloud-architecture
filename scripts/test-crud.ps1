<#
.SYNOPSIS
    Pruebas CRUD sobre ALB Ingress en EKS (Windows PowerShell)
#>
[CmdletBinding()]
param (
    [string]$Namespace = "freshbox"
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " FreshBox Cloud Architecture - Pruebas CRUD via ALB Ingress" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Obtener ALB DNS
$albDns = kubectl get ingress freshbox-ingress -n $Namespace -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
if (-not $albDns) {
    $albDns = kubectl get ingress -n $Namespace -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>$null
}

if (-not $albDns) {
    Write-Error "No se pudo obtener el hostname del ALB Ingress. Verifica kubectl get ingress -n $Namespace"
}

Write-Host "ALB Hostname: $albDns" -ForegroundColor Green
$baseUrl = "http://$albDns"

# 2. GET
Write-Host "`n[2/5] GET $baseUrl/api/products" -ForegroundColor Yellow
Invoke-RestMethod -Uri "$baseUrl/api/products" -Method GET | ConvertTo-Json -Depth 3

# 3. POST
Write-Host "`n[3/5] POST $baseUrl/api/products" -ForegroundColor Yellow
$postBody = @{
    nombre      = "Manzanas Fuji Organicas"
    descripcion = "Bolsa 1kg cultivo limpio"
    precio      = 2490
    stock       = 60
    categoria   = "Frutas"
} | ConvertTo-Json

Invoke-RestMethod -Uri "$baseUrl/api/products" -Method POST -Body $postBody -ContentType "application/json" | ConvertTo-Json

# 4. PUT
Write-Host "`n[4/5] PUT $baseUrl/api/products/1" -ForegroundColor Yellow
$putBody = @{
    nombre      = "Manzanas Fuji Organicas Premium"
    descripcion = "Bolsa 1.2kg certificada"
    precio      = 2890
    stock       = 95
    categoria   = "Frutas"
} | ConvertTo-Json

Invoke-RestMethod -Uri "$baseUrl/api/products/1" -Method PUT -Body $putBody -ContentType "application/json" | ConvertTo-Json

# 5. DELETE
Write-Host "`n[5/5] DELETE $baseUrl/api/products/1" -ForegroundColor Yellow
Invoke-RestMethod -Uri "$baseUrl/api/products/1" -Method DELETE | ConvertTo-Json

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " Pruebas CRUD completadas con exito!" -ForegroundColor Green
