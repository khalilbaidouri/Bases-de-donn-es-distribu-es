ALTER SESSION SET CONTAINER = XEPDB1;

INSERT INTO Categories VALUES (35, 'Electronique');
INSERT INTO Categories VALUES (50, 'Informatique');
INSERT INTO Categories VALUES (60, 'Mobilier');

INSERT INTO Employes VALUES (1, 'Dupont', 'Jean', 'Commercial');
INSERT INTO Employes VALUES (2, 'Martin', 'Marie', 'Gestionnaire');

INSERT INTO Clients VALUES (1,'CLI001','TechCorp','Alice','12 rue de Paris','Paris','France','75001','0101010101');
INSERT INTO Clients VALUES (2,'CLI002','SmallShop','Bob','5 rue du Marché','Lyon','France','69001','0404040404');
INSERT INTO Clients VALUES (3,'CLI003','MegaDist','Carol','Zone Industrielle','Marseille','France','13001','0606060606');

INSERT INTO Produits VALUES (1, 50, 'Ordinateur portable Dell', 899.99, 'Unite');
INSERT INTO Produits VALUES (2, 50, 'Ecran 27 pouces', 349.99, 'Unite');
INSERT INTO Produits VALUES (3, 35, 'Smartphone Samsung', 599.99, 'Unite');
INSERT INTO Produits VALUES (4, 60, 'Bureau ergonomique', 249.99, 'Unite');
INSERT INTO Produits VALUES (5, 35, 'Casque Bluetooth', 79.99, 'Unite');

INSERT INTO Commandes VALUES (1, 1, 1, TO_DATE('2026-01-15','YYYY-MM-DD'), TO_DATE('2026-01-20','YYYY-MM-DD'));
INSERT INTO Commandes VALUES (2, 2, 1, TO_DATE('2026-02-10','YYYY-MM-DD'), TO_DATE('2026-02-15','YYYY-MM-DD'));
INSERT INTO Commandes VALUES (3, 3, 2, TO_DATE('2026-03-05','YYYY-MM-DD'), TO_DATE('2026-03-10','YYYY-MM-DD'));
INSERT INTO Commandes VALUES (4, 1, 2, TO_DATE('2026-04-20','YYYY-MM-DD'), TO_DATE('2026-04-25','YYYY-MM-DD'));

-- Gros volumes (Site1 : Quantite >= 100)
INSERT INTO LigneCommandes VALUES (1, 1, 1, 150, 899.99, 10);
INSERT INTO LigneCommandes VALUES (2, 1, 2, 200, 349.99, 5);
INSERT INTO LigneCommandes VALUES (3, 3, 3, 500, 599.99, 15);
INSERT INTO LigneCommandes VALUES (4, 4, 1, 100, 899.99, 8);

-- Petits volumes (Site2 : Quantite < 100)
INSERT INTO LigneCommandes VALUES (5, 2, 4, 3, 249.99, 0);
INSERT INTO LigneCommandes VALUES (6, 2, 5, 10, 79.99, 0);
INSERT INTO LigneCommandes VALUES (7, 3, 2, 50, 349.99, 3);
INSERT INTO LigneCommandes VALUES (8, 4, 5, 20, 79.99, 2);

COMMIT;