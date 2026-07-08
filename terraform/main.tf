provider "aws" {
  region = "us-east-1"
}

# 1. Creamos el muro de seguridad (Security Group)
resource "aws_security_group" "boton_caos_sg" {
  name        = "boton_caos_sg"
  description = "Permitir trafico para la app y monitoreo"

  # Puerto 22 para que Ansible se conecte después
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puerto 8000 para tu aplicación de FastAPI
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puertos 9090 (Prometheus), 3100 (Loki) y 3000 (Grafana)
  ingress {
    from_port   = 3000
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Pedimos la máquina virtual gratuita
resource "aws_instance" "servidor_boton" {
  ami           = "ami-04b70fa74e45c3917" # Imagen oficial de Ubuntu 24.04 en us-east-1
  instance_type = "t2.micro"              # Capa 100% gratuita

  vpc_security_group_ids = [aws_security_group.boton_caos_sg.id]

  tags = {
    Name = "Servidor-Boton-Caos"
  }
}