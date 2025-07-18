---
-- @Liquipedia
-- page=Module:MatchTicker/DisplayComponents/New
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local MatchCard = Lua.import('Module:Widget/Match/Card')

---@class NewMatchTickerMatch
---@operator call({config: MatchTickerConfig, match: table}): NewMatchTickerMatch
---@field config MatchTickerConfig
---@field match table
local Match = Class.new(
	function(self, args)
		self.config = args.config
		self.match = args.match
	end
)

---@return Html
function Match:create()
	return MatchCard{
		match = MatchGroupUtil.matchFromRecord(self.match),
		hideTournament = self.config.hideTournament,
		displayGameIcons = self.config.displayGameIcons,
		onlyHighlightOnValue = self.config.onlyHighlightOnValue,
	}
end

return {
	Match = Match,
}
