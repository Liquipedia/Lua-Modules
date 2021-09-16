---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local p = {}

local getArgs = require('Module:Arguments').getArgs
local json = require('Module:Json')
local Match = require('Module:Match')
local processMatch = require('Module:Brkts/WikiSpecific').processMatch
local Logic = require('Module:Logic')
local Variables = require('Module:Variables')
local String = require('Module:StringUtils')
local globalArgs
local category = ''
local _loggedInWarning = ''

local MatchGroupDisplay = require('Module:MatchGroup/Display')

local PARENT = Variables.varDefault('tournament_parent', '')

local BRACKET_DATA_PARAMS = {'header', 'tolower', 'toupper', 'qualwin', 'quallose', 'skipround'}

function p.matchlist(frame)
	globalArgs = getArgs(frame)
	return p.luaMatchlist(frame, globalArgs)
end

function p.luaMatchlist(frame, args, matchBuilder)
	local bracketid = args['id']
	if bracketid == nil or bracketid == '' then
		error('argument \'id\' is empty')
	end

	local storeInLPDB = true
	if args.store == 'false' then
		storeInLPDB = false
	end

	require('Module:DevFlags').matchGroupDev = Logic.readBool(args.dev)

	-- make sure bracket id is valid
	p._validateBracketID(bracketid)

	-- prefix id with namespace or pagename incase of user to hinder duplicates
	bracketid = p.getBracketIdPrefix() .. bracketid

	-- check if the bracket is a duplicate
	if storeInLPDB or (not Logic.readBool(args.noDuplicateCheck)) then
		p._checkBracketDuplicate(bracketid)
	end

	if Logic.readBool(args.isLegacy) then
		_loggedInWarning = _loggedInWarning .. p._addLoggedInWarning('This is a Legacy matchlist use the new matchlists instead!')
	end

	local storedData = {}
	local currentMatchInWikicode = 'M1'

	local nextMatch = args[currentMatchInWikicode] or args[1]

	for matchIndex = 1, 5000 do
		-- Reading from args is expensive, and on every iteration we always need the next match.
		-- Thus, we optimize this loop by minimizing those accesses.
		local match = nextMatch

		if match == nil then
			break
		end

		if type(match) == 'string' then
			match = json.parse(match)
		end

		match = processMatch(frame, match)
		local matchId = string.format('%04d', matchIndex)

		if matchBuilder ~= nil then
			match = matchBuilder(frame, match, bracketid .. '_' .. matchId)
		end

		local nextMatchIndex = matchIndex + 1
		local nextMatchInWikicode = 'M' .. nextMatchIndex
		nextMatch = args[nextMatchInWikicode] or args[nextMatchIndex]
		local hasNextMatch = nextMatch ~= nil
		local nextMatchId = bracketid .. '_' .. string.format('%04d', nextMatchIndex)

		--set parent page
		match.parent = PARENT

		-- make bracket data
		local bd = {}

		-- overwrite custom values from match object
		local overwrite_bd = json.parse(match['bracketdata'] or '{}')
		for key, val in pairs(overwrite_bd) do
			bd[key] = val
		end

		-- apply bracket data
		bd['type'] = 'matchlist'
		bd['next'] = hasNextMatch and nextMatchId or nil
		bd['title'] = matchIndex == 1 and args['title'] or nil
		local header = args[currentMatchInWikicode .. 'header'] or
			args['header' .. currentMatchInWikicode] or args[currentMatchInWikicode .. 'header']
		if header ~= nil and header ~= '' then
			bd['header'] = header
		end

		bd['bracketindex'] = Variables.varDefault('match2bracketindex', 0)

		match['bracketdata'] = json.stringify(bd)

		-- set matchid and bracketid
		match['matchid'] = matchId
		match['bracketid'] = bracketid

		-- store match
		local matchJson = Match.store(match, storeInLPDB)
		table.insert(storedData, matchJson)

		currentMatchInWikicode = nextMatchInWikicode
	end

	-- store match data as variable to bypass LPDB on the same page
	Variables.varDefine('match2bracket_' .. bracketid, p._convertDataForStorage(storedData))
	Variables.varDefine('match2bracketindex', Variables.varDefault('match2bracketindex', 0) + 1)

	if args.hide ~= 'true' then
		return _loggedInWarning .. category .. tostring(MatchGroupDisplay.luaMatchlist(frame, {
			bracketid,
			attached = args.attached,
			collapsed = args.collapsed,
			nocollapse = args.nocollapse,
			width = args.width or args.matchWidth,
		}))
	end
	return _loggedInWarning .. category
