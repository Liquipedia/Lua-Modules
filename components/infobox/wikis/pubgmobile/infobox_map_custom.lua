---
-- @Liquipedia
-- wiki=pubgmobile
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

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
	['battle royale'] = 'Battle Royale',
	arena = 'Arena',
}
MODES.arenas = MODES.arena
MODES.tdm = MODES.arena
MODES.battleroyale = MODES['battle royale']
MODES.br = MODES['battle royale']

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local customMap = Map(frame)
	customMap.createWidgetInjector = CustomMap.createWidgetInjector
	customMap.addToLpdb = CustomMap.addToLpdb
	_args = customMap.args
	return customMap:createInfobox()
end

---@return WidgetInjector
function CustomMap:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
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
		content = {_args.size}
	})
	table.insert(widgets, Cell{
		name = 'Game Version',
		content = {CustomMap._getGameVersion()}
	})
	table.insert(widgets, Cell{
		name = 'Game Mode(s)',
		content = {CustomMap._getGameMode()}
	})
	return widgets
end

---@return string?
function CustomMap._getGameVersion()
	return GAME[string.lower(_args.game or '')]
end

---@return string?
function CustomMap._getGameMode()
	return MODES[string.lower(_args.mode or '')]
end

---@param lpdbData table
---@return table
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
