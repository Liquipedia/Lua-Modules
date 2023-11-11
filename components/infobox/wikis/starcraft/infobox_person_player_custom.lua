---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Info = require('Module:Info')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Lpdb = require('Module:Lpdb')
local Math = require('Module:MathUtil')
local Namespace = require('Module:Namespace')
local Notability = require('Module:Notability')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local Person = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local CURRENT_YEAR = tonumber(os.date('%Y'))
local ALLOWED_PLACES = {'1', '2', '3', '4', '3-4'}
local EARNING_MODES = {solo = '1v1', team = 'team'}
local OTHER_MODE = 'other'
local NUMBER_OF_ALLOWED_ACHIEVEMENTS = 10
local FIRST_DAY_OF_YEAR = '-01-01'
local LAST_DAY_OF_YEAR = '-12-31'
local KOREAN = 'South Korea'

local BOT_INFORMATION_TYPE = 'Bot'

-- race stuff
local AVAILABLE_RACES = Array.append(Faction.knownFactions, 'total')
local RACE_FIELD_AS_CATEGORY_LINK = true

local _earningsGlobal = {}
local _achievements = {}
local _awardAchievements = {}

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _player

function CustomPlayer.run(frame)
	local player = Person(frame)
	_args = player.args
	_player = player

	_args.achievements = Achievements.player{noTemplate = true, baseConditions = {
		'[[liquipediatiertype::]]',
		'([[liquipediatier::1]] OR [[liquipediatier::2]])',
		'[[placement::1]]',
	}}

	player.getStatusToStore = CustomPlayer.getStatusToStore
	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.nameDisplay = CustomPlayer.nameDisplay
	player.calculateEarnings = CustomPlayer.calculateEarnings
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.getWikiCategories = CustomPlayer.getWikiCategories
	player.getPersonType = CustomPlayer.getPersonType
	player.shouldStoreData = CustomPlayer.shouldStoreData

	return player:createInfobox()
end

function CustomPlayer:shouldStoreData(args)
	return Namespace.isMain() and
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
		and args.informationType ~= BOT_INFORMATION_TYPE
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		return {
			Cell{
				name = 'Race',
				content = {CustomPlayer._getRaceDisplay(_args.race, RACE_FIELD_AS_CATEGORY_LINK)}
			}
		}
	elseif id == 'role' then return {}
	elseif id == 'region' then return {}
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
	if _args.informationType == BOT_INFORMATION_TYPE then
		return {
			Cell{name = 'Programmer', content = {_args.programmer}},
			Cell{name = 'Affiliation', content = {_args.affiliation}},
			Cell{name = 'Bot Version', content = {_args.botversion}},
			Cell{name = 'BWAPI Version', content = {_args.bwapiversion}},
			Cell{name = 'Language', content = {_args.language}},
			Cell{name = 'Wrapper', content = {_args.wrapper}},
			Cell{name = 'Terrain Analysis', content = {_args.terrain_analysis}},
			Cell{name = 'AI Techniques', content = {_args.aitechniques}},
			Cell{name = 'Framework', content = {_args.framework}},
			Cell{name = 'Strategies', content = {_args.strategies}},
		}
	end

	-- switch to enable yearsActive once 1v1 matches have been converted to match2 storage
	local yearsActive = Logic.readBool(_args.enableYearsActive)
		and Namespace.isMain() and CustomPlayer._getMatchupData() or nil

	local currentYearEarnings = _earningsGlobal[tostring(CURRENT_YEAR)]
	if currentYearEarnings then
		currentYearEarnings = Math.round(currentYearEarnings)
		currentYearEarnings = '$' .. mw.language.new('en'):formatNum(currentYearEarnings)
	end

	return {
		Cell{
			name = 'Approx. Winnings ' .. CURRENT_YEAR,
			content = {currentYearEarnings}
		},
		Cell{name = 'Years active', content = {yearsActive}}
	}
end

