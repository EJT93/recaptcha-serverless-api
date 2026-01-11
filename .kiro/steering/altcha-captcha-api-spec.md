# Altcha CAPTCHA Verification API - Steering Specification

## 1. Context and Goals

### Product Overview
The Altcha CAPTCHA Verification API is a centralized, privacy-preserving CAPTCHA verification service that provides a reCAPTCHA-like integration experience for client applications. The service is built on the open-source Altcha protocol and deployed as serverless AWS Lambda functions behind API Gateway.

### Primary Goals
- **Seamless Integration**: Provide a drop-in replacement experience similar to reCAPTCHA with minimal client-side changes
- **Privacy-First**: Self-hosted solution that eliminates third-party data sharing and tracking concerns
- **Cost-Efficient**: Serverless architecture (AWS Lambda) that scales to zero and charges only for actual usage
- **Multi-Tenant**: Support multiple applications through appId-based isolation with independent configuration
- **Developer-Friendly**: Clear API contracts, comprehensive error handling, and predictable behavior

### Explicit Non-Goals
- **Full Bot Mitigation**: This is not a comprehensive WAF or advanced bot detection system
- **Behavioral Analytics**: No user profiling, session tracking, or behavioral pattern analysis
- **Advanced Threat Protection**: Not designed to handle sophisticated CAPTCHA-solving farms or targeted attacks
- **Real-time Fraud Detection**: No machine learning-based risk scoring or adaptive challenges
- **Custom Challenge Types**: Only supports Altcha's proof-of-work challenge mechanism

## 2. High-Level Architecture

### Core Components

**Challenge Generation Service**
- AWS Lambda function behind API Gateway
- Generates cryptographic challenges using Altcha protocol
- Retrieves app-specific configuration (difficulty, expiration, secrets)
- Returns challenge payload compatible with Altcha widget

**Solution Verification Service**
- AWS Lambda function behind API Gateway
- Validates submitted Altcha tokens using cryptographic verification
- Enforces replay protection and expiration policies
- Returns deterministic success/failure responses

**Configuration Store**
- DynamoDB table for app-level settings (difficulty, origins, status)
- AWS Secrets Manager for cryptographic secrets and API keys
- SSM Parameter Store for system-level configuration

### Data Flow
```
Browser → Client App Frontend → Challenge Endpoint → Challenge Response
Browser → Altcha Widget → User Interaction → Token Generation
Browser → Client App Backend → Verify Endpoint → Verification Response
```

### Trust Boundaries
- **Public Boundary**: API Gateway endpoints (HTTPS only, rate-limited)
- **Application Boundary**: API key authentication between client apps and service
- **Internal Boundary**: Lambda functions access configuration store with IAM roles
- **Secret Boundary**: All cryptographic material stored in AWS Secrets Manager, never logged or returned

## 3. API Specification

### Challenge Endpoint

**Route**: `POST /v1/captcha/challenge`

**Headers**
- `Content-Type: application/json` (required)
- `X-App-Id: string` (required) - Application identifier
- `X-Api-Key: string` (required) - Application API key for authentication
- `Origin: string` (optional but validated if present)
- `User-Agent: string` (optional, logged for debugging)

**Request Schema**
```json
{
  "appId": "string (required, 1-64 chars, alphanumeric + hyphens)",
  "clientHints": {
    "difficulty": "number (optional, 1-100000, overrides app default if within bounds)",
    "expires": "number (optional, seconds, max 3600, overrides app default)"
  }
}
```

**Response Schema**
```json
{
  "challenge": "string (required, base64-encoded challenge data)",
  "algorithm": "string (required, always 'SHA-256')",
  "salt": "string (required, base64-encoded salt)",
  "signature": "string (required, HMAC signature for verification)",
  "expires": "number (required, Unix timestamp)",
  "maxNumber": "number (required, maximum number for proof-of-work)"
}
```

