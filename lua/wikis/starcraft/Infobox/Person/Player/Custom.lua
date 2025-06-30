---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Faction = Lua.import('Module:Faction')
local Info = Lua.import('Module:Info')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Math = Lua.import('Module:MathUtil')
local Namespace = Lua.import('Module:Namespace')
local Notability = Lua.import('Module:Notability')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local Injector = Lua.import('Module:Widget/Injector')
local Opponent = Lua.import('Module:Opponent')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local Condition = Lua.import('Module:Condition')
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

---@class StarcraftInfoboxPlayer: Person
---@field achievements placement[]
---@field awardAchievements placement[]
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.achievements = Achievements.player{noTemplate = true, baseConditions = {
		'[[liquipediatiertype::]]',
		'([[liquipediatier::1]] OR [[liquipediatier::2]])',
		'[[placement::1]]',
	}}

	player.achievements = {}
	player.awardAchievements = {}

	return player:createInfobox()
end

---@param args table
---@return boolean
function CustomPlayer:shouldStoreData(args)
	return Namespace.isMain() and
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
		and args.informationType ~= BOT_INFORMATION_TYPE
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		return self.caller:_addCustomCells(args)
	elseif id == 'status' then
		return {
			Cell{
				name = 'Race',
				content = {CustomPlayer._getRaceDisplay(args.race)}
			}
		}
	elseif id == 'role' then return {}
	elseif id == 'region' then return {}
	elseif
		id == 'history' and
		string.match(args.retired or '', '%d%d%d%d')
	then
		table.insert(widgets, Cell{name = 'Retired', content = {args.retired}})
	end
	return widgets
end

---@param args table
---@return Widget[]
function CustomPlayer:_addCustomCells(args)
	if args.informationType == BOT_INFORMATION_TYPE then
		return {
			Cell{name = 'Programmer', content = {args.programmer}},
			Cell{name = 'Affiliation', content = {args.affiliation}},
			Cell{name = 'Bot Version', content = {args.botversion}},
			Cell{name = 'BWAPI Version', content = {args.bwapiversion}},
			Cell{name = 'Language', content = {args.language}},
			Cell{name = 'Wrapper', content = {args.wrapper}},
			Cell{name = 'Terrain Analysis', content = {args.terrain_analysis}},
			Cell{name = 'AI Techniques', content = {args.aitechniques}},
			Cell{name = 'Framework', content = {args.framework}},
			Cell{name = 'Strategies', content = {args.strategies}},
		}
	end

	-- switch to enable yearsActive once 1v1 matches have been converted to match2 storage
	local yearsActive = Logic.readBool(args.enableYearsActive)
		and Namespace.isMain() and self:_getMatchupData() or nil

	local currentYearEarnings = self.earningsPerYear[CURRENT_YEAR]
	if currentYearEarnings then
		currentYearEarnings = Math.round(currentYearEarnings)
		currentYearEarnings = '$' .. mw.getContentLanguage():formatNum(currentYearEarnings)
	end

	return {
		Cell{
			name = 'Approx. Winnings ' .. CURRENT_YEAR,
			content = {currentYearEarnings}
		},
		Cell{name = 'Years active', content = {yearsActive}}
	}
end

---@param args table
---@return string
function CustomPlayer:nameDisplay(args)
	local factions = Faction.readMultiFaction(args.race or Faction.defaultFaction, {alias = false})

	local raceIcons = table.concat(Array.map(factions, function(faction)
		return Faction.Icon{faction = faction, size = 'medium'}
	end))

	local name = args.id or self.pagename

	return raceIcons .. '&nbsp;' .. name
end

---@param race string?
---@return string
function CustomPlayer._getRaceDisplay(race)
	local factionNames = Array.map(Faction.readMultiFaction(race, {alias = false}), Faction.toName)

	return table.concat(Array.map(factionNames or {}, function(factionName)
		return '[[:Category:' .. factionName .. ' Players|' .. factionName .. ']]'
	end) or {}, ',&nbsp;')
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	local extradata = lpdbData.extradata or {}

	local factions = Faction.readMultiFaction(args.race, {alias = false})

	extradata.race = factions[1]
	extradata.faction = Faction.toName(factions[1])
	extradata.faction2 = Faction.toName(factions[2])

	extradata.teamname = args.team

	if Variables.varDefault('racecount') then
		extradata.racehistorical = true
		extradata.factionhistorical = true
	end

	-- Notability values per year
	for year = Info.startYear, CURRENT_YEAR do
		extradata['notabilityin' .. year] = Notability.notabilityScore{
			players = self.pagename,
			startdate = year .. FIRST_DAY_OF_YEAR,
			enddate = year .. LAST_DAY_OF_YEAR,
			smmult = 0.5,
		}
	end

	lpdbData.extradata = extradata

	return lpdbData
