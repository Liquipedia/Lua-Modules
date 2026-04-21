---
-- @Liquipedia
-- page=Module:TeamPlayerMatches
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Info = Lua.import('Module:Info')
local Logic = Lua.import('Module:Logic')
local MatchTable = Lua.import('Module:MatchTable/Custom')
local MatchTicker = Lua.import('Module:MatchTicker')
local MatchTickerDisplay = Lua.import('Module:MatchTicker/DisplayComponents/Entity')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local TeamPlayerMatches = {}

function TeamPlayerMatches.run(frame)
	local args = Arguments.getArgs(frame)

	return HtmlWidgets.Fragment{
		children = {
			TeamPlayerMatches._matchTicker(args.team),
			HtmlWidgets.H3{children = 'Recent Matches'},
			MatchTable.results{
				tableMode = 'playersOfTeam',
				overallStats = false,
				team = args.team,
				limit = 20,
			}
		}
	}
end

function TeamPlayerMatches._matchTicker(team)
	if Info.config.match2.status == 0 then
		return nil
	end

	local result = Logic.tryCatch(
		function()
			local matchTicker = MatchTicker{
				playerTeam = team,
				limit = 5,
				upcoming = true,
				ongoing = true,
				hideTournament = false,
			}
			matchTicker:query()
			return matchTicker
		end,
		function()
			return nil
		end
	)

	if not result or not result.matches or #result.matches == 0 then
		return nil
	end

	return MatchTickerDisplay.Container{
		config = result.config,
		matches = result.matches,
	}:create()
end

return TeamPlayerMatches
