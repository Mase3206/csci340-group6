BEGIN;

-- Cells will be a view (defined later)


CREATE TABLE pawn_types (
    type_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    class_name varchar(20) NOT NULL,
    subclass_name varchar(20) NOT NULL,
    body_mass int,
    resource_amounts jsonb NOT NULL DEFAULT '{}'::jsonb,
    speed int,
    base_damage int,
    armor int
);


CREATE TABLE factions (
    faction_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    faction_name varchar(50) NOT NULL,
    icon text, -- base64
    is_hidden boolean NOT NULL DEFAULT false
);

-- Many-to-Many - Faction alliances
-- 'left' and 'right' are used, because alliances are reciprocal
CREATE TABLE faction_alliances (
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
CREATE TABLE faction_enemies (
    left_enemy bigint
        REFERENCES factions(faction_id)
        ON DELETE CASCADE,
    right_enemy bigint
        REFERENCES factions(faction_id)
        ON DELETE CASCADE,
    PRIMARY KEY (left_enemy, right_enemy)
);

-- Many-to-Many - a Faction's allowed PawnTypes
CREATE TABLE faction_allowed_pawn_types (
    faction_id bigint NOT NULL,
    pawn_type_id bigint NOT NULL,
    PRIMARY KEY (faction_id, pawn_type_id)
);


CREATE TABLE save_games (
    save_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    save_progress numeric(5, 2)
);


CREATE TABLE tiles (
    tile_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    save_id bigint NOT NULL
        REFERENCES save_games(save_id)
            ON DELETE CASCADE,
    Q int NOT NULL,
    R int NOT NULL,
    S int NOT NULL,
    biome varchar(16) NOT NULL,
    temp_min int NOT NULL,
    temp_max int NOT NULL,

    owned_by bigint
        REFERENCES factions(faction_id)
        ON DELETE CASCADE
        DEFAULT NULL,

    UNIQUE (save_id, Q, R, S)
);


CREATE TABLE pawns (
    pawn_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- relationships
    member_of bigint  -- faction membership
        REFERENCES factions(faction_id)
        ON DELETE SET NULL,
    pawn_type bigint NOT NULL
        REFERENCES pawn_types(type_id)
        ON DELETE RESTRICT,
    location_tile_id bigint
        REFERENCES tiles(tile_id)
        ON DELETE RESTRICT,
    location_cell_x int,
    location_cell_y int,

    -- attributes
    hunger int NOT NULL
        DEFAULT 100
        CHECK (hunger BETWEEN 0 AND 100),
    sleep int NOT NULL
        DEFAULT 100
        CHECK (hunger BETWEEN 0 AND 100),
    mood int NOT NULL
        DEFAULT 100
        CHECK (hunger BETWEEN 0 AND 100),
    work_speed real NOT NULL DEFAULT 1,  -- float multiple
    other_traits jsonb NOT NULL DEFAULT '{}'::jsonb,

    -- Key: effect name
    -- Value: object containing a strength multiplier and the remaining duration (in seconds)
    active_effects jsonb NOT NULL DEFAULT '{}'::jsonb
    -- example: bleeding, slowness, blindness, etc.
    -- { "bleeding": { "strength": 5, "remaining_duration": 10 }
);


CREATE TABLE buildings (
    building_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    name varchar(40) NOT NULL,

    -- keys: building material
    -- values: required qty
    -- If empty, the building has no cost.
    items_required jsonb NOT NULL DEFAULT '{}'::jsonb,

    -- time it takes to build, in seconds (pawns have work speed)
    time_to_build int NOT NULL DEFAULT 0,

    health int NOT NULL,
    damage int NOT NULL,

    -- used by the engine to determine what the building can do
    -- ex: "bed" gives a pawn somewhere to sleep
    type varchar(20) NOT NULL,

    attributes jsonb NOT NULL DEFAULT '{}'::jsonb,

    -- Relationships
    owned_by bigint
        REFERENCES factions(faction_id)
        ON DELETE SET NULL
        DEFAULT NULL
);

-- Many-to-Many
--     the Cell(s) which a Building occupies
--     but also the Building(s) which occupy a Cell
CREATE TABLE building_cells (
    location_tile_id bigint
        REFERENCES tiles(tile_id)
        ON DELETE RESTRICT,
    location_cell_x int,
    location_cell_y int,
    building_id bigint
        REFERENCES buildings(building_id)
        ON DELETE RESTRICT,
    PRIMARY KEY (location_tile_id, location_cell_x, location_cell_y, building_id)
);


CREATE TABLE items (
    item_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    name varchar(30) NOT NULL,
    weight int NOT NULL,
    value int NOT NULL,
    attributes jsonb NOT NULL DEFAULT '{}'::jsonb,

    -- LOCATION
    -- held by player
    held_by bigint
        REFERENCES pawns(pawn_id)
        ON DELETE SET NULL
        DEFAULT NULL,

    -- on cell
    location_tile_id bigint
        REFERENCES tiles(tile_id)
        ON DELETE SET NULL
        DEFAULT NULL,
    location_cell_x int DEFAULT NULL,
    location_cell_y int DEFAULT NULL,

    -- in a building
    contained_within bigint
        REFERENCES buildings(building_id)
        ON DELETE SET NULL
        DEFAULT NULL,

    -- CONSTRAINTS

    -- If on a cell, the tile_id and (x,y) coordinates must not be null
    CONSTRAINT items_require_tileid_xy_for_cell_location CHECK (
        (location_tile_id IS NULL and location_cell_x IS NULL and location_cell_y IS NULL)
        or (location_tile_id IS NOT NULL and location_cell_x IS NOT NULL and location_cell_y IS NOT NULL)
    ),

    -- An item can be held by a player (or in a player's inventory), on a tile, or in a building.
    CONSTRAINT items_mutually_exclusive_location CHECK (
        (
            held_by IS NOT NULL
            and location_tile_id IS NULL and location_cell_x IS NULL and location_cell_y IS NULL
            and contained_within IS NULL
        ) OR (
            held_by IS NULL
            and location_tile_id IS NOT NULL and location_cell_x IS NOT NULL and location_cell_y IS NOT NULL
            and contained_within IS NULL
        ) OR (
            held_by IS NULL
            and location_tile_id IS NULL and location_cell_x IS NULL and location_cell_y IS NULL
            and contained_within IS NOT NULL
        )
    )
);


-- This view was written with the assistance of GitHub Copilot.
CREATE OR REPLACE VIEW cells AS
--- Grab all the occupied cells
WITH occupied_locations AS (
    SELECT location_tile_id AS tile_id,
           location_cell_x AS cell_x,
           location_cell_y AS cell_y
    FROM pawns
    WHERE location_tile_id IS NOT NULL
      AND location_cell_x IS NOT NULL
      AND location_cell_y IS NOT NULL

    UNION

    SELECT location_tile_id,
           location_cell_x,
           location_cell_y
    FROM building_cells

    UNION

    SELECT location_tile_id,
           location_cell_x,
           location_cell_y
    FROM items
    WHERE location_tile_id IS NOT NULL
      AND location_cell_x IS NOT NULL
      AND location_cell_y IS NOT NULL
)
--- For each occupied cell, grab the pawns, buildings, and items which occupy it
--- and put each of them in arrays. (see below for example)
SELECT
    occupied.tile_id,
    occupied.cell_x,
    occupied.cell_y,
    COALESCE(array_agg(DISTINCT pawn.pawn_id)
             FILTER (WHERE pawn.pawn_id IS NOT NULL), ARRAY[]::bigint[]) AS pawn_ids,
    COALESCE(array_agg(DISTINCT building.building_id)
             FILTER (WHERE building.building_id IS NOT NULL), ARRAY[]::bigint[]) AS building_ids,
    COALESCE(array_agg(DISTINCT item.item_id)
             FILTER (WHERE item.item_id IS NOT NULL), ARRAY[]::bigint[]) AS item_ids,
    COUNT(DISTINCT pawn.pawn_id) AS pawn_count,
    COUNT(DISTINCT building.building_id) AS building_count,
    COUNT(DISTINCT item.item_id) AS item_count
FROM occupied_locations AS occupied
--- Using left join, as null values (aka. rows without a match) are expected to exist.
LEFT JOIN pawns AS pawn
    ON pawn.location_tile_id = occupied.tile_id
   AND pawn.location_cell_x = occupied.cell_x
   AND pawn.location_cell_y = occupied.cell_y
LEFT JOIN building_cells AS building
    ON building.location_tile_id = occupied.tile_id
   AND building.location_cell_x = occupied.cell_x
   AND building.location_cell_y = occupied.cell_y
LEFT JOIN items AS item
    ON item.location_tile_id = occupied.tile_id
   AND item.location_cell_x = occupied.cell_x
   AND item.location_cell_y = occupied.cell_y
GROUP BY occupied.tile_id, occupied.cell_x, occupied.cell_y;

-- View example:
-- Assuming the following IDs and locations exist:
--
-- | tile_id | cell_x | cell_y | pawn_ids  | building_ids | item_ids        | pawn_count | building_count | item_count |
-- | ------- | ------:| ------:| --------- | ------------ | --------------- | ----------:| --------------:| ----------:|
-- | 1       | 2      | 3      | `{}`      | `{}`         | `{101,102}`     | 0          | 0              | 2          |
-- | 1       | 4      | 1      | `{12}`    | `{}`         | `{}`            | 1          | 0              | 0          |
-- | 2       | 0      | 2      | `{}`      | `{20}`       | `{103}`         | 0          | 1              | 1          |
-- | 2       | 1      | 2      | `{12,15}` | `{20}`       | `{}`            | 2          | 1              | 0          |
-- | 3       | -2     | 4      | `{}`      | `{21,22}`    | `{104,105,106}` | 0          | 2              | 3          |
--
-- The arrays are PostgreSQL arrays. Empty cells, held items, and items contained inside buildings do not appear in this view.

COMMIT;