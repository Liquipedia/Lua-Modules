---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Person
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local BasicInfobox = require('Module:Infobox/Basic')
local Template = require('Module:Template')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Namespace = require('Module:Namespace')
local Links = require('Module:Links')
local Localisation = require('Module:Localisation').getLocalisation
local Flags = require('Module:Flags')
local String = require('Module:StringUtils')
--local GetBirthAndDeath = require('Module:???')._get

--the following 3 lines as a temp workaround until the Birth&Death stuff is implemented:
local function GetBirthAndDeath()
	return '', nil, nil, nil
end

local Person = Class.new(BasicInfobox)

local Language = mw.language.new('en')
local _LINK_VARIANT = 'player'
local _SHOULD_STORE_DATA

function Person.run(frame)
	local person = Person(frame)
	return person:createInfobox(frame)
end

function Person:createInfobox(frame)
	local infobox = self.infobox
	local args = self.args
	_SHOULD_STORE_DATA = Person:shouldStoreData(args)

	local earnings = self:calculateEarnings(args)
	Variables.varDefine('earnings', earnings)
	if earnings and earnings ~= 0 then
		earnings = '$' .. Language:formatNum(earnings)
	else
		earnings = nil
	end
	local nameDisplay = self:nameDisplay(args)
	local role = self:getRole(args)
	local birthDisplay, deathDisplay, birthday, deathday
		= GetBirthAndDeath(
			args.birth_date,
			args.birth_location,
			args.death_date,
			role.category,
			_SHOULD_STORE_DATA
		)
	local status = self:getStatus(args)

	infobox:name(nameDisplay)
	infobox:image(args.image, args.defaultImage)
	infobox:centeredCell(args.caption)
	infobox:header(self:getInformationType(args) .. ' Information', true)
	infobox:cell('Name', args.name)
	infobox:cell('Romanized Name', args.romanized_name)
	infobox:cell('Birth', birthDisplay)
	infobox:cell('Died', deathDisplay)
	infobox:cell('Status', status.display)
	infobox:cell(role.title or 'Role', role.display)
	infobox:fcell(Cell	:new('Country')
						:content(unpack(self:_createLocations(args, role.category)))
						:make()
			)
			:cell('Region', self:_createRegion(args.region))
			:fcell(Cell	:new('Team')
						:content(
							self:_createTeam(args.team, args.teamlink),
							self:_createTeam(args.team2, args.teamlink2)
						)
						:make()
			)
			:fcell(Cell	:new('Clan')
						:content(
							self:_createTeam(args.clan, args.clanlink),
							self:_createTeam(args.clan2, args.clanlink2)
						)
						:make()
			)
	infobox:cell('Alternate IDs', args.ids or args.alternateids)
	infobox:cell('Nicknames', args.nicknames)
	infobox:cell('Total Earnings', earnings)
	self:addCustomCells(infobox, args)

	local links = Links.transform(args)
	local achievements = self:getAchievements(infobox, args)
	local history = self:getHistory(infobox, args)

	infobox:header('Links', not Table.isEmpty(links))
	infobox:links(links, _LINK_VARIANT)
	infobox:header('Achievements', achievements)
	infobox:centeredCell(achievements)
	infobox:header('History', history)
	infobox:centeredCell(history)
	infobox:centeredCell(args.footnotes)
	self:addCustomContent(infobox, args)
	infobox:bottom(self:createBottomContent(infobox, args))

	if _SHOULD_STORE_DATA then
		args.birthDisplay = birthDisplay
		self:getCategories(infobox, args, role.category, status.store)

		links = Links.makeFullLinksForTableItems(links, _LINK_VARIANT)
		local lpdbData = {
			id = args.id or mw.title.getCurrentTitle().prefixedText,
			alternateid = args.ids,
			name = args.romanized_name or args.name,
			romanizedname = args.romanized_name or args.name,
			localizedname = args.name,
			nationality = args.country or args.nationality,
			nationality2 = args.country2 or args.nationality2,
			nationality3 = args.country3 or args.nationality3,
			birthdate = birthday,
			deathdate = deathday,
			image = args.image,
			region = args.region,
			team = args.teamlink or args.team,
			status = status.store,
			type = role.store,
			earnings = earnings,
			links = links,
			extradata = {},
		}
		lpdbData = self:adjustLPDB(lpdbData, args, role, status)
		lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.extradata)
		lpdbData.links = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.links)
		local storageType = self:getStorageType(args, role, status)

		mw.ext.LiquipediaDB.lpdb_player(storageType .. self.name, lpdbData)
	end

	return infobox:build()
