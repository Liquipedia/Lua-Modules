---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Person
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local BasicInfobox = require('Module:Infobox/Basic')
local Links = require('Module:Links')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Namespace = require('Module:Namespace')
local Localisation = require('Module:Localisation').getLocalisation
local Flags = require('Module:Flags')
local String = require('Module:StringUtils')
local Region = require('Module:Region')
local AgeCalculation = require('Module:AgeCalculation')
local WarningBox = require('Module:WarningBox')
local Earnings = require('Module:Earnings')

local Widgets = require('Module:Infobox/Widget/All')
local Header = Widgets.Header
local Title = Widgets.Title
local Cell = Widgets.Cell
local Center = Widgets.Center
local Builder = Widgets.Builder
local Customizable = Widgets.Customizable

local Person = Class.new(BasicInfobox)

local Language = mw.language.new('en')
local _LINK_VARIANT = 'player'
local _shouldStoreData
local _region
local _warnings = {}
local _earningsPerYear = {}
local _totalEarnings

function Person.run(frame)
	local person = Person(frame)
	return person:createInfobox()
end

function Person:createInfobox()
	local infobox = self.infobox
	local args = self.args

	if String.isEmpty(args.id) then
		error('You need to specify an "id"')
	end

	_shouldStoreData = Person:shouldStoreData(args)
	-- set custom variables here already so they are available
	-- in functions we call from here on
	self:defineCustomPageVariables(args)

	--set those already here as they are needed in several functions below
	local links = Links.transform(args)
	local personType = self:getPersonType(args)
	_totalEarnings, _earningsPerYear = self:calculateEarnings(args)

	local ageCalculationSuccess, age = pcall(AgeCalculation.run, {
			birthdate = args.birth_date,
			birthlocation = args.birth_location,
			deathdate = args.death_date,
			shouldstore = _shouldStoreData
		})
	if not ageCalculationSuccess then
		age = Person._createAgeCalculationErrorMessage(age)
	end

	local widgets = {
		Header{name = self:nameDisplay(args), image = args.image, imageDefault = args.default},
		Center{content = {args.caption}},
		Title{name = (args.informationType or 'Player') .. ' Information'},
		Cell{name = 'Name', content = {args.name}},
		Cell{name = 'Romanized Name', content = {args.romanized_name}},
		Customizable{id = 'nationality', children = {
				Cell{name = 'Nationality', content = self:_createLocations(args, personType.category)}
			}
		},
		Cell{name = 'Born', content = {age.birth}},
		Cell{name = 'Died', content = {age.death}},
		Customizable{id = 'region', children = {
			Cell{name = 'Region', content = {
						self:_createRegion(args.region, args.country)
					}
				}
			}
		},
		Customizable{id = 'status', children = {
			Cell{name = 'Status', content = { args.status }
				}
			}
		},
		Customizable{id = 'role', children = {
			Cell{name = 'Role', content = { args.role }
				}
			}
		},
		Customizable{id = 'teams', children = {
			Cell{name = 'Team', content = {
						self:_createTeam(args.team, args.teamlink),
						self:_createTeam(args.team2, args.teamlink2),
						self:_createTeam(args.team3, args.teamlink3),
						self:_createTeam(args.team4, args.teamlink4),
						self:_createTeam(args.team5, args.teamlink5)
					}
				}
			}
		},
		Cell{name = 'Alternate IDs', content = {args.ids or args.alternateids}},
		Cell{name = 'Nicknames', content = {args.nicknames}},
		Builder{
			builder = function()
				if _totalEarnings and _totalEarnings ~= 0 then
					return {
						Cell{name = 'Total Earnings', content = {'$' .. Language:formatNum(_totalEarnings)}},
					}
				end
			end
		},
		Customizable{id = 'custom', children = {}},
		Builder{
			builder = function()
				if not Table.isEmpty(links) then
					return {
						Title{name = 'Links'},
						Widgets.Links{content = links, variant = _LINK_VARIANT}
					}
				end
			end
		},
		Customizable{id = 'achievements', children = {
				Builder{
					builder = function()
						if not String.isEmpty(args.achievements) then
							return {
								Title{name = 'Achievements'},
								Center{content = {args.achievements}}
							}
						end
					end
				},
			}
		},
		Customizable{id = 'history', children = {
				Builder{
					builder = function()
						if not String.isEmpty(args.history) then
							return {
								Title{name = 'History'},
								Center{content = {args.history}}
							}
						end
					end
				},
			}
		},
		Center{content = {args.footnotes}},
		Customizable{id = 'customcontent', children = {}},
	}

	infobox:bottom(self:createBottomContent())

	local statusToStore = self:getStatusToStore(args)
	infobox:categories(unpack(self:getCategories(
				args,
				age.birth,
				personType.category,
				statusToStore
			)))

	local builtInfobox = infobox:widgetInjector(self:createWidgetInjector()):build(widgets)

	if _shouldStoreData then
		self:_setLpdbData(
			args,
			links,
			statusToStore,
			personType.store
		)
	end

	return tostring(builtInfobox) .. WarningBox.displayAll(_warnings)
