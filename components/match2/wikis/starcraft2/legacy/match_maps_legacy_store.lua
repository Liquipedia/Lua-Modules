---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Match maps/LegacyStore
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Match = require('Module:Match')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Template = require('Module:Template')
local WarningBox = require('Module:WarningBox')

local MatchGroupBase = Lua.import('Module:MatchGroup/Base', {requireDevIfEnabled = true})

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local MatchMapsLegacyStore = {}

function MatchMapsLegacyStore.init(frame)
	local args = Arguments.getArgs(frame)
	return MatchMapsLegacyStore._init(args)
end

function MatchMapsLegacyStore._init(args)
	local store = Logic.nilOr(
		Logic.readBoolOrNil(args.store),
		not Logic.readBool(globalVars:get('disable_SMW_storage'))
	)

	local warnings = {}
	table.insert(warnings, 'This is a legacy matchlist! Please use the new matchlist instead.')

	if store then
		local bracketId = MatchGroupBase.readBracketId(args.id)
		table.insert(warnings, MatchGroupBase._checkBracketDuplicate(bracketId) or nil)
		matchlistVars:set('bracketid', bracketId)
	end

	matchlistVars:set('matchListTitle', args.title or args[1] or 'Match List')
	matchlistVars:set('warnings', Json.stringify(warnings))
	matchlistVars:set('store', store and 'true' or nil)
end

function MatchMapsLegacyStore.close()
	local bracketId = matchlistVars:get('bracketid')

	local matches = Template.retrieveReturnValues('LegacyMatchlist')

	for matchIndex, match in ipairs(matches) do
		local matchid = string.format('%04d', matchIndex)

		local nextMatchId = matchIndex ~= #matches
			and bracketId .. '_' .. string.format('%04d', matchIndex + 1)
			or nil

		-- Make bracket data
		local bd = {}
		bd['type'] = 'matchlist'
		bd['next'] = nextMatchId
		bd['title'] = matchIndex == 1 and matchlistVars:get('matchListTitle') or nil
		bd['bracketindex'] = tonumber(globalVars:get('match2bracketindex')) or 0
		match['bracketdata'] = bd

		-- set matchid and bracketid
		match['matchid'] = matchid
		match['bracketid'] = bracketId

		-- store match
		Match.store(match, true)
	end

	local warnings = Json.parseIfString(matchlistVars:get('warnings')) or {}

	globalVars:set('match2bracketindex', (globalVars:get('match2bracketindex') or 0) + 1)
	globalVars:set('match_number', 0)
	globalVars:delete('matchsection')
	matchlistVars:delete('warnings')
	matchlistVars:delete('store')
	matchlistVars:delete('bracketid')
	matchlistVars:delete('matchListTitle')

	return table.concat(Array.map(Array.map(warnings, WarningBox.display), tostring))
end

return MatchMapsLegacyStore

