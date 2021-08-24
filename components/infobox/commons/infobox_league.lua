---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/League
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local BasicInfobox = require('Module:Infobox/Basic')
local Cell = require('Module:Infobox/Cell')
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

local League = Class.new(BasicInfobox)

function League.run(frame)
	local league = League(frame)
	return league:createInfobox()
end

function League:createInfobox()
	local args = self.args
	self.infobox:name(args.name)
				:image(args.image, args.default)
				:centeredCell(args.caption)
				:header('League Information', true)
				:fcell(Cell:new('Series')
					:options({})
					:content(
						self:_createSeries(mw.getCurrentFrame(), args.series, args.abbrevation),
						self:_createSeries(mw.getCurrentFrame(), args.series2, args.abbrevation2)
					)
					:make()
				)
				:fcell(Cell:new('Organizer')
					:options({})
					:content(
						unpack(self:_createOrganizers(args))
					)
					:make()
				)
				:fcell(Cell:new('Sponsor(s)')
					:options({})
					:content(
						args.sponsor or args.sponsor1,
						args.sponsor2,
						args.sponsor3,
						args.sponsor4,
						args.sponsor5
					)
					:make()
				)
				:cell('Server', args.server)
				:fcell(Cell:new('Type')
					:options({})
					:content(args.type:sub(1,1):upper()..args.type:sub(2))
					:categories(
						function(_, ...)
							local value = select(1, ...)
							value = tostring(value):lower()
							if value == 'offline' then
								self.infobox:categories('Offline Tournaments')
							elseif value == 'online' then
								self.infobox:categories('Online Tournaments')
							else
								self.infobox:categories('Unknown Type Tournaments')
							end
						end
					)
					:make()
				)
				:cell('Location', self:_createLocation({
					region = args.region,
					country = args.country,
					country2 = args.country2,
					location = args.city or args.location,
					location2 = args.city or args.location2
				}))
				:cell('Venue', args.venue)
				:cell('Format', args.format)
				:fcell(self:createPrizepool(args):make())
				:fcell(Cell:new('Date')
					:options({})
					:content(args.date)
					:make()
				)
				:fcell(Cell:new('Start Date')
					:options({})
					:content(args.sdate)
					:make()
				)
				:fcell(Cell:new('End Date')
					:options({})
					:content(args.edate)
					:make()
				)
				:fcell(self:createTier(args):make())
	self:addCustomCells(self.infobox, args)

	local links = Links.transform(args)

	self.infobox:header('Links', not Table.isEmpty(links))
				:links(links)
	self:addCustomContent(self.infobox, args)
	self.infobox:centeredCell(args.footnotes)
				:header('Chronology', self:_isChronologySet(args.previous, args.next))
				:chronology({
					previous = args.previous,
					next = args.next,
					previous2 = args.previous2,
					next2 = args.next2,
				})
				:bottom(self:createBottomContent(self.infobox))

	self:_definePageVariables(args)

	if Namespace.isMain() then
		self.infobox:categories('Tournaments')
		if not String.isEmpty(args.team_number) then
			self.infobox:categories('Team Tournaments')
		end
		self:_setLpdbData(args)
	end

	return self.infobox:build()
end

--- Allows for overriding this functionality
function League:createTier(args)
	error('You need to define a tier function for this wiki!')
end

--- Allows for overriding this functionality
function League:createPrizepool(args)
	error('You need to define a prizepool function for this wiki!')
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
	Variables.varDefine('tournament_shortname', args.shortname)
	Variables.varDefine('tournament_tickername', args.tickername)
	Variables.varDefine('tournament_icon', args.icon)
	Variables.varDefine('tournament_series', args.series)

	Variables.varDefine('tournament_liquipediatier', args.liquipediatier)
	Variables.varDefine('tournament_liquipediatiertype', args.liquipediatiertype)

	Variables.varDefine('tournament_type', args.type)
	Variables.varDefine('tournament_status', args.status)

	Variables.varDefine('tournament_region', args.region)
	Variables.varDefine('tournament_country', args.country)
	Variables.varDefine('tournament_location', args.location or args.city)
	Variables.varDefine('tournament_location2', args.location2 or args.city2)
	Variables.varDefine('tournament_venue', args.venue)

	Variables.varDefine('tournament_game', args.game)

	Variables.varDefine('tournament_parent', args.parent)
	Variables.varDefine('tournament_parentname', args.parentname)
	Variables.varDefine('tournament_subpage', args.subpage)

	Variables.varDefine('tournament_startdate', self:_cleanDate(args.sdate))
	Variables.varDefine('tournament_enddate',
	self:_cleanDate(args.edate) or self:_cleanDate(args.date))

	self:defineCustomPageVariables(args)
end

function League:_setLpdbData(args)
	local lpdbData = {
		name = self.name,
		tickername = args.tickername,
		shortname = args.shortname,
		banner = args.image,
		icon = args.icon,
		series = args.series,
		previous = args.previous,
		previous2 = args.previous2,
		next = args.next,
		next2 = args.next2,
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
		startdate = Variables.varDefault('tournament_startdate', '1970-01-01'),
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
		links = mw.ext.LiquipediaDB.lpdb_create_json({
			discord = Links.makeFullLink('discord', args.discord),
			facebook = Links.makeFullLink('facebook', args.facebook),
			instagram = Links.makeFullLink('instagram', args.instagram),
			twitch = Links.makeFullLink('twitch', args.twitch),
			twitter = Links.makeFullLink('twitter', args.twitter),
			website = Links.makeFullLink('website', args.website),
			weibo = Links.makeFullLink('weibo', args.weibo),
			vk = Links.makeFullLink('vk', args.vk),
			youtube = Links.makeFullLink('youtube', args.youtube),
		}),
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
		content = Flags._Flag(details.country) .. '&nbsp;' ..
			'[[:Category:' .. nationality .. ' Tournaments|' ..
			(details.location or countryName) .. ']]' ..
			'[[Category:' .. nationality .. ' Tournaments]]'
	end

	if not String.isEmpty(details.country2) then
		content = content .. '<br>'
		local nationality2 = Localisation.getLocalisation({displayNoError = true}, details.country2)

		if String.isEmpty(nationality2) then
			content = content .. '[[Category:Unrecognised Country|' .. details.country2 .. ']]'
		else
			local countryName2 = Localisation.getCountryName(details.country2)
			content = content .. Flags._Flag(details.country2) .. '&nbsp;' ..
				'[[:Category:' .. nationality2 .. ' Tournaments|' ..
				(details.location2 or countryName2) .. ']]' ..
				'[[Category:' .. nationality2 .. ' Tournaments]]'
		end
	end

	return content
end

function League:_createSeries(frame, series, abbreviation)
	if String.isEmpty(series) then
		return nil
	end

	local output = ''

	if self:_exists('Template:LeagueIconSmall/' .. series:lower()) then
		output = Template.safeExpand(frame, 'LeagueIconSmall/' .. series:lower()) .. ' '
	end

	if not self:_exists(series) then
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

	if self:_exists(organizer) then
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
			args['organizer-name' .. index],
			args['organizer-link' .. index],
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

function League:_exists(page)
	local existingPage = mw.title.new(page)

	-- In some cases we might have gotten an external link,
	-- which will mean `existingPage` will equal nil
	if existingPage == nil then
		return false
	end

	return existingPage.exists
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
