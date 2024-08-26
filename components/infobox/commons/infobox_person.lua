---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Person
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local AgeCalculation = Lua.import('Module:AgeCalculation')
local BasicInfobox = Lua.import('Module:Infobox/Basic')
local Earnings = Lua.import('Module:Earnings')
local Flags = Lua.import('Module:Flags')
local Links = Lua.import('Module:Links')
local PlayerIntroduction = Lua.import('Module:PlayerIntroduction/Custom')
local Region = Lua.import('Module:Region')

local Widgets = require('Module:Infobox/Widget/All')
local Header = Widgets.Header
local Title = Widgets.Title
local Cell = Widgets.Cell
local Center = Widgets.Center
local Builder = Widgets.Builder
local Customizable = Widgets.Customizable

---@class Person: BasicInfobox
---@field locations string[]
local Person = Class.new(BasicInfobox)

local Language = mw.getContentLanguage()
local LINK_VARIANT = 'player'
local COUNTRIES_EASTERN_NAME_ORDER = {
	'China',
	'Taiwan',
	'Hong Kong',
	'Vietnam',
	'South Korea',
	'Cambodia'
}

---@enum PlayerStatus
local Status = {
	ACTIVE = 'Active',
	INACTIVE = 'Inactive',
	RETIRED = 'Retired',
	DECEASED = 'Passed Away',
}

local STATUS_TRANSLATE = {
	active = Status.ACTIVE,
	inactive = Status.INACTIVE,
	retired = Status.RETIRED,
	['passed away'] = Status.DECEASED,
	deceased = Status.DECEASED, -- Temporary until conversion
	banned = Status.INACTIVE, -- Temporary until conversion
}

local BANNED = 'banned' -- Temporary until conversion

---@param frame Frame
---@return Html
function Person.run(frame)
	local person = Person(frame)
	return person:createInfobox()
end

