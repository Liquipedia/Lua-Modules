---
-- @Liquipedia
-- wiki=commons
-- page=Module:InfoboxPlacementStats/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	--this list holds the liquipediatiers which get included in the query and display
	--make sure that the TierDisplay templates exist for all of them
	--these values have to be strings and have to match the entries in the placement objects in lpdb
	tiers = { '1', '2', '3', },
	--this list holds (liquipedia)tiertypes that are to be excluded from the queries
	exclusionTypes = { 'Qualifier', },
}
