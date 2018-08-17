#!/bin/bash
cd ~/kubeadm-bootstrap
sudo -E ./init-master.bash

# Enable kubectl bash completion on on master
cat > /etc/bash_completion.d/kubectl << __EOF__
source <(kubectl completion bash)
__EOF__