**Status Codes**
- `200`: Challenge generated successfully
- `400`: Malformed request body or invalid parameters
- `401`: Invalid or missing API key
- `403`: App suspended or origin not allowed
- `429`: Rate limit exceeded (per-IP or per-app)
- `500`: Internal server error

### Verification Endpoint

**Route**: `POST /v1/captcha/verify`

**Headers**
- `Content-Type: application/json` (required)
- `X-App-Id: string` (required) - Application identifier
- `X-Api-Key: string` (required) - Application API key for authentication
- `X-Forwarded-For: string` (optional, for IP-based rate limiting)
- `User-Agent: string` (optional, logged for debugging)

**Request Schema**
```json
{
  "appId": "string (required, must match X-App-Id header)",
  "token": "string (required, Altcha token from widget)",
  "clientInfo": {
    "ip": "string (optional but recommended, IPv4/IPv6)",
    "userAgent": "string (optional, for debugging)"
  }
}
```

**Response Schema**
```json
{
  "success": "boolean (required)",
  "reason": "string (optional, enum: invalid-token, expired, replay, app-disabled, rate-limited, malformed)",
  "meta": {
    "requestId": "string (required, UUID for tracing)",
    "processingTimeMs": "number (required, for monitoring)"
  }
}
```

**Status Codes**
- `200`: Verification completed (check success field for result)
- `400`: Malformed request body
- `401`: Invalid or missing API key
- `403`: App suspended
- `429`: Rate limit exceeded
- `500`: Internal server error

## 4. Behavior and Invariants

### Challenge Endpoint Behavior

**Validation Steps**
1. Validate `X-App-Id` header matches request body `appId`
2. Authenticate using `X-Api-Key` against stored app credentials
3. Verify app status is `active` (not `suspended` or `disabled`)
4. If `Origin` header present, validate against app's `allowedOrigins` list
5. Apply client hints within app's configured bounds

**Challenge Generation**
- Use app-specific secret from Secrets Manager for HMAC signing
- Set difficulty based on app configuration, respecting client hints if within bounds
- Set expiration timestamp (default 10 minutes, max 1 hour)
- Generate cryptographically secure salt and challenge data
- Return payload compatible with Altcha widget specification

**Invariants**
- Every challenge must be verifiable using the same app secret
- Challenge expiration must be enforced during verification
- Salt must be unique per challenge to prevent rainbow table attacks
- Signature must validate challenge integrity

### Verification Endpoint Behavior

**Verification Steps**
1. Validate request format and required fields
2. Authenticate app using API key
3. Parse and validate Altcha token structure
4. Retrieve app secret for cryptographic verification
5. Verify token signature using Altcha protocol
6. Check challenge expiration timestamp
7. Enforce replay protection (token can only be used once)
8. Return deterministic result

**Success Conditions**
- Token signature is cryptographically valid
- Challenge has not expired
- Token has not been used before (replay protection)
- App is in active status

**Failure Conditions**
- `invalid-token`: Malformed token or signature verification failed
- `expired`: Challenge timestamp is past expiration
- `replay`: Token has been successfully verified before
- `app-disabled`: Application is suspended or disabled
- `rate-limited`: Request exceeds rate limits

**Invariants**
- Verification is deterministic for identical inputs
- No token can be successfully verified more than once
- Verification never leaks information about which validation step failed
- All cryptographic operations use constant-time comparisons

### Rate Limiting and Abuse Handling

**Rate Limits**
- Per-IP: 100 requests per minute across all endpoints
- Per-App: 1000 requests per minute per endpoint
- Burst allowance: 2x rate limit for short periods

**Abuse Response**
- Return `429` status with `Retry-After` header
- Log rate limit events for monitoring
- Implement exponential backoff for repeated violations
- No permanent blocking (limits reset after time window)

## 5. Configuration and Multi-Tenancy Model

### App Identity Management

