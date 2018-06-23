#!/bin/bash

set -euo pipefail

docker run -i coxauto/aws-ebcli eb --version

docker run -i -w /work -v $PWD:/work coxauto/aws-ebcli eb status wordpress-test

docker run -i -w /work -v $PWD:/work coxauto/aws-ebcli eb deploy wordpress-test --timeout 30

echo "✓ Deployed to eb"
