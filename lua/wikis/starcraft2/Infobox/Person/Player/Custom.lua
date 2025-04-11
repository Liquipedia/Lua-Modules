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
local DateExt = require('Module:Date/Ext')
local Faction = require('Module:Faction')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Lpdb = require('Module:Lpdb')
local MatchTicker = require('Module:MatchTicker/Custom')
local Math = require('Module:MathUtil')
local Set = require('Module:Set')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local YearsActive = require('Module:YearsActive')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local CustomPerson = Lua.import('Module:Infobox/Person/Custom')
local Opponent = Lua.import('Module:Opponent/Starcraft')

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local EPT_SEASON = mw.loadData('Module:Series/EPT/config').currentSeason

local ALLOWED_PLACES = {'1', '2', '3', '4', '3-4'}
local ALL_KILL_ICON = '[[File:AllKillIcon.png|link=All-Kill Format]]&nbsp;×&nbsp;'
local MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS = 20
local MINIMUM_NUMBER_OF_ALLOWED_ACHIEVEMENTS = 10
local MAXIMUM_NUMBER_OF_ACHIEVEMENTS = 30
local NUMBER_OF_RECENT_MATCHES = 10

--race stuff
local RACE_FIELD_AS_CATEGORY_LINK = true
local CURRENT_YEAR = tonumber(os.date('%Y'))

local Injector = Lua.import('Module:Widget/Injector')
local Widgets = Lua.import('Module:Widget/All')

local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class Starcraft2InfoboxPlayer: SC2CustomPerson
---@field shouldQueryData boolean
---@field recentMatches match2[]?
---@field stats table<string, table<string, {w: number, l: number}>>?
---@field years number[]?
---@field earnings table<integer, table<string, number>>?
---@field medals table<string, table<string, integer>>?
---@field achievements placement[]?
---@field awardAchievements placement[]?
---@field infoboxAchievements placement[]?
local CustomPlayer = Class.new(CustomPerson)

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.shouldQueryData = player:shouldStoreData(player.args)

	if player.shouldQueryData then
		player:_getMatchupData(player.pagename)
	end

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		local ranks = caller:_getRank()
		local currentYearEarnings = caller.earningsPerYear[CURRENT_YEAR] or 0

		return {
			Cell{
				name = 'Approx. Winnings ' .. CURRENT_YEAR,
				content = {currentYearEarnings > 0 and ('$' .. mw.getContentLanguage():formatNum(currentYearEarnings)) or nil}
			},
			Cell{name = ranks[1].name or 'Rank', content = {ranks[1].rank}},
			Cell{name = ranks[2].name or 'Rank', content = {ranks[2].rank}},
			Cell{name = 'Military Service', content = {args.military}},
			Cell{
				name = Abbreviation.make('Years Active', 'Years active as a player'),
				content = {caller.yearsActive}
			},
			Cell{
				name = Abbreviation.make('Years Active (caster)', 'Years active as a caster'),
				content = {self.caller:_getActiveCasterYears()}
			},
		}
	elseif id == 'status' then
		return {
			Cell{
				name = 'Race',
				content = {caller:getRaceData(args.race or 'unknown', RACE_FIELD_AS_CATEGORY_LINK)}
			}
		}
	elseif id == 'role' then return {}
	elseif id == 'region' then return {}
	elseif id == 'achievements' and caller.shouldQueryData then
		local allkills = caller:_getAllkills() or 0
		if Table.isEmpty(caller.infoboxAchievements) and allkills == 0 then
			return {}
		end

		return {
			Title{children = 'Achievements'},
			Center{children = {Achievements.display(caller.infoboxAchievements)}},
			Cell{name = 'All-Kills', content = {allkills > 0 and (ALL_KILL_ICON .. allkills) or nil}}
		}
	elseif id == 'achievements' then return {}
	elseif id == 'history' and string.match(args.retired or '', '%d%d%d%d') then
		table.insert(widgets, Cell{name = 'Retired', content = {args.retired}})
	end

	return widgets
end

