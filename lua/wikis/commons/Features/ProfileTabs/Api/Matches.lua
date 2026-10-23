---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Api/Matches
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
-- LPDB checks for profile match data.

local Lua = require('Module:Lua')

local Condition = Lua.import('Module:Condition')
local Table = Lua.import('Module:Table')

local PROFILE_TYPES = Lua.import('Module:Features/ProfileTabs/Types')

local ProfileTabsApiMatches = {}

---Checks whether the player/team has matches stored in lpdb.
---@param profileType string
---@param profile string
---@return boolean
function ProfileTabsApiMatches.has(profileType, profile)
	local field = PROFILE_TYPES[profileType].matchFilterField

	local conditions = Condition.Util.anyOf(field, {profile}):toString()

	local matches = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = conditions,
		limit = 1,
	})

	return Table.isNotEmpty(matches)
end

return ProfileTabsApiMatches