---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- This module is used for both the Player and Commentator infoboxes

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Lpdb = require('Module:Lpdb')
local MatchTicker = require('Module:MatchTicker/Custom')
local Math = require('Module:MathUtil')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements', {requireDevIfEnabled = true})
local CustomPerson = Lua.import('Module:Infobox/Person/Custom', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent/Starcraft', {requireDevIfEnabled = true})

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local EPT_SEASON = mw.loadData('Module:Series/EPT/config').currentSeason

local ALLOWED_PLACES = {'1', '2', '3', '4', '3-4'}
local ALL_KILL_ICON = '[[File:AllKillIcon.png|link=All-Kill Format]]&nbsp;×&nbsp;'
local EARNING_MODES = {solo = '1v1', team = 'team'}
local DEFAULT_EARNINGS_MODE = 'other'
local MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS = 20
local MINIMUM_NUMBER_OF_ALLOWED_ACHIEVEMENTS = 10
local MAXIMUM_NUMBER_OF_ACHIEVEMENTS = 40
local NUMBER_OF_RECENT_MATCHES = 10

--race stuff
local AVAILABLE_RACES = Array.append(Faction.knownFactions, 'total')
local RACE_FIELD_AS_CATEGORY_LINK = true
local CURRENT_YEAR = tonumber(os.date('%Y'))

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _player

function CustomPlayer.run(frame)
	local player = CustomPerson(frame)
	_args = player.args
	_player = player

	player.recentMatches = {}
	player.infoboxAchievements = {}
	player.awardAchievements = {}
	player.achievements = {}
	player.achievementsFallBack = {}
	player.earningsGlobal = {}
	player.shouldQueryData = player:shouldStoreData(_args)
	if player.shouldQueryData then
		player.yearsActive = CustomPlayer._getMatchupData(player.pagename)
	end

	player.calculateEarnings = CustomPlayer.calculateEarnings
	player.createBottomContent = CustomPlayer.createBottomContent
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.getWikiCategories = CustomPlayer.getWikiCategories

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		return {
			Cell{
				name = 'Race',
				content = {_player:getRaceData(_args.race or 'unknown', RACE_FIELD_AS_CATEGORY_LINK)}
			}
		}
	elseif id == 'role' then return {}
	elseif id == 'region' then return {}
	elseif id == 'achievements' then
		local achievementCells = {}
		if _player.shouldQueryData then
			local achievements = Achievements.display(_player.infoboxAchievements)
			if not String.isEmpty(achievements) then
				table.insert(achievementCells, Center{content = {achievements}})
			end

			local allkills = CustomPlayer._getAllkills()
			if not String.isEmpty(allkills) and allkills ~= '0' then
				table.insert(achievementCells, Cell{
						name = 'All-kills',
						content = {ALL_KILL_ICON .. allkills}
					})
			end

			if next(achievementCells) then
				table.insert(achievementCells, 1, Title{name = 'Achievements'})
			end
		end
		return achievementCells
	elseif
		id == 'history' and
		string.match(_args.retired or '', '%d%d%d%d')
	then
		table.insert(widgets, Cell{
				name = 'Retired',
				content = {_args.retired}
			})
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	local rank1, rank2 = {}, {}
	if _player.shouldQueryData then
		rank1, rank2 = CustomPlayer._getRank(_player.pagename)
	end

	local currentYearEarnings = _player.earningsGlobal[tostring(CURRENT_YEAR)]
	if currentYearEarnings then
		currentYearEarnings = Math.round(currentYearEarnings)
		currentYearEarnings = '$' .. mw.language.new('en'):formatNum(currentYearEarnings)
	end

	local yearsActiveCaster = CustomPlayer._getActiveCasterYears()

	return {
		Cell{
			name = 'Approx. Winnings ' .. CURRENT_YEAR,
			content = {currentYearEarnings}
		},
		Cell{name = rank1.name or 'Rank', content = {rank1.rank}},
		Cell{name = rank2.name or 'Rank', content = {rank2.rank}},
		Cell{name = 'Military Service', content = {_args.military}},
		Cell{
			name = Abbreviation.make('Years active', 'Years active as a player'),
			content = {_player.yearsActive}
		},
		Cell{
			name = Abbreviation.make('Years active (caster)', 'Years active as a caster'),
			content = {yearsActiveCaster}
		},
	}
end

function CustomPlayer._getActiveCasterYears()
	if _player.shouldQueryData then
		local queryData = mw.ext.LiquipediaDB.lpdb('broadcasters', {
			query = 'year::date',
			conditions = '[[page::' .. _player.pagename .. ']] OR [[page::' .. _player.pagename:gsub(' ', '_') .. ']]',
			limit = 5000,
		})

		local years = {}
		for _, broadCastItem in pairs(queryData) do
			local year = broadCastItem.year_date
			years[tonumber(year)] = year
		end

		return Table.isNotEmpty(years) and CustomPlayer._getYearsActive(years) or nil
	end
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:createBottomContent(infobox)
	if _player.shouldQueryData then
		return MatchTicker.participant({player = self.pagename}, _player.recentMatches)
	end
end

function CustomPlayer._getMatchupData(player)
	local yearsActive
	local playerWithoutUnderscore = player
	player = player:gsub(' ', '_')
	local queryParameters = {
		conditions = '([[opponent::' .. player .. ']] OR [[opponent::' .. playerWithoutUnderscore .. ']])' ..
			'AND [[walkover::]] AND [[winner::>]]',
		order = 'date desc',
		query = table.concat({
				'match2opponents',
				'winner',
				'pagename',
				'tournament',
				'tickername',
				'icon',
				'date',
				'publishertier',
				'vod',
				'stream',
				'extradata',
				'parent',
				'finished',
				'bestof',
				'match2id',
				'icondark',
			}, ', '),
	}

	local years = {}
	local vs = {}
	for _, item1 in pairs(AVAILABLE_RACES) do
		vs[item1] = {}
		for _, item2 in pairs(AVAILABLE_RACES) do
			vs[item1][item2] = {['win'] = 0, ['loss'] = 0}
		end
	end

	local foundData = false
	local processMatch = function(match)
		foundData = true
		vs = CustomPlayer._addScoresToVS(vs, match.match2opponents, player, playerWithoutUnderscore)
		local year = string.sub(match.date, 1, 4)
		years[tonumber(year)] = year
		if #_player.recentMatches <= NUMBER_OF_RECENT_MATCHES then
			table.insert(_player.recentMatches, match)
		end
	end

	Lpdb.executeMassQuery('match2', queryParameters, processMatch)

	if foundData then
		local category
		if years[CURRENT_YEAR] or years[CURRENT_YEAR - 1] or years[CURRENT_YEAR - 2] then
			Variables.varDefine('isActive', 'true')
		else
			category = 'Players with no matches in the last three years'
		end

		yearsActive = CustomPlayer._getYearsActive(years)

		yearsActive = string.gsub(yearsActive, '<br>', '', 1)

		if String.isNotEmpty(category) and String.isNotEmpty(yearsActive) then
			yearsActive = yearsActive .. '[[Category:' .. category .. ']]'
		end

		CustomPlayer._setVarsForVS(vs)
	end

	return yearsActive
end

function CustomPlayer._getYearsActive(years)
	local yearsActive = ''
	local tempYear = nil
	local firstYear = true

	for i = 2010, CURRENT_YEAR do
		if years[i] then
			if (not tempYear) and (i ~= CURRENT_YEAR) then
				if firstYear then
					firstYear = false
				else
					yearsActive = yearsActive .. '<br/>'
				end
				yearsActive = yearsActive .. years[i]
				tempYear = years[i]
			end
			if i == CURRENT_YEAR then
				if tempYear then
					yearsActive = yearsActive .. '&nbsp;-&nbsp;<b>Present</b>'
				else
					yearsActive = yearsActive .. '<br/><b>Present</b>'
				end
			elseif not years[i + 1] then
				if tempYear ~= years[i] then
					yearsActive = yearsActive .. '&nbsp;-&nbsp;' .. years[i]
				end
				tempYear = nil
			end
		end
	end

	return yearsActive
end

function CustomPlayer._setVarsForVS(table)
	for key1, item1 in pairs(table) do
		for key2, item2 in pairs(item1) do
			for key3, item3 in pairs(item2) do
				Variables.varDefine(key1 .. '_vs_' .. key2 .. '_' .. key3, item3)
			end
		end
	end
end

function CustomPlayer._addScoresToVS(vs, opponents, player, playerWithoutUnderscore)
	--catch matches vs empty opponents and literals
	if #opponents ~= 2 or Array.any(opponents, function(opponent) return opponent.type == Opponent.literal end) then

		return vs
	end

	local plIndex = 1
	local vsIndex = 2

	if opponents[2].name == player or opponents[2].name == playerWithoutUnderscore then
		plIndex = 2
		vsIndex = 1
	end
	local plOpp = opponents[plIndex]
	local vsOpp = opponents[vsIndex]

	local pRace = Faction.read(plOpp.match2players[1].extradata.faction)
	pRace = pRace and pRace ~= Faction.defaultFaction and pRace or 'r'
	local oRace = Faction.read(vsOpp.match2players[1].extradata.faction) or 'r'
	oRace = oRace and oRace ~= Faction.defaultFaction and oRace or 'r'

	vs[pRace][oRace].win = vs[pRace][oRace].win + (tonumber(plOpp.score or 0) or 0)
	vs[pRace][oRace].loss = vs[pRace][oRace].loss + (tonumber(vsOpp.score or 0) or 0)

	vs['total'][oRace].win = vs['total'][oRace].win + (tonumber(plOpp.score or 0) or 0)
	vs['total'][oRace].loss = vs['total'][oRace].loss + (tonumber(vsOpp.score or 0) or 0)

	vs[pRace]['total'].win = vs[pRace]['total'].win + (tonumber(plOpp.score or 0) or 0)
	vs[pRace]['total'].loss = vs[pRace]['total'].loss + (tonumber(vsOpp.score or 0) or 0)

	vs['total']['total'].win = vs['total']['total'].win + (tonumber(plOpp.score or 0) or 0)
	vs['total']['total'].loss = vs['total']['total'].loss + (tonumber(vsOpp.score or 0) or 0)

	return vs
end

function CustomPlayer:calculateEarnings()
	local earningsTotal
	earningsTotal, _player.earningsGlobal = CustomPlayer._getEarningsMedalsData(self.pagename)
	earningsTotal = Math.round(earningsTotal)
	return earningsTotal, _player.earningsGlobal
end

function CustomPlayer._getEarningsMedalsData(player)
	local playerWithUnderScores = player:gsub(' ', '_')
	local playerConditions = ConditionTree(BooleanOperator.any)
	for playerIndex = 1, MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS do
		playerConditions:add({
			ConditionNode(ColumnName('opponentplayers_p' .. playerIndex), Comparator.eq, player),
			ConditionNode(ColumnName('opponentplayers_p' .. playerIndex), Comparator.eq, playerWithUnderScores),
		})
	end

	local placementConditions = ConditionTree(BooleanOperator.any)
	for _, item in pairs(ALLOWED_PLACES) do
		placementConditions:add({
			ConditionNode(ColumnName('placement'), Comparator.eq, item),
		})
	end

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('opponentname'), Comparator.eq, player),
			ConditionNode(ColumnName('opponentname'), Comparator.eq, playerWithUnderScores),
			playerConditions,
		},
		ConditionNode(ColumnName('date'), Comparator.neq, '1970-01-01 00:00:00'),
		ConditionNode(ColumnName('liquipediatiertype'), Comparator.neq, 'Charity'),
		ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('individualprizemoney'), Comparator.gt, '0'),
			ConditionNode(ColumnName('extradata_award'), Comparator.neq, ''),
			ConditionTree(BooleanOperator.all):add{
				ConditionNode(ColumnName('opponenttype'), Comparator.gt, Opponent.solo),
				placementConditions,
			},
		},
	}

	local earnings = {}
	local medals = {}
	earnings['total'] = {}
	medals['total'] = {}
	local earnings_total = 0

	local queryParameters = {
		conditions = conditions:toString(),
		order = 'liquipediatier asc, weight desc, placement asc',
	}

	local processPlacement = function(placement)
		--handle earnings
		earnings, earnings_total = CustomPlayer._addPlacementToEarnings(earnings, earnings_total, placement)

		--handle medals
		medals = CustomPlayer._addPlacementToMedals(medals, placement)
	end

	Lpdb.executeMassQuery('placement', queryParameters, processPlacement)

	-- if < MINIMUM_NUMBER_OF_ALLOWED_ACHIEVEMENTS achievements fill them up
	if #_player.achievements < MINIMUM_NUMBER_OF_ALLOWED_ACHIEVEMENTS then
		Array.extendWith(
			_player.achievements,
			Array.sub(_player.achievementsFallBack, 1, MINIMUM_NUMBER_OF_ALLOWED_ACHIEVEMENTS - #_player.achievements)
		)
	end
	if #_player.achievements > 0 then
		Variables.varDefine('achievements', Json.stringify(_player.achievements))
	end
	if #_player.awardAchievements > 0 then
		Variables.varDefine('awardAchievements', Json.stringify(_player.awardAchievements))
	end
	CustomPlayer._setVarsFromTable(earnings)
	CustomPlayer._setVarsFromTable(medals)

	return earnings_total, earnings['total']
end

function CustomPlayer._addPlacementToEarnings(earnings, earnings_total, data)
	local mode = EARNING_MODES[data.opponenttype or ''] or DEFAULT_EARNINGS_MODE
	if not earnings[mode] then
		earnings[mode] = {}
	end
	local year = string.sub(data.date, 1, 4)
	data.individualprizemoney = tonumber(data.individualprizemoney) or 0
	earnings[mode][year] = (earnings[mode][year] or 0) + data.individualprizemoney
	earnings['total'][year] = (earnings['total'][year] or 0) + data.individualprizemoney
	earnings_total = (earnings_total or 0) + data.individualprizemoney

	return earnings, earnings_total
end

function CustomPlayer._addPlacementToMedals(medals, data)
	if data.liquipediatiertype ~= 'Qualifier' then
		local place = CustomPlayer._getPlacement(data.placement)
		CustomPlayer._setAchievements(data, place)
		if
			data.opponenttype == Opponent.solo
			and place and place <= 3
		then
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

function CustomPlayer._setVarsFromTable(table)
	for key1, item1 in pairs(table) do
		for key2, item2 in pairs(item1) do
			Variables.varDefine(key1 .. '_' .. key2, item2)
		end
	end
end

function CustomPlayer._getPlacement(value)
	if String.isNotEmpty(value) then
		value = mw.text.split(value, '-')[1]
		if Table.includes(ALLOWED_PLACES, value) then
			return tonumber(value)
		end
	end
end

function CustomPlayer._setAchievements(data, place)
	local tier = tonumber(data.liquipediatier)

	if tier == 1 and place == 1 and data.opponenttype == Opponent.solo then
		table.insert(_player.infoboxAchievements, data)
	end

	if CustomPlayer._isAwardAchievement(data, tier) then
		table.insert(_player.awardAchievements, data)
	elseif String.isNotEmpty((data.extradata or {}).award) then
		return
	elseif CustomPlayer._isAchievement(data, place, tier) then
		table.insert(_player.achievements, data)
	elseif (#_player.achievementsFallBack + #_player.achievements) < MINIMUM_NUMBER_OF_ALLOWED_ACHIEVEMENTS then
		table.insert(_player.achievementsFallBack, data)
	end
end

function CustomPlayer._isAchievement(data, place, tier)
	return place and (
			tier == 1 and place <= 4 or
			tier == 2 and place <= 2 or
			#_player.achievements < MAXIMUM_NUMBER_OF_ACHIEVEMENTS and (
				tier == 2 and place <= 4 or
				tier == 3 and place <= 2 or
				tier == 4 and place <= 1
			)
		)
end

function CustomPlayer._isAwardAchievement(data, tier)
	return String.isNotEmpty((data.extradata or {}).award) and (
		tier == 1 or
		tier == 2 and data.individualprizemoney > 50
	)
end

function CustomPlayer._getRank(player)
	local rank_region = require('Module:EPT player region ' .. EPT_SEASON)[player]
		or {'noregion'}
	local type_cond = '([[type::EPT ' ..
		table.concat(rank_region, ' ranking ' .. EPT_SEASON .. ']] OR [[type::EPT ')
		.. ' ranking ' .. EPT_SEASON .. ']])'

	local data = mw.ext.LiquipediaDB.lpdb('datapoint', {
			conditions = '[[name::' .. player .. ']] AND ' .. type_cond,
			query = 'extradata, information, pagename',
			limit = 10
		})

	local rank1 = CustomPlayer._getRankDisplay(data[1])
	local rank2 = CustomPlayer._getRankDisplay(data[2])

	return rank1, rank2
end

function CustomPlayer._getRankDisplay(data)
	local rank = {}
	if type(data) == 'table' then
		rank.name = 'EPT ' .. (data.information or '') .. ' rank'
		local extradata = data.extradata
		if extradata ~= nil and extradata.rank ~= nil then
			rank.rank = '[[' .. data.pagename .. '|#' .. extradata.rank .. ' (' .. extradata.points .. ' points)]]'
		end
	end
	return rank
end

function CustomPlayer._getAllkills()
	if _player.shouldQueryData then
		local allkillsData = mw.ext.LiquipediaDB.lpdb('datapoint', {
			conditions = '[[pagename::' .. _player.pagename:gsub(' ', '_') .. ']] AND [[type::allkills]]',
			query = 'information',
			limit = 1
		})
		if type(allkillsData[1]) == 'table' then
			return allkillsData[1].information
		end
	end
end

function CustomPlayer:getWikiCategories(categories)
	for _, faction in pairs(self:readFactions(_args.race).factions) do
		table.insert(categories, faction .. ' Players')
	end

	table.insert(categories, self:military(_args.military).category)

	return categories
end

return CustomPlayer
