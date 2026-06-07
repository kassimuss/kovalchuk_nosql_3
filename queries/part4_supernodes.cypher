// Запит 1. Фільми з найбільшою кількістю оцінених стосунків

MATCH (m:Movie)<-[r:RATED]-(:User)
WITH
  m,
  count(r) AS ratingCount,
  avg(r.rating) AS avgRating
RETURN
  m.movieId AS movieId,
  m.title AS movie,
  ratingCount,
  round(avgRating * 100) / 100 AS avgRating
ORDER BY ratingCount DESC
LIMIT 10;

// Запит 2. Користувачі з найбільшою кількістю оцінок:

MATCH (u:User)-[r:RATED]->(:Movie)
WITH
  u,
  count(r) AS ratingCount,
  avg(r.rating) AS avgRating
RETURN
  u.userId AS userId,
  u.gender AS gender,
  u.age AS age,
  u.occupation AS occupation,
  ratingCount,
  round(avgRating * 100) / 100 AS avgRating
ORDER BY ratingCount DESC
LIMIT 10;

// Запит 3. Жанри з найбільшою кількістю пов’язаних фільмів:

MATCH (g:Genre)<-[r:HAS_GENRE]-(m:Movie)
WITH
  g,
  count(m) AS movieCount
RETURN
  g.name AS genre,
  movieCount
ORDER BY movieCount DESC
LIMIT 10;

// Запит 4. Вузли з найбільшою сумарною ступенем:

MATCH (n)
WITH
  n,
  labels(n) AS labels,
  count { (n)--() } AS degree
RETURN
  labels,
  CASE
    WHEN "Movie" IN labels THEN n.title
    WHEN "Genre" IN labels THEN n.name
    WHEN "User" IN labels THEN toString(n.userId)
    ELSE "unknown"
  END AS nodeName,
  degree
ORDER BY degree DESC
LIMIT 20;