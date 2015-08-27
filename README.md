#auto_deploy

This script will automate the deployment of a Yelp Pizza App sample along with any required dependencies, if not already installed.

Environment: Linux OS - CentOS/RedHat (I used this script on CentOS 6.3 in particular)

##Install
Clone the "deploy.sh" script into a directory of your choice: `git clone https://github.com/jpena23/auto_deploy.git` <br /> 
Navigate to this directory "cd /path/to/your/directory". <br /> 
Run "bash deploy.sh" from the command line. <br />
The script may prompt you to enter in your MySQL credentials if you already have it installed. <br />

##Notes 
Must be ran by root user. <br />
The default password for the MySQL root password is empty. <br />
