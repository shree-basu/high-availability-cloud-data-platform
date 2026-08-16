# Operational Runbook

## Alert: "DLQ has messages"
1. Inspect: SELECT * FROM <dataset>.dlq ORDER BY 1 DESC LIMIT 50;
2. Causes: malformed JSON, missing fields, schema drift.
3. Fix upstream / patch validation, then replay from the DLQ topic.

## Alert: "Ingestion backlog high"
1. Check Dataflow job status - running/scaling?
2. If stalled: drain and redeploy.
3. If volume spike: increase max workers.

## Cloud SQL failover
1. Failover is automatic; confirm status = RUNNABLE.
2. Verify app reconnected (pool refresh).
3. Confirm standby rebuilt in the second zone.

## Region disaster (DR)
1. gcloud sql instances promote-replica hadp-pg-replica-<env>
2. Repoint the application connection string.
3. Rebuild HA on the promoted instance.

## Run health checks
python ops/health_checks.py --project_id "$PROJECT" \
  --subscription hadp-ingestion-sub-dev \
  --dlq_subscription hadp-ingestion-dlq-sub-dev \
  --dataset hadp_analytics_dev