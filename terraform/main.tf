provider "aws" {
  region = "us-east-1"
}

# Creamos la cerradura en AWS leyendo la llave que acabas de generar
resource "aws_key_pair" "llave_ssh" {
  key_name   = "llave_boton_caos"
  public_key = file("~/.ssh/llave_aws.pub")
}

resource "aws_security_group" "boton_caos_sg" {
  name        = "boton_caos_sg"
  description = "Permitir trafico para la app y monitoreo"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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

resource "aws_instance" "servidor_boton" {
  ami           = "ami-04b70fa74e45c3917"
  instance_type = "t2.micro"
  
  # Le decimos a la máquina que use la llave de arriba
  key_name      = aws_key_pair.llave_ssh.key_name
  vpc_security_group_ids = [aws_security_group.boton_caos_sg.id]

  tags = {
    Name = "Servidor-Boton-Caos"
  }
}