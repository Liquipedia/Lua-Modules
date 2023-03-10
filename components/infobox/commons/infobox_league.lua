---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/League
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local Tier = require('Module:Tier') -- loadData?
local Variables = require('Module:Variables')
local WarningBox = require('Module:WarningBox')

local BasicInfobox = Lua.import('Module:Infobox/Basic', {requireDevIfEnabled = true})
local Flags = Lua.import('Module:Flags', {requireDevIfEnabled = true})
local InfoboxPrizePool = Lua.import('Module:Infobox/Extensions/PrizePool', {requireDevIfEnabled = true})
local LeagueIcon = Lua.import('Module:LeagueIcon', {requireDevIfEnabled = true})
local Links = Lua.import('Module:Links', {requireDevIfEnabled = true})
local Locale = Lua.import('Module:Locale', {requireDevIfEnabled = true})
local MetadataGenerator = Lua.import('Module:MetadataGenerator', {requireDevIfEnabled = true})
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner', {requireDevIfEnabled = true})
local TextSanitizer = Lua.import('Module:TextSanitizer', {requireDevIfEnabled = true})

local _TIER_MODE_TYPES = 'types'
local _TIER_MODE_TIERS = 'tiers'
local _INVALID_TIER_WARNING = '${tierString} is not a known Liquipedia '
	.. '${tierMode}[[Category:Pages with invalid ${tierMode}]]'
local VENUE_DESCRIPTION = '<br><small><small>(${desc})</small></small>'

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder
local Chronology = Widgets.Chronology

local League = Class.new(BasicInfobox)

League.warnings = {}

function League.run(frame)
	local league = League(frame)
	return league:createInfobox()
end

