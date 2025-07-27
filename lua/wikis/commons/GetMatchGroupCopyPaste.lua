---
-- @Liquipedia
-- page=Module:GetMatchGroupCopyPaste
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local BracketAlias = Lua.import('Module:BracketAlias', {loadData = true})
local Class = Lua.import('Module:Class')
local I18n = Lua.import('Module:I18n')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local WikiSpecific = Lua.import('Module:GetMatchGroupCopyPaste/wiki')

---@class Match2CopyPaste
local CopyPaste = Class.new()

---@return string
function CopyPaste.generateID()
	--initiate the rnd generator
	math.randomseed(os.time())
	return CopyPaste._generateID()
end

---@return string
function CopyPaste._generateID()
	---@param num integer
	---@return string|integer
	local charFromNumber = function(num)
		if num <= 10 then
			return num - 1
		elseif num <= 36 then
			return string.char(54 + num)
		end

		return string.char(60 + num)
	end

	local id = table.concat(Array.map(Array.range(1, 10), function()
		return charFromNumber(math.random(62))
	end))

	if mw.ext.Brackets.checkBracketDuplicate(id) == 'ok' then
		return id
	end

	return CopyPaste._generateID()
end

---@param templateid string
---@return table
function CopyPaste._getBracketData(templateid)
	templateid = 'Bracket/' .. templateid
	local matches = mw.ext.Brackets.getCommonsBracketTemplate(templateid)

	assert(type(matches) == 'table' and #matches > 0,
		templateid .. ' does not exist. If you should need it please ask a contributor with reviewer+ rights for help.')

	local bracketDataList = Array.map(matches, function(match)
		local _, baseMatchId = MatchGroupUtil.splitMatchId(match.match2id)
		---@cast baseMatchId -nil
		local bracketData = MatchGroupUtil.bracketDataFromRecord(match.match2bracketdata)
		---@cast bracketData MatchGroupUtilBracketBracketData
		return Table.merge(bracketData, {matchKey = MatchGroupUtil.matchIdToKey(baseMatchId)})
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

---@param headerCode string?
---@param customHeader boolean
---@return string
---@return boolean
function CopyPaste._getHeader(headerCode, customHeader)
	if not headerCode then
		return '', false
	end

	local headerCodeArray = mw.text.split(string.gsub(headerCode, '$', '!'), '!')
	local index = Logic.isEmpty(headerCodeArray[1]) and 2 or 1

	local headerMessage = I18n.translate('brkts-header-' .. headerCodeArray[index], {round = headerCodeArray[index + 1]})
	local header = mw.text.split(headerMessage, ',')[1]
	header = '\n' .. '<!-- ' .. header .. ' -->'

	return header, customHeader
end

---@param frame Frame
---@param args table
---@return Html
function CopyPaste.bracket(frame, args)
	if not args then
		args = Arguments.getArgs(frame)
	end
	local display

	args.id = (args.id or '') and args.id or (args.template or '') and args.template or args.name or ''
	args.id = string.gsub(string.gsub(args.id, '^Bracket/', ''), '^bracket/', '')
	local templateid = BracketAlias[string.lower(args.id)] or args.id

	display, args = WikiSpecific.getStart(templateid, CopyPaste.generateID(), 'bracket', args)

	local empty = Logic.readBool(args.empty)
	local customHeader = Logic.readBool(args.customHeader)
	local bestof = tonumber(args.bestof) or 3
	local opponents = tonumber(args.opponents) or 2
	local mode = WikiSpecific.getMode(args.mode)
	local headersUpTop = Logic.readBool(Logic.emptyOr(args.headersUpTop, true))

	local bracketDataList = CopyPaste._getBracketData(templateid)

	local matchesCopyPaste = Array.map(bracketDataList, function(bracketData, matchIndex)
		local matchKey = bracketData.matchKey

		if not Logic.readBool(args.extra) and (matchKey == 'RxMTP' or matchKey == 'RxMBR') then
			return nil
		end

		local header, hasHeaderEntryParam
		if matchKey ~= 'RxMTP' and matchKey ~= 'RxMBR' then
			header, hasHeaderEntryParam = CopyPaste._getHeader(bracketData.header, customHeader)
		elseif Logic.readBool(args.extra) then
			header = matchKey == 'RxMTP' and ('\n' .. '<!-- Third Place Match -->') or ''
			hasHeaderEntryParam = customHeader
		end

		if hasHeaderEntryParam and headersUpTop then
			display = display .. '\n|' .. matchKey .. 'header='
		end

		local match = empty and '' or WikiSpecific.getMatchCode(bestof, mode, matchIndex, opponents, args)

		return '\n' .. table.concat(Array.append({},
			String.nilIfEmpty(header),
			hasHeaderEntryParam and not headersUpTop and ('|' .. matchKey .. 'header=') or nil,
			'|' .. matchKey .. '=' .. match
		), '\n')
	end)

	display = display .. table.concat(matchesCopyPaste) .. '\n}}'

	return CopyPaste._generateCopyPaste(display)
end

---@param frame Frame
---@param args table
---@return Html
function CopyPaste.matchlist(frame, args)
	if not args then
		args = Arguments.getArgs(frame)
	end

	local display
	display, args = WikiSpecific.getStart(nil, CopyPaste.generateID(), 'matchlist', args)

	local empty = Logic.readBool(args.empty)
	local customHeader = Logic.readBool(args.customHeader)
	local bestof = tonumber(args.bestof) or 3
	local matches = tonumber(args.matches) or 5
	local opponents = tonumber(args.opponents) or 2
	local mode = WikiSpecific.getMode(args.mode)
	local namedMatchParams = Logic.readBool(Logic.nilOr(args.namedMatchParams, true))
	local headersUpTop = Logic.readBool(args.headersUpTop)

	local matchesCopyPaste = Array.map(Array.range(1, matches), function(matchIndex)
		if customHeader and headersUpTop then
			display = display .. '\n|M' .. matchIndex .. 'header='
		end

		local matchKey = namedMatchParams and ('M' .. matchIndex .. '=') or ''
		local match = empty and '' or WikiSpecific.getMatchCode(bestof, mode, matchIndex, opponents, args)

		return '\n' .. table.concat(Array.append({},
			customHeader and not headersUpTop and ('|M' .. matchIndex .. 'header=') or nil,
			'|' .. matchKey .. match
		), '\n')
	end)

	display = display .. table.concat(matchesCopyPaste) .. '\n}}'

	return CopyPaste._generateCopyPaste(display)
end

---@param frame Frame
---@param args table
---@return Html
function CopyPaste.singleMatch(frame, args)
	if not args then
		args = Arguments.getArgs(frame)
	end

	local display
	display, args = WikiSpecific.getStart(nil, CopyPaste.generateID(), 'singlematch', args)

	local bestof = tonumber(args.bestof) or 3
	local opponents = tonumber(args.opponents) or 2
	local mode = WikiSpecific.getMode(args.mode)

	display = display .. '\n|' .. WikiSpecific.getMatchCode(bestof, mode, 1, opponents, args) .. '\n}}'

	return CopyPaste._generateCopyPaste(display)
end

---@param frame Frame
---@param args table
---@return Html
function CopyPaste.matchPage(frame, args)
	if not args then
		args = Arguments.getArgs(frame)
	end

	args.generateMatchPage = true

	local bestof = tonumber(args.bestof) or 3
	local opponents = tonumber(args.opponents) or 2
	local mode = WikiSpecific.getMode(args.mode)

	local display = WikiSpecific.getMatchCode(bestof, mode, 1, opponents, args)

	-- Manually change 'Match' to 'MatchPage'
	display = display:gsub('Match2?', 'MatchPage', 1)

	return CopyPaste._generateCopyPaste(display)
end

---@param display string
---@return Html
function CopyPaste._generateCopyPaste(display)
	return mw.html.create('pre')
		:addClass('selectall')
		:node(mw.text.nowiki(display))
end

return CopyPaste
