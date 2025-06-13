---
-- @Liquipedia
-- page=Module:TournamentsListing/CardList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Currency = require('Module:Currency')
local Flags = require('Module:Flags')
local Game = require('Module:Game')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local LeagueIcon = require('Module:LeagueIcon')
local Lua = require('Module:Lua')
local Medals = require('Module:Medals')
local Region = require('Module:Region')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local Conditions = Lua.import('Module:TournamentsListing/Conditions')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local Tier = Lua.import('Module:Tier/Custom')

local LANG = mw.getContentLanguage()
local NONBREAKING_SPACE = '&nbsp;'
local POSTPONED = 'postponed'
local DELAYED = 'delayed'
local CANCELLED = 'cancelled'
local DEFAULT_ALLOWED_PLACES = '1,2,1-2,2-3,W,L'
local DEFAULT_LIMIT = 5000

--- @class BaseTournamentsListing
--- @operator call(...): BaseTournamentsListing
local BaseTournamentsListing = Class.new(function(self, ...) self:init(...) end)

---@param args table
---@return self
function BaseTournamentsListing:init(args)
	self.args = args

	self:readConfig()

	return self
end

function BaseTournamentsListing:readConfig()
	local args = self.args

	local tier1 = args.tier1 or args.tier

	self.config = {
		-- either manually toggled tier column or if parameters are made in a way that allows for multiple tiers
		--- case 1: tier is set as '!' --> all tiers can be returned
		--- case 2: tier1 and tier2 both set --> multiple tiers can be returned
		showTier = Logic.readBool(Logic.nilOr(args.showTier, tier1 == '!' or Logic.isNotEmpty(args.tier2))),
		onlyTierTypeIfBoth = Logic.nilOr(Logic.readBoolOrNil(args.onlyTierTypeIfBoth), true),
		showOrganizer = Logic.readBool(args.showOrganizer),
		showGameIcon = Logic.readBool(args.showGameIcon),
		showHighlight = Logic.nilOr(Logic.readBoolOrNil(args.showHighlight), true),
		showQualifierColumnOverWinnerRunnerup = Logic.readBool(args.qualifiers),
		useParent = Logic.nilOr(Logic.readBoolOrNil(args.useParent), true),
		showRank = Logic.readBool(Logic.nilOr(args.showRank)),
		noLis = Logic.readBool(args.noLis),
		offset = tonumber(args.offset) or 0,
		allowedPlacements = self:_allowedPlacements(),
		onlyHighlightOnValue = args.onlyHighlightOnValue,
	}
end

---@return string[]
function BaseTournamentsListing:_allowedPlacements()
	local placeConditions = self.args.placeConditions or DEFAULT_ALLOWED_PLACES

	return Array.map(mw.text.split(placeConditions, ','), String.trim)
end

---@return self
function BaseTournamentsListing:create()
	local data = self.args.data or self:_query()
	if Table.isNotEmpty(data) then
		self.data = data
	end

	return self
end

---@return table
function BaseTournamentsListing:_query()
	return mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = self:_buildConditions(),
		query = 'pagename, name, icon, icondark, organizers, startdate, enddate, status, locations, series, '
			.. 'prizepool, participantsnumber, game, liquipediatier, liquipediatiertype, extradata, publishertier, type',
		order = self.args.order,
		limit = self.args.limit or DEFAULT_LIMIT,
		offset = self.config.offset,
	})
end

---@return string
function BaseTournamentsListing:_buildConditions()

	local conditions = Conditions.base(self.args)

	if self.args.additionalConditions then
		return conditions .. self.args.additionalConditions
	end

	return conditions
end

---@return Html?
function BaseTournamentsListing:build()
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

---@return Html
function BaseTournamentsListing:_header()
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
		gameHeader:addClass('GameSeries'):wikitext(Abbreviation.make{text = 'G & S', title = 'Game and Series'})
	else
		gameHeader:addClass('Series'):wikitext(Abbreviation.make{text = 'S', title = 'Series'})
	end

	header:tag('div'):addClass('gridCell'):wikitext('Tournament'):done()

	if config.showOrganizer then
		header:tag('div'):addClass('gridCell'):wikitext('Organizer')
	end

	header
		:tag('div'):addClass('gridCell'):wikitext('Date'):done()
		:tag('div'):addClass('gridCell Prize'):wikitext('Prize' .. NONBREAKING_SPACE .. 'Pool'):done()
		:tag('div'):addClass('gridCell'):wikitext('Location'):done()
		:tag('div'):addClass('gridCell'):wikitext(Abbreviation.make{text = 'P#', title = 'Number of Participants'})

	if config.showQualifierColumnOverWinnerRunnerup then
		header:tag('div'):addClass('gridCell'):wikitext('Qualified')
	else
		header
			:tag('div'):addClass('gridCell'):wikitext('Winner'):done()
			:tag('div'):addClass('gridCell'):wikitext('Runner-up')
	end

	return header
end

