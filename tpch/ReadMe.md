# windows prepare db
```shell
git clone 

$OUT = "Z:\workspace\devclub-high-load-db\tpch\tpch-dbgen\out"
mkdir $OUT -Force | Out-Null

docker run --rm `
  -v "${OUT}:/out" `
  duckdb/duckdb:latest `
  duckdb -c "INSTALL tpch; LOAD tpch;
      CALL dbgen(sf=10);
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
CREATE TABLE nation ( n_nationkey INT PRIMARY KEY, n_name CHAR(25), n_regionkey INT, n_comment VARCHAR(152) );
CREATE TABLE region ( r_regionkey INT PRIMARY KEY, r_name CHAR(25), r_comment VARCHAR(152) );
CREATE TABLE part   ( p_partkey INT PRIMARY KEY, p_name VARCHAR(55), p_mfgr CHAR(25), p_brand CHAR(10), p_type VARCHAR(25), p_size INT, p_container CHAR(10), p_retailprice DECIMAL(12,2), p_comment VARCHAR(23) );
CREATE TABLE supplier ( s_suppkey INT PRIMARY KEY, s_name CHAR(25), s_address VARCHAR(40), s_nationkey INT, s_phone CHAR(15), s_acctbal DECIMAL(12,2), s_comment VARCHAR(101) );
CREATE TABLE partsupp ( ps_partkey INT, ps_suppkey INT, ps_availqty INT, ps_supplycost DECIMAL(12,2), ps_comment VARCHAR(199), PRIMARY KEY(ps_partkey, ps_suppkey) );
CREATE TABLE customer ( c_custkey INT PRIMARY KEY, c_name VARCHAR(25), c_address VARCHAR(40), c_nationkey INT, c_phone CHAR(15), c_acctbal DECIMAL(12,2), c_mktsegment CHAR(10), c_comment VARCHAR(117) );
CREATE TABLE orders   ( o_orderkey BIGINT PRIMARY KEY, o_custkey INT, o_orderstatus CHAR(1), o_totalprice DECIMAL(12,2), o_orderdate DATE, o_orderpriority CHAR(15), o_clerk CHAR(15), o_shippriority INT, o_comment VARCHAR(79) );
CREATE TABLE lineitem ( l_orderkey BIGINT, l_partkey INT, l_suppkey INT, l_linenumber INT,
l_quantity DECIMAL(12,2), l_extendedprice DECIMAL(12,2),
l_discount DECIMAL(12,2), l_tax DECIMAL(12,2),
l_returnflag CHAR(1), l_linestatus CHAR(1),
l_shipdate DATE, l_commitdate DATE, l_receiptdate DATE,
l_shipinstruct CHAR(25), l_shipmode CHAR(10), l_comment VARCHAR(44),
PRIMARY KEY(l_orderkey, l_linenumber) );

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