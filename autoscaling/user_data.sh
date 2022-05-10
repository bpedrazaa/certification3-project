#!/bin/bash -xe

sudo yum install -y httpd wget cowsay
curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
sudo yum install -y nodejs
node --version
sudo systemctl enable httpd
sudo systemctl start httpd
npx create-react-app my-app
cd my-app
npm run build
sudo cp -r build/* /var/www/html/
echo "#!/bin/sh" > /etc/update-motd.d/40-cow
echo 'cowsay "Amazon Linux 2 AMI - UPB"' >> /etc/update-motd.d/40-cow
chmod 755 /etc/update-motd.d/40-cow
sudo rm /etc/update-motd.d/30-banner
update-motd
