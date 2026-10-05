<#
.SYNOPSIS
    Automatizacion de Despliegue en Amazon EKS (Windows PowerShell)
.DESCRIPTION
    Configura kubectl, sustituye variables en los manifiestos YAML y aplica todos los recursos en EKS.
#>
[CmdletBinding()]
param (
    [string]$Region = "us-east-1",
    [string]$ProjectName = "freshbox",
    [string]$Namespace = "freshbox"
)

$ErrorActionPreference = "Stop"

$ClusterName = "$ProjectName-cluster"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " FreshBox Cloud Architecture - EKS Deploy (PowerShell)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Account ID
$AccountId = aws sts get-caller-identity --query Account --output text
Write-Host "[1/6] Configurando kubeconfig para EKS Cluster '$ClusterName'..." -ForegroundColor Yellow
aws eks update-kubeconfig --region $Region --name $ClusterName

# 2. Endpoint de RDS
Write-Host "[2/6] Obteniendo Endpoint de Amazon RDS Multi-AZ..." -ForegroundColor Yellow
$RdsEndpoint = ""
if (Test-Path "terraform\terraform.tfstate") {
    Push-Location terraform
    try { $RdsEndpoint = (terraform output -raw rds_address 2>$null) } catch {}
    Pop-Location
}

if (-not $RdsEndpoint) {
    try {
        $RdsEndpoint = aws rds describe-db-instances --db-instance-identifier "$ProjectName-db" --region $Region --query "DBInstances[0].Endpoint.Address" --output text 2>$null
    } catch {}
}

if (-not $RdsEndpoint -or $RdsEndpoint -eq "None") {
    Write-Warning "No se pudo obtener el endpoint de RDS. Usando valor por defecto freshbox-db.local"
    $RdsEndpoint = "freshbox-db.local"
}
Write-Host "RDS Endpoint: $RdsEndpoint" -ForegroundColor Green

# 3. Directorio temporal para sustitucion
$tmpDir = Join-Path $env:TEMP "freshbox-k8s-tmp"
if (Test-Path $tmpDir) { Remove-Item -Path $tmpDir -Recurse -Force }
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
Copy-Item -Path "k8s\*" -Destination $tmpDir -Recurse

Write-Host "[3/6] Inyectando Account ID ($AccountId) y RDS Endpoint ($RdsEndpoint)..." -ForegroundColor Yellow
Get-ChildItem -Path $tmpDir -Filter "*.yaml" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content.Replace("<ACCOUNT_ID>", $AccountId).Replace("<RDS_ENDPOINT>", $RdsEndpoint)
    Set-Content -Path $_.FullName -Value $content -NoNewline
}

# 4. Aplicar manifiestos
Write-Host "[4/6] Aplicando manifiestos Kubernetes..." -ForegroundColor Yellow
kubectl apply -f (Join-Path $tmpDir "namespace.yaml")
kubectl apply -f (Join-Path $tmpDir "configmap.yaml")
kubectl apply -f (Join-Path $tmpDir "secret.yaml")

kubectl apply -f (Join-Path $tmpDir "frontend-deployment.yaml")
kubectl apply -f (Join-Path $tmpDir "get-products-deployment.yaml")
kubectl apply -f (Join-Path $tmpDir "create-product-deployment.yaml")
kubectl apply -f (Join-Path $tmpDir "update-product-deployment.yaml")
kubectl apply -f (Join-Path $tmpDir "delete-product-deployment.yaml")

kubectl apply -f (Join-Path $tmpDir "ingress.yaml")
kubectl apply -f (Join-Path $tmpDir "hpa-frontend.yaml")
kubectl apply -f (Join-Path $tmpDir "hpa-get-products.yaml")
kubectl apply -f (Join-Path $tmpDir "hpa-create-product.yaml")
kubectl apply -f (Join-Path $tmpDir "hpa-update-product.yaml")
kubectl apply -f (Join-Path $tmpDir "hpa-delete-product.yaml")

# 5. Resumen
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Resumen de Despliegue en Kubernetes (EKS)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
kubectl get pods -n $Namespace -o wide
Write-Host "----------------------------------------------------------"
kubectl get services -n $Namespace
Write-Host "----------------------------------------------------------"
kubectl get ingress -n $Namespace
Write-Host "----------------------------------------------------------"
kubectl get hpa -n $Namespace
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Despliegue finalizado con exito!" -ForegroundColor Green
