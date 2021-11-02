---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Person/Player
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Player = require('Module:Infobox/Person')
local String = require('Module:StringUtils')
local Class = require('Module:Class')
local Namespace = require('Module:Namespace')
local Earnings = require('Module:Earnings')
local Variables = require('Module:Variables')
local Page = require('Module:Page')
local YearsActive = require('Module:YearsActive')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local _BANNED = mw.loadData('Module:Banned')

local _pagename = mw.title.getCurrentTitle().prefixedText

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _roles

local _ROLES = {
	coach = {
		storage = 'Coach',
		typeVar = 'is_talent',
		display = '[[:Category:Coaches|Coach]]',
		roleVar = 'Coach',
		category = {'Coaches'},
	},
	['assistant coach'] = {
		storage = 'Assistant Coach',
		typeVar = 'is_coach',
		display = '[[:Category:Coaches|Assistant Coach]]',
		roleVar = 'Analyst',
		category = {'Coaches', 'Assistant Coaches'},
	},
	analyst = {
		storage = 'Analyst',
		typeVar = 'is_coach',
		display = '[[:Category:Analysts|Analyst]]',
		roleVar = 'Analyst',
		category = {'Analysts'},
	},
	manager = {
		storage = 'Manager',
		typeVar = 'is_management',
		display = '[[:Category:Managers|Manager]]',
		roleVar = 'Manager',
		category = {'Managers'},
	},
	journalist = {
		storage = 'Journalist',
		typeVar = nil,
		display = '[[:Category:Journalists|Journalist]]',
		roleVar = 'Journalist',
		category = {'Journalists'},
	},
	commentator = {
		storage = 'Caster',
		typeVar = 'is_talent',
		display = '[[:Category:Casters|Commentator]]',
		roleVar = 'Commentator',
		category = {'Casters'},
	},
	caster = {
		storage = 'Caster',
		typeVar = 'is_talent',
		display = '[[:Category:Casters|Commentator]]',
		roleVar = 'Commentator',
		category = {'Casters'},
	},
	interviewer = {
		storage = 'Interviewer',
		typeVar = 'is_talent',
		display = '[[:Category:Production Staff|Interviewer]]',
		roleVar = 'Interviewer',
		category = {'Interviewers', 'Production Staff'},
	},
	director = {
		storage = 'Interviewer',
		typeVar = 'is_talent',
		display = '[[:Category:Production Staff|Director]]',
		roleVar = 'Director',
		category = {'Directors', 'Production Staff'},
	},
	producer = {
		storage = 'Producer',
		typeVar = 'is_talent',
		display = '[[:Category:Production Staff|Producer]]',
		roleVar = 'Producer',
		category = {'Producers', 'Production Staff'},
	},
	expert = {
		storage = 'Expert',
		typeVar = 'is_talent',
		display = '[[:Category:Experts|Expert]]',
		roleVar = 'Expert',
		category = {'Experts'},
	},
	host = {
		storage = 'Host',
		typeVar = 'is_talent',
		display = '[[:Category:Hosts|Host]]',
		roleVar = 'Host',
		category = {'Hosts'},
	},
	observer = {
		storage = 'Observer',
		typeVar = 'is_talent',
		display = '[[:Category:Observers|Observer]]',
		roleVar = 'Observer',
		category = {'Observers'},
	},
	['broadcast analyst'] = {
		storage = 'Broadcast Analyst',
		typeVar = 'is_talent',
		display = '[[:Category:Broadcast Analysts|Broadcast Analyst]]',
		roleVar = 'Broadcast Analyst',
		category = {'Broadcast Analysts'},
	},
	executive = {
		storage = 'Executive',
		typeVar = 'is_talent',
		display = '[[:Category:Organizational Staff|Executive]]',
		roleVar = 'Executive',
		category = {'Organizational Staff'},
	},
	['director of esport'] = {
		storage = 'Director of Esport',
		typeVar = 'is_talent',
		display = '[[:Category:Organizational Staff|Director of Esport]]',
		roleVar = 'Director of Esport',
		category = {'Organizational Staff'},
	},
	awp = {
		storage = 'Player',
		typeVar = 'is_player',
		display = '[[:Category:AWPers|AWPer]]',
		roleVar = 'AWPer',
		category = {'AWPers', 'Players'},
	},
	awper = {
		storage = 'Player',
		typeVar = 'is_player',
		display = '[[:Category:AWPers|AWPer]]',
		roleVar = 'AWPer',
		category = {'AWPers', 'Players'},
	},
	igl = {
		storage = 'Player',
		typeVar = 'is_player',
		display = '[[:Category:In-game leaders|In-game leader]]',
		roleVar = 'In-game leader',
		category = {'In-game leaders', 'Players'},
	},
	lurk = {
		storage = 'Player',
		typeVar = 'is_player',
		display = '[[:Category:Riflers|Rifler]] ([[:Category:Lurkers|lurker]])',
		roleVar = 'lurker',
		category = {'Riflers', 'Lurkers', 'Players'},
	},
	lurker = {
		storage = 'Player',
		typeVar = 'is_player',
		display = '[[:Category:Riflers|Rifler]] ([[:Category:Lurkers|lurker]])',
		roleVar = 'lurker',
		category = {'Riflers', 'Lurkers', 'Players'},
	},
	support = {
		storage = 'Player',
		typeVar = 'is_player',
		display = '[[:Category:Riflers|Rifler]] ([[:Category:Support players|support]])',
		roleVar = 'support',
		category = {'Riflers', 'Support players', 'Players'},
	},
	entry = {
		storage = 'Player',
		typeVar = 'is_player',
		display = '[[:Category:Riflers|Rifler]] ([[:Category:Entry fraggers|entry fragger]])',
		roleVar = 'entry fragger',
		category = {'Riflers', 'Entry fraggers', 'Players'},
	},
	entryfragger = {
		storage = 'Player',
		typeVar = 'is_player',
		display = '[[:Category:Riflers|Rifler]] ([[:Category:Entry fraggers|entry fragger]])',
		roleVar = 'entry fragger',
		category = {'Riflers', 'Entry fraggers', 'Players'},
	},
	rifle = {
		storage = 'Player',
		typeVar = 'is_player',
		display = '[[:Category:Riflers|Rifler]]',
		roleVar = 'Rifler',
		category = {'Riflers', 'Players'},
	},
	rifler = {
		storage = 'Player',
		typeVar = 'is_player',
		display = '[[:Category:Riflers|Rifler]]',
		roleVar = 'Rifler',
		category = {'Riflers', 'Players'},
	},
	player = {
		storage = 'Player',
		typeVar = 'is_player',
		display = nil,
		roleVar = 'Executive',
		category = {'Players'},
	},
}

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args
	player.args.informationType = player.args.informationType or 'Player'

	player.calculateEarnings = CustomPlayer.calculateEarnings
	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables
	player.getCategories = CustomPlayer.getCategories
	player.getPersonType = CustomPlayer.getPersonType
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		local statusContents = {}
		local status
		if not String.isEmpty(_args.status) then
			status = Page.makeInternalLink({onlyIfExists = true}, _args.status)
		end
		local banned = _BANNED[string.lower(_args.banned or '')]
		if not banned and not String.isEmpty(_args.banned) then
			banned = '[[Banned Players/Other|Multiple Bans]]'
		end
		local banned2 = _BANNED[string.lower(_args.banned2 or '')]
		local banned3 = _BANNED[string.lower(_args.banned3 or '')]
		table.insert(statusContents, status)
		table.insert(statusContents, banned)
		table.insert(statusContents, banned2)
		table.insert(statusContents, banned3)

		local yearsActive = _args.years_active
		if String.isEmpty(yearsActive) then
			yearsActive = YearsActive.get({player=mw.title.getCurrentTitle().baseText})
		else
			yearsActive = Page.makeInternalLink({onlyIfExists = true}, yearsActive)
		end

		local yearsActiveOrg = _args.years_active_manage
		if not String.isEmpty(yearsActiveOrg) then
			yearsActiveOrg = Page.makeInternalLink({onlyIfExists = true}, yearsActiveOrg)
		end

		return {
			Cell{name = 'Status', content = statusContents},
			Cell{name = 'Years Active (Player)', content = {yearsActive}},
			Cell{name = 'Years Active (Org)', content = {yearsActiveOrg}},
			Cell{name = 'Years Active (Coach)', content = {_args.years_active_coach}},
			Cell{name = 'Years Active (Analyst)', content = {_args.years_active_analyst}},
			Cell{name = 'Years Active (Talent)', content = {_args.years_active_talent}},
		}
	elseif id == 'role' then
		return {
			Cell{name = 'Role(s)', content = roles.display},
		}
	--elseif id == 'history' then
		--this differs hugely across wikis
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	return {
	}
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:calculateEarnings()
	return Earnings.calc_player({ args = { player = _pagename }})
