"""
Operational health checks for the HA data platform.
Non-zero exit if any check fails.
"""
import sys
import argparse
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from google.cloud import monitoring_v3
from google.cloud import bigquery


@dataclass
class HealthResult:
    name: str
    ok: bool
    detail: str

    def __str__(self):
        status = "PASS" if self.ok else "FAIL"
        return f"[{status}] {self.name}: {self.detail}"


def _subscription_backlog(project_id, subscription_id):
    client = monitoring_v3.MetricServiceClient()
    now = datetime.now(timezone.utc)
    interval = monitoring_v3.TimeInterval(
        {
            "end_time": {"seconds": int(now.timestamp())},
            "start_time": {"seconds": int((now - timedelta(minutes=5)).timestamp())},
        }
    )
    metric = "pubsub.googleapis.com/subscription/num_undelivered_messages"
    results = client.list_time_series(
        request={
            "name": f"projects/{project_id}",
            "filter": (
                f'metric.type="{metric}" AND '
                f'resource.labels.subscription_id="{subscription_id}"'
            ),
            "interval": interval,
            "view": monitoring_v3.ListTimeSeriesRequest.TimeSeriesView.FULL,
        }
    )
    latest = 0
    for series in results:
        for point in series.points:
            latest = int(point.value.int64_value)
            break
    return latest


def check_dead_letter(project_id, dlq_subscription, threshold=0):
    try:
        backlog = _subscription_backlog(project_id, dlq_subscription)
        ok = backlog <= threshold
        detail = f"{backlog} messages in DLQ (threshold {threshold})."
        if not ok:
            detail += " Investigate poison/malformed events."
        return HealthResult("dead_letter_backlog", ok, detail)
    except Exception as e:
        return HealthResult("dead_letter_backlog", False, f"check errored: {e}")


def check_ingestion_backlog(project_id, subscription, threshold=1000):
    try:
        backlog = _subscription_backlog(project_id, subscription)
        ok = backlog <= threshold
        detail = f"{backlog} undelivered messages (threshold {threshold})."
        if not ok:
            detail += " Pipeline may be down or under-scaled."
        return HealthResult("ingestion_backlog", ok, detail)
    except Exception as e:
        return HealthResult("ingestion_backlog", False, f"check errored: {e}")


def check_data_freshness(project_id, dataset, table, max_age_minutes=30):
    try:
        client = bigquery.Client(project=project_id)
        query = f"""
            SELECT TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(ingested_at), MINUTE) AS age_min
            FROM `{project_id}.{dataset}.{table}`
        """
        row = next(iter(client.query(query).result()))
        age = row.age_min
        if age is None:
            return HealthResult("data_freshness", False, "table is empty.")
        ok = age <= max_age_minutes
        detail = f"newest row is {age} min old (max {max_age_minutes})."
        return HealthResult("data_freshness", ok, detail)
    except Exception as e:
        return HealthResult("data_freshness", False, f"check errored: {e}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--project_id", required=True)
    parser.add_argument("--subscription", required=True)
    parser.add_argument("--dlq_subscription", required=True)
    parser.add_argument("--dataset", required=True)
    parser.add_argument("--table", default="events")
    args = parser.parse_args()

    checks = [
        check_dead_letter(args.project_id, args.dlq_subscription),
        check_ingestion_backlog(args.project_id, args.subscription),
        check_data_freshness(args.project_id, args.dataset, args.table),
    ]

    print("=" * 60)
    print("HA DATA PLATFORM - HEALTH REPORT")
    print("=" * 60)
    for c in checks:
        print(c)

    if any(not c.ok for c in checks):
        print("\nOverall: UNHEALTHY")
        sys.exit(1)
    print("\nOverall: HEALTHY")
    sys.exit(0)


if __name__ == "__main__":
    main()