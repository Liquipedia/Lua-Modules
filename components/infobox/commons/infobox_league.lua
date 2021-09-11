---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/League
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local BasicInfobox = require('Module:Infobox/Basic')
local Class = require('Module:Class')
local Template = require('Module:Template')
local Table = require('Module:Table')
local Namespace = require('Module:Namespace')
local String = require('Module:String')
local Links = require('Module:Links')
local Flags = require('Module:Flags')
local Localisation = require('Module:Localisation')
local Variables = require('Module:Variables')
local Locale = require('Module:Locale')
local Page = require('Module:Page')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder
local Chronology = Widgets.Chronology

local League = Class.new(BasicInfobox)

function League.run(frame)
	local league = League(frame)
	return league:createInfobox()
end

function League:createInfobox()
	local args = self.args
	local frame = mw.getCurrentFrame()
	local links

	-- set Variables here already so they are available in functions
	-- we call from here on, e.g. createPrizepool
	self:_definePageVariables(args)

	local widgets = {
		Header{name = args.name, image = args.image, imageDark = args.imagedarkmode},
		Center{content = {args.caption}},
		Title{name = 'League Information'},
		Cell{
			name = 'Series',
			content = {
				self:_createSeries(frame, args.series, args.abbreviation),
				self:_createSeries(frame, args.series2, args.abbreviation2)
			}
		},
		Cell{name = 'Organizer(s)', content = self:_createOrganizers(args)},
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
		Builder{
			builder = function()
				local value = tostring(args.type):lower()
				if value == 'offline' then
					self.infobox:categories('Offline Tournaments')
				elseif value == 'online' then
					self.infobox:categories('Online Tournaments')
				else
					self.infobox:categories('Unknown Type Tournaments')
				end

				if not String.isEmpty(args.type) then
					return {
						Cell{
							name = 'Type',
							content = {
								args.type:sub(1,1):upper()..args.type:sub(2)
							}
						}
					}
				end
			end
		},
		Cell{
			name = 'Location',
			content = {
				self:_createLocation({
					region = args.region,
					country = args.country,
					country2 = args.country2,
					location = args.city or args.location,
					location2 = args.city2 or args.location2
				})
			}
		},
		Cell{name = 'Venue', content = {args.venue}},
		Cell{name = 'Format', content = {args.format}},
		Customizable{id = 'prizepool', children = {}},
		Cell{name = 'Date', content = {args.date}},
		Cell{name = 'Start Date', content = {args.sdate}},
		Cell{name = 'End Date', content = {args.edate}},
		Customizable{id = 'custom', children = {}},
		Customizable{id = 'liquipediatier', children = {}},
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

	self.infobox:bottom(self:createBottomContent())

	local builtInfobox = self.infobox:widgetInjector(self:createWidgetInjector()):build(widgets)

	if self:shouldStore(args) then
		self.infobox:categories('Tournaments')
		if not String.isEmpty(args.team_number) then
			self.infobox:categories('Team Tournaments')
		end
		self.infobox:categories(unpack(self:getWikiCategories(args)))
		self:_setLpdbData(args, links)
	end

	return builtInfobox
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

function League:_definePageVariables(args)
	Variables.varDefine('tournament_name', args.name)
	Variables.varDefine('tournament_shortname', args.shortname or args.abbreviation)
	Variables.varDefine('tournament_tickername', args.tickername)
	Variables.varDefine('tournament_icon', args.icon)
	Variables.varDefine('tournament_icon_darkmode', args.icondarkmode)
	Variables.varDefine('tournament_series', mw.ext.TeamLiquidIntegration.resolve_redirect(args.series or ''))

	Variables.varDefine('tournament_liquipediatier', args.liquipediatier)
	Variables.varDefine('tournament_liquipediatiertype', args.liquipediatiertype)

	Variables.varDefine('tournament_type', args.type)
	Variables.varDefine('tournament_status', args.status)

	Variables.varDefine('tournament_region', args.region)
	Variables.varDefine('tournament_country', args.country)
	Variables.varDefine('tournament_location', args.location or args.city)
	Variables.varDefine('tournament_location2', args.location2 or args.city2)
	Variables.varDefine('tournament_venue', args.venue)

	Variables.varDefine('tournament_game', string.lower(args.game or ''))

	Variables.varDefine('tournament_parent', args.parent)
	Variables.varDefine('tournament_parentname', args.parentname)
	Variables.varDefine('tournament_subpage', args.subpage)

	Variables.varDefine('tournament_startdate', self:_cleanDate(args.sdate))
	Variables.varDefine('tournament_enddate',
	self:_cleanDate(args.edate) or self:_cleanDate(args.date))

	self:defineCustomPageVariables(args)
end

function League:_setLpdbData(args, links)
	local lpdbData = {
		name = self.name,
		tickername = args.tickername,
		shortname = args.shortname or args.abbreviation,
		banner = args.image,
		bannerdark = args.imagedarkmode,
		icon = args.icon,
		icondark = args.icondarkmode,
		series = mw.ext.TeamLiquidIntegration.resolve_redirect(args.series or ''),
		previous = args.previous,
		previous2 = args.previous2,
		next = args.next,
		next2 = args.next2,
		game = string.lower(args.game or ''),
		patch = args.patch,
		endpatch = args.endpatch or args.epatch,
		type = args.type,
		organizers = mw.ext.LiquipediaDB.lpdb_create_json({
			organizer1 = args.organizer or args.organizer1,
			organizer2 = args.organizer2,
			organizer3 = args.organizer3,
			organizer4 = args.organizer4,
			organizer5 = args.organizer5,
		}),
		startdate = Variables.varDefaultMulti('tournament_startdate', 'tournament_enddate', '1970-01-01'),
		enddate = Variables.varDefault('tournament_enddate', '1970-01-01'),
		sortdate = Variables.varDefault('tournament_enddate', '1970-01-01'),
		location = Locale.formatLocation({city = args.city or args.location, country = args.country}),
		location2 = Locale.formatLocation({city = args.city2 or args.location2, country = args.country2}),
		venue = args.venue,
		prizepool = Variables.varDefault('tournament_prizepoolusd', 0),
		liquipediatier = Variables.varDefault('tournament_liquipediatier'),
		liquipediatiertype = Variables.varDefault('tournament_liquipediatiertype'),
		status = args.status,
		format = args.format,
		sponsors = mw.ext.LiquipediaDB.lpdb_create_json({
			sponsor1 = args.sponsor or args.sponsor1,
			sponsor2 = args.sponsor2,
			sponsor3 = args.sponsor3,
			sponsor4 = args.sponsor4,
			sponsor5 = args.sponsor5,
		}),
		links = mw.ext.LiquipediaDB.lpdb_create_json(
			Links.makeFullLinksForTableItems(links or {})
		),
	}

	lpdbData = self:addToLpdb(lpdbData, args)
	lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.extradata or {})
	mw.ext.LiquipediaDB.lpdb_tournament('tournament_' .. self.name, lpdbData)
