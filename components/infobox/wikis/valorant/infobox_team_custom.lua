---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Team = require('Module:Infobox/Team')
local Variables = require('Module:Variables')
local Class = require('Module:Class')
local String = require('Module:String')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Template = require('Module:Template')

local CustomTeam = Class.new()
local CustomInjector = Class.new(Injector)

local _team

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	team.createWidgetInjector = CustomTeam.createWidgetInjector
	team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb
	return team:createInfobox(frame)
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'In-Game Leader',
		content = {_team.args.igl}
	})
	return widgets
end

function CustomTeam:createBottomContent()
	return Template.expandTemplate(
		mw.getCurrentFrame(),
		'Upcoming and ongoing matches of',
		{team = _team.name or _team.pagename}
	) .. Template.expandTemplate(
		mw.getCurrentFrame(),
		'Upcoming and ongoing tournaments of',
		{team = _team.name or _team.pagename}
	)
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
