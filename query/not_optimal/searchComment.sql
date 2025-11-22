# SELECT SQL_NO_CACHE * FROM lineitem WHERE l_comment = @s;
EXPLAIN ANALYZE
SELECT SQL_NO_CACHE l_comment
FROM crc_test
WHERE l_comment = 'ede84332707e97bbf7625c79a5934bf0e6fa36b854826c4fef2d878e4e2286e7'
GROUP BY l_comment;
-- -> -> Group (no aggregates)  (cost=2.48 rows=1) (actual time=0.0471..0.0472 rows=1 loops=1)
-- -> Covering index lookup on crc_test using idx_l_comment (l_comment = 'ede84332707e97bbf7625c79a5934bf0e6fa36b854826c4fef2d878e4e2286e7')  (cost=1.56 rows=4) (actual time=0.0321..0.044 rows=4 loops=1)

