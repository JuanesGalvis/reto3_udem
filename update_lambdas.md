# Actualizar Lambdas modificadas

Comandos para empaquetar, subir a S3 y actualizar las funciones Lambda que fueron modificadas.

> **Nota:** Ajusta `STAGE` y `REGION` según tu ambiente. Los comandos asumen que estás en la raíz del proyecto.

## Variables

```bash
STAGE="dev"
REGION="us-east-1"
BUCKET=$(aws cloudformation list-exports --region $REGION --query "Exports[?Name=='reto3-${STAGE}-lambda-code-bucket'].Value" --output text)
echo "Bucket: $BUCKET"
```

## 1. Empaquetar las Lambdas modificadas

```bash
mkdir -p zips

cd codes/auth-signup && zip -r ../../zips/auth-signup.zip . && cd ../..
cd codes/buyer-reserve-seat && zip -r ../../zips/buyer-reserve-seat.zip . && cd ../..
cd codes/buyer-cancel-reservation && zip -r ../../zips/buyer-cancel-reservation.zip . && cd ../..
cd codes/buyer-confirm-attendance && zip -r ../../zips/buyer-confirm-attendance.zip . && cd ../..
cd codes/buyer-edit-reservation && zip -r ../../zips/buyer-edit-reservation.zip . && cd ../..
```

## 2. Subir ZIPs a S3

```bash
aws s3 cp zips/auth-signup.zip s3://$BUCKET/lambdas/auth-signup.zip --region $REGION
aws s3 cp zips/buyer-reserve-seat.zip s3://$BUCKET/lambdas/buyer-reserve-seat.zip --region $REGION
aws s3 cp zips/buyer-cancel-reservation.zip s3://$BUCKET/lambdas/buyer-cancel-reservation.zip --region $REGION
aws s3 cp zips/buyer-confirm-attendance.zip s3://$BUCKET/lambdas/buyer-confirm-attendance.zip --region $REGION
aws s3 cp zips/buyer-edit-reservation.zip s3://$BUCKET/lambdas/buyer-edit-reservation.zip --region $REGION
```

## 3. Actualizar el código de las funciones Lambda

```bash
aws lambda update-function-code --function-name reto3-${STAGE}-auth-signup --s3-bucket $BUCKET --s3-key lambdas/auth-signup.zip --region $REGION
aws lambda update-function-code --function-name reto3-${STAGE}-buyer-reserve-seat --s3-bucket $BUCKET --s3-key lambdas/buyer-reserve-seat.zip --region $REGION
aws lambda update-function-code --function-name reto3-${STAGE}-buyer-cancel-reservation --s3-bucket $BUCKET --s3-key lambdas/buyer-cancel-reservation.zip --region $REGION
aws lambda update-function-code --function-name reto3-${STAGE}-buyer-confirm-attendance --s3-bucket $BUCKET --s3-key lambdas/buyer-confirm-attendance.zip --region $REGION
aws lambda update-function-code --function-name reto3-${STAGE}-buyer-edit-reservation --s3-bucket $BUCKET --s3-key lambdas/buyer-edit-reservation.zip --region $REGION
```

## 4. Crear tabla `attendees` en Aurora (solo si no existe)

```bash
CLUSTER_ARN=$(aws cloudformation list-exports --region $REGION --query "Exports[?Name=='reto3-${STAGE}-aurora-cluster-arn'].Value" --output text)
SECRET_ARN=$(aws cloudformation list-exports --region $REGION --query "Exports[?Name=='reto3-${STAGE}-aurora-secret-arn'].Value" --output text)
DB_NAME="reto3db"

aws rds-data execute-statement \
  --resource-arn "$CLUSTER_ARN" \
  --secret-arn "$SECRET_ARN" \
  --database "$DB_NAME" \
  --region $REGION \
  --sql "CREATE TABLE IF NOT EXISTS attendees (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
  )"
```

## Script todo-en-uno

```bash
#!/bin/bash
set -e

STAGE="dev"
REGION="us-east-1"
BUCKET=$(aws cloudformation list-exports --region $REGION --query "Exports[?Name=='reto3-${STAGE}-lambda-code-bucket'].Value" --output text)
CLUSTER_ARN=$(aws cloudformation list-exports --region $REGION --query "Exports[?Name=='reto3-${STAGE}-aurora-cluster-arn'].Value" --output text)
SECRET_ARN=$(aws cloudformation list-exports --region $REGION --query "Exports[?Name=='reto3-${STAGE}-aurora-secret-arn'].Value" --output text)
DB_NAME="reto3db"

LAMBDAS=("auth-signup" "buyer-reserve-seat" "buyer-cancel-reservation" "buyer-confirm-attendance" "buyer-edit-reservation")

echo "=== Bucket: $BUCKET ==="
mkdir -p zips

# Empaquetar, subir y actualizar
for func in "${LAMBDAS[@]}"; do
  echo "--- Procesando: $func ---"
  (cd "codes/$func" && zip -r "../../zips/${func}.zip" .)
  aws s3 cp "zips/${func}.zip" "s3://$BUCKET/lambdas/${func}.zip" --region $REGION
  aws lambda update-function-code \
    --function-name "reto3-${STAGE}-${func}" \
    --s3-bucket "$BUCKET" \
    --s3-key "lambdas/${func}.zip" \
    --region $REGION
  echo "OK: $func actualizada"
done

# Crear tabla attendees si no existe
echo "--- Creando tabla attendees ---"
aws rds-data execute-statement \
  --resource-arn "$CLUSTER_ARN" \
  --secret-arn "$SECRET_ARN" \
  --database "$DB_NAME" \
  --region $REGION \
  --sql "CREATE TABLE IF NOT EXISTS attendees (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
  )"

echo "=== Todas las Lambdas actualizadas y tabla attendees creada ==="
```
