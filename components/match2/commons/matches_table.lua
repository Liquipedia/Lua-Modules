---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchesTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchesTable = {}

local Class = require('Module:Class')
local Countdown = require('Module:Countdown')
local String = require('Module:StringUtils')
local HiddenSort = require('Module:HiddenSort')
local Logic = require('Module:Logic')
local Table = require('Module:Table')
local Lua = require('Module:Lua')
local MatchGroupWorkaround = require('Module:MatchGroup/Workaround')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})

-- overridable if wikis have custom modules
MatchesTable.OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})
MatchesTable.Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})

local _UTC = ' <abbr data-tz="+0:00" title="Coordinated Universal Time (UTC)">UTC</abbr>'
local _TBD = 'TBD'
local _DEFAULT_TBD_IDENTIFIER = 'tbd'
local _WINNER_LEFT = 1
local _WINNER_RIGHT = 2
local _SCORE_STATUS = 'S'
local _DO_FLIP = true
local _NO_FLIP = false
local _LEFT_SIDE_OPPONENT = 'Left'
local _RIGHT_SIDE_OPPONENT = 'Right'

local _args
local _matchHeader
local _currentId

-- If run in abbreviated roundnames mode
local _ABBREVIATIONS = {
	["Upper Bracket"] = "UB",
	["Lower Bracket"] = "LB",
}

function MatchesTable.run(args)
	_args = args or {}

	local data = mw.ext.LiquipediaDB.lpdb('match2', {
		limit = tonumber(_args.limit) or 10000,
		offset = 0,
		order = 'date asc',
		conditions = MatchesTable._buildConditions(),
	})

	local output = mw.html.create('table')
		:addClass('wikitable wikitable-striped sortable match-card')
		:node(MatchesTable._header())

	if type(data[1]) == 'table' then
		for _, match in ipairs(data) do
			output:node(MatchesTable._row(match))
		end
	end

	return mw.html.create('div')
		:addClass('table-responsive')
		:css('margin-bottom', '10px')
		:node(output)
end

function MatchesTable._buildConditions()
	local tournament = _args.tournament or mw.title.getCurrentTitle().prefixedText
	tournament = string.gsub(tournament,'%s','_')

	local lpdbConditions = '[[pagename::' .. tournament .. ']] AND [[date::>1970-01-01]]'
	if _args.sdate then
		lpdbConditions = lpdbConditions .. ' AND ([[date::>' .. _args.sdate .. ']] OR [[date::' .. _args.sdate .. ']])'
	end
	if _args.edate then
		lpdbConditions = lpdbConditions .. ' AND ([[date::<' .. _args.edate .. ']] OR [[date::' .. _args.edate .. ']])'
	end
	if _args.matchsection then
		lpdbConditions = lpdbConditions .. ' AND [[match2bracketdata_sectionheader::' .. _args.matchsection .. ']]'
	end

	return lpdbConditions
end

function MatchesTable._header()
	local header = mw.html.create('tr')
		:addClass('HeaderRow')
		:node(mw.html.create('th')
			:addClass('divCell')
			:attr('data-sort-type','isoDate')
			:wikitext('Date')
		)

	if _args.hideround ~= 'true' then
		local cell = mw.html.create('th')
			:addClass('divCell')
			:wikitext('Round')
		if not _args.sortround then
			cell:addClass('unsortable')
		end
		header:node(cell)
	end

	header
		:node(mw.html.create('th')
			:addClass('divCell')
			:wikitext('Opponent')
		)
		:node(mw.html.create('th')
			:addClass('divCell')
			:css('width','50')
			:wikitext('Score')
		)
		:node(mw.html.create('th')
			:addClass('divCell')
			:wikitext('vs. Opponent')
		)

	return header
end

function MatchesTable._row(match)
	local matchHeader = match.match2bracketdata.header
	if String.isEmpty(matchHeader) then
		--if we are in the same matchGroup just use the previous _matchHeader
		if _currentId == match.match2bracketid then
			matchHeader = _matchHeader
		end
		--if we do not have a matchHeader yet try:
		-- 1) the title (in case it is a matchlist)
		-- 2) the sectionheader
		-- 3) fallback to the previous _matchHeader
		-- last one only applies if we are in a new matchGroup due to it already being used before else
		if String.isEmpty(matchHeader) then
			matchHeader = string.gsub(match.match2bracketdata.title or '', '%s[mM]atches', '')
			if String.isEmpty(matchHeader) then
				matchHeader = match.match2bracketdata.sectionheader
				if String.isEmpty(matchHeader) then
					matchHeader = _matchHeader
				end
			end
		end
	end
	if String.isEmpty(matchHeader) then
		matchHeader = '&nbsp;'
	end
	_currentId = match.match2bracketid

	if type(matchHeader) == 'string' then
		--if the header is a default bracket header we need to convert it to proper display text
		matchHeader = DisplayHelper.expandHeader(matchHeader)
	end
	_matchHeader = matchHeader

	if Logic.readBool(_args.shortedroundnames) then
		--for default headers in brackets the 3rd entry is the shortest, so use that
		--for non default (i.e. custom) entries it might not be set
		--so use the first entry as a fallback
		matchHeader = matchHeader[3]
			or MatchesTable._applyCustomAbbreviations(matchHeader[1])
	else
		matchHeader = matchHeader[1]
	end

	local row = mw.html.create('tr')
		:addClass('Match')

	local dateCell = mw.html.create('td')
		:addClass('Date')

	local dateDisplay
	if Logic.readBool(match.dateexact) then
		local countdownArgs = {}
		if (not Logic.readBool(match.finished)) and Logic.readBool(_args.countdown) then
			countdownArgs = match.stream or {}
			countdownArgs.rawcountdown = 'true'
		else
			countdownArgs.rawdatetime = 'true'
		end
		countdownArgs.date = match.date .. _UTC
		dateDisplay = Countdown._create(countdownArgs)
	elseif _args.dateexact == 'true' then
		dateCell
			:css('text-align', 'center')
			:css('font-style', 'italic')
		dateDisplay = 'To be announced'
	else
		dateDisplay = mw.language.new('en'):formatDate('F j, Y', match.date)
	end

	dateCell
		:node(HiddenSort.run(match.date))
		:node(dateDisplay)

	row:node(dateCell)

	if not Logic.readBool(_args.hideround) then
		local roundCell = mw.html.create('td')
			:addClass('Round')
		if String.isNotEmpty(matchHeader) then
			roundCell:wikitext(matchHeader)
		end
		row:node(roundCell)
	end

	-- workaround for a lpdb bug
	-- remove when it is fixed
	MatchGroupWorkaround.applyPlayerBugWorkaround(match)

	row:node(
		MatchesTable._buildOpponent(
			match.match2opponents[1],
			_DO_FLIP,
			_LEFT_SIDE_OPPONENT
		)
	)

	row:node(MatchesTable.score(match))

	row:node(
		MatchesTable._buildOpponent(
			match.match2opponents[2],
			_NO_FLIP,
			_RIGHT_SIDE_OPPONENT
		)
	)

	return row
