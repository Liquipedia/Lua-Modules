---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class FreefireLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

--TODO: Seperate categories
local MODES = {
	solo = 'Solos[[Category:Solos Mode Tournaments]]',
	['solo rh'] = 'Solos Rush Hour [[Category:Solos Rush Hour Mode Tournaments]]',
	duo = 'Duos[[Category:Duos Mode Tournaments]]',
	squad = 'Squads[[Category:Squads Mode Tournaments]]',
	['4v4'] = '4v4 Clash Squad[[Category:4v4 Clash Squad Tournaments]]',
	['4v4b'] = '4v4 Bomb Squad [[Category:4v4 Bomb Squad Tournaments]]',
	['5v5'] = '5v5 Bomb Squad [[Category:5v5 Bomb Squad Tournaments]]',
	['6v6'] = '6v6 Clash Squad [[Category:6v6 Clash Squad Tournaments]]',
	default = '[[Category:Unknown Mode Tournaments]]',
}

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Number of Players', content = {args.player_number}},
			Cell{name = 'Number of Teams', content = {args.team_number}}
		)
	elseif id == 'gamesettings' then
		return {
			Cell{name = 'Game Mode', content = {CustomLeague._getGameMode(args.mode)}},
		}
	end
	return widgets
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy Vars:
	Variables.varDefine('tournament_edate', self.data.endDate)
end

---@param mode string?
---@return string?
function CustomLeague._getGameMode(mode)
	return MODES[string.lower(mode or '')]
end

return CustomLeague