end

function p.bracket(frame)
	globalArgs = getArgs(frame)
	return p.luaBracket(frame, globalArgs)
end

function p.luaBracket(frame, args, matchBuilder)
	local templateid = args['1']
	local bracketid = args['id']
	if templateid == nil or templateid == '' then
		error('argument \'1\' (templateid) is empty')
	end
	if bracketid == nil or bracketid == '' then
		error('argument \'id\' is empty')
	end

	local storeInLPDB = true
	if args.store == 'false' then
		storeInLPDB = false
	end

	require('Module:DevFlags').matchGroupDev = Logic.readBool(args.dev)

	-- make sure bracket id is valid
	p._validateBracketID(bracketid)

	-- prefix id with namespace or pagename incase of user to hinder duplicates
	bracketid = p.getBracketIdPrefix() .. bracketid

	-- check if the bracket is a duplicate
	if storeInLPDB or (not Logic.readBool(args.noDuplicateCheck)) then
		p._checkBracketDuplicate(bracketid)
	end

	if Logic.readBool(args.isLegacy) then
		_loggedInWarning = _loggedInWarning .. p._addLoggedInWarning('This is a Legacy bracket use the new brackets instead!')
	end

	-- get bracket data from template
	local bracketData = p._getBracketData(templateid, bracketid)

	local missing = ''
	local storedData = {}

	--get keys of bracketData in ordered way
	local keys = {}
	local k = 0
	for key, _ in pairs(bracketData) do
		k = k + 1
		keys[k] = key
	end
	table.sort(keys)

	--loop in ordered way through bracketData
	--old loop (unordered) was set via: for dataid, bd in pairs(bracketData) do
	for i = 1, k do
		local dataid = keys[i]
		local bd = bracketData[dataid]

		local matchid = dataid:gsub('0*([1-9])', '%1'):gsub('%-', '')

		-- read match
		local match = args[matchid]
		if match ~= nil then
			if type(match) == 'string' then
				match = json.parse(match)
			end

			p._validateMatchBracketData(matchid, bd)

			match = processMatch(frame, match)
			if matchBuilder ~= nil then
				match = matchBuilder(frame, match, bracketid .. '_' .. matchid)
			end

			--set parent page
			match.parent = PARENT

			-- overwrite custom values from match object
			local overwrite_bd = json.parse(match['bracketdata'] or '{}')
			for key, val in pairs(overwrite_bd) do
				bd[key] = val
			end

			-- apply bracket data
			bd['type'] = 'bracket'
			local header = args[matchid .. 'header']
			if not Logic.isEmpty(header) then
				bd['header'] = header
			end
			bd['bracketindex'] = Variables.varDefault('match2bracketindex', 0)
			local winnerTo = match['winnerto']
			if winnerTo ~= nil then
				local winnerToMatch = ''
				local winnerToBracket = match['winnertobracket']
				if winnerToBracket ~= nil then
					winnerToMatch = winnerToBracket .. '_'
				end
				bd['winnerto'] = winnerToMatch .. p._convertMatchIdentifier(winnerTo)
			end

			local loserTo = match['loserto']
			if loserTo ~= nil then
				local loserToMatch = ''
				local loserToBracket = match['losertobracket']
				if loserToBracket ~= nil then
					loserToMatch = loserToBracket .. '_'
				end
				bd['loserto'] = loserToMatch .. p._convertMatchIdentifier(loserTo)
			end

			--kick bd['thirdplace'] if no 3rd place match
			if bd['thirdplace'] ~= '' and not args['RxMTP'] then
				bd['thirdplace'] = ''
			end
			--kick bd['bracketreset'] if no reset match
			if bd['bracketreset'] ~= '' and not args['RxMBR'] then
				bd['bracketreset'] = ''
			end

			match['bracketdata'] = json.stringify(bd)

			-- set matchid and bracketid
			match['matchid'] = dataid
			match['bracketid'] = bracketid

			-- store match
			local matchJson = Match.store(match, storeInLPDB)
			table.insert(storedData, matchJson)
		else
			-- stores ids of missing matches
			if dataid ~= 'RxMBR' and dataid ~= 'RxMTP' then
				missing = missing .. (missing == '' and '' or ', ')
				missing = missing .. matchid
			end
		end
	end

	-- check if all matches of the template have been stored
	if missing ~= '' then
		error('Missing matches: ' .. missing)
	end

	-- store match data as variable to bypass LPDB on the same page
	Variables.varDefine('match2bracket_' .. bracketid, p._convertDataForStorage(storedData))
	Variables.varDefine('match2bracketindex', Variables.varDefault('match2bracketindex', 0) + 1)

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

