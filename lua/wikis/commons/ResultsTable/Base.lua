---
-- @Liquipedia
-- page=Module:ResultsTable/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Currency = Lua.import('Module:Currency')
local DateExt = Lua.import('Module:Date/Ext')
local Game = Lua.import('Module:Game')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local Info = Lua.import('Module:Info', {loadData = true})
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Tier = Lua.import('Module:Tier/Custom')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local LinkWidget = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DEFAULT_VALUES = {
	order = 'desc',
	resolveOpponent = true,
	playerLimit = Info.config.defaultMaxPlayersPerPlacement or 10,
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
local SCORE_CONCAT = '&nbsp;&colon;&nbsp;'
local DEFAULT_RESULTS_SUB_PAGE = 'Results'
local INVALID_TIER_DISPLAY = 'Undefined'
local INVALID_TIER_SORT = 'ZZ'

---@class BaseResultsTable
---@operator call(table): BaseResultsTable
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
		aliases = Array.parseCommaSeparatedString(args.aliases)
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
---@return placement[]
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
		conditions:add(ConditionNode(ColumnName('game'), Comparator.eq, args.game))
	end

	local startDate = args.startdate or args.sdate
	if startDate then
		-- intentional > here to keep it as is in current modules
		-- possibly change to >= later
		conditions:add(ConditionNode(ColumnName('date'), Comparator.gt, startDate))
	end

	local endDate = args.enddate or args.edate
	if endDate then
		-- intentional < here to keep it as is in current modules
		-- possibly change to <= later
		conditions:add(ConditionNode(ColumnName('date'), Comparator.lt, endDate))
	end

	if args.placement then
		conditions:add(ConditionNode(ColumnName('placement'), Comparator.eq, args.placement))
	elseif Logic.readBool(args.awards) then
		conditions:add(ConditionNode(ColumnName('mode'), Comparator.eq, 'award_individual'))
	else
		conditions:add{
			ConditionNode(ColumnName('mode'), Comparator.neq, 'award_individual'),
			ConditionNode(ColumnName('placement'), Comparator.neq, '')
		}
	end

	if args.tier then
		conditions:add(
			ConditionUtil.anyOf(ColumnName('liquipediatier'), Array.parseCommaSeparatedString(args.tier))
		)
	end

	return conditions:toString()
end

---Builds Lpdb conditions for the given opponent
---@return ConditionTree?
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
---@return ConditionTree
function BaseResultsTable:buildNonTeamOpponentConditions()
	local config = self.config
	local opponentConditions = ConditionTree(BooleanOperator.any)

	local opponents = Array.append(config.aliases, config.opponent)

	Array.forEach(opponents, function (opponent)
		opponent = config.resolveOpponent
			and mw.ext.TeamLiquidIntegration.resolve_redirect(opponent)
			or opponent

		local opponentWithUnderscore = opponent:gsub(' ', '_')

		local prefix
		if config.queryType == QUERY_TYPES.solo then
			prefix = PLAYER_PREFIX
			opponentConditions:add(ConditionTree(BooleanOperator.all):add{
				ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.solo),
				ConditionUtil.anyOf(ColumnName('opponentname'), {opponent, opponentWithUnderscore})
			})
		else
			prefix = COACH_PREFIX
		end

		Array.forEach(Array.range(1, config.playerLimit), function (playerIndex)
			local playerColumnName = ColumnName('opponentplayers_' .. prefix .. playerIndex)
			opponentConditions:add{
				ConditionNode(playerColumnName, Comparator.eq, opponent),
				ConditionNode(playerColumnName, Comparator.eq, opponentWithUnderscore),
			}
		end)
	end)

	return opponentConditions
end

---Builds Lpdb conditions for a team
---@return ConditionTree
function BaseResultsTable:buildTeamOpponentConditions()
	local config = self.config

	local opponents = Array.append(config.aliases, config.opponent)
	local opponentTeamTemplates = Array.flatMap(opponents, BaseResultsTable._getOpponentTemplates)

	if config.playerResultsOfTeam then
		return self:buildPlayersOnTeamOpponentConditions(opponentTeamTemplates)
	end

	local opponentConditions = ConditionUtil.anyOf(ColumnName('opponenttemplate'), opponentTeamTemplates)

	return ConditionTree(BooleanOperator.all):add{
			opponentConditions,
			ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.team),
		}
