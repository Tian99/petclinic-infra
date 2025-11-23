import base64
import json
import os

from googleapiclient.discovery import build


def main(event, context):

    project_id = os.environ["PROJECT_ID"]
    backend_service = os.environ["BACKEND_SERVICE"]
    eu_neg_name = os.environ["EU_NEG_NAME"]
    us_neg_name = os.environ["US_NEG_NAME"]

    print(f"Received failover event: {event}")

    compute = build("compute", "v1")

    bs = (
        compute.backendServices()
        .get(project=project_id, backendService=backend_service)
        .execute()
    )

    print("Current backends:", bs.get("backends", []))

    for backend in bs.get("backends", []):
        group = backend["group"]
        if eu_neg_name in group:
            backend["maxRatePerEndpoint"] = 100
            backend["balancingMode"] = "RATE"
            print(f"Set EU backend {group} to 100%")
        elif us_neg_name in group:
            backend["maxRatePerEndpoint"] = 0
            backend["balancingMode"] = "RATE"
            print(f"Set US backend {group} to 0%")

    op = (
        compute.backendServices()
        .patch(project=project_id, backendService=backend_service, body=bs)
        .execute()
    )

    print("Patch operation started:", op.get("name"))
    return "Failover triggered"