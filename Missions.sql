CREATE DATABASE IF NOT EXISTS `missions`;
USE `missions`;

-- BIEN --
CREATE TABLE IF NOT EXISTS Bien (
    Id_bien INT NOT NULL PRIMARY KEY UNIQUE,
    Id_codedep_codecommune VARCHAR(255) NOT NULL,
    No_voie INT DEFAULT  NULL,
    BTQ VARCHAR(1) DEFAULT NULL,
    Type_de_voie VARCHAR(4) DEFAULT NULL,
    Voie VARCHAR(55) DEFAULT NULL,
    Nombre_de_piece INT DEFAULT 0,
    Surface_carrez FLOAT DEFAULT 0,
    Surface_local INT DEFAULT 0,
    Type_de_location INT DEFAULT 0
);

LOAD DATA LOCAL INFILE './Ressources/BienDB.csv'
    INTO TABLE Bien
    FIELDS TERMINATED BY ';'
    LINES TERMINATED BY '\n'
    IGNORE 1 ROWS
    (Id_bien, Id_codedep_codecommune, No_voie, BTQ, Type_de_voie, Voie, Nombre_de_piece, Surface_carrez, Surface_local, Type_de_location);
-- END BIEN --


-- VENTE --
CREATE TABLE IF NOT EXISTS Vente(
    Id_vente INT NOT NULL PRIMARY KEY AUTO_INCREMENT COMMENT 'Primary Key',
    Id_bien INT NOT NULL,
    Date Date NOT NULL,
    Valeur INT
);


LOAD DATA LOCAL INFILE './Ressources/VenteDB_modified.csv'
    INTO TABLE Vente
    FIELDS TERMINATED BY ';'
    LINES TERMINATED BY '\n'
    IGNORE 1 ROWS
    (Id_bien,Date, Valeur);


-- END VENTE --

-- COMMUNE --
CREATE TABLE IF NOT EXISTS Commune (
    Id_codedep_codecommune VARCHAR(255) NOT NULL PRIMARY KEY UNIQUE COMMENT 'Primary Key',
    Id_regional INT NOT NULL,
    Code_departement VARCHAR(3) NOT NULL COMMENT 'Code du département',
    Code_commune INT NOT NULL COMMENT 'Code de la commune',
    Code_postal INT,
    Nom_Commune VARCHAR(50) NOT NULL COMMENT 'Nom de la commune',
    Nbre_habitant_2019 INT NOT NULL
) COMMENT 'Table des communes';

LOAD DATA LOCAL INFILE './Ressources/CommuneDB.csv'
INTO TABLE Commune
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Id_codedep_codecommune,Id_regional, Code_departement, Code_commune,Code_postal, Nom_Commune, Nbre_habitant_2019);
-- END COMMUNE --


-- REGION --
CREATE TABLE IF NOT EXISTS Region(
    Id_regional  VARCHAR (255) NOT NULL PRIMARY KEY UNIQUE COMMENT 'Primary Key',
    Nom_region  VARCHAR(50)NOT NULL,
    Nom_regroup  VARCHAR(50)NOT NULL
);

LOAD DATA LOCAL INFILE './Ressources/RegionDB.csv'
INTO TABLE Region
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Id_regional, Nom_region, Nom_regroup);
-- END REGION --

SELECT * FROM Region;

SELECT * FROM Commune;

SELECT * FROM Bien;

SELECT * FROM Vente;


-- 1. Nombre total d’appartements vendus au 1er semestre 2020.

SELECT COUNT(*) AS total
FROM Vente V
INNER JOIN Bien B ON V.Id_bien = B.Id_bien
WHERE B.Type_de_location = 2 AND V.Date BETWEEN '2020-01-01' AND '2020-06-30';

-- Resultat --
-- 31378

-- 2. Le nombre de ventes d’appartement par région pour le 1er semestre 2020.

SELECT c.Id_regional, COUNT(v.Id_vente) AS Nombre_de_ventes
FROM Vente v
         JOIN Bien b ON v.Id_bien = b.Id_bien
        JOIN Commune c ON b.Id_codedep_codecommune = c.Id_codedep_codecommune
WHERE b.Type_de_location = 2
  AND v.Date BETWEEN '2020-01-01' AND '2020-06-30'
GROUP BY c.Id_regional;

-- Resultat --

/*
Id_regional | Nombre_de_ventes

1 | 2
2 | 94
3 | 34
4 | 44
11 | 13995
24 | 696
27 | 376
28 | 862
32 | 1254
44 | 984
52 | 1357
53 | 983
75 | 1932
76 | 1640
84 | 3253
93 | 3649
94 | 223
*/

-- 3. Proportion des ventes d’appartements par le nombre de pièces.

