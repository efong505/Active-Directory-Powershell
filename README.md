# Active-Directory-Powershell
Powershell scripts for Active Directory

# Description
The purpose of this powershell script is to get the list of server machines and allow the user to change the passwords of the machines from powershell. 

# Scripts

## Main Script that you'll run
- servers_pass_change.ps1 - This is the script that you will run that uses the other scripts to run the program. 

## Scripts that main script calls
- get_servers.ps1 - gets the server machines and places them into a text file
- change_password_script.ps1 - the script that goes throught the list and deterimines if the machines are online. If so, allows the user to change the password. Asks user to enter the password twice for verification. 

# How to use:
It's very simple.
1. Download or clone the repository. 
2. Open powershell where you cloned the repository. 
3. Type .\servers_pass_change.ps1
4. Once the script has made the list it will ask you to enter the new password for each machine
5. Repeat the password

That's it. Machine passwords are changed. 

