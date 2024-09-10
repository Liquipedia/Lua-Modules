---
-- @Liquipedia
-- wiki=commons
-- page=Module:TournamentsListing/Conditions
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Flags = require('Module:Flags')
local Logic = require('Module:Logic')
local Table = require('Module:Table')

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local NON_TIER_TYPE_INPUT = 'none'

local TournamentsListingConditions = {}

---@param args table
---@return string
function TournamentsListingConditions.base(args)
	local startDate = args.startdate or args.sdate
	local endDate = args.enddate or args.edate

	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('startdate'), Comparator.neq, DateExt.defaultDate)}

	if args.year then
		conditions:add{ConditionNode(ColumnName('enddate_year'), Comparator.eq, args.year)}
	else
		if startDate then
			conditions:add{ConditionTree(BooleanOperator.any):add{
				ConditionNode(ColumnName('startdate'), Comparator.gt, startDate),
				ConditionNode(ColumnName('startdate'), Comparator.eq, startDate)
				},
			}
		end
		if endDate then
			conditions:add{ConditionTree(BooleanOperator.any):add{
				ConditionNode(ColumnName('startdate'), Comparator.lt, endDate),
				ConditionNode(ColumnName('startdate'), Comparator.eq, endDate)
				},
			}
		end
	end

	if Logic.readBool(args.recent) then
		conditions:add{ConditionNode(ColumnName('enddate'), Comparator.lt, os.date('%Y-%m-%d'))}
	end

	if args.prizepool then
		conditions:add{ConditionNode(ColumnName('prizepool'), Comparator.gt, tonumber(args.prizepool))}
	end

	if args.mode then
		conditions:add{ConditionNode(ColumnName('mode'), Comparator.eq, args.mode)}
	end

	if args.game then
		conditions:add{ConditionNode(ColumnName('game'), Comparator.eq, args.game)}
	end

	if args.series1 or args.series then
		local seriesConditions = ConditionTree(BooleanOperator.any)
		for _, series in Table.iter.pairsByPrefix(args, 'series', {requireIndex = false}) do
			seriesConditions:add{
				ConditionNode(ColumnName('series'), Comparator.eq, series),
				ConditionNode(ColumnName('extradata_series2'), Comparator.eq, series)
			}
		end
		conditions:add{seriesConditions}
	end

	if args.location then
		local locationConditions = ConditionTree(BooleanOperator.any)
		locationConditions:add{ConditionNode(ColumnName('location'), Comparator.eq, args.location)}
		if args.location2 then
			locationConditions:add{ConditionNode(ColumnName('location'), Comparator.eq, args.location2)}
		end
		conditions:add{locationConditions}
	end

	if args.type then
		conditions:add{ConditionNode(ColumnName('type'), Comparator.eq, args.type)}
	end

	if args.shortnames then
		conditions:add{ConditionNode(ColumnName('shortname'), Comparator.neq, '')}
	end

	TournamentsListingConditions._addConditionsFromCsv(conditions, {
		input = args.organizer,
		lpdbKey = 'organizers_organizer',
		maxNumber = 3,
	})

	TournamentsListingConditions._addConditionsFromCsv(conditions, {
		input = args.region,
		lpdbKey = 'locations_region',
		maxNumber = 2,
	})

	TournamentsListingConditions._addConditionsFromCsv(conditions, {
		input = args.country,
		lpdbKey = 'locations_country',
		maxNumber = tonumber(args.numberOfCountries) or 2,
		normalize = Flags.CountryCode,
	})

	TournamentsListingConditions._addConditionsFromCsv(conditions, {
		input = args.city,
		lpdbKey = 'locations_city',
		maxNumber = tonumber(args.numberOfCities) or 2,
	})

	args.tier1 = args.tier1 or args.tier or '!'
	local tierConditions = ConditionTree(BooleanOperator.any)
	for _, tier in Table.iter.pairsByPrefix(args, 'tier') do
		tierConditions:add{ConditionNode(ColumnName('liquipediatier'), Comparator.eq, tier)}
	end
	conditions:add{tierConditions}

	args.tiertype1 = args.tiertype1 or args.tiertype
	if args.tiertype1 then
		local tierTypeConditions = ConditionTree(BooleanOperator.any)
		for _, tier in Table.iter.pairsByPrefix(args, 'tiertype') do
			tierTypeConditions:add{
				ConditionNode(ColumnName('liquipediatiertype'), Comparator.eq, tier == NON_TIER_TYPE_INPUT and '' or tier)
			}
		end
		conditions:add{tierTypeConditions}
	end
	args.excludeTiertype1 = args.excludeTiertype1 or args.excludeTiertype
	if args.excludeTiertype1 then
		local excludeTiertypeConditions = ConditionTree(BooleanOperator.all)
		for _, tier in Table.iter.pairsByPrefix(args, 'excludeTiertype') do
			excludeTiertypeConditions:add{
				ConditionNode(ColumnName('liquipediatiertype'), Comparator.neq, tier == NON_TIER_TYPE_INPUT and '' or tier)
			}
		end
		conditions:add{excludeTiertypeConditions}
	end

	return conditions:toString()
end

---@param tournamentData table
---@param config table
---@return string
function TournamentsListingConditions.placeConditions(tournamentData, config)
	local conditions = ConditionTree(BooleanOperator.all)
		:add{
			ConditionNode(ColumnName('liquipediatier'), Comparator.eq, tournamentData.liquipediatier),
			ConditionNode(ColumnName('liquipediatiertype'), Comparator.eq, tournamentData.liquipediatiertype),
			ConditionNode(ColumnName(config.useParent and 'parent' or 'pagename'), Comparator.eq, tournamentData.pagename),
		}

	if config.showQualifierColumnOverWinnerRunnerup then
		conditions:add{ConditionNode(ColumnName('qualified'), Comparator.eq, '1')}
		return conditions:toString()
	end

	local placeConditions = ConditionTree(BooleanOperator.any)
	for _, allowedPlacement in pairs(config.allowedPlacements) do
		placeConditions:add{ConditionNode(ColumnName('placement'), Comparator.eq, allowedPlacement)}
	end
	conditions:add{placeConditions}

	return conditions:toString()
end

---@param conditions ConditionTree
---@param props {input: string, lpdbKey: string, maxNumber: integer, normalize?: fun(val: string): string?}
function TournamentsListingConditions._addConditionsFromCsv(conditions, props)
	local values = Array.parseCommaSeparatedString(props.input)

	if props.normalize then
		values = Array.map(values, props.normalize)
	end

	if Logic.isEmpty(values) then
		return
	end

	local csvConditions = ConditionTree(BooleanOperator.any)
	Array.forEach(values, function(value)
		Array.forEach(Array.range(1, props.maxNumber), function(index)
			csvConditions:add{ConditionNode(ColumnName(props.lpdbKey .. index), Comparator.eq, value)}
		end)
	end)

	conditions:add{csvConditions}
end



return TournamentsListingConditions
