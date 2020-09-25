#!/bin/bash
cd ~/kubeadm-bootstrap

echo '============================'
echo '= Provsioning Master Node  ='
echo '============================'
sudo -E ./init-master.bash $1

# Enable kubectl bash completion on on master
cat > kubectl << __EOF__
source <(kubectl completion bash)
__EOF__

sudo mv kubectl /etc/bash_completion.d/kubectl
