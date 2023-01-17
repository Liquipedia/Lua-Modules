---
-- @Liquipedia
-- wiki=teamfortress
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Template = require('Module:Template')

local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local CustomTeam = Class.new()

function CustomTeam.run(frame)
	local team = Team(frame)

	-- Automatic org people
	team.args.coach = Template.expandTemplate(frame, 'Coach of')
	team.args.manager = Template.expandTemplate(frame, 'Manager of')
	team.args.captain = Template.expandTemplate(frame, 'Captain of')

	return team:createInfobox(frame)
end

return CustomTeam
