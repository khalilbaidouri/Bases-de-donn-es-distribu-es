-- Connexion au schéma ESHOP
ALTER SESSION SET CONTAINER = XEPDB1;

CREATE TABLE Clients (
  idclient     NUMBER PRIMARY KEY,
  Codeclient   VARCHAR2(20) UNIQUE NOT NULL,
  Societe      VARCHAR2(100),
  Contact      VARCHAR2(100),
  Adresse      VARCHAR2(200),
  Ville        VARCHAR2(50),
  Pays         VARCHAR2(50),
  CodePostal   VARCHAR2(10),
  Telephone    VARCHAR2(20)
);

CREATE TABLE Categories (
  idCategorie  NUMBER PRIMARY KEY,
  Designation  VARCHAR2(100) NOT NULL
);

CREATE TABLE Employes (
  idemploye    NUMBER PRIMARY KEY,
  Nom          VARCHAR2(50) NOT NULL,
  Prenom       VARCHAR2(50),
  Fonction     VARCHAR2(100)
);

CREATE TABLE Produits (
  idproduit    NUMBER PRIMARY KEY,
  idCategorie  NUMBER NOT NULL,
  Designation  VARCHAR2(200) NOT NULL,
  PrixUnitaire NUMBER(10,2),
  UniteVente   VARCHAR2(20),
  CONSTRAINT fk_prod_cat FOREIGN KEY (idCategorie)
    REFERENCES Categories(idCategorie)
);

CREATE TABLE Commandes (
  idcommande   NUMBER PRIMARY KEY,
  idclient     NUMBER NOT NULL,
  idemploye    NUMBER,
  DateCommande DATE DEFAULT SYSDATE,
  DateLivraison DATE,
  CONSTRAINT fk_cmd_client FOREIGN KEY (idclient)
    REFERENCES Clients(idclient),
  CONSTRAINT fk_cmd_emp FOREIGN KEY (idemploye)
    REFERENCES Employes(idemploye)
);

CREATE TABLE LigneCommandes (
  idligneCommande NUMBER PRIMARY KEY,
  idcommande      NUMBER NOT NULL,
  idproduit       NUMBER NOT NULL,
  Quantite        NUMBER NOT NULL CHECK (Quantite > 0),
  PrixUnitaire    NUMBER(10,2),
  remise          NUMBER(5,2) DEFAULT 0,
  CONSTRAINT fk_lc_cmd  FOREIGN KEY (idcommande)
    REFERENCES Commandes(idcommande),
  CONSTRAINT fk_lc_prod FOREIGN KEY (idproduit)
    REFERENCES Produits(idproduit)
);

COMMIT;