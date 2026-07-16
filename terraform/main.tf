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

# SERVERLESS (S3 + LAMBDA) 

# 1. Crear el Balde S3
resource "aws_s3_bucket" "caos_bucket_piero" {
  bucket        = "boton-caos-piero-final-2026"
  force_destroy = true # Permite borrarlo fácilmente al terminar el ciclo
}

# 2. Empaquetar el código de Python que creamos en un .zip
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/lambda.zip"
}

# 3. Crear el rol de seguridad
resource "aws_iam_role" "lambda_role" {
  name = "lambda_s3_caos_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Darle el poder exacto al rol
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "lambda_s3_policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:PutObject"],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.caos_bucket_piero.arn}/*"
      },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# 4. Crear la Función Lambda
resource "aws_lambda_function" "caos_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "RegistrarClicCaos"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.caos_bucket_piero.bucket
    }
  }
}

# 5. Crear una URL pública para despertar a la Lambda sin necesidad de permisos extra
resource "aws_lambda_function_url" "lambda_url" {
  function_name      = aws_lambda_function.caos_lambda.function_name
  authorization_type = "NONE"
}

# 6. Mostrar la URL en la terminal al terminar
output "lambda_endpoint_url" {
  value = aws_lambda_function_url.lambda_url.function_url
}