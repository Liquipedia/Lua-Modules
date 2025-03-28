---
-- @Liquipedia
-- wiki=commons
-- page=Module:ResultsTable/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local HighlightConditions = require('Module:HighlightConditions')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate') ---@module 'commons.TeamTemplate'
local Tier = require('Module:Tier/Custom')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local DEFAULT_VALUES = {
	order = 'desc',
	resolveOpponent = true,
	playerLimit = 10,
	coachLimit = 5,
	achievementsLimit = 10,
	resultsLimit = 5000,
}
local PLAYER_PREFIX = 'p'
local COACH_PREFIX = 'c'
---@enum validResultsTableQueryTypes
local QUERY_TYPES = {
	solo = 'solo',
	team = 'team',
	coach = 'coach',
}
local SCORE_CONCAT = '&nbsp;&#58;&nbsp;'
local DEFAULT_RESULTS_SUB_PAGE = 'Results'
local INVALID_TIER_DISPLAY = 'Undefined'
local INVALID_TIER_SORT = 'ZZ'

--- @class BaseResultsTable
local BaseResultsTable = Class.new(function(self, ...) self:init(...) end)

---Init function of the BaseResultsTable
---@param args table
---@return self
function BaseResultsTable:init(args)
	self.args = args

	self.pagename = mw.title.getCurrentTitle().text

	self.config = self:readConfig()

	return self
end

---Reads the configs of the results, achievements, awards table
---@return table
function BaseResultsTable:readConfig()
	local args = self.args

	local config = {
		showType = Logic.readBool(args.showType),
		order = args.order or DEFAULT_VALUES.order,
		hideResult = Logic.readBool(args.hideresult),
		resolveOpponent = Logic.readBool(args.resolve or DEFAULT_VALUES.resolveOpponent),
		displayGameIcons = Logic.readBool(args.gameIcons),
		opponent = mw.text.decode(args.coach or args.player or args.team or self:_getOpponent()),
		queryType = self:getQueryType(),
		onlyAchievements = Logic.readBool(args.achievements),
		playerResultsOfTeam = Logic.readBool(args.playerResultsOfTeam),
		resultsSubPage = args.resultsSubPage or DEFAULT_RESULTS_SUB_PAGE,
		displayDefaultLogoAsIs = Logic.readBool(args.displayDefaultLogoAsIs),
		onlyHighlightOnValue = args.onlyHighlightOnValue,
		useIndivPrize = Logic.readBool(args.useIndivPrize),
		aliases = args.aliases and Array.map(mw.text.split(args.aliases, ','), String.trim) or {}
	}

	config.sort = args.sort or
		(config.onlyAchievements and 'weight' or 'date')

	config.limit = tonumber(args.limit) or
		(config.onlyAchievements and DEFAULT_VALUES.achievementsLimit or DEFAULT_VALUES.resultsLimit)

	config.playerLimit =
		(config.queryType == QUERY_TYPES.solo and (tonumber(args.playerLimit) or DEFAULT_VALUES.playerLimit))
		or tonumber(args.coachLimit) or DEFAULT_VALUES.coachLimit

	if config.queryType == QUERY_TYPES.team and Table.isNotEmpty(config.aliases) then
		config.nonAliasTeamTemplates = BaseResultsTable._getOpponentTemplates(config.opponent)
	end

	return config
end