end

function Person:_setLpdbData(args, links, status, personType)
	links = Links.makeFullLinksForTableItems(links, _LINK_VARIANT)

	local lpdbData = {
		id = args.id or mw.title.getCurrentTitle().prefixedText,
		alternateid = args.ids,
		name = args.romanized_name or args.name,
		romanizedname = args.romanized_name or args.name,
		localizedname = String.isNotEmpty(args.romanized_name) and args.name or nil,
		nationality = Person:getStandardNationalityValue(args.country or args.nationality),
		nationality2 = Person:getStandardNationalityValue(args.country2 or args.nationality2),
		nationality3 = Person:getStandardNationalityValue(args.country3 or args.nationality3),
		birthdate = Variables.varDefault('player_birthdate'),
		deathdate = Variables.varDefault('player_deathhdate'),
		image = args.image,
		region = _region,
		team = args.teamlink or args.team,
		status = status,
		type = personType,
		earnings = _totalEarnings,
		links = links,
		extradata = {},
	}

	for year, earningsOfYear in pairs(_earningsPerYear) do
		lpdbData.extradata['earningsin' .. year] = earningsOfYear
	end

	lpdbData = self:adjustLPDB(lpdbData, args, personType)
	lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.extradata)
	lpdbData.links = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.links)
	local storageType = self:getStorageType(args, personType, status)

	mw.ext.LiquipediaDB.lpdb_player(storageType .. '_' .. (args.id or self.name), lpdbData)
end

-- Allows this function to be used in /Custom
function Person:getStandardNationalityValue(nationality)
	if String.isEmpty(nationality) then
		return nil
	end

	local nationalityToStore = Flags.CountryName(nationality)

	if String.isEmpty(nationalityToStore) then
		table.insert(
			_warnings,
			'"' .. nationality .. '" is not supported as a value for nationalities'
		)
		nationalityToStore = nil
	end

	return nationalityToStore
end

--- Allows for overriding this functionality
function Person:defineCustomPageVariables(args)
end

--- Allows for overriding this functionality
function Person:getStorageType(args, personType, status)
	return string.lower(personType)
end

--- Allows for overriding this functionality
function Person:adjustLPDB(lpdbData, args, personType)
	return lpdbData
end

--- Allows for overriding this functionality
function Person:getPersonType(args)
	return { store = 'Player', category = 'Player'}
end

--- Allows for overriding this functionality
function Person:getStatusToStore(args)
	return args.status
end

--- Allows for overriding this functionality
--- Decides if we store in LPDB and Vars or not
function Person:shouldStoreData(args)
	return Namespace.isMain()
end

