---
-- @Liquipedia
-- wiki=commons
-- page=Module:TournamentsListing/Display/Table
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
local Medal = require('Module:Medal')
local Region = require('Module:Region')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local HighlightConditions = Lua.import('Module:HighlightConditions')
local Tier = Lua.import('Module:Tier/Custom')

local LANG = mw.language.new('en')
local NONBREAKING_SPACE = '&nbsp;'
local POSTPONED = 'postponed'
local DELAYED = 'delayed'
local CANCELLED = 'cancelled'

---@class TournamentsListingDisplayTable
---@operator call(...): TournamentsListingDisplayTable
---@field parent BaseTournamentsListing
---@field config table
local TournamentsListingDisplayTable = Class.new(function(self, tournamentListing, settings)
	self.parent = tournamentListing

	local tier1 = settings.tier1 or settings.tier
	self.config = {
		showOrganizer = Logic.readBool(settings.showOrganizer),
		showGameIcon = Logic.readBool(settings.showGameIcon),
		showHighlight = Logic.nilOr(Logic.readBoolOrNil(settings.showHighlight), true),
		showQualifierColumnOverWinnerRunnerup = Logic.readBool(settings.qualifiers),
		showRank = Logic.readBool(Logic.nilOr(settings.showRank)),
		-- either manually toggled tier column or if parameters are made in a way that allows for multiple tiers
		--- case 1: tier is set as '!' --> all tiers can be returned
		--- case 2: tier1 and tier2 both set --> multiple tiers can be returned
		showTier = Logic.readBool(Logic.nilOr(settings.showTier, tier1 == '!' or Logic.isNotEmpty(settings.tier2))),
		offset = tonumber(settings.offset) or 0,
		onlyHighlightOnValue = settings.onlyHighlightOnValue,
		onlyTierTypeIfBoth = Logic.nilOr(Logic.readBoolOrNil(settings.onlyTierTypeIfBoth), true),
		noLis = Logic.readBool(settings.noLis),
	}
end)

---@return Html?
function TournamentsListingDisplayTable:build()
	if not self.parent.data then
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
	for _, rowData in ipairs(self.parent.data) do
		self:_row(rowData)
	end

	return self.display
end

---@return Html
function TournamentsListingDisplayTable:_header()
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
			:tag('div'):addClass('gridCell Prize'):wikitext('Prize' .. NONBREAKING_SPACE .. 'Pool'):done()
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

---@param tournamentData table
function TournamentsListingDisplayTable:_row(tournamentData)
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
				:node(TournamentsListingDisplayTable._organizerDisplay(tournamentData))
	end

	local dateCell = row:tag('div')
			:addClass('gridCell EventDetails Date Header')
			:wikitext(TournamentsListingDisplayTable._dateDisplay(tournamentData.startdate, tournamentData.enddate,
				status))

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
			:wikitext(TournamentsListingDisplayTable._displayLocations(tournamentData.locations or {},
				tournamentData.type))

	local participantsNumberCell = row:tag('div')
			:addClass('gridCell EventDetails PlayerNumber Header')
	if participantNumber ~= -1 then
		participantsNumberCell:node(TournamentsListingDisplayTable.participantsNumber(participantNumber))
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

	local placements = self.parent.placements
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

---@param opponents table[]
---@return Html
function TournamentsListingDisplayTable:_buildParticipantsSpan(opponents)
	local participantsSpan = mw.html.create('span')
			:addClass('Participants')
	for _, opponent in ipairs(opponents) do
		participantsSpan:node(OpponentDisplay.BlockOpponent{opponent = opponent})
	end

	return participantsSpan
end

---@param prize number
function TournamentsListingDisplayTable:_calculateRank(prize)
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
function TournamentsListingDisplayTable._organizerDisplay(tournamentData)
	local organizers = Logic.emptyOr(tournamentData.organizers) or {}
	organizers = Json.parseIfString(organizers)

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
function TournamentsListingDisplayTable._displayLocations(locationData, tournamentType)
	local locations = Array.mapIndexes(function(locationIndex)
		return TournamentsListingDisplayTable._displayLocation(locationData, locationIndex)
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
function TournamentsListingDisplayTable._displayLocation(locationData, locationIndex)
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

	return String.nilIfEmpty(display .. (city or Flags.CountryName(country)))
end

---@param startDate string
---@param endDate string
---@param status string?
---@return string
function TournamentsListingDisplayTable._dateDisplay(startDate, endDate, status)
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

---@param number number|string|nil
---@return Html|string
function TournamentsListingDisplayTable.participantsNumber(number)
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
function TournamentsListingDisplayTable:getHighlightClass(tournamentData)
	return HighlightConditions.tournament(tournamentData, self.config)
			and 'tournament-highlighted-bg'
			or nil
end

---@param tournamentData table
---@return Html
function TournamentsListingDisplayTable:displayTier(tournamentData)
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

return TournamentsListingDisplayTable
