---
-- @Liquipedia
-- page=Module:TournamentsListing/CardList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Currency = Lua.import('Module:Currency')
local DateExt = Lua.import('Module:Date/Ext')
local Flags = Lua.import('Module:Flags')
local FnUtil = Lua.import('Module:FnUtil')
local Game = Lua.import('Module:Game')
local Info = Lua.import('Module:Info', {loadData = true})
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Region = Lua.import('Module:Region')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Conditions = Lua.import('Module:TournamentsListing/Conditions')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local Tier = Lua.import('Module:Tier/Custom')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local LinkWidget = Lua.import('Module:Widget/Basic/Link')
local DateRange = Lua.import('Module:Widget/Misc/DateRange')

local DEFAULT_START_YEAR = Info.startYear
local DEFAULT_END_YEAR = DateExt.getYearOf()
local LANG = mw.getContentLanguage()
local NONBREAKING_SPACE = '&nbsp;'
local POSTPONED = 'postponed'
local DELAYED = 'delayed'
local CANCELLED = 'cancelled'
local DEFAULT_ALLOWED_PLACES = '1,2,1-2,2-3,W,L'
local DEFAULT_LIMIT = 5000

---@class BaseTournamentsListingConfig
---@field showTier boolean
---@field onlyTierTypeIfBoth boolean
---@field showOrganizer boolean
---@field showGameIcon boolean
---@field showHighlight boolean
---@field showQualifierColumnOverWinnerRunnerup boolean
---@field useParent boolean
---@field showRank boolean
---@field noLis boolean
---@field offset number
---@field allowedPlacements string[]
---@field dynamicPlacements boolean
---@field onlyHighlightOnValue string?

--- @class BaseTournamentsListing
--- @field config BaseTournamentsListingConfig
--- @operator call(...): BaseTournamentsListing
local BaseTournamentsListing = Class.new(function(self, ...) self:init(...) end)

---@param args table
---@return Widget?
function BaseTournamentsListing.byYear(args)
	args = args or {}

	args.order = 'enddate desc'

	local subPageName = mw.title.getCurrentTitle().subpageText
	local fallbackYearData = {}
	if subPageName:find('%d%-%d') then
		fallbackYearData = mw.text.split(subPageName, '-')
	end

	local startYear = tonumber(args.startYear) or tonumber(fallbackYearData[1]) or DEFAULT_START_YEAR
	local endYear = tonumber(args.endYear) or tonumber(fallbackYearData[2]) or DEFAULT_END_YEAR

	local children = {}
	Array.forEach(Array.reverse(Array.range(startYear, endYear)), function(year)
		local tournaments = BaseTournamentsListing(Table.merge(args, {year = year})):create():build()
		if not tournaments then return end
		Array.appendWith(children,
			HtmlWidgets.H3{children = year},
			tournaments
		)
	end)

	return HtmlWidgets.Fragment{children = children}
end

---@param args table
---@return self
function BaseTournamentsListing:init(args)
	self.args = Table.merge(Info.config.tournamentsListing, args)

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
		dynamicPlacements = Logic.readBool(args.dynamicPlacements),
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
		conditions = self:buildConditions(),
		query = 'pagename, name, icon, icondark, organizers, startdate, enddate, status, locations, series, '
			.. 'prizepool, participantsnumber, game, liquipediatier, liquipediatiertype, extradata, publishertier, type',
		order = self.args.order,
		limit = self.args.limit or DEFAULT_LIMIT,
		offset = self.config.offset,
	})
end

---@protected
---@return string
function BaseTournamentsListing:buildConditions()

	local conditions = tostring(Conditions.base(self.args))

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

	self.cachedData = {rank = 1, prize = 0, skippedRanks = self.config.offset}

	return TableWidgets.Table{
		columns = self:buildColumnDefinitions(),
		children = {
			TableWidgets.TableHeader{
				children = {self:_header()}
			},
			TableWidgets.TableBody{
				children = Array.map(self.data, FnUtil.curry(self._row, self))
			}
		}
	}
end

