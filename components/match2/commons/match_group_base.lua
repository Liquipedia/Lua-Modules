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
local Match = require('Module:Match')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupDisplay = Lua.import('Module:MatchGroup/Display', {requireDevIfEnabled = true})
local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})

local category = ''
local _loggedInWarning = ''

local MatchGroupBase = {}

-- Saves and displays a matchlist specified by input args.
function MatchGroupBase.luaMatchlist(frame, args, matchBuilder)
	local bracketid = args['id']
	if bracketid == nil or bracketid == '' then
		error('argument \'id\' is empty')
	end

	local storeInLPDB = true
	if args.store == 'false' then
		storeInLPDB = false
	end

	-- make sure bracket id is valid
	MatchGroupBase._validateBracketID(bracketid)

	-- prefix id with namespace or pagename incase of user to hinder duplicates
	bracketid = MatchGroupBase.getBracketIdPrefix() .. bracketid

	-- check if the bracket is a duplicate
	if storeInLPDB or (not Logic.readBool(args.noDuplicateCheck)) then
		MatchGroupBase._checkBracketDuplicate(bracketid)
	end

	if Logic.readBool(args.isLegacy) then
		_loggedInWarning = _loggedInWarning .. MatchGroupDisplay.WarningBox(
			'This is a Legacy matchlist use the new matchlists instead!'
		)
	end

	local matches = MatchGroupInput.readMatchlist(bracketid, args, matchBuilder)
	MatchGroupBase.saveMatchGroup(bracketid, matches, storeInLPDB)

	if args.hide ~= 'true' then
		return tostring(MatchGroupDisplay.luaMatchlist(frame, {
			bracketid,
			attached = args.attached,
			collapsed = args.collapsed,
			nocollapse = args.nocollapse,
			width = args.width or args.matchWidth,
		})) .. _loggedInWarning .. category
	end
	return _loggedInWarning .. category
end

-- Saves and displays a bracket specified by input args.
function MatchGroupBase.luaBracket(frame, args, matchBuilder)
	local bracketid = args['id']
	if bracketid == nil or bracketid == '' then
		error('argument \'id\' is empty')
	end

	local storeInLPDB = true
	if args.store == 'false' then
		storeInLPDB = false
	end

	-- make sure bracket id is valid
	MatchGroupBase._validateBracketID(bracketid)

	-- prefix id with namespace or pagename incase of user to hinder duplicates
	bracketid = MatchGroupBase.getBracketIdPrefix() .. bracketid

	-- check if the bracket is a duplicate
	if storeInLPDB or (not Logic.readBool(args.noDuplicateCheck)) then
		MatchGroupBase._checkBracketDuplicate(bracketid)
	end

	if Logic.readBool(args.isLegacy) then
		_loggedInWarning = _loggedInWarning
			.. MatchGroupDisplay.WarningBox('This is a Legacy bracket use the new brackets instead!')
	end

	local matches = MatchGroupInput.readBracket(bracketid, args, matchBuilder)
	MatchGroupBase.saveMatchGroup(bracketid, matches, storeInLPDB)

	if args.hide ~= 'true' then
		return _loggedInWarning .. category .. tostring(MatchGroupDisplay.luaBracket(frame, {
			bracketid,
			emptyRoundTitles = args.emptyRoundTitles,
			headerHeight = args.headerHeight,
			hideMatchLine = args.hideMatchLine,
			hideRoundTitles = args.hideRoundTitles,
			matchHeight = args.matchHeight,
			matchWidth = args.matchWidth,
			matchWidthMobile = args.matchWidthMobile,
			opponentHeight = args.opponentHeight,
			qualifiedHeader = args.qualifiedHeader,
		}))
	end
	return _loggedInWarning .. category
end

function MatchGroupBase.saveMatchGroup(bracketId, matches, storeInLpdb)
	local storedData = Array.map(matches, function(match)
		return Match.store(match, storeInLpdb)
	end)

	-- store match data as variable to bypass LPDB on the same page
	Variables.varDefine('match2bracket_' .. bracketId, MatchGroupBase._convertDataForStorage(storedData))
	Variables.varDefine('match2bracketindex', Variables.varDefault('match2bracketindex', 0) + 1)
end

function MatchGroupBase._checkBracketDuplicate(bracketid)
	local status = mw.ext.Brackets.checkBracketDuplicate(bracketid)
	if status ~= 'ok' then
		mw.addWarning('Bracketid \'' .. bracketid .. '\' is used more than once on this page.')
		category = '[[Category:Pages with duplicate Bracketid]]'
		_loggedInWarning = MatchGroupDisplay.WarningBox('This Matchgroup uses the duplicate ID \'' .. bracketid .. '\'.')
	end
end

function MatchGroupBase._validateBracketID(bracketid)
	local subbed, count = string.gsub(bracketid, '[0-9a-zA-Z]', '')
	if subbed == '' and count ~= 10 then
		error('Bracketid has the wrong length (' .. count .. ' given, 10 characters expected)')
	elseif subbed ~= '' then
		error('Bracketid contains invalid characters (' .. subbed .. ')')
	end
end

function MatchGroupBase.getBracketIdPrefix()
	local namespace = mw.title.getCurrentTitle().nsText
	if namespace ~= '' then
		local prefix = namespace
		if namespace == 'User' then
			prefix = prefix .. '_' .. mw.title.getCurrentTitle().rootText
		end
		return prefix .. '_'
	end
	return ''
end

function MatchGroupBase._convertDataForStorage(data)
	for _, match in ipairs(data) do
		for _, game in ipairs(match.match2games) do
			game.scores = Json.parse(game.scores)
		end
	end
	return Json.stringify(data)
end

function MatchGroupBase.enableInstrumentation()
	if FeatureFlag.get('perf') then
		local config = Lua.loadDataIfExists('Module:MatchGroup/Config')
		local locations = Table.getByPathOrNil(config, {'perf', 'locations'}) or {}
		require('Module:Performance/Util').startInstrumentation(locations)
	end
end

function MatchGroupBase.disableInstrumentation()
	if FeatureFlag.get('perf') then
		require('Module:Performance/Util').stopAndSave()
	end
end

return MatchGroupBase
