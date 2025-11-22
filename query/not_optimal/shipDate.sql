EXPLAIN SELECT *
FROM (
         SELECT
             r.r_name AS region,
             DATE_FORMAT(li.l_shipdate, '%Y-%m-01') AS month,
             s.s_suppkey,
             SUM(l_extendedprice*(1 - l_discount)) AS revenue,
             RANK() OVER (
                 PARTITION BY r.r_name, DATE_FORMAT(li.l_shipdate, '%Y-%m-01')
                 ORDER BY SUM(l_extendedprice*(1 - l_discount)) DESC
                 ) AS rnk
         FROM lineitem li
                  JOIN supplier s ON s.s_suppkey = li.l_suppkey
                  JOIN nation n ON n.n_nationkey = s.s_nationkey
                  JOIN region r ON r.r_regionkey = n.n_regionkey
         WHERE l_shipdate BETWEEN '1993-01-01' AND '1997-12-31'
         GROUP BY region, month, s.s_suppkey
     ) t
WHERE t.rnk <= 5
ORDER BY region, month, revenue DESC;

-- execution can't reach finish. can optimize adding WITH.

EXPLAIN ANALYZE
WITH li AS (
    SELECT l_suppkey, l_extendedprice*(1 - l_discount) AS rev, l_shipdate
    FROM lineitem FORCE INDEX (lineitem_l_shipdate_index)
    WHERE l_shipdate BETWEEN '1993-01-01' AND '1997-12-31'
)
SELECT *
FROM (
         SELECT
             r.r_name AS region,
             DATE_FORMAT(li.l_shipdate, '%Y-%m-01') AS month,
             s.s_suppkey,
             SUM(li.rev) AS revenue
         FROM li
             JOIN supplier s ON s.s_suppkey = li.l_suppkey
             JOIN nation n ON n.n_nationkey = s.s_nationkey
             JOIN region r ON r.r_regionkey = n.n_regionkey
         GROUP BY region, month, s.s_suppkey
     ) t
WHERE t.revenue >= 5000
ORDER BY revenue DESC LIMIT 100;
-- execution time ~ 1m 4s

-- could add index >
create index lineitem_l_shipdate_index
    on lineitem (l_shipdate);
-- execution time ~ 0.5s