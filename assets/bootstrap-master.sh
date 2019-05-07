#!/bin/bash
cd ~/kubeadm-bootstrap
sudo -E ./init-master.bash

# Enable kubectl bash completion on on master
cat > kubectl << __EOF__
source <(kubectl completion bash)
__EOF__

sudo mv kubectl /etc/bash_completion.d/kubectl
