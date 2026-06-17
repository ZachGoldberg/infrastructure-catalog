import os
import boto3


def nth_prime(n):
    primes = []
    candidate = 2
    while len(primes) < n:
        if all(candidate % p for p in primes):
            primes.append(candidate)
        candidate += 1
    return primes[-1]


def lambda_handler(event, context):
    value = nth_prime(10)
    ses = boto3.client("ses", region_name=os.environ["AWS_SES_REGION"])
    resp = ses.send_email(
        Source=os.environ["SES_FROM_ADDRESS"],
        Destination={"ToAddresses": [os.environ["SES_TO_ADDRESS"]]},
        Message={
            "Subject": {"Data": "Your daily prime"},
            "Body": {"Text": {"Data": f"The 10th prime number is {value}."}},
        },
    )
    # Fail loudly so a bad send registers as a Lambda error (drives the Errors alarm).
    if not resp.get("MessageId"):
        raise RuntimeError(f"SES send returned no MessageId: {resp}")
    return {"message_id": resp["MessageId"], "prime": value}
