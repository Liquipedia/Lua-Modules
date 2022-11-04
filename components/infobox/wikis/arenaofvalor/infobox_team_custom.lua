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

local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})
local CustomTeam = Class.new()

local _args

function CustomTeam.run(frame)
	local team = Team(frame)
	_args = team.args

	-- Automatic org people
	team.args.coach = Template.expandTemplate(frame, 'Coach of')
	team.args.manager = Template.expandTemplate(frame, 'Manager of')
	team.args.captain = Template.expandTemplate(frame, 'Captain of')

	team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb
	return team:createInfobox(frame)
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

function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.region = Variables.varDefault('region', '')

	return lpdbData
end

return CustomTeam
