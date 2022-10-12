---
-- @Liquipedia
-- wiki=splatoon
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local WeaponIcon = require('Module:WeaponIconPlayer')
local WeaponNames = mw.loadData('Module:WeaponNames')
local Lua = require('Module:Lua')
local Region = require('Module:Region')
local Role = require('Module:Role')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local _pagename = mw.title.getCurrentTitle().prefixedText
local _role
local _role2
local _EMPTY_AUTO_HISTORY = '<table style="width:100%;text-align:left"></table>'
local _SIZE_WEAPON = '25x25px'

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _player

function CustomPlayer.run(frame)
	local player = Player(frame)
	_player = player
	_args = player.args

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'history' then
		local automatedHistory = TeamHistoryAuto._results({
			convertrole = 'true',
			player = _pagename
		}) or ''
		automatedHistory = tostring(automatedHistory)
		if automatedHistory == _EMPTY_AUTO_HISTORY then
			automatedHistory = nil
		end

		if not (String.isEmpty(automatedHistory)) then
			return {
				Title{name = 'History'},
				Center{content = {automatedHistory}},
			}
		end

	elseif id == 'region' then return {}

	elseif id == 'role' then
		_role = Role.run({role = _args.role})
		_role2 = Role.run({role = _args.role2})
		return {
			Cell{name = _role2.display and 'Roles' or 'Role', content = {_role.display, _role2.display}}
		}
	end

	return widgets
end


function CustomInjector:addCustomCells(widgets)
	-- Signature Weapon
	local weaponIcons = Array.map(Player:getAllArgsForBase(_args, 'weapon'),
		function(weapon)
			local standardizedWeapon = WeaponNames[weapon:lower()]
			if not standardizedWeapon then
				-- we have an invalid weapon entry
				-- add warning (including tracking category)
				table.insert(
					_player.warnings,
					'Invalid weapon input "' .. weapon .. '"[[Category:Pages with invalid weapon input]]'
				)
			end
			return WeaponIcon.getImage{standardizedWeapon or weapon, size = _SIZE_WEAPON}
		end
	)

	if Table.isNotEmpty(weaponIcons) then
		table.insert(
			widgets,
			Cell{
				name = #weaponIcons > 1 and 'Signature Weapons' or 'Signature Weapon',
				content = {
					table.concat(weaponIcons, '&nbsp;')
				}
			}
		)
	end

	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.isplayer = _role.isPlayer or 'true'
	lpdbData.extradata.role = _role.role
	lpdbData.extradata.role2 = _role2.role

	-- store signature weapons with standardized name
	for weaponIndex, weapon in ipairs(Player:getAllArgsForBase(_args, 'weapon')) do
		lpdbData.extradata['signatureWeapon' .. weaponIndex] = WeaponNames[weapon:lower()]
	end

	local region = Region.run({region = _args.region, country = _args.country})
	if type(region) == 'table' then
		lpdbData.region = region.region
	end

	return lpdbData
end

return CustomPlayer
