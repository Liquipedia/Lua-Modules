---
-- @Liquipedia
-- page=Module:Infobox/LP15Y/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Team = Lua.import('Module:Infobox/Team')

local Widgets = Lua.import('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title


---@class LP15YInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
function CustomTeam.run(frame)
	local team = CustomTeam(frame)
	team:setWidgetInjector(CustomInjector(team))

	return team:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(
			widgets,
			Title{name = 'Statistics'},
			Cell{name = 'Wikis', content = {args.wikis}},
			Cell{name = 'Pages', content = {args.pages}},
			Cell{name = 'Articles', content = {args.articles}},
			Cell{name = 'Edits', content = {args.edits}},
			Cell{name = 'Users', content = {args.users}},
			Cell{name = 'Contributors', content = {args.contributors}},
			Cell{name = 'Discord Users', content = {args.discordusers}}
		)
	end

	return widgets
end

return CustomTeam
