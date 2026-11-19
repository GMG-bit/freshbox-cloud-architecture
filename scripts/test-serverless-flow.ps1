# ==============================================================================
# FreshBox SpA - Script PowerShell de Validacion Integral Flujo Serverless e Hibrido (EP3)
# Asignatura: Arquitectura Cloud (ARY1102)
# ==============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$ApiUrl,
    [string]$UserId = "user001"
)

$ApiUrl = $ApiUrl.TrimEnd('/')

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " INICIANDO PRUEBAS DE ARQUITECTURA HIBRIDA FRESHBOX SPA (SERVERLESS + EKS)" -ForegroundColor Cyan
Write-Host "Target Endpoint: $ApiUrl" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan

# 1. CRUD Catalogo Productos (API Gateway -> EKS ALB)
Write-Host "`n[1/3] Validando CRUD Catalogo de Productos (Enrutado hacia EKS Pods)..." -ForegroundColor Yellow
try {
    Write-Host "  1.1 GET /api/products (Listar catalogo)" -ForegroundColor White
    $resGet = Invoke-RestMethod -Uri "$ApiUrl/api/products" -Method Get
    $resGet | ConvertTo-Json -Depth 3 | Write-Host
} catch {
    Write-Host "  [Error en GET /api/products]: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    Write-Host "  1.2 POST /api/products (Crear nuevo producto)" -ForegroundColor White
    $newProd = @{
        nombre = "Palta Hass Organica 1kg"
        descripcion = "Palta hass fresca de exportacion"
        precio = 4200
        stock = 90
        categoria = "Frutas"
    } | ConvertTo-Json
    $resPost = Invoke-RestMethod -Uri "$ApiUrl/api/products" -Method Post -Body $newProd -ContentType "application/json"
    $resPost | ConvertTo-Json | Write-Host
} catch {
    Write-Host "  [Aviso/Error en POST /api/products]: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 2. Carrito en DynamoDB (API Gateway -> Lambda Cart -> DynamoDB)
Write-Host "`n[2/3] Validando Gestion de Carrito Temporal (Lambda + DynamoDB NoSQL)..." -ForegroundColor Yellow
try {
    Write-Host "  2.1 POST /api/cart (Agregar item a carrito)" -ForegroundColor White
    $cartItem = @{
        userId = $UserId
        productId = "1"
        nombre = "Manzana organica 1kg"
        precio = 3490
        cantidad = 2
    } | ConvertTo-Json
    $resCartPost = Invoke-RestMethod -Uri "$ApiUrl/api/cart" -Method Post -Body $cartItem -ContentType "application/json"
    $resCartPost | ConvertTo-Json | Write-Host

    Write-Host "  2.2 GET /api/cart?userId=$UserId (Consultar carrito y total)" -ForegroundColor White
    $resCartGet = Invoke-RestMethod -Uri "$ApiUrl/api/cart?userId=$UserId" -Method Get
    $resCartGet | ConvertTo-Json -Depth 3 | Write-Host
} catch {
    Write-Host "  [Error en Carrito]: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Flujo Desacoplado de Ordenes (API Gateway -> Lambda Create-Order -> SQS -> Lambda Process-Order -> RDS MySQL)
Write-Host "`n[3/3] Validando Envio Asincrono de Orden (Lambda + SQS + Dead Letter Queue)..." -ForegroundColor Yellow
try {
    Write-Host "  3.1 POST /api/orders (Confirmar pedido y encolar)" -ForegroundColor White
    $orderBody = @{
        userId = $UserId
    } | ConvertTo-Json
    $resOrder = Invoke-RestMethod -Uri "$ApiUrl/api/orders" -Method Post -Body $orderBody -ContentType "application/json"
    $resOrder | ConvertTo-Json | Write-Host
} catch {
    Write-Host "  [Error en Crear Orden]: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n========================================================================" -ForegroundColor Green
Write-Host " FLUJO DE PRUEBAS COMPLETADO" -ForegroundColor Green
Write-Host "Revisa en la consola de AWS: SQS (mensajes recibidos/procesados), CloudWatch Logs y la tabla ordenes en RDS." -ForegroundColor Green
Write-Host "========================================================================" -ForegroundColor Green