function League:createInfobox()
	local args = self.args
	args.abbreviation = self:_fetchAbbreviation()
	local links

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

	-- set Variables here already so they are available in functions
	-- we call from here on, e.g. _createPrizepool
	self:_definePageVariables(args)

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{content = {args.caption}},
		Title{name = 'League Information'},
		Cell{
			name = 'Series',
			content = {
				self:_createSeries(
					{
						shouldSetVariable = true,
						displayManualIcons = Logic.readBool(args.display_series_icon_from_manual_input),
					},
					args.series,
					args.abbreviation,
					args.icon,
					args.icondark or args.icondarkmode
				),
				self:_createSeries(
					{shouldSetVariable = false},
					args.series2,
					args.abbreviation2
				)
			}
		},
		Customizable{
			id = 'organizers',
			children = {
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
			},
		},
		Customizable{
			id = 'sponsors',
			children = {
				Cell{name = 'Sponsor(s)', content = self:getAllArgsForBase(args, 'sponsor')},
			}
		},
		Customizable{
			id = 'gamesettings',
			children = {
				Cell{name = 'Server', content = {args.server}}
			}
		},
		Customizable{id = 'type', children = {
				Builder{
					builder = function()
						local value = tostring(args.type):lower()
						if self:shouldStore(args) then
							if value == 'offline' then
								self.infobox:categories('Offline Tournaments')
							elseif value == 'online' then
								self.infobox:categories('Online Tournaments')
							elseif value:match('online') and value:match('offline') then
								self.infobox:categories('Online/Offline Tournaments')
							else
								self.infobox:categories('Unknown Type Tournaments')
							end
						end

						if not String.isEmpty(args.type) then
							return {
								Cell{
									name = 'Type',
									content = {
										mw.language.getContentLanguage():ucfirst(args.type)
									}
								}
							}
						end
					end
				}
			}
		},
		Customizable{id = 'location', children = {Cell{
			name = 'Location',
			content = {
				self:_createLocation(args)
			}
		}}},
		Builder{
			builder = function()
				local venues = {}
				for prefix, venueName in Table.iter.pairsByPrefix(args, 'venue', {requireIndex = false}) do
					local description
					if String.isNotEmpty(args[prefix .. 'desc']) then
						description = String.interpolate(VENUE_DESCRIPTION, {desc = args[prefix .. 'desc']})
					end

					table.insert(venues, self:createLink(venueName, nil, args[prefix .. 'link'], description))
				end

				return {Cell{
					name = 'Venue',
					content = venues
				}}
			end
		},
		Cell{name = 'Format', content = {args.format}},
		Customizable{id = 'prizepool', children = {
				Cell{
					name = 'Prize Pool',
					content = {self:_createPrizepool(args)},
				},
			},
		},
		Customizable{id = 'dates', children = {
				Cell{name = 'Date', content = {args.date}},
				Cell{name = 'Start Date', content = {args.sdate}},
				Cell{name = 'End Date', content = {args.edate}},
			},
		},
		Customizable{id = 'custom', children = {}},
		Customizable{id = 'liquipediatier', children = {
				Cell{
					name = 'Liquipedia Tier',
					content = {self:createLiquipediaTierDisplay(args)},
					classes = {self:liquipediaTierHighlighted(args) and 'valvepremier-highlighted' or ''},
				},
			},
		},
		Builder{
			builder = function()
				links = Links.transform(args)
				if not Table.isEmpty(links) then
					return {
						Title{name = 'Links'},
						Widgets.Links{content = links}
					}
				end
			end
		},
		Customizable{id = 'customcontent', children = {}},
		Center{content = {args.footnotes}},
		Customizable{id = 'chronology', children = {
				Builder{
					builder = function()
						if self:_isChronologySet(args.previous, args.next) then
							return {
								Title{name = 'Chronology'},
								Chronology{
									content = {
										previous = args.previous,
										next = args.next,
										previous2 = args.previous2,
										next2 = args.next2,
									}
								}
							}
						end
					end
				}
			}
		},
	}

	self.name = TextSanitizer.stripHTML(self.name)

	self.infobox:bottom(self:createBottomContent())

	local builtInfobox = self.infobox:widgetInjector(self:createWidgetInjector()):build(widgets)

	if self:shouldStore(args) then
		self.infobox:categories('Tournaments')
		if not String.isEmpty(args.team_number) then
			self.infobox:categories('Team Tournaments')
		end
		if String.isNotEmpty(args.player_number) or String.isNotEmpty(args.individual) then
			self.infobox:categories('Individual Tournaments')
		end
		self.infobox:categories(unpack(self:getWikiCategories(args)))
		self:_setLpdbData(args, links)
		self:_setSeoTags(args)
	end

	return tostring(builtInfobox) .. WarningBox.displayAll(League.warnings)
end

--- Allows for overriding this functionality
function League:shouldStore(args)
	return Namespace.isMain()
end

--- Allows for overriding this functionality
function League:defineCustomPageVariables(args)
end

--- Allows for overriding this functionality
function League:addToLpdb(lpdbData, args)
	return lpdbData
end

--- Allows for overriding this functionality
function League:seoText(args)
	return MetadataGenerator.tournament(args)
end

--- Allows for overriding this functionality
function League:liquipediaTierHighlighted(args)
	return false
end

--- Allows for overriding this functionality
function League:appendLiquipediatierDisplay()
	return ''
end

function League:_getTierText(tierString, tierMode)
	if not Tier.text[tierMode] then -- allow legacy tier modules
		return Tier.text[tierString]
	else -- default case, i.e. tier module with intended format
		return Tier.text[tierMode][tierString:lower()]
	end
end

--- Allows for overriding this functionality
function League:createLiquipediaTierDisplay(args)
	local tier = args.liquipediatier
	local tierType = args.liquipediatiertype
	if String.isEmpty(tier) then
		return nil
	end

	local function buildTierString(tierString, tierMode)
		local tierText = League:_getTierText(tierString, tierMode)
		if not tierText then
			tierMode = tierMode == _TIER_MODE_TYPES and 'Tiertype' or 'Tier'
			table.insert(
				self.warnings,
				String.interpolate(_INVALID_TIER_WARNING, {tierString = tierString, tierMode = tierMode})
			)
			return ''
		else
			if self:shouldStore(self.args) then
				self.infobox:categories(tierText .. ' Tournaments')
			end
			local tierLink = tierText .. ' Tournaments'
			if Tier.link and Tier.link[tierString] then
				tierLink = Tier.link[tierString]
			end

			return '[[' .. tierLink .. '|' .. tierText .. ']]'
		end
	end

	local tierDisplay = buildTierString(tier, _TIER_MODE_TIERS)

	if String.isNotEmpty(tierType) then
		tierDisplay = buildTierString(tierType, _TIER_MODE_TYPES) .. '&nbsp;(' .. tierDisplay .. ')'
	end

	return tierDisplay .. self.appendLiquipediatierDisplay(args)