**App ID Generation**
- Format: `app-{random-uuid}` (e.g., `app-123e4567-e89b-12d3-a456-426614174000`)
- Unique across all environments
- Immutable once created

**API Key Management**
- Primary and secondary keys per app (for rotation)
- 256-bit random keys, base64-encoded
- Stored as hashed values in configuration store
- Support key rotation without service interruption

### Configuration Model

**App Configuration Schema**
```json
{
  "appId": "string (primary key)",
  "displayName": "string (human-readable name)",
  "status": "enum (active, suspended, disabled)",
  "allowedOrigins": ["string (URLs or wildcards)"],
  "challengeConfig": {
    "difficulty": "number (1-100000, default 10000)",
    "expirationSeconds": "number (60-3600, default 600)",
    "algorithm": "string (always SHA-256)"
  },
  "rateLimits": {
    "requestsPerMinute": "number (default 1000)",
    "burstMultiplier": "number (default 2.0)"
  },
  "createdAt": "ISO8601 timestamp",
  "updatedAt": "ISO8601 timestamp"
}
```

**Configuration Storage**
- App metadata in DynamoDB with appId as partition key
- Cryptographic secrets in AWS Secrets Manager with path `/altcha/apps/{appId}/secret`
- API key hashes in DynamoDB app record
- System configuration in SSM Parameter Store

### Key and Secret Management

**Secret Storage Strategy**
- All secrets stored in AWS Secrets Manager with automatic rotation capability
- Secrets never returned in API responses
- Secrets never logged in plaintext
- Access controlled via IAM roles with least privilege

**Key Rotation Process**
- Support dual-key validation during rotation period
- New challenges use new secret, old tokens verified with appropriate secret
- Rotation window configurable per app (default 24 hours)

## 6. Security, Privacy, and Compliance

### Security Requirements

**Transport Security**
- All endpoints served exclusively over HTTPS (TLS 1.2+)
- HTTP requests automatically redirected to HTTPS
- HSTS headers enforced with long max-age

**Authentication and Authorization**
- API key authentication for all endpoints
- Keys transmitted in headers, never in URL parameters
- Constant-time comparison for all authentication operations
- Failed authentication attempts logged and monitored

**Input Validation**
- Strict JSON schema validation for all requests
- Content-Type header validation
- Request size limits (max 1KB for challenge, 4KB for verify)
- SQL injection and XSS prevention through parameterized queries

**Logging and Monitoring**
- Never log complete tokens, secrets, or API keys
- Log only: appId, requestId, timestamp, endpoint, status, processing time
- Structured logging with correlation IDs
- Security events logged to separate audit stream

### Privacy Requirements

**Data Minimization**
- No cookies set by the service
- No user tracking or profiling
- IP addresses used only for rate limiting, not stored long-term
- User-Agent logged only for debugging, not analyzed

**Data Retention**
- Challenge/verification logs retained for 30 days maximum
- Rate limiting data expires after 24 hours
- No persistent user identifiers stored
- Replay protection tokens expire with challenge expiration

**Third-Party Data Sharing**
- Zero data sharing with external services
- Self-hosted solution eliminates reCAPTCHA privacy concerns
- All processing occurs within customer's AWS account

### Compliance Considerations

**GDPR Compliance**
- No personal data processing beyond technical necessity
- IP addresses processed under legitimate interest for security
- Data subject rights supported through app-level controls
- Privacy by design architecture

**Threat Model**
- **In Scope**: Basic bot traffic, automated form submissions, simple scripted attacks
- **Out of Scope**: Advanced persistent threats, CAPTCHA-solving services, targeted attacks
- **Assumptions**: Attackers have limited computational resources, no access to app secrets

## 7. Operational Characteristics

### Performance and Scalability

**Latency Budgets**
- Challenge endpoint: p95 < 200ms, p99 < 500ms
- Verification endpoint: p95 < 150ms, p99 < 300ms
- Cold start impact: < 1s for first request after idle period

