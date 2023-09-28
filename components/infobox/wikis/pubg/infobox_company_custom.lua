---
-- @Liquipedia
-- wiki=pubg
-- page=Module:Infobox/Company/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Company = Lua.import('Module:Infobox/Company', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomCompany = Class.new()

local CustomInjector = Class.new(Injector)

local _args

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell({
		name = CustomCompany._createSisterCompaniesDescription(_args),
		content = Company:getAllArgsForBase(_args, 'sister', {})
	}))
	return widgets
end

---@param frame Frame
---@return Html
function CustomCompany.run(frame)
	local company = Company(frame)
	company.createWidgetInjector = CustomCompany.createWidgetInjector
	_args = company.args
	return company:createInfobox()
end

---@return WidgetInjector
function CustomCompany:createWidgetInjector()
	return CustomInjector()
end

---@param args table
---@return string
function CustomCompany._createSisterCompaniesDescription(args)
	if args.sister2 then
		return 'Sister Companies'
	end
	return 'Sister Company'
end

return CustomCompany