end

function League:_createPrizepool(args)
	if String.isEmpty(args.prizepool) and String.isEmpty(args.prizepoolusd) then
		return nil
	end
	local date
	if String.isNotEmpty(args.currency_rate) then
		date = args.currency_date
	end

	return InfoboxPrizePool.display{
		prizepool = args.prizepool,
		prizepoolusd = args.prizepoolusd,
		currency = args.localcurrency,
		rate = args.currency_rate,
		date = date or Variables.varDefault('tournament_enddate'),
	}
end

function League:_definePageVariables(args)
	Variables.varDefine('tournament_name', TextSanitizer.stripHTML(args.name))
	Variables.varDefine('tournament_shortname', TextSanitizer.stripHTML(args.shortname or args.abbreviation))
	Variables.varDefine('tournament_tickername', TextSanitizer.stripHTML(args.tickername))
	Variables.varDefine('tournament_icon', args.icon)
	Variables.varDefine('tournament_icondark', args.icondark or args.icondarkmode)
	Variables.varDefine('tournament_series', mw.ext.TeamLiquidIntegration.resolve_redirect(args.series or ''))

	Variables.varDefine('tournament_liquipediatier', args.liquipediatier)
	Variables.varDefine(
		'tournament_liquipediatiertype',
		Tier.text.types
			and Tier.text.types[string.lower(args.liquipediatiertype or '')]
			or args.liquipediatiertype
	)
	--[[ once tier modules all follow the new format we can simplify this again:
	Variables.varDefine('tournament_liquipediatiertype', Tier.text.types[string.lower(args.liquipediatiertype or '')])
	]]

	Variables.varDefine('tournament_type', args.type)
	Variables.varDefine('tournament_status', args.status or Variables.varDefault('tournament_status'))

	Variables.varDefine('tournament_region', args.region)
	Variables.varDefine('tournament_country', args.country)
	Variables.varDefine('tournament_location', args.location or args.city)
	Variables.varDefine('tournament_location2', args.location2 or args.city2)
	Variables.varDefine('tournament_venue', args.venue)

	Variables.varDefine('tournament_game', string.lower(args.game or ''))

	-- If no parent is available, set pagename instead to ease querying
	local parent = args.parent or mw.title.getCurrentTitle().prefixedText
	parent = string.gsub(parent, ' ', '_')
	Variables.varDefine('tournament_parent', parent)
	Variables.varDefine('tournament_parentname', args.parentname)
	Variables.varDefine('tournament_subpage', args.subpage)

	Variables.varDefine('tournament_startdate',
	self:_cleanDate(args.sdate) or self:_cleanDate(args.date))
	Variables.varDefine('tournament_enddate',
	self:_cleanDate(args.edate) or self:_cleanDate(args.date))

	-- gets overwritten by the League:_createPrizepool call if args.prizepool
	-- or args.prizepoolusd is a valid input
	-- if wikis want it unset they can unset it via the defineCustomPageVariables() call
	Variables.varDefine('tournament_currency', args.localcurrency or '')

	self:defineCustomPageVariables(args)
end

