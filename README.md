# High-Availability Cloud Data Platform

Production-oriented reference architecture for building a highly available, fault-tolerant data platform on Google Cloud Platform using Terraform, Pub/Sub, Dataflow, Cloud SQL for PostgreSQL, BigQuery, Cloud Monitoring, Python, and GitHub Actions.

## Business Problem

Modern data platforms must continue processing events even when individual components fail.

This project models a multi-tier cloud data platform designed to:

- decouple producers from downstream processing
- absorb temporary processing outages
- prevent bad records from contaminating analytical datasets
- provide a highly available transactional database
- separate transactional and analytical workloads
- automate infrastructure validation and deployment
- detect operational failures through health checks and monitoring
- define recovery objectives and operational procedures

The design focuses on reliability, fault isolation, idempotent processing, infrastructure as code, and operational readiness.

## Architecture

```text
                         DATA PRODUCERS
                              |
                              v
                    +-------------------+
                    |      Pub/Sub      |
                    |   Ingestion Topic |
                    +---------+---------+
                              |
                     retry / acknowledgement
                              |
                              v
                    +-------------------+
                    | Dataflow / Apache |
                    |       Beam        |
                    +----+---------+----+
                         |         |
                    valid events   invalid events
                         |         |
                         v         v
              +----------------+  +----------------+
              |    BigQuery    |  |   DLQ / Bad   |
              | Analytics Data |  |    Records     |
              +----------------+  +----------------+

                         TRANSACTIONAL
                              |
                              v
                    +-------------------+
                    | Cloud SQL         |
                    | PostgreSQL        |
                    | HA + PITR         |
                    +-------------------+

                    +-------------------+
                    | Cloud Monitoring  |
                    | Python Health     |
                    | Checks + Alerts   |
                    +-------------------+

Infrastructure:
Terraform + GitHub Actions


## Repository Structure

.
├── .github/
│   └── workflows/
│       ├── deploy.yml
│       ├── python-checks.yml
│       └── terraform-validate.yml
│
├── dataflow/
│   ├── requirements.txt
│   └── streaming_pipeline.py
│
├── docs/
│   ├── architecture.md
│   ├── rpo_rto.md
│   └── runbook.md
│
├── ops/
│   ├── health_checks.py
│   └── requirements.txt
│
├── sql/
│   └── schema.sql
│
├── terraform/
│   ├── bigquery.tf
│   ├── cloudsql.tf
│   ├── dataflow.tf
│   ├── monitoring.tf
│   ├── network.tf
│   ├── outputs.tf
│   ├── pubsub.tf
│   ├── variables.example.tfvars
│   ├── variables.tf
│   └── versions.tf
│
└── .gitignore
