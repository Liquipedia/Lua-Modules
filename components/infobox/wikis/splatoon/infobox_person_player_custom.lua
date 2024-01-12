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

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local _role
local _role2
local _SIZE_WEAPON = '25x25px'

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _player

function CustomPlayer.run(frame)
	local player = Player(frame)
	player.args.history = TeamHistoryAuto._results{convertrole = 'true'}

	_player = player
	_args = player.args
	_role = Role.run({role = _args.role})
	_role2 = Role.run({role = _args.role2})

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	if id == 'region' then return {}

	elseif id == 'role' then
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

	lpdbData.region = String.nilIfEmpty(Region.name({region = _args.region, country = _args.country}))

	return lpdbData
end

return CustomPlayer
