# Airflow — Real Estate Data Pipeline

Ce dossier contient la partie **orchestration** du pipeline de données immobilières, basée sur **Apache Airflow**.

> ⚠️ Ce README est un template générique. Je n'ai pas pu accéder au contenu réel du dossier `airflow` du dépôt (accès automatique bloqué par GitHub). Adapte les sections ci-dessous (noms de DAGs, tâches, connexions) pour qu'elles correspondent exactement à ton code.

## 📁 Structure

```
airflow/
├── dags/                  # Fichiers des DAGs (workflows)
│   └── real_estate_pipeline_dag.py
├── plugins/                # Opérateurs / hooks personnalisés (si présents)
├── include/                 # Scripts SQL, fichiers de config, helpers
├── requirements.txt        # Dépendances Python
├── docker-compose.yaml     # (si le projet tourne via Docker)
└── README.md
```

## ⚙️ Prérequis

- Python 3.9+
- Apache Airflow >= 2.x
- Docker & Docker Compose (si utilisation en conteneurs)
- Accès à l'API/source de données (ex. API de listings immobiliers)
- Base de données / Data Warehouse cible (Postgres, Snowflake, BigQuery, etc.)

## 🚀 Installation

### 1. Cloner le projet
```bash
git clone https://github.com/zakariabahtani35-prog/real-estate-data-pipeline.git
cd real-estate-data-pipeline/airflow
```

### 2. Installer les dépendances
```bash
pip install -r requirements.txt
```

### 3. Initialiser Airflow (en local, sans Docker)
```bash
export AIRFLOW_HOME=$(pwd)
airflow db init
airflow users create \
  --username admin \
  --firstname Admin \
  --lastname User \
  --role Admin \
  --email admin@example.com
```

### 4. Ou via Docker
```bash
docker-compose up -d
```

### 5. Variables et connexions Airflow

À configurer depuis l'interface Airflow (`Admin > Variables` et `Admin > Connections`) :

| Nom | Description |
|---|---|
| `api_key` | Clé de l'API source des données immobilières |
| `db_conn` | Connexion vers la base de données cible |
| `s3_conn` | Connexion vers S3/MinIO (si stockage intermédiaire utilisé) |

## ▶️ Exécution du pipeline

1. Ouvrir l'interface Airflow : `http://localhost:8080`
2. Repérer le DAG (ex. `real_estate_pipeline_dag`)
3. Activer le toggle pour le lancer selon le planning, ou déclencher manuellement

```bash
airflow dags trigger real_estate_pipeline_dag
```

## 🔄 Étapes du DAG

À adapter selon les tâches réelles définies dans le DAG :

1. **Extract** — Récupération des données depuis la source (API/scraping)
2. **Transform** — Nettoyage et transformation des données
3. **Load** — Chargement dans la base de données / data warehouse
4. **Validate** — Contrôles de qualité des données

## 🛠️ Dépannage

- Si le DAG n'apparaît pas dans l'interface, vérifier que `dags_folder` pointe bien vers ce dossier dans `airflow.cfg`
- En cas d'erreur de connexion, vérifier les identifiants dans `Admin > Connections`
- Consulter les logs de chaque tâche directement dans l'interface Airflow pour diagnostiquer les échecs

## 📄 Licence

Projet sous licence [MIT](../LICENSE) (à ajuster selon la licence réelle du dépôt).