end

function CustomPlayer:adjustLPDB(lpdbData)

	return lpdbData
end

function CustomPlayer:defineCustomPageVariables(args)
	Variables.varDefine('id', args.id or _pagename)
end

function CustomPlayer:getCategories(args, birthDisplay, personType, status)
	if Namespace.isMain() then
		local categories = { personType .. 's' }

		for _, category in pairs(_roles.categories) do
			table.insert(categories, category)
		end

		if string.lower(args.status) == 'active' and not args.teamlink and not args.team then
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

function CustomPlayer:getPersonType()
	local role = string.lower(_args.role or '')
	local role2 = string.lower(_args.role2 or '')

	local roleData = _ROLES[role] or _ROLES['player']
	local role2Data = _ROLES[role2] or {}

	local categories = {}
	for _, item in pairs(roleData.category or {}) do
		table.insert(categories, item)
	end
	for _, item in pairs(role2Data.category or {}) do
		table.insert(categories, item)
	end

	if roleData.typeVar then
		Variables.varDefine(roleData.typeVar, 'true')
	end
	if role2Data.typeVar then
		Variables.varDefine(role2Data.typeVar, 'true')
	end

	Variables.varDefine('role', roleData.roleVar or '')
	Variables.varDefine('role', role2Data.roleVar or '')

	_roles = {
		display = {
			roleData.display,
			role2Data.display,
		},
		categories = categories
	}

	return {storage = roleData.storage, category = roleData.storage}
end

return CustomPlayer
