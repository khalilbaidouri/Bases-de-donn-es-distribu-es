ALTER SESSION SET CONTAINER = XEPDB1;

-- PROCEDURE INSERT LIGNE SITE1
CREATE OR REPLACE PROCEDURE eshop1.insertligne(
  p_idligne    IN NUMBER,
  p_idcommande IN NUMBER,
  p_idproduit  IN NUMBER,
  p_quantite   IN NUMBER,
  p_prixunit   IN NUMBER,
  p_remise     IN NUMBER DEFAULT 0
) AS
  v_count NUMBER;
BEGIN
  IF p_quantite < 100 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Site1 gere uniquement Quantite >= 100');
  END IF;
  SELECT COUNT(*) INTO v_count FROM eshop1.Commandes1 WHERE idcommande = p_idcommande;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Commande inexistante sur Site1');
  END IF;
  SELECT COUNT(*) INTO v_count FROM eshop1.Produits1 WHERE idproduit = p_idproduit;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20003, 'Produit inexistant sur Site1');
  END IF;
  INSERT INTO eshop1.LigneCommandes1
    (idligneCommande, idcommande, idproduit, Quantite, PrixUnitaire, remise)
  VALUES
    (p_idligne, p_idcommande, p_idproduit, p_quantite, p_prixunit, p_remise);
  COMMIT;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    RAISE_APPLICATION_ERROR(-20004, 'IdLigne deja existant');
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END insertligne;
/

-- PROCEDURE DELETE LIGNE SITE1
CREATE OR REPLACE PROCEDURE eshop1.deleteligne(
  p_idligne IN NUMBER
) AS
  v_idcmd  NUMBER;
  v_count  NUMBER;
BEGIN
  SELECT idcommande INTO v_idcmd
  FROM eshop1.LigneCommandes1
  WHERE idligneCommande = p_idligne;

  DELETE FROM eshop1.LigneCommandes1 WHERE idligneCommande = p_idligne;

  SELECT COUNT(*) INTO v_count
  FROM eshop1.LigneCommandes1 WHERE idcommande = v_idcmd;

  IF v_count = 0 THEN
    DELETE FROM eshop1.Commandes1 WHERE idcommande = v_idcmd;
  END IF;

  COMMIT;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20005, 'LigneCommande introuvable sur Site1');
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END deleteligne;
/

-- PROCEDURE UPDATE LIGNE SITE1
CREATE OR REPLACE PROCEDURE eshop1.updateligne(
  p_idligne   IN NUMBER,
  p_idproduit IN NUMBER DEFAULT NULL,
  p_quantite  IN NUMBER DEFAULT NULL,
  p_remise    IN NUMBER DEFAULT NULL
) AS
  v_count NUMBER;
BEGIN
  IF p_quantite IS NOT NULL AND p_quantite < 100 THEN
    RAISE_APPLICATION_ERROR(-20006, 'Quantite doit etre >= 100 sur Site1');
  END IF;
  SELECT COUNT(*) INTO v_count
  FROM eshop1.LigneCommandes1 WHERE idligneCommande = p_idligne;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20007, 'LigneCommande introuvable');
  END IF;

  UPDATE eshop1.LigneCommandes1
  SET
    idproduit = NVL(p_idproduit, idproduit),
    Quantite  = NVL(p_quantite, Quantite),
    remise    = NVL(p_remise, remise)
  WHERE idligneCommande = p_idligne;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END updateligne;
/