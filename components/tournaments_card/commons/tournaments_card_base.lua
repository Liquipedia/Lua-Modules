---
-- @Liquipedia
-- wiki=commons
-- page=Module:TournamentsCard/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Currency = require('Module:Currency')
local Flags = require('Module:Flags')
local Game = require('Module:Game')
local HighlightConditions = require('Module:HighlightConditions')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local LeagueIcon = require('Module:LeagueIcon')
local Medal = require('Module:Medal')
local Region = require('Module:Region')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
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

local CANCELLED = 'cancelled'
local LANG = mw.language.new('en')
local NONBREAKING_SPACE = '&nbsp;'
local NON_TIER_TYPE_INPUT = 'none'
local POSTPONED = 'postponed'
local DELAYED = 'delayed'
local DEFAULT_ALLOWED_PLACES = '1,2,1-2,2-3,W,L'

--- @class BaseTournamentsCard
local BaseTournamentsCard = Class.new(function(self, ...) self:init(...) end)

function BaseTournamentsCard:init(args)
	self.args = args

	self:readConfig()

	return self
end

function BaseTournamentsCard:readConfig()
	local args = self.args

	local tier1 = args.tier1 or args.tier

	self.config = {
		showTier = Logic.readBool(Logic.nilOr(args.showTier, args.tiers, tier1 == '!' or Logic.isNotEmpty(args.tier2))),
		onlyTierTypeIfBoth = Logic.nilOr(Logic.readBoolOrNil(args.onlyTierTypeIfBoth), true),
		showOrganizer = Logic.readBool(args.showOrganizer),
		showGameIcon = Logic.readBool(args.showGameIcon),
		showHighlight = Logic.nilOr(Logic.readBoolOrNil(args.showHighlight), true),
		showQualifierColumnOverWinnerRunnerup = Logic.readBool(args.qualifiers),
		useParent = Logic.nilOr(Logic.readBoolOrNil(args.useParent), true),
		showRank = Logic.readBool(Logic.nilOr(args.showRank, args.ranked)),
		noLis = Logic.readBool(args.noLis),
		offset = tonumber(args.offset) or 0,
		allowedPlacements = self:_allowedPlacements(),
		onlyHighlightOnValue = args.onlyHighlightOnValue or args.valvetier, -- valvetier for legacy reasons
	}
end

function BaseTournamentsCard:_allowedPlacements()
	local placeConditions = self.args.placeConditions or DEFAULT_ALLOWED_PLACES

	return Array.map(mw.text.split(placeConditions, ','),
		function(placeValue) return mw.text.trim(placeValue) end
	)
end

function BaseTournamentsCard:create()
	local data = self.args.data or self:_query()
	if Table.isNotEmpty(data) then
		self.data = data
	end

	return self
end

function BaseTournamentsCard:_query()
	return mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = self:_buildConditions(),
		query = 'pagename, name, icon, icondark, organizers, startdate, enddate, status, locations, series, '
			.. 'prizepool, participantsnumber, game, liquipediatier, liquipediatiertype, extradata, publishertier, type',
		order = self.args.order,
		limit = self.args.limit,
		offset = self.config.offset,
	})
end

function BaseTournamentsCard:_buildConditions()

	local conditions = self:buildBaseConditions()

	if self.args.additionalConditions then
		return conditions .. self.args.additionalConditions
	end

	return conditions
end

function BaseTournamentsCard:buildBaseConditions()
	local args = self.args

	local startDate = args.startdate or args.sdate
	local endDate = args.enddate or args.edate

	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('startdate'), Comparator.gt, '1970-01-01')}

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

	if args.series then
		conditions:add{ConditionNode(ColumnName('series'), Comparator.eq, args.series)}
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

	if args.organizer then
		local organizerConditions = ConditionTree(BooleanOperator.any)
		for _, organizer in mw.text.split(args.organizer, ',', true) do
			organizer = mw.text.trim(organizer)
			organizerConditions:add{
				ConditionNode(ColumnName('organizers_organizer1'), Comparator.eq, organizer),
				ConditionNode(ColumnName('organizers_organizer2'), Comparator.eq, organizer),
			}
		end
		conditions:add{organizerConditions}
	end

	if args.region then
		local regionConditions = ConditionTree(BooleanOperator.any)
		for _, region in mw.text.split(args.region, ',', true) do
			region = mw.text.trim(region)
			regionConditions:add{
				ConditionNode(ColumnName('locations_region1'), Comparator.eq, region),
				ConditionNode(ColumnName('locations_region2'), Comparator.eq, region),
			}
		end
		conditions:add{regionConditions}
	end

	args.tier1 = args.tier1 or args.tier or '!'
	if args.tier1 then
		local tierConditions = ConditionTree(BooleanOperator.any)
		for _, tier in Table.iter.pairsByPrefix(args, 'tier') do
			tierConditions:add{ConditionNode(ColumnName('liquipediatier'), Comparator.eq, tier)}
		end
		conditions:add{tierConditions}
	end

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

	return conditions:toString()
