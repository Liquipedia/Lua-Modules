---
-- @Liquipedia
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Table = require('Module:Table')

---@class WarcraftBrktsWikiSpecific: BrktsWikiSpecific
local WikiSpecific = Table.copy(require('Module:Brkts/WikiSpecific/Base'))

---Determine if a match has details that should be displayed via popup
---@param match table
---@return boolean
function WikiSpecific.matchHasDetails(match)
	return match.dateIsExact
		or match.vod
		or not Table.isEmpty(match.links)
		or match.comment
		or match.casters
		or 0 < #match.vetoes
		or Array.any(match.games, function(game)
			return game.map and game.map ~= 'TBD'
				or game.winner
		end)
end

return WikiSpecific
