---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local RoleOf = Lua.import('Module:RoleOf')
local Template = Lua.import('Module:Template')

local Team = Lua.import('Module:Infobox/Team')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class HeroesInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)
---@class HeroesInfoboxTeamInjector: WidgetInjector
---@field caller HeroesInfoboxTeam
local CustomInjector = Class.new(Injector)

function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	-- Automatic org people
	team.args.coach = RoleOf.get{role = 'Coach'}
	team.args.manager = RoleOf.get{role = 'Manager'}
	team.args.captain = RoleOf.get{role = 'Captain'}

	team:setWidgetInjector(CustomInjector(team))

	return team:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args
	if id == 'custom' then
		return {
			Cell{name = 'Tag', children = {args.tag}},
			Cell{name = 'Color(s)', children = Array.map(caller:getAllArgsForBase(args, 'color'), function(color)
				return Template.safeExpand(mw.getCurrentFrame(), 'Color box', {color})
			end), options = {separator = ' '}},
		}
	end
	return widgets
end

return CustomTeam
