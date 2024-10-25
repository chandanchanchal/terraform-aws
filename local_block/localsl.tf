# Define the provider (AWS) and the region
provider "aws" {
  region = local.aws_region
}

# Local variables block
locals {
  aws_region     = "us-east-1"  # Define the region in one place
  instance_type  = "t2.micro"   # Instance type
  ami_id         = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (us-east-1)
  instance_count = 2            # Number of instances
  instance_tags  = {            # Tags to apply to all instances
    Environment = "Development"
    Project     = "TerraformDemo"
  }
}

# Resource to create EC2 instances using local variables
resource "aws_instance" "my_instances" {
  count         = local.instance_count  # Use instance_count local variable
  ami           = local.ami_id          # Use ami_id local variable
  instance_type = local.instance_type   # Use instance_type local variable

  tags = local.instance_tags            # Use instance_tags local variable
}

# Output instance IDs to verify the deployment
output "instance_ids" {
  description = "IDs of the created EC2 instances"
  value       = [for instance in aws_instance.my_instances : instance.id]
}
