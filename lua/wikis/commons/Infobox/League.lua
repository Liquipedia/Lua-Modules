---
-- @Liquipedia
-- page=Module:Infobox/League
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local BasicInfobox = Lua.import('Module:Infobox/Basic')
local Class = Lua.import('Module:Class')
local CountryCategory = Lua.import('Module:Infobox/Extension/CountryCategory')
local DateExt = Lua.import('Module:Date/Ext')
local Game = Lua.import('Module:Game')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local InfoboxPrizePool = Lua.import('Module:Infobox/Extension/PrizePool')
local Json = Lua.import('Module:Json')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Links = Lua.import('Module:Links')
local Locale = Lua.import('Module:Locale')
local Logic = Lua.import('Module:Logic')
local MetadataGenerator = Lua.import('Module:MetadataGenerator')
local Namespace = Lua.import('Module:Namespace')
local Page = Lua.import('Module:Page')
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TextSanitizer = Lua.import('Module:TextSanitizer')
local Tier = Lua.import('Module:Tier/Custom')
local TournamentService = Lua.import('Module:Tournament')
local Variables = Lua.import('Module:Variables')

local INVALID_TIER_WARNING = '${tierString} is not a known Liquipedia ${tierMode}'

local Widgets = Lua.import('Module:Widget/All')
local Accommodation = Widgets.Accommodation
local Builder = Widgets.Builder
local Cell = Widgets.Cell
local Center = Widgets.Center
local Chronology = Widgets.Chronology
local Customizable = Widgets.Customizable
local Header = Widgets.Header
local Location = Widgets.Location
local Organizers = Widgets.Organizers
local Title = Widgets.Title
local Venue = Widgets.Venue

---@class InfoboxLeague: BasicInfobox
local League = Class.new(BasicInfobox)

---@param frame Frame
---@return string
function League.run(frame)
	local league = League(frame)
	return league:createInfobox()
end

---@return Html
function League:createInfobox()
	local args = self.args
	self:_parseArgs()

	self:_definePageVariables(args)

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = 'League Information'},
		Cell{
			name = 'Series',
			children = {
				self:createSeriesDisplay({
					displayManualIcons = Logic.readBool(args.display_series_icon_from_manual_input),
					series = args.series,
					abbreviation = args.abbreviation,
					icon = args.icon,
					iconDark = args.icondark or args.icondarkmode,
				}, self.iconDisplay),
				self:createSeriesDisplay{
					series = args.series2,
					abbreviation = args.abbreviation2,
				},
			}
		},
		Customizable{
			id = 'organizers',
			children = {Organizers{args = args}},
		},
		Customizable{
			id = 'sponsors',
			children = {
				Cell{name = 'Sponsor(s)', children = self:getAllArgsForBase(args, 'sponsor')},
			}
		},
		Customizable{
			id = 'gamesettings',
			children = {
				Cell{name = 'Server', children = {args.server}}
			}
		},
		Customizable{id = 'type', children = {
				Builder{
					builder = function()
						local value = tostring(args.type):lower()
						if self:shouldStore(args) then
							if value == 'offline' then
								self:categories('Offline Tournaments')
							elseif value == 'online' then
								self:categories('Online Tournaments')
							elseif value:match('online') and value:match('offline') then
								self:categories('Online/Offline Tournaments')
							else
								self:categories('Unknown Type Tournaments')
							end
						end

						if not String.isEmpty(args.type) then
							return {
								Cell{
									name = 'Type',
									children = {
										mw.language.getContentLanguage():ucfirst(args.type)
									}
								}
							}
						end
					end
				}
			}
		},
		Location{args = args},
		Venue{args = args},
		Cell{name = 'Format', children = {args.format}},
		Customizable{id = 'prizepool', children = {
				Cell{
					name = 'Prize Pool',
					children = {self.prizepoolDisplay},
				},
			},
		},
		Customizable{id = 'dates', children = {
				Cell{name = 'Date', children = {args.date}},
				Cell{name = 'Start Date', children = {args.sdate}},
				Cell{name = 'End Date', children = {args.edate}},
			},
		},
		Customizable{id = 'custom', children = {}},
		Customizable{id = 'liquipediatier', children = {
				Cell{
					name = 'Liquipedia Tier',
					children = {self:createLiquipediaTierDisplay(args)},
					classes = {self:liquipediaTierHighlighted(args) and 'valvepremier-highlighted' or ''},
				},
			},
		},
		Widgets.Links{links = self.links},
		Customizable{id = 'customcontent', children = {}},
		Center{children = {args.footnotes}},
		Customizable{id = 'chronology', children = {
			Chronology{args = args, showTitle = true},
		}},
		Accommodation{
			args = args,
			startDate = self.data.startDate,
			endDate = self.data.endDate,
			name = self.data.name,
		},
	}

	self.name = TextSanitizer.stripHTML(self.name)

	self:bottom(self:createBottomContent())

	if self:shouldStore(args) then
		self:_setLpdbData(args, self.links)
		self:categories(unpack(self:_getCategories(args)))
		self:_setSeoTags(args)
	end

	return mw.html.create()
		:node(self:build(widgets, 'Tournament'))
		:node(Logic.readBool(args.autointro) and ('<br>' .. self:seoText(args)) or nil)
