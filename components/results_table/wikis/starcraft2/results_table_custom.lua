---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:ResultsTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local DivTable = require('Module:DivTable')
local GeneralCollapsible = require('Module:GeneralCollapsible')
local Json = require('Module:Json')
local LeagueIcon = require('Module:LeagueIcon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Page = require('Module:Page')
local Table = require('Module:Table')
local Tier = require('Module:Tier')
local Variables = require('Module:Variables')

local ResultsTable = Lua.import('Module:ResultsTable', {requireDevIfEnabled = true})
local AwardsTable = Lua.import('Module:ResultsTable/Award', {requireDevIfEnabled = true})

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local UNDEFINED_TIER = 'undefined'
local ALL_KILL_ICON = '[[File:AllKillIcon.png|link=All-Kill Format]]'
local DEFAULT_EVENT_ICON = ''
local TBD = 'TBD'
local MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS = 20

local CustomResultsTable = {}

-- Template entry point
function CustomResultsTable.run(frame)
	local args = Arguments.getArgs(frame)
	args.playerLimit = MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS

	if Logic.readBool(args.awards) then
		return CustomResultsTable.awards(args)
	end

	args.data = Json.parseIfTable(Variables.varDefault('achievements'))
	args.manualContent = args[1]

	local resultsTable = ResultsTable(args)

	-- overwrite functions
	resultsTable.tierDisplay = CustomResultsTable.tierDisplay
	resultsTable.rowHighlight = CustomResultsTable.rowHighlight
	resultsTable.processLegacyVsData = CustomResultsTable.processLegacyVsData

	local buildTable = resultsTable:create():build()

	CustomResultsTable._storeAllKill()

	return buildTable
end

function CustomResultsTable.awards(args)
	args.data = Json.parseIfTable(Variables.varDefault('awardAchievements'))

	if Logic.readBool(args.achievements) and Table.isEmpty(args.data) then
		return
	end

	local awardsTable = AwardsTable(args)

	-- overwrite functions
	awardsTable.tierDisplay = CustomResultsTable.tierDisplay
	awardsTable.rowHighlight = CustomResultsTable.rowHighlight

	local sectionHeader = ''
	if Logic.readBool(args.achievements) then
		sectionHeader = '\n=====Notable Awards=====\n'
	end

	return sectionHeader .. tostring(awardsTable:create():build())
end

function CustomResultsTable:tierDisplay(placement)
	local tierDisplay = Tier.text.tiers[placement.liquipediatier] or UNDEFINED_TIER

	tierDisplay = Page.makeInternalLink(
		{},
		tierDisplay,
		tierDisplay .. ' Tournaments'
	)

	local tierTypeDisplay = Tier.text.typesShort[(placement.liquipediatiertype or ''):lower()]

	local sortValue = placement.liquipediatier .. (tierTypeDisplay or '')

	if not tierTypeDisplay then
		return tierDisplay, sortValue
	end

	return tierDisplay .. ' (' .. tierTypeDisplay .. ')', sortValue
end

function CustomResultsTable:rowHighlight(placement)
	if Logic.readBool(placement.publishertier) then
		return 'sc2premier-highlighted'
	end
end

function CustomResultsTable:processLegacyVsData(placement)
	if Table.isEmpty(placement.lastvsdata) then
		local opponent = (placement.extradata or {}).vsOpponent or {}
		placement.lastvsdata = Table.merge(
			Opponent.toLpdbStruct(opponent or {}),
			{groupscore = placement.groupscore, score = placement.lastvsscore}
		)
	end

	return placement
end

-- all kill rows are manual inputs of all kill chievements
-- all kill is a special format in team matches where a player plays as long as he does not get defeated ("killed")
-- or until he has defeated all players of the opponent (possibly with revive of opponent players)
-- an all kill achievement is if a player single handedly defeats a team in an all-kill format
-- the input here is basically to display a very brief information about the match where the all kill was achieved
function CustomResultsTable.allKillRow(frame)
	local args = Arguments.getArgs(frame)

	local header
	if Logic.readBool(args.first) then
		header = mw.html.create('tr')
			:addClass('unsortable')
			:tag('th'):attr('colspan', 10):wikitext('All-Kill Achievements'):done():done()
	end

	local eventName = args.event or TBD
	local eventLink = args.link or eventName

	local row = mw.html.create('tr')
		:tag('td'):wikitext(args.date):done()
		:tag('td'):attr('colspan', 2):wikitext(ALL_KILL_ICON .. ' [[All-Kill Format|All-Kill]]'):done()
		:tag('td'):wikitext(LeagueIcon.display{
			icon = args.icon or DEFAULT_EVENT_ICON,
			iconDark = args.icondark or args.icon or DEFAULT_EVENT_ICON,
			link = eventLink,
			name = eventName,
			options = {noTemplate = true},
		}):done()
		:tag('td'):css('text-align', 'left'):wikitext('[[' .. eventLink .. '|' .. eventName .. ']]'):done()
		:tag('td'):attr('colspan', 4):node(CustomResultsTable._allKillMatch(args)):done()
		:done()

	-- Increment number of all-kills
	local numberOfAllKills = tonumber(Variables.varDefault('allKills')) or 0
	Variables.varDefine('allKills', numberOfAllKills + 1)

	return mw.html.create()
		:node(header)
		:node(row)
end

function CustomResultsTable._allKillMatch(args)
	local teamName = args.team or TBD

	local match = DivTable.create():setStriped(true)
		:addClass('general-collapsible collapsed inherit-bg')
		:css('width', '100%')
		:css('margin', 0)
		:css('padding', 0)
		:row(
			DivTable.HeaderRow()
				:addClass('inherit-bg')
				:cell(mw.html.create('div'):css('width', '35%'):wikitext('vs [[' .. teamName .. ']]'))
				:cell(mw.html.create('div'):css('width', '30%'):wikitext(''))
				:cell(mw.html.create('div'):css('width', '35%'):node(GeneralCollapsible.DefaultToggle()))
		)

	local mapIndex = 1
	local validRound = true
	while validRound do
		validRound = CustomResultsTable._allKillMapRow(args, 'm' .. mapIndex, match)
		mapIndex = mapIndex + 1
	end

	CustomResultsTable._allKillMapRow(args, 'ace', match)
	CustomResultsTable._allKillMapRow(args, 'ace1', match)
	CustomResultsTable._allKillMapRow(args, 'ace2', match)
	CustomResultsTable._allKillMapRow(args, 'ace3', match)

	return match:create()
end

function CustomResultsTable._storeAllKill(args)
	local numberOfAllKills = tonumber(Variables.varDefault('allKills')) or 0
	if not Namespace.isMain() or numberOfAllKills == 0 then
		return
	end

	mw.ext.LiquipediaDB.lpdb_datapoint('allKill_' .. mw.title.getCurrentTitle().text, {
		type = 'allkills',
		information = numberOfAllKills,
	})
end

function CustomResultsTable._allKillMapRow(args, prefix, match)
	if not (args[prefix .. 'p1'] or args[prefix .. 'p2'] or args[prefix .. 'win'] or args[prefix .. 'walkover'])then
		return
	end

	local opponentLeft = mw.html.create('div'):css('text-align', 'right')
	local mapCell = mw.html.create('div'):css('text-align', 'center')
	local opponentRight = mw.html.create('div'):css('text-align', 'left')

	if tonumber(args[prefix .. 'win']) == 1 or tonumber(args[prefix .. 'walkover']) == 1 then
		opponentLeft:addClass('bg-win'):css('font-weight', 'bold')
	elseif tonumber(args[prefix .. 'win']) == 2 or tonumber(args[prefix .. 'walkover']) == 2 then
		opponentRight:addClass('bg-win'):css('font-weight', 'bold')
	elseif args[prefix .. 'win'] == 'skip' then
		opponentLeft:css('text-decoration', 'line-through')
		mapCell:css('text-decoration', 'line-through')
		opponentRight:css('text-decoration', 'line-through')
	end

	local map
	if args[prefix .. 'walkover'] then
		map = 'Walkover'
	else
		map = args[prefix .. 'map']
		map = map and ('[[' .. map .. ']]') or 'Unknown'
	end

	match:row(
		DivTable.Row():addClass('should-collapse inherit-bg')
			:cell(opponentLeft:node(CustomResultsTable._opponentDisplay(args, prefix, 1)):css('width', '33%'):done())
			:cell(mapCell:wikitext(map):css('width', '34%'):done())
			:cell(opponentRight:node(CustomResultsTable._opponentDisplay(args, prefix, 2)):css('width', '33%'):done())
	)

	return true
end

function CustomResultsTable._opponentDisplay(args, prefix, side)
	local players = {CustomResultsTable._buildPlayerStruct(args, prefix .. 'p' .. side)}

	local mapIndex = prefix:gsub('^m', '')
	if args['2v2'] == mapIndex then
		table.insert(players, CustomResultsTable._buildPlayerStruct(args, '2v2p1'))
	end

	local playerIndex = 2
	local playerPrefix = prefix .. 't1p' .. playerIndex
	while (args[playerPrefix]) do
		table.insert(players, CustomResultsTable._buildPlayerStruct(args, playerPrefix))
	end

	return OpponentDisplay.BlockOpponent{
		showLink = false,
		flip = side == 1,
		opponent = {
			type = CustomResultsTable._getOpponentType(#players),
			players = players,
		},
	}
end

function CustomResultsTable._buildPlayerStruct(args, prefix)
	local displayName = args[prefix] or TBD
	return {
		displayName = displayName,
		pageName = args[prefix .. 'link'] or displayName,
		flag = args[prefix .. 'flag'],
		race = args[prefix .. 'race']
	}
end

function CustomResultsTable._getOpponentType(numberOfPlayers)
	for opponentType, playerNumber in pairs(Opponent.partySizes) do
		if playerNumber == numberOfPlayers then
			return opponentType
		end
	end
end

return CustomResultsTable
