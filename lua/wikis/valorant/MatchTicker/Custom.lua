---
-- @Liquipedia
-- page=Module:MatchTicker/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local MatchTicker = Lua.import('Module:MatchTicker')

---@class ValorantMatchTicker: MatchTicker
---@operator call(table): ValorantMatchTicker
local CustomMatchTicker = Class.new(MatchTicker)

---@param match table
---@return table[]
function CustomMatchTicker:expandGamesOfMatch(match)
	if (match.match2bracketdata or {}).matchpage then
		return {match}
	end
	return MatchTicker.expandGamesOfMatch(self, match)
end

---Entry point for display on the main page
---@param frame Frame|table|nil
---@return Html
function CustomMatchTicker.mainPage(frame)
	local args = Arguments.getArgs(frame)
	return CustomMatchTicker(args):query():create()
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
		return CustomMatchTicker(Table.merge(args, {ongoing = true, upcoming = true})):query():create():addClass('new-match-style')
	elseif args.type == 'recent' then
		return CustomMatchTicker(Table.merge(args, {recent = true})):query():create():addClass('new-match-style')
	end
end

---Entry point for display on player pages
---Upcoming and ongoing matches are now automatically displayed via the entity match ticker
---@param frame Frame|table|nil
---@return Html
function CustomMatchTicker.player(frame)
	local args = Arguments.getArgs(frame)
	args.player = args.player or mw.title.getCurrentTitle().text
	return CustomMatchTicker.recent(args)
end

---Displays recent matches for a player or team.
---@param args table
---@param matches {recent: table?}?
---@return Html
function CustomMatchTicker.recent(args, matches)
	matches = matches or {}

	--adjusting args
	args.infoboxClass = Logic.nilOr(Logic.readBoolOrNil(args.infoboxClass), true)
	args.recent = true
	args.limit = args.limit or args.recentLimit or 5

	return CustomMatchTicker(args):query(matches.recent):create(
		CustomMatchTicker.DisplayComponents.Header('Recent Matches')
	)
end

---@deprecated Use CustomMatchTicker.recent() instead. This function only displays recent matches.
---@param args table
---@param matches {recent: table?}?
---@return Html
function CustomMatchTicker.participant(args, matches)
	return CustomMatchTicker.recent(args, matches)
end

return CustomMatchTicker
