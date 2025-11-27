---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local MapModes = Lua.import('Module:MapModes')
local String = Lua.import('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class MarvelRivalsMapInfobox: MapInfobox
---@operator call(Frame): MarvelRivalsMapInfobox
local CustomMap = Class.new(Map)

---@class MarvelRivalsMapInfoboxWidgetInjector: WidgetInjector
---@field caller MarvelRivalsMapInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
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
		local gameModes = self.caller:_getGameMode(args)
		Array.appendWith(
			widgets,
			Cell{name = #gameModes == 1 and 'Game Mode' or 'Game Modes', content = gameModes},
			Cell{name = 'Lighting', content = {args.lighting}},
			Cell{name = 'Checkpoints', content = {args.checkpoints}}
		)
	end
	return widgets
end

---@param args table
---@return string[]
function CustomMap:_getGameMode(args)
	if String.isEmpty(args.mode) and String.isEmpty(args.mode1) then
		return {}
	end

	local modes = self:getAllArgsForBase(args, 'mode')
	local releaseDate = args.releasedate

	return Array.map(modes, function (mode)
		local modeIcon = MapModes.get{mode = mode, date = releaseDate, size = 15}
		return modeIcon .. ' [[' .. mode .. ']]'
	end)
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata.modes = self:getAllArgsForBase(args, 'mode')
	return lpdbData
end

return CustomMap