---@param tournamentData table
function BaseTournamentsListing:_row(tournamentData)
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
			:node(BaseTournamentsListing._organizerDisplay(tournamentData))
	end

	local dateCell = row:tag('div')
		:addClass('gridCell EventDetails Date Header')
		:wikitext(BaseTournamentsListing._dateDisplay(tournamentData.startdate, tournamentData.enddate, status))

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
				dashIfZero = true, displayCurrencyCode = false, formatValue = true
			}))
	else
		priceCell
			:wikitext(NONBREAKING_SPACE)
			:addClass('Blank')
	end

	row:tag('div')
		:addClass('gridCell EventDetails Location Header')
		:wikitext(BaseTournamentsListing._displayLocations(tournamentData.locations or {}, tournamentData.type))

	local participantsNumberCell = row:tag('div')
		:addClass('gridCell EventDetails PlayerNumber Header')
	if participantNumber ~= -1 then
		participantsNumberCell:node(BaseTournamentsListing.participantsNumber(participantNumber))
	else
		participantsNumberCell
			:wikitext('-')
			:addClass(not config.showTier and prizeValue == 0 and 'Blank' or nil)
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
			:node(Medals.display{medal = 'qualified'}:addClass('Medal'):wikitext(NONBREAKING_SPACE))
			:node(self:_buildParticipantsSpan(placements.qualified))

		self.display:node(row)
		return
	end

	local firstPlaceCell = mw.html.create('div')
		:addClass('gridCell Placement FirstPlace')
		:node(Medals.display{medal = 1}:addClass('Medal'):wikitext(NONBREAKING_SPACE))
		:node(self:_buildParticipantsSpan(placements[1]))

	row:node(firstPlaceCell:done())

	local secondPlaceCell = mw.html.create('div')
		:addClass('gridCell Placement SecondPlace')
		:node(Medals.display{medal = 2}:addClass('Medal'):wikitext(NONBREAKING_SPACE))
		:node(self:_buildParticipantsSpan(placements[2]))

	row:node(secondPlaceCell:done())

	self.display:node(row)
end

---@param opponents table[]
---@return Html
function BaseTournamentsListing:_buildParticipantsSpan(opponents)
	local participantsSpan = mw.html.create('span')
		:addClass('Participants')
	for _, opponent in ipairs(opponents) do
		participantsSpan:node(OpponentDisplay.BlockOpponent{opponent = opponent})
	end

	return participantsSpan
end

---@param prize number
function BaseTournamentsListing:_calculateRank(prize)

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

---@param tournamentData table
---@return Html
function BaseTournamentsListing._organizerDisplay(tournamentData)
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

---@param locationData table
---@param tournamentType string?
---@return string?
function BaseTournamentsListing._displayLocations(locationData, tournamentType)
	local locations = Array.mapIndexes(function(locationIndex)
		return BaseTournamentsListing._displayLocation(locationData, locationIndex)
	end)

	locations = Array.map(locations, function(loc)
		return tostring(mw.html.create('span'):addClass('FlagText'):wikitext(loc))
	end)

	if Table.isEmpty(locations) then
		return tournamentType and mw.getContentLanguage():ucfirst(tournamentType) or nil
	end

	return table.concat(locations)
end

---@param locationData table
---@param locationIndex integer
---@return string?
function BaseTournamentsListing._displayLocation(locationData, locationIndex)
	local display = ''
	local region = locationData['region' .. locationIndex]
	local country = locationData['country' .. locationIndex]
	local city = locationData['city' .. locationIndex]

	if country then
		display = Flags.Icon{flag = country} .. NONBREAKING_SPACE
	elseif city and region then
		display = Flags.Icon{flag = region} .. NONBREAKING_SPACE
	elseif region then
		return Region.display{region = region}
	end

	return String.nilIfEmpty(display .. (city or Flags.CountryName{flag = country}))
end

---@param startDate string
---@param endDate string
---@param status string?
---@return string
function BaseTournamentsListing._dateDisplay(startDate, endDate, status)
	if status == POSTPONED or status == DELAYED then
		return 'Postponed'
	end

	if startDate == endDate then
		return LANG:formatDate('M j, Y', startDate) --[[@as string]]
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

---@param tournamentData table
---@return {qualified: table[]?, [1]: table[]?, [2]: table[]?}
function BaseTournamentsListing:_fetchPlacementData(tournamentData)
	local placements = {}

	local conditions = Conditions.placeConditions(tournamentData, self.config)
		.. (self.args.additionalPlaceConditions or '')

	local queryData = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = conditions,
		query = 'opponentname, opponenttype, opponenttemplate, opponentplayers, placement, extradata, game',
		order = 'placement asc',
		limit = 50,
	})

	if self.config.showQualifierColumnOverWinnerRunnerup then
		if Table.isEmpty(queryData) then
			return {qualified = {Opponent.tbd(Opponent.team)}}
		end
		return {qualified = Array.map(queryData, Opponent.fromLpdbStruct)}
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
			elseif Opponent.isTbd(opponent) then
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

---@param number number|string|nil
---@return Html|string
function BaseTournamentsListing.participantsNumber(number)
	number = tonumber(number)
	if not number or number <= 0 then
		return NONBREAKING_SPACE
	end

	return mw.html.create()
		:node(mw.html.create('span'):css('vertical-align', 'top'):wikitext(LANG:formatNum(number)))
		:node(mw.html.create('span'):addClass('PlayerNumberSuffix'):wikitext(NONBREAKING_SPACE .. 'participants'))
end

-- overwritable in case wikis want several highlight options
---@param tournamentData table
---@return string?
function BaseTournamentsListing:getHighlightClass(tournamentData)
	return HighlightConditions.tournament(tournamentData, self.config)
		and 'tournament-highlighted-bg'
		or nil
end

---@param tournamentData table
---@return Html
function BaseTournamentsListing:displayTier(tournamentData)
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

return BaseTournamentsListing
