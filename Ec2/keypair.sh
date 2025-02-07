#!/usr/bin/env bash

aws ec2 create-key-pair \
  --key-name MyKeyPair \
  --key-type rsa \
  --query 'KeyMaterial' \
  --output text > MyKeyPair.pem
