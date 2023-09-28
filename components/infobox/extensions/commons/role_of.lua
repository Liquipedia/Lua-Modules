---
-- @Liquipedia
-- wiki=commons
-- page=Module:RoleOf
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Opponent = require('Module:Opponent')
local OpponentDisplay = require('Module:OpponentDisplay')
local Variables = require('Module:Variables')

local RoleOf = {}

---Fetches a team's current person in a specific role.
---Defaults to current page if team is not provided.
---Data is fetched from LPDB.
---Returns a formatted string to be used in an Infobox. `nil` is return if no person has the provided role.
---@param args {team: string?, role: string}
---@return string?
function RoleOf.get(args)
	assert(args and args.role, 'RoleOf.get() requires a role input')

	local team = args.team or mw.title.getCurrentTitle().text
	local teamPage = mw.ext.TeamLiquidIntegration.resolve_redirect(team):gsub(' ', '_')
	local teamData = mw.ext.LiquipediaDB.lpdb('squadplayer', {
		conditions = '[[pagename::' .. teamPage .. ']] AND [[status::active]] AND ' ..
			'([[position::' .. args.role .. ']] OR [[role::' .. args.role .. ']])',
		query = 'id, link, nationality',
		limit = 1
	})[1]

	if not teamData then
		return
	end

	Variables.varDefine(args.role .. 'id', teamData.link)
	local opponent = Opponent.readOpponentArgs{
		type = Opponent.solo,
		name = teamData.id,
		link = teamData.link,
		flag = teamData.nationality,
	}
	---@cast opponent -nil
	return tostring(OpponentDisplay.InlineOpponent{opponent = opponent})
end

return Class.export(RoleOf)
