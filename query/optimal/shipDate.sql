-- preparation agregation table
CREATE TABLE agregated_rev
(
    l_orderkey_max  BIGINT,
    region     CHAR(25),
    month_stat VARCHAR(10),
    sup_key    INT,
    revenue    DECIMAL(12, 4),
    PRIMARY KEY (region, month_stat, sup_key)
);

INSERT INTO agregated_rev
WITH li AS (
    SELECT l_orderkey, l_suppkey, l_extendedprice*(1 - l_discount) AS rev, l_shipdate
    FROM lineitem FORCE INDEX (lineitem_l_shipdate_index)
    WHERE l_shipdate BETWEEN '1993-01-01' AND '1997-12-31'
)
SELECT
    MAX(l_orderkey) as l_orderkey_max,
    r.r_name AS region,
    DATE_FORMAT(li.l_shipdate, '%Y-%m-01') AS month,
    s.s_suppkey,
    SUM(li.rev) AS revenue
FROM li
         JOIN supplier s ON s.s_suppkey = li.l_suppkey
         JOIN nation n ON n.n_nationkey = s.s_nationkey
         JOIN region r ON r.r_regionkey = n.n_regionkey
GROUP BY region, month, s.s_suppkey;

-- preparation done (1m 37s)

-- execution of both queries will take less time
INSERT INTO agregated_rev
WITH max AS (
    SELECT MAX(l_orderkey_max) as order_key FROM agregated_rev
)
SELECT
    MAX(l_orderkey) as l_orderkey_max,
    r.r_name AS region,
    DATE_FORMAT(li.l_shipdate, '%Y-%m-01') AS month,
    s.s_suppkey,
    SUM(l_extendedprice*(1 - l_discount)) AS revenue
FROM lineitem li
    JOIN supplier s ON s.s_suppkey = li.l_suppkey
    JOIN nation n ON n.n_nationkey = s.s_nationkey
    JOIN region r ON r.r_regionkey = n.n_regionkey
JOIN max
WHERE li.l_orderkey > max.order_key
GROUP BY region, month, s.s_suppkey
ON DUPLICATE KEY UPDATE
     revenue = revenue + VALUES(revenue);

SELECT *
FROM agregated_rev
WHERE revenue >= 5000
ORDER BY revenue DESC LIMIT 100;

-- execution time is less than 1 MS. on huge records amount appearance it can spend more time once.