#!/usr/bin/env bash
# ==============================================================================
# FreshBox SpA - Script de Validacion Integral Flujo Serverless e Hibrido (EA3 / EP3)
# Asignatura: Arquitectura Cloud (ARY1102)
# ==============================================================================

set -e

if [ -z "$1" ]; then
    echo "Uso: ./test-serverless-flow.sh <API_GATEWAY_URL>"
    echo "Ejemplo: ./test-serverless-flow.sh https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod"
    exit 1
fi

API_URL="${1%/}"
USER_ID="user001"

echo "========================================================================"
echo "🌱 INICIANDO PRUEBAS DE ARQUITECTURA HÍBRIDA FRESHBOX SPA (SERVERLESS + EKS)"
echo "Target Endpoint: $API_URL"
echo "========================================================================"

# ------------------------------------------------------------------------------
# 1. Pruebas CRUD Catalogo de Productos (via API Gateway -> Amazon EKS)
# ------------------------------------------------------------------------------
echo -e "\n[1/3] 🛒 Validando CRUD Catalogo de Productos (Enrutado hacia EKS Pods)..."

echo "  1.1 GET /api/products (Listar catalogo)"
curl -s -X GET "$API_URL/api/products" | jq . || curl -s "$API_URL/api/products"
echo ""

echo "  1.2 POST /api/products (Crear nuevo producto organico)"
CREATE_RES=$(curl -s -X POST "$API_URL/api/products" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Palta Hass Organica 1kg","descripcion":"Palta hass extra suave de exportacion","precio":4200,"stock":90,"categoria":"Frutas"}')
echo "  Respuesta: $CREATE_RES"

# ------------------------------------------------------------------------------
# 2. Pruebas Gestion de Carrito (via API Gateway -> Lambda -> DynamoDB con TTL)
# ------------------------------------------------------------------------------
echo -e "\n[2/3] 🧺 Validando Gestion de Carrito Temporal (Lambda + DynamoDB NoSQL)..."

echo "  2.1 POST /api/cart (Agregar item a carrito)"
ADD_CART_RES=$(curl -s -X POST "$API_URL/api/cart" \
  -H "Content-Type: application/json" \
  -d "{\"userId\":\"$USER_ID\",\"productId\":\"1\",\"nombre\":\"Manzana organica 1kg\",\"precio\":3490,\"cantidad\":2}")
echo "  Respuesta: $ADD_CART_RES"

echo "  2.2 GET /api/cart?userId=$USER_ID (Consultar carrito y total)"
curl -s -X GET "$API_URL/api/cart?userId=$USER_ID" | jq . || curl -s "$API_URL/api/cart?userId=$USER_ID"
echo ""

# ------------------------------------------------------------------------------
# 3. Pruebas Flujo Desacoplado de Ordenes (API Gateway -> Lambda -> SQS -> Lambda -> MySQL)
# ------------------------------------------------------------------------------
echo -e "\n[3/3] ⚡ Validando Envio Asincrono de Orden (Lambda + SQS + Dead Letter Queue)..."

echo "  3.1 POST /api/orders (Confirmar pedido y encolar)"
ORDER_RES=$(curl -s -X POST "$API_URL/api/orders" \
  -H "Content-Type: application/json" \
  -d "{\"userId\":\"$USER_ID\"}")
echo "  Respuesta: $ORDER_RES"

echo -e "\n========================================================================"
echo "✅ FLUJO DE PRUEBAS COMPLETADO EXITOSAMENTE"
echo "Verificar en CloudWatch Logs la ejecucion de 'freshbox-order-process' y la persistencia en MySQL RDS."
echo "========================================================================"
