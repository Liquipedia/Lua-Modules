---
-- @Liquipedia
-- page=Module:Infobox/Unit/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')

local Unit = Lua.import('Module:Infobox/Unit')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class WarThunderUnitInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
---@class WarThunderUnitInfoboxWidgetInjector: WidgetInjector
---@field caller WarThunderUnitInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit.args.informationType = 'Vehicle'
	unit:setWidgetInjector(CustomInjector(unit))
	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		return Array.append(widgets,
			Cell{name = 'Released', content = {args.released}},
			Cell{name = 'Acquisition', content = {args.acquisition}},
			Cell{name = 'Vehicle Type', content = {CustomUnit._getVehicleType(args)}},
			Cell{name = 'Battle Rating', content = {args.br}},
			Cell{name = 'Nation', content = {Nation.run(args.nation)}},
			Cell{name = 'Role', content = {args.role}}
		)
	end
	return widgets
end

---@param args table
---@return string[]
function CustomUnit._getVehicleType(args)
	if Logic.isEmpty(args.vehicletype) then
		return {}
	end
	local releasedate = args.releasedate
	local typeIcon = VehicleTypes.get{type = args.vehicletype, date = releasedate, size = 15}
	return typeIcon .. ' [[' .. args.vehicletype .. ']]'
end

---@param args table
---@return string[]
function CustomUnit:getWikiCategories(args)
	if not Namespace.isMain() then return {} end
	return Array.append({'Vehicles'},
		Logic.isNotEmpty(args.vehicletype) and (args.vehicletype .. ' Vehicles') or nil
	)
end

---@param args table
function CustomUnit:setLpdbData(args)
	local lpdbData = {
		name = args.name or self.pagename,
		type = 'vehicle',
		image = args.image,
		date = args.released,
		information = 'vehicle',
		extradata = {
			acquisition = args.acquisition,
			battlerating = args.br,
			nation = args.nation,
			role = args.role,
			type = args.vehicletype
		}
	}

	mw.ext.LiquipediaDB.lpdb_datapoint('vehicle_' .. self.name, Json.stringifySubTables(lpdbData))
end

return CustomUnit
