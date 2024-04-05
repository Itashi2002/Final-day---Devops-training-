resource "aws_instance" "ansibleController" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  tags = {
    Name = var.name
  }
  key_name = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [
    aws_security_group.ansibleController.id
  ]
}
resource "null_resource" "copyAnsibleCfg" {
    triggers={
        ansibleControllerID=aws_instance.ansibleController.id
    }
  provisioner "file" {
    connection {
      type        = "ssh"
      host        = aws_instance.ansibleController.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.keypair.private_key_pem
    }
    source = "ansible.cfg"
    destination = "./ansible.cfg"
  }
}
resource "null_resource" "copyPrivateKey" {
 triggers={
        ansibleControllerID=aws_instance.ansibleController.id
    }
  provisioner "file" {
    connection {
      type        = "ssh"
      host        = aws_instance.ansibleController.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.keypair.private_key_pem
    }
    destination = "/home/ubuntu/.ssh/id_rsa"
    content = tls_private_key.keypair.private_key_pem
  }
}
resource "null_resource" "installAnsible" {
    triggers={
        ansibleControllerID=aws_instance.ansibleController.id
    }
  depends_on = [ 
    null_resource.copyPrivateKey 
  ]
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = aws_instance.ansibleController.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.keypair.private_key_pem
    }
    inline = [
      "sudo apt-get update -y && sudo apt-get install -y ansible",
      "echo ${aws_instance.ansibleController.private_ip} > selfManagedNode",
      "chmod 600 ~/.ssh/id_rsa",
      "ansible --version",
      "ansible all -m ping"
    ]
  }
}

resource "null_resource" "copyPlaybooks" {
  triggers = {
    timestamp = timestamp()
  }
  provisioner "file" {
    connection {
      type        = "ssh"
      host        = aws_instance.ansibleController.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.keypair.private_key_pem
    }
    destination = "./"
    source = "playbooks/"
  }
}

# resource "null_resource" "runPlaybooks" {
#   triggers = {
#     copyPlaybooks = null_resource.copyPlaybooks.id
#   }
#   depends_on = [ 
#     null_resource.copyPlaybooks
#   ]
#   provisioner "remote-exec" {
#     connection {
#       type        = "ssh"
#       host        = aws_instance.ansibleController.public_ip
#       user        = "ubuntu"
#       private_key = tls_private_key.keypair.private_key_pem
#     }
#     inline = [
#       "ansible-playbook myplaybook.yml",
#       "ansible-playbook tomcat_playbook.yml --extra-vars password=${var.password}"
#     ]
#   }
# }

resource "null_resource" "runPlaybooks" {
  triggers = {
    copyPlaybooks = null_resource.copyPlaybooks.id
  }
  depends_on = [ 
    null_resource.copyPlaybooks
  ]
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = aws_instance.ansibleController.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.keypair.private_key_pem
    }
    inline = [
      "ansible-playbook myplaybook.yml",
      "ansible-playbook tomcat_playbook.yml --tags without_pwd"
    ]
  }
}

resource "null_resource" "runPlaybooks_withPassword" {
  triggers = {
    copyPlaybooks = null_resource.copyPlaybooks.id
  }
  depends_on = [ 
    null_resource.copyPlaybooks,
    null_resource.runPlaybooks
  ]
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = aws_instance.ansibleController.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.keypair.private_key_pem
    }
    inline = [
      "ansible-playbook tomcat_playbook.yml --tags with_pwd --extra-vars password=${var.password}"
    ]
  }
}