end

function League:_parseArgs()
	local args = self.args

	args.abbreviation = self:_fetchAbbreviation()

	-- Split venue from legacy format to new format.
	-- Legacy format is a wiki-code string that can include an external link
	-- New format has |venue=, |venuename= and |venuelink= as different parameters.
	-- This should be removed once there's been a bot run to change this.
	if not args.venuename and args.venue and args.venue:sub(1, 2) == '[[' then
		-- Remove [[]] and split on `|`
		local splitVenue = mw.text.split(args.venue:gsub('%[%[', ''):gsub('%]%]', ''), '|')
		args.venue = splitVenue[1]
		args.venuename = splitVenue[2]
	elseif not args.venuelink and args.venue and args.venue:sub(1, 1) == '[' then
		-- Remove [] and split on space
		local splitVenue = mw.text.split(args.venue:gsub('%[', ''):gsub('%]', ''), ' ')
		args.venuelink = splitVenue[1]
		table.remove(splitVenue, 1)
		args.venue = table.concat(splitVenue, ' ')
	end

	local data = {
		name = TextSanitizer.stripHTML(args.name),
		shortName = TextSanitizer.stripHTML(args.shortname or args.abbreviation),
		tickerName = TextSanitizer.stripHTML(args.tickername),
		series = mw.ext.TeamLiquidIntegration.resolve_redirect(args.series or ''),
		--might be set before infobox
		status = args.status or Variables.varDefault('tournament_status'),
		game = Game.toIdentifier{game = args.game},
		-- If no parent is available, set pagename instead to ease querying
		parent = (args.parent or mw.title.getCurrentTitle().prefixedText):gsub(' ', '_'),
		startDate = ReferenceCleaner.cleanDateIfKnown{date = args.sdate}
			or ReferenceCleaner.cleanDateIfKnown{date = args.date},
		endDate = ReferenceCleaner.cleanDateIfKnown{date = args.edate}
			or ReferenceCleaner.cleanDateIfKnown{date = args.date},
		mode = args.mode,
		patch = args.patch,
		endPatch = args.endpatch or args.epatch or args.patch,
		publishertier = Logic.readBool(args.highlighted),
	}

	data.liquipediatier, data.liquipediatiertype =
		Tier.toValue(args.liquipediatier, args.liquipediatiertype)

	self.data = data

	self.prizepoolDisplay, self.data.prizepoolUsd, self.data.localCurrency = self:_parsePrizePool(args, data.endDate)

	data.icon, data.iconDark, self.iconDisplay = self:getIcons{
		displayManualIcons = Logic.readBool(args.display_series_icon_from_manual_input),
		series = args.series,
		abbreviation = args.abbreviation,
		icon = args.icon,
		iconDark = args.icondark or args.icondarkmode,
	}

	self.links = Links.transform(args)

	self:customParseArguments(args)
