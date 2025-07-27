---
-- @Liquipedia
-- page=Module:Infobox/Person/MapMaker/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local CustomPerson = Lua.import('Module:Infobox/Person/Custom')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class Starcraft2MapMakerInfobox: SC2CustomPerson
local CustomMapMaker = Class.new(CustomPerson)

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMapMaker.run(frame)
	local mapMaker = CustomMapMaker(frame)
	mapMaker:setWidgetInjector(CustomInjector(mapMaker))

	return mapMaker:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		return {
			Cell{name = 'Military Service', content = {args.military}},
		}
	elseif id == 'status' then
		return {
			Cell{
				name = 'Race',
				content = {self.caller:getRaceData(args.race or 'unknown')}
			}
		}
	elseif id == 'role' then return {}
	elseif id == 'region' then return {}
	elseif id == 'achievements' then
		if String.isNotEmpty(args.maps_ladder) or String.isNotEmpty(args.maps_special) then
			return {
				Title{children = 'Achievements'},
				Cell{name = 'Ladder maps created', content = {args.maps_ladder}},
				Cell{name = 'Non-ladder competitive maps created', content = {args.maps_special}}
			}
		end
		return {}
	elseif
		id == 'history' and
		string.match(args.retired or '', '%d%d%d%d')
	then
		table.insert(widgets, Cell{
				name = 'Retired',
				content = {args.retired}
			})
	end
	return widgets
end

return CustomMapMaker
