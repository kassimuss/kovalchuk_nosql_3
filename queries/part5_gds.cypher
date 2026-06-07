// Крок 1: матеріалізуємо ребра фільм-фільм через спільних користувачів
MATCH (m1:Movie)<-[r1:RATED]-(u:User)-[r2:RATED]->(m2:Movie)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(m1) < id(m2)
WITH m1, m2, count(u) AS weight
WHERE weight >= 20
WITH m1, m2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (m1)-[co:CO_RATED]-(m2)
SET co.weight = weight;

// Перевіряємо
MATCH ()-[co:CO_RATED]-()
RETURN count(co) AS coRatedLinks;

// Крок 2: створюємо проєкцію на основі матеріалізованих ребер
CALL gds.graph.project(
  'movieGraph',
  'Movie',
  'CO_RATED',
  {
    relationshipProperties: ['weight'],
    undirectedRelationshipTypes: ['CO_RATED'],
    memory: '2GB'
  }
)
YIELD graphName, nodeCount, relationshipCount
RETURN graphName, nodeCount, relationshipCount;

// Крок 3: Запуск PageRank
CALL gds.pageRank.stream('movieGraph', {
  relationshipWeightProperty: 'weight'
})
YIELD nodeId, score
MATCH (m:Movie)
WHERE id(m) = nodeId
RETURN
  m.movieId AS movieId,
  m.title AS movie,
  round(score * 10000) / 10000 AS pageRank
ORDER BY pageRank DESC
LIMIT 10;

// Крок 4: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('movieGraph');
MATCH ()-[co:CO_RATED]-() DELETE co;

// 5.2 Louvain

MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
WHERE weight >= 3
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (u1)-[sim:SIMILAR]->(u2)
SET sim.weight = weight;

// Перевірка

MATCH ()-[sim:SIMILAR]->()
RETURN count(sim) AS similarLinks;

// Створюємо GDS-проєкцію для Louvain

CALL gds.graph.project(
  'userSimilarity',
  'User',
  'SIMILAR',
  {
    relationshipProperties: ['weight'],
    memory: '2GB'
  }
)
YIELD graphName, nodeCount, relationshipCount
RETURN graphName, nodeCount, relationshipCount;

// Запускаємо Louvain

CALL gds.louvain.stream('userSimilarity', {
  relationshipWeightProperty: 'weight'
})
YIELD nodeId, communityId
MATCH (u:User)
WHERE id(u) = nodeId
RETURN
  communityId,
  count(u) AS usersInCommunity
ORDER BY usersInCommunity DESC
LIMIT 10;

// Перегляд топ жанрів в спільноті

CALL gds.louvain.stream('userSimilarity', {
  relationshipWeightProperty: 'weight'
})
YIELD nodeId, communityId
MATCH (u:User)
WHERE id(u) = nodeId
MATCH (u)-[r:RATED]->(m:Movie)-[:HAS_GENRE]->(g:Genre)
WHERE r.rating >= 4
WITH
  communityId,
  g.name AS genre,
  count(*) AS genreCount
ORDER BY communityId, genreCount DESC
WITH
  communityId,
  collect({genre: genre, count: genreCount})[0..3] AS topGenres
RETURN
  communityId,
  topGenres
ORDER BY communityId
LIMIT 10;

// 5.3 shortest path

MATCH (u1:User)-[sim:SIMILAR]->(u2:User)
RETURN
  u1.userId AS user1,
  u2.userId AS user2,
  sim.weight AS weight
ORDER BY sim.weight DESC
LIMIT 10;

CALL gds.graph.project(
  'userGraph',
  'User',
  'SIMILAR',
  {
    relationshipProperties: ['weight'],
    memory: '2GB'
  }
)
YIELD graphName, nodeCount, relationshipCount
RETURN graphName, nodeCount, relationshipCount;

MATCH (source:User {userId: 424})
MATCH (target:User {userId: 1015})
CALL gds.shortestPath.dijkstra.stream('userGraph', {
  sourceNode: id(source),
  targetNode: id(target),
  relationshipWeightProperty: 'weight'
})
YIELD totalCost, nodeIds
RETURN
  totalCost,
  [nodeId IN nodeIds | gds.util.asNode(nodeId).userId] AS userPath,
  size(nodeIds) - 1 AS pathLength;