end

function BaseTournamentsCard:additionalConditions()
	return {}
end

function BaseTournamentsCard:build()
	if not self.data then
		return
	end

	self.display = mw.html.create('div')
		:addClass('gridTable tournamentCard')

	local config = self.config

	if not config.showTier then
		self.display:addClass('Tierless')
	end

	if config.showRank then
		self.display:addClass('Ranked')
	end

	if config.showQualifierColumnOverWinnerRunnerup then
		self.display:addClass('Qualifiers')
	end

	if not config.showGameIcon then
		self.display:addClass('NoGameIcon')
	end

	if config.showOrganizer then
		self.display:addClass('HasOrganizer')
	end

	self.display:node(self:_header())

	self.cachedData = {rank = 1, prize = 0, skippedRanks = self.config.offset}
	for _, rowData in ipairs(self.data) do
		self:_row(rowData)
	end

	return self.display
end

function BaseTournamentsCard:_header()
	local config = self.config

	local header = mw.html.create('div'):addClass('gridHeader')

	if config.showRank then
		header:tag('div'):addClass('gridCell Position'):wikitext('#')
	end

	if config.showTier then
		header:tag('div'):addClass('gridCell Tier'):wikitext('Tier')
	end

	local gameHeader = header:tag('div'):addClass('gridCell')
	if config.showGameIcon then
		gameHeader:addClass('GameSeries'):wikitext(Abbreviation.make('G & S', 'Game and Series'))
	else
		gameHeader:addClass('Series'):wikitext(Abbreviation.make('S', 'Series'))
	end

	header:tag('div'):addClass('gridCell'):wikitext('Tournament'):done()

	if config.showOrganizer then
		header:tag('div'):addClass('gridCell'):wikitext('Organizer')
	end

	header
		:tag('div'):addClass('gridCell'):wikitext('Date'):done()
		:tag('div'):addClass('gridCell'):wikitext('Prize' .. NONBREAKING_SPACE .. 'Pool'):done()
		:tag('div'):addClass('gridCell'):wikitext('Location'):done()
		:tag('div'):addClass('gridCell'):wikitext(Abbreviation.make('P#', 'Number of Participants'))

	if config.showQualifierColumnOverWinnerRunnerup then
		header:tag('div'):addClass('gridCell'):wikitext('Qualified')
	else
		header
			:tag('div'):addClass('gridCell'):wikitext('Winner'):done()
			:tag('div'):addClass('gridCell'):wikitext('Runner-up')
	end

	return header
end

