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

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class HaloMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class HaloMapInfoboxWidgetInjector: WidgetInjector
---@field caller HaloMapInfobox
local CustomInjector = Class.new(Injector)

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
			Cell{name = 'Type', content = {args.type}},
			Cell{name = 'Max Players', content = {args.players}},
			Cell{name = 'Game Version', content = {self.caller:getGame(args)}, options = {makeLink = true}},
			Cell{
				name = 'Game Modes',
				content = Array.map(
					self.caller:getGameModes(args),
					function (gameMode)
						local modeIcon = MapModes.get({mode = gameMode, date = args.releasedate, size = 15})
						return modeIcon .. ' [[' .. gameMode .. ']]'
					end
				)
			}
		)
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata.type = args.type
	lpdbData.extradata.players = args.players
	return lpdbData
end

return CustomMap
