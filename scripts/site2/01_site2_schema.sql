ALTER SESSION SET CONTAINER = XEPDB1;

CREATE USER eshop2 IDENTIFIED BY Eshop123
  DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;
GRANT CONNECT, RESOURCE, DBA TO eshop2;

CREATE TABLE eshop2.Categories2 (
  idCategorie NUMBER PRIMARY KEY,
  Designation VARCHAR2(100)
);

CREATE TABLE eshop2.Clients2 (
  idclient   NUMBER PRIMARY KEY,
  Codeclient VARCHAR2(20),
  Societe    VARCHAR2(100),
  Contact    VARCHAR2(100),
  Adresse    VARCHAR2(200),
  Ville      VARCHAR2(50),
  Pays       VARCHAR2(50)
);

CREATE TABLE eshop2.Produits2 (
  idproduit    NUMBER PRIMARY KEY,
  idCategorie  NUMBER NOT NULL,
  Designation  VARCHAR2(200),
  PrixUnitaire NUMBER(10,2),
  CONSTRAINT fk2_prod_cat FOREIGN KEY (idCategorie)
    REFERENCES eshop2.Categories2(idCategorie)
);

CREATE TABLE eshop2.Commandes2 (
  idcommande   NUMBER PRIMARY KEY,
  idclient     NUMBER NOT NULL,
  idemploye    NUMBER,
  DateCommande DATE,
  CONSTRAINT fk2_cmd_cli FOREIGN KEY (idclient)
    REFERENCES eshop2.Clients2(idclient)
);

CREATE TABLE eshop2.LigneCommandes2 (
  idligneCommande NUMBER PRIMARY KEY,
  idcommande      NUMBER NOT NULL,
  idproduit       NUMBER NOT NULL,
  Quantite        NUMBER NOT NULL,
  PrixUnitaire    NUMBER(10,2),
  remise          NUMBER(5,2) DEFAULT 0,
  CONSTRAINT chk2_qte  CHECK (Quantite < 100),
  CONSTRAINT fk2_lc_cmd  FOREIGN KEY (idcommande)
    REFERENCES eshop2.Commandes2(idcommande),
  CONSTRAINT fk2_lc_prod FOREIGN KEY (idproduit)
    REFERENCES eshop2.Produits2(idproduit)
);

COMMIT;
EXIT