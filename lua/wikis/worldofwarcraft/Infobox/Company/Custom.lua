---
-- @Liquipedia
-- page=Module:Infobox/Company/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Company = Lua.import('Module:Infobox/Company')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class WorldofwarcraftCompanyInfobox: CompanyInfobox
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
	if id == 'parent' then
		table.insert(widgets, Cell{name = 'Focus', content = {args.focus}})
	elseif id == 'employees' then
		table.insert(widgets, Cell{name = 'Key People', content = {args.people}})
	end

	return widgets
end

return CustomCompany
