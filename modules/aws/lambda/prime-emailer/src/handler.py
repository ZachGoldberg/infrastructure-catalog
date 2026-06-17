"""Computes the Nth prime number and emails it via SES.

Invoked on a schedule by EventBridge Scheduler. No event payload is required.
All configuration is passed via environment variables set by Terraform.
"""
import os

import boto3


def nth_prime(n: int) -> int:
    """Return the n-th prime (1-indexed). nth_prime(10) == 29."""
    if n < 1:
        raise ValueError("n must be >= 1")
    primes = []
    candidate = 2
    while len(primes) < n:
        if all(candidate % p != 0 for p in primes if p * p <= candidate):
            primes.append(candidate)
        candidate += 1
    return primes[-1]


def handler(event, context):
    n = int(os.environ.get("PRIME_INDEX", "10"))
    sender = os.environ["SENDER_EMAIL"]
    recipient = os.environ["RECIPIENT_EMAIL"]

    value = nth_prime(n)
    subject = f"The {n}th prime number is {value}"
    body = (
        f"Good morning!\n\n"
        f"The {n}th prime number is {value}.\n\n"
        f"Have a great day.\n"
    )

    ses = boto3.client("ses")
    resp = ses.send_email(
        Source=sender,
        Destination={"ToAddresses": [recipient]},
        Message={
            "Subject": {"Data": subject, "Charset": "UTF-8"},
            "Body": {"Text": {"Data": body, "Charset": "UTF-8"}},
        },
    )
    message_id = resp["MessageId"]
    print(f"Sent email {message_id}: {subject}")
    return {"messageId": message_id, "prime": value}
