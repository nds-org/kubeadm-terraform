#!/usr/bin/env bash

# Parse a json document from the terraform external data operation. Expects:
#    an element called 'host' which contains the public IP address of the
#                             bootstrapped master node.
#    an element called 'private_key' which contains the path to the private
#                             key file which will grant us ssh access to master


# Exit if any of the intermediate steps fail
set -e

# Extract input variables
eval "$(jq -r '@sh "HOST=\(.host) PRIVATE_KEY=\(.private_key)"')"

# Ask kubeadm on master to generate a fully formed join command, suitable for
# executing on each of the workers
JOIN_COMMAND=$(ssh -i $PRIVATE_KEY -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@$HOST sudo kubeadm token create --print-join-command)

# Return it in a JSON result
jq -n --arg command "$JOIN_COMMAND" '{"command":$command}'
