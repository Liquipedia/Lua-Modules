---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Infobox/Person/User/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local User = Lua.import('Module:Infobox/Person/User')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class Dota2InfoboxUser: InfoboxUser
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
		Array.appendWith(widgets,
			Cell{name = 'Gender', content = {args.gender}},
			Cell{name = 'Languages', content = {args.languages}},
			Cell{name = 'Favorite heroes', content = self.caller:_getFavouriteHeroes()},
			Cell{name = 'Favorite players', content = self.caller:_getArgsfromBaseDefault('fav-player', 'fav-players')},
			Cell{name = 'Favorite casters', content = self.caller:_getArgsfromBaseDefault('fav-caster', 'fav-casters')},
			Cell{name = 'Favorite teams', content = {args['fav-teams']}}
		)
		if not String.isEmpty(args['fav-team-1']) then
			Array.appendWith(widgets,
				Title{name = 'Favorite teams'},
				Center{content = {self.caller:_getFavouriteTeams()}}
			)
		end
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

---@return string[]
function CustomUser:_getFavouriteHeroes()
	local foundArgs = self:getAllArgsForBase(self.args, 'fav-hero-')

	local heroes = {}
	for _, item in ipairs(foundArgs) do
		local hero = Template.safeExpand(mw.getCurrentFrame(), 'HeroBracket/' .. item:lower(), nil, '')
		if not String.isEmpty(hero) then
			table.insert(heroes, hero)
		end
	end
	return heroes
end

return CustomUser