---@private
---@return table[]
function BaseTournamentsListing:buildColumnDefinitions()
	local config = self.config

	return WidgetUtil.collect(
		config.showRank and {align = 'right'} or nil, 		-- Rank
		config.showTier and {align = 'left'} or nil, 		-- Tier
		config.showGameIcon and {align = 'center'} or nil, 	-- Game
		{align = 'left'},									-- Icon
		{align = 'left'},									-- Tournament
		config.showOrganizer and {align = 'left'} or nil,	-- Organizer
		{align = 'left'},									-- Date
		{													-- Prizepool
			align = 'right',
			sortType = 'currency',
		},
		{align = 'left'},									-- Location
		{align = 'right'},									-- Participants
		config.showQualifierColumnOverWinnerRunnerup
			and {align = 'left'}							-- Qualified
			or WidgetUtil.collect(
				{align = 'left'},							-- Winner
				{align = 'left'}							-- Runner-up
			)
	)
end
---@private
---@return Widget
function BaseTournamentsListing:_header()
	local config = self.config

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			config.showRank and TableWidgets.CellHeader{children = '#'} or nil,
			config.showTier and TableWidgets.CellHeader{children = 'Tier'} or nil,
			config.showGameIcon and TableWidgets.CellHeader{
				children = HtmlWidgets.Abbr{title = 'Game', children = 'G'}
			} or nil,
			TableWidgets.CellHeader{colspan = 2, children = 'Tournament'},
			config.showOrganizer and TableWidgets.CellHeader{children = 'Organizer'} or nil,
			TableWidgets.CellHeader{children = 'Date'},
			TableWidgets.CellHeader{children = 'Prize' .. NONBREAKING_SPACE .. 'Pool'},
			TableWidgets.CellHeader{children = 'Location'},
			TableWidgets.CellHeader{children = HtmlWidgets.Abbr{title = 'Number of Participants', children = 'P#'}},
			config.showQualifierColumnOverWinnerRunnerup
				and TableWidgets.CellHeader{children = 'Qualified'}
				or WidgetUtil.collect(
					TableWidgets.CellHeader{children = 'Winner'},
					TableWidgets.CellHeader{children = 'Runner-up'}
				)
		)
	}
end

---@private
---@param tournamentData table
---@return Widget
function BaseTournamentsListing:_row(tournamentData)
	local config = self.config

	local highlight = config.showHighlight and self:getHighlightClass(tournamentData) or nil
	local status = tournamentData.status and tournamentData.status:lower()

	if config.showRank then
		self:_calculateRank(tonumber(tournamentData.prizepool) or 0)
	end

	local prizeValue = tonumber(tournamentData.prizepool) or 0
	local participantNumber = tonumber(tournamentData.participantsnumber) or -1

	local placements = self:_fetchPlacementData(tournamentData)

	return TableWidgets.Row{
		highlighted = highlight,
		children = WidgetUtil.collect(
			config.showRank and TableWidgets.Cell{children = self.cachedData.rank} or nil,
			config.showTier and TableWidgets.Cell{children = self:displayTier(tournamentData)} or nil,
			config.showGameIcon and TableWidgets.Cell{
				children = Game.icon{
					game = tournamentData.game, useDefault = false
				}
			} or nil,
			TableWidgets.Cell{
				attributes = {
					['data-sort-value'] = tournamentData.name
				},
				children = LeagueIcon.display{
					icon = tournamentData.icon,
					iconDark = tournamentData.icondark,
					link = tournamentData.parent,
					name = tournamentData.name,
					options = {noTemplate = true},
				}
			},
			TableWidgets.Cell{
				css = {
					['text-decoration'] = status == CANCELLED and 'line-through' or nil,
				},
				attributes = {
					['data-sort-value'] = tournamentData.name,
				},
				children = LinkWidget{
					children = tournamentData.name,
					link = tournamentData.pagename,
				}
			},
			config.showOrganizer
				and TableWidgets.Cell{children = BaseTournamentsListing._organizerDisplay(tournamentData)}
				or nil,
			TableWidgets.Cell{
				classes = {
					status == POSTPONED or status == DELAYED and 'bg-second' or nil
				},
				css = {
					['font-style'] = status == POSTPONED or status == DELAYED and 'italic' or nil,
				},
				children = BaseTournamentsListing._dateDisplay(tournamentData.startdate, tournamentData.enddate, status)
			},
			TableWidgets.Cell{
				children = prizeValue > 0
					and Currency.display('USD', prizeValue, {
						dashIfZero = true, displayCurrencyCode = false, formatValue = true
					}) or nil
			},
			TableWidgets.Cell{
				children = BaseTournamentsListing._displayLocations(tournamentData.locations or {}, tournamentData.type)
			},
			TableWidgets.Cell{
				children = participantNumber ~= -1
					and BaseTournamentsListing.participantsNumber(participantNumber)
					or '-'
			},
			status == CANCELLED
				and TableWidgets.Cell{
					colspan = config.showQualifierColumnOverWinnerRunnerup and 1 or 2,
					classes = {'bg-down'},
					css = {
						['justify-content'] = 'center',
						['font-style'] = 'italic',
					},
					children = 'Cancelled'
				}
				or config.showQualifierColumnOverWinnerRunnerup
					and TableWidgets.Cell{children = self:_buildParticipants(placements.qualified)}
					or WidgetUtil.collect(
						TableWidgets.Cell{children = self:_buildParticipants(placements[1])},
						TableWidgets.Cell{children = self:_buildParticipants(placements[2])}
					) or nil
		)
}
end

