from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from prometheus_fastapi_instrumentator import Instrumentator
import logging
import os
import httpx
import os
import boto3
import json
from datetime import datetime

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

contador_clics = 0

app.mount("/static", StaticFiles(directory="app/static"), name="static")

@app.get("/")
def read_root():
    return FileResponse("app/static/index.html")

@app.post("/click")
def registrar_click():
    global contador_clics
    contador_clics += 1
    logger.info(f"¡Alguien presionó el botón rojo OÑO! Total: {contador_clics}")
    
    # Llamamos a la función
    try:
        guardar_evento_en_s3("usuario_frontend", "clic_boton_caos")
        print("¡Evidencia enviada a S3 correctamente!")
    except Exception as e:
        print(f"Error escribiendo en S3 directamente: {e}")

    # LAMBDA
    lambda_url = os.getenv("LAMBDA_URL")
    if lambda_url:
        try:
            # Disparamos la petición a Lambda y no esperamos respuesta para no poner lenta la página
            httpx.post(lambda_url, timeout=1.0)
        except Exception as e:
            print(f"Aviso a Lambda falló silenciosamente: {e}")

    return {"total_clics": contador_clics}