SELECT  b.Nombre_de_piece, COUNT(*) AS Nombre_de_ventes, (COUNT(*) / (SELECT COUNT(*) FROM Vente)) * 100 AS Proportion
FROM Vente v JOIN Bien b ON v.Id_bien = b.Id_bien
WHERE b.Type_de_location = 2
GROUP BY  b.Nombre_de_piece
ORDER BY  b.Nombre_de_piece;

-- Resultat --
/*
Nombre_de_piece | Nombre_de_ventes | Proportion
0 | 30 | 0.0878
1 | 6739 | 19.7226
2 | 9783 | 28.6312
3 | 8966 | 26.2402
4 | 4460 | 13.0528
5 | 1114 | 3.2603
6 | 204 | 0.5970
7 | 54 | 0.1580
8 | 17 | 0.0498
9 | 8 | 0.0234
10 | 2 | 0.0059
11 | 1 | 0.0029
*/

-- 4. Liste des 10 départements où le prix du mètre carré est le plus élevé.

SELECT  c.Code_departement, AVG(V.Valeur / B.Surface_carrez) AS prix
FROM Vente V
         JOIN Bien B ON V.Id_bien = B.Id_bien
         JOIN Commune C ON B.Id_codedep_codecommune = C.Id_codedep_codecommune
GROUP BY C.Code_departement
ORDER BY prix DESC
LIMIT 10;

-- Resultat --
/*
Code_departement | prix

75 | 12084.094011350971
92 | 7300.659801376467
94 | 5427.865876109605
74 | 4781.394537302812
06 | 4755.507115076021
93 | 4385.746206169729
78 | 4275.5752277951915
69 | 4100.283052626804
2A | 4062.912785201011
33 | 3807.235671550537
*/

-- 5. Prix moyen du mètre carré d’une maison en Île-de-France.

SELECT AVG(V.Valeur / B.Surface_carrez) AS prix
FROM Vente V
         INNER JOIN Bien B ON V.Id_bien = B.Id_bien
         INNER JOIN Commune C ON B.Id_codedep_codecommune = C.Id_codedep_codecommune
         INNER JOIN Region R ON C.Id_regional = R.Id_regional
WHERE R.Nom_region = 'Ile-de-France' AND B.Type_de_location = 1;

-- Resultat --
-- 3764.842720255957

-- 6. Liste des 10 appartements les plus chers avec la région et le nombre de mètres carrés.

SELECT V.Id_vente,  V.Valeur AS Prix, B.Id_bien, B.Surface_carrez  AS Surface_m2, R.Nom_region
FROM Vente V
    JOIN Bien B ON V.Id_bien = B.Id_bien
    JOIN Commune C ON B.Id_codedep_codecommune = C.Id_codedep_codecommune
    JOIN Region R ON C.Id_regional = R.Id_regional
ORDER BY V.Valeur DESC
LIMIT 10;

-- Resultat --

/*
V.Id_vente | prix | B.Id_bien | B.Surface_m2 | Nom_region
3580 | 9000000 | 3580 | 9 | Ile-de-France
29042 | 8600000 | 29042 | 64 | Ile-de-France
30538 | 8577713 | 30538 | 20 | Ile-de-France
26640 | 7620000 | 26640 | 42 | Ile-de-France
24176 | 7600000 | 24176 | 253 | Ile-de-France
16376 | 7535000 | 16376 | 139 | Ile-de-France
33780 | 7420000 | 33780 | 360 | Ile-de-France
17832 | 7200000 | 17832 | 595 | Ile-de-France
32237 | 7050000 | 32237 | 122 | Ile-de-France
15019 | 6600000 | 15019 | 79 | Ile-de-France
*/

-- 7. Taux d’évolution du nombre de ventes entre le premier et le second trimestre de 2020.

SELECT(
((SELECT COUNT(v.Id_vente) FROM Vente v WHERE v.Date BETWEEN '2020-04-01' AND '2020-06-30') -
(SELECT COUNT(v.Id_vente) FROM Vente v WHERE v.Date BETWEEN '2020-01-01' AND '2020-03-31')) /
(SELECT COUNT(v.Id_vente) FROM Vente v WHERE v.Date BETWEEN '2020-04-01' AND '2020-06-30')) * 100 AS Taux_Evolution;

-- 3.5474

-- 8. Le classement des régions par rapport au prix au mètre carré des appartement de plus de 4 pièces.

SELECT   r.Nom_region,  AVG(v.Valeur / b.Surface_carrez) AS prix_m2
FROM Vente v
         JOIN Bien b ON v.Id_bien = b.Id_bien
         JOIN Commune c ON b.Id_codedep_codecommune = c.Id_codedep_codecommune
         JOIN Region r ON c.Id_regional = r.Id_regional
WHERE b.Nombre_de_piece > 4 AND b.Type_de_location = 2
GROUP BY r.Nom_region
ORDER BY prix_m2 DESC;

-- Resultat --