---@private
---@param opponents table[]
---@return Widget
function BaseTournamentsListing:_buildParticipants(opponents)
	return HtmlWidgets.Div{
		css = {
			display = 'inline-grid',
			['grid-template-columns'] = 'repeat( auto-fit, minmax( 150px, 1fr ) )',
			['min-width'] = '15vw'
		},
		children = Array.map(opponents, function (opponent)
			return OpponentDisplay.BlockOpponent{opponent = opponent}
		end)
	}
end

---@private
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

---@private
---@param tournamentData table
---@return string[]
function BaseTournamentsListing._organizerDisplay(tournamentData)
	local organizers = Logic.emptyOr(tournamentData.organizers) or {}
	if type(organizers) == 'string' then
		organizers = Json.parse(organizers)
	end

	local organizerArray = {}
	for _, organizer in Table.iter.pairsByPrefix(organizers, 'organizer') do
		table.insert(organizerArray, organizer)
	end

	return Array.interleave(organizerArray, ', ')
end

---@param locationData table
---@param tournamentType string?
---@return string|Widget?
function BaseTournamentsListing._displayLocations(locationData, tournamentType)
	local locations = Array.mapIndexes(function(locationIndex)
		return BaseTournamentsListing._displayLocation(locationData, locationIndex)
	end)

	if Table.isEmpty(locations) then
		return tournamentType and mw.getContentLanguage():ucfirst(tournamentType) or nil
	end

	return HtmlWidgets.Div{
		css = {
			display = 'inline-grid'
		},
		children = locations
	}
end

---@private
---@param locationData table
---@param locationIndex integer
---@return Widget?
function BaseTournamentsListing._displayLocation(locationData, locationIndex)
	local icon = ''
	local region = locationData['region' .. locationIndex]
	local country = locationData['country' .. locationIndex]
	local city = locationData['city' .. locationIndex]

	if country then
		icon = Flags.Icon{flag = country} .. NONBREAKING_SPACE
	elseif city and region then
		icon = Flags.Icon{flag = region} .. NONBREAKING_SPACE
	elseif region then
		icon = Region.display{region = region, linkToCategory = false}
	end

	local text = city or Flags.CountryName{flag = country}
	if String.isEmpty(icon) and String.isEmpty(text) then
		return nil
	end

	return HtmlWidgets.Span{
		children = {
			icon,
			text
		}
	}
end

---@private
---@param startDate string
---@param endDate string
---@param status string?
---@return Widget|string
function BaseTournamentsListing._dateDisplay(startDate, endDate, status)
	if status == POSTPONED or status == DELAYED then
		return 'Postponed'
	end

	return DateRange{startDate = startDate, endDate = endDate, showYear = true}
end

---@private
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
			if place and place > 2 then
				-- Map runnerup placements to second slot
				place = 2
			end

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
---@return string
function BaseTournamentsListing.participantsNumber(number)
	number = tonumber(number)
	if not number or number <= 0 then
		return NONBREAKING_SPACE
	end

	return LANG:formatNum(number)
end

-- overwritable in case wikis want several highlight options
---@protected
---@param tournamentData table
---@return boolean
function BaseTournamentsListing:getHighlightClass(tournamentData)
	return HighlightConditions.tournament(tournamentData, self.config)
end

---@param tournamentData table
---@return string?
function BaseTournamentsListing:displayTier(tournamentData)
	local tier, tierType, options = Tier.parseFromQueryData(tournamentData)
	options.link = true
	if self.config.onlyTierTypeIfBoth then
		options.onlyTierTypeIfBoth = true
	else
		options.tierTypeShort = true
	end

	return Tier.display(tier, tierType, options)
end

return BaseTournamentsListing
