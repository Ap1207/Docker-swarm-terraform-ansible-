provider "aws" {
        region = "eu-west-2"
}

# path to pub certificate for creation key pair 
variable "certpub" { default = "./dn-test2.pub" }
# path to pem certificate which will be used for connection 
variable "certpem" { default = "./dn-test2.pem" }
# path to file with "worker join token" + manager IP + port
variable "pathtofile" { default = "./token" }

resource "aws_security_group" "default" {
        name = "dn-test33"

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

resource "aws_key_pair" "dn-test2" {
   key_name = "dn-test2"
   public_key = "${file(var.certpub)}"
   depends_on = ["aws_security_group.default"]
}

resource "aws_instance" "manager" {
        ami                             = "ami-f4f21593"
        instance_type                   = "t2.micro"
        key_name                                = "dn-test2"
        vpc_security_group_ids  = ["${aws_security_group.default.id}"]
    associate_public_ip_address = true
    provisioner "local-exec" {
    command = "sleep 120"
    } 
    # This is where we configure the instance with ansible-playbook
    provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ${var.certpem} -i '${aws_instance.manager.public_ip},' manager.yml -e 'ansible_python_interpreter=/usr/bin/python3'"
    }
    # add in file manager's IP + port
     provisioner "local-exec" {
        command = "echo -n ' ' ${aws_instance.manager.public_ip}:2377 >> ${var.pathtofile}"
    }    
        tags {
        Name = "manager"
   }
depends_on = ["aws_key_pair.dn-test2"]
}
resource "aws_instance" "worker1" {
    ami                     = "ami-f4f21593"
    instance_type           = "t2.micro"
    key_name                = "dn-test2"
    vpc_security_group_ids  = ["${aws_security_group.default.id}"]
    associate_public_ip_address = true
   # This is where we configure the instance with ansible-playbook
    provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ${var.certpem} -i '${aws_instance.worker1.public_ip},' worker.yml -e 'ansible_python_interpreter=/usr/bin/python3'"
   }
    tags {
        Name = "worker1"
   }
depends_on = ["aws_instance.manager"]
}
resource "aws_instance" "worker2" {
    ami                     = "ami-f4f21593"
    instance_type           = "t2.micro"
    key_name                = "dn-test2"
    vpc_security_group_ids  = ["${aws_security_group.default.id}"]
    associate_public_ip_address = true
    # This is where we configure the instance with ansible-playbook
    provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ${var.certpem} -i '${aws_instance.worker2.public_ip},' worker.yml -e 'ansible_python_interpreter=/usr/bin/python3'"
   }
    tags {
        Name = "worker2"
   }
depends_on = ["aws_instance.worker1"]
}

