CREATE TABLE crc_test (
                          l_comment varchar(512),
                          l_comment_crc INT UNSIGNED AS (CRC32(l_comment)) STORED,
                          KEY idx_l_comment       (l_comment),
                          KEY idx_l_comment_crc   (l_comment_crc)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELIMITER //
CREATE PROCEDURE fill_crc_test(IN cnt INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= cnt DO
            INSERT INTO crc_test (l_comment)
            SELECT
                SHA2(RAND(), 512)
            FROM crc_test;
            SET i = i + 1;
        END WHILE;
END//
DELIMITER ;

INSERT INTO crc_test (l_comment)
SELECT CONCAT(SHA2(RAND(), 512));

CALL fill_crc_test(25);