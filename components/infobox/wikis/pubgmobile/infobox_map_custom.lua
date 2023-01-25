---
-- @Liquipedia
-- wiki=pubgmobile
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Map = Lua.import('Module:Infobox/Map', {requireDevIfEnabled = true})

local Abbreviation = require('Module:Abbreviation')
local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomMap = Class.new()

local CustomInjector = Class.new(Injector)

local _args

local GAME = {
	mobile = '[[Mobile]]',
	newstate = '[[New State]]',
	peace = '[[Peacekeeper Elite|Peace Elite]]',
	bgmi = '[[Battlegrounds Mobile India|BGMI]]',
}

local MODES = {
	solo = '[[:Category:Solos Mode Tournaments|Solos]]',
	duo = '[[:Category:Duos Mode Tournaments|Duos]]',
	squad = '[[:Category:Squads Mode Tournaments|Squads]]',
	['2v2'] = '[[:Category:2v2 TDM Tournaments|2v2 TDM]]',
	['4v4'] = '[[:Category:4v4 TDM Tournaments|4v4 TDM]]',
	['war mode'] = '[[:Category:War Mode Tournaments|War Mode]]',
	default = '',
}
MODES.solos = MODES.solo
MODES.duos = MODES.duo
MODES.squads = MODES.squad
MODES.tdm = MODES['2v2']

local PERSPECTIVES = {
	fpp = {'FPP'},
	tpp = {'TPP'},
	mixed = {'FPP', 'TPP'},
}
PERSPECTIVES.first = PERSPECTIVES.fpp
PERSPECTIVES.third = PERSPECTIVES.tpp

function CustomMap.run(frame)
	local customMap = Map(frame)
	customMap.createWidgetInjector = CustomMap.createWidgetInjector
	customMap.addToLpdb = CustomMap.addToLpdb
	_args = customMap.args
	return customMap:createInfobox()
end

function CustomMap:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Game Version',
		content = {CustomMap._getGameVersion()}
	})
	table.insert(widgets, Cell{
		name = 'Game Mode(s)',
		content = {CustomMap._getGameMode()}
	})
	table.insert(widgets, Cell{
		name = 'Span',
		content = {_args.span}
	})
	table.insert(widgets, Cell{
		name = 'Theme',
		content = {_args.theme}
	})
	table.insert(widgets, Cell{
		name = 'Size',
		content = {Abbreviation.make(_args.sizeabr, _args.size)}
	})
	return widgets
end

function CustomMap._getGameVersion()
	return GAME[string.lower(_args.game or '')]
end

function CustomMap:_getGameMode()
	if String.isEmpty(_args.perspective) and String.isEmpty(_args.mode) then
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
	local displayPerspectives = Table.mapValues(getPerspectives(_args.perspective), getPerspectiveDisplay)
	local mode = MODES[string.lower(_args.mode or '')] or MODES['default']

	return mode .. '&nbsp;' .. table.concat(displayPerspectives, '&nbsp;')
end

function CustomMap:addToLpdb(lpdbData)
	lpdbData.extradata.theme = _args.theme
	lpdbData.extradata.size = _args.sizeabr
	lpdbData.extradata.span = _args.span
	lpdbData.extradata.mode = string.lower(_args.mode or '')
	lpdbData.extradata.perpective = string.lower(_args.perspective or '')
	lpdbData.extradata.game = string.lower(_args.game or '')
	return lpdbData
end

return CustomMap
