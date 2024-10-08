from airflow import DAG
from airflow.kubernetes.secret import Secret
from airflow.operators.python import PythonOperator
from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import (
    KubernetesPodOperator,
)
from airflow.utils.dates import days_ago
from kubernetes.client import models as k8s
import pandas as pd

kaggle_secret = Secret(
    deploy_type="volume",
    deploy_target="/home/airflow/.kaggle/",
    secret="kaggle",
    key="kaggle.json",
)

volume = k8s.V1Volume(
    name="airflow-shared",
    persistent_volume_claim=k8s.V1PersistentVolumeClaimVolumeSource(
        claim_name="airflow-efs-shared"
    ),
)

volume_mount = k8s.V1VolumeMount(
    name="airflow-shared", mount_path="/pipeline-data/", sub_path="pipeline-data"
)

download_and_unzip_args = (
    "kaggle datasets download -d himalayaashish/medi-drug-dataset -p ~/;"
    "unzip -o ~/medi-drug-dataset.zip -d /pipeline-data/;"
)


def _process_data():
    df = pd.read_csv("/pipeline-data/Medi_Drug.csv")
    df.drop(columns="Information", inplace=True)
    df["Indication"] = df["Indication"].str.replace("\r\n", "Unidentified")
    df.to_csv("/pipeline-data/pipeline-output.csv", index=False)


with DAG(
    dag_id="med-drug-prep",
    start_date=days_ago(1),
    schedule="@daily",
    catchup=False,
):
    executor_config = {
        "pod_override": k8s.V1Pod(
            spec=k8s.V1PodSpec(
                containers=[
                    k8s.V1Container(
                        name="base",
                        volume_mounts=[
                            k8s.V1VolumeMount(
                                mount_path="/pipeline-data/",
                                name="airflow-shared",
                                sub_path="pipeline-data",
                            )
                        ],
                    )
                ]
            )
        )
    }

    download_and_unzip = KubernetesPodOperator(
        task_id="download_and_unzip",
        name="download_and_unzip",
        executor_config=executor_config,
        image="realz/airflow-custom:v1",
        cmds=["sh", "-c"],
        arguments=[download_and_unzip_args],
        secrets=[kaggle_secret],
        volumes=[volume],
        volume_mounts=[volume_mount],
        get_logs=True,
        is_delete_operator_pod=True,
    )

    process_data = PythonOperator(
        task_id="process_data",
        python_callable=_process_data,
        executor_config=executor_config,
    )

    download_and_unzip >> process_data
