---
-- @Liquipedia
-- page=Module:Infobox/UnofficialWorldChampion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')

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
