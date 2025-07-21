---
-- @Liquipedia
-- page=Module:Infobox/Company/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Company = Lua.import('Module:Infobox/Company')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class PokemonCompanyInfobox: CompanyInfobox
local CustomCompany = Class.new(Company)
---@class PokemonCompanyInfoboxInjector: WidgetInjector
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
		return Array.appendWith(widgets,
			Title{children = 'Staff Members'},
			Cell{name = 'Directors', content = Array.parseCommaSeparatedString(args.directors)},
			Cell{name = 'Event Organizer', content = Array.parseCommaSeparatedString(args.organizers)},
			Cell{name = 'Editors', content = Array.parseCommaSeparatedString(args.editors)},
			Cell{name = 'Commentators', content = Array.parseCommaSeparatedString(args.commentators)},
			unpack(Array.mapIndexes(function(roleIndex)
				local prefix = 'role' .. roleIndex
				if not args[prefix] then return end
				return Cell{name = args[prefix], content = Array.parseCommaSeparatedString(args[prefix .. '_list'])}
			end)),
			Cell{name = 'Members', content = Array.parseCommaSeparatedString(args.members)},
			Cell{name = 'Former Staff', content = Array.parseCommaSeparatedString(args.former_staff)}
		)
	end
	return widgets
end

return CustomCompany
