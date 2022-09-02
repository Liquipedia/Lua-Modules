---
-- @Liquipedia
-- wiki=commons
-- page=Module:GroupTableLeague/Starcraft/next
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local DisplayUtil = require('Module:DisplayUtil')
local GeneralCollapsible = require('Module:GeneralCollapsible')
local JsonExt = require('Module:Json/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local StarcraftMatchExternalLinks = require('Module:MatchExternalLinks/Starcraft')
local StarcraftOpponent = require('Module:Opponent/Starcraft')
local StarcraftPlayerExt = require('Module:Player/Ext/Starcraft')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')
local TournamentUtil = require('Module:Tournament/Util')

local GroupTableLeague = Lua.import('Module:GroupTableLeague/next', {requireDevIfEnabled = true})
local GroupTableLeagueUtil = Lua.import('Module:GroupTableLeague/Util', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local StarcraftOpponentDisplay = Lua.import('Module:OpponentDisplay/Starcraft', {requireDevIfEnabled = true})

local StarcraftGroupTableLeague = {}

--[[
Entry point of Template:GroupTableLeague on starcraft/starcraft2
]]
function StarcraftGroupTableLeague.TemplateGroupTableLeague(frame)
	local groupTable = StarcraftGroupTableLeague.readAndImport(Arguments.getArgs(frame))

	GroupTableLeague.store(groupTable)
	return groupTable.config.showTable
		and GroupTableLeague.Table(groupTable)
		or ''
end

function StarcraftGroupTableLeague.Header(groupTable)
	local tableProps = groupTable.tableProps

	local locationNode = tableProps.location and mw.html.create('span')
		:css('padding-right', '3px')
		:node(mw.getCurrentFrame():expandTemplate{title = 'Played in', args = {tableProps.location}})
	local titleNode = mw.html.create('span'):addClass('group-table-title')
		:node(locationNode)
		:node(tableProps.title or mw.title.getCurrentTitle().text)
	DisplayUtil.applyOverflowStyles(titleNode, 'wrap')

	local showDropdown = #groupTable.rounds > 1
	local leftNode = showDropdown and GroupTableLeague.Dropdown(groupTable) or nil

	local linkIconsNode = StarcraftMatchExternalLinks.MatchExternalLinks{links = tableProps.links}
		:addClass('starcraft-match-external-links')
	local rightNode = mw.html.create('div'):addClass('group-table-header-right')
		:css('min-width', showDropdown and tableProps.roundWidth .. 'px' or nil)
		:node(linkIconsNode)
		:node(tableProps.collapsible and GeneralCollapsible.DefaultToggle() or nil)

	if tableProps.collapsible and Table.isEmpty(tableProps.links) and not leftNode then
		leftNode = GeneralCollapsible.DefaultHiddenPlaceholder()
	end

	return mw.html.create('div'):addClass('group-table-header')
		:node(leftNode)
		:node(titleNode)
		:node(rightNode)
end

function StarcraftGroupTableLeague.Entry(props)
	local entry = props.entry
	local result = props.result

	local opponentNode = StarcraftOpponentDisplay.InlineOpponent{opponent = entry.opponent}
	if result.dq then
		opponentNode = mw.html.create('s'):node(opponentNode)
	end
	local leftNode = mw.html.create('div'):css('group-table-entry-left')
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

function StarcraftGroupTableLeague.readAndImport(args)
	local config = StarcraftGroupTableLeague.readConfig(args)
	local rounds = GroupTableLeague.readRounds(args)
	local entries = StarcraftGroupTableLeague.readEntries(args)
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
		tableProps = StarcraftGroupTableLeague.readTableProps(args),
	}

	if Table.isNotEmpty(config.pointsByGameScore) then
		config.pointsPerMatch = {0, 0, 0}
	end

	groupTable.resultsByRound = GroupTableLeague.computeResultsByRound(groupTable)
	GroupTableLeague.populateTableProps(groupTable)
	StarcraftGroupTableLeague.completeEntries(groupTable)
	GroupTableLeague.syncVariables(groupTable)

	return groupTable
end

function StarcraftGroupTableLeague.readConfig(args)
	if Logic.readBool(args.user) then
		args.ns = 2
	end
	args.matchGroupId = args.matchGroupId or args.id

	local metricNames = StarcraftGroupTableLeague.readMetricNames(args)
		or GroupTableLeague.defaultMetricNames({hasPoints = Logic.readBool(args.show_p)})
	args.tiebreaker1 = nil

	return Table.mergeInto(GroupTableLeague.readConfig(args), {
		metricNames = metricNames,
		opponentFromRecord = StarcraftOpponent.fromMatch2Record,
	})
end

function StarcraftGroupTableLeague.readTableProps(args)
	return Table.mergeInto(GroupTableLeague.readTableProps(args), {
		Entry = StarcraftGroupTableLeague.Entry,
		Header = StarcraftGroupTableLeague.Header,
		links = StarcraftMatchExternalLinks.extractFromArgs(args),
		location = args.location,
	})
end

function StarcraftGroupTableLeague.readEntries(args, rounds)
	local date = GroupTableLeague.getResolveDate(rounds)

	local prefixes = {'p', 't', 'team', 'opponent'}
	return TournamentUtil.mapInterleavedPrefix(args, prefixes, function(key, oppIx, prefix)
		local opponent = StarcraftGroupTableLeague.readOpponent(args, key, oppIx, prefix)
		return opponent and Table.mergeInto(
			GroupTableLeague.readCommonEntryProps(args, oppIx, prefix),
			{opponent = Opponent.resolve(opponent, date)}
		)
	end)
end

function StarcraftGroupTableLeague.readOpponent(args, key, oppIx, prefix)
	local opponentArgs = JsonExt.parseIfTable(args[oppIx])
	if opponentArgs then
		return StarcraftOpponent.readOpponentArgs(opponentArgs)

	else
		local opponent = GroupTableLeague.readOpponent(args, key, oppIx, prefix)
		if prefix == 'p' then
			opponent.players[1].race = StarcraftPlayerExt.readRace(args['p' .. oppIx .. 'race'])
		end
		return opponent
	end
end

StarcraftGroupTableLeague.metricAliases = Table.merge(GroupTableLeague.metricAliases, {
	['h2h diff'] = 'ml.gameDiff',
	['h2h games loss'] = 'ml.gameLosses',
	['h2h games won'] = 'ml.gameWins',
	['h2h games'] = 'ml.gameScore',
	['h2h series'] = 'ml.matchScore',
	['head to head diff'] = 'ml.gameDiff',
	['head to head games loss'] = 'ml.gameLosses',
	['head to head games won'] = 'ml.gameWins',
	['head to head games'] = 'ml.gameScore',
	['head to head series'] = 'ml.matchScore',
	['head-to-head diff'] = 'ml.gameDiff',
	['head-to-head games loss'] = 'ml.gameLosses',
	['head-to-head games won'] = 'ml.gameWins',
	['head-to-head games'] = 'ml.gameScore',
	['head-to-head series'] = 'ml.matchScore',
})

function StarcraftGroupTableLeague.readMetricNames(args, config)
	local metricNames = {}
	for _, rawMetric in Table.iter.pairsByPrefix(args, 'tiebreaker') do
		local metricName = StarcraftGroupTableLeague.metricAliases[rawMetric] or rawMetric
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

function StarcraftGroupTableLeague.completeEntries(groupTable)
	local date = GroupTableLeague.getResolveDate(groupTable.rounds, groupTable.matchRecords)

	for _, entry in ipairs(groupTable.entries) do
		local opponent = entry.opponent
		if Opponent.typeIsParty(opponent.type) then
			for _, player in ipairs(opponent.players) do
				if not Opponent.playerIsTbd(player) then
					StarcraftPlayerExt.populatePlayer(player, {date = date})
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

StarcraftGroupTableLeague.perfConfig = {
	locations = Array.extend(GroupTableLeague.perfConfig.locations, {
		'Module:GroupTableLeague/Starcraft/next|*',
	}),
}

return StarcraftGroupTableLeague
