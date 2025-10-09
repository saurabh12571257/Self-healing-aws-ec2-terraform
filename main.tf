locals {
  app_name = "self-heal-demo"
}

resource "aws_key_pair" "deployer" {
  count      = var.key_name == "" ? 1 : 0
  key_name   = "${local.app_name}-key"
  public_key = file(var.public_key_path)
}
# Determine key name to use
locals {
  effective_key_name = var.key_name != "" ? var.key_name : try(aws_key_pair.deployer[0].key_name, null)
}


#Default VPC 
data "aws_vpc" "default" {
  default = true
}


data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


# Find a recent Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "./lambda_function.zip"


  source {
    content  = <<PY
import json
import boto3
import urllib.request


EC2 = boto3.client('ec2')


def lambda_handler(event, context):
    body = event.get('body')
    try:
        payload = json.loads(body)
        alerts = payload.get('alerts', [])
    except Exception:
        return {"statusCode":400, "body":"invalid payload"}


    for alert in alerts:
        instance_label = alert.get('labels', {}).get('instance', '')
        # Expect instance_label to be private IP (e.g., 10.0.x.x)
        instance_id = get_instance_id_by_private_ip(instance_label)
        if instance_id:
            try:
                EC2.reboot_instances(InstanceIds=[instance_id])
            except Exception as e:
                print('reboot failed', e)
        else:
            print('no instance mapping for', instance_label)


    return {"statusCode":200, "body":"ok"}




def get_instance_id_by_private_ip(private_ip):
    try:
        resp = EC2.describe_instances(Filters=[{'Name':'private-ip-address','Values':[private_ip]}])
        for r in resp.get('Reservations',[]):
            for i in r.get('Instances',[]):
                return i.get('InstanceId')
    except Exception as e:
        print(e)
    return None


PY
    filename = "lambda_function.py"
  }
}
