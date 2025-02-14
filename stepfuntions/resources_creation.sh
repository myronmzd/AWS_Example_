#!/usr/bin/env bash


aws lambda create-function \
    --function-name my-function \
    --runtime nodejs18.x \
    --zip-file fileb://my-function.zip \
    --handler my-function.handler \
    --role arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole