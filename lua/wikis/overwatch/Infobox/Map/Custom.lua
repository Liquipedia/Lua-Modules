---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local MapModes = require('Module:MapModes')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')
local Flags = Lua.import('Module:Flags')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class OverwatchMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class OverwatchMapInfoboxWidgetInjector: WidgetInjector
---@field caller OverwatchMapInfobox
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

	if id == 'location' then
		return {
			Cell{
				name = 'Location',
				content = {Flags.Icon{flag = args.location, shouldLink = false} .. '&nbsp;' .. args.location},
			},
		}
	elseif id == 'custom' then
		local gameModes = Array.map(self.caller:getGameModes(args), function (gameMode)
			local releaseDate = args.releasedate

			local modeIcon = MapModes.get{mode = gameMode, date = releaseDate, size = 15}
			return modeIcon .. ' [[' .. gameMode .. ']]'
		end)
		Array.appendWith(
			widgets,
			Cell{name = #gameModes == 1 and 'Game Mode' or 'Game Modes', content = gameModes},
			Cell{name = 'Lighting', content = {args.lighting}},
			Cell{name = 'Checkpoints', content = {args.checkpoints}}
		)
	end
	return widgets
end

return CustomMap