**Scalability Assumptions**
- Expected QPS: 1-10,000 requests per second per app
- Lambda concurrency: Auto-scaling with reserved capacity for high-volume apps
- DynamoDB: On-demand billing with burst capacity
- API Gateway: Regional deployment with CloudFront for global distribution

**Resource Limits**
- Lambda memory: 512MB (sufficient for cryptographic operations)
- Lambda timeout: 30 seconds (actual processing < 1 second)
- API Gateway payload: 10MB (actual payloads < 4KB)

### Observability

**Logging Strategy**
```json
{
  "timestamp": "ISO8601",
  "requestId": "UUID",
  "appId": "string",
  "endpoint": "challenge|verify",
  "statusCode": "number",
  "processingTimeMs": "number",
  "errorType": "string (if error)",
  "clientInfo": {
    "ip": "string (hashed for privacy)",
    "origin": "string"
  }
}
```

**Key Metrics**
- Request volume by endpoint, app, and status code
- Response time percentiles (p50, p95, p99)
- Error rates by type and app
- Rate limiting events
- Challenge success/failure rates
- Lambda cold start frequency and duration

**Alerting Thresholds**
- Error rate > 5% for 5 minutes
- p95 latency > 500ms for 10 minutes
- Rate limiting > 100 events per minute
- Lambda errors or timeouts

**Distributed Tracing**
- X-Ray integration for request flow visibility
- Correlation IDs passed between services
- Performance bottleneck identification

### Deployment and Environments

**Environment Strategy**
- **Development**: Single region, minimal resources, test data
- **Staging**: Production-like setup, synthetic load testing
- **Production**: Multi-AZ deployment, auto-scaling, monitoring

**Configuration Differences**
- Development: Relaxed rate limits, verbose logging, test API keys
- Staging: Production rate limits, production-like secrets rotation
- Production: Strict limits, minimal logging, encrypted secrets

**Deployment Process**
- Blue/green deployment through API Gateway stages
- Automated rollback on health check failures
- Database migrations applied before code deployment
- Zero-downtime deployments required

### Backward Compatibility and Versioning

**API Versioning Strategy**
- URL-based versioning: `/v1/`, `/v2/`
- v1 API guaranteed stable for minimum 2 years
- Breaking changes require new version
- Deprecation notices provided 6 months before removal

**Schema Evolution**
- Additive changes allowed within same version
- Optional fields can be added to responses
- Required fields never removed from existing version
- Client libraries must handle unknown response fields gracefully

## 8. Integration Guide for Client Applications

### Frontend Integration (Browser-Side)

**Altcha Widget Integration**
1. Include Altcha widget library in HTML/React application
2. Configure widget to point to challenge endpoint: `POST /v1/captcha/challenge`
3. Pass app-specific configuration (appId) to widget
4. Handle widget events: challenge loaded, solution generated, errors
5. Extract generated token from widget for backend submission

**Error Handling Patterns**
- Network failures: Retry with exponential backoff
- Rate limiting: Display user-friendly message, implement client-side backoff
- Challenge expiration: Automatically request new challenge
- Widget loading failures: Graceful degradation or alternative verification

### Backend Integration (Server-Side)

**Verification Flow**
1. Receive form submission with Altcha token from frontend
2. Call verification endpoint: `POST /v1/captcha/verify`
3. Include client IP and User-Agent for enhanced security
4. Handle verification response deterministically
5. Proceed with form processing only on successful verification

**Error Handling Strategy**
- **Hard Failures**: Invalid token, expired challenge → Block request
- **Soft Failures**: Rate limiting, service unavailable → Allow with logging
- **Retry Logic**: Implement for 5xx errors only, not 4xx errors
- **Fallback**: Consider alternative verification methods for service outages

**Security Best Practices**
- Always verify tokens server-side, never trust client-side validation
- Include request context (IP, User-Agent) in verification calls
- Log verification attempts for security monitoring
- Implement additional rate limiting at application level

