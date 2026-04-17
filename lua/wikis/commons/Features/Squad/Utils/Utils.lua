---
-- @Liquipedia
-- page=Module:Squad/Utils
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local SquadUtils = {}

---@param status string?
---@return SquadStatus?
function SquadUtils.statusToSquadStatus(status)
	if not status then
		return
	end
	return SquadUtils.StatusToSquadStatus[status:lower()]
end

---@param players {inactivedate: string|nil}[]
---@return boolean
function SquadUtils.anyInactive(players)
	return Array.any(players, function(player)
		return Logic.isNotEmpty(player.inactivedate)
	end)
end

---@param players ModelRow[]
---@param squadStatus SquadStatus
---@return table<string, boolean>
function SquadUtils.analyzeColumnVisibility(players, squadStatus)
	local isInactive = squadStatus == SquadUtils.SquadStatus.INACTIVE
		or squadStatus == SquadUtils.SquadStatus.FORMER_INACTIVE
	local isFormer = squadStatus == SquadUtils.SquadStatus.FORMER
		or squadStatus == SquadUtils.SquadStatus.FORMER_INACTIVE

	return {
		teamIcon = Array.any(players, function(p)
			return p.extradata.loanedto and TeamTemplate.exists(p.extradata.loanedto)
		end),
		name = Array.any(players, function(p)
			return String.isNotEmpty(p.name)
		end),
		role = Array.any(players, function(p)
			return p.role or p.position
		end),
		joindate = Array.any(players, function(p)
			return p.joindate
		end),
		inactivedate = isInactive and Array.any(players, function(p)
			return p.inactivedate
		end),
		activeteam = isInactive and Array.any(players, function(p)
			return  p.extradata.activeteam and TeamTemplate.exists(p.extradata.activeteam)
		end),
		leavedate = isFormer and Array.any(players, function(p)
			return p.leavedate
		end),
		newteam = isFormer and Array.any(players, function(p)
			return p.newteam or p.newteamrole or p.newteamspecial
		end),
	}
end

return SquadUtils
