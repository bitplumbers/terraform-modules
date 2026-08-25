#!/bin/bash
set -e

# Set terminal type for SSM sessions
echo "export TERM=xterm-256color" >> /etc/profile.d/ssm.sh
echo "export TERM=xterm-256color" >> /root/.bashrc
echo "export TERM=xterm-256color" >> /home/ubuntu/.bashrc

# Create a bash wrapper script
cat > /usr/local/bin/ssm-bash << 'BASHWRAP'
#!/bin/bash
exec bash "$@"
BASHWRAP
chmod +x /usr/local/bin/ssm-bash

# Update system
apt-get update
apt-get upgrade -y

# Install common tools
apt-get install -y \
  curl \
  wget \
  git \
  vim \
  htop \
  net-tools \
  postgresql-client \
  jq \
  unzip \
  awscli

# Configure bash for better SSM session experience
cat > /etc/profile.d/bash-config.sh << 'BASHCONF'
# Enable bash history search with Ctrl+R
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# Set history size
HISTSIZE=10000
HISTFILESIZE=20000

# Append to history instead of overwriting
shopt -s histappend

# Save history immediately
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
BASHCONF

# Set permissions
chmod 644 /etc/profile.d/bash-config.sh

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*
