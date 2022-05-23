---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local MatchGroupBase = {}

function MatchGroupBase.readOptions(args, matchGroupType)
	local store = Logic.readBoolOrNil(args.store)
	local show = not Logic.readBool(args.hide)
	local options = {
		bracketId = MatchGroupBase.readBracketId(args.id),
		matchGroupType = matchGroupType,
		shouldWarnMissing = Logic.nilOr(Logic.readBoolOrNil(args.warnMissing), true),
		show = show,
		storeMatch1 = Logic.nilOr(Logic.readBoolOrNil(args.storeMatch1), store, true),
		storeMatch2 = Logic.nilOr(Logic.readBoolOrNil(args.storeMatch2), store, true),
		storePageVar = Logic.nilOr(Logic.readBoolOrNil(args.storePageVar), show),
		storeSmw = Logic.nilOr(Logic.readBoolOrNil(args.storeSmw), store, true),
	}

	local warnings = {}

	if options.storeMatch2 or not Logic.readBool(args.noDuplicateCheck) then
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
	if MatchGroupBase._isduplicate(bracketId) then
		local warning = 'This match group uses the duplicate ID \'' .. bracketId .. '\'.'
		local category = '[[Category:Pages with duplicate Bracketid]]'
		mw.addWarning(warning)
		return warning .. category
	end
end

function MatchGroupBase._isduplicate(bracketId)
	-- if the bracketId is already used on the same page then the according variable is set
	if String.isNotEmpty(Variables.varDefault('match2bracket_' .. bracketId)) then
		return true
	end
	-- if the bracketId is not used on this page we need to check if it is used
	-- on another page in the same namespace
	local page = mw.title.getCurrentTitle()

	local queryData = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = '[[namespace::' .. page.namespace .. ']]'
			.. ' AND [[pagename::!' .. page.text:gsub(' ', '_') .. ']]'
			.. ' AND [[match2bracketid::' .. bracketId .. ']]',
		query = 'pagename, namespace',
	})
	if type(queryData) == 'table' and queryData[1] then
		mw.logObject(queryData, 'Pages with the same bracketId')
		return true
	end

	return false
end

-- Deprecated
function MatchGroupBase.luaMatchlist(_, args)
	local MatchGroup = Lua.import('Module:MatchGroup', {requireDevIfEnabled = true})
	return MatchGroup.MatchList(args) .. MatchGroup.deprecatedCategory
end

-- Deprecated
function MatchGroupBase.luaBracket(_, args)
	local MatchGroup = Lua.import('Module:MatchGroup', {requireDevIfEnabled = true})
	return MatchGroup.Bracket(args) .. MatchGroup.deprecatedCategory
end

return MatchGroupBase
