---
-- @Liquipedia
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
local NameOrder = require('Module:NameOrder')
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

local Roles = Lua.import('Module:Roles')

local Widgets = require('Module:Widget/All')
local Header = Widgets.Header
local Title = Widgets.Title
local Cell = Widgets.Cell
local Center = Widgets.Center
local Builder = Widgets.Builder
local Customizable = Widgets.Customizable

---@class PersonRoleData
---@field category string?
---@field display string?

---@class Person: BasicInfobox
---@field locations string[]
---@field roles PersonRoleData[]
local Person = Class.new(BasicInfobox)

local Language = mw.getContentLanguage()
local LINK_VARIANT = 'player'

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

---@return string
function Person:createInfobox()
	local args = self.args
	assert(String.isNotEmpty(args.id), 'You need to specify an "id"')

	self:_parseArgs()

	local widgets = {
		Header{
			name = self:nameDisplay(args),
			image = args.image,
			imageDefault = args.default,
			imageDefaultDark = args.defaultDark,
			subHeader = self:subHeaderDisplay(args),
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = (args.informationType or 'Player') .. ' Information'},
		Customizable{id = 'names', children = {
				Cell{name = 'Name', content = {args.name}},
				Cell{name = 'Romanized Name', content = {args.romanized_name}},
			}
		},
		Customizable{id = 'nationality', children = {
				Cell{name = 'Nationality', content = self:displayLocations()}
			}
		},
		Cell{name = 'Born', content = {self.age.birth}},
		Cell{name = 'Died', content = {self.age.death}},
		Customizable{id = 'region', children = {
				Cell{name = 'Region', content = {self.region.display}}
			}
		},
		Customizable{id = 'status', children = {
			Cell{name = 'Status', content = {(Logic.readBool(args.banned) and 'Banned') or args.status}}
			}
		},
		Customizable{id = 'role', children = {
			Builder{builder = function()
				local roles = Array.map(self.roles, function(roleData)
					return self:_displayRole(roleData)
				end)

				return {
					Cell{
						name = (#roles > 1 and 'Roles' or 'Role'),
						content = roles,
					}
				}
			end}
		}},
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
				table.concat(Array.parseCommaSeparatedString(args.ids or ''), ', ')
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
				local links = Links.transform(args)
				if Table.isNotEmpty(links) then
					return {
						Title{children = 'Links'},
						Widgets.Links{links = links, variant = LINK_VARIANT}
					}
				end
			end
		},
		Customizable{id = 'achievements', children = {
			Builder{
				builder = function()
					if String.isNotEmpty(args.achievements) then
						return {
							Title{children = 'Achievements'},
							Center{children = {args.achievements}}
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
							Title{children = 'History'},
							Center{children = {args.history}}
						}
					end
				end
			},
		}},
		Center{children = {args.footnotes}},
		Customizable{id = 'customcontent', children = {}},
	}

	self:bottom(self:createBottomContent())

	local statusToStore = self:getStatusToStore(args)
	self:categories(unpack(self:getCategories(
				args,
				self.age.birth,
				self:getPersonType(args).category,
				statusToStore
			)))

	if self:shouldStoreData(args) then
		self:_setLpdbData(
			args,
			Links.transform(args),
			statusToStore,
			self:getPersonType(args).store
		)
	end

	self:_definePageVariables(args)

	return self:build(widgets)
end

