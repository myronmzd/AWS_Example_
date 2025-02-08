#!/usr/bin/env bash

aws ec2 create-key-pair \
  --key-name MyKeyPair \
  --key-type rsa \
  --region ap-south-1 \
  --query 'KeyMaterial' \
  --output text > MyKeyPair.pem