function BaseTournamentsCard:_row(tournamentData)
	local config = self.config

	local highlight = config.showHighlight and self:getHighlightClass(tournamentData) or nil
	local status = tournamentData.status and tournamentData.status:lower()

	local row = mw.html.create('div')
		:addClass('gridRow')
		:addClass(highlight)

	if config.showRank then
		self:_calculateRank(tonumber(tournamentData.prizepool) or 0)

		row:tag('div'):addClass('gridCell Position Header')
			:node(self.cachedData.rank)
	end

	local gameIcon = config.showGameIcon
		and mw.html.create('span'):addClass('icon-16px GameIcon'):wikitext(Game.icon{
			game = tournamentData.game, useDefault = false
		}) or nil

	if config.showTier then
		row:tag('div')
			:addClass('gridCell Tier Header')
			:node(gameIcon)
			:node(self:displayTier(tournamentData))
	end

	if config.showGameIcon then
		row:tag('div')
			:addClass('gridCell Game Header')
			:node(gameIcon)
	end

	row:tag('div')
		:addClass('gridCell Tournament Header')
		:node(LeagueIcon.display{
			options = {noTemplate = Logic.readBool(config.noLIS)},
			icon = tournamentData.icon,
			iconDark = tournamentData.icondark,
			series = tournamentData.series,
			date = tournamentData.enddate,
		})
		:wikitext(NONBREAKING_SPACE .. NONBREAKING_SPACE)
		:wikitext('[[' .. tournamentData.pagename .. '|' .. tournamentData.name .. ']]')
		:cssText(status == CANCELLED and 'text-decoration:line-through;' or nil)

	if config.showOrganizer then
		row:tag('div')
			:addClass('gridCell EventDetails Organizer')
			:node(BaseTournamentsCard._organizerDisplay(tournamentData))
	end

	local dateCell = row:tag('div')
		:addClass('gridCell EventDetails Date Header')
		:wikitext(BaseTournamentsCard._dateDisplay(tournamentData.startdate, tournamentData.enddate, status))

	if status == POSTPONED or status == DELAYED then
		dateCell
			:addClass('bg-second')
			:css('font-style', 'italic')
	end

	local prizeValue = tonumber(tournamentData.prizepool) or 0
	local participantNumber = tonumber(tournamentData.participantsnumber) or -1

	local priceCell = row:tag('div')
		:addClass('gridCell EventDetails Prize Header')
	if prizeValue > 0 then
		priceCell
			:wikitext(Currency.display('USD', prizeValue, {
				dashIfZero = true, abbreviation = false, formatValue = true
			}))
	else
		priceCell
			:wikitext(NONBREAKING_SPACE)
			:addClass(participantNumber == -1 and 'Blank' or nil)
	end

	row:tag('div')
		:addClass('gridCell EventDetails Location Header')
		:wikitext(BaseTournamentsCard._displayLocations(tournamentData.locations or {}, tournamentData.type))

	local participantsNumberCell = row:tag('div')
		:addClass('gridCell EventDetails PlayerNumber Header')
	if participantNumber ~= -1 then
		participantsNumberCell:node(BaseTournamentsCard.participantsNumber(participantNumber))
	else
		participantsNumberCell
			:wikitext('-')
			:addClass(prizeValue > 0 and 'Blank' or nil)
	end

	if status == CANCELLED then
		row:tag('div')
			:addClass('gridCell Placement Qualified bg-down')
			:css('justify-content', 'center')
			:css('font-style', 'italic')
			:wikitext('Cancelled')

		self.display:node(row)
		return
	end

	local placements = self:_fetchPlacementData(tournamentData)

	if placements.qualified then
		row:tag('div')
			:addClass('gridCell Placement Qualified')
			:node(mw.html.create('span'):addClass('Medal'):wikitext(Medal.qual .. NONBREAKING_SPACE))
			:node(self:_buildParticipantsSpan(placements.qualified))

		self.display:node(row)
		return
	end

	local firstPlaceCell = mw.html.create('div')
		:addClass('gridCell Placement FirstPlace')
		:node(mw.html.create('span'):addClass('Medal'):wikitext(Medal['1'] .. NONBREAKING_SPACE))
		:node(self:_buildParticipantsSpan(placements[1]))

	row:node(firstPlaceCell:done())

	local secondPlaceCell = mw.html.create('div')
		:addClass('gridCell Placement SecondPlace')
		:node(mw.html.create('span'):addClass('Medal'):wikitext(Medal['2'] .. NONBREAKING_SPACE))
		:node(self:_buildParticipantsSpan(placements[2]))

	row:node(secondPlaceCell:done())

	self.display:node(row)
end

function BaseTournamentsCard:_buildParticipantsSpan(opponents)
	local participantsSpan = mw.html.create('span')
		:addClass('Participants')
	for _, opponent in ipairs(opponents) do
		participantsSpan:node(OpponentDisplay.BlockOpponent{opponent = opponent})
	end

	return participantsSpan
end


function BaseTournamentsCard:_calculateRank(prize)

	if prize == self.cachedData.prize then
		self.cachedData.skippedRanks = self.cachedData.skippedRanks + 1
		return
	end

	self.cachedData = {
		rank = self.cachedData.rank + self.cachedData.skippedRanks,
		skippedRanks = 1,
		prize = prize,
	}
end

function BaseTournamentsCard._organizerDisplay(tournamentData)
	local organizers = Logic.emptyOr(tournamentData.organizers) or {}
	if type(organizers) == 'string' then
		organizers = Json.parse(organizers)
	end

	local organizerArray = {}
	for _, organizer in Table.iter.pairsByPrefix(organizers, 'organizer') do
		table.insert(organizerArray, organizer)
	end

	return mw.html.create()
		:wikitext(table.concat(organizerArray, ', '))
end

function BaseTournamentsCard._displayLocations(locationData, tournamentType)
	local locations = {}
	local locationIndex = 1
	local location = BaseTournamentsCard._displayLocation(locationData, locationIndex)
	while location do
		table.insert(locations, location)
		locationIndex = locationIndex + 1
		location = BaseTournamentsCard._displayLocation(locationData, locationIndex)
	end

	locations = Array.map(locations, function(loc)
		return tostring(mw.html.create('span'):addClass('FlagText'):wikitext(loc))
	end)

	if Table.isEmpty(locations) then
		return tournamentType and mw.getContentLanguage():ucfirst(tournamentType) or nil
	end

	if String.isNotEmpty(tournamentType) and tournamentType:lower():find('offline') then
		table.insert(locations, '<i>(' .. mw.getContentLanguage():ucfirst(tournamentType) .. ')</i>')
	end

	return table.concat(locations)
