#!/bin/bash

# Script to create Lambda deployment package
set -e

echo "Creating Lambda deployment package..."

# Create src directory if it doesn't exist
mkdir -p src

# Check if package.json exists, if not create a basic one
if [ ! -f "src/package.json" ]; then
    echo "Creating package.json..."
    cat > src/package.json << EOF
{
  "name": "altcha-captcha-api",
  "version": "1.0.0",
  "description": "Altcha CAPTCHA Verification API Lambda Functions",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "crypto": "^1.0.1"
  },
  "keywords": ["altcha", "captcha", "lambda", "aws"],
  "author": "",
  "license": "MIT"
}
EOF
fi

# Create placeholder Lambda functions if they don't exist
if [ ! -f "src/challenge.js" ]; then
    echo "Creating challenge.js placeholder..."
    cat > src/challenge.js << 'EOF'
const crypto = require('crypto');

exports.handler = async (event) => {
    console.log('Challenge endpoint called:', JSON.stringify(event, null, 2));
    
    try {
        // Parse request body
        const body = JSON.parse(event.body || '{}');
        const { appId, clientHints } = body;
        
        // Basic validation
        if (!appId) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    success: false,
                    reason: 'malformed',
                    meta: {
                        requestId: event.requestContext?.requestId || 'unknown',
                        processingTimeMs: 0
                    }
                })
            };
        }
        
        // Generate challenge (placeholder implementation)
        const salt = crypto.randomBytes(16).toString('base64');
        const challenge = crypto.randomBytes(32).toString('base64');
        const signature = crypto.randomBytes(32).toString('base64');
        const expires = Math.floor(Date.now() / 1000) + (clientHints?.expires || 600);
        const maxNumber = clientHints?.difficulty || 10000;
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                challenge,
                algorithm: 'SHA-256',
                salt,
                signature,
                expires,
                maxNumber
            })
        };
        
    } catch (error) {
        console.error('Error in challenge handler:', error);
        
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: false,
                reason: 'internal-error',
                meta: {
                    requestId: event.requestContext?.requestId || 'unknown',
                    processingTimeMs: 0
                }
            })
        };
    }
};
EOF
fi

if [ ! -f "src/verify.js" ]; then
    echo "Creating verify.js placeholder..."
    cat > src/verify.js << 'EOF'
exports.handler = async (event) => {
    console.log('Verify endpoint called:', JSON.stringify(event, null, 2));
    
    try {
        // Parse request body
        const body = JSON.parse(event.body || '{}');
        const { appId, token, clientInfo } = body;
        
        // Basic validation
        if (!appId || !token) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    success: false,
                    reason: 'malformed',
                    meta: {
                        requestId: event.requestContext?.requestId || 'unknown',
                        processingTimeMs: 0
                    }
                })
            };
        }
        
        // Placeholder verification logic
        // In a real implementation, this would verify the Altcha token
        const success = token.length > 10; // Simple placeholder check
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success,
                reason: success ? undefined : 'invalid-token',
                meta: {
                    requestId: event.requestContext?.requestId || 'unknown',
                    processingTimeMs: Math.floor(Math.random() * 100)
                }
            })
        };
        
    } catch (error) {
        console.error('Error in verify handler:', error);
        
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: false,
                reason: 'internal-error',
                meta: {
                    requestId: event.requestContext?.requestId || 'unknown',
                    processingTimeMs: 0
                }
            })
        };
    }
};
EOF
fi

# Install dependencies if package.json exists
if [ -f "src/package.json" ]; then
    echo "Installing dependencies..."
    cd src
    npm install --production
    cd ..
fi

# Create the deployment package
echo "Creating deployment package..."
cd src
zip -r ../package.zip . -x "*.git*" "*.DS_Store*" "node_modules/.cache/*"
cd ..

echo "Lambda deployment package created successfully: package.zip"
echo "Package contents:"
unzip -l package.zip