end

---Fetches the team templates for a given team
---@param opponent string
---@return string[]
function BaseResultsTable._getOpponentTemplates(opponent)
	local rawOpponentTemplate = TeamTemplate.getRawOrNil(opponent) or {}
	local opponentTemplate = rawOpponentTemplate.historicaltemplate or rawOpponentTemplate.templatename
	if not opponentTemplate then
		error(TeamTemplate.noTeamMessage(opponent))
	end

	return TeamTemplate.queryHistoricalNames(opponentTemplate)
end

---Builds Lpdb conditions for players on a given team
---@param opponentTeamTemplates string[]
---@return ConditionTree
function BaseResultsTable:buildPlayersOnTeamOpponentConditions(opponentTeamTemplates)
	local config = self.config

	local opponentConditions = ConditionTree(BooleanOperator.any)

	local prefix = PLAYER_PREFIX
	Array.forEach(opponentTeamTemplates, function (teamTemplate)
		for playerIndex = 1, config.playerLimit do
			opponentConditions:add{
				ConditionNode(ColumnName('opponentplayers_' .. prefix .. playerIndex .. 'template'), Comparator.eq, teamTemplate),
			}
		end
	end)

	return ConditionTree(BooleanOperator.all):add{
		opponentConditions,
		ConditionNode(ColumnName('opponenttype'), Comparator.neq, Opponent.team),
	}
end

---@private
---@return boolean
function BaseResultsTable:_isDataEmpty()
	return Table.isEmpty(self.data) or Table.isEmpty(self.data[1])
end

---Builds the results/achievements/awards table
---@return Widget
function BaseResultsTable:build()
	return TableWidgets.Table{
		sortable = true,
		columns = self:buildColumnDefinitions(),
		children = WidgetUtil.collect(
			TableWidgets.TableHeader{children = {self:buildHeader()}},
			-- Hidden tr that contains a td to prevent the first yearHeader from being inside thead
			not self:_isDataEmpty() and HtmlWidgets.Tr{
				css = {display = 'none'},
				children = HtmlWidgets.Td{}
			} or nil,
			TableWidgets.TableBody{children = WidgetUtil.collect(self:_buildTableBody(), self.args.manualContent)}
		),
		footer = self.config.onlyAchievements and LinkWidget{
			link = self.config.opponent .. '/' .. self.config.resultsSubPage,
			children = 'Extended list of results',
		} or nil
	}
end

---@private
---@return Widget[]
function BaseResultsTable:_buildTableBody()
	if self:_isDataEmpty() then
		return {TableWidgets.Row{children = TableWidgets.Cell{
			colspan = 42,
			children = 'No recorded results found.'
		}}}
	end
	return Array.flatMap(self.data, function (dataSet)
		return self:_buildRows(dataSet)
	end)
end

---@private
---@param placementData table
---@return Html[]
function BaseResultsTable:_buildRows(placementData)
	local rows = {}

	if placementData.header then
		table.insert(rows, TableWidgets.Row{
			section = 'subhead',
			classes = {'sortbottom'},
			css = {['font-weight'] = 'bold'},
			children = TableWidgets.CellHeader{
				align = 'center',
				colspan = 42,
				children = placementData.header
			}
		})
	end

	for _, placement in ipairs(placementData) do
		table.insert(rows, self:buildRow(placement))
	end

	return rows
end

---Applies the row highlight
---@protected
---@param placement placement
---@return boolean
function BaseResultsTable:rowHighlight(placement)
	return HighlightConditions.tournament(placement, self.config)
end

---Builds the tier display
---@protected
---@param placement placement
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