end

---@param args table
---@param endDate string?
---@return number|string?, number?, string?
function League:_parsePrizePool(args, endDate)
	if String.isEmpty(args.prizepool) and String.isEmpty(args.prizepoolusd) then
		return
	end

	--need to get the display here since it sets variables we want/need to get the clean values
	--overwritable since sometimes display is supposed to look a bit different
	return self:displayPrizePool(args, endDate),
		tonumber(Variables.varDefault('tournament_prizepoolusd')) or 0,
		Variables.varDefault('tournament_currency', args.localcurrency)
end

---@param args table
---@param endDate string?
---@return number|string?
function League:displayPrizePool(args, endDate)
	return InfoboxPrizePool.display{
		prizepool = args.prizepool,
		prizepoolusd = args.prizepoolusd,
		currency = args.localcurrency,
		rate = args.currency_rate,
		date = Logic.emptyOr(args.currency_date, endDate),
		setvariables = args.setvariables,
		displayRoundPrecision = args.currencyDispPrecision,
		varRoundPrecision = args.currencyVarPrecision
	}
end

---@param args table
function League:customParseArguments(args)
end

function League:_tournamentPhaseCategory()
	local phaseMapping = {
		ONGOING = 'Live Tournaments',
		UPCOMING = 'Upcoming Tournaments',
		FINISHED = 'Finished Tournaments'
	}

	local tournamentPhase = TournamentService.tournamentFromRecord(self.lpdbData).phase
	return phaseMapping[tournamentPhase]
end

---@param args table
---@return string[]
function League:_getCategories(args)
	return Array.extend(
		{'Tournaments'},
		Logic.isEmpty(args.country) and 'Tournaments without location' or nil,
		self:addParticipantTypeCategory(args),
		self:addTierCategories(args),
		self:_tournamentPhaseCategory(),
		CountryCategory.run(args, 'Tournaments'),
		self:getWikiCategories(args)
	)
end

---@param args table
---@return string[]
function League:addParticipantTypeCategory(args)
	local categories = {}
	if not String.isEmpty(args.team_number) then
		table.insert(categories, 'Team Tournaments')
	end
	if String.isNotEmpty(args.player_number) or String.isNotEmpty(args.individual) then
		table.insert(categories, 'Individual Tournaments')
	end

	return categories
end

---@param args table
---@return string[]
function League:addTierCategories(args)
	local categories = {}
	local tier = args.liquipediatier
	local tierType = args.liquipediatiertype

	local tierCategory, tierTypeCategory = Tier.toCategory(tier, tierType)
	local isValidTierTuple = Tier.isValid(tier, tierType)
	table.insert(categories, tierCategory)
	table.insert(categories, tierTypeCategory)

	if not isValidTierTuple and not tierCategory and Logic.isNotEmpty(tier) then
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

--- Allows for overriding this functionality
---@param args table
---@return boolean
function League:shouldStore(args)
	return Namespace.isMain() and
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
end

--- Allows for overriding this functionality
---@param args table
function League:defineCustomPageVariables(args)
end

--- Allows for overriding this functionality
---@param lpdbData table
---@param args table
---@return table
function League:addToLpdb(lpdbData, args)
	return lpdbData
end

--- Allows for overriding this functionality
---@param args table
---@return string
function League:seoText(args)
	return MetadataGenerator.tournament(args)
end

--- Allows for overriding this functionality
---@param args table
---@return boolean
function League:liquipediaTierHighlighted(args)
	return HighlightConditions.tournament(self.data)
end

--- Allows for overriding this functionality
---@param args table
---@return string
function League:appendLiquipediatierDisplay(args)
	return ''
end

---@param args table
---@return string?
function League:createLiquipediaTierDisplay(args)
	local tierDisplay = Tier.display(args.liquipediatier, args.liquipediatiertype, {link = true})

	if String.isEmpty(tierDisplay) then
		return
	end

	return tierDisplay .. self:appendLiquipediatierDisplay(args)
end