-- retrieve bracket data from bracket template
function p._getBracketData(templateid, bracketid)
	local matches = mw.ext.Brackets.getCommonsBracketTemplate(templateid)

	assert(type(matches) == 'table')
	local bracketData = {}
	local count = 0
	for _, match in ipairs(matches) do
		count = count + 1
		local id = String.split(match.match2id, '_')[2] or match.match2id
		local bd = match.match2bracketdata
		local upper = bd['toupper']
		if upper ~= nil and upper ~= '' then
			bd['toupper'] = bracketid .. '_' .. (String.split(upper, '_')[2] or upper)
		end
		local lower = bd['tolower']
		if lower ~= nil and lower ~= '' then
			bd['tolower'] = bracketid .. '_' .. (String.split(lower, '_')[2] or lower)
		end
		local thirdplace = bd['thirdplace']
		if thirdplace ~= nil and thirdplace ~= '' then
			bd['thirdplace'] = bracketid .. '_' .. (String.split(thirdplace, '_')[2] or thirdplace)
		end
		local bracketreset = bd['bracketreset']
		if bracketreset ~= nil and bracketreset ~= '' then
			bd['bracketreset'] = bracketid .. '_' .. (String.split(bracketreset, '_')[2] or bracketreset)
		end
		bracketData[id] = bd
	end
	if count == 0 then
		error('Bracket ' .. templateid .. ' does not exist')
	end
	return bracketData
end

function p._validateMatchBracketData(matchid, data)
	if data == nil then
		error('bracketdata of match ' .. matchid .. ' is missing')
	end

	for _, param in ipairs(BRACKET_DATA_PARAMS) do
		if data[param] == nil then
			error('bracketdata of match ' .. matchid .. ' is missing parameter \'' .. param .. '\'')
		end
	end
end

function p._checkBracketDuplicate(bracketid)
	local status = mw.ext.Brackets.checkBracketDuplicate(bracketid)
	if status ~= 'ok' then
		mw.addWarning('Bracketid \'' .. bracketid .. '\' is used more than once on this page.')
		category = '[[Category:Pages with duplicate Bracketid]]'
		_loggedInWarning = p._addLoggedInWarning('This Matchgroup uses the duplicate ID \'' .. bracketid .. '\'.')
	end
end

function p._validateBracketID(bracketid)
	local subbed, count = string.gsub(bracketid, '[0-9a-zA-Z]', '')
	if subbed == '' and count ~= 10 then
		error('Bracketid has the wrong length (' .. count .. ' given, 10 characters expected)')
	elseif subbed ~= '' then
		error('Bracketid contains invalid characters (' .. subbed .. ')')
	end
end

function p.getBracketIdPrefix()
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

function p._convertMatchIdentifier(identifier)
	local roundPrefix, roundNumber, matchPrefix, matchNumber = string.match(identifier, '(R)([0-9]*)(M)([0-9]*)')
	return roundPrefix .. string.format('%02d', roundNumber) .. '-' .. matchPrefix .. string.format('%03d', matchNumber)
end

function p._convertDataForStorage(data)
	for _, match in ipairs(data) do
		for _, game in ipairs(match.match2games) do
			game.scores = json.parse(game.scores)
		end
	end
	return json.stringify(data)
end

function p._addLoggedInWarning(text)
	local div = mw.html.create('div'):addClass('shown-when-logged-in navigation-not-searchable ambox-wrapper')
		:addClass('ambox wiki-bordercolor-dark wiki-backgroundcolor-light ambox-red')
	local tbl = mw.html.create('table')
	tbl:tag('tr')
		:tag('td'):addClass('ambox-image'):wikitext('[[File:Emblem-important.svg|40px|link=]]'):done()
		:tag('td'):addClass('ambox-text'):wikitext(text)
	return tostring(div:node(tbl))
end

return p