function Person:_parseArgs()
	local args = self.args

	-- STATUS and BANNED
	local function parseStatusAndBanned()
		local lowerStatus = (args.status or ''):lower()
		if lowerStatus == BANNED then
			-- Temporary until conversion
			args.banned = args.banned or true
		end
		args.status = STATUS_TRANSLATE[lowerStatus]
	end

	-- ENRICH TEAM
	local function enrichTeam()
		if Logic.readBool(args.autoTeam) then
			local team, team2 = PlayerIntroduction.playerTeamAuto{player = self.pagename}
			args.team = Logic.emptyOr(args.team, team)
			args.team2 = Logic.emptyOr(args.team2, team2)
		end
	end

	-- COUNTRY/REGION
	local function parseCountryAndRegion()
		self.locations = self:getLocations()
		-- check if non-representing is used and set an according value in self
		args.country = self:getStandardNationalityValue(args.country or args.nationality)
		if args.country == self:getStandardNationalityValue('non-representing') then
			self.nonRepresenting = true
		end
		self.region = Region.run({region = args.region, country = args.country})
	end

	-- NAME
	local function parseName()
		args.ids = args.ids or args.alternateids
		args.givenname, args.familyname = self:_flipNameOrder(args)
	end

	-- EARNINGS
	local function calculateEarnings()
		self.totalEarnings, self.earningsPerYear = self:calculateEarnings(args)
	end

	-- AGE
	local function calculateAge()
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
	end

	-- ROLES
	local function parseRoles()
		-- Backwards compatibility for the old roles input
		if not args.roles then
			args.roles = table.concat({
				args.role,
				args.role2,
				args.role3,
			}, ', ')
		end

		self.roles = Array.map(Array.parseCommaSeparatedString(args.roles), Person._createRoleData)
	end

	Logic.tryOrElseLog(parseStatusAndBanned)
	Logic.tryOrElseLog(enrichTeam)
	Logic.tryOrElseLog(parseCountryAndRegion, function() self.region = {} end)
	Logic.tryOrElseLog(parseName)
	Logic.tryOrElseLog(calculateEarnings)
	Logic.tryOrElseLog(calculateAge, function() self.age = {} end)
	Logic.tryOrElseLog(parseRoles, function() self.roles = {} end)
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
	local teamRaw = team and mw.ext.TeamTemplate.raw(team) or nil
	if teamRaw then
		teamLink = teamRaw.page
		teamTemplate = teamRaw.templatename
	end

	local roleStorageValue = function(roleData)
		if not roleData then return end
		local key = Table.getKeyOfValue(Roles.All, roleData)
		if not key then
			-- Backwards compatibility for old roles
			return roleData.display or roleData.category or ''
		end
		return key
	end

	local rolesStorageKey = Array.map(self.roles, roleStorageValue)

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
		earningsbyyear = self.earningsPerYear or {},
		links = Links.makeFullLinksForTableItems(links, LINK_VARIANT),
		extradata = {
			firstname = args.givenname,
			lastname = args.familyname,
			banned = args.banned,
			role = rolesStorageKey[1], -- Backwards compatibility
			role2 = rolesStorageKey[2], -- Backwards compatibility
			role3 = rolesStorageKey[3], -- Backwards compatibility
			roles = rolesStorageKey,
		},
	}

	-- Store additional team-templates in extradata
	for teamKey, otherTeam, teamIndex in Table.iter.pairsByPrefix(args, 'team', {requireIndex = false}) do
		if teamIndex > 1 then
			otherTeam = args[teamKey .. 'link'] or otherTeam
			lpdbData.extradata[teamKey] = (mw.ext.TeamTemplate.raw(otherTeam) or {}).templatename
		end
	end

	lpdbData = self:adjustLPDB(lpdbData, args, personType)

	mw.ext.LiquipediaDB.lpdb_player(string.lower(personType) .. '_' .. args.id, Json.stringifySubTables(lpdbData))
end

-- Allows this function to be used in /Custom
---@param nationality string
---@return string?
function Person:getStandardNationalityValue(nationality)
	if String.isEmpty(nationality) then
		return nil
	end

	local nationalityToStore = Flags.CountryName{flag = nationality}

	if String.isEmpty(nationalityToStore) then
		table.insert(
			self.warnings,
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
---@param lpdbData table
---@param args table
---@param personType string
---@return table
function Person:adjustLPDB(lpdbData, args, personType)
	return lpdbData
end

--- Allows for overriding this functionality
--- Default implementation determines the personType based on the first role.
---@param args table
---@return {store: string, category: string}
function Person:getPersonType(args)
	local playerValue = {store = 'player', category = 'Player'}
	local staffValue = {store = 'staff', category = 'Staff'}

	if self.roles[1] and Table.includes(Roles.StaffRoles, self.roles[1]) then
		return staffValue
	end
	return playerValue
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
		return Flags.CountryName{flag = country}
	end)
end

---@return string[]
function Person:displayLocations()
	return Array.map(self.locations, function(country, locationIndex)
		local location = self.args['location' .. locationIndex]
		return Flags.Icon{flag = country, shouldLink = true} .. '&nbsp;' ..
			Page.makeInternalLink(country, ':Category:' .. country) ..
			(location and (',&nbsp;' .. location) or '')
	end)
end

---@param roleKey string
---@return PersonRoleData?
function Person._createRoleData(roleKey)
	if String.isEmpty(roleKey) then return nil end

	local roleData = Roles.All[roleKey:lower()]

	--- Backwards compatibility for old roles
	if not roleData then
		mw.ext.TeamLiquidIntegration.add_category('Pages with invalid role input')
		local display = String.upperCaseFirst(roleKey)
		return {
			display = display,
			category = display .. 's'
		}
	end

	return roleData
end

---@param roleData PersonRoleData?
---@return string?
function Person:_displayRole(roleData)
	if not roleData then return end

	return Page.makeInternalLink(roleData.display, ':Category:' .. roleData.category)
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

	local teamRaw = mw.ext.TeamTemplate.raw(link)
	if teamRaw then
		link, team = teamRaw.page, teamRaw.name
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
	local categories = {}
	if not self:shouldStoreData(args) then
		return categories
	end
	local team = args.teamlink or args.team

	categories = Array.extend(categories, self.age.categories)
	categories = Array.extend(categories,
		personType .. 's',
		status .. ' ' .. personType .. 's'
	)

	categories = Array.extend(categories, Array.map(self.roles, function(roleData)
		return roleData.category
	end))

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
---@return string, string
function Person:_flipNameOrder(args)
	return NameOrder.reorderNames(
		args.givenname, args.familyname, {country = args.country, forceWesternOrder = args.nonameflip}
	)
end

return Person
