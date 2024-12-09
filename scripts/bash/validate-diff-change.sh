#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if two arguments are provided (two branch names)
if [ $# -ne 2 ]; then
  echo "Usage: $0 <branch1> <branch2>"
  exit 1
fi

# Branch names (from the arguments passed)
BRANCH_1=$1
BRANCH_2=$2

# Fetch the latest changes from the remote repository
echo "Fetching latest changes from remote..."
git fetch origin

# Check out the branches to ensure they exist and are up-to-date
echo "Ensuring both branches exist locally and are up-to-date..."
git checkout origin/$BRANCH_1 || { echo "Error: Branch '$BRANCH_1' does not exist."; exit 1; }
git checkout origin/$BRANCH_2 || { echo "Error: Branch '$BRANCH_2' does not exist."; exit 1; }

# Get the list of files that have changed between the two branches
echo "Comparing branches '$BRANCH_1' and '$BRANCH_2'..."

# List the changed files (added, modified, deleted) between the two branches
CHANGED_FILES=$(git diff --name-only origin/$BRANCH_1..origin/$BRANCH_2)

# Check if there are any changes
if [ -z "$CHANGED_FILES" ]; then
  echo "No changes detected between '$BRANCH_1' and '$BRANCH_2'."
else
  echo "Changed files between '$BRANCH_1' and '$BRANCH_2':"
  echo "$CHANGED_FILES"
fi
