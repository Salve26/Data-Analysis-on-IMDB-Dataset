-- Use/create database
DROP DATABASE IF EXISTS imdb;
CREATE DATABASE IF NOT EXISTS imdb CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE imdb;

-- CREATE TABLES
DROP TABLE IF EXISTS movie;
CREATE TABLE movie
 (
  id VARCHAR(10) NOT NULL,
  title VARCHAR(200) DEFAULT NULL,
  year INT DEFAULT NULL,
  date_published DATE DEFAULT NULL,
  duration INT,
  country VARCHAR(250),
  worlwide_gross_income VARCHAR(30),
  languages VARCHAR(200),
  production_company VARCHAR(200),
  PRIMARY KEY (id)
);

DROP TABLE IF EXISTS genre;
CREATE TABLE genre
 (
    movie_id VARCHAR(10),
    genre VARCHAR(50),
    PRIMARY KEY (movie_id, genre)
);

DROP TABLE IF EXISTS director_mapping;
CREATE TABLE director_mapping
 (
    movie_id VARCHAR(10),
    name_id VARCHAR(10),
    PRIMARY KEY (movie_id, name_id)
);

DROP TABLE IF EXISTS role_mapping;
CREATE TABLE role_mapping
 (
    movie_id VARCHAR(10) NOT NULL,
    name_id VARCHAR(10) NOT NULL,
    category VARCHAR(20),
    PRIMARY KEY (movie_id, name_id)
);

DROP TABLE IF EXISTS names;
CREATE TABLE names
 (
  id varchar(10) NOT NULL,
  name varchar(100) DEFAULT NULL,
  height int DEFAULT NULL,
  date_of_birth date DEFAULT NULL,
  known_for_movies varchar(255) DEFAULT NULL,
  PRIMARY KEY (id)
);

DROP TABLE IF EXISTS ratings;
CREATE TABLE ratings
(
    movie_id VARCHAR(10) NOT NULL,
    avg_rating DECIMAL(3,1),
    total_votes INT,
    median_rating INT,
    PRIMARY KEY (movie_id)
);

-- ============================
-- LOAD CSV FILES from dataset/
-- ============================

LOAD DATA LOCAL INFILE 'dataset/movie.csv'
INTO TABLE movie
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@id, @title, @year, @release_date, @runtime, @country, @gross, @language, @production)
SET
  id = NULLIF(@id, ''),
  title = NULLIF(@title, ''),
  year = NULLIF(@year, '') + 0,
  date_published = NULLIF(STR_TO_DATE(NULLIF(@release_date, ''), '%Y-%m-%d'), ''),
  duration = NULLIF(@runtime, '') + 0,
  country = NULLIF(@country, ''),
  worlwide_gross_income = NULLIF(@gross, ''),
  languages = NULLIF(@language, ''),
  production_company = NULLIF(@production, '');

LOAD DATA LOCAL INFILE 'dataset/genre.csv'
INTO TABLE genre
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@movie_id, @genre)
SET
  movie_id = NULLIF(@movie_id, ''),
  genre = NULLIF(@genre, '');

LOAD DATA LOCAL INFILE 'dataset/director_mapping.csv'
INTO TABLE director_mapping
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@movie_id, @name_id)
SET
  movie_id = NULLIF(@movie_id, ''),
  name_id = NULLIF(@name_id, '');

LOAD DATA LOCAL INFILE 'dataset/role_mapping.csv'
INTO TABLE role_mapping
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@movie_id, @name_id, @category)
SET
  movie_id = NULLIF(@movie_id, ''),
  name_id = NULLIF(@name_id, ''),
  category = NULLIF(@category, '');

LOAD DATA LOCAL INFILE 'dataset/names.csv'
INTO TABLE names
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@id, @name, @height, @dob, @known_for)
SET
  id = NULLIF(@id, ''),
  name = NULLIF(@name, ''),
  height = NULLIF(@height, '') + 0,
  date_of_birth = NULLIF(STR_TO_DATE(NULLIF(@dob, ''), '%Y-%m-%d'), ''),
  known_for_movies = NULLIF(@known_for, '');

LOAD DATA LOCAL INFILE 'dataset/ratings.csv'
INTO TABLE ratings
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@movie_id, @avg_rating, @total_votes, @median_rating)
SET
  movie_id = NULLIF(@movie_id, ''),
  avg_rating = NULLIF(@avg_rating, '') + 0,
  total_votes = NULLIF(@total_votes, '') + 0,
  median_rating = NULLIF(@median_rating, '') + 0;

-- Optional: check counts
SELECT 'movie' AS tbl, COUNT(*) AS rows FROM movie
UNION ALL
SELECT 'genre', COUNT(*) FROM genre
UNION ALL
SELECT 'director_mapping', COUNT(*) FROM director_mapping
UNION ALL
SELECT 'role_mapping', COUNT(*) FROM role_mapping
UNION ALL
SELECT 'names', COUNT(*) FROM names
UNION ALL
SELECT 'ratings', COUNT(*) FROM ratings;
