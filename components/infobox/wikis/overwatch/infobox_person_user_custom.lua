---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:Infobox/Person/User/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local CharacterNames = mw.loadData('Module:CharacterNames')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local User = Lua.import('Module:Infobox/Person/User')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local SIZE_HERO = '25x25px'

---@class OverwatchInfoboxUser: InfoboxUser
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
		Cell{name = 'Main Hero', content = {self:_getHeroes()}},
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

---@return string
function CustomUser:_getHeroes()
	local icons = Array.map(self:getAllArgsForBase(self.args, 'hero'), function(hero)
		return CharacterIcon.Icon{character = CharacterNames[hero:lower()], size = SIZE_HERO}
	end)

	return table.concat(icons, '&nbsp;')
end

return CustomUser
