# TLS Deployment Guide

## TLS Termination
- Terminate TLS at approved ingress/load-balancer layers.
- Enforce TLS-only transport for all external traffic.

## Certificate Rotation
- Rotate certificates on a fixed schedule and on compromise events.
- Track rotation events in change/audit records.

## TLS Minimum Versions and Ciphers
- Minimum protocol: TLS 1.2 (prefer TLS 1.3).
- Disable weak ciphers and legacy protocol versions.

## Log Redaction Requirements
- Never log Authorization headers, tokens, or secret values.
- Ensure request/response logging pipelines redact sensitive headers.
