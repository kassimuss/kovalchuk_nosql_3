// Базові запити. Запит 1. Знайти всі фільми жанру «Thriller» із середнім рейтингом вище 4.0:

MATCH (m:Movie)-[:HAS_GENRE]->(:Genre {name: "Thriller"})
MATCH (m)<-[r:RATED]-(:User)
WITH
  m,
  avg(r.rating) AS avgRating,
  count(r) AS ratingCount
WHERE avgRating > 4.0 AND ratingCount >= 20
RETURN
  m.title AS movie,
  round(avgRating * 100) / 100 AS avgRating,
  ratingCount
ORDER BY avgRating DESC, ratingCount DESC
LIMIT 10;

// Базові запити. Запит 2. Знайти користувачів, які поставили оцінку 5 більш ніж 50 фільмам:

MATCH (u:User)-[r:RATED]->(m:Movie)
WHERE r.rating = 5
WITH
  u,
  count(m) AS fiveStarMovies
WHERE fiveStarMovies > 50
RETURN
  u.userId AS userId,
  u.gender AS gender,
  u.age AS age,
  u.occupation AS occupation,
  fiveStarMovies
ORDER BY fiveStarMovies DESC
LIMIT 10;

// Запити середнього рівня. Запит 3. Знайти фільми, які обидва користувачі (наприклад, userId=1 і userId=2) оцінили високо (рейтинг ≥ 4):

MATCH (u1:User {userId: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User {userId: 2})
WHERE r1.rating >= 4 AND r2.rating >= 4
RETURN
  m.title AS movie,
  r1.rating AS user1Rating,
  r2.rating AS user2Rating
ORDER BY movie
LIMIT 20;

// Запити середнього рівня. Запит 4. Знайти жанри, чиї фільми стабільно отримують високі оцінки — середній рейтинг і кількість оцінок:

MATCH (g:Genre)<-[:HAS_GENRE]-(m:Movie)<-[r:RATED]-(:User)
WITH
  g,
  avg(r.rating) AS avgRating,
  count(r) AS ratingCount
WHERE ratingCount >= 1000
RETURN
  g.name AS genre,
  round(avgRating * 100) / 100 AS avgRating,
  ratingCount
ORDER BY avgRating DESC
LIMIT 10;

// Складні запити. Запит 5. Рекомендація «користувачі зі схожими смаками також дивилися»: для заданого користувача знайти фільми, які він ще не дивився, але високо оцінили користувачі з подібними смаками:

MATCH (target:User {userId: 1})-[r1:RATED]->(common:Movie)<-[r2:RATED]-(similar:User)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND target <> similar

WITH
  target,
  similar,
  count(common) AS commonLikedMovies
WHERE commonLikedMovies >= 3

MATCH (similar)-[r3:RATED]->(rec:Movie)
WHERE r3.rating >= 4
  AND NOT (target)-[:RATED]->(rec)

RETURN
  rec.title AS recommendedMovie,
  count(DISTINCT similar) AS similarUsers,
  sum(commonLikedMovies) AS recommendationScore
ORDER BY recommendationScore DESC, similarUsers DESC
LIMIT 10;

// Складні запити. Запит 6. Знайти найкоротший ланцюжок зв’язку між двома користувачами через спільні фільми:

MATCH path = shortestPath(
  (u1:User {userId: 1})-[:RATED*..6]-(u2:User {userId: 2})
)
RETURN
  path,
  length(path) AS pathLength;