end

---
-- Format:
-- {
--     region: Region or continent
--     country: the country
--     location: the city or place
-- }
function League:_createLocation(details)
	if Table.isEmpty(details) then
		return nil
	end

	if String.isEmpty(details.country) then
		return Template.safeExpand(mw.getCurrentFrame(), 'Abbr/TBD')
	end

	local content
	local nationality = Localisation.getLocalisation({displayNoError = true}, details.country)

	if String.isEmpty(nationality) then
			content = '[[Category:Unrecognised Country|' .. details.country .. ']]'
	else
		local countryName = Localisation.getCountryName(details.country)
		local displayText = details.location or countryName
		if displayText == '' then
			displayText = details.country
		end

		content = Flags._Flag(details.country) .. '&nbsp;' ..
			displayText .. '[[Category:' .. nationality .. ' Tournaments]]'
	end

	if not String.isEmpty(details.country2) then
		content = content .. '<br>'
		local nationality2 = Localisation.getLocalisation({displayNoError = true}, details.country2)

		if String.isEmpty(nationality2) then
			content = content .. '[[Category:Unrecognised Country|' .. details.country2 .. ']]'
		else
			local countryName2 = Localisation.getCountryName(details.country2)

			local displayText = details.location2 or countryName2
			if displayText == '' then
				displayText = details.country2
			end

			content = content .. Flags._Flag(details.country2) .. '&nbsp;' ..
				displayText .. '[[Category:' .. nationality2 .. ' Tournaments]]'
		end
	end

	return content
end

function League:_createSeries(frame, series, abbreviation)
	if String.isEmpty(series) then
		return nil
	end

	local output = ''

	if Page.exists('Template:LeagueIconSmall/' .. series:lower()) then
		output = Template.safeExpand(frame, 'LeagueIconSmall/' .. series:lower()) .. ' '
	end

	if not Page.exists(series) then
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

function League:_createOrganizer(organizer, name, link, reference)
	if String.isEmpty(organizer) then
		return nil
	end

	local output

	if Page.exists(organizer) then
		output = '[[' .. organizer .. '|'
		if String.isEmpty(name) then
			output = output .. organizer .. ']]'
		else
			output = output .. name .. ']]'
		end

	elseif not String.isEmpty(link) then
		if String.isEmpty(name) then
			output = '[' .. link .. ' ' .. organizer .. ']'
		else
			output = '[' .. link .. ' ' .. name .. ']'

		end
	elseif String.isEmpty(name) then
		output = organizer
	else
		output = name
	end

	if not String.isEmpty(reference) then
		output = output .. reference
	end

	return output
end

function League:_createOrganizers(args)
	local organizers = {
		League:_createOrganizer(
			args.organizer, args['organizer-name'], args['organizer-link'], args.organizerref),
	}

	local index = 2

	while not String.isEmpty(args['organizer' .. index]) do
		table.insert(
			organizers,
			League:_createOrganizer(
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

	date = date:gsub('-??', '-01')
	date = date:gsub('-XX', '-01')
	return date
end

function League:_isUnknownDate(date)
	return date == nil or string.lower(date) == 'tba' or string.lower(date) == 'tbd'
end

function League:_isChronologySet(previous, next)
	-- We only need to check the first of these params, since it makes no sense
	-- to set next2 and not next, etc.
	return not (String.isEmpty(previous) and String.isEmpty(next))
end

return League
