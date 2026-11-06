---
-- @Liquipedia
-- page=Module:TeamParticipants/Roster
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local TeamParticipantsWikiParser = Lua.import('Module:TeamParticipants/Parse/Wiki')

local TeamParticipantsRoster = {}

--- Merges imported players into the manual list; manual entries win on conflicts.
---@param manualPlayers standardPlayer[]
---@param importedPlayers standardPlayer[]
function TeamParticipantsRoster.mergeImportedPlayers(manualPlayers, importedPlayers)
	Array.forEach(importedPlayers, function(player)
		local manualIndex = Array.indexOf(manualPlayers, function(p)
			return p.pageName == player.pageName
		end)

		if manualIndex == 0 then
			table.insert(manualPlayers, 1, player)
		else
			manualPlayers[manualIndex] = Table.deepMerge(player, manualPlayers[manualIndex])
		end
	end)
end

---@param opponent standardOpponent
---@param minimumPlayers number?
function TeamParticipantsRoster.fillIncompleteRoster(opponent, minimumPlayers)
	local expectedPlayerCount = minimumPlayers or (Info.config.participants or {}).defaultPlayerNumber
	if not expectedPlayerCount or not opponent.players then
		return
	end

	local activePlayerCount = #Array.filter(opponent.players, function(player)
		return player.extradata.type == 'player' and not player.extradata.status
	end)
	if activePlayerCount >= expectedPlayerCount then
		return
	end

	Array.extendWith(opponent.players, TeamParticipantsRoster.createTBDPlayers(expectedPlayerCount - activePlayerCount))
end

---@param count number
---@return standardPlayer[]
function TeamParticipantsRoster.createTBDPlayers(count)
	return Array.mapRange(1, count, function()
		return TeamParticipantsWikiParser.parsePlayer{'TBD'}
	end)
end

--- Defaults unset flags: `played` to true, `results` to `played`.
---@param player standardPlayer
function TeamParticipantsRoster.resolvePlayerFlags(player)
	local extradata = player.extradata or {}
	player.extradata = extradata
	extradata.results = Logic.nilOr(extradata.results, extradata.played, true)
	extradata.played = Logic.nilOr(extradata.played, true)
end

--- Sorts by the key tuples from `getKey`; ties keep input order.
---@generic T
---@param elements T[]
---@param getKey fun(element: T): any[]
---@return T[]
local function stableSortBy(elements, getKey)
	local indexOf = Table.map(elements, function(index, element) return element, index end)
	return Array.sortBy(elements, function(element)
		return Array.extend(getKey(element), indexOf[element])
	end)
end

---@param name string?
---@return string
local function sortName(name)
	return mw.ustring.lower(name or '')
end

---@param player standardPlayer
---@return number
local function getRoleSortOrder(player)
	local roles = player.extradata.roles or {}
	return roles[1] and roles[1].sortOrder or math.huge
end

--- Staff after players; then by name (TBD last) if alphabetical, else by role.
---@param players standardPlayer[]
---@param alphabetical boolean?
---@return standardPlayer[]
function TeamParticipantsRoster.sortPlayers(players, alphabetical)
	return stableSortBy(players, function(player)
		local staffOrder = player.extradata.type == 'staff' and 1 or 0
		if not alphabetical then
			return {staffOrder, getRoleSortOrder(player)}
		end
		return {staffOrder, Opponent.playerIsTbd(player) and 1 or 0, sortName(player.displayName)}
	end)
end

---@param participant TeamParticipant
---@return boolean
local function isTbdParticipant(participant)
	return Opponent.isTbd(participant.opponent) or Logic.isNotEmpty(participant.potentialQualifiers)
end

--- By displayed team name; TBD and contender cards last.
---@param participants TeamParticipant[]
---@return TeamParticipant[]
function TeamParticipantsRoster.sortParticipants(participants)
	return stableSortBy(participants, function(participant)
		local template = participant.opponent.template or ''
		local teamName = (TeamTemplate.getRawOrNil(template) or {}).name or template
		return {isTbdParticipant(participant) and 1 or 0, sortName(teamName)}
	end)
end

return TeamParticipantsRoster