end

---@return string?
function CustomPlayer:_getMatchupData()
	local yearsActive
	local playerWithoutUnderscore = string.gsub(self.pagename, '_', ' ')
	local player = self.pagename
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
		local year = string.sub(match.date, 1, 4)
		years[tonumber(year)] = year

		if Array.any(match.match2opponents, function(opponent) return opponent.status and opponent.status ~= 'S' end) then
			return
		end
		vs = CustomPlayer._addScoresToVS(vs, match.match2opponents, player, playerWithoutUnderscore)
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

---@param years integer[]
---@return string
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

---@param tbl table<string, table<string, table<string, number>>>
function CustomPlayer._setVarsForVS(tbl)
	for key1, item1 in pairs(tbl) do
		for key2, item2 in pairs(item1) do
			for key3, item3 in pairs(item2) do
				Variables.varDefine(key1 .. '_vs_' .. key2 .. '_' .. key3, item3)
			end
		end
	end
end

---@param vs table<string, table<string, table<string, number>>>
---@param opponents match2opponent[]
---@param player string
---@param playerWithoutUnderscore string
---@return table<string, table<string, table<string, number>>>
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

---@param args table
---@return number
---@return table<integer, number?>?
function CustomPlayer:calculateEarnings(args)
	local player = self.pagename
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
		ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDateTime),
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
		medals = self:_addPlacementToMedals(medals, placement)
	end

	Lpdb.executeMassQuery('placement', queryParameters, processPlacement)

	if #self.achievements > 0 then
		Variables.varDefine('achievements', Json.stringify(self.achievements))
	end
	if #self.awardAchievements > 0 then
		Variables.varDefine('awardAchievements', Json.stringify(self.awardAchievements))
	end
	CustomPlayer._setVarsFromTable(earnings)
	CustomPlayer._setVarsFromTable(medals)

	local earningsByYear = Table.map(earnings['total'], function(key, value)
		return tonumber(key) or key, Math.round(value)
	end)

	return Math.round(earningsTotal), earningsByYear
end

---@param earnings table<string, table<string, number>>
---@param earningsTotal number
---@param data placement
---@return table<string, table<string, number>>
---@return number
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

---@param medals table<string, table<string, number>>
---@param data placement
---@return table<string, table<string, number>>
function CustomPlayer:_addPlacementToMedals(medals, data)
	if data.liquipediatiertype ~= 'Qualifier' then
		local place = CustomPlayer._getPlacement(data.placement)
		self:_setAchievements(data, place)
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

---@param tbl table<string, table<string, number>>
function CustomPlayer._setVarsFromTable(tbl)
	for key1, item1 in pairs(tbl) do
		for key2, item2 in pairs(item1) do
			Variables.varDefine(key1 .. '_' .. key2, item2)
		end
	end
end

---@param value string
---@return number?
function CustomPlayer._getPlacement(value)
	if String.isNotEmpty(value) then
		value = mw.text.split(value, '-')[1]
		if Table.includes(ALLOWED_PLACES, value) then
			return tonumber(value)
		end
	end
end

---@param data placement
---@param place number?
function CustomPlayer:_setAchievements(data, place)
	local tier = tonumber(data.liquipediatier)
	if CustomPlayer._isAwardAchievement(data, tier) then
		table.insert(self.awardAchievements, data)
	elseif #self.achievements < NUMBER_OF_ALLOWED_ACHIEVEMENTS then
		table.insert(self.achievements, data)
	end
end

---@param data placement
---@param tier integer?
---@return boolean
function CustomPlayer._isAwardAchievement(data, tier)
	local prizeMoney = tonumber(data.individualprizemoney) or 0
	return String.isNotEmpty((data.extradata or {}).award) and (
		tier == 1 or
		tier == 2 and prizeMoney > 50
	)
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	local args = self.args
	if args.tlpdsospa then
		table.insert(categories, 'SOSPA Players')
	end

	if args.country ~= KOREAN then
		table.insert(categories, 'Foreign Players')
	end

	for _, faction in pairs(Faction.readMultiFaction(args.race, {alias = false})) do
		table.insert(categories, Faction.toName(faction) .. ' Players')
	end

	local botCategoryKeys = {
		'language',
		'wrapper',
		'terrain_analysis',
		'aitechniques',
		'framework',
	}
	for _, key in pairs(botCategoryKeys) do
		if args.informationType == BOT_INFORMATION_TYPE and args[key] then
			table.insert(categories, args[key] .. ' bot')
		end
	end

	return categories
end

---@param args table
---@return {store: string, category: string}
function CustomPlayer:getPersonType(args)
	return {store = args.defaultPersonType, category = args.defaultPersonType}
end

return CustomPlayer
