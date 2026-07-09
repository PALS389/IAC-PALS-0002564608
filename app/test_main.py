from fastapi.testclient import TestClient
from app.main import app

# ARRANGE 
client = TestClient(app)
def test_cargar_pagina():
    """Prueba que la página principal cargue correctamente (Código 200)"""
# ACT
    response = client.get("/")
# ASSERT
    assert response.status_code == 200

def test_registrar_click():
    """Prueba que el botón registre el clic y devuelva el total"""
# ACT
    response = client.post("/click")
# ASSERT
    assert response.status_code == 200
    assert "total_clics" in response.json()