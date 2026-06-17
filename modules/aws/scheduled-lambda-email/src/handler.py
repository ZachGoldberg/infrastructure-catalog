"""Compute the Nth prime and email it via SES.

A failed SES send is re-raised so it surfaces on the Lambda Errors CloudWatch
alarm rather than failing silently.
"""
import os

import boto3


def nth_prime(n: int) -> int:
    """Return the n-th prime (1-based): nth_prime(10) == 29."""
    if n < 1:
        raise ValueError("prime index must be >= 1")
    primes = []
    candidate = 2
    while len(primes) < n:
        if all(candidate % p != 0 for p in primes if p * p <= candidate):
            primes.append(candidate)
        candidate += 1
    return primes[-1]


def lambda_handler(event, context):
    index = int(os.environ.get("PRIME_INDEX", "10"))
    email = os.environ["EMAIL_ADDRESS"]

    value = nth_prime(index)
    subject = f"The {index}th prime number is {value}"
    body = f"Good morning!\n\nThe {index}th prime number is {value}.\n"

    ses = boto3.client("ses")
    resp = ses.send_email(
        Source=email,
        Destination={"ToAddresses": [email]},
        Message={
            "Subject": {"Data": subject},
            "Body": {"Text": {"Data": body}},
        },
    )
    message_id = resp["MessageId"]
    print(f"sent prime={value} index={index} ses_message_id={message_id}")
    return {"prime": value, "index": index, "messageId": message_id}
