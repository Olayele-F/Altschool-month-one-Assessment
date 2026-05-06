welcome!

so basically, this is all you need to know about doing this project.

prerequisites:
-aws account
-vscode
-terraform
-ssh key and a password.

deployment steps.
to start, initiate "terraform init" to start the process
the write your terraform steps
use "terraform plan" to map out and preview all that will be created
then use "terraform apply -auto-approve" to apply your plan and deploy.

Once the apply is complete, copy the alb_dns_name from the terminal output and paste it into your browser!

you can Connect to Bastion:
ssh ec2-user@<bastion_public_ip>

and Jump to Web/DB Server:
From inside the Bastion, use the private IP of db or webservers:
ssh ec2-user@<private_ip_of_target>

To avoid ongoing AWS charges (especially for the NAT Gateway and ALB), destroy the infrastructure when you are finished. "terraform destroy -auto-approve"

voila!
