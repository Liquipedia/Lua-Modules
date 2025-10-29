---
-- @Liquipedia
-- page=Module:Infobox/Unit/Engine/Custom
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
local Title = Widgets.Title

---@class Formula1EngineInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit:setWidgetInjector(CustomInjector(unit))
	unit.args.informationType = 'Engine'
	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Manufacturer', children = {args.manufacturer}},
			Cell{name = 'Production', children = {args.production}},
			Cell{name = 'Weight', children = {args.weight}},
			Title{children = 'Engine Output'},
			Cell{name = 'Power', children = {args.power}},
			Cell{name = 'Torque', children = {args.torque}},
			Cell{name = 'Idle RPM', children = {args.idlerpm}},
			Cell{name = 'Peak RPM', children = {args.peakrpm}},
			Title{children = 'Engine Layout'},
			Cell{name = 'Configuration', children = {args.configuration}},
			Cell{name = 'Displacement', children = {args.displacement}},
			Cell{name = 'Compression', children = {args.compression}},
			Cell{name = 'Cylinder Bore', children = {args.bore}},
			Cell{name = 'Piston Stroke', children = {args.stroke}}
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
		return {'Engines'}
	end

	return {}
end

---@param args table
function CustomUnit:setLpdbData(args)
	local lpdbData = {
		name = args.name,
		type = 'engine',
		image = args.image,
		date = args.released,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{},
	}

	mw.ext.LiquipediaDB.lpdb_datapoint('engine_' .. self.pagename, lpdbData)
end

return CustomUnit