---Determines the opponent (player coach team) if not entered
---@return string
function BaseResultsTable:_getOpponent()
	if Namespace.isMain() then
		return mw.title.getCurrentTitle().baseText
	elseif String.contains(mw.title.getCurrentTitle().subpageText:lower(), 'results') then
		local pageName = mw.text.split(mw.title.getCurrentTitle().text, '/')
		return pageName[#pageName - 1]
	end

	return mw.title.getCurrentTitle().subpageText
end

---Determines the queryType
---@return validResultsTableQueryTypes
function BaseResultsTable:getQueryType()
	local args = self.args

	if args.querytype then
		local queryType = args.querytype:lower()
		if Table.includes(QUERY_TYPES, queryType) then
			return queryType
		end
	end

	error('Invalid querytype "' .. (args.querytype or '') .. '"')
end

---Creates the results, achievements, awards table
---@return self
function BaseResultsTable:create()
	local data = self.args.data or self:queryData()

	if Table.isEmpty(data) then
		self.data = {}
		return self
	end

	table.sort(data, function(placement1, placement2) return placement1.date > placement2.date end)

	if self.config.onlyAchievements then
		self.data = {data}
		return self
	end

	-- split placements into years for non achievements
	local splitData = Array.groupBy(data, function(placementData)
		return placementData.date:sub(1,4)
	end)
	--we want to insert values for named keys hence table[][] would cause annotation warnings
	---@cast splitData table[]

	-- Set the header
	Array.forEach(splitData, function(dataSet)
		dataSet.header = dataSet[1].date:sub(1,4)
	end)

	self.data = Array.sortBy(splitData, function(val) return val.header end, function(val1, val2) return val1 > val2 end)

	return self
end

---Fetches data from Lpdb
---@return table[]
function BaseResultsTable:queryData()
	local data = mw.ext.LiquipediaDB.lpdb('placement', {
		limit = self.config.limit,
		order = self.config.sort .. ' ' .. self.config.order,
		conditions = self:buildConditions(),
	})

	if type(data) ~= 'table' then
		mw.logObject(self:buildConditions(), 'conditions')
		error(data)
	end

	return data
end

---Builds the conditions for the results, achievements, awards table
---@return string
function BaseResultsTable:buildConditions()
	if self.args.customConditions then
		return self.args.customConditions
	end

	local conditions = self:buildBaseConditions()

	if self.args.additionalConditions then
		return conditions .. self.args.additionalConditions
	end

	return conditions
end

---Builds the base conditions for the results, achievements, awards table
---@return string
function BaseResultsTable:buildBaseConditions()
	local args = self.args

	local conditions = ConditionTree(BooleanOperator.all)
		:add{self:buildOpponentConditions()}

	if args.game then
		conditions:add{ConditionNode(ColumnName('game'), Comparator.eq, args.game)}
	end

	local startDate = args.startdate or args.sdate
	if startDate then
		-- intentional > here to keep it as is in current modules
		-- possibly change to >= later
		conditions:add{ConditionNode(ColumnName('date'), Comparator.gt, startDate)}
	end

	local endDate = args.enddate or args.edate
	if endDate then
		-- intentional < here to keep it as is in current modules
		-- possibly change to <= later
		conditions:add{ConditionNode(ColumnName('date'), Comparator.lt, endDate)}
	end

	if args.placement then
		conditions:add{ConditionNode(ColumnName('placement'), Comparator.eq, args.placement)}
	elseif Logic.readBool(args.awards) then
		conditions:add{ConditionNode(ColumnName('mode'), Comparator.eq, 'award_individual')}
	else
		conditions:add{ConditionNode(ColumnName('mode'), Comparator.neq, 'award_individual')}
		conditions:add{ConditionNode(ColumnName('placement'), Comparator.neq, '')}
	end

	if args.tier then
		local tierConditions = ConditionTree(BooleanOperator.any)
		for _, tier in pairs(Array.map(mw.text.split(args.tier, ',', true), String.trim)) do
			tierConditions:add{ConditionNode(ColumnName('liquipediatier'), Comparator.eq, tier)}
		end
		conditions:add{tierConditions}
	end

	return conditions:toString()
end

---Builds Lpdb conditions for the given opponent
---@return table?
function BaseResultsTable:buildOpponentConditions()
	local config = self.config

	if config.queryType == QUERY_TYPES.solo or config.queryType == QUERY_TYPES.coach then
		return self:buildNonTeamOpponentConditions()
	elseif config.queryType == QUERY_TYPES.team then
		return self:buildTeamOpponentConditions()
	end
end

-- todo: adjust once #1802 is done
---Builds Lpdb conditions for the non team opponent case
---@return table
function BaseResultsTable:buildNonTeamOpponentConditions()
	local config = self.config
	local opponentConditions = ConditionTree(BooleanOperator.any)

	local opponents = Array.append(config.aliases, config.opponent)

	for _, opponent in pairs(opponents) do
		opponent = config.resolveOpponent
			and mw.ext.TeamLiquidIntegration.resolve_redirect(opponent)
			or opponent

		local opponentWithUnderscore = opponent:gsub(' ', '_')

		local prefix
		if config.queryType == QUERY_TYPES.solo then
			prefix = PLAYER_PREFIX
			opponentConditions:add{
				ConditionTree(BooleanOperator.all):add{
					ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.solo),
					ConditionNode(ColumnName('opponentname'), Comparator.eq, opponent),
				},
				ConditionTree(BooleanOperator.all):add{
					ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.solo),
					ConditionNode(ColumnName('opponentname'), Comparator.eq, opponentWithUnderscore),
				},
			}
		else
			prefix = COACH_PREFIX
		end

		for playerIndex = 1, config.playerLimit do
			opponentConditions:add{
				ConditionNode(ColumnName('opponentplayers_' .. prefix .. playerIndex), Comparator.eq, opponent),
				ConditionNode(ColumnName('opponentplayers_' .. prefix .. playerIndex), Comparator.eq, opponentWithUnderscore),
			}
		end
	end

	return opponentConditions
