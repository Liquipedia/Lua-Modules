---
-- @Liquipedia
-- wiki=clashofclans
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Team = Lua.import('Module:Infobox/Team')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class ClashofClansInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
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

	if id == 'topcustomcontent' then
		table.insert(widgets, Cell{name = 'Clan Tag', content = {args.clantag}})
	end
	return widgets
end

return CustomTeam
