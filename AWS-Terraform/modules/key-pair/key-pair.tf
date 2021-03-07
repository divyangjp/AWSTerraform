variable "key_name" {
  default = ""
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = tls_private_key.this.public_key_openssh
}


output "public_key" {
  value = aws_key_pair.this.public_key
}

output "private_key" {
  value = tls_private_key.this.private_key_pem
}

output "key-name" {
  value = aws_key_pair.this.key_name
}