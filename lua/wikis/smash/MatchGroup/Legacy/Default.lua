---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')
local Mappings = Lua.import('Module:MatchGroup/Legacy/Mappings', {loadData = true})

local MAX_NUMBER_OF_OPPONENTS = 2

---@class SmashMatchGroupLegacyDefault: MatchGroupLegacy
---@operator call(Frame): SmashMatchGroupLegacyDefault
local MatchGroupLegacyDefault = Class.new(MatchGroupLegacy)

---@param template string
---@param bracketType string?
---@return match2mapping
function MatchGroupLegacyDefault.get(template, bracketType)
	return MatchGroupLegacy.getAlt(template, bracketType)
end

---@param template string
---@param templateOld string?
---@return match2mapping
function MatchGroupLegacyDefault:_get(template, templateOld)
	local config = Mappings[templateOld]
	-- fall back to the on-wiki mapping modules
	if not config or config.template ~= template then
		return MatchGroupLegacy._get(self, template, templateOld)
	end

	local mapping = MatchGroupLegacyDefault.get(config.template, self.bracketType)
	if config.lower then
		mapping = MatchGroupLegacy.toLowerBracket(mapping, config.roundOffset)
	end
	if config.resetRound then
		mapping = MatchGroupLegacy.withReset(mapping, config.resetRound)
	end
	for match2key, match1key in pairs(config.matches or {}) do
		mapping[match2key] = {details = match1key, opp1 = match1key .. 'p1', opp2 = match1key .. 'p2'}
	end
	for match2header, match1header in pairs(config.headers or {}) do
		mapping[match2header] = match1header
	end
	return mapping
end

---@param args table
function MatchGroupLegacyDefault._applyConfig(args)
	local config = Mappings[args.templateOld] or {}
	args.template = Logic.emptyOr(args.template, config.template)
	args.type = Logic.emptyOr(args.type, config.type, Opponent.solo)
end

---@param prefix string
---@param scoreKey string
---@return table
function MatchGroupLegacyDefault:getOpponent(prefix, scoreKey)
	if self.bracketType ~= Opponent.duo then
		return MatchGroupLegacy.getOpponent(self, prefix, scoreKey)
	end
	-- match1 doubles keys use t{n} for the side, e.g. r1m1t1p2
	local sidePrefix = prefix:gsub('p(%d)$', 't%1')
	return {
		['$notEmpty$'] = sidePrefix .. 'p1',
		p1 = sidePrefix .. 'p1',
		p1flag = sidePrefix .. 'p1flag',
		p2 = sidePrefix .. 'p2',
		p2flag = sidePrefix .. 'p2flag',
		score = sidePrefix .. scoreKey,
	}
end

---@param isReset boolean
---@param match1params match1Keys
---@param match table
function MatchGroupLegacyDefault:handleOpponents(isReset, match1params, match)
	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function (opponentIndex)
		local opp = self:getOpponent(match1params['opp' .. opponentIndex], 'score')
		if isReset then
			local sidePrefix = self.bracketType == Opponent.duo and 't' or 'p'
			opp.score = match1params['details'] .. sidePrefix .. opponentIndex .. 'score'
		end
		if Logic.isEmpty(self.args[opp['$notEmpty$']]) then return end

		opp['$notEmpty$'] = nil
		match['opponent' .. opponentIndex] = self:readOpponent(opp)
	end)
end

---@param isReset boolean
---@param prefix string
---@return table
function MatchGroupLegacyDefault:getDetails(isReset, prefix)
	local details = MatchGroupLegacy.getDetails(self, false, prefix)

	local isDuo = self.bracketType == Opponent.duo
	local charWithStock = function(charKey, stockKey)
		return Json.stringify{self.args[charKey] .. ',' .. (self.args[stockKey] or '')}
	end

	Table.iter.forEachPair(self.args, function (key)
		if not tonumber(key) and String.startsWith(key, prefix) then
			---@cast key string
			local duoPlayer, gameIndex = key:gsub(prefix, ''):match('^(t%dp%d)char(%d+)$')
			if isDuo and duoPlayer then
				details[duoPlayer .. 'char' .. gameIndex] = charWithStock(key, prefix .. duoPlayer .. 'stock' .. gameIndex)
			elseif String.contains(key, 'p1char') or String.contains(key, 'p2char') then
				local playerPrefix = key:gsub(prefix, ''):sub(1, 2)
				details[key:gsub(prefix, '')] = charWithStock(
					key, prefix .. playerPrefix .. 'stock' .. key:gsub(prefix .. playerPrefix, ''):sub(5)
				)
			else
				details[key:gsub(prefix, '')] = self.args[key]
			end
		end
	end)
	return details
end

---@return table
function MatchGroupLegacyDefault:getMap()
	if self.bracketType == Opponent.duo then
		return {
			['$notEmpty$'] = 'win$1$',
			winner = 'win$1$',
			map = 'stage$1$',
			o1c1 = 't1p1char$1$',
			o1c2 = 't1p2char$1$',
			o2c1 = 't2p1char$1$',
			o2c2 = 't2p2char$1$',
			vod = 'vodgame$1$',
		}
	end
	return {
		['$notEmpty$'] = 'win$1$',
		winner = 'win$1$',
		map = 'stage$1$',
		o1c1 = 'p1char$1$',
		o2c1 = 'p2char$1$',
		vod = 'vodgame$1$',
	}
end

---@param frame Frame
---@return string
function MatchGroupLegacyDefault.run(frame)
	MatchGroupLegacyDefault._applyConfig(frame.args)
	return MatchGroupLegacyDefault(frame):build()
end

---@param frame Frame
---@return string
function MatchGroupLegacyDefault.runGenerate(frame)
	local args = frame.args
	---@cast args -nil
	-- |<template>|<templateOld> or |<templateOld>
	if Logic.isNotEmpty(args[2]) then
		args.template = args[1]
		args.templateOld = args[2]
	else
		args.templateOld = Logic.emptyOr(args.templateOld, args[1])
	end
	MatchGroupLegacyDefault._applyConfig(args)

	return MatchGroupLegacyDefault(frame):generate()
end

return MatchGroupLegacyDefault
