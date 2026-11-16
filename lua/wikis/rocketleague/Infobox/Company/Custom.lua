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

---@class RocketleagueCompanyInfobox: CompanyInfobox
---@operator call(Frame): RocketleagueCompanyInfobox
local CustomCompany = Class.new(Company)

---@class RocketleagueCompanyInfoboxWidgetInjector: WidgetInjector
---@operator call(RocketleagueCompanyInfobox): RocketleagueCompanyInfoboxWidgetInjector
---@field caller RocketleagueCompanyInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return VNode
function CustomCompany.run(frame)
	local company = CustomCompany(frame)
	company:setWidgetInjector(CustomInjector(company))

	return company:createInfobox()
end
---@param id string
---@param widgets Renderable[]
---@return Renderable[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		table.insert(widgets, Cell{name = 'Epic Creator Code', children = {args.creatorcode}})
	end

	return widgets
end

return CustomCompany
