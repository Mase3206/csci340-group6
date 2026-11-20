BEGIN;
-- ROLLBACK;
/*
    faction_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    faction_name varchar(50) NOT NULL,
    icon text, -- base64
    is_hidden boolean NOT NULL DEFAULT false
*/
INSERT INTO factions (faction_name, icon, is_hidden)
VALUES
    ('player', 'house', FALSE),
    ('hidden', NULL, TRUE),
    ('tribal_01', 'hut', FALSE),
    ('tribal_02', 'hut_02', FALSE),
    ('industrial_01', 'gear', FALSE),
    ('industrial_02','some_icon_1', FALSE),
    ('spacer_01','some_icon_2', FALSE),
    ('spacer_02','some_icon_3', FALSE),
    ('The yarrs','skull and crossbones', FALSE),
    ('wannabe pirates','toy boat', FALSE),
    ('mechanoid', 'robot', FALSE),
    ('insect_hive','bug', FALSE)

RETURNING faction_id, faction_name;

COMMIT;
