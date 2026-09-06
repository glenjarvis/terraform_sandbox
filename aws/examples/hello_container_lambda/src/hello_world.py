"""Minimal Lambda handler: greets whoever the invoke payload names."""


def handler(event, context):
    """Return a greeting.

    `event` is the JSON payload passed to the invoke. Anything under the
    "name" key is echoed back, so you can see the payload make the round
    trip.
    """
    name = event.get("name", "world") if isinstance(event, dict) else "world"
    return_body = f"Hello, {name}!"
    print(return_body)

    return {
        "statusCode": 200,
        "body": return_body,
        "event": event,
    }
