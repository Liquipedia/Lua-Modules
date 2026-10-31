---
-- @Liquipedia
-- page=Module:Features/TournamentAppearances/Lib/ParseQueried
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local Placement = Lua.import('Module:Placement')

local ParseQueried = {}

function ParseQueried.fromPlacement(players, config, placement)
	local opponent = Opponent.fromLpdbStruct(placement)
	-- todo: support opponent case

	---@param player standardPlayer
	local function processPlayer(player)
		if Opponent.playerIsTbd(player) then
			return
		end
		local pageName = player.pageName
		---@cast pageName -nil
		if not players[pageName] then
			players[pageName] = player
			player.extradata = player.extradata or {}
			player.extradata.appearances = 0
			player.extradata.placementSum = 0
			player.extradata.results = {}
		end

		local extradata = players[pageName].extradata --[[ @as table ]]

		extradata.appearances = extradata.appearances + 1
		extradata.results[placement.parent] = {
			placement = placement.placement,
			date = placement.date,
			team = opponent.type == Opponent.team and opponent.template or player.team
		}
		local rawPlacement = Placement.raw(placement.placement)
		extradata.placementSum = extradata.placementSum + (tonumber(rawPlacement.placement[1]) or 1000)
	end

	if config.player then
		Array.forEach(opponent.players, processPlayer)
	end
	if config.staff then
		Array.forEach(Array.mapIndexes(function (index)
			return Logic.nilIfEmpty(Opponent.staffFromLpdbStruct(placement.opponentplayers, index))
		end), processPlayer)
	end
end

---@param a standardPlayer
---@param b standardPlayer
---@return boolean
function ParseQueried.sort(a, b)
	local aData = a.extradata or {}
	local bData = b.extradata or {}
	if aData.appearances ~= bData.appearances then
		return aData.appearances > bData.appearances
	elseif aData.placementSum ~= bData.placementSum then
		return aData.placementSum < bData.placementSum
	end
	--todo: account for opponent case
	return a.pageName < b.pageName
end

return ParseQueried
