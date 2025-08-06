---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local RoleOf = Lua.import('Module:RoleOf')

local Team = Lua.import('Module:Infobox/Team')

---@class TeamfortressInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	-- Automatic org people
	team.args.coach = RoleOf.get{role = 'Coach'}
	team.args.manager = RoleOf.get{role = 'Manager'}
	team.args.captain = RoleOf.get{role = 'Captain'}


	return team:createInfobox()
end

return CustomTeam
