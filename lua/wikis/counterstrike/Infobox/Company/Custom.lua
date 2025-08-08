---
-- @Liquipedia
-- page=Module:Infobox/Company/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Company = Lua.import('Module:Infobox/Company')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class CounterstrikeCompanyInfobox: CompanyInfobox
local CustomCompany = Class.new(Company)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCompany.run(frame)
	local company = CustomCompany(frame)
	company:setWidgetInjector(CustomInjector(company))

	return company:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		table.insert(widgets, Cell{name = 'Series', children = {args.series}})
	elseif id == 'parent' then
		table.insert(widgets, Cell{name = 'Sister Company', children = {args.sister}})
		table.insert(widgets, Cell{name = 'Subsidiaries', children = {args.subsidiaries}})
		table.insert(widgets, Cell{name = 'Focus', children = {args.focus or args.industry}})
	elseif id == 'dates' then
		table.insert(widgets, Cell{name = 'Fate', children = {args.fate}})
	elseif id == 'employees' then
		table.insert(widgets, Cell{name = 'Key People', children = {args.people}})
	end

	return widgets
end

return CustomCompany
