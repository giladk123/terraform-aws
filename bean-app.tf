resource "aws_elastic_beanstalk_application" "vprofile-prod" {
  name = "vprofile-prod"
}

resource "aws_elastic_beanstalk_application_version" "new_version" {
  application = "vprofile-prod"
  bucket      = aws_s3_bucket.b.id
  key         = aws_s3_object.war_file.id
  name        = "vprofile-v4.5"

  provisioner "local-exec" {
    command = "aws --region ${var.AWS_REGION} elasticbeanstalk update-environment --environment-name ${aws_elastic_beanstalk_environment.vprofile-bean-prod.name} --version-label ${aws_elastic_beanstalk_application_version.new_version.name}"
  }

  depends_on = [aws_s3_object.war_file]
}