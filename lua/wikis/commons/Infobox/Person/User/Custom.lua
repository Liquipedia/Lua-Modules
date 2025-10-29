---
-- @Liquipedia
-- page=Module:Infobox/Person/User/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local User = Lua.import('Module:Infobox/Person/User')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class CustomInfoboxUser: InfoboxUser
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
			Cell{name = 'Gender', children = {args.gender}},
			Cell{name = 'Languages', children = {args.languages}},
			Cell{name = 'Favorite Players', children = self.caller:_getArgsfromBaseDefault('fav-player', 'fav-players')},
			Cell{name = 'Favorite Casters', children = self.caller:_getArgsfromBaseDefault('fav-caster', 'fav-casters')},
			Cell{name = 'Favorite Teams', children = {args['fav-teams']}}
		)
		if not String.isEmpty(args['fav-team-1']) then
			Array.appendWith(widgets,
				Title{children = 'Favorite Teams'},
				Center{children = {self.caller:_getFavouriteTeams()}}
			)
		end
	elseif
		id == 'history' and
		not (String.isEmpty(args.team_history) and String.isEmpty(args.clan_history))
	then
		return {
			Title{children = 'History' },
			Center{children = {args.team_history}},
			Center{children = {args.clan_history}},
		}
	end

	return widgets
end

return CustomUser
