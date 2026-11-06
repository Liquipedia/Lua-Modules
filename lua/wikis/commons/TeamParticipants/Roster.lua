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
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')

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

---@param player standardPlayer
---@param played boolean
local function setPlayed(player, played)
	local extradata = player.extradata
	if not extradata or extradata.type == 'staff' or extradata.played ~= nil then
		return
	end
	extradata.played = played
	if not played and extradata.results == nil then
		extradata.results = false
		-- keeps page vars so match lineups can still pick the player up
		extradata.autoDnp = true
	end
end

--- Sets unset `played` from match data; returns played pagenames missing from the roster.
---@param players standardPlayer[]
---@param playedPlayers table<string, boolean>
---@return string[]
function TeamParticipantsRoster.applyPlayed(players, playedPlayers)
	local onRoster = {}
	Array.forEach(players, function(player)
		local pageName = Page.pageifyLink(player.pageName)
		if pageName and not Opponent.playerIsTbd(player) then
			onRoster[pageName] = true
			setPlayed(player, playedPlayers[pageName] == true)
		end
	end)
	return Array.filter(Array.extractKeys(playedPlayers, Table.iter.spairs), function(pageName)
		return not onRoster[pageName]
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

return TeamParticipantsRoster
