---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTicker/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local MatchTicker = Lua.import('Module:MatchTicker', {requireDevIfEnabled = true})

local CURRENT_PAGE = mw.title.getCurrentTitle().text

local CustomMatchTicker = {}

---Entry point for display on tournament pages
---@param frame Frame
---@return Html|string
function CustomMatchTicker.tournament(frame)
	local args = Arguments.getArgs(frame)

	--adjusting args
	args.upcoming = true
	args.ongoing = true
	args.recent = false
	args.tournament = args.tournament or args.tournament1 or args[1] or CURRENT_PAGE
	args.queryByParent = args.queryByParent or true
	args.showAllTbdMatches = args.showAllTbdMatches or true

	return MatchTicker(args):query():create(
		MatchTicker.DisplayComponents.Header('Upcoming matches')
	)
end

---Entry point for display on main page
---@param frame Frame
---@return Html|string
function CustomMatchTicker.mainPage(frame)
	local args = Arguments.getArgs(frame)
	return MatchTicker(args):query():create()
end

---Entry point for display on main page
---@param frame Frame
---@return Html
function CustomMatchTicker.player(frame)
	local args = Arguments.getArgs(frame)

	args.player = args.player or CURRENT_PAGE

	return CustomMatchTicker.participant(args)
end

---Entry point for display on main page
---@param frame Frame
---@return Html
function CustomMatchTicker.team(frame)
	local args = Arguments.getArgs(frame)

	args.team = args.team or CURRENT_PAGE

	return CustomMatchTicker.participant(args)
end

---Entry point for display on main page
---@param args table
---@param matches {ongoing: table?, upcoming: table?, recent: table?}?
---@return Html
function CustomMatchTicker.participant(args, matches)
	matches = matches or {}

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
