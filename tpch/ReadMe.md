# windows prepare db (sf=10 will create db with size 10 GB instead of 1 GB records)
```shell
git clone 

$OUT = "Z:\workspace\devclub-high-load-db\tpch\tpch-dbgen\out"
mkdir $OUT -Force | Out-Null

docker run --rm `
  -v "${OUT}:/out" `
  duckdb/duckdb:latest `
  duckdb -c "INSTALL tpch; LOAD tpch;
      CALL dbgen(sf=1);
      COPY (SELECT * FROM nation)   TO '/out/nation.tbl'   WITH (HEADER false, DELIMITER '|');
      COPY (SELECT * FROM region)   TO '/out/region.tbl'   WITH (HEADER false, DELIMITER '|');
      COPY (SELECT * FROM part)     TO '/out/part.tbl'     WITH (HEADER false, DELIMITER '|');
      COPY (SELECT * FROM supplier) TO '/out/supplier.tbl' WITH (HEADER false, DELIMITER '|');
      COPY (SELECT * FROM partsupp) TO '/out/partsupp.tbl' WITH (HEADER false, DELIMITER '|');
      COPY (SELECT * FROM customer) TO '/out/customer.tbl' WITH (HEADER false, DELIMITER '|');
      COPY (SELECT * FROM orders)   TO '/out/orders.tbl'   WITH (HEADER false, DELIMITER '|');
      COPY (SELECT * FROM lineitem) TO '/out/lineitem.tbl' WITH (HEADER false, DELIMITER '|');"
```

# create schemas
```sql

create schema

    SET sql_log_bin=0;
SET autocommit=0;
SET foreign_key_checks=0;

