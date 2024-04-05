resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "aws_key_pair" "keypair" {
  key_name   = var.name
  public_key = tls_private_key.keypair.public_key_openssh
}
resource "local_file" "tls_private_key" {
  filename        = "c:/users/Admin/.ssh/${var.name}.pem"
  content         = tls_private_key.keypair.private_key_pem
  file_permission = "0600"
}
