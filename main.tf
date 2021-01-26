data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ami" "aws" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "pritunl" {
  ami           = data.aws_ami.aws.id
  instance_type = var.instance_type
  key_name      = var.aws_key_name
  user_data     = file("${path.module}/provision.sh")

  vpc_security_group_ids = [
    aws_security_group.pritunl.id,
    aws_security_group.allow_from_office.id,
  ]

  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true

  tags = "${
    merge(
      map("Name", format("%s-%s", var.resource_name_prefix, "vpn")),
      var.tags,
    )
  }"

  //  provisioner "remote-exec" {
  //    connection {
  //      host = aws_instance.pritunl.public_ip
  //      user = "ec2-user"
  //    }
  //    inline = [
  //      "sleep 300",
  //      "sudo pritunl setup-key",
  //    ]
  //  }

}

data "aws_instance" "pritunl_loaded" {
  depends_on = [
    aws_instance.pritunl
  ]

  filter {
    name   = "image-id"
    values = [data.aws_ami.aws.id]
  }

  filter {
    name   = "tag:Name"
    values = [format("%s-%s", var.resource_name_prefix, "vpn")]
  }
}

resource "aws_eip" "pritunl" {
  instance = "${aws_instance.pritunl.id}"
  vpc      = true
}
