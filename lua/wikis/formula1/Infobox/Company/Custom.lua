---
-- @Liquipedia
-- page=Module:Infobox/Company/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Widget/Injector')
local Company = Lua.import('Module:Infobox/Company')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class Formula1CompanyInfobox: CompanyInfobox
local CustomCompany = Class.new(Company)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCompany.run(frame)
	local company = CustomCompany(frame)
	company:setWidgetInjector(CustomInjector(company))
	return company:createInfobox(frame)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		local staffInfoCells = {
			{key = 'president', name = 'President'},
			{key = 'deputypresidentmobility', name = 'Deputy President of Mobility'},
			{key = 'deputypresidentsport', name = 'Deputy President of Sport'},
			{key = 'senatepresident', name = 'Senate President'},
			{key = 'chiefexecutiveofficer', name = 'Chief Executive Officer'},
			{key = 'singleseaterdirector', name = 'Single-Seater Director'},
			{key = 'circuitsportdirector', name = 'Circuit Sport Director'},
			{key = 'roadsportdirector', name = 'Road Sport Director'},
		}
		if not Array.any(staffInfoCells, function(cellData) return args[cellData.key] end) then
			return widgets
		end

		return Array.extendWith(widgets,
			{Title{children = 'Staff Information'}},
			Array.map(staffInfoCells, function(cellData)
				return Cell{name = cellData.name, children = {args[cellData.key]}}
			end)
		)
	end

	return widgets
end

return CustomCompany
