---
-- @Liquipedia
-- page=Module:Infobox/Unit/Car/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Namespace = Lua.import('Module:Namespace')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Chronology = Widgets.Chronology

---@class Formula1CarInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit.args.informationType = 'Car'
	unit:setWidgetInjector(CustomInjector(unit))
	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Manufacturer', content = {args.manufacturer}},
			Cell{name = 'Team(s)', content = {args.team}},
			Cell{name = 'Designer', content = {args.designer}},
			Cell{name = 'Season(s)', content = {args.season}},
			Cell{name = 'Power', content = {args.power}},
			Cell{name = 'Weight', content = {args.weight}},
			Cell{name = 'Engine Provider', content = {args.engine}},
			Cell{name = 'Fuel', content = {args.fuel}},
			Cell{name = 'Lubricant(s)', content = {args.lubricant}},
			Cell{name = 'Tyre Supplier', content = {args.tyres}},
			Cell{name = 'First Entry', content = {args.firstentry}},
			Cell{name = 'Last Entry', content = {args.lastentry}}
		)
	elseif id == 'customcontent' then
		return {
			Chronology{args = args, showTitle = true}
		}
	end
	return widgets
end

---@param args table
---@return string[]
function CustomUnit:getWikiCategories(args)
	if Namespace.isMain() then
		return {'Cars'}
	end

	return {}
end

---@param args table
function CustomUnit:setLpdbData(args)
	local lpdbData = {
		name = args.name,
		type = 'car',
		image = args.image,
		date = args.released,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{
			manufacturer = args.manufacturer,
			engineprovider = args.engine,
			season = args.season,
			team = args.team,
			designer = args.designer,
		},
	}

	mw.ext.LiquipediaDB.lpdb_datapoint('car_' .. self.pagename, lpdbData)
end

return CustomUnit
