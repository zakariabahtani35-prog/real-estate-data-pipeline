from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator

# Fonction temporaire pour charger les donnees CSV brutes dans la couche Bronze de Snowflake
def load_csv_to_bronze_func():
    print("Demarrage de l'ETL : Lecture du fichier CSV brut...")
    # En production, implémentez ici votre logique d'ingestion (ex: avec snowflake-connector-python)
    print("Donnees brutes chargees avec succes dans REAL_ESTATE_DB.BRONZE.RAW_REAL_ESTATE.")

# Configuration des arguments par defaut pour l'ensemble du pipeline
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2026, 7, 1),
    'retries': 2,                          # Reessayer 2 fois en cas d'echec
    'retry_delay': timedelta(minutes=5),    # Attente de 5 minutes entre chaque tentative
}

# Definition du DAG
with DAG(
    dag_id='real_estate_pipeline',
    default_args=default_args,
    description='Pipeline ETL pour les donnees immobilieres avec Airflow, dbt et Snowflake',
    schedule_interval='@daily',            # S'execute automatiquement une fois par jour
    catchup=False,                         # Desactive l'execution des dates passees (backfilling)
) as dag:

    # Tache 1 : Ingerer les donnees CSV brutes dans la couche Bronze
    load_bronze_task = PythonOperator(
        task_id='load_csv_to_bronze',
        python_callable=load_csv_to_bronze_func,
    )

    # Tache 2 : Executer les modeles de transformation dbt (Couches Silver & Gold)
    dbt_run_task = BashOperator(
        task_id='dbt_run_transformation',
        bash_command='dbt run --project-dir dbt/real_estate_silver --profiles-dir dbt/real_estate_silver',
    )

    # Tache 3 : Executer les tests de validation de la qualite des donnees dbt
    dbt_test_task = BashOperator(
        task_id='dbt_test_validation',
        bash_command='dbt test --project-dir dbt/real_estate_silver --profiles-dir dbt/real_estate_silver',
    )

    # Definition de l'ordre d'execution du pipeline
    load_bronze_task >> dbt_run_task >> dbt_test_task