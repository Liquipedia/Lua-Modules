---
-- @Liquipedia
-- page=Module:NotabilityChecker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local MathUtil = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')
local Tier = Lua.import('Module:Tier/Custom')

local ResultsTable = Lua.import('Module:ResultsTable/Custom')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class NotabilityCheckerPlacementPoints
---@field maxPlacement integer? applies to all remaining placements if omitted
---@field points number

---A number is the points for first place, reduced by `placementDropOff` for lower placements.
---A list awards fixed points per placement range; placements beyond the last range get 0.
---@alias NotabilityCheckerTierTypePoints number|NotabilityCheckerPlacementPoints[]

---@class NotabilityCheckerTierConfig
---@field ignoreDateLoss boolean?
---@field points table<string, NotabilityCheckerTierTypePoints> keyed by tier type identifier, `general` if none

---@class NotabilityCheckerConfig
---@field thresholds {discussion: number, notable: number}
---@field maxParticipants integer?
---@field maxCoaches integer
---@field modeMultipliers table<string, number>?
---@field placementDropOff table<string, number>? exponent by tier type identifier, with a `default` fallback
---@field tiers table<integer, NotabilityCheckerTierConfig>
---@field modeTiers table<string, table<integer, NotabilityCheckerTierConfig>>? replaces `tiers` for that mode

---@type NotabilityCheckerConfig
local Config = Lua.import('Module:NotabilityChecker/config')

local GENERAL_TIER_TYPE = 'general'
local NOW = DateExt.getCurrentTimestamp()
local SECONDS_IN_YEAR = DateExt.daysToSeconds(365.2425)
local MAX_NUMBER_OF_PARTICIPANTS = Config.maxParticipants or Info.config.defaultMaxPlayersPerPlacement or 10
local FORFEIT_PLACEMENTS = {w = 1, l = 2}

local NotabilityChecker = {}

---@param args table
---@return VNode
function NotabilityChecker.run(args)
	local team = Logic.nilIfEmpty(args.team)
	local people = Array.mapIndexes(function(index)
		return Logic.nilIfEmpty(args['player' .. index])
	end)

	local teamResult = team and NotabilityChecker._runForOpponent(team, 'team') or nil
	local personResults = Array.map(people, function(person)
		return NotabilityChecker._runForOpponent(person, 'solo')
	end)

	local weight = (teamResult and teamResult.weight or 0)
	if #personResults > 0 then
		weight = weight + MathUtil.sum(Array.map(personResults, Operator.property('weight'))) / #personResults
	end

	return Html.Fragment{children = WidgetUtil.collect(
		teamResult and Html.H3{children = 'Team Results'} or nil,
		teamResult and teamResult.display or nil,
		#personResults > 0 and Html.H3{children = 'People Results'} or nil,
		Array.map(personResults, Operator.property('display')),
		Html.H3{children = 'Summary'},
		Html.P{children = {Html.B{children = 'Final weight:'}, ' ', MathUtil.round(weight, 2)}},
		Html.P{children = {
			'This means this ',
			team and 'team' or 'person',
			' is ',
			Html.B{children = NotabilityChecker._verdict(weight)},
		}}
	)}
end

---@private
---@param weight number
---@return string
function NotabilityChecker._verdict(weight)
	if weight >= Config.thresholds.notable then
		return 'NOTABLE'
	elseif weight >= Config.thresholds.discussion then
		return 'OPEN FOR DISCUSSION'
	end
	return 'NOT NOTABLE'
end

---@private
---@param name string
---@param queryType 'team'|'solo'
---@return {weight: number, display: VNode}
function NotabilityChecker._runForOpponent(name, queryType)
	name = mw.ext.TeamLiquidIntegration.resolve_redirect(name)
	local conditions = queryType == 'team'
		and NotabilityChecker._buildTeamConditions(name)
		or NotabilityChecker._buildPersonConditions(name)
	local placements = NotabilityChecker._queryPlacements(conditions)
	local weight = MathUtil.sum(Array.map(placements, NotabilityChecker.calculatePlacementWeight))

	return {
		weight = weight,
		display = Html.Div{children = {
			GeneralCollapsible{
				title = 'Tournaments found featuring ' .. name,
				shouldCollapse = true,
				children = ResultsTable.results{
					querytype = queryType,
					team = queryType == 'team' and name or nil,
					player = queryType == 'solo' and name or nil,
					hideresult = true,
					data = placements,
				},
			},
			Html.P{children = {
				Link{link = name},
				' ',
				Html.B{children = 'Weight:'},
				' ',
				MathUtil.round(weight, 2),
			}},
		}},
	}
