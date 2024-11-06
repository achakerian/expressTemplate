#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Install dependencies
npm install express
npm install --save-dev jest supertest

# Generate an Express app
npx express-generator --no-view

# Install app dependencies
npm install

# Modify app.js to export the app
sed -i '/module.exports = app;/d' app.js
echo 'module.exports = app;' >> app.js

# Create test directory and test file
mkdir -p tests
cat <<EOL > tests/app.test.js
const request = require('supertest');
const app = require('../app');

describe('Test the root path', () => {
  test('It should respond with a 200 status code', async () => {
    const response = await request(app).get('/');
    expect(response.statusCode).toBe(200);
  });
});
EOL

# Update package.json scripts
npm set-script test "jest"

# Create Dockerfile
cat <<EOL > Dockerfile
FROM node:14-alpine

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install --production

COPY . .

EXPOSE 3000
CMD [ "npm", "start" ]
EOL

# Create .dockerignore
echo "node_modules" > .dockerignore
echo "npm-debug.log" >> .dockerignore
echo "tests" >> .dockerignore

# Create GitHub Actions workflow
mkdir -p .github/workflows
cat <<EOL > .github/workflows/ci.yml
name: Node.js CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Use Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '14'

      - name: Install dependencies
        run: npm install

      - name: Run tests
        run: npm test

      - name: Build Docker image
        run: docker build -t myapp .
EOL

# Initialize Git if not already initialized
if [ ! -d ".git" ]; then
  git init
  git add .
  git commit -m "Initial project setup"
fi

echo "Project setup complete."
