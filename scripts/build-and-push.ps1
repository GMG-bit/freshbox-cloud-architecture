<#
.SYNOPSIS
    Build y Push de Imagenes Docker a Amazon ECR (Windows PowerShell)
.DESCRIPTION
    Construye las imagenes de los 5 microservicios de FreshBox SpA y las sube a Amazon ECR.
#>
[CmdletBinding()]
param (
    [string]$Region = "us-east-1",
    [string]$ProjectName = "freshbox"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " FreshBox Cloud Architecture - ECR Build & Push (PowerShell)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Obtener Account ID
$AccountId = aws sts get-caller-identity --query Account --output text
if (-not $AccountId) {
    Write-Error "No se pudo obtener el Account ID de AWS. Verifica tus credenciales."
}
Write-Host "AWS Account ID: $AccountId | Region: $Region" -ForegroundColor Green

# 2. Login ECR
Write-Host "[1/4] Autenticando Docker en Amazon ECR..." -ForegroundColor Yellow
$loginPwd = aws ecr get-login-password --region $Region
$loginPwd | docker login --username AWS --password-stdin "$AccountId.dkr.ecr.$Region.amazonaws.com"

# 3. Verificar y crear repositorios si faltan
$repos = @(
    "$ProjectName-frontend",
    "$ProjectName-get-products",
    "$ProjectName-create-product",
    "$ProjectName-update-product",
    "$ProjectName-delete-product"
)

Write-Host "[2/4] Verificando repositorios ECR..." -ForegroundColor Yellow
foreach ($repo in $repos) {
    aws ecr describe-repositories --repository-names $repo --region $Region 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Creando repositorio ECR $repo..." -ForegroundColor Gray
        aws ecr create-repository --repository-name $repo --region $Region | Out-Null
    }
}

# 4. Build de imagenes
Write-Host "[3/4] Construyendo imagenes Docker..." -ForegroundColor Yellow
docker build -t "$ProjectName-frontend:latest" ./app/microservicioFrontend
docker build -t "$ProjectName-get-products:latest" ./app/microserviciosBackend/get-products
docker build -t "$ProjectName-create-product:latest" ./app/microserviciosBackend/create-product
docker build -t "$ProjectName-update-product:latest" ./app/microserviciosBackend/update-product
docker build -t "$ProjectName-delete-product:latest" ./app/microserviciosBackend/delete-product

# 5. Tag y Push
Write-Host "[4/4] Etiquetando y subiendo imagenes a ECR..." -ForegroundColor Yellow
$services = @("frontend", "get-products", "create-product", "update-product", "delete-product")
foreach ($svc in $services) {
    $ecrUri = "$AccountId.dkr.ecr.$Region.amazonaws.com/$ProjectName-$svc`:latest"
    docker tag "$ProjectName-$svc`:latest" $ecrUri
    docker push $ecrUri
    Write-Host " -> Imagen $svc subida: $ecrUri" -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Build & Push completado con exito!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
