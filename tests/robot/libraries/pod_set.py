"""
Library to parse JSON string to Python object usable for pod set definitions.
"""

import json

def from_string(text):
    obj = json.loads(text)
    # Validate all required fields are there.
    pod_set = obj["pod_set"]
    for item in pod_set:
        template = item["template"]
        name = item["name"]
        replicas = item["replicas"]
        location = item["location"]
        # TODO: Should we validate location? Should "1", "2" point to "client_node" and "server_node"?
    return obj