---@param args table
function League:_definePageVariables(args)
	Variables.varDefine('tournament_name', self.data.name)
	Variables.varDefine('tournament_shortname', self.data.shortName)
	Variables.varDefine('tournament_tickername', self.data.tickerName)
	Variables.varDefine('tournament_series', self.data.series)

	Variables.varDefine('tournament_icon', self.data.icon)
	Variables.varDefine('tournament_icondark', self.data.iconDark)

	Variables.varDefine('tournament_liquipediatier', self.data.liquipediatier)
	Variables.varDefine('tournament_liquipediatiertype', self.data.liquipediatiertype)
	Variables.varDefine('tournament_publishertier', tostring(self.data.publishertier or ''))

	Variables.varDefine('tournament_type', args.type)
	Variables.varDefine('tournament_mode', self.data.mode)
	Variables.varDefine('tournament_status', self.data.status)

	Variables.varDefine('tournament_region', args.region)
	Variables.varDefine('tournament_country', args.country)
	Variables.varDefine('tournament_location', args.location or args.city)
	Variables.varDefine('tournament_location2', args.location2 or args.city2)
	Variables.varDefine('tournament_venue', args.venue)

	Variables.varDefine('tournament_game', self.data.game)

	Variables.varDefine('tournament_parent', self.data.parent)
	Variables.varDefine('tournament_parentname', args.parentname)
	Variables.varDefine('tournament_subpage', args.subpage)

	Variables.varDefine('tournament_startdate', self.data.startDate)
	Variables.varDefine('tournament_enddate', self.data.endDate)

	Variables.varDefine('tournament_patch', self.data.patch)
	Variables.varDefine('tournament_endpatch ', self.data.endPatch)

	Variables.varDefine('tournament_currency', self.data.localCurrency or '')

	Variables.varDefine('tournament_summary', self:seoText(args))

	self:defineCustomPageVariables(args)
end

---@param args table
---@param links table
function League:_setLpdbData(args, links)
	local lpdbData = {
		name = self.name,
		tickername = self.data.tickerName,
		shortname = self.data.shortName,
		banner = args.image,
		bannerdark = args.imagedark or args.imagedarkmode,
		icon = self.data.icon,
		icondark = self.data.iconDark,
		series = mw.ext.TeamLiquidIntegration.resolve_redirect(args.series or ''),
		seriespage = Page.pageifyLink(args.series),
		serieslist = {
			Page.pageifyLink(args.series),
			Page.pageifyLink(args.series2),
		},
		previous = self:_getPageNameFromChronology(args.previous),
		previous2 = self:_getPageNameFromChronology(args.previous2),
		next = self:_getPageNameFromChronology(args.next),
		next2 = self:_getPageNameFromChronology(args.next2),
		game = self.data.game,
		mode = self.data.mode,
		patch = self.data.patch,
		endpatch = self.data.endPatch,
		type = args.type,
		organizers = Table.mapValues(
			League:_getNamedTableofAllArgsForBase(args, 'organizer'),
			mw.ext.TeamLiquidIntegration.resolve_redirect
		),
		startdate = self.data.startDate or self.data.endDate or DateExt.defaultDate,
		enddate = self.data.endDate or DateExt.defaultDate,
		sortdate = self.data.endDate or DateExt.defaultDate,
		location = mw.text.decode(Locale.formatLocation({city = args.city or args.location, country = args.country})),
		location2 = mw.text.decode(Locale.formatLocation({city = args.city2 or args.location2, country = args.country2})),
		venue = args.venue,
		locations = Locale.formatLocations(args),
		prizepool = self.data.prizepoolUsd,
		liquipediatier = self.data.liquipediatier,
		liquipediatiertype = self.data.liquipediatiertype,
		publishertier = tostring(self.data.publishertier or ''),
		participantsnumber = tonumber(args.participants_number)
			or tonumber(args.team_number)
			or tonumber(args.player_number)
			or -1,
		status = self.data.status,
		format = TextSanitizer.stripHTML(args.format),
		sponsors = League:_getNamedTableofAllArgsForBase(args, 'sponsor'),
		links = Links.makeFullLinksForTableItems(links or {}),
		summary = self:seoText(args),
		extradata = {
			series2 = args.series2 and mw.ext.TeamLiquidIntegration.resolve_redirect(args.series2) or nil,
		},
	}

	lpdbData = self:addToLpdb(lpdbData, args)
	mw.ext.LiquipediaDB.lpdb_tournament('tournament_' .. self.name, Json.stringifySubTables(lpdbData))
	self.lpdbData = lpdbData
end

---@param args table
function League:_setSeoTags(args)
	local desc = self:seoText(args)
	if desc then
		mw.ext.SearchEngineOptimization.metadescl(desc)
	end
end

---@param args table
---@param base string
---@return table
function League:_getNamedTableofAllArgsForBase(args, base)
	local basedArgs = self:getAllArgsForBase(args, base)
	local namedArgs = {}
	for key, item in pairs(basedArgs) do
		namedArgs[base .. key] = item
	end
	return namedArgs
end

---@param seriesArgs {displayManualIcons:boolean, series:string?, abbreviation:string?, icon:string?, iconDark:string?}
---@param iconDisplay string?
---@return string?
function League:createSeriesDisplay(seriesArgs, iconDisplay)
	if String.isEmpty(seriesArgs.series) then
		return nil
	end

	iconDisplay = iconDisplay or self:_createSeriesIcon(seriesArgs)

	if String.isNotEmpty(iconDisplay) then
		iconDisplay = iconDisplay .. ' '
	end

	local abbreviation = Logic.emptyOr(seriesArgs.abbreviation, seriesArgs.series)
	local pageDisplay = Page.makeInternalLink({onlyIfExists = true}, abbreviation, seriesArgs.series)
		or abbreviation

	return iconDisplay .. pageDisplay
end

---@param iconArgs {displayManualIcons:boolean, series:string?, abbreviation:string?, icon:string?, iconDark:string?}
---@return string?
---@return string?
---@return string?
function League:getIcons(iconArgs)
	local display = self:_createSeriesIcon(iconArgs)

	if not display then
		return iconArgs.icon, iconArgs.iconDark, nil
	end

	local icon, iconDark, trackingCategory = LeagueIcon.getIconFromTemplate{
		icon = iconArgs.icon,
		iconDark = iconArgs.iconDark,
		stringOfExpandedTemplate = display
	}

	if String.isNotEmpty(trackingCategory) then
		table.insert(self.warnings, 'Missing icon while icondark is set.')
	end

	return icon, iconDark, display
end

---@param iconArgs {displayManualIcons:boolean, series:string?, abbreviation:string?, icon:string?, iconDark:string?}
---@return string?
function League:_createSeriesIcon(iconArgs)
	if String.isEmpty(iconArgs.series) then
		return ''
	end
	local series = iconArgs.series
	---@cast series -nil

	local output = LeagueIcon.display{
		icon = iconArgs.displayManualIcons and iconArgs.icon or nil,
		iconDark = iconArgs.displayManualIcons and iconArgs.iconDark or nil,
		series = series,
		abbreviation = iconArgs.abbreviation,
		date = self.data.endDate,
		options = {noLink = not Page.exists(series)}
	}

	return output == LeagueIcon.display{} and '' or output
end

--- used in brawlstars, chess, counterstrike customs
---@param id string?
---@param name string?
---@param link string?
---@param desc string?
---@return string?
function League:createLink(id, name, link, desc)
	if String.isEmpty(id) then
		return nil
	end
	---@cast id -nil

	local output

	if Page.exists(id) or id:find('^[Ww]ikipedia:') then
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

-- Given the format `pagename|displayname`, returns pagename or the parameter, otherwise
---@param item string?
---@return string?
function League:_getPageNameFromChronology(item)
	if item == nil then return end

	return mw.ext.TeamLiquidIntegration.resolve_redirect(mw.text.split(item, '|')[1])
end

-- Given a series, query its abbreviation if abbreviation is not set manually
---@return string?
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
