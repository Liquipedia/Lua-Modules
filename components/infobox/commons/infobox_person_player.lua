---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Person/Player
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[
TODO:
* Categories
* Variables
* LPDB adjusting
* 

]]--

--[[
RL has additionally:
* {{#vardefine:id|{{{id|{{PAGENAME}}}}}}}
* Epic Creator Code
* Starting Game
* Solo MMR
* history handling
* region handling???
* 

]]--

--[[
CS has additionally:
* {{#vardefine:id|{{{id|{{PAGENAME}}}}}}}
* Role handling
* Games
* Prize Money
* history handling
* region handling???
* adjust earnings stuff (CS still uses the smw shit)

]]--

--[[
TODO as prep:
- push https://liquipedia.net/rocketleague/Module:YearsActive to commons and use class.export for it
- create region data modules???

]]--

--[[
Remarks:
- We agreed to kick clans
- removed "Signature Hero" stuff from RL (templates it uses do not exist, seems to be a copy paste left over)

]]--

local Player = require('Module:Infobox/Person')
local String = require('Module:StringUtils')
local Class = require('Module:Class')
local Earnings = require('Module:Earnings')
local Page = require('Module:Page')
local YearsActive = require('Module:YearsActive')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local _BANNED = mw.loadData('Module:Banned')

local _pagename = mw.title.getCurrentTitle().prefixedText

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args
	player.args.informationType = player.args.informationType or 'Player'

	player.calculateEarnings = CustomPlayer.calculateEarnings
	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables
	player.getCategories = CustomPlayer.getCategories
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
	--aaa
end

function CustomPlayer:getCategories(args, birthDisplay, personType, status)
	if _shouldStoreData then --this needs to be defined
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

return CustomPlayer
