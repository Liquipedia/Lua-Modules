---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local PageVariableNamespace = require('Module:PageVariableNamespace')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

local globalVars = PageVariableNamespace()

local USER_SPACE = 2

---@class StarcraftMatchGroupLegacyDefault: MatchGroupLegacy
local MatchGroupLegacyDefault = Class.new(MatchGroupLegacy)

---@param prefix string
---@param scoreKey string
---@return table
function MatchGroupLegacyDefault:getOpponent(prefix, scoreKey)
	return {
		['$notEmpty$'] = prefix,
		name = prefix,
		flag = prefix .. 'flag',
		race = prefix .. 'race',
		score = prefix .. scoreKey,
		win = prefix .. 'win',
	}
end

---@return table
function MatchGroupLegacyDefault:getMap()
	return {
		['$notEmpty$'] = 'map$1$',
		map = 'map$1$',
		winner = 'map$1$win',
		race1 = 'map$1$p1race',
		race2 = 'map$1$p2race'
	}
end

---@param opponentData table
---@return table
function MatchGroupLegacyDefault:readOpponent(opponentData)
	local opponent = self:_copyAndReplace(opponentData, self.args)
	opponent.type = self.bracketType

	local scoreAdvantage, scoreSum = string.match(opponent.score or '',
			'<abbr title="[wW]inners?\'?s? [bB]racket [Aa]dvantage of (%d+) %a+">(%d+)</abbr>')

	if scoreAdvantage then
		opponent.score = scoreSum
		opponent.advantage = scoreAdvantage
	end

	return opponent
end

---@param args table
---@return boolean
function MatchGroupLegacyDefault:shouldStoreData(args)
	local namespaceNumber = mw.title.getCurrentTitle().namespace
	return Logic.nilOr(
		Logic.readBoolOrNil(args.store),
		namespaceNumber ~= USER_SPACE and not Logic.readBool(globalVars:get('disable_LPDB_storage'))
	)
end

---@param frame Frame
---@return string
function MatchGroupLegacyDefault.run(frame)
	return MatchGroupLegacyDefault(frame):build()
end

return MatchGroupLegacyDefault
