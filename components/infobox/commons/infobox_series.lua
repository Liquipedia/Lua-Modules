---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Series
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tier = require('Module:Tier')
local WarningBox = require('Module:WarningBox')

local BasicInfobox = Lua.import('Module:Infobox/Basic', {requireDevIfEnabled = true})
local Flags = Lua.import('Module:Flags', {requireDevIfEnabled = true})
local LeagueIcon = Lua.import('Module:LeagueIcon', {requireDevIfEnabled = true})
local Links = Lua.import('Module:Links', {requireDevIfEnabled = true})
local Locale = Lua.import('Module:Locale', {requireDevIfEnabled = true})
local Localisation = Lua.import('Module:Localisation', {requireDevIfEnabled = true})
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner', {requireDevIfEnabled = true})

local _TIER_MODE_TYPES = 'types'
local _TIER_MODE_TIERS = 'tiers'
local _INVALID_TIER_WARNING = '${tierString} is not a known Liquipedia '
	.. '${tierMode}[[Category:Pages with invalid ${tierMode}]]'

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder

local Series = Class.new(BasicInfobox)

Series.warnings = {}

function Series.run(frame)
	local series = Series(frame)
	return series:createInfobox(frame)
end

function Series:createInfobox(frame)
	local infobox = self.infobox
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

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{content = {args.caption}},
		Title{name = 'Series Information'},
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
				args.venue1 = args.venue1 or args.venue
				args.venue1link = args.venue1link or args.venuelink
				args.venue1desc = args.venue1desc or args.venuedesc

				local venues = {}
				for prefix, venueName in Table.iter.pairsByPrefix(args, 'venue') do
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
						Title{name = 'Links'},
						Widgets.Links{content = links}
					}
				end
			end
		},
		Customizable{id = 'customcontent', children = {}},
	}

	if Namespace.isMain() then
		infobox:categories(
			'Tournament series',
			self:_setCountryCategories(args.country),
			self:_setCountryCategories(args.country2),
			self:_setCountryCategories(args.country3),
			self:_setCountryCategories(args.country4),
			self:_setCountryCategories(args.country5)
		)
	end

	local builtInfobox = infobox:widgetInjector(self:createWidgetInjector()):build(widgets)

	if Namespace.isMain() then
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
			prizepool = args.prizepool,
			liquipediatier = Tier.text.tiers
				and Tier.text.tiers[string.lower(args.liquipediatier or '')]
				or args.liquipediatiertype,
			liquipediatiertype = Tier.text.types
				and Tier.text.types[string.lower(args.liquipediatiertype or '')]
				or args.liquipediatiertype,
			publishertier = args.publishertier,
			launcheddate = ReferenceCleaner.clean(args.launcheddate or args.sdate or args.inaugurated),
			defunctdate = ReferenceCleaner.clean(args.defunctdate or args.edate),
			defunctfate = ReferenceCleaner.clean(args.defunctfate),
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
		lpdbData = self:_getIconFromLeagueIconSmall(frame, lpdbData)

		lpdbData = self:addToLpdb(lpdbData)
		mw.ext.LiquipediaDB.lpdb_series('series_' .. self.name, lpdbData)
	end

	return tostring(builtInfobox)
		.. WarningBox.displayAll(Series.warnings)
end

--- Allows for overriding this functionality
function Series:addToLpdb(lpdbData)
	return lpdbData
end

function Series:createLiquipediaTierDisplay(args)
	local tier = args.liquipediatier
	local tierType = args.liquipediatiertype
	if String.isEmpty(tier) then
		return nil
	end

	local function buildTierString(tierString, tierMode)
		local tierText
		if not Tier.text[tierMode] then -- allow legacy tier modules
			tierText = Tier.text[tierString]
		else -- default case, i.e. tier module with intended format
			tierText = Tier.text[tierMode][tierString:lower()]
		end
		if not tierText then
			tierMode = tierMode == _TIER_MODE_TYPES and 'Tiertype' or 'Tier'
			table.insert(
				self.warnings,
				String.interpolate(_INVALID_TIER_WARNING, {tierString = tierString, tierMode = tierMode})
			)
			return ''
		else
			self.infobox:categories(tierText .. ' Tournaments')
			return '[[' .. tierText .. ' Tournaments|' .. tierText .. ']]'
		end
	end

	local tierDisplay = buildTierString(tier, _TIER_MODE_TIERS)

	if String.isNotEmpty(tierType) then
		tierDisplay = buildTierString(tierType, _TIER_MODE_TYPES) .. '&nbsp;(' .. tierDisplay .. ')'
	end

	return tierDisplay .. self.appendLiquipediatierDisplay(args)
end

--- Allows for overriding this functionality
function Series:liquipediaTierHighlighted(args)
	return false
end

--- Allows for overriding this functionality
function Series:appendLiquipediatierDisplay()
	return ''
end

function Series:_getIconFromLeagueIconSmall(frame, lpdbData)
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

function Series:_createLocation(country, city)
	if country == nil or country == '' then
		return ''
	end

	return Flags.Icon({flag = country, shouldLink = true}) .. '&nbsp;' .. (city or country)
end

function Series:_createLink(id, name, link, desc)
	if String.isEmpty(id) then
		return nil
	end

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

function Series:_createOrganizers(args)
	local organizers = {
		Series:_createLink(
			args.organizer, args['organizer-name'], args['organizer-link'], args.organizerref),
	}

	local index = 2

	while not String.isEmpty(args['organizer' .. index]) do
		table.insert(
			organizers,
			Series:_createLink(
				args['organizer' .. index],
				args['organizer' .. index .. '-name'],
				args['organizer' .. index .. '-link'],
				args['organizerref' .. index])
		)
		index = index + 1
	end

	return organizers
end

function Series:_setCountryCategories(country)
	if country == nil or country == '' then
		return ''
	end

	local countryAdjective = Localisation.getLocalisation({ shouldReturnSimpleError = true }, country)
	if countryAdjective == 'error' then
		return 'Unrecognised Country||' .. country
	end

	return countryAdjective .. ' Tournaments'
end

return Series
