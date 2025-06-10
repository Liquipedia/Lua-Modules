---
-- @Liquipedia
-- page=Module:Infobox/Company/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Company = Lua.import('Module:Infobox/Company')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class PubgCompanyInfobox: CompanyInfobox
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
		table.insert(widgets, Cell{
			name = CustomCompany._createSisterCompaniesDescription(args),
			content = self.caller:getAllArgsForBase(args, 'sister', {})
		})
	end
	return widgets
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
