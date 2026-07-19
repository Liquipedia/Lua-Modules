---
-- @Liquipedia
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

local CONVERT_PICK_BAN_ENTRY = {
	none = {},
	pick = {'pick'},
	ban = {'ban'},
	player = {'player'},
	['pick + ban'] = {'pick', 'ban'},
	['pick + player'] = {'player', 'pick'},
	['ban + player'] = {'player', 'ban'},
	all = {'player', 'pick', 'ban'},
}
local PARAM_TO_SHORT = {
	pick = 'c',
	ban = 'b',
	player = 'p',
}
local LIMIT_OF_PARAM = {
	pick = 3,
	ban = 3,
	player = 3,
}

---@class BrawlstarsMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = WikiCopyPaste.Indent

--returns the Code for a Match, depending on the input
---@param bestof integer
---@param mode string
---@param matchIndex integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getMatchCode(bestof, mode, matchIndex, opponents, args)
	local showScore = Logic.readBool(args.score)
	local numberOfCasters = tonumber(args.casters) or 2
	local numberOfGlobalBans = tonumber(args.globals) or 2

	local lines = Array.extend(
		'{{Match',
		matchIndex == 1 and (INDENT .. '|bestof=' .. (bestof ~= 0 and bestof or '')) or nil,
		Logic.readBool(args.hasDate) and {INDENT .. '|date=', INDENT .. '|twitch='} or {},
		numberOfCasters > 0 and Array.mapRange(1, numberOfCasters, function(casterIndex)
			return INDENT .. '|caster' .. casterIndex .. '='
		end) or {},
		Logic.readBool(args.hasVod) and (INDENT .. '|vod=') or nil,
		Array.mapRange(1, opponents, function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. WikiCopyPaste.getOpponent(mode, showScore)
		end),
		numberOfGlobalBans > 0 and WikiCopyPaste._globalBanParams(opponents, numberOfGlobalBans) or {}
	)

	Array.extendWith(lines, WikiCopyPaste._getMapVetoCode(args.mapVeto, args.customVeto))

	Array.forEach(Array.range(1, bestof), function(mapIndex)
		Array.extendWith(lines, WikiCopyPaste._getMapCode(args, matchIndex, opponents, mapIndex))
	end)

	table.insert(lines, '}}')

	return table.concat(lines, '\n')
end

--subfunction used to generate the code for the Map template
--sets up as many maps as specified via the bestoff param
---@param args table
---@param matchIndex integer
---@param numberOfOpponents integer
---@param mapIndex integer
---@return string[]
function WikiCopyPaste._getMapCode(args, matchIndex, numberOfOpponents, mapIndex)
	local lines = {
		INDENT .. '|map' .. mapIndex .. '={{Map',
		INDENT .. INDENT .. '|map=|maptype=|firstpick=',
		INDENT .. INDENT .. '|score1=|score2=',
	}

	Array.forEach(CONVERT_PICK_BAN_ENTRY[args.pickBan or ''] or {}, function(item)
		Array.extendWith(lines, WikiCopyPaste._pickBanParams(item, numberOfOpponents))
	end)

	--first map has additional mapBestof if it is the first match
	if matchIndex == 1 and mapIndex == 1 and String.isNotEmpty(args.mapBestof) then
		Array.appendWith(lines, INDENT .. INDENT .. '|bestof=' .. args.mapBestof)
	end

	return Array.append(lines, INDENT .. '}}')
end

---@param mapVeto string
---@param customVeto string
---@return string[]
function WikiCopyPaste._getMapVetoCode(mapVeto, customVeto)
	if mapVeto == 'none' then
		return {}
	end

	assert(
		mapVeto ~= 'custom' or String.isNotEmpty(customVeto),
		'Custom map veto is empty. Example: pick,ban,decider,default'
	)

	local vetoTypes = mapVeto == 'custom' and customVeto or mapVeto
	vetoTypes = string.gsub(vetoTypes, '%-', ',')

	local types = Array.parseCommaSeparatedString(vetoTypes)
	vetoTypes = table.concat(types, ',')

	local lines = {
		INDENT .. '|mapveto={{MapVeto',
		INDENT .. INDENT .. '|firstpick=1',
		INDENT .. INDENT .. '|types=' .. vetoTypes,
	}

	local mapNumber = 1
	local deciderAdded = false

	Array.forEach(types, function(vetoType)
		assert(
			vetoType == 'pick'
				or vetoType == 'ban'
				or vetoType == 'default'
				or vetoType == 'decider',
			'Unknown map veto type "' .. vetoType ..
				'". Expected a comma-separated list using only: pick, ban, decider, default. ' ..
				'Example: pick,ban,decider,default'
		)

		if vetoType == 'pick' or vetoType == 'ban' then
			table.insert(lines,
				INDENT .. INDENT .. '|t1map' .. mapNumber .. '=|t2map' .. mapNumber .. '='
			)
			mapNumber = mapNumber + 1
		elseif vetoType == 'default' or vetoType == 'decider' then
			if not deciderAdded then
				table.insert(lines, INDENT .. INDENT .. '|decider=')
				deciderAdded = true
			end
		end
	end)

	table.insert(lines, INDENT .. '}}')

	return lines
end

---@param key string
---@param numberOfOpponents integer
---@return string[]
function WikiCopyPaste._pickBanParams(key, numberOfOpponents)
	local shortKey = PARAM_TO_SHORT[key]
	local limit = LIMIT_OF_PARAM[key]

	return Array.mapRange(1, numberOfOpponents, function(opponentIndex)
		return INDENT .. INDENT .. table.concat(Array.mapRange(1, limit, function(keyIndex)
			return '|t' .. opponentIndex .. shortKey .. keyIndex .. '='
		end))
	end)
end

---@param numberOfOpponents integer
---@param numberOfGlobals integer
---@return string[]
function WikiCopyPaste._globalBanParams(numberOfOpponents, numberOfGlobals)
	return {
		INDENT .. table.concat(Array.mapRange(1, numberOfOpponents, function(opponentIndex)
			return table.concat(Array.mapRange(1, numberOfGlobals, function(globalIndex)
				return '|t' .. opponentIndex .. 'b' .. globalIndex .. '='
			end))
		end))
	}
end

return WikiCopyPaste
