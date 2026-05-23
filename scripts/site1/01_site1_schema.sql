ALTER SESSION SET CONTAINER = XEPDB1;

CREATE USER eshop1 IDENTIFIED BY Eshop123
  DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;
GRANT CONNECT, RESOURCE, DBA TO eshop1;

CREATE TABLE eshop1.Categories1 (
  idCategorie NUMBER PRIMARY KEY,
  Designation VARCHAR2(100)
);

CREATE TABLE eshop1.Clients1 (
  idclient   NUMBER PRIMARY KEY,
  Codeclient VARCHAR2(20),
  Societe    VARCHAR2(100),
  Contact    VARCHAR2(100),
  Adresse    VARCHAR2(200),
  Ville      VARCHAR2(50),
  Pays       VARCHAR2(50)
);

CREATE TABLE eshop1.Produits1 (
  idproduit    NUMBER PRIMARY KEY,
  idCategorie  NUMBER NOT NULL,
  Designation  VARCHAR2(200),
  PrixUnitaire NUMBER(10,2),
  CONSTRAINT fk1_prod_cat FOREIGN KEY (idCategorie)
    REFERENCES eshop1.Categories1(idCategorie)
);

CREATE TABLE eshop1.Commandes1 (
  idcommande   NUMBER PRIMARY KEY,
  idclient     NUMBER NOT NULL,
  idemploye    NUMBER,
  DateCommande DATE,
  CONSTRAINT fk1_cmd_cli FOREIGN KEY (idclient)
    REFERENCES eshop1.Clients1(idclient)
);

CREATE TABLE eshop1.LigneCommandes1 (
  idligneCommande NUMBER PRIMARY KEY,
  idcommande      NUMBER NOT NULL,
  idproduit       NUMBER NOT NULL,
  Quantite        NUMBER NOT NULL,
  PrixUnitaire    NUMBER(10,2),
  remise          NUMBER(5,2) DEFAULT 0,
  CONSTRAINT chk1_qte  CHECK (Quantite >= 100),
  CONSTRAINT fk1_lc_cmd  FOREIGN KEY (idcommande)
    REFERENCES eshop1.Commandes1(idcommande),
  CONSTRAINT fk1_lc_prod FOREIGN KEY (idproduit)
    REFERENCES eshop1.Produits1(idproduit)
);

COMMIT;
EXIT