-- TPC-H tables (MySQL-friendly types)
CREATE TABLE region (
                        r_regionkey INT PRIMARY KEY,
                        r_name CHAR(25),
                        r_comment VARCHAR(152)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Nation -> Region
CREATE TABLE nation (
                        n_nationkey INT PRIMARY KEY,
                        n_name CHAR(25),
                        n_regionkey INT NOT NULL,
                        n_comment VARCHAR(152),
                        KEY idx_nation_region (n_regionkey),
                        CONSTRAINT fk_nation_region
                            FOREIGN KEY (n_regionkey) REFERENCES region(r_regionkey)
                                ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Part (parent of PartSupp + LineItem)
CREATE TABLE part (
                      p_partkey INT PRIMARY KEY,
                      p_name VARCHAR(55),
                      p_mfgr CHAR(25),
                      p_brand CHAR(10),
                      p_type VARCHAR(25),
                      p_size INT,
                      p_container CHAR(10),
                      p_retailprice DECIMAL(12,2),
                      p_comment VARCHAR(23)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Supplier -> Nation
CREATE TABLE supplier (
                          s_suppkey INT PRIMARY KEY,
                          s_name CHAR(25),
                          s_address VARCHAR(40),
                          s_nationkey INT NOT NULL,
                          s_phone CHAR(15),
                          s_acctbal DECIMAL(12,2),
                          s_comment VARCHAR(101),
                          KEY idx_supplier_nation (s_nationkey),
                          CONSTRAINT fk_supplier_nation
                              FOREIGN KEY (s_nationkey) REFERENCES nation(n_nationkey)
                                  ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Customer -> Nation
CREATE TABLE customer (
                          c_custkey INT PRIMARY KEY,
                          c_name VARCHAR(25),
                          c_address VARCHAR(40),
                          c_nationkey INT NOT NULL,
                          c_phone CHAR(15),
                          c_acctbal DECIMAL(12,2),
                          c_mktsegment CHAR(10),
                          c_comment VARCHAR(117),
                          KEY idx_customer_nation (c_nationkey),
                          CONSTRAINT fk_customer_nation
                              FOREIGN KEY (c_nationkey) REFERENCES nation(n_nationkey)
                                  ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Orders -> Customer
CREATE TABLE orders (
                        o_orderkey BIGINT PRIMARY KEY,
                        o_custkey INT NOT NULL,
                        o_orderstatus CHAR(1),
                        o_totalprice DECIMAL(12,2),
                        o_orderdate DATE,
                        o_orderpriority CHAR(15),
                        o_clerk CHAR(15),
                        o_shippriority INT,
                        o_comment VARCHAR(79),
                        KEY idx_orders_customer (o_custkey),
                        CONSTRAINT fk_orders_customer
                            FOREIGN KEY (o_custkey) REFERENCES customer(c_custkey)
                                ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- PartSupp -> Part + Supplier (composite PK)
CREATE TABLE partsupp (
                          ps_partkey INT NOT NULL,
                          ps_suppkey INT NOT NULL,
                          ps_availqty INT,
                          ps_supplycost DECIMAL(12,2),
                          ps_comment VARCHAR(199),
                          PRIMARY KEY (ps_partkey, ps_suppkey),
                          KEY idx_ps_part (ps_partkey),
                          KEY idx_ps_supp (ps_suppkey),
                          CONSTRAINT fk_partsupp_part
                              FOREIGN KEY (ps_partkey) REFERENCES part(p_partkey)
                                  ON DELETE RESTRICT ON UPDATE CASCADE,
                          CONSTRAINT fk_partsupp_supplier
                              FOREIGN KEY (ps_suppkey) REFERENCES supplier(s_suppkey)
                                  ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- LineItem -> Orders + Part + Supplier + Partsupp (composite)
CREATE TABLE lineitem (
                          l_orderkey BIGINT NOT NULL,
                          l_partkey INT NOT NULL,
                          l_suppkey INT NOT NULL,
                          l_linenumber INT NOT NULL,
                          l_quantity DECIMAL(12,2),
                          l_extendedprice DECIMAL(12,2),
                          l_discount DECIMAL(12,2),
                          l_tax DECIMAL(12,2),
                          l_returnflag CHAR(1),
                          l_linestatus CHAR(1),
                          l_shipdate DATE,
                          l_commitdate DATE,
                          l_receiptdate DATE,
                          l_shipinstruct CHAR(25),
                          l_shipmode CHAR(10),
                          l_comment varchar(512),
                          l_comment_crc INT UNSIGNED AS (CRC32(l_comment)) STORED,
                          PRIMARY KEY (l_orderkey, l_linenumber),
                          KEY idx_l_comment       (l_comment),
                          KEY idx_l_comment_crc   (l_comment_crc),
                          KEY idx_li_order (l_orderkey),
                          KEY idx_li_part (l_partkey),
                          KEY idx_li_supp (l_suppkey),
                          KEY idx_li_part_supp (l_partkey, l_suppkey),

                          CONSTRAINT fk_lineitem_orders
                              FOREIGN KEY (l_orderkey) REFERENCES orders(o_orderkey)
                                  ON DELETE RESTRICT ON UPDATE CASCADE,
                          CONSTRAINT fk_lineitem_part
                              FOREIGN KEY (l_partkey) REFERENCES part(p_partkey)
                                  ON DELETE RESTRICT ON UPDATE CASCADE,
                          CONSTRAINT fk_lineitem_supplier
                              FOREIGN KEY (l_suppkey) REFERENCES supplier(s_suppkey)
                                  ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Enforce that (part,supplier) pair exists in partsupp
                          CONSTRAINT fk_lineitem_partsupp
                              FOREIGN KEY (l_partkey, l_suppkey)
                                  REFERENCES partsupp(ps_partkey, ps_suppkey)
                                  ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;
```

# do data import from out folder
```sql
SET sql_log_bin=0; SET autocommit=0; SET foreign_key_checks=0;

LOAD DATA LOCAL INFILE 'out/nation.tbl'   INTO TABLE nation   FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'out/region.tbl'   INTO TABLE region   FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'out/part.tbl'     INTO TABLE part     FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'out/supplier.tbl' INTO TABLE supplier FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'out/partsupp.tbl' INTO TABLE partsupp FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'out/customer.tbl' INTO TABLE customer FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'out/orders.tbl'   INTO TABLE orders   FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'out/lineitem.tbl' INTO TABLE lineitem FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n';

COMMIT;
SET foreign_key_checks=1;
```