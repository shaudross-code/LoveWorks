#!/bin/bash
while ! /opt/homebrew/bin/brew list | grep -q mongodb-community; do
  echo "Waiting for mongo install..."
  sleep 2
done
echo "Starting mongod..."
/opt/homebrew/bin/brew services start mongodb/brew/mongodb-community@7.0
sleep 3
cd backend
source venv/bin/activate
uvicorn server:app --reload &
