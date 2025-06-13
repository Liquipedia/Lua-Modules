---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class PubgmobileLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local MODES = {
	solo = 'Solos[[Category:Solos Mode Tournaments]]',
	duo = 'Duos[[Category:Duos Mode Tournaments]]',
	squad = 'Squads[[Category:Squads Mode Tournaments]]',
	['1v1'] = '1v1 TDM[[Category:1v1 TDM Tournaments]]',
	['2v2'] = '2v2 TDM[[Category:2v2 TDM Tournaments]]',
	['4v4'] = '4v4 TDM[[Category:4v4 TDM Tournaments]]',
	['war mode'] = 'War Mode[[Category:War Mode Tournaments]]',
	default = '[[Category:Unknown Mode Tournaments]]',
}
MODES.solos = MODES.solo
MODES.duos = MODES.duo
MODES.squads = MODES.squad
MODES.tdm = MODES['2v2']
MODES.tdm1 = MODES['1v1']

local PERSPECTIVES = {
	fpp = {'FPP'},
	tpp = {'TPP'},
	mixed = {'FPP', 'TPP'},
}
PERSPECTIVES.first = PERSPECTIVES.fpp
PERSPECTIVES.third = PERSPECTIVES.tpp

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

	if id == 'sponsors' then
		table.insert(widgets, Cell{name = 'Official Device', content = {args.device}})
	elseif id == 'gamesettings' then
		return {
			Cell{name = 'Game version', content = {Game.name{game = args.game}}},
			Cell{name = 'Game mode', content = {CustomLeague._getGameMode(args)}},
		}
	elseif id == 'customcontent' then
		if args.player_number then
			table.insert(widgets, Title{children = 'Players'})
			table.insert(widgets, Cell{name = 'Number of players', content = {args.player_number}})
		end

		--teams section
		if args.team_number then
			table.insert(widgets, Title{children = 'Teams'})
			table.insert(widgets, Cell{name = 'Number of teams', content = {args.team_number}})
		end
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.extradata.individual = String.isNotEmpty(args.player_number) and 'true' or ''

	return lpdbData
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy Vars:
	Variables.varDefine('tournament_edate', self.data.endDate)
end

---@param args table
---@return string?
function CustomLeague._getGameMode(args)
	if String.isEmpty(args.perspective) and String.isEmpty(args.mode) then
		return nil
	end

	local getPerspectives = function(perspectiveInput)
		local perspective = string.lower(perspectiveInput or '')
		-- Clean unnecessary data from the input
		perspective = string.gsub(perspective, ' person', '')
		perspective = string.gsub(perspective, ' perspective', '')
		return PERSPECTIVES[perspective] or {}
	end
	local getPerspectiveDisplay = function(perspective)
		return Template.safeExpand(mw.getCurrentFrame(), 'Abbr/' .. perspective)
	end
	local displayPerspectives = Table.mapValues(getPerspectives(args.perspective), getPerspectiveDisplay)

	local mode = MODES[string.lower(args.mode or '')] or MODES['default']

	return mode .. '&nbsp;' .. table.concat(displayPerspectives, '&nbsp;')
end

return CustomLeague
