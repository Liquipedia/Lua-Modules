---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class SimracingLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local SPECIAL_SPONSORS = {
	polyphony ='[[File:Polyphony Digital.png|x18px|Premier Tournament held by Polyphony Digital]]',
	sms ='[[File:Slightly Mad Studios.png|x18px|Premier Tournament held by Slightly Mad Studios]]',
	sector3 ='[[File:Sector3.png|x18px|Premier Tournament held by Sector3]]',
	turn10 ='[[File:Turn10.png|x18px|Premier Tournament held by Turn10]]',
	fia ='[[File:FIA logo.png|x18px|Premier Tournament held by FIA]]',
	iracing ='[[File:IRacing Logo.png|x18px|Official World Championships sanctioned by iRacing]]',
	f1 ='[[File:F1 New Logo.png|x10px|Official Championship of the FIA Formula One World Championship]]',
}

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.game = Game.name{game = league.args.game}

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Game', children = {args.game}},
			Cell{name = 'Number of Players', children = {args.player_number}},
			Cell{name = 'Number of Teams', children = {args.team_number}}
		)
	end

	return widgets
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername or args.name)
	Variables.varDefine('tournament_tier', args.liquipediatier)
	Variables.varDefine('mode', args.mode)

	--Legacy date vars
	Variables.varDefine('tournament_sdate', self.data.startDate)
	Variables.varDefine('tournament_edate', self.data.endDate)
	Variables.varDefine('tournament_date', self.data.endDate)
	Variables.varDefine('date', self.data.endDate)
	Variables.varDefine('sdate', self.data.startDate)
	Variables.varDefine('edate', self.data.endDate)
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	return {
		args.game and (args.game .. ' Competitions') or 'Tournaments without game version'
	}
end

---@param args table
---@return boolean
function CustomLeague:liquipediaTierHighlighted(args)
	return Table.any(SPECIAL_SPONSORS, function(key)
		return args[key..'-sponsored']
	end)
end

---@param args table
---@return string
function CustomLeague:appendLiquipediatierDisplay(args)
	local content = ''

	for param, icon in pairs(SPECIAL_SPONSORS) do
		if args[param..'-sponsored'] then
			content = content .. icon
		end
	end

	return content
end

return CustomLeague
