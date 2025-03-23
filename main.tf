resource "aws_vpc" "main_vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "MainVPC"
    }
}
resource "aws_subnet" "public_subnet_1" {
vpc_id            = aws_vpc.main_vpc.id
cidr_block        = "10.0.1.0/24"
availability_zone = "us-east-1a"
tags = {
    Name = "public_subnet1"
}
}
resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "public_subnet2"
  }
}
resource "aws_internet_gateway" "main_igw" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "MainIGW"
    }
}
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
  tags = {
    Name = "PublicRouteTable"
  }
}
resource "aws_route_table_association" "rta_subnet_1" {
    subnet_id = aws_subnet.public_subnet_1.id
    route_table_id = aws_route_table.public_rt.id
  }
  resource "aws_route_table_association" "rta_subnet_2" {
    subnet_id = aws_subnet.public_subnet_2.id
    route_table_id = aws_route_table.public_rt.id
}
resource "aws_key_pair" "deployer" {
    key_name = "ssh.keygen"
    public_key = file("ssh-keygen.pub")         # Ensure you have an SSH key generated
}
resource "aws_security_group" "ec2_sg" {
    vpc_id = aws_vpc.main_vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]               # Allow SSH access
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]   # Allow HTTP access
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  tags = {
    Name = "EC2SecurityGroup"
  }
}
resource "aws_instance" "web_server_1" {
    ami                         = "ami-0f9de6e2d2f067fca"           # Amazon Linux 2 (Update based on region)
    instance_type               = "t2.micro"
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.public_subnet_1.id
    vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
    key_name                    = aws_key_pair.deployer.key_name
    user_data = <<-EOF
                 #!/bin/bash
                 sudo yum update -y
                 sudo yum install httpd -y
                 sudo systemctl start httpd
                 sudo systemctl enable httpd
                 echo "<h1>Welcom to the Web Server 1  $(hostname -f)</h1>" | sudo tee /var/www/html/index.html
                 sudo systemctl restart httpd
                 EOF  
    tags = {
        Name = "Webserver1"
    }
}
resource "aws_instance" "web_server_2" {
    ami                         =  "ami-0f9de6e2d2f067fca"
    instance_type               = "t2.micro"
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.public_subnet_2.id
    vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
    key_name                    = aws_key_pair.deployer.key_name
    user_data = <<-EOF
                 #!/bin/bash
                 sudo yum update -y
                 sudo yum install httpd -y
                 sudo systemctl start httpd
                 sudo systemctl enable httpd
                 echo "<h1>Welcom to the Web Server 2  $(hostname -f)</h1>" | sudo tee /var/www/html/index.html
                 sudo systemctl restart httpd
                 EOF  
    tags = {
      Name = "Webserver2"
    }
}

resource "aws_lb" "web_alb" {
    name                = "web-alb"
    internal            = false
    load_balancer_type  = "application"
    security_groups     = [aws_security_group.ec2_sg.id]
    subnets             = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  tags = {
    Name = "WebALB"
  }
}

resource "aws_lb_target_group" "web_tg" {
    name = "web-target-group"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.main_vpc.id
}

resource "aws_lb_target_group_attachment" "web_tg_attach_1" {
target_group_arn      = aws_lb_target_group.web_tg.arn
target_id             = aws_instance.web_server_1.id  
port                  = 80 
  
}

resource "aws_lb_target_group_attachment" "web_tg_attach_2" {
target_group_arn        = aws_lb_target_group.web_tg.arn
target_id               = aws_instance.web_server_2.id
port                    = 80
  
}

resource "aws_lb_listener" "web_listener" {
load_balancer_arn    = aws_lb.web_alb.arn
port                 = 80
protocol             = "HTTP"
default_action  {
type               = "forward"
target_group_arn   = aws_lb_target_group.web_tg.arn
    }  
}
  
