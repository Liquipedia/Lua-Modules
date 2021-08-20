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
--local GetBirthAndDeath = require('Module:???')._get

--the following 3 lines as a temp workaround until the Birth&Death stuff is implemented:
local function GetBirthAndDeath()
	return '', nil, nil, nil
end

local Player = Class.new(BasicInfobox)

local Language = mw.language.new('en')
local _LINK_VARIANT = 'player'
local shouldStoreData

function Player.run(frame)
	local player = Player(frame)
	return player:createInfobox(frame)
end

function Player:createInfobox(frame)
	local infobox = self.infobox
	local args = self.args
	shouldStoreData = Player:shouldStoreData(args)

	local earnings = self:calculateEarnings(args)
	Variables.varDefine('earnings', earnings)
	if earnings == 0 then
		earnings = nil
	else
		earnings = '$' .. Language:formatNum(earnings)
	end
	local nameDisplay = self:nameDisplay(args)
	local role = self:getRole(args)
	local birthDisplay, deathDisplay, birthday, deathday
		= GetBirthAndDeath(
			args.birth_date,
			args.birth_location,
			args.death_date,
			role.category,
			shouldStoreData
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
	infobox:fcell(Cell :new('Country')
						:options({})
						:content(unpack(self:_createLocations(args, role.category)))
						:make()
			)
			:cell('Region', self:_createRegion(args.region))
			:fcell(Cell :new('Team')
						:options({})
						:content(
							self:_createTeam(args.team, args.teamlink),
							self:_createTeam(args.team2, args.teamlink2)
						)
						:make()
			)
			:fcell(Cell :new('Clan')
						:options({})
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

	infobox :header('Links', not Table.isEmpty(links))
	infobox:links(links, _LINK_VARIANT)
	infobox:header('Achievements', achievements)
	infobox:centeredCell(achievements)
	infobox:header('History', history)
	infobox:centeredCell(history)
	infobox:centeredCell(args.footnotes)
	self:addCustomContent(infobox, args)
	infobox:bottom(self:createBottomContent(infobox, args))

	if shouldStoreData then
		infobox:categories(role.category .. 's')
		if not args.teamlink and not args.team then
			infobox:categories('Teamless ' .. role.category .. 's')
		end
		if args.country2 or args.nationality2 then
			infobox:categories('Dual Citizenship ' .. role.category .. 's')
		end
		if args.death_date then
			infobox:categories('Deceased ' .. role.category .. 's')
		end
		if
			args.retired == 'yes' or args.retired == 'true'
			or string.lower(status.store or '') == 'retired'
			or string.match(args.retired or '', '%d%d%d%d%')--if retired has year set apply the retired category
		then
			infobox:categories('Retired ' .. role.category .. 's')
		else
			infobox:categories('Active ' .. role.category .. 's')
		end
		if not args.id then
			infobox:categories('InfoboxIncomplete.')
		end
		if not args.image then
			infobox:categories(role.category .. 's with no profile picture')
		end
		if not birthDisplay then
			infobox:categories(role.category .. 's with unknown birth date')
		end

		links = self:_getLinksLPDB(links)
		local lpdbData = {
			id = args.id or mw.title.getCurrentTitle().prefixedText,
			alternateid = args.ids,
			name = args.romanized_name or args.name,
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
function Player:getStorageType(args, role, status)
	return 'player'
end

--- Allows for overriding this functionality
function Player:getInformationType(args)
	return args.informationType or 'Player'
end

--- Allows for overriding this functionality
function Player:adjustLPDB(lpdbData, args, role, status)
	return lpdbData
end

--- Allows for overriding this functionality
function Player:getRole(args)
	return { display = args.role, store = args.role, category = args.role or 'Player'}
end

--- Allows for overriding this functionality
function Player:getStatus(args)
	return { display = args.status, store = args.status }
end

--- Allows for overriding this functionality
function Player:getHistory(infobox, args)
	return args.history
end

--- Allows for overriding this functionality
--- Decides if we store in LPDB and Vars or not
function Player:shouldStoreData(args)
	return Namespace.isMain()
end

--- Allows for overriding this functionality
--- e.g. to add faction icons to the display for SC2, SC, WC
function Player:nameDisplay(args)
	local team = args.teamlink or args.team
	local icon = mw.ext.TeamTemplate.teamexists(team)
		and mw.ext.TeamTemplate.teamicon(team) or ''
	local name = args.id or mw.title.getCurrentTitle().text

	return icon .. '&nbsp;' .. name
end

--- Allows for overriding this functionality
function Player:getAchievements(infobox, args)
	return args.achievements
end

--- Allows for overriding this functionality
function Player:calculateEarnings(args)
	return 0
end

function Player:_createRegion(region)
	if region == nil or region == '' then
		return ''
	end

	return Template.safeExpand(self.frame, 'Region', {region})
end

function Player:_createLocations(args, role)
	local countryDisplayData = {}
	local country = args.country or args.country1 or args.nationality or args.nationality1
	if country == nil or country == '' then
		return countryDisplayData
	end

	countryDisplayData[1] = Player:_createLocation(country, args.location, role)

	for index = 2, 99 do
		country = args['country' .. index] or args['nationality' .. index]
		if country == nil or country == '' then
			break
		else
			countryDisplayData[index] = Player:_createLocation(country, args['location' .. index], role)
		end
	end

	return countryDisplayData
end

function Player:_createLocation(country, location, role)
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

function Player:_createTeam(team, link)
	if team == nil or team == '' then
		return ''
	end
	link = link or team

	return '[[' .. link .. '|' .. team .. ']]'
end

function Player:_getLinksLPDB(links)
	for key, item in pairs(links) do
		links[key] = Links.makeFullLink(key, item, _LINK_VARIANT)
	end
	return links
end

return Player
