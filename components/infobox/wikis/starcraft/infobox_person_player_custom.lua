---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local CleanRace = require('Module:CleanRace')
local Info = require('Module:Info')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lpdb = require('Module:Lpdb')
local Math = require('Module:Math')
--local Namespace = require('Module:Namespace')
local Notability = require('Module:Notability')
local Person = require('Module:Infobox/Person/dev')
local RaceIcon = require('Module:RaceIcon')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Condition = require('Module:Condition')

local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local _CURRENT_YEAR = tonumber(os.date('%Y'))
local _ALLOWED_PLACES = {'1', '2', '3', '4', '3-4'}
local _EARNING_MODES = {['solo'] = '1v1', ['team'] = 'team'}
local _MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS = 30
local _NUMBER_OF_ALLOWED_ACHIEVEMENTS = 10
local _FIRST_DAY_OF_YEAR = '-01-01'
local _LAST_DAY_OF_YEAR = '-12-31'
local _KOREAN = 'South Korea'

--race stuff
--local _AVAILABLE_RACES = {'p', 't', 'z', 'r', 'total'}
local _RACE_FIELD_AS_CATEGORY_LINK = true
local _RACE_DATA = {
	p = {'Protoss'},
	pt = {'Protoss', 'Terran'},
	pz = {'Protoss', 'Zerg'},
	t = {'Terran'},
	tp = {'Terran', 'Protoss'},
	tz = {'Terran', 'Zerg'},
	z = {'Zerg'},
	zt = {'Zerg', 'Terran'},
	zp = {'Zerg', 'Protoss'},
	r = {'Random'},
	a = {'Protoss', 'Terran', 'Zerg'},
}
local _RACE_ALL = 'All'
local _RACE_ALL_SHORT = 'a'

local _earningsGlobal = {}
local _achievements = {}
local _awardAchievements = {}
local _raceData
local _statusStore

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _player
local _lpdbData = {}

