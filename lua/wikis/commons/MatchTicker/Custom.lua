---
-- @Liquipedia
-- page=Module:MatchTicker/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local MatchTicker = Lua.import('Module:MatchTicker')

local CustomMatchTicker = {}

---@deprecated Upcoming matches are now automatically displayed in the league infobox.
---Remove this template invocation from the page.
function CustomMatchTicker.tournament()
end

---Entry point for display on the main page
---@param frame Frame|table|nil
---@return Html
function CustomMatchTicker.mainPage(frame)
	local args = Arguments.getArgs(frame)
	return MatchTicker(args):query():create()
end

---Entry point for display on the main page with the new style
---@param frame Frame|table|nil
---@return Html?
function CustomMatchTicker.newMainPage(frame)
	local args = Arguments.getArgs(frame)
	args.newStyle = true

	args.tiers = args['filterbuttons-liquipediatier']
	if args.tiers == 'curated' then
		args.tiers = nil
		args.featuredOnly = true
	end

	args.tiertypes = args['filterbuttons-liquipediatiertype']
	args.regions = args['filterbuttons-region']
	args.games = args['filterbuttons-game']

	if args.type == 'upcoming' then
		return MatchTicker(Table.merge(args, {ongoing = true, upcoming = true})):query():create():addClass('new-match-style')
	elseif args.type == 'recent' then
		return MatchTicker(Table.merge(args, {recent = true})):query():create():addClass('new-match-style')
	end
end

---@deprecated Upcoming matches are now automatically displayed in the player infobox.
function CustomMatchTicker.player()
end

---@deprecated Upcoming matches are now automatically displayed in the team infobox.
function CustomMatchTicker.team()
end

---Entry point for displaying recent matches on player/team pages.
---NOTE: Upcoming and ongoing matches are now automatically displayed via the entity match ticker
---in player/team infoboxes. This function should ONLY be used for displaying recent matches.
---
---@param args table
---@param matches {recent: table?}?
---@return Html
function CustomMatchTicker.participant(args, matches)
	matches = matches or {}

	--adjusting args
	args.infoboxClass = Logic.nilOr(Logic.readBoolOrNil(args.infoboxClass), true)
	args.recent = true
	args.limit = args.limit or args.recentLimit or 5

	return MatchTicker(args):query(matches.recent):create(
		MatchTicker.DisplayComponents.Header('Recent Matches')
	)
end

return CustomMatchTicker
