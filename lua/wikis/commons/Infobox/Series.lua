---
-- @Liquipedia
-- page=Module:Infobox/Series
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Tier = Lua.import('Module:Tier/Custom')
local Variables = Lua.import('Module:Variables')

local BasicInfobox = Lua.import('Module:Infobox/Basic')
local Flags = Lua.import('Module:Flags')
local InfoboxPrizePool = Lua.import('Module:Infobox/Extensions/PrizePool')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Links = Lua.import('Module:Links')
local Locale = Lua.import('Module:Locale')
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner')

local INVALID_TIER_WARNING = '${tierString} is not a known Liquipedia ${tierMode}'

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder

---@class SeriesInfobox: BasicInfobox
local Series = Class.new(BasicInfobox)

---@param frame Frame
---@return string
function Series.run(frame)
	local series = Series(frame)
	return series:createInfobox()
end

---@return string
function Series:createInfobox()
	local args = self.args

	-- define this here so we can use it in lpdb data and the display
	local links = Links.transform(args)

	-- Split venue from legacy format to new format.
	-- Legacy format is a wiki-code string that can include an external link
	-- New format has |venue= and |venuelink= as different parameters.
	-- This should be removed once there's been a bot run to change this.
	if not args.venuelink and args.venue and args.venue:sub(1, 1) == '[' then
		-- Remove [] and split on space
		local splitVenue = mw.text.split(args.venue:gsub('%[', ''):gsub('%]', ''), ' ')
		args.venuelink = splitVenue[1]
		table.remove(splitVenue, 1)
		args.venue = table.concat(splitVenue, ' ')
	end

	self.totalSeriesPrizepool = self:getSeriesPrizepools()

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = 'Series Information'},
		Builder{
			builder = function()
				local organizers = self:_createOrganizers(args)
				local title = Table.size(organizers) == 1 and 'Organizer' or 'Organizers'

				return {
					Cell{
						name = title,
						content = organizers
					}
				}
			end
		},
		Cell{
			name = 'Sponsor(s)',
			content = self:getAllArgsForBase(args, 'sponsor')
		},
		Customizable{id = 'type', children = {}},
		Customizable{
			id = 'location',
			children = {
				Cell{
					name = 'Location',
					content = {
						self:_createLocation(args.country, args.city)
					}
				},
			}
		},
		Builder{
			builder = function()
				local venues = {}
				for prefix, venueName in Table.iter.pairsByPrefix(args, 'venue', {requireIndex = false}) do
					-- TODO: Description
					local description = ''
					table.insert(venues, self:_createLink(venueName, nil, args[prefix .. 'link'], description))
				end

				return {Cell{
					name = 'Venue',
					content = venues
				}}
			end
		},
		Cell{
			name = 'Date',
			content = {
				args.date
			}
		},
		Cell{
			name = 'Start Date',
			content = {
				args.sdate or args.launched or args.inaugurated
			}
		},
		Cell{
			name = 'End Date',
			content = {
				args.edate or args.defunct
			}
		},
		Customizable{
			id = 'custom',
			children = {}
		},
		Customizable{id = 'totalprizepool', children = {Builder{
			builder = function()
				if self.totalSeriesPrizepool then
					return {Cell{
						name = 'Cumulative Prize Pool',
						content = {InfoboxPrizePool.display{prizepoolusd = self.totalSeriesPrizepool}}
					}}
				end
			end
		}}},
		Customizable{
			id = 'liquipediatier',
			children = {
				Cell{
					name = 'Liquipedia Tier',
					content = {self:createLiquipediaTierDisplay(args)},
					classes = {self:liquipediaTierHighlighted(args) and 'valvepremier-highlighted' or ''},
				},
			}
		},
		Builder{
			builder = function()
				if not Table.isEmpty(links) then
					return {
						Title{children = 'Links'},
						Widgets.Links{links = links}
					}
				end
			end
		},
		Customizable{id = 'customcontent', children = {}},
	}

	if self:shouldStore(args) then
		self:_setLpdbData(args, links)
		self:categories(unpack(self:_getCategories(args)))
	end

	return self:build(widgets)
end

---@param args table
---@param links table
function Series:_setLpdbData(args, links)
	local tier, tierType = Tier.toValue(args.liquipediatier, args.liquipediatiertype)

	local lpdbData = {
		name = self.name,
		image = args.image,
		imagedark = args.imagedark or args.imagedarkmode,
		abbreviation = args.abbreviation or args.acronym,
		icon = args.icon,
		icondark = args.icondark or args.icondarkmode,
		game = args.game,
		type = args.type,
		location = Locale.formatLocation({city = args.city, country = args.country}),
		location2 = Locale.formatLocation({city = args.city2, country = args.country2}),
		locations = Locale.formatLocations(args),
		previous = args.previous,
		previous2 = args.previous2,
		next = args.next,
		next2 = args.next2,
		prizepool = self.totalSeriesPrizepool or args.prizepool,
		liquipediatier = tier,
		liquipediatiertype = tierType,
		publishertier = args.publishertier,
		launcheddate = ReferenceCleaner.clean{input = args.launcheddate or args.sdate or args.inaugurated},
		defunctdate = ReferenceCleaner.clean{input = args.defunctdate or args.edate},
		defunctfate = ReferenceCleaner.clean{input = args.defunctfate},
		organizers = mw.ext.LiquipediaDB.lpdb_create_json({
			organizer1 = args.organizer or args.organizer1,
			organizer2 = args.organizer2,
			organizer3 = args.organizer3,
			organizer4 = args.organizer4,
			organizer5 = args.organizer5,
		}),
		sponsors = mw.ext.LiquipediaDB.lpdb_create_json({
			sponsor1 = args.sponsor1,
			sponsor2 = args.sponsor2,
			sponsor3 = args.sponsor3,
			sponsor4 = args.sponsor4,
			sponsor5 = args.sponsor5,
		}),
		links = mw.ext.LiquipediaDB.lpdb_create_json(
			Links.makeFullLinksForTableItems(links or {})
		),
	}
	lpdbData = self:_getIconFromLeagueIconSmall(lpdbData)

	lpdbData = self:addToLpdb(lpdbData, args)

	mw.ext.LiquipediaDB.lpdb_series('series_' .. self.name, lpdbData)
