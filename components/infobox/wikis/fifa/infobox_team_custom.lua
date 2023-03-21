---
-- @Liquipedia
-- wiki=fifa
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local MatchTicker = require('Module:MatchTicker/Participant')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')

local CustomTeam = Class.new()
local CustomInjector = Class.new(Injector)

local _team
local _doStore = true

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	team.createWidgetInjector = CustomTeam.createWidgetInjector
	team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb
	return team:createInfobox()
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

function CustomTeam:createBottomContent()
	if _doStore then
		return MatchTicker.run({team = _team.pagename})
	end
end

function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.region = Variables.varDefault('region', '')

	return lpdbData
end

return CustomTeam
