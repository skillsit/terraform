#================================PROVIDER=====================================================================#

provider "aws" {
  region = "us-west-1" # Sydney 
}

#================================VARIABLES=====================================================================#

variable "server_port" {
  description = "The port used for HTTP requests"
  default     = 8080
}

#================================RESOURCES=====================================================================#

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_launch_configuration" "my_first_terraform" {
  image_id          = "ami-0f56279347d2fa43e"
  instance_type     = "t2.micro"
  security_groups   = [aws_security_group.instance2.id]
  placement_tenancy = "default"
  user_data = <<-EOF
              #!/bin/bash
              echo "<marquee direction="down" width="1000" height="800" behavior="alternate" style="border:solid">
              <marquee behavior="alternate">
              <h1>SKILLSIT</h1>
              </marquee>
              </marquee>" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
  EOF


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "my_first_terraform" {
  launch_configuration = aws_launch_configuration.my_first_terraform.id
  availability_zones   = [data.aws_availability_zones.available.names[0]]

  load_balancers    = [aws_elb.my_first_terraform.name]
  health_check_type = "ELB"

  min_size = 2
  max_size = 3

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_elb" "my_first_terraform" {
  name               = "terraform-asg-example"
  availability_zones = [data.aws_availability_zones.available.names[0]]
  security_groups    = [aws_security_group.elb.id]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-example-elb"

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "instance2" {
  name = "terraform-example-instance2"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "elb_dns_name" {
  value = aws_elb.my_first_terraform.dns_name
}

