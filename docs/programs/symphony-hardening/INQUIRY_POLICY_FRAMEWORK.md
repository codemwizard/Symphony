# Inquiry Policy Framework

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

This document defines metadata-driven rail inquiry policy entries.

## Policy Entries

### Policy: ZECHL
- rail_id: ZECHL
- cadence_seconds: 120
- retry_window_seconds: 3600
- max_attempts: 12
- timeout_threshold_seconds: 60
- orphan_threshold_seconds: 900
- circuit_breaker_threshold_rate: 0.25
- circuit_breaker_window_seconds: 600

### Policy: DDACC
- rail_id: DDACC
- cadence_seconds: 120
- retry_window_seconds: 3600
- max_attempts: 12
- timeout_threshold_seconds: 60
- orphan_threshold_seconds: 900
- circuit_breaker_threshold_rate: 0.25
- circuit_breaker_window_seconds: 600

### Policy: ZIPSS
- rail_id: ZIPSS
- cadence_seconds: 120
- retry_window_seconds: 3600
- max_attempts: 12
- timeout_threshold_seconds: 60
- orphan_threshold_seconds: 900
- circuit_breaker_threshold_rate: 0.25
- circuit_breaker_window_seconds: 600

### Policy: MMO-*
- rail_id: MMO-*
- cadence_seconds: 120
- retry_window_seconds: 3600
- max_attempts: 12
- timeout_threshold_seconds: 60
- orphan_threshold_seconds: 900
- circuit_breaker_threshold_rate: 0.25
- circuit_breaker_window_seconds: 600
