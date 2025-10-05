CREATE EXTENSION postgres_fdw;

/* SHARD 1 */
CREATE SERVER minidb_1_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'postgres_db1', port '5432', dbname 'minidb');

CREATE USER MAPPING FOR "postgres"
    SERVER minidb_1_server
    OPTIONS (user 'postgres', password 'postgres');

CREATE FOREIGN TABLE books_1
(
    id bigint not null,
    category_id int not null,
    author character varying not null,
    title character varying not null,
    year int not null
) SERVER minidb_1_server
  OPTIONS (schema_name 'public', table_name 'books');

CREATE FOREIGN TABLE store_1
(
   store_id SERIAL PRIMARY KEY,
   address_id smallint NOT NULL,
   last_update timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) SERVER minidb_1_server
  OPTIONS (schema_name 'public', table_name 'store');

/* SHARD 2 */
CREATE SERVER minidb_2_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'postgres_db2', port '5432', dbname 'minidb');

CREATE USER MAPPING FOR "postgres"
    SERVER minidb_2_server
    OPTIONS (user 'postgres', password 'postgres');

CREATE FOREIGN TABLE books_2
(
    id bigint not null,
    category_id int not null,
    author character varying not null,
    title character varying not null,
    year int not null
) SERVER minidb_2_server
  OPTIONS (schema_name 'public', table_name 'books');

CREATE FOREIGN TABLE store_2
(
   store_id SERIAL PRIMARY KEY,
   address_id smallint NOT NULL,
   last_update timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) SERVER minidb_2_server
  OPTIONS (schema_name 'public', table_name 'store');

CREATE VIEW books AS
SELECT *
FROM books_1
UNION ALL
SELECT *
FROM books_2;

CREATE VIEW store AS
SELECT *
FROM store_1
UNION ALL
SELECT *
FROM store_2;

CREATE RULE books_insert AS ON INSERT TO books
    DO INSTEAD NOTHING;
CREATE RULE books_update AS ON UPDATE TO books
    DO INSTEAD NOTHING;
CREATE RULE books_delete AS ON DELETE TO books
    DO INSTEAD NOTHING;

CREATE RULE books_insert AS ON INSERT TO store
    DO INSTEAD NOTHING;
CREATE RULE books_update AS ON UPDATE TO store
    DO INSTEAD NOTHING;
CREATE RULE books_delete AS ON DELETE TO store
    DO INSTEAD NOTHING;

CREATE RULE books_insert_to_1 AS ON INSERT TO books
    WHERE (year <= 1999)
    DO INSTEAD INSERT INTO books_1
               VALUES (NEW.*);

CREATE RULE books_insert_to_2 AS ON INSERT TO books
    WHERE (year > 1999)
    DO INSTEAD INSERT INTO books_2
               VALUES (NEW.*);

CREATE RULE store_insert_to_1 AS ON INSERT TO store
    WHERE (store_id <= 5)
    DO INSTEAD INSERT INTO store_1
               VALUES (NEW.*);

CREATE RULE store_insert_to_2 AS ON INSERT TO store
    WHERE (store_id > 5)
    DO INSTEAD INSERT INTO store_2
               VALUES (NEW.*);

