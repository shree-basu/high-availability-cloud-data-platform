# Architecture

| Tier       | Service            | Responsibility                        |
|------------|--------------------|---------------------------------------|
| Ingestion  | Pub/Sub (+ DLQ)    | Durable buffer; decouples producers   |
| Processing | Dataflow (Beam)    | Validate, transform, route bad records|
| Storage    | Cloud SQL (PG)     | Transactional store, HA + PITR        |
| Serving    | BigQuery           | Analytics at scale                    |
| Monitoring | Python + Cloud Mon | Health checks + 24/7 alerting         |

## Data flow
Producers -> Pub/Sub -> Dataflow -> BigQuery (analytics)
                 |             \-> DLQ table (bad records)
                 \-> Pub/Sub DLQ (undeliverable after 5 attempts)

## Principles
- Every tier fails independently; 24h Pub/Sub retention absorbs outages.
- Idempotency via event_id makes retries safe.
- No public IP on the database; private VPC peering only.