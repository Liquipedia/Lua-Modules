---
-- @Liquipedia
-- page=Module:Features/Squad/Lib/History
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local SquadTypes = Lua.import('Module:Features/Squad/Types')
local TeamHistory = Lua.import('Module:Domain/TeamHistory/Model')

local TransferType = TeamHistory.TransferType
local ROLE_INACTIVE = SquadTypes.ROLE_INACTIVE

--- Answers "was this person on the team, and when" from transfer records.
--- Pure: it neither queries nor renders anything, it only reads records and returns history.
local SquadHistory = {}

---Walks a person's team history as join -> [inactive] -> leave and returns the stints it found.
---@private
---@param entries TeamHistoryEntry[]
---@return SquadHistorySelection
function SquadHistory._selectFormerStints(entries)
	local stints = {}
	local warnings = {}
	local hasFormerInactiveEntry = false

	local joinEntry, inactiveEntry

	Array.forEach(entries, function (entry)
		if entry.type == TransferType.JOIN then
			if joinEntry then
				table.insert(warnings, {reason = 'Invalid entry: Duplicate JOIN. Skipping', entry = entry})
				return
			end
			joinEntry = entry
			return
		end
		if not joinEntry then
			table.insert(warnings, {reason = 'Invalid entry: Missing previous JOIN. Skipping', entry = entry})
			return
		end

		if entry.type == TransferType.CHANGE and entry.toRole == ROLE_INACTIVE then
			-- Enable the Inactive Date display in Former Squad tables
			hasFormerInactiveEntry = true
			-- Keep the transfer that took them off the active squad. Further inactive transfers
			-- before they leave are role changes made while already inactive, so they do not move
			-- the inactive date. Becoming active again ends the row and clears this.
			inactiveEntry = inactiveEntry or entry
			return
		end

		table.insert(stints, {joinEntry = joinEntry, inactiveEntry = inactiveEntry, leaveEntry = entry})
		joinEntry = nil
		inactiveEntry = nil

		if entry.type == TransferType.CHANGE then
			joinEntry = entry
		end
	end)

	return {stints = stints, warnings = warnings, hasFormerInactiveEntry = hasFormerInactiveEntry}
end

---Selects the stints of one person's team history that belong in a squad table of a given status.
---For (in)active tables at most one stint is returned, for former tables there may be several.
---Returns nothing when the history holds no row for a table of this status, which also covers an
---unrecognized status.
---@param entries TeamHistoryEntry[]
---@param squadStatus SquadStatus?
---@return SquadHistorySelection?
function SquadHistory.selectStints(entries, squadStatus)
	if squadStatus == SquadTypes.SquadStatus.ACTIVE then
		-- Only most recent transfer is relevant
		local last = entries[#entries]
		if last and (last.type == TransferType.CHANGE or last.type == TransferType.JOIN)
				and last.toRole ~= ROLE_INACTIVE then
			-- When the last transfer is a leave transfer, or the role is inactive, the person wouldn't be active
			return {stints = {{joinEntry = last}}, warnings = {}, hasFormerInactiveEntry = false}
		end
	end

	if squadStatus == SquadTypes.SquadStatus.INACTIVE then
		local last, secondToLast = entries[#entries], entries[#entries - 1]
		if secondToLast and last.type == TransferType.CHANGE and last.toRole == ROLE_INACTIVE then
			return {
				stints = {{joinEntry = secondToLast, inactiveEntry = last}},
				warnings = {},
				hasFormerInactiveEntry = false,
			}
		end
	end

	if squadStatus == SquadTypes.SquadStatus.FORMER or squadStatus == SquadTypes.SquadStatus.FORMER_INACTIVE then
		return SquadHistory._selectFormerStints(entries)
	end

	return nil
end

return SquadHistory
