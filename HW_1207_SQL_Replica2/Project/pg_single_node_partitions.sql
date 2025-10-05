CREATE TABLE users (
    id uuid PRIMARY KEY,
    username character varying NOT NULL,
    passwd character varying NOT NULL
) PARTITION BY HASH (id);

/* PARTITION 0 */
CREATE TABLE users_1 PARTITION OF users
    FOR VALUES WITH (MODULUS 3, REMAINDER 0);

/* PARTITION 1 */  
CREATE TABLE users_2 PARTITION OF users
    FOR VALUES WITH (MODULUS 3, REMAINDER 1);

/* PARTITION 2 */
CREATE TABLE users_3 PARTITION OF users
    FOR VALUES WITH (MODULUS 3, REMAINDER 2);


INSERT INTO users (id, username, passwd) VALUES
    (gen_random_uuid(), 'user1', 'password1'),
    (gen_random_uuid(), 'user2', 'password2'),
    (gen_random_uuid(), 'user3', 'password3'),
    (gen_random_uuid(), 'user4', 'password4'),
    (gen_random_uuid(), 'user5', 'password5'),
    (gen_random_uuid(), 'user6', 'password6'),
    (gen_random_uuid(), 'user7', 'password7'),
    (gen_random_uuid(), 'user8', 'password8'),
    (gen_random_uuid(), 'user9', 'password9'),
    (gen_random_uuid(), 'user10', 'password10');