end

---Builds Lpdb conditions for a team
---@return table
function BaseResultsTable:buildTeamOpponentConditions()
	local config = self.config

	local opponents = Array.append(config.aliases, config.opponent)
	local opponentTeamTemplates = Array.flatten(Array.map(opponents, BaseResultsTable._getOpponentTemplates))

	if config.playerResultsOfTeam then
		return self:buildPlayersOnTeamOpponentConditions(opponentTeamTemplates)
	end

	local opponentConditions = ConditionTree(BooleanOperator.any)
	for _, teamTemplate in pairs(opponentTeamTemplates) do
		opponentConditions:add{ConditionNode(ColumnName('opponenttemplate'), Comparator.eq, teamTemplate)}
	end

	return ConditionTree(BooleanOperator.all):add{
			opponentConditions,
			ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.team),
		}
end

---Fetches the team templates for a given team
---@param opponent string
---@return string[]
function BaseResultsTable._getOpponentTemplates(opponent)
	if not TeamTemplate.exists(opponent) then
		error(TeamTemplate.noTeamMessage(opponent))
	end
	return TeamTemplate.queryHistoricalNames(opponent)
end

---Builds Lpdb conditions for players on a given team
---@param opponentTeamTemplates string[]
---@return ConditionTree
function BaseResultsTable:buildPlayersOnTeamOpponentConditions(opponentTeamTemplates)
	local config = self.config

	local opponentConditions = ConditionTree(BooleanOperator.any)

	local prefix = PLAYER_PREFIX
	for _, teamTemplate in pairs(opponentTeamTemplates) do
		for playerIndex = 1, config.playerLimit do
			opponentConditions:add{
				ConditionNode(ColumnName('opponentplayers_' .. prefix .. playerIndex .. 'template'), Comparator.eq, teamTemplate),
			}
		end
	end

	return ConditionTree(BooleanOperator.all):add{
		opponentConditions,
		ConditionNode(ColumnName('opponenttype'), Comparator.neq, Opponent.team),
	}
end

---Builds the results/achievements/awards table
---@return Html
function BaseResultsTable:build()
	local displayTable = mw.html.create('table')
		:addClass('wikitable wikitable-striped sortable')
		:css('text-align', 'center')
		:node(self:buildHeader())

	if Table.isEmpty(self.data) or Table.isEmpty(self.data[1]) then
		return displayTable:node(mw.html.create('tr')
			:tag('td'):attr('colspan', 42):wikitext('No recorded results found.'))
	end

	for _, dataSet in ipairs(self.data) do
		for _, row in ipairs(self:_buildRows(dataSet)) do
			displayTable:node(row)
		end
	end

	if self.config.onlyAchievements then
		displayTable:tag('tr')
			:tag('th')
				:attr('colspan', 42)
				:css('font-style', 'italic')
				:wikitext('[[' .. self.config.opponent .. '/' .. self.config.resultsSubPage .. '|Extended list of results]]')
	end

	displayTable:node(self.args.manualContent)

	return mw.html.create('div')
		:addClass('table-responsive')
		:node(displayTable)
end

---comment
---@param placementData table
---@return Html[]
function BaseResultsTable:_buildRows(placementData)
	local rows = {}

	if placementData.header then
		table.insert(rows, mw.html.create('tr'):addClass('sortbottom')
			:tag('th'):attr('colspan', 42):wikitext(placementData.header):done()
			:done())
	end

	for _, placement in ipairs(placementData) do
		table.insert(rows, self:buildRow(placement))
	end

	return rows
end

-- overwritable
---Applies the row highlight
---@param placement table
---@return string?
function BaseResultsTable:rowHighlight(placement)
	if HighlightConditions.tournament(placement, self.config) then
		return 'tournament-highlighted-bg'
	end
end

-- overwritable
---Builds the tier display
---@param placement table
---@return string?, string?
function BaseResultsTable:tierDisplay(placement)
	local tier, tierType, options = Tier.parseFromQueryData(placement)
	options.link = true
	options.onlyTierTypeIfBoth = true

	if not Tier.isValid(tier, tierType) then
		return INVALID_TIER_DISPLAY, INVALID_TIER_SORT
	end

	return Tier.display(tier, tierType, options), Tier.toSortValue(tier, tierType)
