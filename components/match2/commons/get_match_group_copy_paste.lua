---
-- @Liquipedia
-- wiki=commons
-- page=Module:GetMatchGroupCopyPaste
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[

bracket finder (and code generator) / matchlist code generator

]]--

local Arguments = require('Module:Arguments')
local BracketAlias = mw.loadData('Module:BracketAlias')
local Class = require('Module:Class')
local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local WikiSpecific = Lua.import('Module:GetMatchGroupCopyPaste/wiki')

---@class Match2CopyPaste
local CopyPaste = Class.new()

function CopyPaste.generateID()
	--initiate the rnd generator
	math.randomseed(os.time())
	return CopyPaste._generateID()
end

function CopyPaste._generateID()
	local id = ''

	for _ = 1, 10 do
		local rnd = math.random(62)
		if rnd <= 10 then
			id = id .. (rnd-1)
		elseif rnd <= 36 then
			id = id .. string.char(54 + rnd)
		else
			id = id .. string.char(60 + rnd)
		end
	end

	if mw.ext.Brackets.checkBracketDuplicate(id) ~= 'ok' then
		id = CopyPaste._generateID()
	end

	return id
end

function CopyPaste._getBracketData(templateid)
	templateid = 'Bracket/' .. templateid
	local matches = mw.ext.Brackets.getCommonsBracketTemplate(templateid)
	assert(type(matches) == 'table')
	if #matches == 0 then
		error(templateid .. ' does not exist. If you should need it please ask a contributor with reviewer+ rights for help.')
	end

	local bracketDataList = Array.map(matches, function(match)
		local _, baseMatchId = MatchGroupUtil.splitMatchId(match.match2id)
		local bracketData = MatchGroupUtil.bracketDataFromRecord(match.match2bracketdata)
		bracketData.matchKey = MatchGroupUtil.matchIdToKey(baseMatchId)
		return bracketData
	end)

	local function sortKey(bracketData)
		local coordinates = bracketData.coordinates
		if bracketData.matchKey == 'RxMTP' or bracketData.matchKey == 'RxMBR' then
			-- RxMTP and RxMBR entries appear immediately after the match they're attached to
			local finalBracketData = Array.find(bracketDataList, function(bracketData_)
				return bracketData_.thirdPlaceMatchId or bracketData_.bracketResetMatchId
			end)
			return Array.extend(sortKey(finalBracketData), 1)
		elseif coordinates.semanticDepth == 0 then
			-- Grand finals are at the end in reverse section order
			return {1, -coordinates.sectionIndex}
		else
			-- Remaining matches are ordered by section, then the usual order within a section
			return {0, coordinates.sectionIndex, coordinates.roundIndex, coordinates.matchIndexInRound}
		end
	end

	Array.sortInPlaceBy(bracketDataList, sortKey)

	return bracketDataList
end

function CopyPaste._getHeader(headerCode, customHeader)
	local header = ''

	if not headerCode then
		return header, false
	end

	headerCode = mw.text.split(string.gsub(headerCode, '$', '!'), '!')
	local index = 1
	if (headerCode[1] or '') == '' then
		index = 2
	end
	header = mw.message.new('brkts-header-' .. headerCode[index]):params(headerCode[index + 1] or ''):plain()

	header = mw.text.split(header, ',')[1]

	header = '\n\n' .. '<!-- ' .. header .. ' -->'

	return header, customHeader
end