/*
Nom_region | prix_m2
Ile-de-France,8806.66580308195
La Rï¿½union,3659.826139088729
Provence-Alpes-Cï¿½te d'Azur,3616.7089920908425
Corse,3117.8804072626663
Auvergne-Rhï¿½ne-Alpes,2903.8571305014634
Nouvelle-Aquitaine,2476.503480903778
Bretagne,2427.140819020973
Pays de la Loire,2329.2106903951308
Hauts-de-France,2199.923477318061
Occitanie,2107.244051489931
Normandie,2026.3089624878899
Grand Est,1560.9139044845404
Centre-Val de Loire,1459.9827028657387
Bourgogne-Franche-Comtï¿½,1260.7318887541098
Martinique,574.7663551401869

*/
-- 9. Liste des communes ayant eu au moins 50 ventes au 1er trimestre
SELECT C.Nom_commune, COUNT(v.Id_vente) AS nombre_ventes
from Vente v
JOIN Bien b ON v.Id_bien = b.Id_bien
JOIN Commune C on b.Id_codedep_codecommune = C.Id_codedep_codecommune
WHERE v.Date BETWEEN '2020-01-01' AND '2020-03-31'
GROUP BY C.Nom_commune
HAVING COUNT(v.Id_vente) > 50;

-- 10. Différence en pourcentage du prix au mètre carré entre un appartement de 2 pièces et un appartement de 3 pièces.

SELECT B.Nombre_de_piece, SUM(V.Valeur) AS Total_Valeur
FROM Vente V  JOIN Bien B ON V.Id_bien = B.Id_bien
WHERE B.Nombre_de_piece IN (2, 3)
GROUP BY B.Nombre_de_piece;

SELECT(((SELECT AVG(V1.Valeur / B1.Surface_carrez)
FROM Vente V1
JOIN Bien B1 ON V1.Id_bien = B1.Id_bien
WHERE B1.Nombre_de_piece = 3) -

(SELECT AVG(V2.Valeur / B2.Surface_carrez)
FROM Vente V2
JOIN Bien B2 ON V2.Id_bien = B2.Id_bien
WHERE B2.Nombre_de_piece = 2)) /

(SELECT AVG(V2.Valeur / B2.Surface_carrez)
FROM Vente V2
JOIN Bien B2 ON V2.Id_bien = B2.Id_bien
WHERE B2.Nombre_de_piece = 2)) * 100 AS Pourcentage_Difference;

-- -13.081196064334108

-- 11. Les moyennes de valeurs foncières pour le top 3 des communes des départements 6, 13, 33, 59 et 69.

SELECT Code_departement, Nom_Commune, Moyenne
FROM (
    SELECT
    c.Code_departement,
    c.Nom_Commune,
    AVG(v.Valeur) AS Moyenne,
    ROW_NUMBER() OVER (PARTITION BY c.Code_departement ORDER BY AVG(v.Valeur) DESC) AS rang
FROM Vente v
JOIN Bien b ON v.Id_bien = b.Id_bien
JOIN Commune c ON b.Id_codedep_codecommune = c.Id_codedep_codecommune
WHERE c.Code_departement IN ('6', '13', '33', '59', '69')
GROUP BY c.Code_departement, c.Nom_Commune) AS RankedValues
WHERE rang = 1
ORDER BY Moyenne DESC
LIMIT 3;

/*
33,Lï¿½ge-Cap-Ferret,549500.6364
69,Ville-sur-Jarnioux,485300.0000
59,Bersï¿½e,433202.0000

*/

-- 12. Les 20 communes avec le plus de transactions pour 1000 habitants pour les communes qui dépassent les 10 000 habitants

SELECT C.Nom_Commune, COUNT(V.Id_vente) / (C.Nbre_habitant_2019/1000) AS TransactionParHab
FROM Vente V
JOIN Bien B on V.Id_bien = B.Id_bien
JOIN Commune C on B.Id_codedep_codecommune = C.Id_codedep_codecommune
WHERE C.Nbre_habitant_2019 > 10000
GROUP BY C.Nom_Commune
ORDER BY TransactionParHab DESC
LIMIT 20;

/*
Paris 2e Arrondissement,5.8431
Paris 1er Arrondissement,4.9206
Paris 3e Arrondissement,4.6931
Arcachon,4.6226
La Baule-Escoublac,4.5842
Paris 4e Arrondissement,4.0830
Roquebrune-Cap-Martin,3.9874
Paris 8e Arrondissement,3.8345
Sanary-sur-Mer,3.4965
Paris 9e Arrondissement,3.4344
La Londe-les-Maures,3.4336
Paris 6e Arrondissement,3.3762
Saint-Cyr-sur-Mer,3.2409
Chantilly,3.1312
Pornichet,3.0594
Saint-Mandï¿½,3.0563
Paris 10e Arrondissement,3.0393
Menton,2.9373
Saint-Hilaire-de-Riez,2.8693
Vincennes,2.8071

*/