function League:_setLpdbData(args, links)
	local lpdbData = {
		name = self.name,
		tickername = TextSanitizer.stripHTML(args.tickername),
		shortname = TextSanitizer.stripHTML(args.shortname or args.abbreviation),
		banner = args.image,
		bannerdark = args.imagedark or args.imagedarkmode,
		icon = Variables.varDefault('tournament_icon'),
		icondark = Variables.varDefault('tournament_icondark'),
		series = mw.ext.TeamLiquidIntegration.resolve_redirect(args.series or ''),
		seriespage = mw.ext.TeamLiquidIntegration.resolve_redirect(args.series or ''):gsub(' ', '_'),
		previous = mw.ext.TeamLiquidIntegration.resolve_redirect(self:_getPageNameFromChronology(args.previous)),
		previous2 = mw.ext.TeamLiquidIntegration.resolve_redirect(self:_getPageNameFromChronology(args.previous2)),
		next = mw.ext.TeamLiquidIntegration.resolve_redirect(self:_getPageNameFromChronology(args.next)),
		next2 = mw.ext.TeamLiquidIntegration.resolve_redirect(self:_getPageNameFromChronology(args.next2)),
		game = string.lower(args.game or ''),
		mode = Variables.varDefault('tournament_mode', ''),
		patch = args.patch,
		endpatch = args.endpatch or args.epatch,
		type = args.type,
		organizers = mw.ext.LiquipediaDB.lpdb_create_json(
			Table.mapValues(
				League:_getNamedTableofAllArgsForBase(args, 'organizer'),
				mw.ext.TeamLiquidIntegration.resolve_redirect
			)
		),
		startdate = Variables.varDefaultMulti('tournament_startdate', 'tournament_enddate', '1970-01-01'),
		enddate = Variables.varDefault('tournament_enddate', '1970-01-01'),
		sortdate = Variables.varDefault('tournament_enddate', '1970-01-01'),
		location = mw.text.decode(Locale.formatLocation({city = args.city or args.location, country = args.country})),
		location2 = mw.text.decode(Locale.formatLocation({city = args.city2 or args.location2, country = args.country2})),
		venue = args.venue,
		locations = Locale.formatLocations(args),
		prizepool = Variables.varDefault('tournament_prizepoolusd', 0),
		liquipediatier = Variables.varDefault('tournament_liquipediatier'),
		liquipediatiertype = Variables.varDefault('tournament_liquipediatiertype'),
		status = Variables.varDefault('tournament_status'),
		format = TextSanitizer.stripHTML(args.format),
		sponsors = mw.ext.LiquipediaDB.lpdb_create_json(
			League:_getNamedTableofAllArgsForBase(args, 'sponsor')
		),
		links = mw.ext.LiquipediaDB.lpdb_create_json(
			Links.makeFullLinksForTableItems(links or {})
		),
		extradata = {
			series2 = args.series2 and mw.ext.TeamLiquidIntegration.resolve_redirect(args.series2) or nil,
		},
	}

	lpdbData = self:addToLpdb(lpdbData, args)
	lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.extradata)
	mw.ext.LiquipediaDB.lpdb_tournament('tournament_' .. self.name, lpdbData)
end

function League:_setSeoTags(args)
	local desc = self:seoText(args)
	if desc then
		mw.ext.SearchEngineOptimization.metadescl(desc)
	end
end

function League:_getNamedTableofAllArgsForBase(args, base)
	local basedArgs = self:getAllArgsForBase(args, base)
	local namedArgs = {}
	for key, item in pairs(basedArgs) do
		namedArgs[base .. key] = item
	end
	return namedArgs
end

---
-- Format:
-- {
--	region: Region or continent
--	country: the country
--	location: the city or place
-- }
function League:_createLocation(args)
	if String.isEmpty(args.country) then
		return Template.safeExpand(mw.getCurrentFrame(), 'Abbr/TBD')
	end

	local index = 1
	local content = ''
	local current = args['country']
	local currentLocation = args['city'] or args['location']

	while not String.isEmpty(current) do
		local nationality = Flags.getLocalisation(current)

		if String.isEmpty(nationality) then
			content = content .. '[[Category:Unrecognised Country|' .. current .. ']]'

		else
			local countryName = Flags.CountryName(current)
			local displayText = currentLocation or countryName
			if displayText == '' then
				displayText = current
			end

			if self:shouldStore(args) then
				content = content .. '[[Category:' .. nationality .. ' Tournaments]]'
			end
			content = content .. Flags.Icon{flag = current, shouldLink = true} .. '&nbsp;' .. displayText .. '<br>'
		end

		index = index + 1
		current = args['country' .. index]
		currentLocation = args['city' .. index] or args['location' .. index]
	end
	return content
