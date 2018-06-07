#!/bin/bash
cat >> rook-cluster.yaml << EOF
    - name: "$1"
      directories:
      - path: "/rook"
EOF