function CustomPlayer.run(frame)
	local player = Person(frame)
	_args = player.args
	_player = player

	player.getStatusToStore = CustomPlayer.getStatusToStore
	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.nameDisplay = CustomPlayer.nameDisplay
	player.calculateEarnings = CustomPlayer.calculateEarnings
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.getWikiCategories = CustomPlayer.getWikiCategories

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		return {
			Cell{
				name = 'Race',
				content = {CustomPlayer._getRaceData(_args.race or 'unknown', _RACE_FIELD_AS_CATEGORY_LINK)}
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
	--enable this AFTER the match to match2 conversion of 1v1 matchlists and brackets
	--local yearsActive = Namespace.isMain() and CustomPlayer._getMatchupData() or nil

	local currentYearEarnings = _earningsGlobal[tostring(_CURRENT_YEAR)]
	if currentYearEarnings then
		currentYearEarnings = Math.round{currentYearEarnings}
		currentYearEarnings = '$' .. mw.language.new('en'):formatNum(currentYearEarnings)
	end

	return {
		Cell{
			name = 'Approx. Winnings ' .. _CURRENT_YEAR,
			content = {currentYearEarnings}
		},
		--Cell{name = 'Years active', content = {yearsActive}}
	}
end

function CustomPlayer.nameDisplay()
	CustomPlayer._getRaceData(_args.race or 'unknown')
	local raceIcon = RaceIcon.getNormalIcon{_raceData.race}
	local name = _args.id or _player.pagename

	return raceIcon .. '&nbsp;' .. name
end

function CustomPlayer._getRaceData(race, asCategory)
	race = string.lower(race)
	race = CleanRace[race] or race
	local raceTable = _RACE_DATA[race]

	local faction, faction2
	if race == _RACE_ALL_SHORT then
		faction = _RACE_ALL
	else
		faction = (raceTable or {})[1]
		faction2 = (raceTable or {})[2]
	end

	local display
	if not raceTable and race ~= 'unknown' then
		display = '[[Category:InfoboxRaceError]]<strong class="error">' ..
			mw.text.nowiki('Error: Invalid Race') .. '</strong>'
	else
		if asCategory then
			for raceIndex, raceValue in ipairs(raceTable or {}) do
				raceTable[raceIndex] = ':Category:' .. raceValue .. ' Players|' .. raceValue .. ']]'
					.. '[[Category:' .. raceValue .. ' Players'
			end
		end
		if raceTable then
			display = '[[' .. table.concat(raceTable, ']],&nbsp;[[') .. ']]'
		end
	end

	_raceData = {
		race = race,
		faction = faction or '',
		faction2 = faction2 or '',
		display = display,
	}

	return display
end

function CustomPlayer.adjustLPDB(_, lpdbData)
	_lpdbData = lpdbData
	local extradata = lpdbData.extradata or {}
	extradata.race = _raceData.race
	extradata.faction = _raceData.faction
	extradata.faction2 = _raceData.faction2
	extradata.lc_id = string.lower(_player.pagename)
	extradata.teamname = _args.team
	extradata.activeplayer = (not _statusStore) and Variables.varDefault('isActive', '') or ''

	if Variables.varDefault('racecount') then
		extradata.racehistorical = true
		extradata.factionhistorical = true
	end

	--Notability values per year
	for year = Info.startYear, _CURRENT_YEAR do
		extradata['notabilityin' .. year] = Notability.notabilityScore{
			players = _player.pagename,
			startdate = year .. _FIRST_DAY_OF_YEAR,
			enddate = year .. _LAST_DAY_OF_YEAR,
			smmult = 0.5,
		}
	end

	lpdbData.extradata = extradata

	return lpdbData
end

function CustomPlayer.getStatusToStore()
	if String.isNotEmpty(_args.status) then
		_statusStore = mw.getContentLanguage():ucfirst(_args.status)
	elseif _args.death_date then
		_statusStore = 'Deceased'
	elseif _args.retired then
		_statusStore = 'Retired'
	elseif not Logic.readBool(_args.isplayer) then
		_statusStore = 'not player'
	end
	return _statusStore
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

--[==[enable this AFTER the match to match2 conversion of 1v1 matchlists and brackets
function CustomPlayer._getMatchupData()
	local yearsActive
	player = string.gsub(_player.pagename, '_', ' ')
	local queryParameters = {
		conditions = '[[opponent::' .. player .. ']] AND [[walkover::]] AND [[winner::>]]',
		query = 'match2opponents, date',
	}

	local years = {}
	local vs = {}
	for _, item1 in pairs(_AVAILABLE_RACES) do
		vs[item1] = {}
		for _, item2 in pairs(_AVAILABLE_RACES) do
			vs[item1][item2] = {['win'] = 0, ['loss'] = 0}
		end
	end

	local foundData = false
	local processMatch = function(match)
		foundData = true
		vs = CustomPlayer._addScoresToVS(vs, match.match2opponents, player)
		local year = string.sub(match.date, 1, 4)
		years[tonumber(year)] = year
	end

	Lpdb.executeMassQuery('match2', queryParameters, processMatch)

	if foundData then
		local category
		if years[_CURRENT_YEAR] or years[_CURRENT_YEAR - 1] or years[_CURRENT_YEAR - 2] then
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

	for i = _START_YEAR, _CURRENT_YEAR do
		if years[i] then
			if (not tempYear) and (i ~= _CURRENT_YEAR) then
				if firstYear then
					firstYear = nil
				else
					yearsActive = yearsActive .. '<br/>'
				end
				yearsActive = yearsActive .. years[i]
				tempYear = years[i]
			end
			if i == _CURRENT_YEAR then
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

function CustomPlayer._addScoresToVS(vs, opponents, player)
	local plIndex = 1
	local vsIndex = 2
	--catch matches vs empty opponents
	if opponents[1] and opponents[2] then
		if opponents[2].name == player then
			plIndex = 2
			vsIndex = 1
		end
		local plOpp = opponents[plIndex]
		local vsOpp = opponents[vsIndex]

		local prace = CleanRace[plOpp.match2players[1].extradata.faction] or 'r'
		local orace = CleanRace[vsOpp.match2players[1].extradata.faction] or 'r'

		vs[prace][orace].win = vs[prace][orace].win + (tonumber(plOpp.score or 0) or 0)
		vs[prace][orace].loss = vs[prace][orace].loss + (tonumber(vsOpp.score or 0) or 0)

		vs['total'][orace].win = vs['total'][orace].win + (tonumber(plOpp.score or 0) or 0)
		vs['total'][orace].loss = vs['total'][orace].loss + (tonumber(vsOpp.score or 0) or 0)

		vs[prace]['total'].win = vs[prace]['total'].win + (tonumber(plOpp.score or 0) or 0)
		vs[prace]['total'].loss = vs[prace]['total'].loss + (tonumber(vsOpp.score or 0) or 0)

		vs['total']['total'].win = vs['total']['total'].win + (tonumber(plOpp.score or 0) or 0)
		vs['total']['total'].loss = vs['total']['total'].loss + (tonumber(vsOpp.score or 0) or 0)
	end

	return vs
end
]==]

function CustomPlayer:calculateEarnings()
	local earningsTotal
	earningsTotal, _earningsGlobal = CustomPlayer._getEarningsMedalsData(_player.pagename)
	earningsTotal = Math.round{earningsTotal}
	return earningsTotal, _earningsGlobal
end

function CustomPlayer._getEarningsMedalsData(player)
	local playerConditions = ConditionTree(BooleanOperator.any)
	for playerIndex = 1, _MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS do
		playerConditions:add{
			ConditionNode(ColumnName('players_p' .. playerIndex), Comparator.eq, player),
		}
	end

	local placementConditions = ConditionTree(BooleanOperator.any)
	for _, item in pairs(_ALLOWED_PLACES) do
		placementConditions:add{
			ConditionNode(ColumnName('placement'), Comparator.eq, item),
		}
	end

	local conditions = ConditionTree(BooleanOperator.all):add{
		playerConditions,
		ConditionNode(ColumnName('date'), Comparator.neq, '1970-01-01 00:00:00'),
		ConditionNode(ColumnName('liquipediatiertype'), Comparator.neq, 'Charity'),
		ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('individualprizemoney'), Comparator.gt, '0'),
			ConditionNode(ColumnName('extradata_award'), Comparator.neq, ''),
			ConditionTree(BooleanOperator.all):add{
				ConditionNode(ColumnName('players_type'), Comparator.gt, 'solo'),
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
		--handle earnings
		earnings, earningsTotal = CustomPlayer._addPlacementToEarnings(earnings, earningsTotal, placement)

		--handle medals
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
	local mode = _EARNING_MODES[(data.players or {}).type or ''] or 'other'
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
			(data.players or {}).type == 'solo'
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
		if Table.includes(_ALLOWED_PLACES, value) then
			return tonumber(value)
		end
	end
end

function CustomPlayer._setAchievements(data, place)
	local tier = tonumber(data.liquipediatier)
	if CustomPlayer._isAwardAchievement(data, tier) then
		table.insert(_awardAchievements, data)
	elseif #_achievements < _NUMBER_OF_ALLOWED_ACHIEVEMENTS then
		table.insert(_achievements, data)
	end
end

function CustomPlayer._isAwardAchievement(data, tier)
	return String.isNotEmpty((data.extradata or {}).award) and (
		tier == 1 or
		tier == 2 and data.individualprizemoney > 50
	)
end

function CustomPlayer:getWikiCategories(categories)
	if _args.tlpdsospa then
		table.insert(categories, 'SOSPA Players')
	end

	if _lpdbData.nationality ~= _KOREAN then
		table.insert(categories, 'Foreign Players')
	end

	return categories
end

return CustomPlayer
