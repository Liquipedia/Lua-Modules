---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchGroup = Lua.import('Module:MatchGroup')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local MatchSubobjects = Lua.import('Module:Match/Subobjects')

local globalVars = PageVariableNamespace()

local MAX_NUMBER_OF_OPPONENTS = 2
local RESET_MATCH = 'RxMBR'
local THIRD_PLACE_MATCH = 'RxMTP'

---@alias roundKeys {R: number, G: number, W: number, D: number}
---@alias match1Keys {opp1: string, opp2: string, details: string, header: string?}
---@alias match2mapping {[string]: match1Keys}|{[string] : string}

---@class MatchGroupLegacy
---@operator call(table): MatchGroupLegacy
---@field args table
---@field bracketType string
---@field newArgs table
---@field mapMappings {[number]: table}
local MatchGroupLegacy = Class.new(function(self, frame)
	local args = Arguments.getArgs(frame)
	assert(String.isNotEmpty(args.id), 'Argument \'id\' is empty')
	assert(String.isNotEmpty(args.template), 'Argument \'template\' is empty')
	assert(String.isNotEmpty(args.templateOld), 'Argument \'templateOld\' is empty')
	assert(String.isNotEmpty(args.type), 'Argument \'type\' is empty')

	self.args = args
end)

---@param match match2
---@param match2mapping match2mapping
---@param lowerHeaders {[number] : number}
---@param lastRound roundKeys
---@param roundData {[number]: roundKeys}
---@return roundKeys, number
function MatchGroupLegacy._getMatchMapping(match, match2mapping, lowerHeaders, lastRound, roundData)
	local _, baseMatchId = MatchGroupUtil.splitMatchId(match.match2id)
	---@cast baseMatchId -nil
	local id = MatchGroupUtil.matchIdToKey(baseMatchId)

	local roundNum
	local round
	local isReset = false
	if id == THIRD_PLACE_MATCH then
		round = lastRound
	elseif id == RESET_MATCH then
		round = lastRound
		round.G = round.G - 2
		round.W = round.W - 2
		round.D = round.D - 2
		isReset = true
	else
		roundNum = id:match('R%d*'):gsub('R', '')
		roundNum = tonumber(roundNum)
		round = roundData[roundNum] or { R = roundNum, G = 0, D = 1, W = 1 }
	end
	round.G = round.G + 1

	local bd = match.match2bracketdata
	--if bd.header starts with '!l'
	if string.match(bd.header or '', '^!l') then
		lowerHeaders[roundNum or ''] = round.G
	end

	local match1Keys = {}
	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function (opponentIndex)
		local prefix
		if not isReset and
			(Logic.isEmpty(bd.toupper) and opponentIndex == 1 or
			Logic.isEmpty(bd.tolower) and opponentIndex == 2) then

			prefix = 'R' .. round.R .. 'D' .. round.D
			round.D = round.D + 1
		else
			prefix = 'R' .. round.R .. 'W' .. round.W
			round.W = round.W + 1
		end

		match1Keys['opp' .. opponentIndex] = prefix
	end)
	match1Keys['details'] = 'R' .. round.R .. 'G' .. round.G

	match2mapping[id] = match1Keys

	roundData[round.R] = round

	return round, round.R
end

---@param template string
---@return match2mapping
function MatchGroupLegacy.get(template)
	local matches = mw.ext.Brackets.getCommonsBracketTemplate(template)
	assert(type(matches) == 'table')

	local match2mapping = {}
	local lowerHeaders = {}
	local roundData = {}
	local lastRound = {}
	local lastRoundIndex = 0
	Array.forEach(matches, function (match2)
		lastRound, lastRoundIndex = MatchGroupLegacy._getMatchMapping(match2, match2mapping, lowerHeaders,
			lastRound, roundData)
	end)

	Array.forEach(Array.range(1, lastRoundIndex), function (roundIndex)
		match2mapping['R' .. roundIndex .. 'M1header'] = 'R' .. roundIndex
		if lowerHeaders[roundIndex] then
			match2mapping['R' .. roundIndex .. 'M' .. lowerHeaders[roundIndex] .. 'header'] = 'L' .. roundIndex
		end
	end)

	return match2mapping
end

---@param match1params match1Keys
---@return match1Keys
function MatchGroupLegacy.matchMappingFromCustom(match1params)
	return match1params
end

---@return match1Keys
---@param match1params match1Keys
function MatchGroupLegacy.matchResetMappingFromCustom(match1params)
	return match1params
end

---@param blueprint table
---@param tbl table
---@param delete boolean?
---@return table
function MatchGroupLegacy:_copyAndReplace(blueprint, tbl, delete)
	local newObject = {}
	Table.iter.forEachPair(blueprint, function (key, val)
		newObject[key] = delete and Table.extract(tbl, val) or tbl[val]
	end)

	return newObject
end

---@param prefix string
---@param scoreKey string
---@return table
function MatchGroupLegacy:getOpponent(prefix, scoreKey)
	return {
		['$notEmpty$'] = self.bracketType == 'team' and (prefix .. 'team') or prefix,
		template = prefix .. 'team',
		score = prefix .. scoreKey,
		name = prefix,
		displayname = prefix .. 'display',
		flag = prefix .. 'flag',
		win = prefix .. 'win',
	}
end

---@param mapIndex number
---@return table
function MatchGroupLegacy:_getMap(mapIndex)
	if self.mapMappings[mapIndex] then
		return self.mapMappings[mapIndex]
	end

	local mapping = {}
	Table.iter.forEachPair(self:getMap(), function (key, val)
		val = val:gsub('%$1%$',mapIndex, 1)
		mapping[key] = val
	end)

	self.mapMappings[mapIndex] = mapping
	return mapping
