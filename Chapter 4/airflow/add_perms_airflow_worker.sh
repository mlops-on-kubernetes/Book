POD_LAUNCHER_ROLE_NAME="airflow-pod-launcher-role"
AIRFLOW_NAMESPACE="airflow"

kubectl -n $AIRFLOW_NAMESPACE patch role $POD_LAUNCHER_ROLE_NAME --type='json' -p='[
  {"op": "add", "path": "/rules/-", "value": {"apiGroups": [""], "resources": ["pods"], "verbs": ["deletecollection"]}},
  {"op": "add", "path": "/rules/-", "value": {"apiGroups": ["sparkoperator.k8s.io"], "resources": ["*"], "verbs": ["*"]}},
  {"op": "add", "path": "/rules/-", "value": {"apiGroups": [""], "resources": ["configmaps"], "verbs": ["*"]}},
  {"op": "add", "path": "/rules/-", "value": {"apiGroups": [""], "resources": ["services", "persistentvolumeclaims"], "verbs": ["deletecollection"]}}
]'
