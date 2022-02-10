---
-- @Liquipedia
-- wiki=commons
-- page=Module:GroupTableLeague/next
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local ArrayExt = require('Module:Array/Ext')
local Countdown = require('Module:Countdown')
local DateExt = require('Module:Date/Ext')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local DisplayUtil = require('Module:DisplayUtil')
local Flags = require('Module:Flags')
local FnUtil = require('Module:FnUtil')
local GeneralCollapsible = require('Module:GeneralCollapsible')
local Json = require('Module:Json')
local JsonExt = require('Module:Json/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MathUtil = require('Module:MathUtil')
local Opponent = require('Module:Opponent')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local PlayerExt = require('Module:Player/Ext')
local StreamLinks = require('Module:Links/Stream')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')
local TournamentUtil = require('Module:Tournament/Util')

local GroupTableLeagueUtil = Lua.import('Module:GroupTableLeague/Util', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay/downstream', {requireDevIfEnabled = true})

local globalVars = PageVariableNamespace()
local pageVars = PageVariableNamespace('GroupTableLeague')
local enDash = '–'

local GroupTableLeague = {}

--[[
Entry point of Template:GroupTableLeague
]]
function GroupTableLeague.TemplateGroupTableLeague(frame)
	local groupTable = GroupTableLeague.readAndImport(Arguments.getArgs(frame))

	GroupTableLeague.store(groupTable)
	return groupTable.config.showTable
		and GroupTableLeague.Table(groupTable)
		or ''
end


--[[
Section: Display Components
]]

function GroupTableLeague.Table(groupTable)
	local tableProps = groupTable.tableProps

	local roundNodes = Array.map(groupTable.rounds, function(_, roundIndex)
		return GroupTableLeague.RoundResults{roundIndex = roundIndex, groupTable = groupTable}
			:attr('data-toggle-area-content', roundIndex)
	end)

	local tableNode = mw.html.create('div'):addClass('group-table')
		:addClass('toggle-area toggle-area-' .. #groupTable.rounds)
		:addClass(tableProps.collapsed and 'collapsed' or nil)
		:addClass(tableProps.collapsible and 'general-collapsible' or nil)
		:attr('data-toggle-area', #groupTable.rounds)
		:css('width', tableProps.width .. 'px')
		:node(groupTable.tableProps.Header(groupTable))
		:node(GroupTableLeague.CountdownRow(groupTable))

	Array.extendWith(tableNode.nodes, roundNodes)
	return tableNode
end

function GroupTableLeague.Header(groupTable)
	local tableProps = groupTable.tableProps

	local titleNode = mw.html.create('div'):addClass('group-table-title')
		:node(tableProps.title or mw.title.getCurrentTitle().text)
	DisplayUtil.applyOverflowStyles(titleNode, 'wrap')

	local showDropdown = #groupTable.rounds > 1
	local leftNode = showDropdown and GroupTableLeague.Dropdown(groupTable) or nil

	local rightNode = mw.html.create('div'):addClass('group-table-header-right')
		:css('min-width', showDropdown and tableProps.roundWidth .. 'px' or nil)
		:node(tableProps.collapsible and GeneralCollapsible.DefaultToggle() or nil)

	if rightNode and not leftNode then
		leftNode = GeneralCollapsible.DefaultHiddenPlaceholder()
	end

	return mw.html.create('div'):addClass('group-table-header')
		:node(leftNode)
		:node(titleNode)
		:node(rightNode)
end

function GroupTableLeague.CountdownRow(groupTable)
	local tableProps = groupTable.tableProps
	if not tableProps.headerTime then
		return nil
	end

	local finished = not tableProps.isLive
		and tableProps.headerTime <= os.time()

	local countdownNode = Countdown._create(
		Table.merge(tableProps.streams, {
			date = DateExt.toCountdownArg(tableProps.headerTime),
			finished = finished and 'true' or nil,
			rawdatetime = not tableProps.showCountdown or nil,
		})
	)

	return mw.html.create('div'):addClass('group-table-countdown')
		:node(countdownNode)
end

function GroupTableLeague.Dropdown(props)
	local tableProps = props.tableProps

	local buttonText = tableProps.groupFinished
		and tableProps.roundPrefix .. ' ' .. tableProps.currentRoundIndex
		or 'Current'
	local buttonNode = mw.html.create('div')
		:addClass('dropdown-box-button btn btn-primary')
		:css('width', tableProps.roundWidth .. 'px')
		:wikitext(buttonText)
		:node('<span class="caret"></span>')

	local boxNode = mw.html.create('div'):addClass('dropdown-box')

	for roundIx = 1, tableProps.currentRoundIndex do
		local boxButtonText = (roundIx ~= tableProps.currentRoundIndex or tableProps.roundFinished)
			and tableProps.roundPrefix .. ' ' .. roundIx
			or 'Current'
		boxNode:tag('div'):addClass('toggle-area-button btn btn-primary')
			:attr('data-toggle-area-btn', roundIx)
			:css('width', tableProps.roundWidth .. 'px')
			:wikitext(boxButtonText)
	end

	return mw.html.create('div'):addClass('dropdown-box-wrapper')
		:node(buttonNode)
		:node(boxNode)
end

function GroupTableLeague.RoundResults(props)
	local groupTable = props.groupTable
	local tableProps = groupTable.tableProps
	local results = groupTable.resultsByRound[props.roundIndex]

	-- Sort opponent results of this round
	local sortedOppIxs = Array.sortBy(Array.range(1, #results), function(oppIx)
		return results[oppIx].slotIndex
	end)

	local rowNodes = Array.map(sortedOppIxs, function(oppIx, slotIx)
		return tableProps.ResultRow{
			tableProps = tableProps,
			entry = groupTable.entries[oppIx],
			result = results[oppIx],
			slot = groupTable.slots[slotIx],
		}
	end)

	local templateColumns = GroupTableLeague.getTemplateColumns(tableProps)
	local gridNode = mw.html.create('div'):addClass('group-table-results')
		:css('grid-template-columns', table.concat(templateColumns, ' '))
	Array.extendWith(gridNode.nodes, rowNodes)
	return gridNode
end

function GroupTableLeague.getTemplateColumns(tableProps)
	return Array.extend(
		tableProps.showRank and '[rank] minmax(min-content, auto)' or nil,
		'[entry] minmax(min-content, 1fr)',
		tableProps.showMatchScore and '[match-score] minmax(min-content, auto)' or nil,
		tableProps.showMatchWinRate and '[match-win-rate] minmax(min-content, auto)' or nil,
		tableProps.showGameScore and '[game-score] minmax(min-content, auto)' or nil,
		tableProps.showGameDiff and '[game-diff] minmax(min-content, auto)' or nil,
		tableProps.showPoints and '[points] minmax(min-content, auto)' or nil
	)
end

function GroupTableLeague.HeaderRow(groupTable)
	local tableProps = groupTable.tableProps
	local th = GroupTableLeague.TextCell

	local function abbr(text, title)
		return mw.html.create('abbr'):attr('title', title):wikitext(text)
	end

	return mw.html.create('div'):addClass('group-table-header-row')
		:node(tableProps.showRank and th(tableProps.rankHeaderText or abbr('#', 'Rank')) or nil)
		:node(th(tableProps.opponentHeaderText))
		:node(tableProps.showMatchScore and th('Matches') or nil)
		:node(tableProps.showMatchWinRate and th(abbr('Match %', 'Match win rate')) or nil)
		:node(tableProps.showGameScore and th('Games') or nil)
		:node(tableProps.showGameDiff and th(abbr('GD', 'Game difference')) or nil)
		:node(tableProps.showPoints and th(abbr('Pts', 'Points')) or nil)
end

function GroupTableLeague.ResultRow(props)
	local result = props.result
	local tableProps = props.tableProps

	local entryNode = tableProps.Entry(props)
	DisplayHelper.addOpponentHighlight(entryNode, props.entry.opponent)

	local bgClass = result.dq and 'bg-dq'
		or result.bg and 'bg-' .. result.bg

	return mw.html.create('div'):addClass('group-table-result-row')
		:addClass(bgClass)
		:node(tableProps.showRank and GroupTableLeague.Rank(props) or nil)
		:node(entryNode)
		:node(tableProps.showMatchScore and GroupTableLeague.MatchScore(props) or nil)
		:node(tableProps.showMatchWinRate and GroupTableLeague.MatchWinRate(props) or nil)
		:node(tableProps.showGameScore and GroupTableLeague.GameScore(props) or nil)
		:node(tableProps.showGameDiff and GroupTableLeague.GameDiff(props) or nil)
		:node(tableProps.showPoints and GroupTableLeague.Points(props) or nil)
end

function GroupTableLeague.Entry(props)
	local entry = props.entry
	local result = props.result

	local opponentNode = OpponentDisplay.InlineOpponent{opponent = entry.opponent}
	if result.dq then
		opponentNode = mw.html.create('s'):node(opponentNode)
	end
	local leftNode = mw.html.create('span'):css('group-table-entry-left')
		:node(opponentNode)
		:node(entry.note and '&nbsp;<sup><b>' .. entry.note .. '</b></sup>')
	DisplayUtil.applyOverflowStyles(leftNode, 'wrap')

	local rankChangeNode = result.rankChange
		and GroupTableLeague.RankChange{rankChange = result.rankChange}

	return mw.html.create('div')
		:addClass('group-table-cell group-table-entry')
		:node(leftNode)
		:node(rankChangeNode)
end

function GroupTableLeague.TextCell(text)
	local contentNode = mw.html.create('div'):addClass('group-table-cell-content')
		:node(text)
	return mw.html.create('div'):addClass('group-table-cell')
		:node(contentNode)
end

function GroupTableLeague.RankChange(props)
	local rankChangeNode = mw.html.create('span'):addClass('group-table-rank-change')
	if props.rankChange < 0 then
		rankChangeNode
			:css('color', 'green')
			:wikitext('&#x25B2;' .. -props.rankChange) -- ▲
	elseif props.rankChange > 0 then
		rankChangeNode
			:css('color', 'red')
			:wikitext('&#x25BC;' .. props.rankChange) -- ▼
	end
	return rankChangeNode
end

function GroupTableLeague.Rank(props)
	local result = props.result
	local text = result.dq and 'DQ'
		or MathUtil.sum(result.matchScore) > 0 and result.rank .. '.'
		or ''

	local bgClass = result.dq and 'bg-dq'
		or props.slot.pbg and 'bg-' .. props.slot.pbg
	return GroupTableLeague.TextCell(text):addClass('group-table-rank')
		:addClass(bgClass)
end

function GroupTableLeague.MatchScore(props)
	local result = props.result
	local text = props.tableProps.showMatchDraws
		and table.concat(result.matchScore, enDash)
		or table.concat({result.matchScore[1], result.matchScore[3]}, enDash)
	return GroupTableLeague.TextCell(text):addClass('group-table-match-score')
end

function GroupTableLeague.MatchWinRate(props)
	local result = props.result
	local matchCount = MathUtil.sum(result.matchScore)
	local text
	if matchCount > 0 then
		local winRate = result.matchScore[1] / matchCount
		text = string.format('%.3f', math.floor(winRate * 1e3 + 0.5) / 1e3)
	else
		text = enDash
	end

	return GroupTableLeague.TextCell(text):addClass('group-table-win-rate')
end

function GroupTableLeague.GameScore(props)
	local result = props.result
	local text = result.gameScore[1] .. enDash .. result.gameScore[3]
	return GroupTableLeague.TextCell(text):addClass('group-table-game-score')
end

function GroupTableLeague.GameDiff(props)
	local result = props.result
	local gameDiff = result.gameScore[1] - result.gameScore[3]
	local text = gameDiff > 0
		and '+' .. gameDiff
		or tostring(gameDiff)
	return GroupTableLeague.TextCell(text):addClass('group-table-game-diff')
end

function GroupTableLeague.Points(props)
	local text = props.result.points .. 'p'
	return GroupTableLeague.TextCell(text):addClass('group-table-points')
end


--[[
Section: Input Parsing
]]

function GroupTableLeague.readAndImport(args)
	local config = GroupTableLeague.readConfig(args)
	local rounds = GroupTableLeague.readRounds(args)
	local entries = GroupTableLeague.readEntries(args, rounds)
	local matchRecords = GroupTableLeagueUtil.fetchMatchRecords(rounds, entries, config)
	GroupTableLeagueUtil.importRounds(rounds, matchRecords, config)
	GroupTableLeagueUtil.importEntries(entries, matchRecords, config)

	local groupTable = {
		config = config,
		entries = entries,
		entryIxsByName = GroupTableLeagueUtil.buildEntryIxsByName(entries),
		manualResultsByRound = GroupTableLeague.readManualResults(args, #entries, rounds),
		matchRecords = matchRecords,
		matchRecordsByRound = GroupTableLeagueUtil.groupMatchRecordsByRound(matchRecords, rounds),
		rounds = rounds,
		slots = GroupTableLeague.readSlots(args, #entries),
		tableProps = GroupTableLeague.readTableProps(args),
	}

	groupTable.resultsByRound = GroupTableLeague.computeResultsByRound(groupTable)
	GroupTableLeague.populateTableProps(groupTable)
	GroupTableLeague.completeEntries(groupTable)
	GroupTableLeague.syncVariables(groupTable)

	return groupTable
end

function GroupTableLeague.readConfig(args)
	local groupTableIndex = tonumber(globalVars:get('index'))
	globalVars:set('index', groupTableIndex and groupTableIndex + 1 or 0)

	return Table.mergeInto(
		GroupTableLeague.readComputeConfig(args),
		{
			showTable = true,
			storeLpdb = Logic.nilOr(Logic.readBoolOrNil(args.storeLpdb), true),
		}
	)
end

function GroupTableLeague.readComputeConfig(args)
	local hasPoints = Logic.readBool(args.show_p)

	local metricNames = GroupTableLeague.readMetricNames(args)
		or GroupTableLeague.defaultMetricNames({hasPoints = hasPoints})

	local pointsByGameScore = GroupTableLeague.readPointsByGameScore(args)
	local pointsPerMatch
	if args.win_p or args.tie_p or args.lose_p then
		pointsPerMatch = {tonumber(args.win_p) or 0, tonumber(args.tie_p) or 0, tonumber(args.lose_p) or 0}
	elseif Table.isEmpty(pointsByGameScore) then
		pointsPerMatch = {3, 1, 0}
	else
		pointsPerMatch = {0, 0, 0}
	end

	return {
		exclusive = Logic.nilOr(Logic.readBoolOrNil(args.exclusive), true),
		gamesPerWalkover = tonumber(args.walkover_win) or 0,
		getMetric = function(name) return GroupTableLeagueUtil.Metric[name] end,
		hasPoints = hasPoints,
		importOpponents = Logic.readBoolOrNil(args.importOpponents),
		importRoundCount = tonumber(args.rounds),
		importRounds = Logic.nilOr(Logic.readBoolOrNil(args.rounds), true),
		matchGroupsSpec = TournamentUtil.readMatchGroupsSpec(args, {includeCurrentPage = true}),
		metricNames = metricNames,
		opponentFromRecord = Opponent.fromMatch2Record,
		pointsByGameScore = pointsByGameScore,
		pointsPerMatch = pointsPerMatch,
	}
end

function GroupTableLeague.readPointsByGameScore(args)
	local pointsByGameScore = {}
	for key, value in pairs(args) do
		-- Parameter of the form X-Y_p
		local gameWins, gameLosses = tostring(key):match('^(%d+)-(%d+)_p$')
		if gameWins and gameLosses then
			pointsByGameScore[table.concat({gameWins, 0, gameLosses}, '-')] = tonumber(value)
		end
	end
	return pointsByGameScore
end

function GroupTableLeague.readTableProps(args)
	return Table.mergeInto(
		GroupTableLeague.readTableLiveProps(args),
		GroupTableLeague.readTableColumnProps(args),
		{
			Entry = GroupTableLeague.Entry,
			Header = GroupTableLeague.Header,
			ResultRow = GroupTableLeague.ResultRow,
			collapsed = Logic.nilOr(Logic.readBoolOrNil(args.collapsed), Logic.readBool(args.hide)),
			collapsible = Logic.nilOr(Logic.readBoolOrNil(args.collapsible), args.hide ~= nil),
			roundPrefix = args.roundtitle or 'Round',
			roundWidth = tonumber(args.roundwidth) or 100,
			title = args.title,
			width = tonumber((args.width or ''):match('^(%d+)')) or 300,
		}
	)
end

function GroupTableLeague.readTableLiveProps(args)
	local finished = Logic.readBoolOrNil(args.finished) or 'auto'
	return {
		headerTime = DateExt.readTimestamp(args.date),
		isLive = finished ~= 'auto' and not finished or nil,
		showCountdown = Logic.nilOr(Logic.readBoolOrNil(args.showCountdown), not Logic.readBool(args.rawdatetime)),
		streams = StreamLinks.readCountdownStreams(args),
	}
end

function GroupTableLeague.readTableColumnProps(args)
	return {
		rankHeaderText = args.sort,
		showGameDiff = Logic.nilOr(Logic.readBoolOrNil(args.diff), true),
		showGameScore = Logic.nilOr(Logic.readBoolOrNil(args.show_g), true),
		showMatchDraws = Logic.readBoolOrNil(args.ties),
		showMatchScore = Logic.nilOr(Logic.readBoolOrNil(args.showMatchScore), true),
		showMatchWinRate = Logic.readBool(args.showMatchWinRate or args.show_percentage),
		showPoints = Logic.readBool(args.show_p),
		showRank = Logic.nilOr(Logic.readBoolOrNil(args.showRank), true),
	}
end

function GroupTableLeague.readRounds(args)
	local round1StartTime = DateExt.readTimestamp(args.sdate) or DateExt.minTimestamp
	local endTimes = Array.mapIndexes(function(roundIx)
		return DateExt.readTimestamp(args['round' .. roundIx .. 'edate'])
	end)

	if #endTimes == 0 then
		local range = {
			round1StartTime,
			DateExt.readTimestamp(args.edate) or DateExt.maxTimestamp,
		}
		return {{range = range}}
	else
		return Array.map(endTimes, function(endTime, roundIx)
			local range = {
				roundIx == 1 and round1StartTime or endTimes[roundIx - 1],
				endTime,
			}
			return {range = range}
		end)
	end
end

function GroupTableLeague.readSlots(args, entryCount)
	local slots = {}
	for slotIx = 1, entryCount do
		table.insert(slots, {
			pbg = args['pbg' .. slotIx] or (slots[#slots] or {}).pbg or 'up',
		})
	end
	return slots
end

function GroupTableLeague.readEntries(args, rounds)
	local date = GroupTableLeague.getResolveDate(rounds)

	local prefixes = {'p', 't', 'team', 'opponent'}
	return TournamentUtil.mapInterleavedPrefix(args, prefixes, function(key, oppIx, prefix)
		local opponent = GroupTableLeague.readOpponent(args, key, oppIx, prefix)
		return opponent and Table.mergeInto(
			GroupTableLeague.readCommonEntryProps(args, oppIx, prefix),
			{opponent = Opponent.resolve(opponent, date)}
		)
	end)
end

function GroupTableLeague.readOpponent(args, key, oppIx, prefix)
	local opponentArgs = JsonExt.parseIfTable(args[key])
	if opponentArgs then
		return Opponent.readOpponentArgs(opponentArgs)

	elseif prefix == 'p' then
		local player = {
			displayName = args[key],
			flag = String.nilIfEmpty(Flags.CountryName(args['p' .. oppIx .. 'flag'])),
			pageName = args['p' .. oppIx .. 'link'],
		}
		return player.displayName and {type = 'solo', players = {player}}

	elseif prefix == 'team' or prefix == 't' then
		return args[key] and {type = 'team', template = args[key]}

	end
end

function GroupTableLeague.readCommonEntryProps(args, oppIx, prefix)
	local aliasString = prefix and args[prefix .. oppIx .. 'alias']
		or args['alias' .. oppIx]
	local note = prefix and args[prefix .. oppIx .. 'note']
		or args['note' .. oppIx]
	return {
		note = note,
		aliases = aliasString and mw.text.split(aliasString, ',', true) or {},
	}
end

--[[
Read manual results. Manual results require looping through the entire arguments
table
]]
function GroupTableLeague.readManualResults(args, entryCount, rounds)
	local resultsByRound = {
		initial = GroupTableLeagueUtil.blankResults(entryCount),
	}
	local function getResults(roundIx)
		if not resultsByRound[roundIx] then
			resultsByRound[roundIx] = GroupTableLeagueUtil.blankResults(entryCount)
		end
		return resultsByRound[roundIx]
	end

	-- By default, final tiebreak preserves initial entry order
	for oppIx, result in ipairs(resultsByRound.initial) do
		result.finalTiebreak = entryCount - oppIx + 1
	end

	for key, value in pairs(args) do
		key = tostring(key)
		-- Parameter of the form roundXfooY
		local roundIx, param, oppIx = key:match('^round(%d+)(%w-)(%d+)$')
		if roundIx and tonumber(roundIx) <= #rounds then
			local result = getResults(tonumber(roundIx))[tonumber(oppIx)]
			if result then
				GroupTableLeague.insertSparseResult(result, param, value)
			end
		end

		-- Parameter of the form fooY
		-- Goes into the manual results for the final round
		param, oppIx = key:match('^(%w-)(%d+)$')
		if oppIx then
			local result = getResults(#rounds)[tonumber(oppIx)]
			if result then
				GroupTableLeague.insertSparseResult(result, param, value)
			end
		end
	end

	return resultsByRound
end

function GroupTableLeague.insertSparseResult(result, param, value)
	if param == 'bg' then
		result.bg = value
	elseif param == 'temp_p' then
		result.points = tonumber(value)
	elseif param == 'temp_tie' then
		result.finalTiebreak = tonumber(value)
	elseif param == 'temp_win_m' then
		result.matchScore[1] = tonumber(value)
	elseif param == 'temp_tie_m' then
		result.matchScore[2] = tonumber(value)
	elseif param == 'temp_lose_m' then
		result.matchScore[3] = tonumber(value)
	elseif param == 'temp_win_g' then
		result.gameScore[1] = tonumber(value)
	elseif param == 'temp_lose_g' then
		result.gameScore[3] = tonumber(value)
	elseif param == 'dq' then
		result.dq = Logic.readBool(value)
	end
end

GroupTableLeague.metricAliases = {
	['games loss'] = 'gameLosses',
	['games won'] = 'gameWins',
	['h2h games'] = 'ml.gameScore',
	['h2h series'] = 'ml.matchScore',
	['head to head games'] = 'ml.gameScore',
	['head to head series'] = 'ml.matchScore',
	['head-to-head games'] = 'ml.gameScore',
	['head-to-head series'] = 'ml.matchScore',
	['series diff'] = 'matchDiff',
	['series percentage'] = 'matchWinRate',
	['series%'] = 'matchWinRate',
	['series-percentage'] = 'matchWinRate',
	diff = 'gameDiff',
	pts = 'points',
	series = 'matchScore',
}

function GroupTableLeague.isMetricName(metricName)
	local evalMethod, tiedMetric = metricName:match('^(%w+)%.(%w+)$')
	return (evalMethod == 'ml' or evalMethod == 'h2h') and GroupTableLeagueUtil.Metric[tiedMetric] ~= nil
		or GroupTableLeagueUtil.Metric[metricName] ~= nil
end

function GroupTableLeague.defaultMetricNames(config)
	return Array.extend(
		'dq',
		config.hasPoints and 'points' or nil,
		'matchScore',
		'gameDiff',
		'ml.matchDiff',
		'ml.gameScore',
		'gameWins',
		'gameLosses',
		'finalTiebreak'
	)
end

function GroupTableLeague.readMetricNames(args, config)
	local metricNames = {}
	for _, rawMetric in Table.iter.pairsByPrefix(args, 'tiebreaker') do
		local metricName = GroupTableLeague.metricAliases[rawMetric] or rawMetric
		assert(GroupTableLeague.isMetricName(metricName), 'Invalid tiebreaker ' .. rawMetric)
		table.insert(metricNames, metricName)
	end

	if #metricNames ~= 0 then
		table.insert(metricNames, 1, 'dq')
		table.insert(metricNames, 'finalTiebreak')
		return metricNames
	else
		return nil
	end
end

--[[
Fills in missing entry fields that were not specified in input args or
imported from LPDB.
]]
function GroupTableLeague.completeEntries(groupTable)
	local date = GroupTableLeague.getResolveDate(groupTable.rounds, groupTable.matchRecords)

	for _, entry in ipairs(groupTable.entries) do
		local opponent = entry.opponent
		if Opponent.typeIsParty(opponent.type) then
			for _, player in ipairs(opponent.players) do
				if not Opponent.playerIsTbd(player) then
					PlayerExt.populatePlayer(player)
				else
					player.pageName = nil
				end
				player.flag = player.flag or 'tbd'
			end
		elseif opponent.type == 'team' then
			opponent.template = TeamTemplate.resolve(opponent.template, date)
		end
	end
end

--[[
Sets page variables expected by other templates.
]]
function GroupTableLeague.syncVariables(groupTable)
	local groupTableIndex = tonumber(pageVars:get('index'))
	pageVars:set('index', groupTableIndex and groupTableIndex + 1 or 0)

	local matchTime = groupTable.rounds[1].range[1] ~= DateExt.minTimestamp
		and groupTable.rounds[1].range[1]
		or groupTable.tableProps.headerTime
	if matchTime then
		globalVars:set('matchDate', DateExt.formatTimestamp('Y-m-d H:i:s', matchTime))
	end
end


--[[
Section: Results Computation
]]

function GroupTableLeague.computeResultsByRound(groupTable)
	local resultsByRound = GroupTableLeague.aggregateResultsByRound(groupTable)

	for roundIx = 1, #groupTable.rounds do
		local results = resultsByRound[roundIx]
		local ranks = GroupTableLeagueUtil.computeRanks(groupTable, results, roundIx)

		GroupTableLeagueUtil.mergeRanks(results, ranks)
		for oppIx, rankEntry in ipairs(ranks) do
			results[oppIx].rankChange = roundIx > 1
				and rankEntry.rank - resultsByRound[roundIx - 1][oppIx].rank
				or 0
		end
	end

	return resultsByRound
end

function GroupTableLeague.aggregateResultsByRound(groupTable)
	local results = Table.deepCopy(groupTable.manualResultsByRound.initial)

	return Array.map(groupTable.rounds, function(round, roundIx)
		local roundResults = GroupTableLeagueUtil.blankResults(#groupTable.entries)
		for _, matchRecord in ipairs(groupTable.matchRecordsByRound[roundIx]) do
			GroupTableLeagueUtil.applyMatchRecord(roundResults, matchRecord, groupTable.entryIxsByName, groupTable.config)
		end

		local manualResults = groupTable.manualResultsByRound[roundIx]
		if manualResults then
			GroupTableLeagueUtil.mergeResultsInto(roundResults, manualResults)
		end

		GroupTableLeagueUtil.addMatchPoints(roundResults, groupTable.config)

		GroupTableLeagueUtil.mergeResultsInto(results, roundResults)
		return Table.deepCopy(results)
	end)
end


--[[
Section: Display Properties
]]

--[[
Returns a timestamp for the end of the group.
]]
function GroupTableLeague.getEndTime(rounds, matchRecords)
	-- Use the end of the final round if specified.
	if rounds and rounds[#rounds].range[2] ~= DateExt.maxTimestamp then
		return rounds[#rounds].range[2]
	end

	-- Use the tournament end date plus one day if set.
	local tournamentEnddate = TournamentUtil.getContextualDate()
	if tournamentEnddate then
		return DateExt.readTimestamp(tournamentEnddate) + 24 * 3600
	end

	-- Use the start time of the final match if available
	if matchRecords and #matchRecords > 0 then
		local lastMatchDate = matchRecords[#matchRecords].date
		return DateExt.readTimestamp(lastMatchDate)
	end

	-- Fallback: time when the page is rendered
	return os.time()
end

--[[
Returns a yyyy-mm-dd formatted date for the purpose of resolving team
templates and other things.
]]
function GroupTableLeague.getResolveDate(rounds, matchRecords)
	-- Use the end of the final round if specified.
	if rounds and rounds[#rounds].range[2] ~= DateExt.maxTimestamp then
		return DateExt.toYmdInUtc(rounds[#rounds].range[2])
	end

	-- Use the tournament end date if set.
	local tournamentEnddate = TournamentUtil.getContextualDate()
	if tournamentEnddate then
		return tournamentEnddate
	end

	-- Use the start date of the final match if available
	if matchRecords and #matchRecords > 0 then
		local lastMatchTime = matchRecords[#matchRecords].date
		return DateExt.toYmdInUtc(lastMatchTime)
	end

	-- Fallback: date when the page is rendered
	return os.date('%F')
end

--[[
Returns the round that is active when the page is rendered. Returns the final
round if the group has concluded.
]]
function GroupTableLeague.getCurrentRoundIndex(rounds)
	local now = os.time()
	local currentRoundIndex = ArrayExt.findIndex(rounds, function(round) return now < round.range[2] end)
	return currentRoundIndex == 0 and #rounds or currentRoundIndex
end

--[[
Computes a bunch of properties that affect table rendering.
]]
function GroupTableLeague.populateTableProps(groupTable)
	local tableProps = groupTable.tableProps

	local roundStats = GroupTableLeague.computeRoundStatus(groupTable)
	Table.mergeInto(tableProps, roundStats, {
		groupFinished = roundStats.currentRoundIndex == #groupTable.rounds and roundStats.roundFinished,
		groupStarted = roundStats.currentRoundIndex > 1 or roundStats.roundStarted,
		headerTime = tableProps.headerTime or GroupTableLeague.computeDisplayTimestamp(groupTable, roundStats),
		showMatchDraws = GroupTableLeague.computeShowMatchDraws(groupTable),
	})
end

--[[
Auto decide whether match scores should be shown as W-L or W-D-L
]]
function GroupTableLeague.computeShowMatchDraws(groupTable)
	for roundIx = 1, #groupTable.rounds do
		for _, result in ipairs(groupTable.resultsByRound[roundIx]) do
			if result.matchScore[2] ~= 0 then
				return true
			end
		end
	end
	return false
end

--[[
Compute whether the current round has started or finished.
]]
function GroupTableLeague.computeRoundStatus(groupTable)
	local tableProps = groupTable.tableProps

	local currentRoundIndex = GroupTableLeague.getCurrentRoundIndex(groupTable.rounds)
	local records = groupTable.matchRecordsByRound[currentRoundIndex]

	local firstExactMatchTime = FnUtil.memoize(function()
		local firstWithTime = Array.find(records, function(record) return Logic.readBool(record.dateexact) end)
		return firstWithTime and DateExt.readTimestamp(firstWithTime.date)
	end)

	local roundStarted = tableProps.isLive
		or tableProps.headerTime and tableProps.headerTime <= os.time()
		or firstExactMatchTime() and firstExactMatchTime() <= os.time()
		or Array.any(records, function(record) return Logic.readBool(record.finished) end)

	local isLive = Logic.nilOr(
		tableProps.isLive,
		function()
			return Array.any(records, function(record) return not Logic.readBool(record.finished) end)
		end
	)

	return {
		currentRoundIndex = currentRoundIndex,
		isLive = isLive,
		roundFinished = roundStarted and not isLive,
		roundStarted = roundStarted,
	}
end

--[[
Returns the start time of a round determined from the start time of its
earliest match with an exact date.
]]
function GroupTableLeague.getStartTime(groupTable, roundIx)
	local records = groupTable.matchRecordsByRound[roundIx]
	local firstWithTime = Array.find(records, function(record) return Logic.readBool(record.dateexact) end)
	if firstWithTime then
		return DateExt.readTimestamp(firstWithTime.date)
	end

	-- Fallback: lower time bound of the round, if set.
	local range = groupTable.rounds[roundIx].range
	if range[1] ~= DateExt.minTimestamp then
		return range[1]
	end

	return nil
end

--[[
Auto-decide the datetime that should be displayed in the group table header.
]]
function GroupTableLeague.computeDisplayTimestamp(groupTable, roundStatus)
	if not roundStatus.roundFinished then
		return GroupTableLeague.getStartTime(groupTable, roundStatus.currentRoundIndex)
	elseif roundStatus.currentRoundIndex < #groupTable.rounds then
		return GroupTableLeague.getStartTime(groupTable, roundStatus.currentRoundIndex + 1)
	else
		return GroupTableLeague.getStartTime(groupTable, 1)
	end
end


--[[
Section: Storage
]]

function GroupTableLeague.store(groupTable)
	if groupTable.config.storeLpdb then
		local record = GroupTableLeague.DataPointRecord.toRecord(groupTable)
		GroupTableLeague.DataPointRecord.store(record)
	end
end

local DataPointRecord = {}

function DataPointRecord.store(record)
	local groupTableIndex = record.extradata.groupTableIndex or 'unknown'
	record.extradata = Json.stringify(record.extradata)
	mw.ext.LiquipediaDB.lpdb_datapoint('GroupTableLeague_' .. groupTableIndex, record)
end

function DataPointRecord.toRecord(groupTable)
	local entries = groupTable.entries
	local matchRecords = groupTable.matchRecords
	local rounds = groupTable.rounds
	local tableProps = groupTable.tableProps

	-- Sort opponent results of the final round
	local results = groupTable.resultsByRound[#rounds]
	local sortedOppIxs = Array.sortBy(Array.range(1, #entries), function(oppIx)
		return results[oppIx].slotIndex
	end)

	local function makeResultRecord(slotIx)
		local oppIx = sortedOppIxs[slotIx]
		local result = results[oppIx]

		local resultRecord = Table.merge(result, {
			pbg = groupTable.slots[slotIx].pbg,
			opponent = entries[oppIx].opponent,
		})

		if not groupTable.config.hasPoints then
			resultRecord.points = nil
		end

		return resultRecord
	end

	local bracketIndexes = Array.map(matchRecords, function(match)
		return tonumber((match.match2bracketdata or {}).bracketindex)
	end)
	local matchGroupIds = Array.map(matchRecords, function(matchRecord)
		return matchRecord.match2bracketid
	end)
	local stageNames = Array.map(matchRecords, function(matchRecord)
		return String.nilIfEmpty((matchRecord.match2bracketdata or {}).sectionheader)
	end)

	local extradata = {
		bracketIndex = Array.min(bracketIndexes),
		groupFinished = tableProps.groupFinished,
		groupTableIndex = tonumber(pageVars:get('index')),
		matchGroupId = ArrayExt.uniqueElement(matchGroupIds),
		metrics = groupTable.config.metricNames,
		results = Array.map(Array.range(1, #entries), makeResultRecord),
		roundFinished = tableProps.roundFinished,
		rounds = rounds,
		showMatchDraws = tableProps.showMatchDraws or nil,
		stageName = ArrayExt.uniqueElement(stageNames) or globalVars:get('bracket_header'),
	}

	local endTime = GroupTableLeague.getEndTime(groupTable.rounds, groupTable.matchRecords)
	return {
		date = DateExt.formatTimestamp('c', endTime),
		extradata = extradata,
		name = tableProps.title,
		type = 'GroupTableLeague',
	}
end

GroupTableLeague.DataPointRecord = DataPointRecord

GroupTableLeague.perfConfig = {
	locations = {
		'Module:GroupTableLeague/next|*',
	},
}

return GroupTableLeague
