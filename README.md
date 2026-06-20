# EShop Multibase — Base de Données Distribuée

[![Oracle](https://img.shields.io/badge/Oracle-21c%20XE-red?logo=oracle)](https://container-registry.oracle.com)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue?logo=docker)](https://docs.docker.com/compose/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

> Infrastructure Oracle 21c XE distribuée avec fragmentation horizontale.  
> **3 nœuds Oracle** · **Docker Compose** · **DB Links** · **Triggers de synchronisation** · **Package anti-boucle**

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  eshop-network (172.20.0.0/16)          │
│                                                         │
│              oracle-global (172.20.0.10:1524)           │
│              BDD principale + triggers de routage       │
│                    ↙               ↘                    │
│         DB Link                      DB Link            │
│        ↙                                  ↘             │
│  oracle-site1                        oracle-site2       │
│  172.20.0.11:1522                    172.20.0.12:1523   │
│  Quantite ≥ 100                      Quantite < 100     │
│  user: eshop1                        user: eshop2       │
└─────────────────────────────────────────────────────────┘
```

### Règle de fragmentation horizontale

| Condition | Destination |
|---|---|
| `Quantite >= 100` | Site1 (gros volumes) |
| `Quantite < 100` | Site2 (petits volumes) |

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
    │   ├── 05_triggers.sql          ← SYC_INSERT/UPDATE/DELETE_LIGNE + package sync_ctrl
    │   ├── 06_optimisation.sql      ← Index + EXPLAIN PLAN
    │   ├── 07_requetes.sql          ← Requêtes distribuées CA
    │   ├── 08_tests.sql             ← Tests de validation complets
    │   ├── 09_reset_data.sql        ← Remise à zéro des données
    │   └── tnsnames.ora             ← Résolution SITE1, SITE2
    ├── site1/
    │   ├── 01_site1_schema.sql      ← Tables eshop1 (Quantite >= 100)
    │   ├── 02_procedures.sql        ← insert_and_sync, update_and_sync, deleteligne
    │   ├── 04_dblink_global.sql     ← DB Link link_global
    │   ├── triginv.sql              ← TRG_INV_INSERT/UPDATE/DELETE
    │   └── tnsnames_site1.ora       ← Résolution GLOBAL
    └── site2/
        ├── 01_site2_schema.sql      ← Tables eshop2 (Quantite < 100)
        ├── 02_procedures.sql        ← insert_and_sync, update_and_sync, deleteligne
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
UPDATE Site1 → TRG_INV_UPDATE → UPDATE Global → SYC_UPDATE_LIGNE → UPDATE Site1 → ...
```

La solution utilise un **package Oracle** comme flag de session sur Global :

```sql
CREATE OR REPLACE PACKAGE eshop.sync_ctrl AS
  g_syncing BOOLEAN := FALSE;
END sync_ctrl;

CREATE OR REPLACE PROCEDURE eshop.set_syncing AS
BEGIN eshop.sync_ctrl.g_syncing := TRUE; END;

CREATE OR REPLACE PROCEDURE eshop.unset_syncing AS
BEGIN eshop.sync_ctrl.g_syncing := FALSE; END;
```

Chaque procédure Site active le flag **avant** de propager vers Global, puis le désactive après. Le trigger `SYC_UPDATE/DELETE_LIGNE` vérifie ce flag et s'arrête si actif.

```
Site1.update_and_sync()
  → set_syncing@link_global       (flag = TRUE)
  → UPDATE LigneCommandes@global  (trigger vérifie flag → RETURN)
  → unset_syncing@link_global     (flag = FALSE)
```

---

## Triggers Oracle

| Trigger | Sur | Événement | Rôle |
|---|---|---|---|
| `SYC_INSERT_LIGNE` | Global | AFTER INSERT | Route vers Site1 (≥100) ou Site2 (<100) avec flag anti-boucle |
| `SYC_UPDATE_LIGNE` | Global | AFTER UPDATE | Propage UPDATE vers le bon site (vérifie flag anti-boucle) |
| `SYC_DELETE_LIGNE` | Global | AFTER DELETE | Supprime sur le bon site (vérifie flag anti-boucle) |
| `TRG_INV_INSERT` | Site1 & Site2 | AFTER INSERT | Propage INSERT vers Global si absent |
| `TRG_INV_UPDATE` | Site1 & Site2 | AFTER UPDATE | Propage UPDATE vers Global via `update_and_sync` |
| `TRG_INV_DELETE` | Site1 & Site2 | AFTER DELETE | Propage DELETE vers Global |

---

## Procédures stockées

### Sur Global

| Procédure | Paramètres | Rôle |
|---|---|---|
| `insert_global` | `(idcmd, idprod, qte, prix, remise)` | INSERT avec `SEQ_LIGNE.NEXTVAL` auto + routage trigger |
| `update_global` | `(idligne, qte, remise)` | UPDATE propagé vers Site1 ou Site2 |
| `delete_global` | `(idligne)` | DELETE propagé vers Site1 ou Site2 |
| `set_syncing` | — | Active le flag anti-boucle |
| `unset_syncing` | — | Désactive le flag anti-boucle |

### Sur Site1 & Site2

| Procédure | Paramètres | Rôle |
|---|---|---|
| `insert_and_sync` | `(idcmd, idprod, qte, prix, remise)` | INSERT avec `SEQ_LIGNE.NEXTVAL` + flag anti-boucle |
| `update_and_sync` | `(idligne, qte, remise)` | UPDATE local + propagation vers Global avec flag |
| `deleteligne` | `(idligne)` | DELETE local + propagation vers Global |

---

## Séquences Oracle

| Séquence | Sur | Incrément | Usage |
|---|---|---|---|
| `SEQ_LIGNE` | Global | 1 | ID auto des LigneCommandes (partagé) |
| `SEQ_LIGNE` | Site1 | 1 | ID local Site1 |
| `SEQ_LIGNE` | Site2 | 1 | ID local Site2 |
| `SEQ_COMMANDE` | Global | 1 | ID auto des Commandes |

---

## Tests de synchronisation

### Connexion Global

```bash
docker exec -it eshop-global sqlplus "eshop/Eshop123@localhost/XEPDB1"
```

---

### INSERT : Global → Sites

```sql
SET SERVEROUTPUT ON;

-- INSERT Global → Site1 (quantite >= 100) via procédure
EXEC eshop.insert_global(1, 1, 200, 100.00, 5);

-- Vérifier sur Global
SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes
WHERE idligneCommande = SEQ_LIGNE.CURRVAL;

-- Vérifier sur Site1 (doit apparaître automatiquement)
SELECT idligneCommande, quantite, remise FROM eshop1.LigneCommandes1@link_site1
WHERE idligneCommande = SEQ_LIGNE.CURRVAL;
-- ✅ Résultat attendu : quantite=200, remise=5

-- INSERT Global → Site2 (quantite < 100) via procédure
EXEC eshop.insert_global(2, 5, 10, 50.00, 0);

-- Vérifier sur Site2 (doit apparaître automatiquement)
SELECT idligneCommande, quantite, remise FROM eshop2.LigneCommandes2@link_site2
WHERE idligneCommande = SEQ_LIGNE.CURRVAL;
-- ✅ Résultat attendu : quantite=10, remise=0
```

---

### INSERT : Site1 → Global

```bash
docker exec -it eshop-site1 sqlplus "eshop1/Eshop123@localhost/XEPDB1"
```

```sql
SET SERVEROUTPUT ON;

-- INSERT via procédure (ID généré automatiquement)
EXEC eshop1.insert_and_sync(1, 1, 150, 100.00, 5);

-- Vérifier sur Site1
SELECT idligneCommande, quantite, remise FROM LigneCommandes1
WHERE idligneCommande = SEQ_LIGNE.CURRVAL;

-- Vérifier que Global a reçu
SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes@link_global
WHERE idligneCommande = SEQ_LIGNE.CURRVAL;
-- ✅ Résultat attendu : ligne présente sur les 2 bases
```

---

### INSERT : Site2 → Global

```bash
docker exec -it eshop-site2 sqlplus "eshop2/Eshop123@localhost/XEPDB1"
```

```sql
SET SERVEROUTPUT ON;

EXEC eshop2.insert_and_sync(2, 5, 10, 50.00, 0);

SELECT idligneCommande, quantite, remise FROM LigneCommandes2
WHERE idligneCommande = SEQ_LIGNE.CURRVAL;

SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes@link_global
WHERE idligneCommande = SEQ_LIGNE.CURRVAL;
-- ✅ Résultat attendu : ligne présente sur les 2 bases
```

---

### UPDATE : Global → Site1

```bash
docker exec -it eshop-global sqlplus "eshop/Eshop123@localhost/XEPDB1"
```

```sql
-- Valeur avant
SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes WHERE idligneCommande = 1;

-- UPDATE via procédure
EXEC eshop.update_global(1, 999, 50);

-- Vérifier Global
SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes WHERE idligneCommande = 1;

-- Vérifier Site1 (propagation automatique)
SELECT idligneCommande, quantite, remise FROM eshop1.LigneCommandes1@link_site1
WHERE idligneCommande = 1;
-- ✅ Résultat attendu : quantite=999, remise=50 sur les 2 bases
```

---

### UPDATE : Global → Site2

```sql
-- Valeur avant
SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes WHERE idligneCommande = 5;

-- UPDATE via procédure
EXEC eshop.update_global(5, 80, 20);

-- Vérifier Site2 (propagation automatique)
SELECT idligneCommande, quantite, remise FROM eshop2.LigneCommandes2@link_site2
WHERE idligneCommande = 5;
-- ✅ Résultat attendu : quantite=80, remise=20 sur les 2 bases
```

---

### UPDATE : Site1 → Global

```bash
docker exec -it eshop-site1 sqlplus "eshop1/Eshop123@localhost/XEPDB1"
```

```sql
-- Valeur avant
SELECT idligneCommande, quantite, remise FROM LigneCommandes1 WHERE idligneCommande = 1;

-- UPDATE via procédure (avec flag anti-boucle)
EXEC eshop1.update_and_sync(1, 500, 30);

-- Vérifier Site1
SELECT idligneCommande, quantite, remise FROM LigneCommandes1 WHERE idligneCommande = 1;

-- Vérifier Global (propagation via TRG_INV_UPDATE)
SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes@link_global
WHERE idligneCommande = 1;
-- ✅ Résultat attendu : quantite=500, remise=30 sur les 2 bases
```

---

### UPDATE : Site2 → Global

```bash
docker exec -it eshop-site2 sqlplus "eshop2/Eshop123@localhost/XEPDB1"
```

```sql
-- UPDATE via procédure
EXEC eshop2.update_and_sync(5, 50, 15);

-- Vérifier Site2
SELECT idligneCommande, quantite, remise FROM LigneCommandes2 WHERE idligneCommande = 5;

-- Vérifier Global
SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes@link_global
WHERE idligneCommande = 5;
-- ✅ Résultat attendu : quantite=50, remise=15 sur les 2 bases
```

---

### DELETE : Site1 → Global

```bash
docker exec -it eshop-site1 sqlplus "eshop1/Eshop123@localhost/XEPDB1"
```

```sql
-- Vérifier avant
SELECT idligneCommande, quantite, remise FROM LigneCommandes1 WHERE idligneCommande = 1;

-- DELETE via procédure
EXEC eshop1.deleteligne(1);

-- Vérifier Site1 → doit être 0
SELECT COUNT(*) AS site1_doit_etre_0 FROM LigneCommandes1 WHERE idligneCommande = 1;

-- Vérifier Global → doit être 0
SELECT COUNT(*) AS global_doit_etre_0 FROM eshop.LigneCommandes@link_global
WHERE idligneCommande = 1;
-- ✅ Résultat attendu : COUNT=0 sur les 2 bases
```

---

### DELETE : Site2 → Global

```bash
docker exec -it eshop-site2 sqlplus "eshop2/Eshop123@localhost/XEPDB1"
```

```sql
-- DELETE via procédure
EXEC eshop2.deleteligne(5);

-- Vérifier Site2 → doit être 0
SELECT COUNT(*) AS site2_doit_etre_0 FROM LigneCommandes2 WHERE idligneCommande = 5;

-- Vérifier Global → doit être 0
SELECT COUNT(*) AS global_doit_etre_0 FROM eshop.LigneCommandes@link_global
WHERE idligneCommande = 5;
-- ✅ Résultat attendu : COUNT=0 sur les 2 bases
```

---

### DELETE : Global → Site1

```bash
docker exec -it eshop-global sqlplus "eshop/Eshop123@localhost/XEPDB1"
```

```sql
-- Vérifier avant
SELECT idligneCommande, quantite, remise FROM eshop.LigneCommandes WHERE idligneCommande = 2;
SELECT idligneCommande, quantite, remise FROM eshop1.LigneCommandes1@link_site1
WHERE idligneCommande = 2;

-- DELETE via procédure
EXEC eshop.delete_global(2);

-- Vérifier Global → doit être 0
SELECT COUNT(*) AS global_doit_etre_0 FROM eshop.LigneCommandes WHERE idligneCommande = 2;

-- Vérifier Site1 → doit être 0
SELECT COUNT(*) AS site1_doit_etre_0 FROM eshop1.LigneCommandes1@link_site1
WHERE idligneCommande = 2;
-- ✅ Résultat attendu : COUNT=0 sur les 2 bases
```

---

### DELETE : Global → Site2

```sql
-- DELETE via procédure
EXEC eshop.delete_global(3);

-- Vérifier Global → doit être 0
SELECT COUNT(*) AS global_doit_etre_0 FROM eshop.LigneCommandes WHERE idligneCommande = 3;

-- Vérifier Site2 → doit être 0
SELECT COUNT(*) AS site2_doit_etre_0 FROM eshop2.LigneCommandes2@link_site2
WHERE idligneCommande = 3;
-- ✅ Résultat attendu : COUNT=0 sur les 2 bases
```

---

### Vérification globale des 3 sites

```sql
-- Comptage sur les 3 bases simultanément
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
| 1 | INSERT | Global → Site1 | `insert_global(1,1,200,100,5)` | Présent sur Global + Site1 |
| 2 | INSERT | Global → Site2 | `insert_global(2,5,10,50,0)` | Présent sur Global + Site2 |
| 3 | INSERT | Site1 → Global | `insert_and_sync(1,1,150,100,5)` | Présent sur Site1 + Global |
| 4 | INSERT | Site2 → Global | `insert_and_sync(2,5,10,50,0)` | Présent sur Site2 + Global |
| 5 | UPDATE | Global → Site1 | `update_global(1,999,50)` | quantite=999, remise=50 sur les 2 |
| 6 | UPDATE | Global → Site2 | `update_global(5,80,20)` | quantite=80, remise=20 sur les 2 |
| 7 | UPDATE | Site1 → Global | `update_and_sync(1,500,30)` | quantite=500, remise=30 sur les 2 |
| 8 | UPDATE | Site2 → Global | `update_and_sync(5,50,15)` | quantite=50, remise=15 sur les 2 |
| 9 | DELETE | Site1 → Global | `deleteligne(1)` | COUNT=0 sur Site1 + Global |
| 10 | DELETE | Site2 → Global | `deleteligne(5)` | COUNT=0 sur Site2 + Global |
| 11 | DELETE | Global → Site1 | `delete_global(2)` | COUNT=0 sur Global + Site1 |
| 12 | DELETE | Global → Site2 | `delete_global(3)` | COUNT=0 sur Global + Site2 |

---

## Commandes utiles

```bash
# Voir les logs Oracle
docker compose logs -f oracle-global

# Se connecter en SQL*Plus
docker exec -it eshop-global sqlplus "eshop/Eshop123@localhost/XEPDB1"
docker exec -it eshop-site1  sqlplus "eshop1/Eshop123@localhost/XEPDB1"
docker exec -it eshop-site2  sqlplus "eshop2/Eshop123@localhost/XEPDB1"

# Vérifier les triggers actifs
docker exec -it eshop-global sqlplus "eshop/Eshop123@localhost/XEPDB1" <<'EOF'
SELECT trigger_name, status FROM user_triggers ORDER BY trigger_name;
EXIT
EOF

# Vérifier les procédures
docker exec -it eshop-global sqlplus "eshop/Eshop123@localhost/XEPDB1" <<'EOF'
SELECT object_name, status FROM user_objects WHERE object_type = 'PROCEDURE';
EXIT
EOF

# Arrêter sans perdre les données
docker compose down

# Reset complet (efface toutes les données Oracle)
docker compose down -v
```

---

## ⚠️ Limitation connue

La **migration automatique** d'une ligne entre Site1 et Site2 lors d'un UPDATE
qui fait changer le seuil de quantité (ex: 50 → 150) n'est pas implémentée.

Le trigger `SYC_UPDATE_LIGNE` met à jour la ligne sur le site d'origine sans la déplacer.
Pour migrer manuellement une ligne de Site2 vers Site1 :

```sql
-- 1. Supprimer de l'ancien site
EXEC eshop.delete_global(idligne);

-- 2. Réinsérer avec la nouvelle quantité (sera routée vers le bon site)
EXEC eshop.insert_global(idcommande, idproduit, nouvelle_quantite, prix, remise);
```

---

## Dépôts liés

- **Frontend** (Next.js 14) : https://github.com/khalilbaidouri/eshop_front.git
- **Backend** (Spring Boot) : https://github.com/khalilbaidouri/eshop_back.git