end

-- overwritable
---Builds the opponent display
---@param data table
---@param options table?
---@return Html?
function BaseResultsTable:opponentDisplay(data, options)
	options = options or {}

	if not data.opponenttype then
		return OpponentDisplay.BlockOpponent{
			opponent = Opponent.tbd(),
			flip = options.flip,
		}
	elseif data.opponenttype ~= Opponent.team and (data.opponenttype ~= Opponent.solo or not options.teamForSolo) then
		return OpponentDisplay.BlockOpponent{
			opponent = Opponent.fromLpdbStruct(data) --[[@as standardOpponent]],
			flip = options.flip,
		}
	elseif self.config.displayDefaultLogoAsIs then
		return OpponentDisplay.BlockOpponent{
			opponent = Opponent.fromLpdbStruct(data) --[[@as standardOpponent]],
			flip = options.flip,
			teamStyle = 'icon',
		}
	end

	local teamTemplate
	if data.opponenttype == Opponent.team then
		teamTemplate = data.opponenttemplate
	else
		teamTemplate = data.opponentplayers.p1template
	end

	if String.isEmpty(teamTemplate) then
		return
	end

	local rawTeamTemplate = TeamTemplate.getRawOrNil(teamTemplate, data.date) or {}

	local teamDisplay = OpponentDisplay.BlockOpponent{
		opponent = {template = rawTeamTemplate.templatename, type = Opponent.team},
		flip = options.flip,
		teamStyle = 'icon',
	}

	if self:shouldDisplayAdditionalText(rawTeamTemplate, not options.isLastVs) then
		return BaseResultsTable.teamIconDisplayWithText(teamDisplay, rawTeamTemplate, options.flip)
	end

	return teamDisplay
end

---Checks if additional text should be displayed below the team icon
---@param rawTeamTemplate table
---@param isNotLastVs boolean?
---@return boolean?
function BaseResultsTable:shouldDisplayAdditionalText(rawTeamTemplate, isNotLastVs)
	local config = self.config

	return rawTeamTemplate and (
		Game.isDefaultTeamLogo{logo = rawTeamTemplate.image} or
		(isNotLastVs and config.nonAliasTeamTemplates
			and not Table.includes(config.nonAliasTeamTemplates, rawTeamTemplate.templatename))
	)
end

---Builds team icon display with text below it
---@param teamDisplay Html
---@param rawTeamTemplate table
---@param flip boolean?
---@return Html
function BaseResultsTable.teamIconDisplayWithText(teamDisplay, rawTeamTemplate, flip)
	return mw.html.create()
		:node(teamDisplay)
		:node(mw.html.create('div')
			:css('width', '60px')
			:css('float', flip and 'right' or 'left')
			:node(
				mw.html.create('div')
					:css('line-height', '1')
					:css('font-size', '80%')
					:css('text-align', 'center')
					:wikitext('([[' .. rawTeamTemplate.page .. '|' .. rawTeamTemplate.shortname .. ']])')
			)
		)
end

---Builds the tournament display name
---@param placement table
---@return string
function BaseResultsTable.tournamentDisplayName(placement)
	if String.isNotEmpty(placement.tournament) then
		return placement.tournament
	end

	return (placement.pagename:gsub('_', ' '))
end

---Converts the lastvsdata to display components
---@param placement table
---@return string, Html?, string?
function BaseResultsTable:processVsData(placement)
	local lastVs = placement.lastvsdata or {}

	if Logic.isNotEmpty(lastVs.groupscore) then
		return placement.groupscore, nil, Abbreviation.make('Grp S.', 'Group Stage')
	end

	local score = ''
	if Logic.isNotEmpty(placement.lastscore) or String.isNotEmpty(lastVs.score) then
		score = (placement.lastscore or '-') .. SCORE_CONCAT .. (lastVs.score or '-')
	end

	local vsDisplay = self:opponentDisplay(lastVs, {isLastVs = true})

	return score, vsDisplay
end

function BaseResultsTable:buildHeader()
	error('Function "buildHeader" needs to be set via the module that requires "Module:BaseResultsTable/Base"')
end

---@param placement table
function BaseResultsTable:buildRow(placement)
	error('Function "buildRow" needs to be set via the module that requires "Module:BaseResultsTable/Base"')
end

return BaseResultsTable
