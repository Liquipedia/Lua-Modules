---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Json = require('Module:Json')
local Math = require('Module:Math')
local Namespace = require('Module:Namespace')
local RaceIcon = require('Module:RaceIcon')
local String = require('Module:StringUtils')
local Team = require('Module:Infobox/Team')
local Variables = require('Module:Variables')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Breakdown = require('Module:Infobox/Widget/Breakdown')

local Condition = require('Module:Condition')

local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local doStore = true

local CustomTeam = Class.new()

local CustomInjector = Class.new(Injector)
local _LANGUAGE = mw.language.new('en')

local _earnings = 0
local _EARNINGS_MODES = {team = 'team'}
local _ALLOWED_PLACES = {'1', '2', '3', '4', '3-4'}
local _MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS = 35
local _PLAYER_EARNINGS_ABBREVIATION = '<abbr title="Earnings of players while on the team">Player earnings</abbr>'

local _args
local _team

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	_args = team.args

	team.getWikiCategories = CustomTeam.getWikiCategories
	team.addToLpdb = CustomTeam.addToLpdb
	team.createWidgetInjector = CustomTeam.createWidgetInjector

	return team:createInfobox(frame)
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell({
		name = 'Gaming Director',
		content = {_args['gaming director']}
	}))

	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'earnings' then
		local earningsWhileOnTeam
		_earnings, earningsWhileOnTeam = CustomTeam.calculateEarnings(_args)
		local earningsDisplay
		if _earnings == 0 then
			earningsDisplay = nil
		else
			earningsDisplay = '$' .. _LANGUAGE:formatNum(_earnings)
		end
		local earningsFromPlayersDisplay
		if earningsWhileOnTeam > 0 then
			earningsFromPlayersDisplay = '$' .. _LANGUAGE:formatNum(earningsWhileOnTeam)
		end
		return {
			Cell{name = 'Approx. Total Winnings', content = {earningsDisplay}},
			Cell{name = _PLAYER_EARNINGS_ABBREVIATION, content = {earningsFromPlayersDisplay}},
		}
	elseif id == 'achievements' then
		table.insert(widgets, Cell{name = 'Solo Achievements', content = {_args['solo achievements']}})
		--need this ABOVE the history display and below the
		--achievements display, hence moved it here
		local playerBreakDown = CustomTeam.playerBreakDown(_args)
		if playerBreakDown.playernumber then
				table.insert(widgets, Title{name = 'Player Breakdown'})
				table.insert(widgets, Cell{name = 'Number of players', content = {playerBreakDown.playernumber}})
				table.insert(widgets, Breakdown{content = playerBreakDown.display, classes = {'infobox-center'}})
		end
	elseif id == 'history' then
		local index = 1
		while(not String.isEmpty(_args['history' .. index .. 'title'])) do
			table.insert(widgets, Cell{
				name = _args['history' .. index .. 'title'],
				content = {_args['history' .. index]}
			})
			index = index + 1
		end
	end
	return widgets
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

function CustomTeam:addToLpdb(lpdbData)
	lpdbData.earnings = _earnings or 0
	lpdbData.region = nil
	lpdbData.extradata.subteams = CustomTeam.listSubTeams()
	return lpdbData
end

function CustomTeam.getWikiCategories()
	local categories = {}
	if String.isNotEmpty(_args.disbanded) then
		table.insert(categories, 'Disbanded Teams')
	end

	return categories
end

-- gets a list of sub/accademy teams of the team
-- this data can be used in results queries to include
-- results of accademy teams of the current team
function CustomTeam.listSubTeams()
	if String.isEmpty(_args.subteam) and String.isEmpty(_args.subteam1) then
		return nil
	end
	local subTeams = Team:getAllArgsForBase(_args, 'subteam')
	local subTeamsToStore = {}
	for index, subTeam in pairs(subTeams) do
		subTeamsToStore['subteam' .. index] = mw.ext.TeamLiquidIntegration.resolve_redirect(subTeam)
	end
	return Json.stringify(subTeamsToStore)
