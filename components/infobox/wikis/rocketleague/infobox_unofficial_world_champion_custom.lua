---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Infobox/UnofficialWorldChampion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Json = require('Module:Json')
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
	unofficialWorldChampion:_setLpdbData()
	return unofficialWorldChampion:createInfobox()
end

function CustomUnofficialWorldChampion:_setLpdbData()
	if Namespace.isMain() and Logic.readBool(self.args.storeLPDB) then
		mw.ext.LiquipediaDB.lpdb_datapoint(
			'Unofficial World Champion',
			Json.stringifySubTables({
				type = 'Unofficial World Champion',
				name = self.args.currentChampOpponent.template
			})
		)
	end
end

return CustomUnofficialWorldChampion
