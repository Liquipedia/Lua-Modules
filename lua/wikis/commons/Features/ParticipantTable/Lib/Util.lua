---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Lib/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Opponent = Lua.import('Module:Opponent/Custom')

local Util = {}

---@param section ParticipantTableSection
function Util.backFillEntries(section)
	local config = section.config
	Array.forEach(section.entries, function(entry)
		entry.sortName = entry.sortName or Opponent.toName(entry.opponent)
		entry.opponent = entry.isResolved and entry.opponent or Opponent.resolve(entry.opponent, config.resolveDate, {
			syncPlayer = config.syncPlayers,
			overwritePageVars = true,
		})
		entry.name = entry.name or Opponent.toName(entry.opponent)
		entry.isResolved = true
	end)
end

---@param section ParticipantTableSection
function Util.sortOpponents(section)
	if not section.config.sortOpponents then return end
	Array.sortInPlaceBy(section.entries, function(entry)
		return entry.sortName:lower()
	end)
end

---@param sections ParticipantTableSection[]
---@return boolean
function Util.hasSeed(sections)
	return Array.any(sections, function(section)
		return Array.any(section.entries, function(entry)
			return entry.seed ~= nil
		end)
	end)
end

return Util
