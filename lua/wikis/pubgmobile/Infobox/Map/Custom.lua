---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class PubgMobileMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class PubgMobileMapInfoboxWidgetInjector: WidgetInjector
---@field caller PubgMobileMapInfobox
local CustomInjector = Class.new(Injector)

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
			Cell{name = 'Game Version', content = {Game.text{
				game = args.game,
				useDefault = true,
				useAbbreviation = true,
			}}},
			Cell{name = 'Game Mode(s)',content = self.caller:getGameModes(args)}
		)
	end
	return widgets
end

---@param args table
---@return string[]
function CustomMap:getGameModes(args)
	return Array.map(
		self:getAllArgsForBase(args, 'mode'),
		function (gameMode)
			return MODES[gameMode:lower()]
		end
	)
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata.theme = args.theme
	lpdbData.extradata.size = args.sizeabr
	lpdbData.extradata.span = args.span
	lpdbData.extradata.perpective = string.lower(args.perspective or '')
	return lpdbData
end

return CustomMap
