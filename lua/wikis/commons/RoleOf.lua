---
-- @Liquipedia
-- page=Module:RoleOf
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

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
	local staffData = mw.ext.LiquipediaDB.lpdb('squadplayer', {
		conditions = '[[pagename::' .. teamPage .. ']] AND [[status::active]]',
		query = 'id, link, nationality, position, role',
		limit = 100,
	})

	if #staffData == 0 then
		return
	end

	local output = {}
	Array.forEach(staffData, function (staff)
		if not (staff.role or ''):lower():find(string.lower(args.role))
				and not (staff.position or ''):lower():find(string.lower(args.role)) then
			return
		end

		local opponent = Opponent.readOpponentArgs{
			type = Opponent.solo,
			name = staff.id,
			link = staff.link,
			flag = staff.nationality,
		}
		table.insert(output, tostring(OpponentDisplay.InlineOpponent{opponent = opponent}))
	end)

	return table.concat(output, ' ')
end

return Class.export(RoleOf, {exports = {'get'}})
