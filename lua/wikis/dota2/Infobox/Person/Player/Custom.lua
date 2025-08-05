---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local Class = Lua.import('Module:Class')
local HeroNames = Lua.import('Module:HeroNames', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Template = Lua.import('Module:Template')
local YearsActive = Lua.import('Module:YearsActive')

local Flags = Lua.import('Module:Flags')
local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local BANNED = Lua.import('Module:Banned', {loadData = true})

local SIZE_HERO = '44x25px'
local CONVERSION_PLAYER_ID_TO_STEAM = 61197960265728

local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	-- Override links to allow one param to set multiple links
	player.args.datdota = player.args.playerid
	player.args.dotabuff = player.args.playerid
	player.args.stratz = player.args.playerid
	if Logic.isNumeric(player.args.playerid) then
		player.args.steamalternative = '765' .. (tonumber(player.args.playerid) + CONVERSION_PLAYER_ID_TO_STEAM)
	end

	player.args.informationType = player.args.informationType or 'Player'

	player.args.banned = tostring(player.args.banned or '')

	player.basePageName = mw.title.getCurrentTitle().baseText

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		local icons = Array.map(caller:getAllArgsForBase(args, 'hero'), function(hero)
			return CharacterIcon.Icon{character = HeroNames[hero:lower()], size = SIZE_HERO}
		end)
		return {
			Cell{name = 'Signature Hero', content = {table.concat(icons, '&nbsp;')}}
		}
	elseif id == 'status' then
		local statusContents = caller:_getStatusContents()

		local yearsActive = args.years_active
		if String.isEmpty(yearsActive) then
			yearsActive = YearsActive.display({player = caller.basePageName})
		else
			yearsActive = Page.makeInternalLink({onlyIfExists = true}, yearsActive)
		end

		local yearsActiveOrg = args.years_active_manage
		if not String.isEmpty(yearsActiveOrg) then
			yearsActiveOrg = Page.makeInternalLink({onlyIfExists = true}, yearsActiveOrg)
		end

		return {
			Cell{name = 'Status', content = statusContents},
			Cell{name = 'Years Active (Player)', content = {yearsActive}},
			Cell{name = 'Years Active (Org)', content = {yearsActiveOrg}},
			Cell{name = 'Years Active (Coach)', content = {args.years_active_coach}},
			Cell{name = 'Years Active (Analyst)', content = {args.years_active_analyst}},
			Cell{name = 'Years Active (Talent)', content = {args.years_active_talent}},
		}
	elseif id == 'history' then
		if not String.isEmpty(args.history_iwo) then
			table.insert(widgets, Title{children = '[[Intel World Open|Intel World Open]] History'})
			table.insert(widgets, Center{children = {args.history_iwo}})
		end
		if not String.isEmpty(args.history_gfinity) then
			table.insert(widgets, Title{children = '[[Gfinity/Elite_Series|Gfinity Elite Series]] History'})
			table.insert(widgets, Center{children = {args.history_gfinity}})
		end
		if not String.isEmpty(args.history_odl) then
			table.insert(widgets, Title{children = '[[Oceania Draft League|Oceania Draft League]] History'})
			table.insert(widgets, Center{children = {args.history_odl}})
		end
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.status = lpdbData.status or 'Unknown'

	for heroIndex, hero in ipairs(self:getAllArgsForBase(args, 'hero')) do
		lpdbData.extradata['hero' .. heroIndex] = HeroNames[hero:lower()]
	end

	lpdbData.extradata['lc_id'] = self.basePageName:lower()
	lpdbData.extradata.team2 = mw.ext.TeamLiquidIntegration.resolve_redirect(
		not String.isEmpty(args.team2link) and args.team2link or args.team2 or '')
	lpdbData.extradata.playerid = args.playerid

	return lpdbData
end

---@return string?
function CustomPlayer:createBottomContent()
	if Namespace.isMain() then
		return tostring(Template.safeExpand(
			mw.getCurrentFrame(), 'Upcoming_and_ongoing_matches_of_player', {player = self.basePageName})
			.. '<br>' .. Template.safeExpand(
			mw.getCurrentFrame(), 'Upcoming_and_ongoing_tournaments_of_player', {player = self.basePageName})
		)
	end
end

---@return string[]
function CustomPlayer:_getStatusContents()
	local args = self.args
	local statusContents = {}
	local status
	if not String.isEmpty(args.status) then
		status = Page.makeInternalLink({onlyIfExists = true}, args.status) or args.status
	end
	table.insert(statusContents, status)

	local banned = BANNED[string.lower(args.banned or '')]
	if not banned and not String.isEmpty(args.banned) then
		banned = '[[Banned Players|Multiple Bans]]'
		table.insert(statusContents, banned)
	end

	statusContents = Array.map(self:getAllArgsForBase(args, 'banned'),
		function(item, _)
			return BANNED[string.lower(item)]
		end
	)

	return statusContents
end

---@return string[]
function CustomPlayer:getLocations()
	return Array.map(self:getAllArgsForBase(self.args, 'country'), function(country)
		return Flags.CountryName{flag = country}
	end)
end

return CustomPlayer
