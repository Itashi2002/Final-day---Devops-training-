provider "aws" {
  region = "us-east-2" #OHIO
}

provider "tls" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "ubuntu" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
   tags = {
    Name = "Itashi"
  }
  key_name=aws_key_pair.keypair.key_name
  vpc_security_group_ids=[
    aws_security_group.ubuntu.id
  ]
}
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits = 2048
}
resource "aws_key_pair" "keypair" {
  key_name = "itashi-key"
  public_key = tls_private_key.keypair.public_key_openssh
}

resource "aws_security_group" "ubuntu"{
  name="itashi-key"
  description="Managed by terraform"
    egress = [{
    to_port          = 0
    from_port        = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    security_groups  = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = false
    description      = "All open for outbound access."
  }]
ingress = [{
    to_port          = 22
    from_port        = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    security_groups  = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = false
    description      = "Port 22 for outbound access."
  },
  {
    to_port          = 80
    from_port        = 80
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    security_groups  = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = false
    description      = "HTTP Port"
  }] 
}

output "public-ip" {
  value = aws_instance.ubuntu.public_ip
}

resource "local_file" "tls_private_key" {
  filename = "c:/users/Admin/.ssh/itashi-key.pem"
  content = tls_private_key.keypair.private_key_pem
  file_permission = "0600"
}

resource "null_resource" "install_packages" {
   depends_on = [ 
    null_resource.copy_index_html
  ]
  triggers = {
    copy_index_html = null_resource.copy_index_html.id
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = aws_instance.ubuntu.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.keypair.private_key_pem
    }
    inline = [
      "sudo apt-get update -y && sudo apt-get install -y apache2",
       "sudo cp /tmp/index.html /var/www/html/index.html"
    ]
  }
}

data "http" "access_apache" {
  depends_on = [ 
    null_resource.install_packages
  ]
  url = "http://${aws_instance.ubuntu.public_ip}:80"
  method = "HEAD"
}

resource "template_file" "index_html" {
  template = file("./index.html.tpl")
  vars = {
    PRIVATE_IP = aws_instance.ubuntu.private_ip
    SECURITY_GROUP = aws_security_group.ubuntu.name
  }
}
resource "local_file" "index_html" {
  filename = "index.html"
  content = template_file.index_html.rendered
}

resource "null_resource" "copy_index_html" {
  triggers = {
    index_html = local_file.index_html.id
  }
  provisioner "file" {
    connection {
      type        = "ssh"
      host        = aws_instance.ubuntu.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.keypair.private_key_pem
    }
    source = "index.html"
    destination = "/tmp/index.html"
  }
}