### SDK and Library Considerations

**Client Library Requirements**
- Support for all major languages (JavaScript, Python, Java, Go, PHP)
- Automatic retry logic with exponential backoff
- Built-in error handling and logging
- Configuration management for different environments
- Type definitions for request/response schemas

**Integration Examples**
```javascript
// Frontend (React)
<AltchaWidget
  challengeUrl="/api/captcha/challenge"
  onSolution={(token) => setToken(token)}
  onError={(error) => handleError(error)}
/>

// Backend (Node.js)
const result = await altchaClient.verify({
  appId: 'app-123',
  token: requestBody.token,
  clientInfo: {
    ip: req.ip,
    userAgent: req.get('User-Agent')
  }
});
```

### Contract Stability Guarantees

**API Stability Promise**
- Request/response schemas remain backward compatible within major version
- New optional fields may be added to responses
- Existing field types and semantics never change
- Endpoint URLs and HTTP methods remain stable

**Breaking Change Process**
1. Announce breaking changes 6 months in advance
2. Release new major version with breaking changes
3. Support previous version for minimum 12 months
4. Provide migration guide and tooling
5. Deprecate old version with clear timeline

## 9. Acceptance Criteria and Guardrails

### Implementation Requirements

**API Contract Compliance**
- [ ] All endpoints conform exactly to documented request/response schemas
- [ ] JSON schema validation enforced for all requests
- [ ] HTTP status codes match specification exactly
- [ ] Error responses include required fields (success, reason, meta)

**Security and Privacy**
- [ ] No secrets, tokens, or API keys logged in plaintext
- [ ] All authentication uses constant-time comparison
- [ ] HTTPS enforced for all endpoints
- [ ] Input validation prevents injection attacks

**Functional Correctness**
- [ ] Verification is deterministic for identical inputs
- [ ] Replay protection prevents token reuse
- [ ] Challenge expiration enforced consistently
- [ ] Rate limiting works across all endpoints

**Operational Readiness**
- [ ] Structured logging with correlation IDs
- [ ] Metrics collection for all key performance indicators
- [ ] Health checks return meaningful status
- [ ] Deployment process supports zero-downtime updates

### Code Review Checklist

**Security Review**
- [ ] No hardcoded secrets or credentials
- [ ] All user inputs validated and sanitized
- [ ] Error messages don't leak sensitive information
- [ ] Cryptographic operations use secure libraries

**Performance Review**
- [ ] Database queries use appropriate indexes
- [ ] Lambda functions stay within memory/timeout limits
- [ ] No blocking operations in request path
- [ ] Caching implemented where appropriate

**Reliability Review**
- [ ] Error handling covers all failure modes
- [ ] Retry logic implemented with backoff
- [ ] Circuit breakers prevent cascade failures
- [ ] Graceful degradation for dependency failures

**Observability Review**
- [ ] All errors logged with sufficient context
- [ ] Metrics emitted for business and technical KPIs
- [ ] Distributed tracing spans created
- [ ] Log levels appropriate for environment

### Documentation Requirements

**API Documentation**
- [ ] OpenAPI specification generated from this spec
- [ ] Interactive API documentation available
- [ ] Code examples for all major languages
- [ ] Error response examples for all status codes

**Integration Documentation**
- [ ] Step-by-step integration guide for frontend
- [ ] Backend integration examples with error handling
- [ ] SDK documentation and examples
- [ ] Migration guide from other CAPTCHA services

**Operational Documentation**
- [ ] Deployment runbook with rollback procedures
- [ ] Monitoring and alerting setup guide
- [ ] Troubleshooting guide for common issues
- [ ] Security incident response procedures

This specification serves as the single source of truth for implementing the Altcha CAPTCHA Verification API. All implementation decisions should reference back to these requirements, and any ambiguities should be resolved through updates to this document.