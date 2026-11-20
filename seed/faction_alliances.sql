BEGIN;
/*
CREATE TABLE IF NOT EXISTS faction_alliances (
    left_ally bigint
        REFERENCES factions(faction_id)
        ON DELETE CASCADE,
    right_ally bigint
        REFERENCES factions(faction_id)
        ON DELETE CASCADE,
    PRIMARY KEY (left_ally, right_ally)
);

-- Many-to-Many - Faction enemies
-- 'left' and 'right' are used, because conflicts are reciprocal
CREATE TABLE IF NOT EXISTS faction_enemies (
    left_enemy bigint
        REFERENCES factions(faction_id)
        ON DELETE CASCADE,
    right_enemy bigint
        REFERENCES factions(faction_id)
        ON DELETE CASCADE,
    PRIMARY KEY (left_enemy, right_enemy)
);
*/
INSERT INTO factions (faction_name, icon, is_hidden)
VALUES
    ()




RETURNING ;

COMMIT;
