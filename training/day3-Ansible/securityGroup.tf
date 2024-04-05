resource "aws_security_group" "ansibleController" {
  name        = var.name
  description = "Managed by Terraform"
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
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    security_groups  = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = false
    description      = "SSH Port"
  },
  {
    to_port          = 8080
    from_port        = 8080
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    security_groups  = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = false
    description      = "SSH Port"
  }
  ]
}
