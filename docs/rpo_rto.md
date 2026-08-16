# RPO / RTO by Component

| Component          | Scenario            | Mechanism                     | RPO      | RTO      |
|--------------------|---------------------|-------------------------------|----------|----------|
| Cloud SQL (zone)   | Primary zone outage | Regional HA auto-failover     | 0 (sync) | ~1-2 min |
| Cloud SQL (data)   | Bad write/corruption| Point-in-time recovery (7d)   | ~seconds | ~30 min  |
| Cloud SQL (region) | Region outage       | Promote replica / restore     | ~minutes | ~1-2 hr  |
| Pub/Sub            | Consumer down       | 24h retention + replay        | 0        | 0        |
| Dataflow           | Worker crash        | Auto-restart + checkpointing  | 0        | ~minutes |
| BigQuery           | Accidental delete   | 7-day time-travel             | ~0       | ~minutes |

## Trade-offs
- Regional HA doubles DB cost for near-zero RPO - justified for the system of record.
- Read replica is zonal (cheaper) and doubles as a DR promotion candidate.
- 7-day PITR balances storage cost vs. how far back we may need to rewind.