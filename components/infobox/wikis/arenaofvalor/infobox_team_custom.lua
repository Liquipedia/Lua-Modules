---
-- @Liquipedia
-- wiki=arenaofvalor
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomTeam = Class.new()
local CustomInjector = Class.new(Injector)

local _args

function CustomTeam.run(frame)
	local team = Team(frame)
	_args = team.args

	-- Automatic org people
	team.args.coach = Template.expandTemplate(frame, 'Coach of')
	team.args.manager = Template.expandTemplate(frame, 'Manager of')
	team.args.captain = Template.expandTemplate(frame, 'Captain of')

	team.createWidgetInjector = CustomTeam.createWidgetInjector
	team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb
	team.getWikiCategories = CustomTeam.getWikiCategories
	return team:createInfobox(frame)
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

function CustomTeam:createBottomContent()
	if not _args.disbanded then
		return Template.expandTemplate(
			mw.getCurrentFrame(),
			'Upcoming and ongoing matches of'
		) .. Template.expandTemplate(
			mw.getCurrentFrame(),
			'Upcoming and ongoing tournaments of'
		) .. Template.expandTemplate(
			mw.getCurrentFrame(),
			'Placement summary'
		)
	end
end

function CustomInjector:addCustomCells(widgets)
	local args = _args
	table.insert(widgets, Cell{
		name = 'Abbreviation',
		content = {_args.abbreviation}
	})

	return widgets
end

function CustomTeam:addToLpdb(lpdbData, args)
	if not String.isEmpty(args.teamcardimage) then
		lpdbData.logo = args.teamcardimage
	elseif not String.isEmpty(args.image) then
		lpdbData.logo = args.image
	end

	lpdbData.region = Variables.varDefault('region', '')

	return lpdbData
end

return CustomTeam
