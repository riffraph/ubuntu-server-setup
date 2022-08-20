# Bash setup script for Ubuntu servers

This is a fork of https://github.com/jasonheecs/ubuntu-server-setup.git.

It is a work in progress.


This is a setup script to automate the setup and provisioning of Ubuntu servers. It does the following:
* Adds or updates a user account with sudo access
* Adds a public ssh key for the new user account
* Disables password authentication to the server
* Deny root login to the server
* Setup Firewall
* Create Swap file based on machine's installed memory
* Setup the timezone for the server
* Install Network Time Protocol
* Install Docker engine


# Installation

Clone this repository and run the base set up script:
```bash
cd /
git clone https://github.com/riffraph/ubuntu-server-setup.git
cd ubuntu-server-setup
chmod g+x *.sh
sudo setup-base.sh
```


# Setup prompts
When the setup script is run, you will be prompted to enter the username of the new user account. 

Following that, you will then be prompted to add a public ssh key (which should be from your local machine) for the new account. To generate an ssh key from your local machine:
```bash
ssh-keygen -t ed25519 -a 200 -C "user@server" -f ~/.ssh/user_server_ed25519
cat ~/.ssh/user_server_ed25519.pub
```

Finally, you will be prompted to specify a [timezone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) for the server. 


# Supported versions
This setup script has been tested against Ubuntu 14.04, Ubuntu 16.04, Ubuntu 18.04, Ubuntu 20.04 and Ubuntu 22.04.

# Running tests
Tests are run against a set of Vagrant VMs. To run the tests, run the following in the project's directory:  
`./tests/tests.sh`
