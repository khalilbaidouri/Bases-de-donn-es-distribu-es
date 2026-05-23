ALTER SESSION SET CONTAINER = XEPDB1;

-- Plan AVANT index
EXPLAIN PLAN FOR
SELECT c.idclient, c.Societe, COUNT(cmd.idcommande) AS nb_commandes
FROM eshop.Clients c
JOIN eshop.Commandes cmd ON c.idclient = cmd.idclient
WHERE EXTRACT(YEAR FROM cmd.DateCommande) = 2026
GROUP BY c.idclient, c.Societe
ORDER BY nb_commandes DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Création des index
CREATE INDEX eshop.idx_cmd_client
  ON eshop.Commandes(idclient);

CREATE INDEX eshop.idx_cmd_date
  ON eshop.Commandes(DateCommande);

CREATE INDEX eshop.idx_cmd_date_client
  ON eshop.Commandes(DateCommande, idclient);

CREATE INDEX eshop.idx_lc_commande
  ON eshop.LigneCommandes(idcommande);

CREATE INDEX eshop.idx_lc_produit
  ON eshop.LigneCommandes(idproduit);

-- Plan APRES index
EXPLAIN PLAN FOR
SELECT c.idclient, c.Societe, COUNT(cmd.idcommande) AS nb_commandes
FROM eshop.Clients c
JOIN eshop.Commandes cmd ON c.idclient = cmd.idclient
WHERE EXTRACT(YEAR FROM cmd.DateCommande) = 2026
GROUP BY c.idclient, c.Societe
ORDER BY nb_commandes DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

EXIT