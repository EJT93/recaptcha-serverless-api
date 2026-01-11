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
