from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(message)s")
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
    logger.info(f"¡Alguien presionó el botón rojo! Total: {contador_clics}")
    return {"total_clics": contador_clics}