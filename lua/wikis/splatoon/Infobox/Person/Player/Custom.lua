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

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local SIZE_WEAPON = '25x25px'

---@class SplatoonInfoboxPlayer: Person
---@field role table
---@field role2 table
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.role = Role.run{role = player.args.role}
	player.role2 = Role.run{role = player.args.role2}

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		-- Signature Weapon
		local weaponIcons = Array.map(caller:getAllArgsForBase(args, 'weapon'), function(weapon)
			local standardizedWeapon = WeaponNames[weapon:lower()]
			if not standardizedWeapon then
				-- we have an invalid weapon entry
				-- add warning (including tracking category)
				table.insert(
					caller.warnings,
					'Invalid weapon input "' .. weapon .. '"[[Category:Pages with invalid weapon input]]'
				)
			end
			return WeaponIcon.getImage{standardizedWeapon or weapon, size = SIZE_WEAPON}
		end)

		table.insert(widgets, Cell{
			name = #weaponIcons > 1 and 'Signature Weapons' or 'Signature Weapon',
			content = {table.concat(weaponIcons, '&nbsp;')}
		})
	elseif id == 'region' then return {}
	elseif id == 'role' then
		return {
			Cell{name = caller.role2.display and 'Roles' or 'Role', content = {caller.role.display, caller.role2.display}}
		}
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.extradata.isplayer = self.role.isPlayer or 'true'
	lpdbData.extradata.role = self.role.role
	lpdbData.extradata.role2 = self.role2.role

	-- store signature weapons with standardized name
	for weaponIndex, weapon in ipairs(self:getAllArgsForBase(args, 'weapon')) do
		lpdbData.extradata['signatureWeapon' .. weaponIndex] = WeaponNames[weapon:lower()]
	end

	lpdbData.region = String.nilIfEmpty(Region.name({region = args.region, country = args.country}))

	return lpdbData
end

return CustomPlayer
