---
-- @Liquipedia
-- page=Module:MatchTicker/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Table = Lua.import('Module:Table')

local MatchTicker = Lua.import('Module:MatchTicker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local CustomMatchTicker = {}

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
	args.wrapperClasses = {'new-match-style'}
	args.recent = true
	args.newStyle = true
	args.limit = args.limit or args.recentLimit or 5

	return HtmlWidgets.Fragment{
		children = {
			HtmlWidgets.Div{
				classes = {'infobox-header'},
				children = 'Recent Matches'
			},
			MatchTicker(args):query(matches.recent):create()
		}
	}
end

---@deprecated Use CustomMatchTicker.recent() instead. This function only displays recent matches.
---@param args table
---@param matches {recent: table?}?
---@return Html
function CustomMatchTicker.participant(args, matches)
	return CustomMatchTicker.recent(args, matches)
end

return CustomMatchTicker
