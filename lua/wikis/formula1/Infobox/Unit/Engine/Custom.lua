---
-- @Liquipedia
-- page=Module:Infobox/Unit/Engine/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = require('Module:Widget/All')
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
			Cell{name = 'Manufacturer', content = {args.manufacturer}},
			Cell{name = 'Production', content = {args.production}},
			Cell{name = 'Weight', content = {args.weight}},
			Title{children = 'Engine Output'},
			Cell{name = 'Power', content = {args.power}},
			Cell{name = 'Torque', content = {args.torque}},
			Cell{name = 'Idle RPM', content = {args.idlerpm}},
			Cell{name = 'Peak RPM', content = {args.peakrpm}},
			Title{children = 'Engine Layout'},
			Cell{name = 'Configuration', content = {args.configuration}},
			Cell{name = 'Displacement', content = {args.displacement}},
			Cell{name = 'Compression', content = {args.compression}},
			Cell{name = 'Cylinder Bore', content = {args.bore}},
			Cell{name = 'Piston Stroke', content = {args.stroke}}
		)
	elseif id == 'customcontent' then
		if String.isEmpty(args.previous) and String.isEmpty(args.next) then return widgets end
		return {
			Title{children = 'Chronology'},
			Chronology{links = {previous = args.previous, next = args.next}}
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
