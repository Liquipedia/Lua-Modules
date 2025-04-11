---
-- @Liquipedia
-- wiki=mobilelegends
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local HeroNames = mw.loadData('Module:HeroNames')
local Lua = require('Module:Lua')
local Region = require('Module:Region')
local Role = require('Module:Role')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local SIZE_HERO = '25x25px'

---@class MobilelegendsInfoboxPlayer: Person
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
		-- Signature Heroes
		local heroIcons = Array.map(caller:getAllArgsForBase(args, 'hero'), function(hero)
			local standardizedHero = HeroNames[hero:lower()]
			if not standardizedHero then
				-- we have an invalid hero entry
				-- add warning (including tracking category)
				table.insert(
					caller.warnings,
					'Invalid hero input "' .. hero .. '"[[Category:Pages with invalid hero input]]'
				)
			end
			return CharacterIcon.Icon{character = standardizedHero or hero, size = SIZE_HERO}
		end)

		table.insert(widgets, Cell{
			name = #heroIcons > 1 and 'Signature Heroes' or 'Signature Hero',
			content = {table.concat(heroIcons, '&nbsp;')},
		})
	elseif id == 'region' then return {}
	elseif id == 'role' then
		return {
			Cell{name = 'Role(s)', content = {caller.role.display, caller.role2.display}}
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

	-- store signature heroes with standardized name
	for heroIndex, hero in ipairs(self:getAllArgsForBase(args, 'hero')) do
		lpdbData.extradata['signatureHero' .. heroIndex] = HeroNames[hero:lower()]
	end

	lpdbData.region = String.nilIfEmpty(Region.name{region = args.region, country = args.country})

	return lpdbData
end

return CustomPlayer
