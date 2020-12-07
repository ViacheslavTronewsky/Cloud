
provider aws {
    access_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    secret_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    region = "us-east-1"
}

data "aws_ami" "amazon_test" {
  most_recent = true
  owners = ["self"]
}

resource "aws_security_group" "SG"{

    name = "ELB_SG"

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

   tags = {
       Name = "ELB_SG"
   }
}

resource "aws_lb" "ELB" {
    name = "ELB"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.SG.id]
    subnets = ["subnet-d87811d6", "subnet-383ac109"]

}

resource "aws_instance" "ec2" {
    ami = data.aws_ami.amazon_test.id
    key_name = "MyKeyPair"
    count = 2
    security_groups = [aws_security_group.SG.name] 
    instance_type = "t2.micro"
    user_data = file(format("user_data%d.sh", count.index+1))
 
    tags = {
    Name = format("Instance-%d", count.index)
  }
}



resource "aws_lb_target_group" "target_group" {
  name     = "Lab6-Target-Group"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-504b8b2d"
}

resource "aws_lb_target_group_attachment" "target_group_attachment" {
  count = length(aws_instance.ec2)
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id = aws_instance.ec2[count.index].id
  port = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.ELB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

