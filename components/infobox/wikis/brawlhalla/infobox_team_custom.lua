---
-- @Liquipedia
-- wiki=brawlhalla
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Team = require('Module:Infobox/Team')
local Variables = require('Module:Variables')
local Class = require('Module:Class')
local String = require('Module:String')
local Template = require('Module:Template')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local CustomTeam = Class.new()

local CustomInjector = Class.new(Injector)

local _team

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	--team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb
	team.createWidgetInjector = CustomTeam.createWidgetInjector
	return team:createInfobox(frame)
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	return {
		Cell{
			name = 'Player number',
			content = {_team.args.player_number}
		},
	}
end

function CustomInjector:parse(id, widgets)
	return widgets
end

--[[in case it is wanted later
function CustomTeam:createBottomContent()
	return Template.expandTemplate(
		mw.getCurrentFrame(),
		'Upcoming and ongoing matches of',
		{team = _team.name or _team.pagename}
	)
end
]]

function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.region = Variables.varDefault('region', '')

	return lpdbData
end

return CustomTeam
