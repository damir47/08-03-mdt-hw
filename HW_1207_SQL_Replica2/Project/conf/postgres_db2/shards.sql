CREATE TABLE books
(
    id bigint not null,
    category_id int not null,
    author character varying not null,
    title character varying not null,
    year int not null,
    CONSTRAINT year_check CHECK (year > 1999)
);

CREATE INDEX year_idx ON books USING btree(year);


CREATE TABLE store
(
   store_id SERIAL PRIMARY KEY,
   address_id smallint NOT NULL,
   last_update timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
   CONSTRAINT store_id_CHECK CHECK (store_id >5)
);