end

---@private
---@param team string
---@return ConditionTree
function NotabilityChecker._buildTeamConditions(team)
	return ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('opponentname'), Comparator.eq, team),
	}
end

---@private
---@param person string
---@return ConditionTree
function NotabilityChecker._buildPersonConditions(person)
	local names = Array.unique{person, (person:gsub(' ', '_'))}
	local columns = Array.extend(
		'opponentname',
		Array.map(Array.range(1, MAX_NUMBER_OF_PARTICIPANTS), function(index)
			return 'opponentplayers_p' .. index
		end),
		Array.map(Array.range(1, Config.maxCoaches), function(index)
			return 'opponentplayers_c' .. index
		end)
	)

	return ConditionTree(BooleanOperator.any):add(Array.map(columns, function(column)
		return ConditionUtil.anyOf(ColumnName(column), names)
	end))
end

---@private
---@param conditions ConditionTree
---@return placement[]
function NotabilityChecker._queryPlacements(conditions)
	local placements = {}
	Lpdb.executeMassQuery('placement', {
		conditions = conditions:toString(),
		order = 'date desc',
	}, function(placement)
		table.insert(placements, placement)
	end)
	return placements
end

---@param placement placement
---@return number
function NotabilityChecker.calculatePlacementWeight(placement)
	local mode = (placement.mode or ''):lower()
	local tiers = (Config.modeTiers or {})[mode] or Config.tiers
	local tierConfig = tiers[Tier.toIdentifier(placement.liquipediatier)]
	local placementNumber = NotabilityChecker._parsePlacement(placement.placement)
	if not tierConfig or not placementNumber then
		return 0
	end

	local tierType = tostring(Tier.toIdentifier(placement.liquipediatiertype) or GENERAL_TIER_TYPE)
	local points = NotabilityChecker._placementPoints(tierConfig.points[tierType], tierType, placementNumber)
	local dateLoss = tierConfig.ignoreDateLoss and 1 or NotabilityChecker._dateLoss(placement.date)
	local notabilityMod = tonumber((placement.extradata or {}).notabilitymod) or 1
	local modeMultiplier = (Config.modeMultipliers or {})[mode] or 1

	return points * notabilityMod * modeMultiplier / dateLoss
end

---@private
---@param tierTypePoints NotabilityCheckerTierTypePoints?
---@param tierType string
---@param placement integer
---@return number
function NotabilityChecker._placementPoints(tierTypePoints, tierType, placement)
	if type(tierTypePoints) == 'number' then
		local dropOff = Config.placementDropOff or {}
		return tierTypePoints / placement ^ (dropOff[tierType] or dropOff.default or 0)
	end

	local range = Array.find(tierTypePoints or {}, function(placementPoints)
		return placementPoints.maxPlacement == nil or placement <= placementPoints.maxPlacement
	end)
	return range and range.points or 0
end

---Parses the upper bound of a placement, e.g. `3-4` -> 3, and treats forfeit wins/losses as 1st/2nd
---@private
---@param placement string?
---@return integer?
function NotabilityChecker._parsePlacement(placement)
	if Logic.isEmpty(placement) then
		return
	end
	---@cast placement -nil
	placement = placement:lower()
	return FORFEIT_PLACEMENTS[placement] or tonumber((placement:match('^([^-]+)')))
end

---Each started year since the tournament divides its weight by one more
---@private
---@param date string
---@return integer
function NotabilityChecker._dateLoss(date)
	local differenceSeconds = NOW - (DateExt.readTimestamp(date) or NOW)
	-- Future dates come from editor mistakes in prize pools
	if differenceSeconds < 0 then
		return 1
	end
	return math.floor(differenceSeconds / SECONDS_IN_YEAR) + 1
end

return Class.export(NotabilityChecker, {exports = {'run'}})
