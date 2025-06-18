---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Image = require('Module:Image')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = Lua.import('Module:Widget/Infobox/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center
local Table = Widgets.Table

---@class UnderlordsCharacterInfobox: CharacterInfobox
---@field alliances string[]
---@field statsByLevel table[]
local CustomCharacter = Class.new(Character)
---@class UnderlordsCharacterInfoboxWidgetInjector: WidgetInjector
---@field caller UnderlordsCharacterInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character.args.informationType = 'Hero'
	character:setWidgetInjector(CustomInjector(character))

	character.alliances = character:getAllArgsForBase(character.args, 'alliance')
	character.statsByLevel = character:_getStatsByLevel(character.args)

	return character:createInfobox()
end

---@private
---@param args table
---@return table[]
function CustomCharacter:_getStatsByLevel(args)
	return Array.map(Array.range(1, 3), function(level)
		return {
			health = args['health' .. level],
			mana = args['mana' .. level],
			dps = args['dps' .. level],
			dmgMin = tonumber(args['dmg-min' .. level]),
			dmgMax = tonumber(args['dmg-max' .. level]),
			atkspeed = args['atkspeed' .. level],
			movespeed = args['move' .. level],
			range = args['range' .. level],
			magicresit = args['magicres' .. level],
			armor = args['armor' .. level],
			hpRegen = args['hpregen' .. level],
		}
	end)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		local allianceIcon = function(alliance)
			local filename = 'Underlords_' .. alliance .. '_Alliance.png'
			return Image.display(filename, nil, {
				alt = alliance,
				link = alliance .. '_Alliance',
				size = 50,
			})
		end

		local stats = self.caller.statsByLevel
		local makeRow = function(title, stat)
			local getValue = function(level)
				if stat == 'damage' then
					return (stats[level].dmgMin or 0) .. '-' .. (stats[level].dmgMax or 0)
				end
				return stats[level][stat] or 0
			end
			return {
				title, getValue(1), getValue(2), getValue(3)
			}
		end

		Array.appendWith(widgets,
			Cell{name = 'Tier', content = {args.tier}},
			Title{children = 'Alliances'},
			Center{children = Array.interleave(Array.map(self.caller.alliances, allianceIcon), '&nbsp;')},
			Title{children = 'Level Changes'},
			Table{
				rows = {
					{'Level', '1', '2', '3'},
					makeRow('Health', 'health'),
					makeRow('Mana', 'mana'),
					makeRow('DPS', 'dps'),
					makeRow('Damage', 'damage'),
					makeRow('Attack Speed', 'atkspeed'),
					makeRow('Move Speed', 'movespeed'),
					makeRow('Attack Range', 'range'),
					makeRow('Magic Resist', 'magicresit'),
					makeRow('Armor', 'armor'),
					makeRow('Health Regen', 'hpRegen'),
				},
				options = {
					columns = 4,
					columnOptions = {
						[1] = {classes = {'infobox-cell-3', 'infobox-description'}},
						[2] = {classes = {'infobox-cell-4-5', 'infobox-center'}},
						[3] = {classes = {'infobox-cell-4-5', 'infobox-center'}},
						[4] = {classes = {'infobox-cell-4-5', 'infobox-center'}},
					},
				}
			}
		)
	end

	return widgets
end

---@param lpdbData table
---@param args table
function CustomCharacter:addToLpdb(lpdbData, args)
	local extradata = lpdbData.extradata
	extradata.name = lpdbData.name
	extradata.tier = args.tier
	extradata.alliance = self.alliances
	local makeStatsArray = function(stat)
		return Array.map(self.statsByLevel, function(levelStats)
			return levelStats[stat] or 0
		end)
	end

	extradata.health = makeStatsArray('health')
	extradata.mana = makeStatsArray('mana')
	extradata.dps = makeStatsArray('dps')
	extradata['minimum damage'] = makeStatsArray('dmgMin')
	extradata['maximum damage'] = makeStatsArray('dmgMax')
	extradata['attack speed'] = makeStatsArray('atkspeed')
	extradata['move speed'] = makeStatsArray('movespeed')
	extradata['attack range'] = makeStatsArray('range')
	extradata['magic resistance'] = makeStatsArray('magicresit')
	extradata['armor'] = makeStatsArray('armor')
	extradata['health regeneration'] = makeStatsArray('hpRegen')

	return lpdbData
end

return CustomCharacter
