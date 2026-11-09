import json
import os
import time
import boto3
from decimal import Decimal
from boto3.dynamodb.conditions import Key

# Inicializacion de clientes AWS
dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('DYNAMODB_TABLE', 'freshbox-cart')
table = dynamodb.Table(TABLE_NAME)

CORS_HEADERS = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization'
}

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return int(obj) if obj % 1 == 0 else float(obj)
    raise TypeError

def lambda_handler(event, context):
    """
    Gestion de Carrito Temporal en DynamoDB con TTL (24 horas)
    Rutas:
      - GET /api/cart?userId=...
      - POST /api/cart  (body: {userId, productId, nombre, precio, cantidad})
      - DELETE /api/cart/{productId}?userId=...
    """
    http_method = event.get('httpMethod') or event.get('requestContext', {}).get('http', {}).get('method', 'GET')
    
    if http_method == 'OPTIONS':
        return {'statusCode': 200, 'headers': CORS_HEADERS, 'body': json.dumps({'message': 'OK'})}
    
    query_params = event.get('queryStringParameters') or {}
    path_params = event.get('pathParameters') or {}
    user_id = query_params.get('userId')
    
    try:
        # GET: Consultar carrito del usuario
        if http_method == 'GET':
            if not user_id:
                return {'statusCode': 400, 'headers': CORS_HEADERS, 'body': json.dumps({'error': 'userId es requerido'})}
            
            response = table.query(
                KeyConditionExpression=Key('userId').eq(user_id)
            )
            items = response.get('Items', [])
            total = sum(Decimal(str(item.get('precio', 0))) * Decimal(str(item.get('cantidad', 1))) for item in items)
            
            return {
                'statusCode': 200,
                'headers': CORS_HEADERS,
                'body': json.dumps({'userId': user_id, 'items': items, 'total': total}, default=decimal_default)
            }

        # POST: Agregar o actualizar producto en el carrito
        elif http_method == 'POST':
            body_str = event.get('body', '{}')
            body = json.loads(body_str) if isinstance(body_str, str) else body_str
            
            p_user_id = body.get('userId')
            p_product_id = str(body.get('productId'))
            nombre = body.get('nombre', 'Producto Organico')
            precio = Decimal(str(body.get('precio', 0)))
            cantidad = int(body.get('cantidad', 1))
            
            if not p_user_id or not p_product_id:
                return {'statusCode': 400, 'headers': CORS_HEADERS, 'body': json.dumps({'error': 'userId y productId son requeridos'})}
            
            # TTL de 24 horas (86400 segundos) para auto-expiracion de carritos abandonados
            ttl_timestamp = int(time.time()) + 86400
            
            item = {
                'userId': p_user_id,
                'productId': p_product_id,
                'nombre': nombre,
                'precio': precio,
                'cantidad': cantidad,
                'expire_at': ttl_timestamp
            }
            
            table.put_item(Item=item)
            return {
                'statusCode': 201,
                'headers': CORS_HEADERS,
                'body': json.dumps({'message': 'Producto agregado al carrito con exito', 'item': item}, default=decimal_default)
            }

        # DELETE: Eliminar producto del carrito
        elif http_method == 'DELETE':
            product_id = path_params.get('productId') or query_params.get('productId')
            if not user_id or not product_id:
                return {'statusCode': 400, 'headers': CORS_HEADERS, 'body': json.dumps({'error': 'userId y productId son requeridos'})}
            
            table.delete_item(
                Key={'userId': user_id, 'productId': str(product_id)}
            )
            return {
                'statusCode': 200,
                'headers': CORS_HEADERS,
                'body': json.dumps({'message': f'Producto {product_id} eliminado del carrito'})
            }

        else:
            return {'statusCode': 405, 'headers': CORS_HEADERS, 'body': json.dumps({'error': f'Metodo {http_method} no permitido'})}

    except Exception as e:
        return {
            'statusCode': 500,
            'headers': CORS_HEADERS,
            'body': json.dumps({'error': 'Error interno del servidor', 'details': str(e)})
        }
