---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Person/User/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local CustomPerson = Lua.import('Module:Infobox/Person/Custom', {requireDevIfEnabled = true})

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

---@class Starcraft2InfoboxUser: SC2CustomPerson
local CustomUser = Class.new(CustomPerson)

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
			Cell{name = 'Languages', content = {args.languages}},
			Cell{name = 'Favorite players', content = self.caller:_getArgsfromBaseDefault('fav-player', 'fav-players')},
			Cell{name = 'Favorite casters', content = self.caller:_getArgsfromBaseDefault('fav-caster', 'fav-casters')},
			Cell{name = 'Favorite teams', content = {args['fav-teams']}}
		)
	if not String.isEmpty(args['fav-team-1']) then
		table.insert(widgets, Title{name = 'Favorite teams'})
		table.insert(widgets, Center{content = {self.caller:_getFavouriteTeams()}})
	end
	elseif id == 'status' then
		return {
			Cell{name = 'Race', content = {self.caller:getRaceData(args.race or 'unknown')}}
		}
	elseif id == 'role' then return {}
	elseif id == 'region' then return {}
	elseif id == 'achievements' then return {}
	elseif
		id == 'history' and
		string.match(args.retired or '', '%d%d%d%d')
	then
		table.insert(widgets, Cell{
				name = 'Retired',
				content = {args.retired}
			})
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
function CustomUser:shouldStoreData(args)
	Variables.varDefine('disable_LPDB_storage', 'true')
	return false
end

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
