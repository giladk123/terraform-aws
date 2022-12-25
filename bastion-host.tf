resource "aws_instance" "vprofile-bastion" {
  ami                    = lookup(var.AMIS, var.AWS_REGION)
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.vprofilekey.key_name
  subnet_id              = module.vpc.public_subnets[0]
  count                  = var.instance_count
  vpc_security_group_ids = [aws_security_group.vprofile-bastion-sg.id]

  tags = {
    Name    = "vprofile-bastion"
    PROJECT = "vprofile"
  }

  provisioner "file" {
    content     = templatefile("templates/db-deploy.tmpl", { rds-endpoint = aws_db_instance.vprofile-rds.address, dbuser = var.dbuser, dbpass = var.dbpass })
    destination = "/tmp/vprofile-dbdeploy.sh"
  }

  provisioner "file" {
    content     = templatefile("templates/app_properties.tmpl", { mc-endpoint = aws_elasticache_cluster.vprofile-cache.configuration_endpoint, rds-endpoint = aws_db_instance.vprofile-rds.address, dbuser = var.dbuser, dbpass = var.dbpass, amq-endpoint = aws_mq_broker.vprofile-rmq.instances.0.endpoints.1, rmquser = var.rmquser, rmqpass = var.rmqpass })
    destination = "/tmp/application.properties"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/vprofile-dbdeploy.sh",
      "sed -i -e 's/\r$//' /tmp/vprofile-dbdeploy.sh",
      "sudo /tmp/vprofile-dbdeploy.sh",
      "chmod +x /tmp/application.properties",
      "sed -i 's/:5671//' /tmp/application.properties",
      "sed -i 's/:11211//' /tmp/application.properties",
      "sed -i 's#amqp+ssl://##g' /tmp/application.properties",
      "sudo cp -f /tmp/application.properties /home/ubuntu/vprofile-project/src/main/resources/",
      "cd /home/ubuntu/vprofile-project",
      "sudo mvn install"
    ]
  }

  connection {
    user        = var.USERNAME
    private_key = file(var.PRIV_KEY_PATH)
    host        = self.public_ip
  }

  depends_on = [aws_db_instance.vprofile-rds]
}

resource "aws_s3_bucket" "b" {
  bucket = "beanstalk-apps-2023"
  tags = {
    Name        = "Jars"
    Environment = " Dev"
  }
}

resource "aws_s3_bucket_acl" "b-acl" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}

output "PublicIP" {
  value = aws_instance.vprofile-bastion[0].public_ip
}

output "PrivateIP" {
  value = aws_instance.vprofile-bastion[0].private_ip
}