---@return string?
function CustomPlayer:_getActiveCasterYears()
	if not self.shouldQueryData then return end

	local queryData = mw.ext.LiquipediaDB.lpdb('broadcasters', {
		query = 'year::date',
		conditions = '[[page::' .. self.pagename .. ']] OR [[page::' .. self.pagename:gsub(' ', '_') .. ']]',
		limit = 5000,
	})

	local years = Set{}
	Array.forEach(queryData,
		---@param item broadcasters
		---@return number?
		function(item) years:add(tonumber(item.year_date)) end
	)

	return YearsActive.displayYears(years:toArray())
end

---@return Html?
function CustomPlayer:createBottomContent()
	if self.shouldQueryData then
		return MatchTicker.participant({player = self.pagename}, self.recentMatches)
	end
end

---@param player string
function CustomPlayer:_getMatchupData(player)
	-- set empty data tables
	self.recentMatches = {}
	self.stats = {total = {}}

	player = player:gsub(' ', '_')
	local playerWithoutUnderscore = player:gsub('_', ' ')

	local years = Set{}

	---@param match match2
	local processMatch = function(match)
		local year = tonumber(string.sub(match.date, 1, 4))
		years:add(year)

		if #self.recentMatches < NUMBER_OF_RECENT_MATCHES then
			table.insert(self.recentMatches, match)
		end

		if Array.any(match.match2opponents, function(opponent) return opponent.status and opponent.status ~= 'S' end) then
			return
		end

		self:_addToStats(match, player, playerWithoutUnderscore)
	end

	Lpdb.executeMassQuery('match2', {
		conditions = table.concat({
			'[[finished::1]]', -- only finished matches
			'[[winner::!]]', -- expect a winner
			'[[status::!notplayed]]', -- i.e. ignore not played matches
			'[[date::!' .. DateExt.defaultDate .. ']]', --i.e. wrongly set up
			'([[opponent::' .. player .. ']] OR [[opponent::' .. playerWithoutUnderscore .. ']])'
		}, ' AND '),
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
	}, processMatch)

	self.years = years:toArray()
	self.yearsActive = YearsActive.displayYears(self.years)
end

---@param match match2
---@param player string
---@param playerWithoutUnderscore string
function CustomPlayer:_addToStats(match, player, playerWithoutUnderscore)
	local opponents = match.match2opponents

	--catch matches vs empty opponents and literals
	if #opponents ~= 2 or Array.any(opponents, function(opponent) return opponent.type == Opponent.literal end) then
		return
	end

	local playerIndex = (opponents[1].name == player or opponents[1].name == playerWithoutUnderscore) and 1 or 2
	local playerOpponent = opponents[playerIndex]
	local vsOpponent = opponents[3 - playerIndex]

	local playerScore = tonumber(playerOpponent.score) or 0
	local vsScore = tonumber(vsOpponent.score) or 0

	if playerScore < 0 or vsScore < 0 or (vsScore + playerScore == 0) then return end

	local getFaction = function(opponent)
		local faction = Faction.read(opponent.match2players[1].extradata.faction)
		-- treat default faction as random
		return faction ~= Faction.defaultFaction and faction or Faction.read('r')
	end
	local playerRace = getFaction(playerOpponent)
	local vsRace = getFaction(vsOpponent)

	self.stats[playerRace] = self.stats[playerRace] or {}

	local addScores = function(statsTable)
		statsTable[vsRace] = statsTable[vsRace] or self.emptyStatsCell()
		statsTable.total = statsTable.total or self.emptyStatsCell()

		statsTable[vsRace].w = statsTable[vsRace].w + playerScore
		statsTable[vsRace].l = statsTable[vsRace].l + vsScore

		statsTable.total.w = statsTable.total.w + playerScore
		statsTable.total.l = statsTable.total.l + vsScore
	end

	addScores(self.stats.total)
	addScores(self.stats[playerRace])
end

---@return {w: integer, l: integer}
function CustomPlayer.emptyStatsCell()
	return {w = 0, l = 0}
end