end

function CustomTeam.playerBreakDown(args)
	local playerBreakDown = {}
	local playernumber = tonumber(args.player_number or 0) or 0
	local zergnumber = tonumber(args.zerg_number or 0) or 0
	local terrannumbner = tonumber(args.terran_number or 0) or 0
	local protossnumber = tonumber(args.protoss_number or 0) or 0
	local randomnumber = tonumber(args.random_number or 0) or 0
	if playernumber == 0 then
		playernumber = zergnumber + terrannumbner + protossnumber + randomnumber
	end

	if playernumber > 0 then
		playerBreakDown.playernumber = playernumber
		if zergnumber + terrannumbner + protossnumber + randomnumber > 0 then
			playerBreakDown.display = {}
			if protossnumber > 0 then
				playerBreakDown.display[#playerBreakDown.display + 1] = RaceIcon.getSmallIcon({'p'}) .. ' ' .. protossnumber
			end
			if terrannumbner > 0 then
				playerBreakDown.display[#playerBreakDown.display + 1] = RaceIcon.getSmallIcon({'t'}) .. ' ' .. terrannumbner
			end
			if zergnumber > 0 then
				playerBreakDown.display[#playerBreakDown.display + 1] = RaceIcon.getSmallIcon({'z'}) .. ' ' .. zergnumber
			end
			if randomnumber > 0 then
				playerBreakDown.display[#playerBreakDown.display + 1] = RaceIcon.getSmallIcon({'r'}) .. ' ' .. randomnumber
			end
		end
	end
	return playerBreakDown
end

function CustomTeam.calculateEarnings(args)
	if args.disable_smw == 'true' or args.disable_lpdb == 'true' or args.disable_storage == 'true'
		or Variables.varDefault('disable_SMW_storage', 'false') == 'true'
		or (not Namespace.isMain()) then
			doStore = false
			Variables.varDefine('disable_SMW_storage', 'true')
	else
		local earnings, earningsWhileOnTeam = CustomTeam.getEarningsAndMedalsData()
		Variables.varDefine('earnings', earnings)

		return earnings, earningsWhileOnTeam
	end

	return 0, 0
end

function CustomTeam._getLPDBrecursive(cond, query, queryType)
	local data = {} -- get LPDB results in here
	local count
	local offset = 0
	repeat
		local additionalData = mw.ext.LiquipediaDB.lpdb(queryType, {
			conditions = cond,
			query = query,
			offset = offset,
			limit = 5000
		})
		count = #additionalData
		-- Merging
		for i, item in ipairs(additionalData or {}) do
			data[offset + i] = item
		end
		offset = offset + count
	until count ~= 5000

	return data
end

function CustomTeam.getEarningsAndMedalsData()
	local team = _team.pagename
	local query = 'liquipediatier, liquipediatiertype, placement, date, individualprizemoney, prizemoney, players'

	local playerTeamConditions = ConditionTree(BooleanOperator.any):add({
	})
	for playerIndex = 1, _MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS do
		playerTeamConditions:add({
			ConditionNode(ColumnName('players_p' .. playerIndex .. 'team'), Comparator.eq, team),
		})
	end

	local placementConditions = ConditionTree(BooleanOperator.any)
	for _, item in pairs(_ALLOWED_PLACES) do
		placementConditions:add({
			ConditionNode(ColumnName('placement'), Comparator.eq, item),
		})
	end

	local conditions = ConditionTree(BooleanOperator.all):add({
		ConditionNode(ColumnName('date'), Comparator.neq, '1970-01-01 00:00:00'),
		ConditionNode(ColumnName('liquipediatiertype'), Comparator.neq, 'Charity'),
		ConditionNode(ColumnName('liquipediatiertype'), Comparator.neq, 'Qualifier'),
		ConditionTree(BooleanOperator.any):add({
			ConditionNode(ColumnName('prizemoney'), Comparator.gt, '0'),
			ConditionTree(BooleanOperator.all):add({
				ConditionNode(ColumnName('players_type'), Comparator.eq, 'team'),
				ConditionNode(ColumnName('participantlink'), Comparator.eq, team),
				placementConditions,
			}),
		}),
		ConditionTree(BooleanOperator.any):add({
			ConditionNode(ColumnName('participantlink'), Comparator.eq, team),
			ConditionTree(BooleanOperator.all):add({
				ConditionNode(ColumnName('players_type'), Comparator.neq, 'team'),
				playerTeamConditions
			}),
		}),
	})

	local data = CustomTeam._getLPDBrecursive(conditions:toString(), query, 'placement')

	local earnings = {}
	local medals = {}
	local teamMedals = {}
	local playerEarnings = 0
	earnings['total'] = {}
	medals['total'] = {}
	teamMedals['total'] = {}

	if type(data[1]) == 'table' then
		for _, item in pairs(data) do
			--handle earnings
			earnings, playerEarnings = CustomTeam._addPlacementToEarnings(earnings, playerEarnings, item)

			--handle medals
			local mode = (item.players or {}).type
			if mode == 'solo' then
				medals = CustomTeam._addPlacementToMedals(medals, item)
			elseif mode == 'team' then
				teamMedals = CustomTeam._addPlacementToMedals(teamMedals, item)
			end
		end
	end

	CustomTeam._setVarsFromTable(earnings)
	CustomTeam._setVarsFromTable(medals)
	CustomTeam._setVarsFromTable(teamMedals, 'team_')

	if earnings.team == nil then
		earnings.team = {}
	end

	if doStore then
		mw.ext.LiquipediaDB.lpdb_datapoint('total_earnings_players_while_on_team_' .. team, {
				type = 'total_earnings_players_while_on_team',
				name = _team.pagename,
				information = playerEarnings,
		})
	end

	return Math.round{earnings.team.total or 0}, Math.round{playerEarnings or 0}
end

function CustomTeam._addPlacementToEarnings(earnings, playerEarnings, data)
	local prizeMoney = data.prizemoney
	local mode = (data.players or {}).type
	mode = _EARNINGS_MODES[mode]
	if not mode then
		prizeMoney = data.individualprizemoney
		playerEarnings = playerEarnings + prizeMoney
		mode = 'other'
	end
	if not earnings[mode] then
		earnings[mode] = {}
	end
	local date = string.sub(data.date, 1, 4)
	earnings[mode][date] = (earnings[mode][date] or 0) + prizeMoney
	earnings[mode]['total'] = (earnings[mode]['total'] or 0) + prizeMoney
	earnings['total'][date] = (earnings['total'][date] or 0) + prizeMoney

	return earnings, playerEarnings
end

function CustomTeam._addPlacementToMedals(medals, data)
	local place = CustomTeam._placements(data.placement)
	if place then
		if data.liquipediatiertype ~= 'Qualifier' then
			local tier = data.liquipediatier or 'undefined'
			if not medals[place] then
				medals[place] = {}
			end
			medals[place][tier] = (medals[place][tier] or 0) + 1
			medals[place]['total'] = (medals[place]['total'] or 0) + 1
			medals['total'][tier] = (medals['total'][tier] or 0) + 1
		end
	end

	return medals
end

function CustomTeam._setVarsFromTable(table, prefix)
	for key1, item1 in pairs(table) do
		for key2, item2 in pairs(item1) do
			Variables.varDefine((prefix or '') .. key1 .. '_' .. key2, item2)
		end
	end
end

function CustomTeam._placements(value)
	value = mw.text.split(value or '', '-')[1]
	if value == '1' or value == '2' then
		return value
	elseif value == '3' then
		return 'sf'
	end

	return nil
end

return CustomTeam
