from airflow import DAG
from datetime import datetime
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator


today = datetime.now().date()

def my_python_function():
        print("Hello from my_python_function!")

with DAG(
        dag_id="my_dag",
        start_date=datetime(today.year, today.month, today.day),
        schedule="@daily",
    catchup=False,
):
        task1 = BashOperator(
                task_id="print_current_date",
                bash_command="date"
        )
        task2 = PythonOperator(
        task_id="python_task",
        python_callable=my_python_function,
    )

        task1 >> task2