---@return boolean
function CustomPlayer:_isActive()
	return Table.includes(self.years or {}, CURRENT_YEAR) or Table.includes(self.years or {}, CURRENT_YEAR - 1)
end

---@param args table
---@return number
---@return table<integer, number?>?
function CustomPlayer:calculateEarnings(args)
	self.earnings = {}
	self.medals = {total = self:_emptyMedalsRow()}
	self.achievements = {}
	self.awardAchievements = {}
	self.infoboxAchievements = {}
	local fallBackAchievements = {}

	local processPlacement = function(placement)
		self:_addToEarnings(placement)
		self:_addToMedals(placement, fallBackAchievements)
	end

	local player = self.pagename
	local playerWithUnderScores = player:gsub(' ', '_')

	local playerConditions = ConditionTree(BooleanOperator.any)
	Array.forEach(Array.range(1, MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS), function (playerIndex)
		playerConditions:add({
			ConditionNode(ColumnName('opponentplayers_p' .. playerIndex), Comparator.eq, player),
			ConditionNode(ColumnName('opponentplayers_p' .. playerIndex), Comparator.eq, playerWithUnderScores),
		})
	end)

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
		ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDateTime),
		ConditionNode(ColumnName('liquipediatier'), Comparator.neq, '-1'),
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

	Lpdb.executeMassQuery('placement', {
		conditions = conditions:toString(),
		order = 'liquipediatier asc, weight desc, placement asc',
	}, processPlacement)

	if #self.achievements < MINIMUM_NUMBER_OF_ALLOWED_ACHIEVEMENTS then
		Array.extendWith(
			self.achievements,
			Array.sub(fallBackAchievements, 1, MINIMUM_NUMBER_OF_ALLOWED_ACHIEVEMENTS - #self.achievements)
		)
	end

	local sumUp = function(dataSet)
		local sum = 0
		for _, value in pairs(dataSet) do
			sum = sum + value
		end
		return sum
	end

	local earningsByYear = Table.mapValues(self.earnings, function (dataSet)
		return Math.round(sumUp(dataSet))
	end)

	return sumUp(earningsByYear), earningsByYear
end

---@param placement placement
function CustomPlayer:_addToEarnings(placement)
	local prize = tonumber(placement.individualprizemoney) or 0
	if prize == 0 then return end

	self.hasEarnings = true

	local mode = placement.opponenttype == Opponent.solo and Opponent.solo
		or placement.opponenttype == Opponent.team and Opponent.team
		or 'other'

	local year = tonumber(string.sub(placement.date, 1, 4)) --[[@as number]]

	self.earnings[year] = self.earnings[year] or {[Opponent.solo] = 0, [Opponent.team] = 0, other = 0}

	self.earnings[year][mode] = self.earnings[year][mode] + prize
end

---@param placement placement
---@param fallBackAchievements placement[]
function CustomPlayer:_addToMedals(placement, fallBackAchievements)
	if placement.liquipediatiertype == 'Qualifier' then return end

	self:_setAchievements(placement, fallBackAchievements)

	local isMedal = Table.includes(ALLOWED_PLACES, placement.placement or '')

	if placement.opponenttype ~= Opponent.solo or not isMedal then return end

	local place = placement.placement
	local tier = placement.liquipediatier or 'undefined'

	self.medals[tier] = self.medals[tier] or self:_emptyMedalsRow()

	self.medals[tier].total = self.medals[tier].total + 1
	self.medals[tier][place] = self.medals[tier][place] + 1
	self.medals.total[place] = self.medals.total[place] + 1
	self.medals.total.total = self.medals.total.total + 1
end

---@return table<string, integer>
function CustomPlayer:_emptyMedalsRow()
	return Table.merge(
		{total = 0},
		Table.map(ALLOWED_PLACES, function(_, placement) return placement, 0 end)
	)
end

---@param placement placement
---@param fallBackAchievements placement[]
function CustomPlayer:_setAchievements(placement, fallBackAchievements)
	local tier = tonumber(placement.liquipediatier)
	local place = tonumber(mw.text.split(placement.placement, '-')[1])
	local hasNoTierType = String.isEmpty(placement.liquipediatiertype)

	if tier == 1 and place == 1 and placement.opponenttype == Opponent.solo and hasNoTierType then
		table.insert(self.infoboxAchievements, placement)
	end

	if self:_isAwardAchievemnet(placement, tier) then
		table.insert(self.awardAchievements, placement)
	elseif String.isNotEmpty((placement.extradata or {}).award) then
		return
	elseif self:_isAchievement(placement, tier, place) then
		table.insert(self.achievements, placement)
	elseif (#fallBackAchievements + #self.achievements) < MINIMUM_NUMBER_OF_ALLOWED_ACHIEVEMENTS then
		table.insert(fallBackAchievements, placement)
	end
end

---@param placement placement
---@param tier integer?
---@return boolean
function CustomPlayer:_isAwardAchievemnet(placement, tier)
	return String.isNotEmpty((placement.extradata or {}).award) and (
		tier == 1 or
		tier == 2 and (tonumber(placement.individualprizemoney) or 0) > 50
	)
end

---@param placement placement
---@param tier integer?
---@param place integer?
---@return boolean
function CustomPlayer:_isAchievement(placement, tier, place)
	if not Table.includes(ALLOWED_PLACES, placement.placement) or not place then return false end

	return tier == 1 and place <= 4
		or tier == 2 and place <= 2
		or #self.achievements < MAXIMUM_NUMBER_OF_ACHIEVEMENTS and (
			tier == 2 and place <= 4 or
			tier == 3 and place <= 2 or
			tier == 4 and place <= 1
		)
end

---@return {name:string?, rank: string?}[]
function CustomPlayer:_getRank()
	if not self.shouldQueryData then return {{}, {}} end

	local rankRegion = require('Module:EPT player region ' .. EPT_SEASON)[self.pagename]
		or {'noregion'}
	local typeCond = '([[type::EPT ' ..
		table.concat(rankRegion, ' ranking ' .. EPT_SEASON .. ']] OR [[type::EPT ')
		.. ' ranking ' .. EPT_SEASON .. ']])'

	local data = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[name::' .. self.pagename .. ']] AND ' .. typeCond,
		query = 'extradata, information, pagename',
		limit = 10
	})

	if type(data[1]) ~= 'table' then return {{}, {}} end

	---@param dataSet datapoint
	---@return {name:string?, rank: string?}
	local getRankDisplay = function(dataSet)
		local extradata = (dataSet or {}).extradata or {}
		if not extradata.rank then return {} end

		return {
			name = 'EPT ' .. (dataSet.information or '') .. ' rank',
			rank = '[[' .. dataSet.pagename .. '|#' .. extradata.rank .. ' (' .. extradata.points .. ' points)]]'
		}
	end

	return {
		getRankDisplay(data[1]),
		getRankDisplay(data[2]),
	}
end

---@return number?
function CustomPlayer:_getAllkills()
	if not self.shouldQueryData then return end

	local allkillsData = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[pagename::' .. self.pagename:gsub(' ', '_') .. ']] AND [[type::allkills]]',
		query = 'information',
		limit = 1
	})
	if type(allkillsData[1]) == 'table' then
		return tonumber(allkillsData[1].information)
	end
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	for _, faction in pairs(self:readFactions(self.args.race).factions) do
		table.insert(categories, faction .. ' Players')
	end

	table.insert(categories, self:military(self.args.military).category)

	if not self:_isActive() then
		table.insert(categories, 'Players with no matches in the last two years')
	end

	return categories
end

---@param args table
function CustomPlayer:defineCustomPageVariables(args)
	Variables.varDefine('matchUpStats', Json.stringify(self.stats or {}))
	Variables.varDefine('isActive', tostring(self:_isActive()))
	Variables.varDefine('achievements', Json.stringify(self.achievements or {}))
	Variables.varDefine('awardAchievements', Json.stringify(self.awardAchievements or {}))
	Variables.varDefine('earningsStats', Json.stringify(self.earnings or {}))
	Variables.varDefine('medals', Json.stringify(self.medals or {}))
end

return CustomPlayer
