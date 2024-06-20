#!/bin/bash
# This script creates PV and PVC for Airflow
#

EFS_PV_NAME="efs-pv"
VOLUME_HANDLE=$(kubectl get pv $EFS_PV_NAME -o jsonpath='{.spec.csi.volumeHandle}')
echo $VOLUME_HANDLE

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: airflow-efs-shared
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 5Gi
  csi:
    driver: efs.csi.aws.com
    volumeHandle: $VOLUME_HANDLE
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  volumeMode: Filesystem
EOF

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: airflow-efs-shared
  namespace: airflow
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: efs-sc
  volumeMode: Filesystem
  volumeName: airflow-efs-shared
EOF
