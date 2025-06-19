---
-- @Liquipedia
-- page=Module:MatchGroup/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local Variables = Lua.import('Module:Variables')

local MatchGroupBase = {}

---@class MatchGroupBaseOptions
---@field bracketId string
---@field matchGroupType 'bracket'|'matchlist'
---@field shouldWarnMissing boolean
---@field show boolean
---@field storeMatch1 boolean
---@field storeMatch2 boolean
---@field storePageVar boolean

---@param args table
---@param matchGroupType string
---@return MatchGroupBaseOptions
---@return string[]
function MatchGroupBase.readOptions(args, matchGroupType)
	local currentTitle = mw.title.getCurrentTitle()
	local store = Logic.nilOr(Logic.readBoolOrNil(args.store),
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage')))
	local show = not Logic.readBool(args.hide)
	local options = {
		bracketId = MatchGroupBase.readBracketId(args.id),
		matchGroupType = matchGroupType,
		shouldWarnMissing = Logic.nilOr(Logic.readBoolOrNil(args.warnMissing), true),
		show = show,
		storeMatch1 = Logic.nilOr(Logic.readBoolOrNil(args.storeMatch1), store),
		storeMatch2 = Logic.nilOr(Logic.readBoolOrNil(args.storeMatch2), store),
		storePageVar = Logic.nilOr(Logic.readBoolOrNil(args.storePageVar), show),
	}

	local warnings = {}

	if options.storeMatch2 or not Logic.readBool(args.noDuplicateCheck) then
		local warning = MatchGroupBase._checkBracketDuplicate(options.bracketId)
		if warning then
			table.insert(warnings, warning)
		end
	end

	if not (Variables.varDefault('tournament_parent') or Namespace.isDocumentative(currentTitle)) then
		table.insert(warnings, 'Missing tournament context. Ensure the page has a InfoboxLeague or a HiddenDataBox.')
		local categoryPrefix = Namespace.isUser(currentTitle) and 'User space ' or ''
		mw.ext.TeamLiquidIntegration.add_category(categoryPrefix .. 'Pages with missing tournament context')
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

---@param baseBracketId string
---@return string
function MatchGroupBase.readBracketId(baseBracketId)
	assert(baseBracketId, 'Argument \'id\' is empty')

	local _, message = MatchGroupBase.validateBaseBracketId(baseBracketId)
	if message then
		error(message)
	end

	return MatchGroupBase.getBracketIdPrefix() .. baseBracketId
end

---@param baseBracketId string
---@return boolean
---@return string?
function MatchGroupBase.validateBaseBracketId(baseBracketId)
	local subbed, count = baseBracketId:gsub('[0-9a-zA-Z]', '')
	if subbed ~= '' then
		return false, 'Bracket ID contains invalid characters (' .. subbed .. ')'
	elseif count ~= 10 then
		return false, 'Bracket ID has the wrong length (' .. count .. ' given, 10 characters expected)'
	end
	return true
end

---Non-mainspace match groups are used for testing. Their IDs are prefixed with the namespace
---so that they don't collide with mainspace IDs.
---@return string
function MatchGroupBase.getBracketIdPrefix()
	local currentTitle = mw.title.getCurrentTitle()
	if Namespace.isUser(currentTitle) then
		return currentTitle.nsText .. '_' .. currentTitle.rootText .. '_'
	elseif not Namespace.isMain(currentTitle) then
		return currentTitle.nsText .. '_'
	else
		return ''
	end
end

---@param bracketId string
---@return string?
function MatchGroupBase._checkBracketDuplicate(bracketId)
	local status = mw.ext.Brackets.checkBracketDuplicate(bracketId)
	if status ~= 'ok' then
		local warning = 'This match group uses the duplicate ID \'' .. bracketId .. '\'.'
		mw.ext.TeamLiquidIntegration.add_category('Pages with duplicate Bracketid')
		mw.addWarning(warning)
		return warning
	end
end

return MatchGroupBase
