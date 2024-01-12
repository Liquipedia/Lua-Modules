---
-- @Liquipedia
-- wiki=pubgmobile
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class PubgMobileMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
local CustomInjector = Class.new(Injector)

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
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))

	return map:createInfobox()
end

--@param id string
---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Span', content = {args.span}},
			Cell{name = 'Theme', content = {args.theme}},
			Cell{name = 'Size', content = {args.size}},
			Cell{name = 'Game Version', content = {self.caller:_getGameVersion(args)}},
			Cell{name = 'Game Mode(s)',content = {self.caller:_getGameMode(args)}}
		)
	end
	return widgets
end

---@param args table
---@return string?
function CustomMap:_getGameVersion(args)
	return GAME[string.lower(args.game or '')]
end

---@param args table
---@return string?
function CustomMap:_getGameMode(args)
	return MODES[string.lower(args.mode or '')]
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata.theme = args.theme
	lpdbData.extradata.size = args.sizeabr
	lpdbData.extradata.span = args.span
	lpdbData.extradata.mode = string.lower(args.mode or '')
	lpdbData.extradata.perpective = string.lower(args.perspective or '')
	lpdbData.extradata.game = string.lower(args.game or '')
	return lpdbData
end

return CustomMap
