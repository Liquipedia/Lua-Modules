---
-- @Liquipedia
-- wiki=arenaofvalor
-- page=Module:InfoboxPlacementStats/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	--this list holds the liquipediatiers which get included in the query and display
	--these values have to match the entries in the placement objects in lpdb
	tiers = { '1', '2', '3', '4', '5'},
	--this list holds (liquipedia)tiertypes that are to be excluded from the queries
	exclusionTypes = { 'Qualifier', },
}
