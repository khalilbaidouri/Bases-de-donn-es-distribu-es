# EShop Multibase — Base de Données Distribuée

[![Oracle](https://img.shields.io/badge/Oracle-21c%20XE-red?logo=oracle)](https://container-registry.oracle.com)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue?logo=docker)](https://docs.docker.com/compose/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.x-green?logo=springboot)](https://spring.io/projects/spring-boot)
[![Next.js](https://img.shields.io/badge/Next.js-14-black?logo=nextdotjs)](https://nextjs.org)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

> Infrastructure Oracle 21c XE distribuée avec fragmentation horizontale automatique.
> **3 nœuds Oracle** · **Docker Compose** · **DB Links** · **Triggers de synchronisation bidirectionnelle** · **Migration inter-sites automatique**

---

## Table des matières

- [Architecture](#architecture)
- [Règle de fragmentation](#règle-de-fragmentation)
- [Prérequis](#prérequis)
- [Démarrage rapide](#démarrage-rapide)
- [Structure des dossiers](#structure-des-dossiers)
- [Informations de connexion](#informations-de-connexion)
- [Mécanisme anti-boucle](#mécanisme-anti-boucle)
- [Triggers Oracle](#triggers-oracle)
- [Procédures stockées](#procédures-stockées)
- [Séquences Oracle](#séquences-oracle)
- [Synchronisation bidirectionnelle](#synchronisation-bidirectionnelle)
- [Tests complets](#tests-complets)
- [Commandes utiles](#commandes-utiles)
- [Dépôts liés](#dépôts-liés)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   eshop-network (172.20.0.0/16)             │
│                                                             │
│               oracle-global (172.20.0.10:1524)             │
│         BDD principale · triggers de routage · sync_ctrl   │
│                      ↙               ↘                      │
│           DB Link                      DB Link              │
│          ↙                                  ↘               │
│   oracle-site1                        oracle-site2          │
│   172.20.0.11:1522                    172.20.0.12:1523      │
│   Quantite ≥ 100                      Quantite < 100        │
│   user: eshop1                        user: eshop2          │
│                                                             │
│   ← Synchronisation bidirectionnelle automatique →         │
│   ← Migration inter-sites si seuil franchi →              │
└─────────────────────────────────────────────────────────────┘
```

---

## Règle de fragmentation

| Condition | Destination | Description |
|---|---|---|
| `Quantite >= 100` | Site1 | Gros volumes |
| `Quantite < 100` | Site2 | Petits volumes |

La fragmentation est **automatique et dynamique** : si la quantité d'une ligne change
et franchit le seuil (100), la ligne est **automatiquement migrée** vers le bon site.

---

## Prérequis

- Docker Desktop 24.x+
- Docker Compose v2.x+
- Compte gratuit sur [container-registry.oracle.com](https://container-registry.oracle.com)

---

## Démarrage rapide

### 1. Cloner le dépôt

```bash
git clone https://github.com/khalilbaidouri/Bases-de-donn-es-distribu-es.git
cd Bases-de-donn-es-distribu-es
```

### 2. Se connecter au registre Oracle

```bash
docker login container-registry.oracle.com
# Entrer votre email Oracle et mot de passe
```

### 3. Lancer les 3 conteneurs

```bash
docker compose up -d
```

> ⚠️ Le premier démarrage télécharge l'image Oracle (~2 Go) et prend 10-15 minutes.

### 4. Vérifier que les 3 conteneurs sont prêts

```bash
docker compose ps
# Les 3 conteneurs doivent afficher STATUS = healthy
```

### 5. Configurer le réseau Oracle (TNS)

```bash
# Sur oracle-global
docker cp "scripts/global/tnsnames.ora" eshop-global:/tmp/tnsnames.ora
docker exec -it eshop-global bash -c "cp /tmp/tnsnames.ora /opt/oracle/homes/OraDBHome21cXE/network/admin/tnsnames.ora"

# Sur oracle-site1
docker cp "scripts/site1/tnsnames_site1.ora" eshop-site1:/tmp/tnsnames.ora
docker exec -it eshop-site1 bash -c "cp /tmp/tnsnames.ora /opt/oracle/homes/OraDBHome21cXE/network/admin/tnsnames.ora"

# Sur oracle-site2
docker cp "scripts/site2/tnsnames_site2.ora" eshop-site2:/tmp/tnsnames.ora
docker exec -it eshop-site2 bash -c "cp /tmp/tnsnames.ora /opt/oracle/homes/OraDBHome21cXE/network/admin/tnsnames.ora"

# Tester la connectivité
docker exec -it eshop-global bash -c "tnsping SITE1"
docker exec -it eshop-global bash -c "tnsping SITE2"
docker exec -it eshop-site1  bash -c "tnsping GLOBAL"
docker exec -it eshop-site2  bash -c "tnsping GLOBAL"
```

### 6. Initialiser oracle-global

```bash
docker cp "scripts/global/01_user.sql"         eshop-global:/tmp/
docker cp "scripts/global/02_tables.sql"       eshop-global:/tmp/
docker cp "scripts/global/03_data.sql"         eshop-global:/tmp/
docker cp "scripts/global/04_dblinks.sql"      eshop-global:/tmp/
docker cp "scripts/global/05_triggers.sql"     eshop-global:/tmp/
docker cp "scripts/global/06_optimisation.sql" eshop-global:/tmp/

docker exec -it eshop-global sqlplus "sys/Oracle123@localhost/XEPDB1 as sysdba" "@/tmp/01_user.sql"
docker exec -it eshop-global sqlplus "eshop/Eshop123@localhost/XEPDB1" "@/tmp/02_tables.sql"
docker exec -it eshop-global sqlplus "eshop/Eshop123@localhost/XEPDB1" "@/tmp/03_data.sql"
docker exec -it eshop-global sqlplus "eshop/Eshop123@localhost/XEPDB1" "@/tmp/04_dblinks.sql"
docker exec -it eshop-global sqlplus "eshop/Eshop123@localhost/XEPDB1" "@/tmp/05_triggers.sql"
docker exec -it eshop-global sqlplus "eshop/Eshop123@localhost/XEPDB1" "@/tmp/06_optimisation.sql"
```

### 7. Initialiser oracle-site1

```bash
docker cp "scripts/site1/01_site1_schema.sql"  eshop-site1:/tmp/
docker cp "scripts/site1/02_procedures.sql"    eshop-site1:/tmp/
docker cp "scripts/site1/04_dblink_global.sql" eshop-site1:/tmp/
docker cp "scripts/site1/triginv.sql"          eshop-site1:/tmp/

docker exec -it eshop-site1 sqlplus "sys/Oracle123@localhost/XEPDB1 as sysdba" "@/tmp/01_site1_schema.sql"
docker exec -it eshop-site1 sqlplus "eshop1/Eshop123@localhost/XEPDB1" "@/tmp/02_procedures.sql"
docker exec -it eshop-site1 sqlplus "eshop1/Eshop123@localhost/XEPDB1" "@/tmp/04_dblink_global.sql"
docker exec -it eshop-site1 sqlplus "eshop1/Eshop123@localhost/XEPDB1" "@/tmp/triginv.sql"
```

### 8. Initialiser oracle-site2

```bash
docker cp "scripts/site2/01_site2_schema.sql"  eshop-site2:/tmp/
docker cp "scripts/site2/02_procedures.sql"    eshop-site2:/tmp/
docker cp "scripts/site2/04_dblink_global.sql" eshop-site2:/tmp/
docker cp "scripts/site2/triginv.sql"          eshop-site2:/tmp/

docker exec -it eshop-site2 sqlplus "sys/Oracle123@localhost/XEPDB1 as sysdba" "@/tmp/01_site2_schema.sql"
docker exec -it eshop-site2 sqlplus "eshop2/Eshop123@localhost/XEPDB1" "@/tmp/02_procedures.sql"
docker exec -it eshop-site2 sqlplus "eshop2/Eshop123@localhost/XEPDB1" "@/tmp/04_dblink_global.sql"
docker exec -it eshop-site2 sqlplus "eshop2/Eshop123@localhost/XEPDB1" "@/tmp/triginv.sql"
```

---

## Structure des dossiers

```
eshop-distributed/
├── docker-compose.yml
└── scripts/
    ├── global/
    │   ├── 01_user.sql              ← Création utilisateur eshop
    │   ├── 02_tables.sql            ← Tables + séquences SEQ_LIGNE, SEQ_COMMANDE
    │   ├── 03_data.sql              ← Données de test initiales
    │   ├── 04_dblinks.sql           ← DB Links link_site1, link_site2
    │   ├── 05_triggers.sql          ← SYC_INSERT/UPDATE/DELETE_LIGNE
    │   │                               + package sync_ctrl (anti-boucle)
    │   │                               + procédures set_syncing/unset_syncing
    │   │                               + procédures insert/update/delete_global
    │   ├── 06_optimisation.sql      ← Index + EXPLAIN PLAN
    │   ├── 07_requetes.sql          ← Requêtes distribuées CA
    │   ├── 08_tests.sql             ← Tests de validation complets
    │   ├── 09_reset_data.sql        ← Remise à zéro des données
    │   └── tnsnames.ora             ← Résolution SITE1, SITE2
    ├── site1/
    │   ├── 01_site1_schema.sql      ← Tables eshop1 (Quantite >= 100)
    │   ├── 02_procedures.sql        ← insert_and_sync, update_and_sync,
    │   │                               deleteligne (avec migration inter-sites)
    │   ├── 04_dblink_global.sql     ← DB Link link_global
    │   ├── triginv.sql              ← TRG_INV_INSERT/UPDATE/DELETE
    │   └── tnsnames_site1.ora       ← Résolution GLOBAL
    └── site2/
        ├── 01_site2_schema.sql      ← Tables eshop2 (Quantite < 100)
        ├── 02_procedures.sql        ← insert_and_sync, update_and_sync,
        │                               deleteligne (avec migration inter-sites)
        ├── 04_dblink_global.sql     ← DB Link link_global
        ├── triginv.sql              ← TRG_INV_INSERT/UPDATE/DELETE
        └── tnsnames_site2.ora       ← Résolution GLOBAL
```

---

## Informations de connexion

| Conteneur | IP Docker | Port externe | Utilisateur | Mot de passe |
|---|---|---|---|---|
| eshop-global | 172.20.0.10 | 1524 | eshop | Eshop123 |
| eshop-site1 | 172.20.0.11 | 1522 | eshop1 | Eshop123 |
| eshop-site2 | 172.20.0.12 | 1523 | eshop2 | Eshop123 |
| tous (admin) | — | — | sys | Oracle123 |

---

## Mécanisme anti-boucle

Sans protection, les triggers créent une boucle infinie :

```
UPDATE Site1
  → TRG_INV_UPDATE (Site1)
    → UPDATE Global
      → SYC_UPDATE_LIGNE (Global)
        → UPDATE Site1       ← boucle infinie !
```

La solution utilise un **package Oracle** comme flag de session sur Global :

```sql
-- Package flag anti-boucle
CREATE OR REPLACE PACKAGE eshop.sync_ctrl AS
  g_syncing BOOLEAN := FALSE;
END sync_ctrl;

-- Procédures appelées via DB link depuis les sites
CREATE OR REPLACE PROCEDURE eshop.set_syncing AS
BEGIN eshop.sync_ctrl.g_syncing := TRUE; END;

CREATE OR REPLACE PROCEDURE eshop.unset_syncing AS
BEGIN eshop.sync_ctrl.g_syncing := FALSE; END;
```

Flux protégé :

```
Site1.update_and_sync(idligne, qte, remise)
  → eshop.set_syncing@link_global      ← flag = TRUE
  → UPDATE LigneCommandes@link_global  ← trigger vérifie flag → RETURN
  → eshop.unset_syncing@link_global    ← flag = FALSE
```

---

## Triggers Oracle

| Trigger | Sur | Événement | Rôle |
|---|---|---|---|
| `SYC_INSERT_LIGNE` | Global | AFTER INSERT | Route vers Site1 (≥100) ou Site2 (<100) · vérifie flag anti-boucle |
| `SYC_UPDATE_LIGNE` | Global | AFTER UPDATE | Met à jour le bon site · **migre la ligne si le seuil change** · vérifie flag |
| `SYC_DELETE_LIGNE` | Global | AFTER DELETE | Supprime sur le bon site · vérifie flag anti-boucle |
| `TRG_INV_INSERT` | Site1 & Site2 | AFTER INSERT | Propage INSERT vers Global si absent |
| `TRG_INV_UPDATE` | Site1 & Site2 | AFTER UPDATE | Propage UPDATE vers Global via `update_and_sync` |
| `TRG_INV_DELETE` | Site1 & Site2 | AFTER DELETE | Propage DELETE vers Global |

### Logique de migration dans SYC_UPDATE_LIGNE

```
Ancien Quantite < 100  ET  Nouveau Quantite >= 100
  → DELETE de Site2 + INSERT sur Site1   (migration Site2 → Site1)

Ancien Quantite >= 100  ET  Nouveau Quantite < 100
  → DELETE de Site1 + INSERT sur Site2   (migration Site1 → Site2)

Sinon
  → simple UPDATE sur le même site
```

---

## Procédures stockées

### Sur Global

| Procédure | Paramètres | Rôle |
|---|---|---|
| `insert_global` | `(idcmd, idprod, qte, prix, remise)` | INSERT avec SEQ_LIGNE.NEXTVAL + routage trigger |
| `update_global` | `(idligne, qte, remise)` | UPDATE + migration automatique si seuil franchi |
| `delete_global` | `(idligne)` | DELETE propagé vers Site1 ou Site2 |
| `set_syncing` | — | Active le flag anti-boucle |
| `unset_syncing` | — | Désactive le flag anti-boucle |

### Sur Site1 & Site2

| Procédure | Paramètres | Rôle |
|---|---|---|
| `insert_and_sync` | `(idcmd, idprod, qte, prix, remise)` | INSERT avec SEQ_LIGNE.NEXTVAL + flag anti-boucle |
| `update_and_sync` | `(idligne, qte, remise)` | UPDATE + propagation Global + **migration si seuil franchi** |
| `deleteligne` | `(idligne)` | DELETE local + propagation vers Global |

---

## Séquences Oracle

| Séquence | Sur | Incrément | Usage |
|---|---|---|---|
| `SEQ_LIGNE` | Global | 1 | ID auto des LigneCommandes |
| `SEQ_LIGNE` | Site1 | 1 | ID local Site1 |
| `SEQ_LIGNE` | Site2 | 1 | ID local Site2 |
| `SEQ_COMMANDE` | Global | 1 | ID auto des Commandes |

---

## Synchronisation bidirectionnelle

```
┌─────────────────────────────────────────────────────────────┐
│               TOUTES LES DIRECTIONS SUPPORTÉES              │
├──────────────────────────┬──────────────────────────────────┤
│ INSERT Global → Site1/2  │ Trigger SYC_INSERT_LIGNE         │
│ INSERT Site1  → Global   │ TRG_INV_INSERT + insert_and_sync │
│ INSERT Site2  → Global   │ TRG_INV_INSERT + insert_and_sync │
├──────────────────────────┼──────────────────────────────────┤
│ UPDATE Global → Site1/2  │ Trigger SYC_UPDATE_LIGNE         │
│ UPDATE Site1  → Global   │ TRG_INV_UPDATE + update_and_sync │
│ UPDATE Site2  → Global   │ TRG_INV_UPDATE + update_and_sync │
├──────────────────────────┼──────────────────────────────────┤
│ DELETE Global → Site1/2  │ Trigger SYC_DELETE_LIGNE         │
│ DELETE Site1  → Global   │ TRG_INV_DELETE + deleteligne     │
│ DELETE Site2  → Global   │ TRG_INV_DELETE + deleteligne     │
├──────────────────────────┼──────────────────────────────────┤
│ MIGRATION Site2 → Site1  │ UPDATE qte passe de <100 à ≥100  │
│ MIGRATION Site1 → Site2  │ UPDATE qte passe de ≥100 à <100  │
└──────────────────────────┴──────────────────────────────────┘
```

---

## Tests complets

### Connexion aux bases

```bash
docker exec -it eshop-global sqlplus "eshop/Eshop123@localhost/XEPDB1"
docker exec -it eshop-site1  sqlplus "eshop1/Eshop123@localhost/XEPDB1"
docker exec -it eshop-site2  sqlplus "eshop2/Eshop123@localhost/XEPDB1"
```

---

### TEST 1 — INSERT Global → Site1 (qte >= 100)

```sql
-- Sur eshop-global
SET SERVEROUTPUT ON;
EXEC eshop.insert_global(1, 1, 200, 100.00, 5);

SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes
WHERE idligneCommande = SEQ_LIGNE.CURRVAL;

SELECT idligneCommande, quantite, remise FROM eshop1.LigneCommandes1@link_site1
WHERE idligneCommande = SEQ_LIGNE.CURRVAL;
-- ✅ quantite=200, remise=5 sur Global ET Site1 · Absent de Site2
```

---

### TEST 2 — INSERT Global → Site2 (qte < 100)

```sql
-- Sur eshop-global
EXEC eshop.insert_global(2, 5, 10, 50.00, 0);

SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes
WHERE idligneCommande = SEQ_LIGNE.CURRVAL;

SELECT idligneCommande, quantite, remise FROM eshop2.LigneCommandes2@link_site2
WHERE idligneCommande = SEQ_LIGNE.CURRVAL;
-- ✅ quantite=10, remise=0 sur Global ET Site2 · Absent de Site1
```

---

### TEST 3 — INSERT Site1 → Global

```sql
-- Sur eshop-site1
SET SERVEROUTPUT ON;
EXEC eshop1.insert_and_sync(1, 1, 150, 100.00, 5);

SELECT idligneCommande, quantite, remise FROM LigneCommandes1
WHERE idligneCommande = SEQ_LIGNE.CURRVAL;

SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes@link_global
WHERE idligneCommande = SEQ_LIGNE.CURRVAL;
-- ✅ quantite=150, remise=5 sur Site1 ET Global
```

---

### TEST 4 — INSERT Site2 → Global

```sql
-- Sur eshop-site2
SET SERVEROUTPUT ON;
EXEC eshop2.insert_and_sync(2, 5, 10, 50.00, 0);

SELECT idligneCommande, quantite, remise FROM LigneCommandes2
WHERE idligneCommande = SEQ_LIGNE.CURRVAL;

SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes@link_global
WHERE idligneCommande = SEQ_LIGNE.CURRVAL;
-- ✅ quantite=10, remise=0 sur Site2 ET Global
```

---

### TEST 5 — UPDATE Global → Site1 (même site)

```sql
-- Sur eshop-global
SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes WHERE idligneCommande = 1;

EXEC eshop.update_global(1, 999, 50);

SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes WHERE idligneCommande = 1;
SELECT idligneCommande, quantite, remise FROM eshop1.LigneCommandes1@link_site1 WHERE idligneCommande = 1;
-- ✅ quantite=999, remise=50 sur Global ET Site1
```

---

### TEST 6 — UPDATE Global → Site2 (même site)

```sql
-- Sur eshop-global
EXEC eshop.update_global(5, 80, 20);

SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes WHERE idligneCommande = 5;
SELECT idligneCommande, quantite, remise FROM eshop2.LigneCommandes2@link_site2 WHERE idligneCommande = 5;
-- ✅ quantite=80, remise=20 sur Global ET Site2
```

---

### TEST 7 — UPDATE Site1 → Global (même site)

```sql
-- Sur eshop-site1
SELECT idligneCommande, quantite, remise FROM LigneCommandes1 WHERE idligneCommande = 1;

EXEC eshop1.update_and_sync(1, 500, 30);

SELECT idligneCommande, quantite, remise FROM LigneCommandes1 WHERE idligneCommande = 1;
SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes@link_global WHERE idligneCommande = 1;
-- ✅ quantite=500, remise=30 sur Site1 ET Global
```

---

### TEST 8 — UPDATE Site2 → Global (même site)

```sql
-- Sur eshop-site2
EXEC eshop2.update_and_sync(5, 50, 15);

SELECT idligneCommande, quantite, remise FROM LigneCommandes2 WHERE idligneCommande = 5;
SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes@link_global WHERE idligneCommande = 5;
-- ✅ quantite=50, remise=15 sur Site2 ET Global
```

---

### TEST 9 — MIGRATION Site2 → Site1 via Site2 (qte passe de <100 à >=100)

```sql
-- Sur eshop-site2 : ligne 5 a quantite=50 (sur Site2)
SELECT idligneCommande, quantite FROM LigneCommandes2 WHERE idligneCommande = 5;

-- Changer quantite à 150 → migration automatique vers Site1
EXEC eshop2.update_and_sync(5, 150, 10);

-- Site2 → doit être 0 (ligne supprimée)
SELECT COUNT(*) AS site2_doit_etre_0 FROM LigneCommandes2 WHERE idligneCommande = 5;

-- Site1 → doit apparaître (ligne migrée)
SELECT idligneCommande, quantite, remise FROM eshop1.LigneCommandes1@link_site1
WHERE idligneCommande = 5;

-- Global → quantite=150
SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes@link_global
WHERE idligneCommande = 5;
-- ✅ Site2=0 · Site1=150 · Global=150
```

---

### TEST 10 — MIGRATION Site1 → Site2 via Site1 (qte passe de >=100 à <100)

```sql
-- Sur eshop-site1 : ligne 1 a quantite=500 (sur Site1)
SELECT idligneCommande, quantite FROM LigneCommandes1 WHERE idligneCommande = 1;

-- Changer quantite à 50 → migration automatique vers Site2
EXEC eshop1.update_and_sync(1, 50, 5);

-- Site1 → doit être 0 (ligne supprimée)
SELECT COUNT(*) AS site1_doit_etre_0 FROM LigneCommandes1 WHERE idligneCommande = 1;

-- Site2 → doit apparaître (ligne migrée)
SELECT idligneCommande, quantite, remise FROM eshop2.LigneCommandes2@link_site2
WHERE idligneCommande = 1;

-- Global → quantite=50
SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes@link_global
WHERE idligneCommande = 1;
-- ✅ Site1=0 · Site2=50 · Global=50
```

---

### TEST 11 — MIGRATION Site2 → Site1 via Global

```sql
-- Sur eshop-global : ligne 5 sur Site2 (quantite=50)
SELECT idligneCommande, quantite FROM eshop2.LigneCommandes2@link_site2
WHERE idligneCommande = 5;

-- UPDATE depuis Global → quantite passe à 200
EXEC eshop.update_global(5, 200, 10);

-- Site2 → doit être 0
SELECT COUNT(*) AS site2_doit_etre_0 FROM eshop2.LigneCommandes2@link_site2
WHERE idligneCommande = 5;

-- Site1 → doit apparaître
SELECT idligneCommande, quantite, remise FROM eshop1.LigneCommandes1@link_site1
WHERE idligneCommande = 5;
-- ✅ Migration automatique Site2 → Site1 via SYC_UPDATE_LIGNE
```

---

### TEST 12 — MIGRATION Site1 → Site2 via Global

```sql
-- Sur eshop-global : ligne 1 sur Site1 (quantite=999)
SELECT idligneCommande, quantite FROM eshop1.LigneCommandes1@link_site1
WHERE idligneCommande = 1;

-- UPDATE depuis Global → quantite passe à 30
EXEC eshop.update_global(1, 30, 5);

-- Site1 → doit être 0
SELECT COUNT(*) AS site1_doit_etre_0 FROM eshop1.LigneCommandes1@link_site1
WHERE idligneCommande = 1;

-- Site2 → doit apparaître
SELECT idligneCommande, quantite, remise FROM eshop2.LigneCommandes2@link_site2
WHERE idligneCommande = 1;
-- ✅ Migration automatique Site1 → Site2 via SYC_UPDATE_LIGNE
```

---

### TEST 13 — DELETE Site1 → Global

```sql
-- Sur eshop-site1
SELECT idligneCommande, quantite FROM LigneCommandes1 WHERE idligneCommande = 1;

EXEC eshop1.deleteligne(1);

SELECT COUNT(*) AS site1_doit_etre_0 FROM LigneCommandes1 WHERE idligneCommande = 1;
SELECT COUNT(*) AS global_doit_etre_0 FROM eshop.LigneCommandes@link_global
WHERE idligneCommande = 1;
-- ✅ COUNT=0 sur Site1 ET Global
```

---

### TEST 14 — DELETE Site2 → Global

```sql
-- Sur eshop-site2
EXEC eshop2.deleteligne(5);

SELECT COUNT(*) AS site2_doit_etre_0 FROM LigneCommandes2 WHERE idligneCommande = 5;
SELECT COUNT(*) AS global_doit_etre_0 FROM eshop.LigneCommandes@link_global
WHERE idligneCommande = 5;
-- ✅ COUNT=0 sur Site2 ET Global
```

---

### TEST 15 — DELETE Global → Site1

```sql
-- Sur eshop-global
SELECT idligneCommande, quantite FROM eshop1.LigneCommandes1@link_site1
WHERE idligneCommande = 2;

EXEC eshop.delete_global(2);

SELECT COUNT(*) AS global_doit_etre_0 FROM eshop.LigneCommandes WHERE idligneCommande = 2;
SELECT COUNT(*) AS site1_doit_etre_0 FROM eshop1.LigneCommandes1@link_site1
WHERE idligneCommande = 2;
-- ✅ COUNT=0 sur Global ET Site1
```

---

### TEST 16 — DELETE Global → Site2

```sql
-- Sur eshop-global
EXEC eshop.delete_global(3);

SELECT COUNT(*) AS global_doit_etre_0 FROM eshop.LigneCommandes WHERE idligneCommande = 3;
SELECT COUNT(*) AS site2_doit_etre_0 FROM eshop2.LigneCommandes2@link_site2
WHERE idligneCommande = 3;
-- ✅ COUNT=0 sur Global ET Site2
```

---

### Vérification globale finale

```sql
-- Sur eshop-global : état des 3 bases simultanément
SELECT 'Global' AS site, COUNT(*) AS total FROM eshop.LigneCommandes
UNION ALL
SELECT 'Site1',  COUNT(*) FROM eshop1.LigneCommandes1@link_site1
UNION ALL
SELECT 'Site2',  COUNT(*) FROM eshop2.LigneCommandes2@link_site2;
```

---

## Tableau récapitulatif des tests

| # | Opération | Direction | Procédure | Résultat attendu |
|---|---|---|---|---|
| 1 | INSERT | Global → Site1 | `insert_global(1,1,200,100,5)` | Global + Site1 ✅ |
| 2 | INSERT | Global → Site2 | `insert_global(2,5,10,50,0)` | Global + Site2 ✅ |
| 3 | INSERT | Site1 → Global | `insert_and_sync(1,1,150,100,5)` | Site1 + Global ✅ |
| 4 | INSERT | Site2 → Global | `insert_and_sync(2,5,10,50,0)` | Site2 + Global ✅ |
| 5 | UPDATE | Global → Site1 | `update_global(1,999,50)` | qte=999 sur Global + Site1 ✅ |
| 6 | UPDATE | Global → Site2 | `update_global(5,80,20)` | qte=80 sur Global + Site2 ✅ |
| 7 | UPDATE | Site1 → Global | `update_and_sync(1,500,30)` | qte=500 sur Site1 + Global ✅ |
| 8 | UPDATE | Site2 → Global | `update_and_sync(5,50,15)` | qte=50 sur Site2 + Global ✅ |
| 9 | MIGRATION | Site2 → Site1 via Site2 | `update_and_sync(5,150,10)` | Site2=0, Site1=150, Global=150 ✅ |
| 10 | MIGRATION | Site1 → Site2 via Site1 | `update_and_sync(1,50,5)` | Site1=0, Site2=50, Global=50 ✅ |
| 11 | MIGRATION | Site2 → Site1 via Global | `update_global(5,200,10)` | Site2=0, Site1=200, Global=200 ✅ |
| 12 | MIGRATION | Site1 → Site2 via Global | `update_global(1,30,5)` | Site1=0, Site2=30, Global=30 ✅ |
| 13 | DELETE | Site1 → Global | `deleteligne(1)` | COUNT=0 Site1 + Global ✅ |
| 14 | DELETE | Site2 → Global | `deleteligne(5)` | COUNT=0 Site2 + Global ✅ |
| 15 | DELETE | Global → Site1 | `delete_global(2)` | COUNT=0 Global + Site1 ✅ |
| 16 | DELETE | Global → Site2 | `delete_global(3)` | COUNT=0 Global + Site2 ✅ |

---

## Commandes utiles

```bash
# Voir les logs Oracle
docker compose logs -f oracle-global

# Se connecter en SQL*Plus
docker exec -it eshop-global sqlplus "eshop/Eshop123@localhost/XEPDB1"
docker exec -it eshop-site1  sqlplus "eshop1/Eshop123@localhost/XEPDB1"
docker exec -it eshop-site2  sqlplus "eshop2/Eshop123@localhost/XEPDB1"

# Vérifier les triggers actifs sur Global
docker exec -it eshop-global sqlplus "eshop/Eshop123@localhost/XEPDB1" <<'EOF'
SELECT trigger_name, status FROM user_triggers ORDER BY trigger_name;
EXIT
EOF

# Vérifier les triggers actifs sur Site1
docker exec -it eshop-site1 sqlplus "eshop1/Eshop123@localhost/XEPDB1" <<'EOF'
SELECT trigger_name, status FROM user_triggers ORDER BY trigger_name;
EXIT
EOF

# Vérifier les procédures sur Global
docker exec -it eshop-global sqlplus "eshop/Eshop123@localhost/XEPDB1" <<'EOF'
SELECT object_name, status FROM user_objects WHERE object_type = 'PROCEDURE';
EXIT
EOF

# Vérifier les erreurs de compilation
docker exec -it eshop-global sqlplus "eshop/Eshop123@localhost/XEPDB1" <<'EOF'
SELECT name, line, text FROM user_errors WHERE type IN ('TRIGGER','PROCEDURE');
EXIT
EOF

# Arrêter sans perdre les données
docker compose down

# Reset complet (efface toutes les données Oracle)
docker compose down -v
```

---

## Dépôts liés

| Projet | Technologie | Lien |
|---|---|---|
| Base de données | Oracle 21c XE + Docker | Ce dépôt |
| Backend | Spring Boot 3.x + JDBC | https://github.com/khalilbaidouri/eshop_back.git |
| Frontend | Next.js 14 + Tailwind CSS | https://github.com/khalilbaidouri/eshop_front.git |
