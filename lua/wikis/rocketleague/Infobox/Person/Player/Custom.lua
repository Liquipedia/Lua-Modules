---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Matches = Lua.import('Module:Matches_Player')
local Namespace = Lua.import('Module:Namespace')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Variables = Lua.import('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')
local YearsActive = Lua.import('Module:YearsActive')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local BANNED = Lua.import('Module:Banned', {loadData = true})

local NOT_APPLICABLE = 'N/A'

---@class RocketleagueInfoboxPlayer: Person
---@field basePageName string
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.informationType = player.args.informationType or 'Player'

	player.args.banned = tostring(player.args.banned or '')

	player.basePageName = mw.title.getCurrentTitle().baseText

	return player:createInfobox()
end

---@param manualInput string
---@param varName string
---@param autoFunction function
---@param autoFunctionParam table|string
---@return string?
function CustomPlayer:_parseActive(manualInput, varName, autoFunction, autoFunctionParam)
	if String.isNotEmpty(manualInput) then
		return manualInput:upper() ~= NOT_APPLICABLE and manualInput or nil
	end
	return Logic.readBool(Variables.varDefault(varName)) and autoFunction(autoFunctionParam) or nil
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		local gameDisplay = string.lower(args.game or '')
		gameDisplay = gameDisplay == 'sarpbc' and '[[SARPBC]]' or '[[Rocket League]]'

		local mmrDisplay
		if String.isNotEmpty(args.mmr) then
			mmrDisplay = '[[Leaderboards|' .. args.mmr .. ']]'
			if String.isNotEmpty(args.mmrdate) then
				mmrDisplay = mmrDisplay .. ' <small><i>('
					.. args.mmrdate .. ')</i></small>'
			end
		end

		return {
			Cell{
				name = Abbreviation.make{
					text = 'Epic Creator Code',
					title = 'Support-A-Creator Code used when purchasing Rocket League or Epic Games Store products',
				},
				content = {args.creatorcode}
			},
			Cell{name = 'Starting Game', content = {gameDisplay}},
			Cell{name = 'Solo MMR', content = {mmrDisplay}},
		}
	elseif id == 'status' then
		local statusContents = CustomPlayer._getStatusContents(args)

		-- Years active
		local yearsActive = caller:_parseActive(
			args.years_active, 'role_player', YearsActive.get, {player = caller.basePageName}
		)
		local yearsActiveCoach = caller:_parseActive(
			args.years_active_coach, 'role_coach', YearsActive.get, {player = caller.basePageName, prefix = 'c'}
		)
		local yearsActiveTalent = caller:_parseActive(
			args.years_active_talent, 'role_talent', YearsActive.getTalent, caller.basePageName
		)

		return {
			Cell{name = 'Status', content = statusContents},
			Cell{name = 'Years Active (Player)', content = {yearsActive}},
			Cell{name = 'Years Active (Coach)', content = {yearsActiveCoach}},
			Cell{name = 'Years Active (Talent)', content = {yearsActiveTalent}},
		}
	elseif id == 'history' then
		local getHistoryCells = function(key, title)
			return {
				String.isNotEmpty(args[key]) and Title{children = title} or nil,
				Center{children = {args[key]}},
			}
		end

		Array.extendWith(widgets,
			getHistoryCells('history_fwc', '[[FIFAe World Cup|FIFAe World Cup]] History'),
			getHistoryCells('history_iwo', '[[Intel World Open|Intel World Open]] History'),
			getHistoryCells('history_gfinity', '[[Gfinity/Elite_Series|Gfinity Elite Series]] History'),
			getHistoryCells('history_odl', '[[Oceania Draft League|Oceania Draft League]] History'),
			getHistoryCells('history_irc', '[[Italian Rocket Championship]] History'),
			getHistoryCells('history_elite_series', '[[Elite Series]] History')
		)
	elseif id == 'nationality' then
		return {
			Cell{name = 'Location', content = {args.location}},
			Cell{name = 'Nationality', content = caller:displayLocations()}
		}
	end
	return widgets
end

