"""
Streaming pipeline: Pub/Sub -> validate -> BigQuery (good) / DLQ (bad).

Resilience:
- Malformed messages branch to a dead-letter output instead of crashing.
- BigQuery writes retry on transient errors.
- event_id enables idempotent downstream dedupe.
"""
import argparse
import json
import logging

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions, StandardOptions

DEAD_LETTER = "dead_letter"
VALID = "valid"


class ParseAndValidate(beam.DoFn):
    REQUIRED = ("event_id", "event_type", "event_time")

    def process(self, message_bytes):
        raw = message_bytes.decode("utf-8", errors="replace")
        try:
            record = json.loads(raw)
        except json.JSONDecodeError as e:
            yield beam.pvalue.TaggedOutput(
                DEAD_LETTER, {"raw": raw, "error": f"json_decode: {e}"}
            )
            return

        missing = [f for f in self.REQUIRED if f not in record]
        if missing:
            yield beam.pvalue.TaggedOutput(
                DEAD_LETTER, {"raw": raw, "error": f"missing_fields: {missing}"}
            )
            return

        yield beam.pvalue.TaggedOutput(
            VALID,
            {
                "event_id": record["event_id"],
                "event_type": record["event_type"],
                "payload": json.dumps(record.get("payload", {})),
                "event_time": record["event_time"],
                "ingested_at": None,
            },
        )


def run(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_subscription", required=True)
    parser.add_argument("--output_table", required=True)
    parser.add_argument("--dead_letter_table", required=True)
    args, pipeline_args = parser.parse_known_args(argv)

    options = PipelineOptions(pipeline_args, streaming=True, save_main_session=True)
    options.view_as(StandardOptions).streaming = True

    with beam.Pipeline(options=options) as p:
        parsed = (
            p
            | "ReadPubSub" >> beam.io.ReadFromPubSub(subscription=args.input_subscription)
            | "ParseValidate" >> beam.ParDo(ParseAndValidate()).with_outputs(
                DEAD_LETTER, VALID
            )
        )

        (
            parsed[VALID]
            | "WriteEvents" >> beam.io.WriteToBigQuery(
                args.output_table,
                write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
                create_disposition=beam.io.BigQueryDisposition.CREATE_NEVER,
                insert_retry_strategy="RETRY_ON_TRANSIENT_ERROR",
            )
        )

        (
            parsed[DEAD_LETTER]
            | "WriteDLQ" >> beam.io.WriteToBigQuery(
                args.dead_letter_table,
                schema="raw:STRING,error:STRING",
                write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
                create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED,
            )
        )


if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    run()