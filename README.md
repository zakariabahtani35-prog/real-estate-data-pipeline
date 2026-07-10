# 🏠 Projet Data Engineering – Pipeline Immobilier avec Architecture Medallion

## Présentation du projet

Ce projet a pour objectif de concevoir un pipeline Data Engineering complet permettant de transformer des données immobilières brutes en un Data Warehouse exploitable pour l'analyse décisionnelle.

Le pipeline repose sur une architecture **Medallion (Bronze → Silver → Gold)** hébergée sur **Snowflake**, avec les transformations réalisées via **dbt**, l'orchestration assurée par **Apache Airflow**, la gestion du code avec **Git/GitHub**, et la visualisation des données dans **Power BI**.

---

# Architecture du projet

```
CSV
 │
 ▼
Python Loader
 │
 ▼
Snowflake
 │
 ├── Bronze (Raw)
 │
 ▼
dbt
 │
 ├── Silver (Cleaned)
 │
 ▼
dbt
 │
 ├── Gold (Star Schema)
 │
 ▼
Power BI
```

L'ensemble du pipeline est orchestré par **Apache Airflow**.

---

# Technologies utilisées

* Python 3
* Snowflake
* dbt Core
* Apache Airflow
* Power BI
* Git & GitHub

---

# Structure du projet

```
real-estate-pipeline/

│
├── airflow/
│   └── dags/
│       └── real_estate_pipeline.py
│
├── dbt/
│   ├── models/
│   │
│   ├── bronze/
│   ├── silver/
│   ├── gold/
│   │
│   ├── macros/
│   └── tests/
│
├── data/
│   └── real_estate.csv
│
├── scripts/
│   └── load_bronze.py
│
├── docs/
│   └── architecture.pdf
│
├── README.md
│
└── requirements.txt
```

---

# Description des données

Le fichier CSV contient des annonces immobilières provenant de plusieurs pays.

Colonnes disponibles :

* listing_id
* property_type
* country
* city
* neighborhood
* surface_m2
* num_rooms
* num_bathrooms
* floor
* year_built
* price
* listing_date
* condition
* heating_type
* parking
* energy_rating

---

# Architecture Medallion

## Bronze Layer (Raw)

Objectif :

Conserver les données exactement comme elles sont reçues.

Caractéristiques :

* Chargement du CSV sans modification
* Aucune transformation
* Traçabilité complète
* Ajout d'une colonne :

```
load_timestamp
```

Cette colonne contient la date et l'heure du chargement.

---

## Silver Layer (Cleaned)

La couche Silver est construite avec dbt.

Toutes les anomalies du fichier source sont corrigées.

### Nettoyage effectué

* Suppression des doublons (listing_id)
* Gestion des valeurs manquantes
* Conversion des prix texte vers numérique
* Uniformisation des dates
* Normalisation des espaces
* Uniformisation des majuscules/minuscules
* Correction des valeurs de parking
* Correction des types de chauffage
* Suppression des surfaces impossibles
* Suppressio n des prix aberrants

### Colonnes calculées

#### Prix au m²

```
price_per_m2 = price / surface_m2
```

#### Âge du bien

```
property_age = année courante - year_built
```

---

## Gold Layer

La couche Gold contient un **Star Schema**.

### Pourquoi le Star Schema ?

Le modèle en étoile est particulièrement adapté aux outils décisionnels comme Power BI.

Avantages :

* Requêtes rapides
* Modèle simple
* Maintenance facilitée
* Très bonne performance analytique

---

# Modèle dimensionnel

## Table de faits

### Fact_Listings

Mesures :

* price
* surface_m2
* price_per_m2
* property_age

Clés :

* property_key
* location_key
* date_key

---

## Dimensions

### Dim_Property

* property_type
* condition
* heating_type
* parking
* energy_rating

---

### Dim_Location

* country
* city
* neighborhood

---

### Dim_Date

* date
* année
* trimestre
* mois
* jour

---

# Pipeline Airflow

Le DAG exécute automatiquement les étapes suivantes :

1. Chargement du CSV vers Bronze
2. Exécution des modèles dbt Silver
3. Exécution des modèles dbt Gold
4. Notification de fin

Fonctionnalités :

* Retry automatique
* Gestion des erreurs
* Logs détaillés
* Suivi de chaque étape

---

# Gestion Git

Le projet est réalisé par quatre membres.

Organisation :

```
main
│
├── branche_membre_1
├── branche_membre_2
├── branche_membre_3
└── branche_membre_4
```

Règles :

* Aucun développement sur **main**
* Une Pull Request obligatoire
* Validation par un autre membre
* Commits fréquents et explicites

Exemple :

```
feat: création du modèle Silver

fix: correction du nettoyage des prix

docs: mise à jour du README

refactor: optimisation du DAG Airflow
```

---

# Dashboard Power BI

Les données proviennent directement de la couche Gold dans Snowflake.

Aucun import du fichier CSV n'est effectué dans Power BI.

## Page 1 – Vue Générale du Marché

### KPI

* Nombre total d'annonces
* Prix moyen
* Surface moyenne

### Visualisations

* Répartition des annonces par pays
* Répartition par type de bien

### Filtre

* Pays

---

## Page 2 – Analyse des Prix

Visualisations :

* Prix moyen par pays
* Prix moyen par ville
* Prix médian au m²
* Distribution des prix
* Évolution des prix dans le temps

Filtres :

* Fourchette de prix
* Type de bien

---

## Page 3 – Caractéristiques des Biens

Visualisations :

* Distribution des surfaces
* Répartition des classes énergétiques
* Âge moyen des biens
* Proportion des biens avec parking

Tableau récapitulatif :

* Ville
* Nombre d'annonces
* Prix moyen
* Surface moyenne
* Prix moyen au m²

Filtre :

* État du bien

---

# Installation du projet

## 1. Cloner le dépôt

```bash
git clone <repository_url>

cd real-estate-pipeline
```

---

## 2. Installer les dépendances

```bash
pip install -r requirements.txt
```

---

## 3. Configurer Snowflake

Créer :

* Warehouse
* Database
* Schemas

  * BRONZE
  * SILVER
  * GOLD

---

## 4. Configurer dbt

Modifier le fichier :

```
profiles.yml
```

avec les informations de connexion Snowflake.

---

## 5. Charger les données Bronze

```bash
python scripts/load_bronze.py
```

---

## 6. Exécuter les modèles dbt

Construire la couche Silver :

```bash
dbt run --select silver
```

Construire la couche Gold :

```bash
dbt run --select gold
```

Tester les modèles :

```bash
dbt test
```

---

## 7. Lancer Apache Airflow

Démarrer les services Airflow puis activer le DAG **real_estate_pipeline**.

---

## 8. Connecter Power BI

Créer une connexion directe vers Snowflake et sélectionner les tables de la couche Gold.

---

# Contrôles de qualité

Les modèles dbt incluent des tests pour vérifier :

* Unicité des identifiants
* Valeurs non nulles
* Intégrité des clés
* Cohérence des données
* Validité des dimensions

---

# Résultats attendus

À la fin de l'exécution du pipeline :

* Les données brutes sont stockées dans Bronze.
* Les données nettoyées sont disponibles dans Silver.
* Le schéma dimensionnel est créé dans Gold.
* Le DAG Airflow automatise entièrement le traitement.
* Le tableau de bord Power BI est alimenté directement depuis Snowflake.
* Le projet est versionné avec Git et documenté pour une exécution reproductible.
