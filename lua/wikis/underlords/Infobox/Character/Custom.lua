---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = require('Module:Widget/Infobox/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center
local Table = Widgets.Table

local AutoInlineIcon = Lua.import('Module:AutoInlineIcon')

---@class UnderlordsCharacterInfobox: CharacterInfobox
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
	return character:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		local alliances = self.caller:getAllArgsForBase(args, 'alliance')
		local statsByLevel = Array.map(Array.range(1, 3), function(level)
			return {
				health = args['health' .. level],
				dps = args['dps' .. level],
				dpsMin = args['dps-min' .. level],
				dpsMax = args['dps-max' .. level],
				atkspeed = args['atkspeed' .. level],
				movespeed = args['move' .. level],
				range = args['range' .. level],
				magicresit = args['magicres' .. level],
				armor = args['armor' .. level],
				hpRegen = args['hpregen' .. level],
			}
		end)

		local makeRow = function(title, stat)
			return {
				title, statsByLevel[1][stat], statsByLevel[2][stat], statsByLevel[3][stat]
			}
		end

		Array.appendWith(widgets,
			Cell{name = 'Tier', content = {args.tier}},
			Title{children = 'Alliances'},
			Center{children = {alliances}}, -- TODO map to images
			Title{children = 'Level Changes'},
			Table{
				rows = {
					{
						'Level', '1', '2', '3' -- TODO Icons
					},
					{
						makeRow('Health', 'health'),
					},
					{
						makeRow('DPS', 'dps'),
					},
					{
						makeRow('Damage', 'atkspeed'),-- TODO how should this be calculated?
					},
					{
						makeRow('Attack Speed', 'atkspeed'),
					},
					{
						makeRow('Move Speed', 'movespeed'),
					},
					{
						makeRow('Attack Range', 'range'),
					},
					{
						makeRow('Magic Resist', 'magicresit'),
					},
					{
						makeRow('Armor', 'armor'),
					},
					{
						makeRow('Health Regen', 'hpRegen'),
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
	-- TODO: Bunch of data to store

	return lpdbData
end

return CustomCharacter
