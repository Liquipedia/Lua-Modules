---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FeatureFlag = require('Module:FeatureFlag')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Match = Lua.import('Module:Match', {requireDevIfEnabled = true})

local MatchGroupBase = {}

function MatchGroupBase.readOptions(args, matchGroupType)
	local store = Logic.readBoolOrNil(args.store)
	local options = {
		bracketId = MatchGroupBase.readBracketId(args.id),
		matchGroupType = matchGroupType,
		shouldWarnMissing = Logic.nilOr(Logic.readBoolOrNil(args.warnMissing), true),
		show = not Logic.readBool(args.hide),
		storeMatch1 = Logic.nilOr(Logic.readBoolOrNil(args.storeMatch1), store, true),
		storeMatch2 = Logic.nilOr(Logic.readBoolOrNil(args.storeMatch2), store, true),
		storeSmw = Logic.nilOr(Logic.readBoolOrNil(args.storeSmw), store, true),
	}
	options.store = Logic.nilOr(store, options.storeMatch2 or options.storeMatch1 or options.storeSmw)

	local warnings = {}

	if options.store or not Logic.readBool(args.noDuplicateCheck) then
		local warning = MatchGroupBase._checkBracketDuplicate(options.bracketId)
		if warning then
			table.insert(warnings, warning)
		end
	end

	if Logic.readBool(args.isLegacy) then
		if matchGroupType == 'matchlist' then
			table.insert(warnings, 'This is a legacy matchlist! Please use the new matchlist instead.')
		else
			table.insert(warnings, 'This is a legacy bracket! Please use the new bracket instead.')
		end
	end

	return options, warnings
end

function MatchGroupBase.readBracketId(baseBracketId)
	assert(baseBracketId, 'Argument \'id\' is empty')

	local _, message = MatchGroupBase.validateBaseBracketId(baseBracketId)
	if message then
		error(message)
	end

	return MatchGroupBase.getBracketIdPrefix() .. baseBracketId
end

function MatchGroupBase.validateBaseBracketId(baseBracketId)
	local subbed, count = baseBracketId:gsub('[0-9a-zA-Z]', '')
	if subbed ~= '' then
		return false, 'Bracket ID contains invalid characters (' .. subbed .. ')'
	elseif count ~= 10 then
		return false, 'Bracket ID has the wrong length (' .. count .. ' given, 10 characters expected)'
	end
	return true
end

--[[
Non-mainspace match groups are used for testing. Their IDs are prefixed with
the namespace so that they don't collide with mainspace IDs.
]]
function MatchGroupBase.getBracketIdPrefix()
	local namespace = mw.title.getCurrentTitle().nsText

	if namespace == 'User' then
		return namespace .. '_' .. mw.title.getCurrentTitle().rootText .. '_'
	elseif namespace ~= '' then
		return namespace .. '_'
	else
		return ''
	end
end

function MatchGroupBase._checkBracketDuplicate(bracketId)
	local status = mw.ext.Brackets.checkBracketDuplicate(bracketId)
	if status ~= 'ok' then
		local warning = 'This match group uses the duplicate ID \'' .. bracketId .. '\'.'
		local category = '[[Category:Pages with duplicate Bracketid]]'
		mw.addWarning(warning)
		return warning .. category
	end
end

function MatchGroupBase.saveMatchGroup(bracketId, matches, options)
	local recordsInMatches = Array.map(matches, Match.splitRecordsByType)

	-- Store matches in a page variable to bypass LPDB on the same page
	if options.show then
		local matchRecords = Array.map(recordsInMatches, function(records)
			Match.populateEdges(records)
			return records.matchRecord
		end)
		Variables.varDefine('match2bracket_' .. bracketId, Json.stringify(matchRecords))
		Variables.varDefine('match2bracketindex', Variables.varDefault('match2bracketindex', 0) + 1)
	end

	if options.store then
		for _, records in ipairs(recordsInMatches) do
			Match.store(records, options)
		end
	end
end

function MatchGroupBase.enableInstrumentation()
	if FeatureFlag.get('perf') then
		local config = Lua.loadDataIfExists('Module:MatchGroup/Config')
		local perfConfig = Table.getByPathOrNil(config, {'perf'}) or {}
		require('Module:Performance/Util').startInstrumentation(perfConfig)
	end
end

function MatchGroupBase.disableInstrumentation()
	if FeatureFlag.get('perf') then
		require('Module:Performance/Util').stopAndSave()
	end
end

-- Deprecated
function MatchGroupBase.luaMatchlist(_, args)
	local MatchGroupDisplay = Lua.import('Module:MatchGroup/Display', {requireDevIfEnabled = true})
	return MatchGroupDisplay.MatchlistBySpec(args) .. MatchGroupDisplay.deprecatedCategory
end

-- Deprecated
function MatchGroupBase.luaBracket(_, args)
	local MatchGroupDisplay = Lua.import('Module:MatchGroup/Display', {requireDevIfEnabled = true})
	return MatchGroupDisplay.BracketBySpec(args) .. MatchGroupDisplay.deprecatedCategory
end

return MatchGroupBase
