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

local MatchTicker = Lua.import('Module:MatchTicker/Controller')
local InfoboxHeader = Lua.import('Module:Widget/Infobox/Header')

local CustomMatchTicker = {}

---Entry point for display on the main page
---@param frame Frame|table|nil
---@return Renderable?
function CustomMatchTicker.mainPage(frame)
	local args = Arguments.getArgs(frame)

	args.tiers = args['filterbuttons-liquipediatier']
	if args.tiers == 'curated' then
		args.tiers = nil
		args.featuredOnly = true
	end

	args.tiertypes = args['filterbuttons-liquipediatiertype']
	args.regions = args['filterbuttons-region']
	args.games = args['filterbuttons-game']

	if args.type == 'upcoming' then
		return MatchTicker.makeMatchTicker(Table.merge(args, {ongoing = true, upcoming = true}))
	elseif args.type == 'recent' then
		return MatchTicker.makeMatchTicker(Table.merge(args, {recent = true}))
	end
end

---Entry point for display on player pages
---Upcoming and ongoing matches are now automatically displayed via the entity match ticker
---@param frame Frame|table|nil
---@return Renderable?
function CustomMatchTicker.player(frame)
	local args = Arguments.getArgs(frame)
	args.player = args.player or mw.title.getCurrentTitle().text
	return CustomMatchTicker.recent(args)
end

---Displays recent matches for a player or team.
---@param args table
---@return Renderable?
function CustomMatchTicker.recent(args)
	--adjusting args
	args.infoboxClass = Logic.nilOr(Logic.readBoolOrNil(args.infoboxClass), true)
	args.recent = true
	args.limit = args.limit or args.recentLimit or 5
	args.header = InfoboxHeader{name = 'Recent Matches', displayButtons = false}

	return MatchTicker.makeMatchTicker(args)
end

return CustomMatchTicker
