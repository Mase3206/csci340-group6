-- Run with psql after loading the schema and existing pawn types.
-- Each run adds one new scenario. The table scripts share this transaction.

\set ON_ERROR_STOP on

BEGIN;
\ir seed/factions.sql
\ir seed/faction_alliances.sql
\ir seed/faction_enemies.sql
\ir seed/faction_allowed_pawn_types.sql
\ir seed/save_games.sql
\ir seed/tiles.sql
\ir seed/buildings.sql
\ir seed/building_cells.sql
\ir seed/pawns.sql
\ir seed/items.sql
COMMIT;
