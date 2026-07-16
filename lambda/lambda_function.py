import json
import boto3
import datetime
import os

# Conectamos con S3
s3 = boto3.client('s3')

def lambda_handler(event, context):
    # Obtenemos el nombre del balde desde las variables de entorno
    bucket_name = os.environ['BUCKET_NAME']
    
    # Creamos un nombre de archivo único con la fecha y hora exacta
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    file_name = f"clic_detectado_{timestamp}.json"
    
    # La información que vamos a guardar
    datos = {
        "evento": "¡El Botón del Caos fue presionado!",
        "fecha_hora": timestamp,
        "ingeniero": "Piero Leiva Sandoval"
    }
    
    # Mandamos el archivo al balde S3
    s3.put_object(
        Bucket=bucket_name,
        Key=file_name,
        Body=json.dumps(datos)
    )
    
    return {
        "statusCode": 200,
        "body": json.dumps({"mensaje": f"Archivo {file_name} guardado en S3 exitosamente."})
    }