end

function League:_createSeries(options, series, abbreviation, icon, iconDark)
	if String.isEmpty(series) then
		return nil
	end
	options = options or {}

	local seriesPageExists = Page.exists(series)

	local output = LeagueIcon.display{
		icon = options.displayManualIcons and icon or nil,
		iconDark = options.displayManualIcons and iconDark or nil,
		series = series,
		abbreviation = abbreviation,
		date = Variables.varDefault('tournament_enddate'),
		options = { noLink = not seriesPageExists }
	}

	if output == LeagueIcon.display{} then
		output = ''
	else
		output = output .. ' '
		if options.shouldSetVariable then
			League:_setIconVariable(output, icon, iconDark)
		end
	end

	if not seriesPageExists then
		if String.isEmpty(abbreviation) then
			output = output .. series
		else
			output = output .. abbreviation
		end
	elseif String.isEmpty(abbreviation) then
		output = output .. '[[' .. series .. '|' .. series .. ']]'
	else
		output = output .. '[[' .. series .. '|' .. abbreviation .. ']]'
	end

	return output
end

function League:_setIconVariable(iconSmallTemplate, manualIcon, manualIconDark)
	local icon, iconDark, trackingCategory = LeagueIcon.getIconFromTemplate{
		icon = manualIcon,
		iconDark = manualIconDark,
		stringOfExpandedTemplate = iconSmallTemplate
	}
	Variables.varDefine('tournament_icon', icon)
	Variables.varDefine('tournament_icondark', iconDark)

	if String.isNotEmpty(trackingCategory) then
		table.insert(
			self.warnings,
			'Missing icon while icondark is set.'
		)
	end
end

function League:createLink(id, name, link, desc)
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

function League:_createOrganizers(args)
	local organizers = {
		self:createLink(
			args.organizer, args['organizer-name'], args['organizer-link'], args.organizerref),
	}

	local index = 2

	while not String.isEmpty(args['organizer' .. index]) do
		table.insert(
			organizers,
			self:createLink(
				args['organizer' .. index],
				args['organizer' .. index .. '-name'],
				args['organizer' .. index .. '-link'],
				args['organizerref' .. index])
		)
		index = index + 1
	end

	return organizers
end

function League:_cleanDate(date)
	if self:_isUnknownDate(date) then
		return nil
	end
	return ReferenceCleaner.clean(date)
end

function League:_isUnknownDate(date)
	return date == nil or string.lower(date) == 'tba' or string.lower(date) == 'tbd'
end

function League:_isChronologySet(previous, next)
	-- We only need to check the first of these params, since it makes no sense
	-- to set next2 and not next, etc.
	return not (String.isEmpty(previous) and String.isEmpty(next))
end

-- Given the format `pagename|displayname`, returns pagename or the parameter, otherwise
function League:_getPageNameFromChronology(item)
	if item == nil then
		return ''
	end

	return mw.text.split(item, '|')[1]
end

-- Given a series, query its abbreviation if abbreviation is not set manually
function League:_fetchAbbreviation()
	if not String.isEmpty(self.args.abbreviation) then
		return self.args.abbreviation
	elseif String.isEmpty(self.args.series) then
		return nil
	end

	local series = string.gsub(mw.ext.TeamLiquidIntegration.resolve_redirect(self.args.series), ' ', '_')
	local seriesData = mw.ext.LiquipediaDB.lpdb('series', {
			conditions = '[[pagename::' .. series .. ']] AND [[abbreviation::!]]',
			query = 'abbreviation',
			limit = 1
		})
	if type(seriesData) == 'table' and seriesData[1] then
		return seriesData[1].abbreviation
	end
end

return League
