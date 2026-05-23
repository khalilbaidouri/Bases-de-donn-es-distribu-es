ALTER SESSION SET CONTAINER = XEPDB1;

-- Requête 1 : Commandes par client en 2026
SELECT c.idclient, c.Societe, COUNT(cmd.idcommande) AS nb_commandes
FROM eshop.Clients c
JOIN eshop.Commandes cmd ON c.idclient = cmd.idclient
WHERE EXTRACT(YEAR FROM cmd.DateCommande) = 2026
GROUP BY c.idclient, c.Societe
ORDER BY nb_commandes DESC;

-- Requête 2 : CA par catégorie 2026 (Site1 + Site2)
SELECT cat.Designation AS categorie,
       SUM(ca_total)   AS chiffre_affaires_2026
FROM eshop.Categories cat
JOIN (
  SELECT p.idCategorie,
    SUM(lc.Quantite * lc.PrixUnitaire * (1 - lc.remise/100)) AS ca_total
  FROM eshop1.LigneCommandes1@link_site1 lc
  JOIN eshop1.Commandes1@link_site1 cmd ON lc.idcommande = cmd.idcommande
  JOIN eshop1.Produits1@link_site1  p   ON lc.idproduit  = p.idproduit
  WHERE EXTRACT(YEAR FROM cmd.DateCommande) = 2026
  GROUP BY p.idCategorie
  UNION ALL
  SELECT p.idCategorie,
    SUM(lc.Quantite * lc.PrixUnitaire * (1 - lc.remise/100)) AS ca_total
  FROM eshop2.LigneCommandes2@link_site2 lc
  JOIN eshop2.Commandes2@link_site2 cmd ON lc.idcommande = cmd.idcommande
  JOIN eshop2.Produits2@link_site2  p   ON lc.idproduit  = p.idproduit
  WHERE EXTRACT(YEAR FROM cmd.DateCommande) = 2026
  GROUP BY p.idCategorie
) contributions ON cat.idCategorie = contributions.idCategorie
GROUP BY cat.Designation
ORDER BY chiffre_affaires_2026 DESC;

EXIT