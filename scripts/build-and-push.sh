#!/bin/bash
# ==============================================================================
# FreshBox SpA - Build y Push de Imagenes Docker a Amazon ECR (EA2)
# ==============================================================================
set -e

REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="freshbox"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "=========================================================="
echo " FreshBox Cloud Architecture - ECR Build & Push"
echo " AWS Account: $ACCOUNT_ID | Region: $REGION"
echo "=========================================================="

# 1. Autenticacion en Amazon ECR
echo "[1/4] Autenticando Docker en Amazon ECR..."
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# 2. Creacion de repositorios si no existen
REPOS=("${PROJECT_NAME}-frontend" "${PROJECT_NAME}-get-products" "${PROJECT_NAME}-create-product" "${PROJECT_NAME}-update-product" "${PROJECT_NAME}-delete-product")

echo "[2/4] Verificando repositorios ECR..."
for REPO in "${REPOS[@]}"; do
    aws ecr describe-repositories --repository-names "$REPO" --region "$REGION" >/dev/null 2>&1 || \
    aws ecr create-repository --repository-name "$REPO" --region "$REGION" >/dev/null
done

# 3. Build de imagenes Docker
echo "[3/4] Construyendo imagenes Docker..."
docker build -t "${PROJECT_NAME}-frontend:latest" ./app/microservicioFrontend
docker build -t "${PROJECT_NAME}-get-products:latest" ./app/microserviciosBackend/get-products
docker build -t "${PROJECT_NAME}-create-product:latest" ./app/microserviciosBackend/create-product
docker build -t "${PROJECT_NAME}-update-product:latest" ./app/microserviciosBackend/update-product
docker build -t "${PROJECT_NAME}-delete-product:latest" ./app/microserviciosBackend/delete-product

# 4. Tag y Push a ECR
echo "[4/4] Etiquetando y subiendo imagenes a ECR..."
SERVICES=("frontend" "get-products" "create-product" "update-product" "delete-product")

for SVC in "${SERVICES[@]}"; do
    ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${PROJECT_NAME}-$SVC:latest"
    docker tag "${PROJECT_NAME}-$SVC:latest" "$ECR_URI"
    docker push "$ECR_URI"
    echo " -> Imagen $SVC subida exitosamente: $ECR_URI"
done

echo "=========================================================="
echo " Todas las imagenes fueron publicadas en Amazon ECR"
echo " Proximo paso: Ejecutar ./scripts/deploy-k8s.sh"
echo "=========================================================="
