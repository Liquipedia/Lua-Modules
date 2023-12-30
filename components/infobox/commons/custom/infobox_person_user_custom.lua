---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Person/User/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local User = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class CustomInfoboxUser: Person
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
			Cell{name = 'Favorite Players', content = self.caller:_getArgsfromBaseDefault('fav-player', 'fav-players')},
			Cell{name = 'Favorite Casters', content = self.caller:_getArgsfromBaseDefault('fav-caster', 'fav-casters')},
			Cell{name = 'Favorite Teams', content = {args['fav-teams']}}
		)
		if not String.isEmpty(args['fav-team-1']) then
			Array.appendWith(widgets,
				Title{name = 'Favorite Teams'},
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
