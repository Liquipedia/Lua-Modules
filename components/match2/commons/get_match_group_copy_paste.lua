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

local Array = require('Module:Array')
local Lua = require("Module:Lua")
local WikiSpecific = require("Module:GetMatchGroupCopyPaste/wiki")
local getArgs = require('Module:Arguments').getArgs

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local BracketAlias = Lua.loadDataIfExists('Module:BracketAlias')

local copyPaste = {}

function copyPaste.generateID()
	--initiate the rnd generator
	math.randomseed(os.time())
	return copyPaste._generateID()
end

function copyPaste._generateID()
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
		id = copyPaste._generateID()
	end

	return id
end

function copyPaste._getBracketData(templateid)
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

function copyPaste._getHeader(headerCode, customHeader, matchKey)
	local header = ''

	if not headerCode then
		return header
	end

	headerCode = mw.text.split(string.gsub(headerCode, '$', '!'), '!')
	local index = 1
	if (headerCode[1] or '') == '' then
		index = 2
	end
	header = mw.message.new('brkts-header-' .. headerCode[index]):params(headerCode[index + 1] or ''):plain()

	header = mw.text.split(header, ',')[1]

	header = '\n\n' .. '<!-- ' .. header .. ' -->'
		.. (customHeader and ('\n|' .. matchKey .. 'header=') or '')

	return header
end

function copyPaste.bracket(frame, args)
	if not args then
		args = getArgs(frame)
	end

	local empty = args.empty == 'true'
	local customHeader = args.customHeader == 'true'
	local bestof = tonumber(args.bestof or 3) or 3
	local opponents = tonumber(args.opponents or 2) or 2
	local mode = WikiSpecific.getMode(args.mode)

	args.id = (args.id or '') and args.id or (args.template or '') and args.template or args.name or ''
	args.id = string.gsub(string.gsub(args.id, '^Bracket/', ''), '^bracket/', '')
	local templateid = BracketAlias[string.lower(args.id)] or args.id

	local out = WikiSpecific.getStart(templateid, copyPaste.generateID(), 'bracket', args)

	local bracketDataList = copyPaste._getBracketData(templateid)

	for index, bracketData in ipairs(bracketDataList) do
		local matchKey = bracketData.matchKey
		if matchKey == 'RxMTP' or matchKey == 'RxMBR' then
			if args.extra == 'true' then
				local header
				if matchKey == 'RxMTP' then
					header = '\n\n' .. '<!-- Third Place Match -->' .. '\n|' .. matchKey .. 'header='
				end
				if empty then
					out = out .. header .. '\n|' .. matchKey .. '='
				else
					out = out .. header .. '\n|' .. matchKey .. '=' .. WikiSpecific.getMatchCode(bestof, mode, index, opponents, args)
				end
			end
		else
			if empty then
				out = out .. copyPaste._getHeader(bracketData.header, customHeader, matchKey) .. '\n|' .. matchKey .. '='
			else
				out = out .. copyPaste._getHeader(bracketData.header, customHeader, matchKey).. '\n|' .. matchKey .. '=' ..
					WikiSpecific.getMatchCode(bestof, mode, index, opponents, args)
			end
		end
	end

	out = out .. '\n}}'
	return '<pre class="selectall" width=50%>' .. mw.text.nowiki(out) .. '</pre>'
end

function copyPaste.matchlist(frame, args)
	if not args then
		args = getArgs(frame)
	end

	local empty = args.empty == 'true'
	local customHeader = args.customHeader == 'true'
	local bestof = tonumber(args.bestof or 3) or 3
	local matches = tonumber(args.matches or 5) or 5
	local opponents = tonumber(args.opponents or 2) or 2
	local mode = WikiSpecific.getMode(args.mode)

	local out = WikiSpecific.getStart(nil, copyPaste.generateID(), 'matchlist', args)

	for index = 1, matches do
		if customHeader then
			out = out .. '\n|M' .. index .. 'header='
		end

		out = out .. '\n|M' .. index .. '=' ..
			(not empty and WikiSpecific.getMatchCode(bestof, mode, index, opponents, args) or '')
	end

	out = out .. '\n}}'
	return '<pre class="selectall" width=50%>' .. mw.text.nowiki(out) .. '</pre>'
end

function copyPaste.singleMatch(frame, args)
	if not args then
		args = getArgs(frame)
	end

	local bestof = tonumber(args.bestof or 3) or 3
	local opponents = tonumber(args.opponents or 2) or 2
	local mode = WikiSpecific.getMode(args.mode)

	local out = WikiSpecific.getStart(nil, copyPaste.generateID(), 'singlematch', args)

	out = out .. '\n|' ..
		WikiSpecific.getMatchCode(bestof, mode, 1, opponents, args)
		.. '\n}}'
	return '<pre class="selectall" width=50%>' .. mw.text.nowiki(out) .. '</pre>'
end

return copyPaste