end

--- Allows for overriding this functionality
---@param lpdbData table
---@param args table
---@return table
function Series:addToLpdb(lpdbData, args)
	return lpdbData
end

--- Allows for overriding this functionality
---@param args table
---@return boolean
function Series:shouldStore(args)
	return Namespace.isMain() and
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
end

---@param args table
---@return string
function Series:createLiquipediaTierDisplay(args)
	return (Tier.display(args.liquipediatier, args.liquipediatiertype, {link = true}) or '')
		.. self:appendLiquipediatierDisplay(args)
end

--- Allows for overriding this functionality
---@param args table
---@return boolean
function Series:liquipediaTierHighlighted(args)
	return false
end

--- Allows for overriding this functionality
---@param args table
---@return string
function Series:appendLiquipediatierDisplay(args)
	return ''
end

---@param lpdbData table
---@return table
function Series:_getIconFromLeagueIconSmall(lpdbData)
	local icon = lpdbData.icon
	local iconDark = lpdbData.icondark
	local iconSmallTemplate = LeagueIcon.display{
		icon = icon,
		iconDark = iconDark,
		series = lpdbData.name,
		date = lpdbData.defunctfate
	}
	local trackingCategory

	icon, iconDark, trackingCategory = LeagueIcon.getIconFromTemplate{
		icon = icon,
		iconDark = iconDark,
		stringOfExpandedTemplate = iconSmallTemplate
	}

	if String.isNotEmpty(trackingCategory) then
		table.insert(
			self.warnings,
			'Missing icon while icondark is set.' .. trackingCategory
		)
	end

	lpdbData.icon = icon
	lpdbData.icondark = iconDark

	return lpdbData
end

---@param country string?
---@param city string?
---@return string
function Series:_createLocation(country, city)
	if country == nil or country == '' then
		return ''
	end

	return Flags.Icon{flag = country, shouldLink = true} .. '&nbsp;' .. (city or country)
end

---@param id string?
---@param name string?
---@param link string?
---@param desc string?
---@return string?
function Series:_createLink(id, name, link, desc)
	if String.isEmpty(id) then
		return nil
	end
	---@cast id -nil

	local output

	if Page.exists(id) then
		output = '[[' .. id .. '|'
		if String.isEmpty(name) then
			output = output .. id .. ']]'
		else
			output = output .. name .. ']]'
		end

	elseif not String.isEmpty(link) then
		if String.isEmpty(name) then
			output = '[' .. link .. ' ' .. id .. ']'
		else
			output = '[' .. link .. ' ' .. name .. ']'

		end
	elseif String.isEmpty(name) then
		output = id
	else
		output = name
	end

	if not String.isEmpty(desc) then
		output = output .. desc
	end

	return output
end

---@param args table
---@return string[]
function Series:_createOrganizers(args)
	local organizers = {}

	for prefix, organizer in Table.iter.pairsByPrefix(args, 'organizer', {requireIndex = false}) do
		table.insert(organizers, self:_createLink(organizer, args[prefix .. '-name'], args[prefix .. '-link']))
	end

	return organizers
end

---@param args table
---@return string[]
function Series:_getCategories(args)
	local categories = {'Tournament series'}

	for _, country in Table.iter.pairsByPrefix(args, 'country', {requireIndex = false}) do
		table.insert(categories, self:_setCountryCategories(country))
	end

	Array.extendWith(categories, self:addTierCategories(args))

	return categories
end

---@param args table
---@return string[]
function Series:addTierCategories(args)
	local categories = {}
	local tier = args.liquipediatier
	local tierType = args.liquipediatiertype

	local tierCategory, tierTypeCategory = Tier.toCategory(tier, tierType)
	local isValidTierTuple = Tier.isValid(tier, tierType)
	table.insert(categories, tierCategory)
	table.insert(categories, tierTypeCategory)

	if not isValidTierTuple and not tierCategory and String.isNotEmpty(tier) then
		table.insert(self.warnings, String.interpolate(INVALID_TIER_WARNING, {tierString = tier, tierMode = 'Tier'}))
		table.insert(categories, 'Pages with invalid Tier')
	end
	if not isValidTierTuple and not tierTypeCategory and String.isNotEmpty(tierType) then
		table.insert(self.warnings,
			String.interpolate(INVALID_TIER_WARNING, {tierString = tierType, tierMode = 'Tiertype'}))
		table.insert(categories, 'Pages with invalid Tiertype')
	end

	return categories
end

---@param country string?
---@return string?
function Series:_setCountryCategories(country)
	if String.isEmpty(country) then
		return nil
	end

	local countryAdjective = Flags.getLocalisation(country)
	if not countryAdjective then
		return 'Unrecognised Country'
	end

	return countryAdjective .. ' Tournaments'
end

---@return number?
function Series:getSeriesPrizepools()
	local pagename = self.pagename:gsub('%s', '_')
	local queryData = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[series::' .. self.name .. ']] OR [[seriespage::' .. pagename .. ']]',
		query = 'sum::prizepool'
	})

	local prizemoney = tonumber(queryData[1]['sum_prizepool'])

	if prizemoney == nil or prizemoney == 0 then
		return nil
	end
	return prizemoney
end

return Series