--- Allows for overriding this functionality
--- e.g. to add faction icons to the display for SC2, SC, WC
function Person:nameDisplay(args)
	local team = string.lower(args.teamicon or args.ttlink or args.teamlink or args.team or '')
	local icon = mw.ext.TeamTemplate.teamexists(team)
		and mw.ext.TeamTemplate.teamicon(team) or ''
	local team2 = string.lower(args.team2icon or args.ttlink2 or args.team2link or args.team2 or '')
	local icon2 = mw.ext.TeamTemplate.teamexists(team2)
		and mw.ext.TeamTemplate.teamicon(team2) or ''
	local name = args.id or mw.title.getCurrentTitle().text

	local display = name
	if not String.isEmpty(icon) then
		display = icon .. '&nbsp;' .. name
	end
	if not String.isEmpty(icon2) then
		display = display .. ' ' .. icon2
	end

	return display
end

--- Allows for overriding this functionality
function Person:calculateEarnings(args)
	return Earnings.calculateForPlayer{
		player = args.earnings or self.pagename,
		perYear = true
	}
end

function Person:_createRegion(region, country)
	region = Region.run({region = region, country = country})
	if type(region) == 'table' then
		_region = region.region
		return region.display
	end
end

function Person:_createLocations(args, personType)
	local countryDisplayData = {}
	local country = args.country or args.country1 or args.nationality or args.nationality1
	if country == nil or country == '' then
		return countryDisplayData
	end

	countryDisplayData[1] = Person:_createLocation(country, args.location, personType)

	local index = 2
	country = args['country2'] or args['nationality2']
	while(not String.isEmpty(country)) do
		countryDisplayData[index] = Person:_createLocation(country, args['location' .. index], personType)
		index = index + 1
		country = args['country' .. index] or args['nationality' .. index]
	end

	return countryDisplayData
end

function Person:_createLocation(country, location, personType)
	if country == nil or country == '' then
		return nil
	end
	local countryDisplay = Flags.CountryName(country)
	local demonym = Localisation(countryDisplay)

	return Flags.Icon({flag = country, shouldLink = true}) .. '&nbsp;' ..
				'[[:Category:' .. countryDisplay .. '|' .. countryDisplay .. ']]'
				.. '[[Category:' .. demonym .. ' ' .. personType .. 's]]'
				.. (location ~= nil and (',&nbsp;' .. location) or '')
end

function Person:_createTeam(team, link)
	link = link or team
	if link == nil or link == '' then
		return nil
	end

	if mw.ext.TeamTemplate.teamexists(link) then
		local data = mw.ext.TeamTemplate.raw(link)
		return '[[' .. data.page .. '|' .. data.name .. ']]'
	end

	return '[[' .. link .. '|' .. team .. ']]'
end

--- Allows for overriding this functionality
function Person:getCategories(args, birthDisplay, personType, status)
	if _shouldStoreData then
		local categories = { personType .. 's' }

		if not args.teamlink and not args.team then
			table.insert(categories, 'Teamless ' .. personType .. 's')
		end
		if args.country2 or args.nationality2 then
			table.insert(categories, 'Dual Citizenship ' .. personType .. 's')
		end
		if args.death_date then
			table.insert(categories, 'Deceased ' .. personType .. 's')
		end
		if
			args.retired == 'yes' or args.retired == 'true'
			or string.lower(status or '') == 'retired'
			or string.match(args.retired or '', '%d%d%d%d')--if retired has year set apply the retired category
		then
			table.insert(categories, 'Retired ' .. personType .. 's')
		else
			table.insert(categories, 'Active ' .. personType .. 's')
		end
		if not args.image then
			table.insert(categories, personType .. 's with no profile picture')
		end
		if String.isEmpty(birthDisplay) then
			table.insert(categories, personType .. 's with unknown birth date')
		end

		return categories
	end
	return {}
end

function Person._createAgeCalculationErrorMessage(text)
	-- Return formatted message text for an error.
	local strongStart = '<strong class="error">Error: '
	local strongEnd = '</strong>'
	text = string.gsub(text or '', 'Module:AgeCalculation/test:%d+: ', '')
	if mw.title.getCurrentTitle():inNamespaces(0) then
		strongEnd = strongEnd .. '[[Category:Age error]]'
	end
	text = strongStart .. mw.text.nowiki(text) .. strongEnd

	if string.match(text, '[Dd]eath') then
		return {death = text}
	else
		return {birth = text}
	end
end

return Person
