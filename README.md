# foundry-ubuntu
A shell script to help with doing an install of Foundry Virtual Tabletop onto an Ubuntu system. 

In the first section you'll need to enter the URL for your foundry download. This is a timed URL you get from your account page for foundry. Be sure to pick the Linux version of the install.

The Hostname is for Reverse Proxy. This assumes you'll have a subdomain pointed back at your external IP address. You'll need to setup port forwarding for port 30000 on your internal network to your Ubuntu Server. 

The rest of the variables are generally good practice but feel free to change them if you want. 

Once you start the install it will ask if this is a first time install, and then goes through a series of installs.
-=Be sure you've already updated your OS apps=-

# Update Date Time
This is specific to my setup, but I assume others may have this problem too. By default my Ubuntu Server installs point to my Gateway as the NTP, and of course my gateway is not running NTP. So this command just quickly updates your NTP to be Google's time server.

# Setup Foundry Install
This downloads the Foundry installer and holds onto it until a later step. Some of the other steps can take awhile and your Time URL can expire, so that's why this step happens here.

# Setup Node Preqeqs
Version 18 seems to be pretty stable. I haven't messed with any of the later versions. Modify at your own risk, but feel free to mess with it.

#Setup Caddy Prereqs
Caddy is used for Reverse Proxy. This will make it so your players can just type in your subdomain to connect to your game.

# Install Caddy and Node
It also installs a few other items that are needed such as NPM and Unzip. 

# Create system user
It creates a user called foundry. After the script is finished I usually force a password onto this account so I can connect using FTP with it. 

# Install PM2
PM2 is used to run Foundry. If you make any system side updates or just need to bounce your foundry instance, you can just use PM2 commands to bounce it. This will also let you run multiple instances of foundry if you so desire, but I have no idea how to set that up.

The rest of the functions go through the installation process and grant the foundry user permissions to the installation folders. It uses the parameters in the first section of the script.

Thank you.
