from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from prometheus_fastapi_instrumentator import Instrumentator
import logging
import os
import httpx
import boto3
import json
from datetime import datetime

# --- CONFIGURACIÓN DE LOGS ---
os.makedirs("logs", exist_ok=True)
logging.basicConfig(
    level=logging.INFO, 
    format="%(asctime)s - %(message)s",
    handlers=[
        logging.FileHandler("logs/app.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = FastAPI()

# Exponer métricas para Prometheus
Instrumentator().instrument(app).expose(app)

contador_clics = 0

app.mount("/static", StaticFiles(directory="app/static"), name="static")

# --- FUNCIÓN PARA S3 (Definida aquí para que sea visible) ---
def guardar_evento_en_s3(usuario, accion):
    try:
        s3 = boto3.client('s3', region_name='us-east-1')
        data = {
            "usuario": usuario,
            "accion": accion,
            "timestamp": str(datetime.now())
        }
        nombre_archivo = f"evento_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        s3.put_object(
            Bucket='boton-caos-piero-final-2026',
            Key=f"eventos/{nombre_archivo}",
            Body=json.dumps(data)
        )
        print("DEBUG: ¡ÉXITO! Archivo subido a S3.")
    except Exception as e:
        print(f"DEBUG: ¡ERROR CRÍTICO EN S3!: {str(e)}")

# --- RUTAS ---
@app.get("/")
def read_root():
    return FileResponse("app/static/index.html")

@app.post("/click")
def registrar_click():
    global contador_clics
    contador_clics += 1
    logger.info(f"¡Alguien presionó el botón rojo OÑO! Total: {contador_clics}")
    
    # Llamada a la función ahora que ya existe
    try:
        guardar_evento_en_s3("usuario_frontend", "clic_boton_caos")
    except Exception as e:
        print(f"Error general en la ruta: {e}")

    # LAMBDA
    lambda_url = os.getenv("LAMBDA_URL")
    if lambda_url:
        try:
            httpx.post(lambda_url, timeout=1.0)
        except Exception as e:
            print(f"Aviso a Lambda falló silenciosamente: {e}")

    return {"total_clics": contador_clics}