function CopyPaste.bracket(frame, args)
	if not args then
		args = Arguments.getArgs(frame)
	end
	local out

	args.id = (args.id or '') and args.id or (args.template or '') and args.template or args.name or ''
	args.id = string.gsub(string.gsub(args.id, '^Bracket/', ''), '^bracket/', '')
	local templateid = BracketAlias[string.lower(args.id)] or args.id

	out, args = WikiSpecific.getStart(templateid, CopyPaste.generateID(), 'bracket', args)

	local empty = Logic.readBool(args.empty)
	local customHeader = Logic.readBool(args.customHeader)
	local bestof = tonumber(args.bestof) or 3
	local opponents = tonumber(args.opponents) or 2
	local mode = WikiSpecific.getMode(args.mode)
	local headersUpTop = Logic.readBool(Logic.emptyOr(args.headersUpTop, true))

	local bracketDataList = CopyPaste._getBracketData(templateid)

	local matchOut = ''
	for index, bracketData in ipairs(bracketDataList) do
		local matchKey = bracketData.matchKey
		local header, hasHeaderEntryParam
		if Logic.readBool(args.extra) and (matchKey == 'RxMTP' or matchKey == 'RxMBR') then
			header = ''
			hasHeaderEntryParam = customHeader
			if matchKey == 'RxMTP' then
				header = '\n\n' .. '<!-- Third Place Match -->'
			end
		elseif matchKey ~= 'RxMTP' and matchKey ~= 'RxMBR' then
			header, hasHeaderEntryParam = CopyPaste._getHeader(bracketData.header, customHeader)
		end

		if Logic.readBool(args.extra) or (matchKey ~= 'RxMTP' and matchKey ~= 'RxMBR') then
			matchOut = matchOut .. header
			if hasHeaderEntryParam and headersUpTop then
				out = out .. '\n|' .. matchKey .. 'header='
			elseif hasHeaderEntryParam then
				matchOut = matchOut .. '\n|' .. matchKey .. 'header='
			end
			if empty then
				matchOut = matchOut .. '\n|' .. matchKey .. '='
			else
				matchOut = matchOut .. '\n|' .. matchKey .. '=' ..
					WikiSpecific.getMatchCode(bestof, mode, index, opponents, args)
			end
		end
	end

	out = out .. matchOut .. '\n}}'
	return '<pre class="selectall" width=50%>' .. mw.text.nowiki(out) .. '</pre>'
end

function CopyPaste.matchlist(frame, args)
	if not args then
		args = Arguments.getArgs(frame)
	end
	local out

	out, args = WikiSpecific.getStart(nil, CopyPaste.generateID(), 'matchlist', args)

	local empty = Logic.readBool(args.empty)
	local customHeader = Logic.readBool(args.customHeader)
	local bestof = tonumber(args.bestof) or 3
	local matches = tonumber(args.matches) or 5
	local opponents = tonumber(args.opponents) or 2
	local mode = WikiSpecific.getMode(args.mode)
	local namedMatchParams = Logic.readBool(Logic.nilOr(args.namedMatchParams, true))
	local headersUpTop = Logic.readBool(args.headersUpTop)

	local matchOut = ''
	for index = 1, matches do
		if customHeader and headersUpTop then
			out = out .. '\n|M' .. index .. 'header='
		elseif customHeader then
			matchOut = matchOut .. '\n|M' .. index .. 'header='
		end

		matchOut = matchOut .. '\n|' .. (namedMatchParams and ('M' .. index .. '=') or '') ..
			(not empty and WikiSpecific.getMatchCode(bestof, mode, index, opponents, args) or '')
	end

	out = out .. matchOut .. '\n}}'
	return '<pre class="selectall" width=50%>' .. mw.text.nowiki(out) .. '</pre>'
end

function CopyPaste.singleMatch(frame, args)
	if not args then
		args = Arguments.getArgs(frame)
	end

	local out
	out, args = WikiSpecific.getStart(nil, CopyPaste.generateID(), 'singlematch', args)

	local bestof = tonumber(args.bestof) or 3
	local opponents = tonumber(args.opponents) or 2
	local mode = WikiSpecific.getMode(args.mode)

	out = out .. '\n|' ..
		WikiSpecific.getMatchCode(bestof, mode, 1, opponents, args)
		.. '\n}}'
	return '<pre class="selectall" width=50%>' .. mw.text.nowiki(out) .. '</pre>'
end

return CopyPaste
