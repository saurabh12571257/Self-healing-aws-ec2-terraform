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

EC2 = boto3.client('ec2')

def lambda_handler(event, context):
    body = event.get('body')
    
    # Handle case where body is already a dict (direct Lambda invocation)
    if isinstance(body, dict):
        payload = body
    else:
        try:
            payload = json.loads(body) if body else {}
        except json.JSONDecodeError as e:
            print(f"JSON decode error: {e}")
            return {"statusCode": 400, "body": json.dumps({"error": "Invalid JSON payload"})}
    
    alerts = payload.get('alerts', [])
    
    if not alerts:
        return {"statusCode": 400, "body": json.dumps({"error": "No alerts found"})}
    
    results = []
    for alert in alerts:
        instance_label = alert.get('labels', {}).get('instance', '')
        if not instance_label:
            print(f"Alert missing instance label: {alert}")
            continue
            
        instance_id = get_instance_id_by_private_ip(instance_label)
        if instance_id:
            try:
                EC2.reboot_instances(InstanceIds=[instance_id])
                print(f"Rebooted instance {instance_id} (IP: {instance_label})")
                results.append({"instance_id": instance_id, "status": "rebooted"})
            except Exception as e:
                print(f"Reboot failed for {instance_id}: {e}")
                results.append({"instance_id": instance_id, "status": "failed", "error": str(e)})
        else:
            print(f"No instance found for IP: {instance_label}")
            results.append({"ip": instance_label, "status": "not_found"})
    
    return {
        "statusCode": 200, 
        "body": json.dumps({"message": "Processing complete", "results": results})
    }


def get_instance_id_by_private_ip(private_ip):
    """Get EC2 instance ID by private IP address"""
    if not private_ip:
        return None
        
    try:
        resp = EC2.describe_instances(
            Filters=[
                {'Name': 'private-ip-address', 'Values': [private_ip]},
                {'Name': 'instance-state-name', 'Values': ['running', 'stopped']}
            ]
        )
        for reservation in resp.get('Reservations', []):
            for instance in reservation.get('Instances', []):
                return instance.get('InstanceId')
    except Exception as e:
        print(f"Error querying EC2 for IP {private_ip}: {e}")
    
    return None

def notify_slack(message):
    requests.post(SLACK_WEBHOOK_URL, json={"text": message})


PY
    filename = "lambda_function.py"
  }
}
