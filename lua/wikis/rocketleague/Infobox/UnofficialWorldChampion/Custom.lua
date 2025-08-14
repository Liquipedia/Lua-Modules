---
-- @Liquipedia
-- page=Module:Infobox/UnofficialWorldChampion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')

local UnofficialWorldChampion = Lua.import('Module:Infobox/UnofficialWorldChampion')

---@class RocketLeagueUnofficialWorldChampionInfobox: UnofficialWorldChampionInfobox
local CustomUnofficialWorldChampion = Class.new(UnofficialWorldChampion)

---@param frame Frame
---@return Html
function CustomUnofficialWorldChampion.run(frame)
	local unofficialWorldChampion = CustomUnofficialWorldChampion(frame)
	return unofficialWorldChampion:createInfobox()
end

---@param args table
function CustomUnofficialWorldChampion:setLpdbData(args)
	if not Namespace.isMain() or not Logic.readBool(args.storeLPDB) then
		return
	end

	mw.ext.LiquipediaDB.lpdb_datapoint(
		'unofficial_world_champion',
		{
			type = 'Unofficial World Champion',
			name = args.currentChampOpponent.template
		}
	)
end

return CustomUnofficialWorldChampion
