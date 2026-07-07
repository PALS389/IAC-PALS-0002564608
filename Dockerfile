# Usar una imagen oficial de Python muy ligera para ahorrar recursos
FROM python:3.9-slim

# Establecer la carpeta de trabajo dentro del contenedor
WORKDIR /code

# Copiar primero el requirements para aprovechar el caché de Docker
COPY ./app/requirements.txt /code/requirements.txt

# Instalar dependencias
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# Copiar el código y el HTML de nuestra app
COPY ./app /code/app

# Exponer el puerto 8000
EXPOSE 8000

# Comando para prender el servidor web al iniciar el contenedor
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]