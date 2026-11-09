import json
import os
import uuid
import boto3
from decimal import Decimal
from boto3.dynamodb.conditions import Key

# Clientes AWS
dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')

TABLE_NAME = os.environ.get('DYNAMODB_TABLE', 'freshbox-cart')
QUEUE_URL = os.environ.get('SQS_QUEUE_URL', '')
table = dynamodb.Table(TABLE_NAME)

CORS_HEADERS = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization'
}

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return int(obj) if obj % 1 == 0 else float(obj)
    raise TypeError

def lambda_handler(event, context):
    """
    Recepcion asincrona y desacoplada de Ordenes de Compra
    Ruta: POST /api/orders (body: {userId})
    Envia payload a cola Amazon SQS para procesamiento en segundo plano.
    """
    http_method = event.get('httpMethod') or event.get('requestContext', {}).get('http', {}).get('method', 'POST')
    
    if http_method == 'OPTIONS':
        return {'statusCode': 200, 'headers': CORS_HEADERS, 'body': json.dumps({'message': 'OK'})}
    
    try:
        body_str = event.get('body', '{}')
        body = json.loads(body_str) if isinstance(body_str, str) else body_str
        user_id = body.get('userId')
        
        if not user_id:
            return {'statusCode': 400, 'headers': CORS_HEADERS, 'body': json.dumps({'error': 'userId es requerido'})}
        
        # 1. Consultar articulos del carrito en DynamoDB
        response = table.query(
            KeyConditionExpression=Key('userId').eq(user_id)
        )
        items = response.get('Items', [])
        
        # Si el carrito esta vacio, permitir orden con items de prueba o rechazar
        if not items:
            items = [
                {
                    'productId': '1',
                    'nombre': 'Manzana organica 1kg',
                    'precio': Decimal('3490'),
                    'cantidad': 1
                }
            ]
        
        total = sum(Decimal(str(item.get('precio', 0))) * Decimal(str(item.get('cantidad', 1))) for item in items)
        order_id = f"ORD-{uuid.uuid4().hex[:8].upper()}"
        
        order_payload = {
            'orderId': order_id,
            'userId': user_id,
            'items': items,
            'total': float(total),
            'timestamp': int(context.get_remaining_time_in_millis() if context else 0)
        }
        
        # 2. Publicar en Amazon SQS para desacoplamiento total
        if QUEUE_URL:
            sqs.send_message(
                QueueUrl=QUEUE_URL,
                MessageBody=json.dumps(order_payload, default=decimal_default),
                MessageAttributes={
                    'OrderId': {'DataType': 'String', 'StringValue': order_id},
                    'UserId': {'DataType': 'String', 'StringValue': user_id}
                }
            )
        
        # 3. Retorno inmediato al cliente (Patron Asynchronous Request-Reply)
        return {
            'statusCode': 202,
            'headers': CORS_HEADERS,
            'body': json.dumps({
                'message': 'Su pedido fue recibido',
                'orderId': order_id,
                'total': float(total)
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': CORS_HEADERS,
            'body': json.dumps({'error': 'Fallo al encolar la orden', 'details': str(e)})
        }
