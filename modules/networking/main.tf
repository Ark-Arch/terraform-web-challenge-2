resource "aws_vpc" "this" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    tags = { Name = "project-vpc" }
}

resource "aws_internet_gateway" "this"{
    vpc_id = aws_vpc.this.id
    tags = { Name = "project-igw"}
}

resource "aws_subnet" "public" {
    count = length(var.public_subnet_cidrs) # a meta argument!
    vpc_id = aws_vpc.this.id 
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = var.azs[count.index]
    map_public_ip_on_launch = true
    tags = { Name = "public-${count.index}" }
}

resource "aws_subnet" "private" {
    count =  length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.this.id
    cidr_block = var.private_subnet_cidrs[count.index]
    availability_zone = var.azs[count.index]
    tags = { Name = "private-${count.index}" }
}


############################################################
# NAT Gateway (only in prod)
resource "aws_eip" "nat" {
    count = var.environment == "prod" ? length(var.public_subnet_cidrs) : 0
    domain = "vpc"
}

resource "aws_nat_gateway" "this" {
  count = var.environment == "prod" ? length(var.public_subnet_cidrs) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name = "project-nat-${count.index}"
  }
}
###########################################################

# NAT Instance (only in dev)
resource "aws_instance" "nat" {
  count = var.environment == "dev" ? length(var.public_subnet_cidrs) : 0

  ami           = var.nat_ami
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public[count.index].id
  source_dest_check = false
  associate_public_ip_address = true
#   vpc_security_group_ids = 

    user_data = <<-EOF
                #!/bin/bash

                cat << 'EOT' > /usr/local/sbin/nat-setup.sh
                #!/bin/bash
                sysctl -w net.ipv4.ip_forward=1
                echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
                sysctl -p
                IFACE=$(ip route | grep default | awk '{print $5}')
                iptables -t nat -A POSTROUTING -o "$IFACE" -j MASQUERADE
                EOT

                chmod +x /usr/local/sbin/nat-setup.sh

                # Creating the systemd service
                cat << 'EOT' > /etc/systemd/system/nat-setup.service
                [Unit]
                Description=setup NAT iptables rules
                After=network.target

                [Service]
                Type=oneshot
                ExecStart=/usr/local/sbin/nat-setup.sh
                RemainAfterExit=yes

                [Install]
                WantedBy=multi-user.target
                EOT

                # Enable and start the service
                systemctl daemon-reexec
                systemctl daemon-reload
                systemctl enable nat-setup.service

                # Clear the history
                history -c
                echo "NAT WORKING ..."
                EOF

  tags = {
    Name = "${var.environment}-nat-instance"
  }
}

######################################################
# Route Table - Public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "public-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table - Private
resource "aws_route_table" "private" {
  count = length(aws_subnet.private)
  vpc_id = aws_vpc.this.id
  tags   = { Name = "private-rt-${count.index}" }
}

# Route for web/app private subnets
resource "aws_route" "private_nat" {
  count = var.create_nat_route_for_web ? var.webapp_count: 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id = aws_instance.nat[count.index].primary_network_interface_id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security Groups

# For nat-instance
resource "aws_security_group" "nat_instance" {
  count = var.environment == "dev" ? 1 : 0

  name = "nat_instance-sg"
  description = "Allow traffic from private subnets and outbout to internet"
  vpc_id = aws_vpc.this.id

  # Allow traffic from private subnets
  ingress {
    description = "Private subnet traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.public_subnet_cidrs
  }

  # # (Optional) Allow SSH only from your IP
  # ingress {
  #   description = "SSH access"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = [""]
  # }

  # Outbound unrestricted (NAT needs this)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}

resource "aws_security_group" "web" {
  name        = "webapp-sg"
  description = "Allow HTTP/HTTPS inbound"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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

resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "Allow MySQL traffic from web SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
}
