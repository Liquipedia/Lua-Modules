---
-- @Liquipedia
-- page=Module:Infobox/Unit/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
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
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		return Array.append(widgets,
			Cell{name = 'Released', content = {args.releasedate}},
			Cell{name = 'Acquisition', content = {args.acquisition}},
			Cell{name = 'Vehicle Type', content = {args.vehicletype}},
			Cell{name = 'Battle Rating', content = {args.br}},
			Cell{name = 'Nation', content = {caller:buildNationDisplay()}},
			Cell{name = 'Role', content = {args.role}}
		)
	end
	return widgets
end

---@return string?
function CustomUnit:buildNationDisplay()
	local flag = Flags.Icon{flag = self.args.country, shouldLink = false}
	if Logic.isEmpty(flag) then return end
	return flag .. ' ' .. Flags.CountryName{flag = self.args.country}
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
			country = Flags.CountryCode{flag = args.country},
			role = args.role,
			vehicletype = args.vehicletype
		}
	}

	mw.ext.LiquipediaDB.lpdb_datapoint('vehicle_' .. self.name, Json.stringifySubTables(lpdbData))
end

return CustomUnit

