---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local PageLink = require('Module:Page')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class ArenafpsLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local MODES = {
	['arena'] = 'Arena',
	['shaft arena'] = 'Shaft Arena',
	['rocket arena'] = 'Rocket Arena',
	['duel'] = 'Duel',
	['sacrifice'] = 'Sacrifice',
	['team deathmatch'] = 'Team Deathmatch',
	['2vs2 tdm'] = '2vs2 Team Deathmatch',
	['3vs3 circuit'] = '3vs3 Circuit',
	['wipeout'] = 'Wipeout',
	['race'] = 'Race',
	['4vs4 team deathmatch'] = '4vs4 Team Deathmatch',
	['ctf'] = 'Capture the Flag',
	['free for all'] = 'Free For All',
	['macguffin'] = 'MacGuffin',
	['slipgate'] = 'Slipgate',
	['clan arena'] = 'Clan Arena',
}

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.player_number = league.args.participants_number
	league.args.game = Game.name{game = league.args.game}
	league.args.mode = league:_modeLookup(league.args.mode)

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Game', content = {args.game}},
			Cell{name = 'Mode', content = {args.mode}},
			Cell{name = 'Number of Players', content = {args.player_number}},
			Cell{name = 'Number of Teams', content = {args.team_number}}
		)
	elseif id == 'customcontent' then
		local maps = self.caller:getAllArgsForBase(args, 'map')
		if #maps > 0 then
			local game = args.game and ('/' .. args.game) or ''

			maps = Array.map(maps, function(map)
				return tostring(self.caller:_createNoWrappingSpan(
					PageLink.makeInternalLink({}, map, map .. game)
				))
			end)

			table.insert(widgets, Title{children = 'Maps'})
			table.insert(widgets, Center{children = {table.concat(maps, '&nbsp;• ')}})
		end
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(self:getAllArgsForBase(args, 'map'), ';')

	return lpdbData
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername or args.name)
	Variables.varDefine('tournament_tier', args.liquipediatier)
	Variables.varDefine('tournament_prizepool', args.prizepoolusd)

	--Legacy date vars
	Variables.varDefine('tournament_sdate', self.data.startDate)
	Variables.varDefine('tournament_edate', self.data.endDate)
	Variables.varDefine('tournament_date', self.data.endDate)
	Variables.varDefine('date', self.data.endDate)
	Variables.varDefine('sdate', self.data.startDate)
	Variables.varDefine('edate', self.data.endDate)
	Variables.varDefine('mode', args.mode)
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	return {
		self.data.game and (Game.name{game = args.game} .. ' Competitions') or 'Tournaments without game version',
		args.mode and (args.mode .. ' Tournaments') or 'Tournaments Missing Mode',
	}
end

---@param mode string?
---@return string?
function CustomLeague:_modeLookup(mode)
	return MODES[string.lower(mode or '')]
end

---@param content Html|string|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague
