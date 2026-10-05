#!/bin/bash
# ==============================================================================
# FreshBox SpA - Automatizacion de Despliegue en Amazon EKS (EA2)
# ==============================================================================
set -e

REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="freshbox"
CLUSTER_NAME="${PROJECT_NAME}-cluster"
NAMESPACE="freshbox"

echo "=========================================================="
echo " FreshBox Cloud Architecture - EKS Deployment Automation"
echo "=========================================================="

# 1. Obtener Account ID y configurar kubeconfig
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "[1/6] Configurando kubeconfig para EKS Cluster '$CLUSTER_NAME'..."
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"

# 2. Obtener Endpoint de RDS MySQL
echo "[2/6] Obteniendo Endpoint de Amazon RDS Multi-AZ..."
if [ -d "terraform" ]; then
    RDS_ENDPOINT=$(cd terraform && terraform output -raw rds_address 2>/dev/null || echo "")
fi

if [ -z "$RDS_ENDPOINT" ]; then
    echo "Consultando endpoint de RDS via AWS CLI..."
    RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier "${PROJECT_NAME}-db" --region "$REGION" --query "DBInstances[0].Endpoint.Address" --output text 2>/dev/null || echo "")
fi

if [ -z "$RDS_ENDPOINT" ] || [ "$RDS_ENDPOINT" == "None" ]; then
    echo "ADVERTENCIA: No se encontro el endpoint de RDS. Usando placeholder o variable DB_HOST."
    RDS_ENDPOINT="freshbox-db.local"
fi
echo "RDS Endpoint: $RDS_ENDPOINT"

# 3. Preparar manifiestos temporales con sustitucion de variables
TMP_K8S_DIR="/tmp/freshbox-k8s"
mkdir -p "$TMP_K8S_DIR"
cp -r k8s/* "$TMP_K8S_DIR/"

echo "[3/6] Inyectando Account ID ($ACCOUNT_ID) y RDS Endpoint ($RDS_ENDPOINT)..."
sed -i "s|<ACCOUNT_ID>|$ACCOUNT_ID|g" "$TMP_K8S_DIR"/*.yaml
sed -i "s|<RDS_ENDPOINT>|$RDS_ENDPOINT|g" "$TMP_K8S_DIR"/configmap.yaml

# 4. Aplicar manifiestos en orden
echo "[4/6] Aplicando manifiestos Kubernetes..."
kubectl apply -f "$TMP_K8S_DIR/namespace.yaml"
kubectl apply -f "$TMP_K8S_DIR/configmap.yaml"
kubectl apply -f "$TMP_K8S_DIR/secret.yaml"

# Aplicar deployments y services
kubectl apply -f "$TMP_K8S_DIR/frontend-deployment.yaml"
kubectl apply -f "$TMP_K8S_DIR/get-products-deployment.yaml"
kubectl apply -f "$TMP_K8S_DIR/create-product-deployment.yaml"
kubectl apply -f "$TMP_K8S_DIR/update-product-deployment.yaml"
kubectl apply -f "$TMP_K8S_DIR/delete-product-deployment.yaml"

# Aplicar Ingress y HPAs
kubectl apply -f "$TMP_K8S_DIR/ingress.yaml"
kubectl apply -f "$TMP_K8S_DIR/hpa-frontend.yaml"
kubectl apply -f "$TMP_K8S_DIR/hpa-get-products.yaml"
kubectl apply -f "$TMP_K8S_DIR/hpa-create-product.yaml"
kubectl apply -f "$TMP_K8S_DIR/hpa-update-product.yaml"
kubectl apply -f "$TMP_K8S_DIR/hpa-delete-product.yaml"

# 5. Esperar disponibilidad de pods
echo "[5/6] Verificando despliegue de Pods (10 pods requeridos en EA2)..."
kubectl rollout status deployment/frontend -n "$NAMESPACE" --timeout=120s || true
kubectl rollout status deployment/get-products -n "$NAMESPACE" --timeout=120s || true
kubectl rollout status deployment/create-product -n "$NAMESPACE" --timeout=120s || true
kubectl rollout status deployment/update-product -n "$NAMESPACE" --timeout=120s || true
kubectl rollout status deployment/delete-product -n "$NAMESPACE" --timeout=120s || true

# 6. Resumen de recursos
echo "=========================================================="
echo " Resumen de Despliegue en Kubernetes (EKS)"
echo "=========================================================="
kubectl get pods -n "$NAMESPACE" -o wide
echo "----------------------------------------------------------"
kubectl get services -n "$NAMESPACE"
echo "----------------------------------------------------------"
kubectl get ingress -n "$NAMESPACE"
echo "----------------------------------------------------------"
kubectl get hpa -n "$NAMESPACE"
echo "=========================================================="
echo " Despliegue finalizado!"
echo " Para probar el API ejecuta: ./scripts/test-crud.sh"
echo "=========================================================="