---Builds the opponent display
---@protected
---@param data placement
---@param options table?
---@return string|Widget?
function BaseResultsTable:opponentDisplay(data, options)
	options = options or {}

	if not Opponent.isType(data.opponenttype) then
		return '-'
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
		opponent = Opponent.readOpponentArgs{template = rawTeamTemplate.templatename, type = Opponent.team},
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
---@param teamDisplay Widget
---@param rawTeamTemplate teamTemplateData
---@param flip boolean?
---@return Widget
function BaseResultsTable.teamIconDisplayWithText(teamDisplay, rawTeamTemplate, flip)
	return HtmlWidgets.Fragment{children = {
		teamDisplay,
		HtmlWidgets.Div{
			css = {
				width = '60px',
				float = flip and 'right' or 'left',
			},
			children = HtmlWidgets.Div{
				css = {
					['line-height'] = 1,
					['font-size'] = '80%',
					['text-align'] = 'center',
				},
				children = {
					'(',
					LinkWidget{link = rawTeamTemplate.page, children = rawTeamTemplate.shortname},
					')'
				}
			}
		}
	}}
end

---Builds the tournament display name
---@param placement placement
---@return string
function BaseResultsTable.tournamentDisplayName(placement)
	if String.isNotEmpty(placement.tournament) then
		return placement.tournament
	end

	return (placement.pagename:gsub('_', ' '))
end

---Converts the lastvsdata to display components
---@param placement placement
---@return string, string|Widget?, string?
function BaseResultsTable:processVsData(placement)
	local lastVs = placement.lastvsdata or {}

	if Logic.isNotEmpty(lastVs.groupscore) then
		return placement.groupscore, nil, Abbreviation.make{text = 'Grp S.', title = 'Group Stage'}
	end

	local score = ''
	if Logic.isNotEmpty(placement.lastscore) or String.isNotEmpty(lastVs.score) then
		score = (placement.lastscore or '-') .. SCORE_CONCAT .. (lastVs.score or '-')
	end

	local vsDisplay = self:opponentDisplay(lastVs, {isLastVs = true})

	return score, vsDisplay
end

---@protected
---@return table[]
function BaseResultsTable:buildColumnDefinitions()
	error('BaseResultsTable:buildColumnDefinitions() cannot be called directly and must be overridden.')
end

---@protected
---@return Widget
function BaseResultsTable:buildHeader()
	error('BaseResultsTable:buildHeader() cannot be called directly and must be overridden.')
end

---@protected
---@param placement placement
---@return Widget
function BaseResultsTable:buildRow(placement)
	error('BaseResultsTable:buildRow() cannot be called directly and must be overridden.')
end

---@protected
---@param placement placement
---@return Widget
function BaseResultsTable:createDateCell(placement)
	return TableWidgets.Cell{children = DateExt.toYmdInUtc(placement.date)}
end

---@protected
---@param placement placement
---@return Widget
function BaseResultsTable:createTierCell(placement)
	local tierDisplay, tierSortValue = self:tierDisplay(placement)
	return TableWidgets.Cell{
		attributes = {
			['data-sort-value'] = tierSortValue
		},
		children = tierDisplay
	}
end

---@protected
---@param placement placement
---@return Widget?
function BaseResultsTable:createTypeCell(placement)
	if not self.config.showType then
		return
	end
	return TableWidgets.Cell{
		children = placement.type
	}
end

---@protected
---@param placement placement
---@return Widget[]
function BaseResultsTable:createTournamentCells(placement)
	local tournamentDisplayName = BaseResultsTable.tournamentDisplayName(placement)
	return {
		TableWidgets.Cell{
			attributes = {
				['data-sort-value'] = tournamentDisplayName
			},
			children = LeagueIcon.display{
				icon = placement.icon,
				iconDark = placement.icondark,
				link = placement.parent,
				name = tournamentDisplayName,
				options = {noTemplate = true},
			}
		},
		TableWidgets.Cell{
			attributes = {
				['data-sort-value'] = tournamentDisplayName
			},
			children = LinkWidget{
				children = tournamentDisplayName,
				link = placement.pagename,
			}
		},
	}
end

---@protected
---@param props {useIndivPrize: boolean?, placement: placement}
---@return Widget
function BaseResultsTable:createPrizeCell(props)
	local useIndivPrize = Logic.nilOr(props.useIndivPrize, self.config.queryType ~= Opponent.team)
	local placement = props.placement
	return TableWidgets.Cell{children = Currency.display(
		'USD',
		useIndivPrize and placement.individualprizemoney or placement.prizemoney,
		{dashIfZero = true, displayCurrencyCode = false, formatValue = true}
	)}
end

return BaseResultsTable
