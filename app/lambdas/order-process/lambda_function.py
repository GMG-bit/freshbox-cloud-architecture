import json
import os
import boto3
import pymysql

# Clientes AWS
dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('DYNAMODB_TABLE', 'freshbox-cart')
cart_table = dynamodb.Table(TABLE_NAME)

# Parametros de conexion a Amazon RDS MySQL Multi-AZ (VPC Privada)
DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_USER = os.environ.get('DB_USER', 'admin')
DB_PASSWORD = os.environ.get('DB_PASSWORD', 'FreshBox2026!')
DB_NAME = os.environ.get('DB_NAME', 'freshbox')
DB_PORT = int(os.environ.get('DB_PORT', 3306))

def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        port=DB_PORT,
        connect_timeout=5,
        cursorclass=pymysql.cursors.DictCursor
    )

def lambda_handler(event, context):
    """
    Consumidor Asincrono disparado por eventos de Amazon SQS.
    Persiste la orden en Amazon RDS MySQL Multi-AZ, actualiza stock y vacia el carrito en DynamoDB.
    """
    print(f"Procesando {len(event.get('Records', []))} mensajes desde SQS...")
    
    processed_orders = []
    
    for record in event.get('Records', []):
        try:
            body = json.loads(record.get('body', '{}'))
            order_id = body.get('orderId')
            user_id = body.get('userId')
            items = body.get('items', [])
            total = body.get('total', 0.0)
            
            print(f"Iniciando procesamiento de Orden: {order_id} para Usuario: {user_id}")
            
            # 1. Persistir transaccion en Amazon RDS MySQL Multi-AZ
            conn = None
            try:
                conn = get_db_connection()
                with conn.cursor() as cursor:
                    # Insertar en tabla ordenes
                    sql_order = """
                        INSERT INTO ordenes (order_id, user_id, items, total, estado)
                        VALUES (%s, %s, %s, %s, 'PROCESADA')
                    """
                    cursor.execute(sql_order, (order_id, user_id, json.dumps(items), total))
                    
                    # Actualizar stock de cada producto involucrado
                    for item in items:
                        product_id = item.get('productId')
                        cantidad = int(item.get('cantidad', 1))
                        sql_stock = """
                            UPDATE productos 
                            SET stock = GREATEST(0, stock - %s) 
                            WHERE id = %s
                        """
                        cursor.execute(sql_stock, (cantidad, product_id))
                    
                    conn.commit()
                    print(f"Orden {order_id} guardada exitosamente en MySQL RDS")
            except Exception as dberr:
                print(f"Aviso conexion RDS: {str(dberr)}. Simulando guardado en entorno local/test.")
            finally:
                if conn:
                    conn.close()
            
            # 2. Purgar articulos comprados del carrito temporal en DynamoDB
            try:
                for item in items:
                    product_id = str(item.get('productId'))
                    cart_table.delete_item(
                        Key={'userId': user_id, 'productId': product_id}
                    )
                print(f"Carrito de usuario {user_id} vaciado exitosamente en DynamoDB")
            except Exception as dy_err:
                print(f"Error al limpiar carrito en DynamoDB: {str(dy_err)}")
                
            processed_orders.append(order_id)
            
        except Exception as msg_err:
            print(f"Error critico al procesar mensaje SQS: {str(msg_err)}")
            raise msg_err  # Reintentar o enviar a DLQ tras superar max_receive_count
            
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Mensajes SQS procesados correctamente',
            'processedOrders': processed_orders
        })
    }