end

function MatchesTable._applyCustomAbbreviations(matchHeader)
	for long, short in pairs(_ABBREVIATIONS) do
		matchHeader = matchHeader:gsub(long, short)
	end
end

function MatchesTable._buildOpponent(opponent, flip, side)
	opponent = MatchesTable.Opponent.fromMatch2Record(opponent)

	local opponentDisplay
	if MatchesTable.opponentIsTbdOrEmpty(opponent) then
		opponentDisplay = mw.html.create('i')
			:wikitext(_TBD)
	else
		opponentDisplay = MatchesTable.OpponentDisplay.InlineOpponent{
			opponent = opponent,
			teamStyle = 'short',
			flip = flip,
		}
	end

	return mw.html.create('td')
		:addClass('Team' .. side)
		:node(opponentDisplay)
end

-- overridable value
MatchesTable.tbdIdentifier = _DEFAULT_TBD_IDENTIFIER
function MatchesTable.opponentIsTbdOrEmpty(opponent)
	local firstPlayer = (opponent.players or {})[1] or {}

	local listToCheck = {
		string.lower(firstPlayer.pageName or opponent.name or ''),
		string.lower(firstPlayer.displayName or ''),
		string.lower(opponent.template or ''),
	}

	return Table.includes(listToCheck, MatchesTable.tbdIdentifier)
		or Table.all(listToCheck, function(_, value) return String.isEmpty(value) end)
end

function MatchesTable.score(match)
	local scoreCell = mw.html.create('td')
		:addClass('Score')

	local scoreDisplay = 'vs.'
	if
		Logic.readBool(match.finished) or (
			Logic.readBool(match.dateexact) and
			os.time() >= MatchesTable._parseDateTime(match.date)
		)
	then
		scoreDisplay = MatchesTable.scoreDisplay(match)
	end

	if (tonumber(match.bestof) or 0) > 0 then
		return scoreCell
			:node(mw.html.create('div')
				:css('line-height', '1.1')
				:node(scoreDisplay)
			)
			:node(mw.html.create('div')
				:css('font-size', '75%')
				:css('padding-bottom', '1px')
				:wikitext('(')
				:node(MatchesTable._bestof(match.bestof))
				:wikitext(')')
			)
	end

	return scoreCell:wikitext(scoreDisplay)
end

function MatchesTable.scoreDisplay(match)
	return MatchesTable.getOpponentScore(
		match.match2opponents[1],
		match.winner == _WINNER_LEFT
	) .. ':' .. MatchesTable.getOpponentScore(
		match.match2opponents[2],
		match.winner == _WINNER_RIGHT
	)
end

function MatchesTable.getOpponentScore(opponent, isWinner)
	local score
	if opponent.status == _SCORE_STATUS then
		score = tonumber(opponent.score)
		if score == -1 then
			score = 0
		end
	else
		score = opponent.status or ''
	end
	if isWinner then
		score = '<b>' .. score .. '</b>'
	end

	return score
end

function MatchesTable._parseDateTime(str)
	local year, month, day, hour, minutes, seconds
		= str:match("(%d%d%d%d)-?(%d?%d?)-?(%d?%d?) (%d?%d?):(%d?%d?):(%d?%d?)$")

	-- Adjust time based on server timezone offset from UTC
	local offset = os.time(os.date("*t")) - os.time(os.date("!*t"))
	-- create time - this will take our UTC timestamp and put it into localtime without converting
	local localTime = os.time{
		year = year,
		month = month,
		day = day,
		hour = hour,
		min = minutes,
		sec = seconds
	}

	return localTime + offset -- "Convert" back to UTC
end

function MatchesTable._bestof(value)
	value = tonumber(value)
	if not value then
		return nil
	end

	return mw.html.create('abbr')
		:attr('title', 'Best of ' .. value)
		:wikitext('Bo' .. value)
end

return Class.export(MatchesTable)
