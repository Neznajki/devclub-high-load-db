EXPLAIN ANALYZE
SELECT SQL_NO_CACHE l_comment
FROM crc_test
WHERE CRC32('ede84332707e97bbf7625c79a5934bf0e6fa36b854826c4fef2d878e4e2286e7') = l_comment_crc
  AND l_comment = 'ede84332707e97bbf7625c79a5934bf0e6fa36b854826c4fef2d878e4e2286e7'
GROUP BY l_comment_crc, l_comment;
-- -> Group (no aggregates)  (cost=2.04 rows=1) (actual time=0.122..0.122 rows=1 loops=1)
# -> Filter: ((crc_test.l_comment = 'ede84332707e97bbf7625c79a5934bf0e6fa36b854826c4fef2d878e4e2286e7') and (crc_test.l_comment_crc = <cache>(crc32('ede84332707e97bbf7625c79a5934bf0e6fa36b854826c4fef2d878e4e2286e7'))))  (cost=1.81 rows=1) (actual time=0.106..0.119 rows=4 loops=1)
#         -> Intersect rows sorted by row ID  (cost=1.81 rows=1) (actual time=0.101..0.112 rows=4 loops=1)
#             -> Index range scan on crc_test using idx_l_comment over (l_comment = 'ede84332707e97bbf7625c79a5934bf0e6fa36b854826c4fef2d878e4e2286e7')  (cost=0.29..1.16 rows=4) (actual time=0.0255..0.0337 rows=4 loops=1)
#             -> Index range scan on crc_test using idx_l_comment_crc over (l_comment_crc = 1850977942)  (cost=0.138..0.551 rows=4) (actual time=0.0742..0.0763 rows=4 loops=1)
