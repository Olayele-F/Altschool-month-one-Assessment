#!/bin/bash
                yum update -y
                amazon-linux-extras install nginx1 -y

# Clear the default welcome page config
                sudo rm -f /etc/nginx/conf.d/default.conf

# Force create your file
                echo "<h1>Welcome to TechCorp Web Server ${count.index + 1}</h1>" | sudo tee /usr/share/nginx/html/index.html

# FIX: Add Permissions and Ownership directly in the script
                sudo chmod 644 /usr/share/nginx/html/index.html
                sudo chown nginx:nginx /usr/share/nginx/html/index.html

                systemctl restart nginx
                systemctl enable nginx

# Enable Password Auth
            echo "ec2-user:Olayele66" | chpasswd
            sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
            systemctl restart sshd