end

--- Allows for overriding this functionality
function Person:getCategories(infobox, args, role, status)
	infobox:categories(role .. 's')
	if not args.teamlink and not args.team then
		infobox:categories('Teamless ' .. role .. 's')
	end
	if args.country2 or args.nationality2 then
		infobox:categories('Dual Citizenship ' .. role .. 's')
	end
	if args.death_date then
		infobox:categories('Deceased ' .. role .. 's')
	end
	if
		args.retired == 'yes' or args.retired == 'true'
		or string.lower(status or '') == 'retired'
		or string.match(args.retired or '', '%d%d%d%d%')--if retired has year set apply the retired category
	then
		infobox:categories('Retired ' .. role .. 's')
	else
		infobox:categories('Active ' .. role .. 's')
	end
	if not args.id then
		infobox:categories('InfoboxIncomplete.')
	end
	if not args.image then
		infobox:categories(role .. 's with no profile picture')
	end
	if not args.birthDisplay then
		infobox:categories(role .. 's with unknown birth date')
	end

	return infobox
end

--- Allows for overriding this functionality
function Person:getStorageType(args, role, status)
	return 'player'
end

--- Allows for overriding this functionality
function Person:getInformationType(args)
	return args.informationType or 'Player'
end

--- Allows for overriding this functionality
function Person:adjustLPDB(lpdbData, args, role, status)
	return lpdbData
end

--- Allows for overriding this functionality
function Person:getRole(args)
	return { display = args.role, store = args.role, category = args.role or 'Player'}
end

--- Allows for overriding this functionality
function Person:getStatus(args)
	return { display = args.status, store = args.status }
end

--- Allows for overriding this functionality
function Person:getHistory(infobox, args)
	return args.history
end

--- Allows for overriding this functionality
--- Decides if we store in LPDB and Vars or not
function Person:shouldStoreData(args)
	return Namespace.isMain()
end

--- Allows for overriding this functionality
--- e.g. to add faction icons to the display for SC2, SC, WC
function Person:nameDisplay(args)
	local team = args.teamlink or args.team
	local icon = mw.ext.TeamTemplate.teamexists(team)
		and mw.ext.TeamTemplate.teamicon(team) or ''
	local name = args.id or mw.title.getCurrentTitle().text

	return icon .. '&nbsp;' .. name
end

--- Allows for overriding this functionality
function Person:getAchievements(infobox, args)
	return args.achievements
end

--- Allows for overriding this functionality
function Person:calculateEarnings(args)
	return 0
end

function Person:_createRegion(region)
	if region == nil or region == '' then
		return ''
	end

	return Template.safeExpand(self.frame, 'Region', {region})
end

function Person:_createLocations(args, role)
	local countryDisplayData = {}
	local country = args.country or args.country1 or args.nationality or args.nationality1
	if country == nil or country == '' then
		return countryDisplayData
	end

	countryDisplayData[1] = Person:_createLocation(country, args.location, role)

	local index = 2
	country = args['country2'] or args['nationality2']
	while(not String.isEmpty(country)) do
		countryDisplayData[index] = Person:_createLocation(country, args['location' .. index], role)
		index = index + 1
		country = args['country' .. index] or args['nationality' .. index]
	end

	return countryDisplayData
end

function Person:_createLocation(country, location, role)
	if country == nil or country == '' then
		return nil
	end
	local countryDisplay = Flags._CountryName(country)
	local demonym = Localisation(countryDisplay)

	return Flags._Flag(country) .. '&nbsp;' ..
				'[[:Category:' .. countryDisplay .. '|' .. countryDisplay .. ']]'
				.. '[[Category:' .. demonym .. ' ' .. role .. ']]'
				.. (location ~= nil and (',&nbsp;' .. location) or '')
end

function Person:_createTeam(team, link)
	link = link or team
	if link == nil or link == '' then
		return ''
	end

	if mw.ext.TeamTemplate.teamexists(link) then
		local data = mw.ext.TeamTemplate.raw(link)
		return '[[' .. data.page .. '|' .. data.name .. ']]'
	end

	return '[[' .. link .. '|' .. team .. ']]'
end

return Person
