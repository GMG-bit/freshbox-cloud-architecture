#!/bin/bash
# ==============================================================================
# FreshBox SpA - Pruebas Funcionales CRUD via ALB Ingress en EKS (EA2)
# ==============================================================================
set -e

NAMESPACE="freshbox"

echo "=========================================================="
echo " FreshBox Cloud Architecture - Pruebas CRUD via ALB Ingress"
echo "=========================================================="

# 1. Obtener DNS del ALB
echo "[1/5] Obteniendo hostname DNS del Application Load Balancer..."
ALB_DNS=$(kubectl get ingress freshbox-ingress -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -z "$ALB_DNS" ]; then
    echo "Consultando Ingress generico en namespace $NAMESPACE..."
    ALB_DNS=$(kubectl get ingress -n "$NAMESPACE" -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
fi

if [ -z "$ALB_DNS" ]; then
    echo "Consultando Service LoadBalancer de frontend en namespace $NAMESPACE..."
    ALB_DNS=$(kubectl get svc frontend -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
fi

if [ -z "$ALB_DNS" ]; then
    echo "AVISO: No se detecto hostname publico de ALB asignado todavia (toma ~2 minutos)."
    echo "Puedes volver a ejecutar este script en 60 segundos."
    exit 0
fi

echo "ALB Hostname: $ALB_DNS"
BASE_URL="http://$ALB_DNS"

# 2. Prueba GET - Listar productos
echo ""
echo "[2/5] GET $BASE_URL/api/products (Listar catalogo)"
curl -s -i "$BASE_URL/api/products" | head -n 25

# 3. Prueba POST - Crear producto organico
echo ""
echo "[3/5] POST $BASE_URL/api/products (Crear producto)"
curl -s -i -X POST "$BASE_URL/api/products" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Manzanas Fuji Organicas","descripcion":"Bolsa 1kg cultivo limpio","precio":2490,"stock":60,"categoria":"Frutas"}'

# 4. Prueba PUT - Modificar producto
echo ""
echo "[4/5] PUT $BASE_URL/api/products/1 (Modificar producto)"
curl -s -i -X PUT "$BASE_URL/api/products/1" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Manzanas Fuji Organicas Premium","descripcion":"Bolsa 1.2kg certificada","precio":2890,"stock":95,"categoria":"Frutas"}'

# 5. Prueba DELETE - Eliminar producto de prueba
echo ""
echo "[5/5] DELETE $BASE_URL/api/products/1 (Eliminar producto)"
curl -s -i -X DELETE "$BASE_URL/api/products/1"

echo ""
echo "=========================================================="
echo " Pruebas CRUD completadas exitosamente!"
echo "=========================================================="