end

---@return table
function MatchGroupLegacy:getMap()
	return {}
end

---@param isReset boolean
---@param prefix string
---@return table
function MatchGroupLegacy:getDetails(isReset, prefix)
	local detailsKey = isReset and 'resetDetails' or prefix .. 'details'
	local details = Table.extract(self.args, detailsKey)
	if details then
		return (Json.parse(details))
	end

	return {}
end

---@param opponentData table
---@return table
function MatchGroupLegacy:readOpponent(opponentData)
	local opponent = self:_copyAndReplace(opponentData, self.args)
	opponent.type = self.bracketType
	return opponent
end

---@param isReset boolean
---@param match1params match1Keys
---@param match table
function MatchGroupLegacy:handleOpponents(isReset, match1params, match)
	local scoreKey = isReset and 'score2' or 'score'
	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function (opponentIndex)
		local opp = self:getOpponent(match1params['opp' .. opponentIndex], scoreKey)
		if Logic.isEmpty(self.args[opp['$notEmpty$']]) then return end

		opp['$notEmpty$'] = nil
		match['opponent' .. opponentIndex] = self:readOpponent(opp)
	end)
end

---@param details table
---@param mapIndex number
---@return table?
function MatchGroupLegacy:handleMap(details, mapIndex)
	local blueprint = self:_getMap(mapIndex)
	if Logic.isEmpty(details[blueprint['$notEmpty$']]) then
		return nil
	end

	local map
	if details[blueprint['$parse$']] then
		map = Json.parseIfTable(Table.extract(details, blueprint['$parse$'])) or {}
	else
		blueprint = Table.copy(blueprint)
		blueprint['$notEmpty$'] = nil
		map = self:_copyAndReplace(blueprint, details, true)
	end

	return MatchSubobjects.luaGetMap(map)
end

---@param isReset boolean
---@param match1params match1Keys
---@param match table
function MatchGroupLegacy:handleDetails(isReset, match1params, match)
	local details = self:getDetails(isReset, match1params.details)
	Array.mapIndexes(function (mapIndex)
		local map = self:handleMap(details, mapIndex)
		match['map' .. mapIndex] = map
		return map
	end)

	Table.deepMergeInto(match, details)
end

---@param isReset boolean
---@param match table
function MatchGroupLegacy:handleFinished(isReset, match)
	if isReset then return end
	match['finished'] = String.isNotEmpty(((match.opponent1 or {}).win or '') ..
		((match.opponent2 or {}).win or ''))
end

---@param isReset boolean
---@param match table
function MatchGroupLegacy:handleOtherMatchParams(isReset, match)
end

---@param match2key string
---@param match1params match1Keys
function MatchGroupLegacy:getMatch(match2key, match1params)
	local isReset = match2key == RESET_MATCH
	local isValidReset = false
	local match = {}

	self:handleOpponents(isReset, match1params, match)
	self:handleDetails(isReset, match1params, match)
	self:handleFinished(isReset, match)
	self:handleOtherMatchParams(isReset, match)
	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function (opponentIndex)
		local opponent = match['opponent' .. opponentIndex] or {}
		match.winner = match.winner or opponent.win and opponentIndex or nil
		isValidReset = isValidReset or Logic.isNotEmpty(opponent.score)
	end)

	if isReset and not isValidReset then
		return nil
	elseif match2key == THIRD_PLACE_MATCH then
		if Logic.isEmpty(match.opponent1) and Logic.isEmpty(match.opponent2) then
			return nil
		end
	end
	return match
end

---@param match2mapping match2mapping
function MatchGroupLegacy:_populateNewArgs(match2mapping)
	Table.iter.forEachPair(match2mapping, function (match2key, val)
		if String.contains(match2key, 'header') then
			---@cast val string
			self.newArgs[match2key] = self.newArgs[match2key] or self.args[val]
		else
			---@cast val match1Keys
			if val.header then
				self.newArgs[match2key .. 'header'] = self.args[val.header]
			end
			self.newArgs[match2key] = self:getMatch(match2key, val)
		end
	end)
end

---@param templateid string
---@param oldTemplateid string?
---@return table
function MatchGroupLegacy._get(templateid, oldTemplateid)
	if Lua.moduleExists('Module:MatchGroup/Legacy/' .. templateid) then
		mw.log('Module:MatchGroup/Legacy/' .. templateid .. ' exists')
		return (require('Module:MatchGroup/Legacy/' .. templateid)[oldTemplateid] or function() return nil end)()
			or MatchGroupLegacy.get(templateid)
	else
		return MatchGroupLegacy.get(templateid)
	end
end

function MatchGroupLegacy:handleOtherBracketParams()
end

---@param args table
---@return boolean
function MatchGroupLegacy:shouldStoreData(args)
	return Logic.nilOr(
		Logic.readBoolOrNil(args.store),
		not Logic.readBool(globalVars:get('disable_LPDB_storage'))
	)
end

---@return string
function MatchGroupLegacy:build()
	mw.addWarning('You are editing a page that uses a Legacy Bracket. '
		.. 'Please use the new Bracket System on new pages.')

	local args = self.args

	local match2mapping = MatchGroupLegacy._get(args.template, args.templateOld)

	self.bracketType = args.type
	self.newArgs = {
		args.template,
		id = args.id,
		store = self:shouldStoreData(args),
		noDuplicateCheck = args.noDuplicateCheck,
		isLegacy = true
	}
	self.mapMappings = {}

	self:_populateNewArgs(match2mapping)
	self:handleOtherBracketParams()

	return MatchGroup.Bracket(self.newArgs)
end

return MatchGroupLegacy
