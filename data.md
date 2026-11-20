pawn_types:
humanoid
animal
mechanoid (exclusive to mechanoid faction)
insectoid (exclusive to insectoid faction)

factions:
player
hidden
tribal_01
tribal_02
industrial_01
industrial_02
spacer_01
spacer_02
pirate_01
pirate_02
mechanoid (only mechanoids)
hive (only insectoids)

pirates will be hostile always, one of each {t, i, s} will be hostile and one will be either nuetral or friendly. hidden is neutral/ally with all

save_games:
make 1 save game

tiles:
make 5 x 5 tiles, for all hex coordinates in a radius of 5 from the origin
each faction gets 1 tile at random and it will own that tile. The player likewise starts on a random tile.

pawns:
player gets 3 pawns spawn on the player owned tile,
every faction (excepting mechanoid and insectoid) get one world pawn which is the "leader" for that faction. That pawn would exist on some tile owned by their respective faction

pawns start with full sleep, hunger, etc.

buildings:
each of the faction tiles gets a random configuration of houses, (the faction base spawns on the cell)
The player tile gets "ruins", which are owned by the hidden faction

items:
Every pawn starts with clothing items (pants and shirt), and "drop-pod" makes a set of weapons and raw material "spawn" on the player tile. 3 guns, wood, steel, components

attributes themselves just live in the item (with the assumption that the 'game engine' will handle it)

