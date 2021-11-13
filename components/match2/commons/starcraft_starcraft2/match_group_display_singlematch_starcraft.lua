---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/SingleMatch/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local SingleMatchDisplay = Lua.import('Module:MatchGroup/Display/SingleMatch', {requireDevIfEnabled = true})
local StarcraftMatchSummary = Lua.import('Module:MatchSummary/Starcraft', {requireDevIfEnabled = true})

local StarcraftSingleMatchDisplay = {propTypes = {}}

function StarcraftSingleMatchDisplay.SingleMatchContainer(props)
	return SingleMatchDisplay.SingleMatch({
		match = props.match,
		config = Table.merge(props.config, {
			MatchSummaryContainer = StarcraftMatchSummary.MatchSummaryContainer,
		})
	})
end

return StarcraftSingleMatchDisplay
