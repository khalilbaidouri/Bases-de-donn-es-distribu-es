ALTER SESSION SET CONTAINER = XEPDB1;

CREATE OR REPLACE TRIGGER eshop.SYC_INSERT_LIGNE
AFTER INSERT ON eshop.LigneCommandes
FOR EACH ROW
DECLARE
  v_idclient  NUMBER;
  v_idemploye NUMBER;
  v_datecmd   DATE;
  v_idcateg   NUMBER;
  v_count     NUMBER;
BEGIN
  SELECT idclient, idemploye, DateCommande
  INTO v_idclient, v_idemploye, v_datecmd
  FROM eshop.Commandes
  WHERE idcommande = :NEW.idcommande;

  SELECT idCategorie INTO v_idcateg
  FROM eshop.Produits
  WHERE idproduit = :NEW.idproduit;

  IF :NEW.Quantite >= 100 THEN

    -- 1. Categorie
    SELECT COUNT(*) INTO v_count
    FROM eshop1.Categories1@link_site1
    WHERE idCategorie = v_idcateg;
    IF v_count = 0 THEN
      INSERT INTO eshop1.Categories1@link_site1
        (idCategorie, Designation)
      SELECT idCategorie, Designation
      FROM eshop.Categories
      WHERE idCategorie = v_idcateg;
    END IF;

    -- 2. Client
    SELECT COUNT(*) INTO v_count
    FROM eshop1.Clients1@link_site1
    WHERE idclient = v_idclient;
    IF v_count = 0 THEN
      INSERT INTO eshop1.Clients1@link_site1
        (idclient, Codeclient, Societe, Contact, Adresse, Ville, Pays)
      SELECT idclient, Codeclient, Societe, Contact, Adresse, Ville, Pays
      FROM eshop.Clients
      WHERE idclient = v_idclient;
    END IF;

    -- 3. Produit
    SELECT COUNT(*) INTO v_count
    FROM eshop1.Produits1@link_site1
    WHERE idproduit = :NEW.idproduit;
    IF v_count = 0 THEN
      INSERT INTO eshop1.Produits1@link_site1
        (idproduit, idCategorie, Designation, PrixUnitaire)
      SELECT idproduit, idCategorie, Designation, PrixUnitaire
      FROM eshop.Produits
      WHERE idproduit = :NEW.idproduit;
    END IF;

    -- 4. Commande
    SELECT COUNT(*) INTO v_count
    FROM eshop1.Commandes1@link_site1
    WHERE idcommande = :NEW.idcommande;
    IF v_count = 0 THEN
      INSERT INTO eshop1.Commandes1@link_site1
        (idcommande, idclient, idemploye, DateCommande)
      VALUES (:NEW.idcommande, v_idclient, v_idemploye, v_datecmd);
    END IF;

    -- 5. LigneCommande
    INSERT INTO eshop1.LigneCommandes1@link_site1
      (idligneCommande, idcommande, idproduit, Quantite, PrixUnitaire, remise)
    VALUES
      (:NEW.idligneCommande, :NEW.idcommande, :NEW.idproduit,
       :NEW.Quantite, :NEW.PrixUnitaire, :NEW.remise);

  ELSE

    -- 1. Categorie
    SELECT COUNT(*) INTO v_count
    FROM eshop2.Categories2@link_site2
    WHERE idCategorie = v_idcateg;
    IF v_count = 0 THEN
      INSERT INTO eshop2.Categories2@link_site2
        (idCategorie, Designation)
      SELECT idCategorie, Designation
      FROM eshop.Categories
      WHERE idCategorie = v_idcateg;
    END IF;

    -- 2. Client
    SELECT COUNT(*) INTO v_count
    FROM eshop2.Clients2@link_site2
    WHERE idclient = v_idclient;
    IF v_count = 0 THEN
      INSERT INTO eshop2.Clients2@link_site2
        (idclient, Codeclient, Societe, Contact, Adresse, Ville, Pays)
      SELECT idclient, Codeclient, Societe, Contact, Adresse, Ville, Pays
      FROM eshop.Clients
      WHERE idclient = v_idclient;
    END IF;

    -- 3. Produit
    SELECT COUNT(*) INTO v_count
    FROM eshop2.Produits2@link_site2
    WHERE idproduit = :NEW.idproduit;
    IF v_count = 0 THEN
      INSERT INTO eshop2.Produits2@link_site2
        (idproduit, idCategorie, Designation, PrixUnitaire)
      SELECT idproduit, idCategorie, Designation, PrixUnitaire
      FROM eshop.Produits
      WHERE idproduit = :NEW.idproduit;
    END IF;

    -- 4. Commande
    SELECT COUNT(*) INTO v_count
    FROM eshop2.Commandes2@link_site2
    WHERE idcommande = :NEW.idcommande;
    IF v_count = 0 THEN
      INSERT INTO eshop2.Commandes2@link_site2
        (idcommande, idclient, idemploye, DateCommande)
      VALUES (:NEW.idcommande, v_idclient, v_idemploye, v_datecmd);
    END IF;

    -- 5. LigneCommande
    INSERT INTO eshop2.LigneCommandes2@link_site2
      (idligneCommande, idcommande, idproduit, Quantite, PrixUnitaire, remise)
    VALUES
      (:NEW.idligneCommande, :NEW.idcommande, :NEW.idproduit,
       :NEW.Quantite, :NEW.PrixUnitaire, :NEW.remise);

  END IF;
END SYC_INSERT_LIGNE;
/

CREATE OR REPLACE TRIGGER eshop.SYC_DELETE_LIGNE
AFTER DELETE ON eshop.LigneCommandes
FOR EACH ROW
BEGIN
  IF :OLD.Quantite >= 100 THEN
    DELETE FROM eshop1.LigneCommandes1@link_site1
    WHERE idligneCommande = :OLD.idligneCommande;
  ELSE
    DELETE FROM eshop2.LigneCommandes2@link_site2
    WHERE idligneCommande = :OLD.idligneCommande;
  END IF;
END SYC_DELETE_LIGNE;
/

CREATE OR REPLACE TRIGGER eshop.SYC_UPDATE_LIGNE
AFTER UPDATE ON eshop.LigneCommandes
FOR EACH ROW
BEGIN
  IF :OLD.Quantite >= 100 THEN
    UPDATE eshop1.LigneCommandes1@link_site1
    SET idproduit = :NEW.idproduit,
        Quantite  = :NEW.Quantite,
        remise    = :NEW.remise
    WHERE idligneCommande = :NEW.idligneCommande;
  ELSE
    UPDATE eshop2.LigneCommandes2@link_site2
    SET idproduit = :NEW.idproduit,
        Quantite  = :NEW.Quantite,
        remise    = :NEW.remise
    WHERE idligneCommande = :NEW.idligneCommande;
  END IF;
END SYC_UPDATE_LIGNE;
/

EXIT