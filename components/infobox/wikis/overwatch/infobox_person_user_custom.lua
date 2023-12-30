---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:Infobox/Person/User/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Class')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local User = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class OverwatchInfoboxUser: Person
local CustomUser = Class.new(User)

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUser.run(frame)
	local user = CustomUser(frame)
	user:setWidgetInjector(CustomInjector(user))

	user.args.informationType = user.args.informationType or 'User'

	return user:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		self.caller:addCustomCells(widgets)
	elseif
		id == 'history' and
		not (String.isEmpty(args.team_history) and String.isEmpty(args.clan_history))
	then
		return {
			Title{ name = 'History' },
			Center{content = {args.team_history}},
			Center{content = {args.clan_history}},
		}
	end
	return widgets
end

---@param widgets Widget[]
---@return Widget[]
function CustomUser:addCustomCells(widgets)
	local args = self.args

	Array.appendWith(widgets,
		Cell{name = 'Gender', content = {args.gender}},
		Cell{name = 'Languages', content = {args.languages}},
		Cell{name = 'BattleTag', content = {args.battletag}},
		Cell{name = 'Main Hero', content = self:_getHeroes()},
		Cell{name = 'Favorite players', content = self:_getArgsfromBaseDefault('fav-player', 'fav-players')},
		Cell{name = 'Favorite casters', content = self:_getArgsfromBaseDefault('fav-caster', 'fav-casters')},
		Cell{name = 'Favorite teams', content = {args['fav-teams']}}
)

	if not String.isEmpty(args['fav-team-1']) then
		table.insert(widgets, Title{name = 'Favorite teams'})
		table.insert(widgets, Center{content = {self:_getFavouriteTeams()}})
	end

	if not String.isEmpty(args.s1high) then
		table.insert(widgets, Title{name = '[[Leaderboards|Skill Ratings]]'})
	end

	local index = 1
	while not String.isEmpty(args['s' .. index .. 'high']) do
		local display = args['s' .. index .. 'high']
		if not String.isEmpty(args['s' .. index .. 'final']) then
			display = display .. '&nbsp;<small>(Final: ' .. args['s' .. index .. 'final'] .. ')</small>'
		end
		table.insert(widgets, Cell{name = 'Season ' .. index, content = {display}})
		index = index + 1
	end

	table.insert(widgets, Cell{name = 'National teams', content = {args['nationalteams']}})

	return widgets
end

---@return string[]
function CustomUser:_getHeroes()
	local foundArgs = self:getAllArgsForBase(self.args, 'hero')

	local heroes = {}
	for _, item in ipairs(foundArgs) do
		local hero = Template.safeExpand(mw.getCurrentFrame(), 'Hero/' .. item, nil, '')
		if not String.isEmpty(hero) then
			table.insert(heroes, hero)
		end
	end
	return heroes
end

---@return string
function CustomUser:_getFavouriteTeams()
	local foundArgs = self:getAllArgsForBase(self.args, 'fav-team-')

	local display = ''
	for _, item in ipairs(foundArgs) do
		local team = item:lower():gsub('_', ' ')
		display = display .. mw.ext.TeamTemplate.teamicon(team)
	end

	return display
end

---@param base any
---@param default any
---@return string[]
function CustomUser:_getArgsfromBaseDefault(base, default)
	local foundArgs = self:getAllArgsForBase(self.args, base)
	table.insert(foundArgs, self.args[default])
	return foundArgs
end

---@param args table
---@return boolean
function CustomUser:shouldStoreData(args) return false end

---@param args table
---@return string
function CustomUser:getStatusToStore(args) return '' end

---@param args table
---@param birthDisplay string
---@param personType string
---@param status PlayerStatus
---@return string[]
function CustomUser:getCategories(args, birthDisplay, personType, status) return {} end

---@param args table
---@return {store: string, category: string}
function CustomUser:getPersonType(args)
	return {store = 'User', category = 'User'}
end

return CustomUser
