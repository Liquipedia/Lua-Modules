---
-- @Liquipedia
-- wiki=worldoftanks
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Players
	['igl'] = {category = 'In-game leaders', variable = 'In-game leader', isplayer = true},

	-- Staff and Talents
	['analyst'] = {category = 'Analysts', variable = 'Analyst', staff = true},
	['broadcast analyst'] = {category = 'Broadcast Analysts', variable = 'Broadcast Analyst', talent = true},
	['observer'] = {category = 'Observers', variable = 'Observer', talent = true},
	['host'] = {category = 'Host', variable = 'Host', talent = true},
	['coach'] = {category = 'Coaches', variable = 'Coach', staff = true},
	['caster'] = {category = 'Casters', variable = 'Caster', talent = true},
	['manager'] = {category = 'Managers', variable = 'Manager', staff = true},
	['streamer'] = {category = 'Streamers', variable = 'Streamer', talent = true},
}

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = Player(frame)

	player.args.history = TeamHistoryAuto._results{convertrole = 'true'}
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.getPersonType = CustomPlayer.getPersonType

	_args = player.args

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'status' then
		return {
			Cell{name = 'Status', content = CustomPlayer._getStatusContents()},
			Cell{name = 'Years Active', content = {_args.years_active}},
		}
	elseif id == 'role' then
		return {
			Cell{name = 'Role', content = {
				CustomPlayer._createRole('role', _args.role),
				CustomPlayer._createRole('role2', _args.role2)
			}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{
			name = 'Retired',
			content = {_args.retired}
		})
	end
	return widgets
end

---@return WidgetInjector
function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

---@return string[]
function CustomPlayer._getStatusContents()
	return {Page.makeInternalLink({onlyIfExists = true}, _args.status) or _args.status}
end

---@param key string
---@param role string?
---@return string?
function CustomPlayer._createRole(key, role)
	if String.isEmpty(role) then
		return nil
	end
	---@cast role -nil

	local roleData = ROLES[role:lower()]
	if not roleData then
		return nil
	end
	if Player:shouldStoreData(_args) then
		local categoryCoreText = 'Category:' .. roleData.category

		return '[[' .. categoryCoreText .. ']]' .. '[[:' .. categoryCoreText .. '|' ..
			Variables.varDefineEcho(key or 'role', roleData.variable) .. ']]'
	else
		return Variables.varDefineEcho(key or 'role', roleData.variable)
	end
end

---@param role string?
---@return boolean
function CustomPlayer._isNotPlayer(role)
	local roleData = ROLES[(role or ''):lower()]
	return roleData and (roleData.talent or roleData.staff)
end

---@param args table
---@return {store: string, category: string}
function CustomPlayer:getPersonType(args)
	local roleData = ROLES[(args.role or ''):lower()]
	if roleData then
		if roleData.staff then
			return {store = 'staff', category = 'Staff'}
		elseif roleData.talent then
			return {store = 'talent', category = 'Talent'}
		end
	end
	return {store = 'player', category = 'Player'}
end

return CustomPlayer