function CustomPlayer.nameDisplay()
	local factions = Faction.readMultiFaction(_args.race or Faction.defaultFaction, {alias = false})

	local raceIcons = table.concat(Array.map(factions, function(faction)
		return Faction.Icon{faction = faction, size = 'medium'}
	end))

	local name = _args.id or _player.pagename

	return raceIcons .. '&nbsp;' .. name
end

function CustomPlayer._getRaceDisplay(race, asCategory)
	local factionNames = Array.map(Faction.readMultiFaction(race, {alias = false}), Faction.toName)

	return table.concat(Array.map(factionNames or {}, function(factionName)
		if asCategory then
			return '[[:Category:' .. factionName .. ' Players|' .. factionName .. ']]'
		end
		return '[[' .. factionName .. ']]'
	end) or {}, ',&nbsp;')
end

function CustomPlayer.adjustLPDB(_, lpdbData)
	local extradata = lpdbData.extradata or {}

	local factions = Faction.readMultiFaction(_args.race, {alias = false})

	extradata.race = factions[1]
	extradata.faction = Faction.toName(factions[1])
	extradata.faction2 = Faction.toName(factions[2])

	extradata.teamname = _args.team

	if Variables.varDefault('racecount') then
		extradata.racehistorical = true
		extradata.factionhistorical = true
	end

	-- Notability values per year
	for year = Info.startYear, CURRENT_YEAR do
		extradata['notabilityin' .. year] = Notability.notabilityScore{
			players = _player.pagename,
			startdate = year .. FIRST_DAY_OF_YEAR,
			enddate = year .. LAST_DAY_OF_YEAR,
			smmult = 0.5,
		}
	end

	lpdbData.extradata = extradata

	return lpdbData
end