end

function BaseTournamentsCard._displayLocation(locationData, locationIndex)
	local display = ''
	local region = locationData['region' .. locationIndex]
	local country = locationData['country' .. locationIndex]
	local city = locationData['city' .. locationIndex]

	if country then
		display = Flags.Icon{flag = country} .. NONBREAKING_SPACE
	elseif city and region then
		display = Flags.Icon{flag = region} .. NONBREAKING_SPACE
	elseif region then
		return Region.run{region = region, onlyDisplay = true}
	end

	return String.nilIfEmpty(display .. (city or Flags.CountryName(country)))
end

function BaseTournamentsCard._dateDisplay(startDate, endDate, status)
	if status == POSTPONED or status == DELAYED then
		return 'Postponed'
	end

	if startDate == endDate then
		return LANG:formatDate('M j, Y', startDate)
	end

	local startYear, startMonth = startDate:match('(%d+)-(%d+)-%d+')
	local endYear, endMonth = endDate:match('(%d+)-(%d+)-%d+')

	if startYear ~= endYear then
		return LANG:formatDate('M j, Y', startDate) .. ' - ' .. LANG:formatDate('M j, Y', endDate)
	end

	if startMonth == endMonth then
		return LANG:formatDate('M j', startDate) .. ' - ' .. LANG:formatDate('j, Y', endDate)
	end

	return LANG:formatDate('M j', startDate) .. ' - ' .. LANG:formatDate('M j, Y', endDate)
end

function BaseTournamentsCard:_fetchPlacementData(tournamentData)
	local placements = {}

	local queryData = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = self:_buildPlacementConditions(tournamentData),
		query = 'opponentname, opponenttype, opponenttemplate, opponentplayers, placement, extradata',
		order = 'placement asc',
		limit = 50,
	})

	if self.config.showQualifierColumnOverWinnerRunnerup then
		if Table.isEmpty(queryData) then
			return {qualified = {Opponent.tbd(Opponent.team)}}
		end
		return {qualified = queryData}
	end

	for _, item in ipairs(queryData) do
		local place = tonumber(mw.text.split(item.placement, '-')[1])
		if not place and item.placement == 'W' then
			place = 1
		elseif not place and item.placement == 'L' then
			place = 2
		end

		if place then
			if not placements[place] then
				placements[place] = {}
			end

			local opponent = Opponent.fromLpdbStruct(item)
			if not opponent then
				mw.logObject({pageName = tournamentData.pagename, place = item.placement}, 'Invalid Prize Pool Data returned from')
			end
			if Opponent.isTbd(opponent) then
				opponent = Opponent.tbd(Opponent.team)
			end
			table.insert(placements[place], opponent)
		end
	end

	if Table.isEmpty(placements[1]) then
		placements[1] = {Opponent.tbd(Opponent.team)}
	end

	if Table.isEmpty(placements[2]) then
		placements[2] = {Opponent.tbd(Opponent.team)}
	end

	return placements
end

function BaseTournamentsCard:_buildPlacementConditions(tournamentData)
	local config = self.config
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

function BaseTournamentsCard.participantsNumber(number)
	number = tonumber(number)
	if not number or number <= 0 then
		return NONBREAKING_SPACE
	end

	return mw.html.create()
		:node(mw.html.create('span'):css('vertical-align', 'top'):wikitext(LANG:formatNum(number)))
		:node(mw.html.create('span'):addClass('PlayerNumberSuffix'):wikitext(NONBREAKING_SPACE .. 'participants'))
end

-- overwritable in case wikis want several highlight options
function BaseTournamentsCard:getHighlightClass(tournamentData)
	return HighlightConditions.tournament(tournamentData, self.config)
		and 'tournament-highlighted-bg'
		or nil
end

function BaseTournamentsCard:displayTier(tournamentData)
	local tier, tierType, options = Tier.parseFromQueryData(tournamentData)
	options.link = true
	if self.config.onlyTierTypeIfBoth then
		options.onlyTierTypeIfBoth = true
	else
		options.tierTypeShort = true
	end

	return mw.html.create('span')
		:wikitext(Tier.display(tier, tierType, options))
end

return BaseTournamentsCard
