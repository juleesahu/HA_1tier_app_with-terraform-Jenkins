resource "aws_instance" "jenkins_server" {
    ami                 = "ami-0f9de6e2d2f067fca"
    instance_type       = "t2.medium"
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.public_subnet_1.id
    vpc_security_group_ids      = [aws_security_group.jenkins_sg.id] 
    key_name                    = "ssh.keygen"
  user_data = <<-EOF
      # Install Java 17
      # Ref: https://www.rosehosting.com/blog/how-to-install-java-17-lts-on-ubuntu-20-04/
      "sudo apt update -y",
      "sudo apt install openjdk-17-jdk openjdk-17-jre -y",
      "java -version",

      # Install Jenkins
      # Ref: https://www.jenkins.io/doc/book/installing/linux/#debianubuntu
      "sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key",
      "echo \"deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/\" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
      "sudo apt-get update -y",
      "sudo apt-get install -y jenkins",
      "sudo systemctl start jenkins",
      "sudo systemctl enable jenkins",
      "sudo chmod +x jenkins",

    EOF 
  
      tags = {
        Name = "jenkinsServer"
    }            
  }

  resource "aws_security_group" "jenkins_sg" {
    vpc_id = aws_vpc.main_vpc.id
  ingress {
    from_port    = 22
    to_port      = 22
    protocol     = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]     #  Allow SSH access
    }
    # Define inbound rules for Port 80
  ingress {
    description     = "HTTP Port"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port      = 8080
    to_port        = 8080
    protocol       = "tcp"
    cidr_blocks    = ["0.0.0.0/0"]      # Allow jenkins web UI
   }
 egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  } 
 tags = {
   Name = "jenkinsSecurityGroup"
 }
  # Port 443 is required for HTTPS
  ingress {
    description     = "HTTPS Port"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

} 

 

    
  

