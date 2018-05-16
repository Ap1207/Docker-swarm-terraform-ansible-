provider "aws" {
        region = "eu-west-2"
}

resource "aws_security_group" "default" {
        name = "test33"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

        ingress {
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }

        egress {
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_key_pair" "test2" {
   key_name = "test2"
   public_key = "${file("/pat/to/cert.pub")}"
   depends_on = ["aws_security_group.default"]
}

resource "aws_instance" "manager" {
        ami                             = "ami-f4f21593"
        instance_type                   = "t2.micro"
        key_name                                = "test2"
        vpc_security_group_ids  = ["${aws_security_group.default.id}"]
    associate_public_ip_address = true
    provisioner "local-exec" {
    command = "sleep 120"
    }
    # This is where we configure the instance with ansible-playbook
    provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u _server_user_ --private-key ./path/to/local/cert.pem -i '${aws_instance.manager.public_ip},' manager.yml -e 'ansible_python_interpreter=/usr/bin/python3'"
    }
    # add in file manager's IP + port token thi is name of file
     provisioner "local-exec" {
        command = "echo -n ' ' ${aws_instance.manager.public_ip}:2377 >> /path/to/file/token"
    }
        tags {
        Name = "manager"
   }
depends_on = ["aws_key_pair.test2"]
}
resource "aws_instance" "worker1" {
    ami                     = "ami-f4f21593"
    instance_type           = "t2.micro"
    key_name                = "test2"
    vpc_security_group_ids  = ["${aws_security_group.default.id}"]
    associate_public_ip_address = true
   # This is where we configure the instance with ansible-playbook
    provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u _server_user_ --private-key ./path/to/local/cert.pem -i '${aws_instance.worker1.public_ip},' worker.yml -e 'ansible_python_interpreter=/usr/bin/python3'"
   }
    tags {
        Name = "worker1"
   }
depends_on = ["aws_instance.manager"]
}
resource "aws_instance" "worker2" {
    ami                     = "ami-f4f21593"
    instance_type           = "t2.micro"
    key_name                = "test2"
    vpc_security_group_ids  = ["${aws_security_group.default.id}"]
    associate_public_ip_address = true
    # This is where we configure the instance with ansible-playbook
    provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u _server_user_ --private-key ./path/to/local/cert.pem -i '${aws_instance.worker2.public_ip},' worker.yml -e 'ansible_python_interpreter=/usr/bin/python3'"
   }
    tags {
        Name = "worker2"
   }
depends_on = ["aws_instance.worker1"]
}