function CustomPlayer.getStatusToStore()
	if String.isNotEmpty(_args.status) then
		return mw.getContentLanguage():ucfirst(_args.status)
	elseif _args.death_date then
		return 'Deceased'
	elseif _args.retired then
		return 'Retired'
	end
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer._getMatchupData()
	local yearsActive
	local playerWithoutUnderscore = string.gsub(_player.pagename, '_', ' ')
	local player = _player.pagename
	local queryParameters = {
		conditions = '([[opponent::' .. player .. ']] OR [[opponent::' .. playerWithoutUnderscore .. ']])' ..
			'AND [[walkover::]] AND [[winner::>]]',
		query = 'match2opponents, date',
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

	for i = Info.startYear, CURRENT_YEAR do
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
	local plIndex = 1
	local vsIndex = 2
	-- catch matches vs empty opponents
	if opponents[1] and opponents[2] then
		if opponents[2].name == player or opponents[2].name == playerWithoutUnderscore then
			plIndex = 2
			vsIndex = 1
		end
		local plOpp = opponents[plIndex]
		local vsOpp = opponents[vsIndex]

		local prace = Faction.read(plOpp.match2players[1].extradata.faction)
		prace = prace and prace ~= Faction.defaultFaction and prace or 'r'
		local orace = Faction.read(vsOpp.match2players[1].extradata.faction) or 'r'
		orace = orace and orace ~= Faction.defaultFaction and orace or 'r'

		vs[prace][orace].win = vs[prace][orace].win + (tonumber(plOpp.score) or 0)
		vs[prace][orace].loss = vs[prace][orace].loss + (tonumber(vsOpp.score) or 0)

		vs['total'][orace].win = vs['total'][orace].win + (tonumber(plOpp.score) or 0)
		vs['total'][orace].loss = vs['total'][orace].loss + (tonumber(vsOpp.score) or 0)

		vs[prace]['total'].win = vs[prace]['total'].win + (tonumber(plOpp.score) or 0)
		vs[prace]['total'].loss = vs[prace]['total'].loss + (tonumber(vsOpp.score) or 0)

		vs['total']['total'].win = vs['total']['total'].win + (tonumber(plOpp.score) or 0)
		vs['total']['total'].loss = vs['total']['total'].loss + (tonumber(vsOpp.score) or 0)
	end

	return vs
end

function CustomPlayer:calculateEarnings()
	local earningsTotal
	earningsTotal, _earningsGlobal = CustomPlayer._getEarningsMedalsData(_player.pagename)
	earningsTotal = Math.round(earningsTotal)
	return earningsTotal, _earningsGlobal
end

function CustomPlayer._getEarningsMedalsData(player)
	local playerWithUnderScores = player:gsub(' ', '_')
	local playerConditions = ConditionTree(BooleanOperator.any)
	for playerIndex = 1, Info.maximumNumberOfPlayersInPlacements do
		playerConditions:add{
			ConditionNode(ColumnName('opponentplayers_p' .. playerIndex), Comparator.eq, player),
			ConditionNode(ColumnName('opponentplayers_p' .. playerIndex), Comparator.eq, playerWithUnderScores),
		}
	end

	local placementConditions = ConditionTree(BooleanOperator.any)
	for _, item in pairs(ALLOWED_PLACES) do
		placementConditions:add{
			ConditionNode(ColumnName('placement'), Comparator.eq, item),
		}
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
	local earningsTotal = 0

	local queryParameters = {
		conditions = conditions:toString(),
		order = 'weight desc, liquipediatier asc, placement asc',
	}

	local processPlacement = function(placement)
		-- handle earnings
		earnings, earningsTotal = CustomPlayer._addPlacementToEarnings(earnings, earningsTotal, placement)

		-- handle medals
		medals = CustomPlayer._addPlacementToMedals(medals, placement)
	end

	Lpdb.executeMassQuery('placement', queryParameters, processPlacement)

	if #_achievements > 0 then
		Variables.varDefine('achievements', Json.stringify(_achievements))
	end
	if #_awardAchievements > 0 then
		Variables.varDefine('awardAchievements', Json.stringify(_awardAchievements))
	end
	CustomPlayer._setVarsFromTable(earnings)
	CustomPlayer._setVarsFromTable(medals)

	return earningsTotal, earnings['total']
end

function CustomPlayer._addPlacementToEarnings(earnings, earningsTotal, data)
	local mode = EARNING_MODES[data.opponenttype] or OTHER_MODE
	if not earnings[mode] then
		earnings[mode] = {}
	end
	local year = string.sub(data.date, 1, 4)
	earnings[mode][year] = (earnings[mode][year] or 0) + data.individualprizemoney
	earnings['total'][year] = (earnings['total'][year] or 0) + data.individualprizemoney
	earningsTotal = (earningsTotal or 0) + data.individualprizemoney

	return earnings, earningsTotal
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
	if CustomPlayer._isAwardAchievement(data, tier) then
		table.insert(_awardAchievements, data)
	elseif #_achievements < NUMBER_OF_ALLOWED_ACHIEVEMENTS then
		table.insert(_achievements, data)
	end
end

function CustomPlayer._isAwardAchievement(data, tier)
	local prizeMoney = tonumber(data.individualprizemoney) or 0
	return String.isNotEmpty((data.extradata or {}).award) and (
		tier == 1 or
		tier == 2 and prizeMoney > 50
	)
end

function CustomPlayer:getWikiCategories(categories)
	if _args.tlpdsospa then
		table.insert(categories, 'SOSPA Players')
	end

	if _args.country ~= KOREAN then
		table.insert(categories, 'Foreign Players')
	end

	for _, faction in pairs(Faction.readMultiFaction(_args.race, {alias = false})) do
		table.insert(categories, faction .. ' Players')
	end

	local botCategoryKeys = {
		'language',
		'wrapper',
		'terrain_analysis',
		'aitechniques',
		'framework',
	}
	for _, key in pairs(botCategoryKeys) do
		if _args.informationType == BOT_INFORMATION_TYPE and _args[key] then
			table.insert(categories, _args[key] .. ' bot')
		end
	end

	return categories
end

function CustomPlayer.getPersonType()
	return {store = _args.defaultPersonType, category = _args.defaultPersonType}
end

return CustomPlayer