---@return Html
function Person:createInfobox()
	local infobox = self.infobox
	local args = self.args

	self.locations = self:getLocations()

	local lowerStatus = (args.status or ''):lower()
	if lowerStatus == BANNED then
		-- Temporary until conversion
		args.banned = args.banned or true
	end
	args.status = STATUS_TRANSLATE[lowerStatus]

	assert(String.isNotEmpty(args.id), 'You need to specify an "id"')

	if Logic.readBool(args.autoTeam) then
		local team, team2 = PlayerIntroduction.playerTeamAuto{player=self.pagename}
		args.team = Logic.emptyOr(args.team, team)
		args.team2 = Logic.emptyOr(args.team2, team2)
	end

	-- check if non-representing is used and set an according value in self
	-- so it can be accessed in the /Custom modules
	args.country = self:getStandardNationalityValue(args.country or args.nationality)
	if args.country == self:getStandardNationalityValue('non-representing') then
		self.nonRepresenting = true
	end

	self.region = Region.run({region = args.region, country = args.country})

	args.ids = args.ids or args.alternateids

	args = self:_flipNameOrder(args)

	--set those already here as they are needed in several functions below
	local links = Links.transform(args)
	local personType = self:getPersonType(args)
	--make earnings values available in the /Custom modules
	self.totalEarnings, self.earningsPerYear = self:calculateEarnings(args)

	local ageCalculationSuccess, age = pcall(AgeCalculation.run, {
			birthdate = args.birth_date,
			birthlocation = args.birth_location,
			deathdate = args.death_date,
			deathlocation = args.death_location,
		})
	if not ageCalculationSuccess then
		age = self:_createAgeCalculationErrorMessage(age --[[@as string]])
	end

	self.age = age

	local widgets = {
		Header{
			name = self:nameDisplay(args),
			image = args.image,
			imageDefault = args.default,
			subHeader = self:subHeaderDisplay(args),
			size = args.imagesize,
		},
		Center{content = {args.caption}},
		Title{name = (args.informationType or 'Player') .. ' Information'},
		Customizable{id = 'names', children = {
				Cell{name = 'Name', content = {args.name}},
				Cell{name = 'Romanized Name', content = {args.romanized_name}},
			}
		},
		Customizable{id = 'nationality', children = {
				Cell{name = 'Nationality', content = self:displayLocations()}
			}
		},
		Cell{name = 'Born', content = {age.birth}},
		Cell{name = 'Died', content = {age.death}},
		Customizable{id = 'region', children = {
				Cell{name = 'Region', content = {self.region.display}}
			}
		},
		Customizable{id = 'status', children = {
			Cell{name = 'Status', content = {(Logic.readBool(args.banned) and 'Banned') or args.status}}
			}
		},
		Customizable{id = 'role', children = {
			Cell{name = 'Role', content = {args.role}}
			}
		},
		Customizable{id = 'teams', children = {
			Builder{builder = function()
				local teams = Array.mapIndexes(function (integerIndex)
					local index = integerIndex == 1 and '' or integerIndex
					return self:_createTeam(args['team' .. index], args['team' .. index .. 'link'])
				end)
				return {Cell{
					name = #teams > 1 and 'Teams' or 'Team',
					content = teams
				}}
			end}
		}},
		Cell{name = 'Alternate IDs', content = {
				table.concat(Array.map(mw.text.split(args.ids or '', ',', true), String.trim), ', ')
			}
		},
		Cell{name = 'Nickname(s)', content = {args.nicknames}},
		Builder{
			builder = function()
				if self.totalEarnings and self.totalEarnings ~= 0 then
					return {
						Cell{name = 'Approx. Total Winnings', content = {'$' .. Language:formatNum(self.totalEarnings)}},
					}
				end
			end
		},
		Customizable{id = 'custom', children = {}},
		Builder{
			builder = function()
				if Table.isNotEmpty(links) then
					return {
						Title{name = 'Links'},
						Widgets.Links{content = links, variant = LINK_VARIANT}
					}
				end
			end
		},
		Customizable{id = 'achievements', children = {
			Builder{
				builder = function()
					if String.isNotEmpty(args.achievements) then
						return {
							Title{name = 'Achievements'},
							Center{content = {args.achievements}}
						}
					end
				end
			},
		}},
		Customizable{id = 'history', children = {
			Builder{
				builder = function()
					if String.isNotEmpty(args.history) then
						return {
							Title{name = 'History'},
							Center{content = {args.history}}
						}
					end
				end
			},
		}},
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

	if self:shouldStoreData(args) then
		self:_definePageVariables(args)
		self:_setLpdbData(
			args,
			links,
			statusToStore,
			personType.store
		)
	end

	return infobox:build(widgets)
end

---@param args table
function Person:_definePageVariables(args)
	Variables.varDefine('firstname', args.givenname or '')
	Variables.varDefine('lastname', args.familyname or '')
	self:defineCustomPageVariables(args)
end

---@param args table
---@param links table
---@param status PlayerStatus
---@param personType string
function Person:_setLpdbData(args, links, status, personType)
	local teamLink, teamTemplate
	local team = args.teamlink or args.team
	if team and mw.ext.TeamTemplate.teamexists(team) then
		local teamRaw = mw.ext.TeamTemplate.raw(team)
		teamLink = teamRaw.page
		teamTemplate = teamRaw.templatename
	end

	local lpdbData = {
		id = args.id,
		alternateid = args.ids,
		name = args.romanized_name or args.name,
		romanizedname = args.romanized_name or args.name,
		localizedname = String.isNotEmpty(args.romanized_name) and args.name or nil,
		nationality = args.country, -- already standardized above
		nationality2 = self:getStandardNationalityValue(args.country2 or args.nationality2),
		nationality3 = self:getStandardNationalityValue(args.country3 or args.nationality3),
		birthdate = self.age.birthDateIso,
		deathdate = self.age.deathDateIso,
		image = args.image,
		region = self.region.region,
		team = teamLink or team,
		teampagename = mw.ext.TeamLiquidIntegration.resolve_redirect(teamLink or team or ''):gsub(' ', '_'),
		teamtemplate = teamTemplate,
		status = status,
		type = personType,
		earnings = self.totalEarnings,
		earningsbyyear = {},
		links = Links.makeFullLinksForTableItems(links, LINK_VARIANT),
		extradata = {
			firstname = args.givenname,
			lastname = args.familyname,
			banned = args.banned,
		},
	}

	for year, earningsOfYear in pairs(self.earningsPerYear or {}) do
		lpdbData.extradata['earningsin' .. year] = earningsOfYear
		lpdbData.earningsbyyear[year] = earningsOfYear
	end

	-- Store additional team-templates in extradata
	for teamKey, otherTeam, teamIndex in Table.iter.pairsByPrefix(args, 'team', {requireIndex = false}) do
		if teamIndex > 1 then
			otherTeam = args[teamKey .. 'link'] or otherTeam
			lpdbData.extradata[teamKey] = (mw.ext.TeamTemplate.raw(otherTeam) or {}).templatename
		end
	end

	lpdbData = self:adjustLPDB(lpdbData, args, personType)
	lpdbData = Json.stringifySubTables(lpdbData)
	local storageType = self:getStorageType(args, personType, status)

	mw.ext.LiquipediaDB.lpdb_player(storageType .. '_' .. args.id, lpdbData)
end

-- Allows this function to be used in /Custom
---@param nationality string
---@return string?
function Person:getStandardNationalityValue(nationality)
	if String.isEmpty(nationality) then
		return nil
	end

	local nationalityToStore = Flags.CountryName(nationality)

	if String.isEmpty(nationalityToStore) then
		table.insert(
			self.infobox.warnings,
			'"' .. nationality .. '" is not supported as a value for nationalities'
		)
		return nil
	end

	return nationalityToStore
end

--- Allows for overriding this functionality
---@param args table
function Person:defineCustomPageVariables(args)
end

--- Allows for overriding this functionality
---@param args table
---@param personType string
---@param status string
---@return string
function Person:getStorageType(args, personType, status)
	return string.lower(personType)
end

--- Allows for overriding this functionality
---@param lpdbData table
---@param args table
---@param personType string
---@return table
function Person:adjustLPDB(lpdbData, args, personType)
	return lpdbData
end

--- Allows for overriding this functionality
---@param args table
---@return {store: string, category: string}
function Person:getPersonType(args)
	return {store = 'Player', category = 'Player'}
end

--- Allows for overriding this functionality
---@param args table
---@return PlayerStatus
function Person:getStatusToStore(args)
	if args.status then
		return args.status
	elseif args.death_date then
		return Status.DECEASED
	elseif Logic.readBool(args.retired) or string.match(args.retired or '', '%d%d%d%d') then
		return Status.RETIRED
	elseif Logic.readBool(args.inactive) then
		return Status.INACTIVE
	end

	return Status.ACTIVE
end

--- Allows for overriding this functionality
--- Decides if we store in LPDB and Vars or not
---@param args table
---@return boolean
function Person:shouldStoreData(args)
	return Namespace.isMain() and
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
end

--- Allows for overriding this functionality
--- e.g. to add faction icons to the display for SC2, SC, WC
---@param args table
---@return string
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
---@param args table
---@return string?
function Person:subHeaderDisplay(args)
	return args.localid
end

--- Allows for overriding this functionality
---@param args table
---@return number
---@return table<integer, number?>?
function Person:calculateEarnings(args)
	return Earnings.calculateForPlayer{
		player = args.earnings or self.pagename,
		perYear = true
	}
end

---@return string[]
function Person:getLocations()
	local locations = {}
	for _, country in Table.iter.pairsByPrefix(self.args, {'country', 'nationality'}, {requireIndex = false}) do
		table.insert(locations, country)
	end

	return Array.map(locations, function(country)
		return Flags.CountryName(country)
	end)
end

---@return string[]
function Person:displayLocations()
	return Array.map(self.locations, function(country, locationIndex)
		local location = self.args['location' .. locationIndex]
		return Flags.Icon({flag = country, shouldLink = true}) .. '&nbsp;' ..
			Page.makeInternalLink(country, ':Category:' .. country) ..
			(location and (',&nbsp;' .. location) or '')
	end)
end

---@param team string?
---@param link string?
---@return string?
function Person:_createTeam(team, link)
	link = link or team
	if String.isEmpty(link) then
		return nil
	end
	---@cast link -nil

	if mw.ext.TeamTemplate.teamexists(link) then
		local data = mw.ext.TeamTemplate.raw(link)
		link, team = data.page, data.name
	end

	return Page.makeInternalLink({onlyIfExists = true}, team, link) or team
end

--- Allows for overriding this functionality
---@param args table
---@param birthDisplay string
---@param personType string
---@param status PlayerStatus
---@return string[]
function Person:getCategories(args, birthDisplay, personType, status)
	if not self:shouldStoreData(args) then
		return {}
	end

	local team = args.teamlink or args.team
	local categories = Array.append(self.age.categories,
		personType .. 's',
		status .. ' ' .. personType .. 's'
	)

	if
		not self.nonRepresenting and (args.country2 or args.nationality2)
		or args.country3
		or args.nationality3
	then
		table.insert(categories, 'Dual Citizenship ' .. personType .. 's')
	end

	--account for banned possibly being a (stringified) bool
	--or being a string that indicates what the player is banned from
	if Logic.readBoolOrNil(args.banned) ~= false and Logic.isNotEmpty(args.banned) then
		table.insert(categories, 'Banned ' .. personType .. 's')
	end

	if status == Status.ACTIVE and String.isEmpty(team) then
		table.insert(categories, 'Teamless ' .. personType .. 's')
	end

	if not args.image then
		table.insert(categories, personType .. 's with no profile picture')
	end

	if String.isEmpty(birthDisplay) then
		table.insert(categories, personType .. 's with unknown birth date')
	end

	if String.isNotEmpty(team) and not mw.ext.TeamTemplate.teamexists(team) then
		table.insert(categories, 'Players with invalid team')
	end

	Array.extendWith(categories, Array.map(self.locations, function(country)
		return Flags.getLocalisation(country) .. ' ' .. personType .. 's'
	end))

	return self:getWikiCategories(categories)
end

--- Allows for overriding this functionality
---@param categories string[]
---@return string[]
function Person:getWikiCategories(categories)
	return categories
end

--below annotation needs the isos as optional strings to match the annotation of what `AgeCalculation.run` returns

---@param text string
---@return {death: string?, birth: string?, birthDateIso: string?, deathDateIso: string?, categories: string[]}
function Person:_createAgeCalculationErrorMessage(text)
	-- Return formatted message text for an error.
	local strongStart = '<strong class="error">Error: '
	local strongEnd = '</strong>'
	text = string.gsub(text or '', 'Module:AgeCalculation:%d+: ', '')
	text = strongStart .. mw.text.nowiki(text) .. strongEnd

	if string.match(text, '[Dd]eath') then
		return {death = text, categories = {'Age error'}}
	else
		return {birth = text, categories = {'Age error'}}
	end
end

---@param args table
---@return table
function Person:_flipNameOrder(args)
	if not Logic.readBool(args.nonameflip) and Table.includes(COUNTRIES_EASTERN_NAME_ORDER, args.country) then
		args.givenname, args.familyname = args.familyname, args.givenname
	end
	return args
end

return Person
