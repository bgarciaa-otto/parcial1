ALTER SESSION SET "_ORACLE_SCRIPT"=true; 

-- Brallan Garcia Aguirre

-- 1. CREATE A TABLESPACE MID_TERM WITH ONE DATAFILE OF 50Mb (For the datafile don't put the path, just the name of the datafile)
CREATE TABLESPACE MID_TERM
    DATAFILE 'MID_TERM01.dbf' SIZE 50M
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE;

-- 2. CREATE AN USER WITH 20Mb ASSIGNED TO THE TABLESPACE MID_TERM
CREATE USER USER01
IDENTIFIED BY "USER01" 
DEFAULT TABLESPACE MID_TERM
QUOTA 20M ON MID_TERM;

-- 3. GIVE THE DBA ROLE TO THE USER, ALSO SHOULD BE ABLE TO LOG IN.
GRANT CONNECT TO USER01;
GRANT DBA TO USER01;

-- 4. CREATE TWO SEQUENCES:
--	5.1 COMUNAS_SEQ SHOULD START IN 50 WITH INCREMENTS OF 3
CREATE SEQUENCE COMUNAS_SEQ
    START WITH 50
    INCREMENT BY 3
    NOCYCLE;
--	5.2 COLEGIOS_SEQ SHOULD START IN 100 WITH INCREMENTS OF 1
CREATE SEQUENCE COLEGIOS_SEQ
    START WITH 100
    INCREMENT BY 1
    NOCYCLE;
    
-- 5. CREATE THE NEXT TABLES:

CREATE TABLE COMUNAS (
	ID INTEGER PRIMARY KEY,
	NOMBRE VARCHAR2(255)
);

INSERT INTO COMUNAS VALUES (1,	'POPULAR');
INSERT INTO COMUNAS VALUES (10,	'LA CANDELARIA');
INSERT INTO COMUNAS VALUES (11,	'LAURELES ESTADIO');
INSERT INTO COMUNAS VALUES (12,	'LA AMERICA');
INSERT INTO COMUNAS VALUES (13,	'SAN JAVIER');
INSERT INTO COMUNAS VALUES (14,	'POBLADO');
INSERT INTO COMUNAS VALUES (15,	'GUAYABAL');
INSERT INTO COMUNAS VALUES (16,	'BELÉN');
INSERT INTO COMUNAS VALUES (2,	'SANTA CRUZ');
INSERT INTO COMUNAS VALUES (3,	'MANRIQUE');
INSERT INTO COMUNAS VALUES (4,	'ARANJUEZ');
INSERT INTO COMUNAS VALUES (5,	'CASTILLA');
INSERT INTO COMUNAS VALUES (50,	'PALMITAS');
INSERT INTO COMUNAS VALUES (6,	'DOCE DE OCTUBRE');
INSERT INTO COMUNAS VALUES (60,	'SAN CRISTOBAL');
INSERT INTO COMUNAS VALUES (7,	'ROBLEDO');
INSERT INTO COMUNAS VALUES (70,	'ALTAVISTA');
INSERT INTO COMUNAS VALUES (8,	'VILLA HERMOSA');
INSERT INTO COMUNAS VALUES (80,	'SAN ANTONIO DE PRADO');
INSERT INTO COMUNAS VALUES (9,	'BUENOS AIRES');
INSERT INTO COMUNAS VALUES (90,	'SANTA ELENA');

--FOR THE NEXT TABLE YOU SHOULD: 	

-- ADD THE PRIMARY KEY "ID" COLUMN TO THE COLEGIOS TABLE, 
-- ALSO ADD THE FOREIGN KEY WITH COMUNAS TABLE. THE NAME OF THE FOREIGN KEY SHOULD BE "COMUNA_FK"

create table colegios (
	ID INTEGER PRIMARY KEY,
	consecutivo_dane VARCHAR2(255),
	nombre_sede VARCHAR2(255),
	tipo_sede VARCHAR2(255),
	comuna_id INTEGER,
	prestacion_servicio VARCHAR2(255),
	zona VARCHAR2(255),
	barrio VARCHAR2(255),
	sector VARCHAR2(255),
	direccion_sede VARCHAR2(255),
	telefono_sede VARCHAR2(255),
	rector VARCHAR2(255),
	contador_prejardin_jardin INTEGER,
	contador_transicion INTEGER,
	contador_primaria INTEGER,
	contador_secundaria INTEGER,
	contador_media INTEGER,
	contador_adultos INTEGER,
	jornada_completa VARCHAR(8),
	jornada_manana VARCHAR(8),
	jornada_tarde VARCHAR(8),
	jornada_nocturna VARCHAR(8),
	jornada_fin_de_semana VARCHAR(8),
	jornada_unica VARCHAR(8),
	clasificacion_icfes VARCHAR(8),
    CONSTRAINT COMUNA_FK
    FOREIGN KEY (comuna_id)
    REFERENCES COMUNAS (id)
);

-- 6. Import the data: https://gist.github.com/amartinezg/035524e3cb6ec719bb839dd97018c098

-- 7. Queries (DO NOT CHANGE THE NAME OF THE COLUMNS):

-- 7.1: Traiga el nombre del barrio y el número de colegios ubicados en cada barrio de aquellas instituciones ubicadas en la comuna de buenos aires
--      ordenado por el número de colegios de mayor a menor.
--	    Columnas: barrio, numero_colegios
SELECT B.barrio, COUNT(1) AS numero_colegios 
FROM COMUNAS A
INNER JOIN COLEGIOS B
ON A.id = b.comuna_id
WHERE A.NOMBRE = 'BUENOS AIRES'
GROUP BY B.barrio
ORDER BY COUNT(1) DESC;

-- 7.2: Traiga los registros junto con el nombre de su comuna, para cada registro deberá calcularse el total de los estudiantes según los contadores. 
--      También deberá traer el total de estudiantes agrupados por comuna.
--	    Columnas: ID, NOMBRE_SEDE, COMUNA_ID, NOMBRE_COMUNA, TOTAL_GENERAL, TOTAL_POR COMUNA
SELECT  b.ID, 
        b.nombre_sede, 
        b.comuna_id, 
        a.nombre as NOMBRE_COMUNA, 
        (contador_prejardin_jardin +
        contador_transicion +
        contador_primaria +
        contador_secundaria +
        contador_media +
        contador_adultos) as TOTAL_GENERAL,
        sum(contador_prejardin_jardin +
        contador_transicion +
        contador_primaria +
        contador_secundaria +
        contador_media +
        contador_adultos) OVER (PARTITION BY a.nombre) as "TOTAL_POR COMUNA"
FROM COMUNAS A
INNER JOIN COLEGIOS B
ON A.id = b.comuna_id;

-- 7.3: Traiga los colegios que dicten clases a estudiantes de prejardin-jardin y que en la prestación de su servicio sean no oficiales 
--      para las comunas ARANJUEZ, CASTILLA y DOCE DE OCTUBRE. 
--      Deberá incluir el contador de estudiantes de secundaria y deberá calcular el promedio de estudiantes de secundaria agrupados por comuna
--      redondeado a 2 decimales.
--	    Columnas: ID, NOMBRE_SEDE, COMUNA_ID, NOMBRE_COMUNA, CONTADOR_SECUNDARIA, PROMEDIO_SECUNDARIA_COMUNA
SELECT  B.ID, 
        b.nombre_sede, 
        b.comuna_id, 
        a.nombre as NOMBRE_COMUNA, 
        b.contador_secundaria AS CONTADOR_SECUNDARIA, 
        round(AVG(b.contador_secundaria) OVER (PARTITION BY a.nombre),2)  AS PROMEDIO_SECUNDARIA_COMUNA
FROM COMUNAS A
INNER JOIN COLEGIOS B
ON A.id = b.comuna_id
WHERE b.prestacion_servicio = 'NO OFICIAL'
AND contador_prejardin_jardin > 0
AND a.nombre IN ('ARANJUEZ', 'CASTILLA','DOCE DE OCTUBRE');

-- 7.4 Traiga el nombre de los rectores y el número de colegios encargados para cada rector de aquellos rectores que estén encargados de más de 2 colegios. 
--	Los registros deberán estar ordenados alfabéticamente
--	Nota: NO se deberán incluir aquellos registros que tengan un correo electrónico registrado y tampoco aquellos que registran como nombre "s/d"
--	Columnas: rector, numero_colegios
SELECT b.rector, COUNT(1) AS numero_colegios
FROM COMUNAS A
INNER JOIN COLEGIOS B
ON A.id = b.comuna_id
WHERE b.rector not Like '%s/d%'
AND b.rector not Like '%@%'
GROUP BY b.rector
HAVING COUNT(1) > 1
ORDER BY b.rector;

-- 7.5 Muestre el nombre del colegio, el barrio, la dirección de aquellos colegios que estén ubicados en la zona rural
--     y tengan algún tipo de clasificación en el ICFES. Además deberá traer aquellos colegios que enseñan a más de 200 estudiantes adultos
--	   Columnas: barrio, numero_colegios
SELECT b.nombre_sede, b.barrio, b.direccion_sede
FROM COMUNAS A 
INNER JOIN COLEGIOS B
ON A.id = b.comuna_id
WHERE b.zona = 'Rural'
and b.clasificacion_icfes <> 'N/A'
and b.contador_adultos > 200;