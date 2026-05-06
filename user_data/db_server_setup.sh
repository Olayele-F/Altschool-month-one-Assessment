#!/bin/bash
              amazon-linux-extras install postgresql14 -y
              yum install -y postgresql-server
              postgresql-setup initdb
              systemctl start postgresql
              systemctl enable postgresql
              # Enable Password Auth
              echo "ec2-user:Olayele66" | chpasswd
              sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
              systemctl restart sshd