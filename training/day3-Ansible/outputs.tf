
output "ansibleControllerPublicIp" {
  value = aws_instance.ansibleController.public_ip
}
