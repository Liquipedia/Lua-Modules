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

local CURRENT_PAGE = mw.title.getCurrentTitle().text

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

---Entry point for display on player pages
---@param frame Frame|table|nil
---@return Html
function CustomMatchTicker.player(frame)
	local args = Arguments.getArgs(frame)

	args.player = args.player or CURRENT_PAGE

	return CustomMatchTicker.participant(args)
end

---@deprecated Upcoming matches are now automatically displayed in the team infobox.
function CustomMatchTicker.team()
end

---Entry point for display on any participant-type page
---@param args table
---@param matches {ongoing: table?, upcoming: table?, recent: table?}?
---@return Html
function CustomMatchTicker.participant(args, matches)
	matches = matches or {}

	--adjusting args
	args.infoboxClass = Logic.nilOr(Logic.readBoolOrNil(args.infoboxClass), true)

	if Logic.readBool(args.short) then
		args.upcoming = true
		args.ongoing = true
		args.recent = false
		args.limit = args.limit or 5
		return MatchTicker(args):query():create(
			MatchTicker.DisplayComponents.Header('Upcoming Matches')
		)
	end

	return mw.html.create()
		:node(MatchTicker(Table.merge(args, {
			limit = args.ongoingLimit or 5, ongoing = true
		})):query(matches.ongoing):create(MatchTicker.DisplayComponents.Header('Ongoing Matches')))
		:node(MatchTicker(Table.merge(args, {
			limit = args.upcomingLimit or 3, upcoming = true
		})):query(matches.upcoming):create(MatchTicker.DisplayComponents.Header('Upcoming Matches')))
		:node(MatchTicker(Table.merge(args, {
			limit = args.recentLimit or 5, recent = true
		})):query(matches.recent):create(MatchTicker.DisplayComponents.Header('Recent Matches')))
end

return CustomMatchTicker
