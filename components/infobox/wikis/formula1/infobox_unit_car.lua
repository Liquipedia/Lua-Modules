---
-- @Liquipedia
-- wiki=formula1
-- page=Module:Infobox/Unit/Car
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Unit = Lua.import('Module:Infobox/Unit', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Chronology = Widgets.Chronology
local Title = Widgets.Title

local _args

local CustomUnit = Class.new()

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = Unit(frame)
	_args = unit.args
	unit.args.informationType = 'Car'
	unit.setLpdbData = CustomUnit.setLpdbData
	unit.getWikiCategories = CustomUnit.getWikiCategories
	unit.createWidgetInjector = CustomUnit.createWidgetInjector
	return unit:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return {
		Cell{name = 'Season(s)', content = {_args.season}},
		Cell{name = 'Power', content = {_args.power}},
		Cell{name = 'Weight', content = {_args.weight}},
		Cell{name = 'Engine', content = {_args.engine}},
		Cell{name = 'Fuel', content = {_args.fuel}},
		Cell{name = 'Lubricant(s)', content = {_args.lubricant}},
		Cell{name = 'Tyre Supplier', content = {_args.tyres}},
		Cell{name = 'First Entry', content = {_args.firstentry}},
		Cell{name = 'Last Entry', content = {_args.lastentry}},
	}
end

---@return WidgetInjector
function CustomUnit:createWidgetInjector()
	return CustomInjector()
end

---@param id string
---@widgets Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'customcontent' then
		if String.isNotEmpty(_args.previous) or String.isNotEmpty(_args.next) then
				return {
					Title{name = 'Chronology'},
					Chronology{
						content = {
							previous = _args.previous,
							next = _args.next,
						}
					}
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
