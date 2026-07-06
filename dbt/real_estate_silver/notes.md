\# Analyse du CSV – Couche Bronze

\*\*Auteur : Assiya\*\*

\*\*Date : 01/07/2026\*\*

\*\*Branche : feature/dbt-silver\*\*



\---



\## 1. Valeurs manquantes (NULL)



| Colonne | Strategie d'imputation |

|---|---|

| country | Mode par city (ex: Nice → France) |

| neighborhood | Mode par city |

| heating\_type | Mode par property\_type |

| energy\_rating | Mode par property\_type + year\_range + heating\_type |

| condition | Base sur energy\_rating (A→New, C→Good, D→Renovated, E→Old) |

| parking | Mode par property\_type + surface\_range |

| surface\_m2 | Moyenne par property\_type |

| num\_rooms | Mediane par property\_type |

| num\_bathrooms | Mediane globale |

| year\_built | Mediane globale |

| price | Moyenne globale |

| floor | Mediane par property\_type |

| listing\_date | Fallback date fixe 2022-01-01 |



\---



\## 2. Doublons



\- Cle utilisee : listing\_id

\- Methode : ROW\_NUMBER() OVER (PARTITION BY listing\_id)

\- Resultat : 0 doublons dans la table Silver



\---



\## 3. Types incorrects



| Colonne | Probleme | Solution |

|---|---|---|

| price | "387809 EUR" au lieu de 387809 | REPLACE(' EUR', '') + CAST FLOAT |

| listing\_date | Formats mixtes | TRY\_TO\_DATE avec 4 formats |

| surface\_m2 | Decimales (38.666) | ROUND + CAST INTEGER |

| num\_rooms | Decimales (1.5) | ROUND + CAST INTEGER |



\---



\## 4. Casse et espaces incoherents



| Colonne | Probleme | Solution |

|---|---|---|

| property\_type | house/HOUSE/APT | LOWER + CASE standardise |

| neighborhood | SUBURBS/Suburbs | LOWER(TRIM()) |

| heating\_type | Electric/CENTRAL | LOWER(TRIM()) |

| energy\_rating | A/a/B/b | UPPER(TRIM()) |

| parking | YES/yes/1/NO/no/0 | CASE standardise → YES/NO |



\---



\## 5. Valeurs aberrantes



| Colonne | Probleme | Solution |

|---|---|---|

| surface\_m2 | 9999 (impossible) | → NULL → moyenne |

| surface\_m2 | Studio > 60m2 | → NULL → moyenne par type |

| surface\_m2 | Villa < 80m2 | → NULL → moyenne par type |

| price | < 1000 (irrealiste) | → NULL → moyenne globale |

| num\_rooms | Studio > 2 pieces | → NULL → mediane par type |



\---



\## 6. Colonnes calculees ajoutees



| Colonne | Formule |

|---|---|

| property\_age | YEAR(CURRENT\_DATE()) - year\_built |

| price\_per\_m2 | ROUND(price / surface\_m2, 2) |



\---



\## 7. Resultats finaux



| Metrique | Valeur |

|---|---|

| Total lignes | 2000 |

| IDs uniques | 2000 |

| NULL restants | 0 |

| Doublons | 0 |

| Prix minimum | 51202 |

| Surface maximum | 400 m2 |

| Tests dbt passes | 23/23 |

