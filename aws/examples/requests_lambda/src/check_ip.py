"""Report the function's public egress IP, using `requests` from a layer.

`requests` is deliberately absent from this deployment package. It comes
from the layer published by ../requests_layer/, which Lambda unpacks to
/opt/python and puts on sys.path before this module is imported.
"""

import requests

CHECK_IP_URL = "https://checkip.amazonaws.com"


def handler(event, context):
    """Fetch and return the IP address AWS sees this function calling from."""
    response = requests.get(CHECK_IP_URL, timeout=5)
    response.raise_for_status()
    ip = response.text.strip()

    print(f"Egress IP: {ip}")

    return {
        "statusCode": 200,
        "body": ip,
        # Proof of which layer version actually served the import.
        "requests_version": requests.__version__,
        "requests_module": requests.__file__,
    }


if __name__ == "__main__":
    print(handler({}, None))
