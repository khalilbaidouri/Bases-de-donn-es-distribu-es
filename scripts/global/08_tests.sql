ALTER SESSION SET CONTAINER = XEPDB1;

PROMPT ==============================
PROMPT TEST 1 : Comptage initial
PROMPT ==============================
SELECT 'Global' AS site, COUNT(*) AS total
FROM eshop.LigneCommandes
UNION ALL
SELECT 'Site1', COUNT(*)
FROM eshop1.LigneCommandes1@link_site1
UNION ALL
SELECT 'Site2', COUNT(*)
FROM eshop2.LigneCommandes2@link_site2;

PROMPT ==============================
PROMPT TEST 2 : INSERT gros volume
PROMPT Quantite=300 doit aller Site1
PROMPT ==============================
INSERT INTO eshop.Commandes
  VALUES (99, 1, 1, TO_DATE('2026-06-01','YYYY-MM-DD'), NULL);
INSERT INTO eshop.LigneCommandes
  VALUES (999, 99, 1, 300, 899.99, 10);
COMMIT;

SELECT 'Site1' AS site, COUNT(*) AS present
FROM eshop1.LigneCommandes1@link_site1
WHERE idligneCommande = 999;

PROMPT ==============================
PROMPT TEST 3 : INSERT petit volume
PROMPT Quantite=5 doit aller Site2
PROMPT ==============================
INSERT INTO eshop.Commandes
  VALUES (98, 2, 1, TO_DATE('2026-06-02','YYYY-MM-DD'), NULL);
INSERT INTO eshop.LigneCommandes
  VALUES (998, 98, 5, 5, 79.99, 0);
COMMIT;

SELECT 'Site2' AS site, COUNT(*) AS present
FROM eshop2.LigneCommandes2@link_site2
WHERE idligneCommande = 998;

PROMPT ==============================
PROMPT TEST 4 : UPDATE synchronisation
PROMPT ==============================
UPDATE eshop.LigneCommandes
SET remise = 20
WHERE idligneCommande = 999;
COMMIT;

SELECT remise AS remise_site1
FROM eshop1.LigneCommandes1@link_site1
WHERE idligneCommande = 999;

PROMPT ==============================
PROMPT TEST 5 : DELETE synchronisation
PROMPT ==============================
DELETE FROM eshop.LigneCommandes
WHERE idligneCommande = 998;
COMMIT;

SELECT COUNT(*) AS doit_etre_0
FROM eshop2.LigneCommandes2@link_site2
WHERE idligneCommande = 998;

PROMPT ==============================
PROMPT TOUS LES TESTS TERMINES
PROMPT ==============================

EXIT