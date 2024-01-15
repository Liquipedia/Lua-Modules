---
-- @Liquipedia
-- wiki=formula1
-- page=Module:Infobox/Unit/Car/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Chronology = Widgets.Chronology
local Title = Widgets.Title

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
			Cell{name = 'Team', content = {args.team}},
			Cell{name = 'Designer', content = {args.designer}},
			Cell{name = 'Season(s)', content = {args.season}},
			Cell{name = 'Power', content = {args.power}},
			Cell{name = 'Weight', content = {args.weight}},
			Cell{name = 'Engine', content = {args.engine}},
			Cell{name = 'Fuel', content = {args.fuel}},
			Cell{name = 'Lubricant(s)', content = {args.lubricant}},
			Cell{name = 'Tyre Supplier', content = {args.tyres}},
			Cell{name = 'First Entry', content = {args.firstentry}},
			Cell{name = 'Last Entry', content = {args.lastentry}}
		)
	elseif id == 'customcontent' then
		if String.isNotEmpty(args.previous) or String.isNotEmpty(args.next) then
				return {
					Title{name = 'Chronology'},
					Chronology{content = {previous = args.previous, next = args.next,}}
				}
		end
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
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{},
	}

	mw.ext.LiquipediaDB.lpdb_datapoint('car_' .. self.pagename, lpdbData)
end

return CustomUnit
