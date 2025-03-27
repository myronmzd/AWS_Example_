#!/bin/bash

# Ensure a commit message is passed as an argument
if [ -z "$1" ]; then
  echo "Error: Commit message is required."
  exit 1
fi

# Add all changes (including new files)
git add .

# Commit with the provided message
git commit -m "$1"

# Push the changes to the default remote (usually origin)
git push

# Check for successful push
if [ $? -eq 0 ]; then
  echo "Changes successfully pushed."
else
  echo "Error: Failed to push changes."
  exit 1
fi
