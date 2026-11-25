---
-- @Liquipedia
-- page=Module:Features/Squad/Lib/Columns
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local String = Lua.import('Module:StringUtils')
local SquadTypes = Lua.import('Module:Features/Squad/Types')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local SquadColumns = {}

---@param players ModelRow[]
---@param squadStatus SquadStatus
---@return table<string, boolean>
function SquadColumns.analyzeColumnVisibility(players, squadStatus)
	local isInactive = squadStatus == SquadTypes.SquadStatus.INACTIVE
		or squadStatus == SquadTypes.SquadStatus.FORMER_INACTIVE
	local isFormer = squadStatus == SquadTypes.SquadStatus.FORMER
		or squadStatus == SquadTypes.SquadStatus.FORMER_INACTIVE

	return {
		teamIcon = Array.any(players, function(p)
			return p.extradata.loanedto
		end),
		name = Array.any(players, function(p)
			return String.isNotEmpty(p.name)
		end),
		role = Array.any(players, function(p)
			local role = String.nilIfEmpty(p.role) or String.nilIfEmpty(p.position)
			return role ~= nil and role ~= 'Captain' and role ~= 'Sub'
		end),
		joindate = Array.any(players, function(p)
			return String.isNotEmpty(p.joindate)
		end),
		inactivedate = isInactive and Array.any(players, function(p)
			return String.isNotEmpty(p.inactivedate)
		end),
		activeteam = isInactive and Array.any(players, function(p)
			return p.extradata.activeteam and TeamTemplate.exists(p.extradata.activeteam)
		end),
		leavedate = isFormer and Array.any(players, function(p)
			return String.isNotEmpty(p.leavedate)
		end),
		newteam = isFormer and Array.any(players, function(p)
			return String.isNotEmpty(p.newteam)
				or String.isNotEmpty(p.newteamrole)
				or String.isNotEmpty(p.extradata.newteamspecial)
		end),
	}
end

return SquadColumns
