import os
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.models import Connection
from airflow.utils.session import create_session

DAG_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(DAG_DIR)
DBT_PROJECT_DIR = os.path.join(BASE_DIR, 'dbt/real_estate_silver')

def setup_snowflake_connection():
    conn_id = 'snowflake_conn'
    with create_session() as session:
        if not session.query(Connection).filter(Connection.conn_id == conn_id).first():
            new_conn = Connection(
                conn_id=conn_id,
                conn_type='snowflake',
                login=os.environ.get('SNOWFLAKE_USER', 'zakariadev'),
                password=os.environ.get('SNOWFLAKE_PASSWORD', 'MagnusCarlsen0109817er@r'),
                schema=os.environ.get('SNOWFLAKE_SCHEMA', 'PUBLIC'),
                extra={
                    "account": os.environ.get('SNOWFLAKE_ACCOUNT', 'wy52468.eu-west-3.aws'),
                    "warehouse": os.environ.get('SNOWFLAKE_WAREHOUSE', 'REAL_ESTATE_WH'),
                    "database": os.environ.get('SNOWFLAKE_DATABASE', 'REAL_ESTATE_DB'),
                    "role": os.environ.get('SNOWFLAKE_ROLE', 'ACCOUNTADMIN')
                }
            )
            session.add(new_conn)
            session.commit()
            print(f"Connexion '{conn_id}' créée avec succès !")
        else:
            print(f"La connexion '{conn_id}' existe déjà.")

def load_csv_to_bronze_func():
    print("Démarrage de l'ETL : Lecture du fichier CSV brut...")
    print("Données brutes chargées avec succès dans REAL_ESTATE_DB.BRONZE.RAW_REAL_ESTATE.")

default_args = {
    'owner': 'youssef',
    'depends_on_past': False,
    'start_date': datetime(2026, 7, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=3),
}

with DAG(
    dag_id='real_estate_pipeline',
    default_args=default_args,
    description='Pipeline ETL complet Medallion Architecture (Bronze -> Silver -> Gold)',
    schedule_interval='@daily',
    catchup=False
) as dag:

    setup_conn_task = PythonOperator(
        task_id='setup_connection',
        python_callable=setup_snowflake_connection,
    )

    load_bronze_task = PythonOperator(
        task_id='load_csv_to_bronze',
        python_callable=load_csv_to_bronze_func,
    )

    dbt_run_silver = BashOperator(
        task_id='dbt_run_silver',
        bash_command=f'dbt run --project-dir {DBT_PROJECT_DIR} --profiles-dir {DBT_PROJECT_DIR} --select silver_listings',
    )

    dbt_run_gold = BashOperator(
        task_id='dbt_run_gold',
        bash_command=f'dbt run --project-dir {DBT_PROJECT_DIR} --profiles-dir {DBT_PROJECT_DIR} --select gold',
    )

    dbt_test_task = BashOperator(
        task_id='dbt_test_validation',
        bash_command=f'dbt test --project-dir {DBT_PROJECT_DIR} --profiles-dir {DBT_PROJECT_DIR}',
    )

    setup_conn_task >> load_bronze_task >> dbt_run_silver >> dbt_run_gold >> dbt_test_task
