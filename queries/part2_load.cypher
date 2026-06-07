MATCH (n)
DETACH DELETE n;

CREATE CONSTRAINT user_id_unique IF NOT EXISTS
FOR (u:User)
REQUIRE u.userId IS UNIQUE;

CREATE CONSTRAINT movie_id_unique IF NOT EXISTS
FOR (m:Movie)
REQUIRE m.movieId IS UNIQUE;

CREATE CONSTRAINT genre_name_unique IF NOT EXISTS
FOR (g:Genre)
REQUIRE g.name IS UNIQUE;

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/kassimuss/kovalchuk_nosql_3/refs/heads/main/csv_import/users.csv' AS row
MERGE (u:User {userId: toInteger(row.userId)})
SET
  u.gender = row.gender,
  u.age = toInteger(row.age),
  u.occupation = row.occupation;

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/kassimuss/kovalchuk_nosql_3/refs/heads/main/csv_import/movies.csv' AS row
MERGE (m:Movie {movieId: toInteger(row.movieId)})
SET
  m.title = row.title,
  m.year = CASE
    WHEN row.title =~ '.*\\([0-9]{4}\\).*'
    THEN toInteger(replace(split(row.title, '(')[-1], ')', ''))
    ELSE null
  END;

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/kassimuss/kovalchuk_nosql_3/refs/heads/main/csv_import/movies.csv' AS row
MATCH (m:Movie {movieId: toInteger(row.movieId)})
WITH m, split(row.genres, '|') AS genres
UNWIND genres AS genreName
MERGE (g:Genre {name: genreName})
MERGE (m)-[:HAS_GENRE]->(g);

CALL apoc.periodic.iterate(
  "
  LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/kassimuss/kovalchuk_nosql_3/refs/heads/main/csv_import/ratings.csv' AS row
  WITH row
  LIMIT 200000
  RETURN row
  ",
  "
  MATCH (u:User {userId: toInteger(row.userId)})
  MATCH (m:Movie {movieId: toInteger(row.movieId)})
  MERGE (u)-[r:RATED]->(m)
  SET
    r.rating = toFloat(row.rating),
    r.timestamp = toInteger(row.timestamp)
  ",
  {batchSize: 5000, parallel: false}
);

MATCH (u:User) RETURN count(u) AS users;
MATCH (m:Movie) RETURN count(m) AS movies;
MATCH (g:Genre) RETURN count(g) AS genres;
MATCH ()-[r:RATED]->() RETURN count(r) AS ratings;
MATCH ()-[r:HAS_GENRE]->() RETURN count(r) AS genreLinks;