---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomTeam = Class.new(Team)
local CustomInjector = Class.new(Injector)

function CustomTeam.run(frame)
	local team = CustomTeam(frame)
	team:setWidgetInjector(CustomInjector(team))
	return team:createInfobox()
end

function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'staff' then
		return {
			Cell{name = 'In-Game Leader', content = {args.igl}}
		}
	end

	if id == 'customcontent' then
		table.insert(widgets, Cell{
				name = 'Analysts',
				content = {args.analyst}
		})
	end
	return widgets
end

function CustomTeam:createBottomContent()
	args = self.args
	if not args.disbanded then
		return Template.expandTemplate(
			mw.getCurrentFrame(),
			'Upcoming and ongoing tournaments of',
			{team = self.name or self.pagename}
		)
	end
end

function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.region = Variables.varDefault('region', '')

	return lpdbData
end

return CustomTeam