---@param args table
---@param birthDisplay string
---@param personType string
---@param status PlayerStatus
---@return string[]
function CustomPlayer:getCategories(args, birthDisplay, personType, status)
	if not Namespace.isMain() then return {} end

	local categories = {}

	local roles = self.roles

	---@param roleString string
	---@param role PersonRoleDataExtended
	---@return boolean
	local roleIsContained = function(roleString, role)
		return (role.key or role.display or ''):lower():find(roleString) ~= nil
	end

	---@param roleString string
	---@param category string
	---@return string?
	local checkRole = function(roleString, category)
		if not Array.any(roles, FnUtil.curry(roleIsContained, roleString)) then return end
		return category
	end

	Array.appendWith(categories,
		checkRole('observer', 'Observers'),
		checkRole('coach', 'Coaches'),
		checkRole('caster', 'Casters'),
		checkRole('host', 'Hosts'),
		checkRole('player', 'Players'),
		checkRole('producer', 'Producers'),
		checkRole('manager', 'Managers'),
		checkRole('analyst', 'Analysts')
	)

	if Array.any(roles, FnUtil.curry(roleIsContained, 'player')) then
		if string.lower(args.status) == 'active' and not args.teamlink and not args.team then
			table.insert(categories, 'Teamless Players')
		end

		if String.isEmpty(args.status) then
			table.insert(categories, 'Players without a status')
		end
	end

	local personTypeSuffix = personType == 'Coach' and 'es' or 's'

	if
		not self.nonRepresenting and (args.country2 or args.nationality2)
		or args.country3
		or args.nationality3
	then
		table.insert(categories, 'Dual Citizenship ' .. personType .. personTypeSuffix)
	end

	if args.death_date then
		table.insert(categories, 'Deceased ' .. personType .. personTypeSuffix)
	end

	if
		args.retired == 'yes' or args.retired == 'true'
		or string.lower(status or '') == 'retired'
		or string.match(args.retired or '', '%d%d%d%d')--if `|retired` has year set
	then
		table.insert(categories, 'Retired ' .. personType .. personTypeSuffix)
	end

	if not args.image then
		table.insert(categories, personType .. personTypeSuffix .. ' with no profile picture')
	end

	if String.isEmpty(birthDisplay) then
		table.insert(categories, personType .. personTypeSuffix .. ' with unknown birth date')
	end

	if string.lower(args.game or '') == 'sarpbc' then
		table.insert(categories, 'SARPBC Players')
	end

	local team = args.teamlink or args.team
	if team and not mw.ext.TeamTemplate.teamexists(team) then
		table.insert(categories, 'Players with invalid team')
	end

	Array.forEach(self.locations, function(country)
		local demonym = Flags.getLocalisation(country)
		if demonym then
			Array.appendWith(categories,
				checkRole('observer', demonym .. ' Observers'),
				checkRole('coach', demonym .. ' Coaches'),
				checkRole('caster', demonym .. ' Casters'),
				checkRole('host', demonym .. ' Casters'),
				checkRole('player', demonym .. ' Players'),
				checkRole('producer', demonym .. ' Producers'),
				checkRole('manager', demonym .. ' Managers'),
				checkRole('analyst', demonym .. ' Analysts')
			)
		end
	end)

	return categories
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.status = lpdbData.status or 'Unknown'

	local birthMonthAndDay = string.match(args.birth_date or '', '%-%d%d?%-%d%d?$')
	birthMonthAndDay = string.gsub(birthMonthAndDay or '', '^%-', '')

	lpdbData.extradata.birthmonthandday = birthMonthAndDay

	return lpdbData
end

---@param args table
function CustomPlayer:defineCustomPageVariables(args)
	Variables.varDefine('id', args.id or self.pagename)
end

---@return string?
function CustomPlayer:createBottomContent()
	if Namespace.isMain() then
		return tostring(Matches.get({args = {noClass = true}}))
	end
end

---@param args table
---@return string[]
function CustomPlayer._getStatusContents(args)
	local statusContents = {}
	local status
	if not String.isEmpty(args.status) then
		status = Page.makeInternalLink({onlyIfExists = true}, args.status) or args.status
	end
	table.insert(statusContents, status)

	local banned = BANNED[string.lower(args.banned or '')]
	if not banned and not String.isEmpty(args.banned) then
		banned = '[[Banned Players/Other|Multiple Bans]]'
		table.insert(statusContents, banned)
	end

	local index = 2
	banned = BANNED[string.lower(args['banned' .. index] or '')]
	while banned do
		table.insert(statusContents, banned)
		index = index + 1
		banned = BANNED[string.lower(args['banned' .. index] or '')]
	end

	return statusContents
end

---@return string[]
function CustomPlayer:displayLocations()
	return Array.map(self.locations, function(country)
		return Flags.Icon{flag = country, shouldLink = true} .. ' ' ..
			Page.makeInternalLink(country, ':Category:' .. country)
	end)
end

---@return string[]
function CustomPlayer:getLocations()
	return Array.map(self:getAllArgsForBase(self.args, 'country'), function(country)
		return Flags.CountryName{flag = country}
	end)
end

return CustomPlayer
