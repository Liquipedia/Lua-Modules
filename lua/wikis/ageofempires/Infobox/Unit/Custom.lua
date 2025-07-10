---
-- @Liquipedia
-- page=Module:Infobox/Unit/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Chronology = Widgets.Chronology
local Title = Widgets.Title
local AgeIcon = Lua.import('Module:Widget/Infobox/AgeIcon')
local ExpansionIcon = Lua.import('Module:Widget/Infobox/ExpansionIcon')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class AgeOfEmpiresUnitInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
---@class AgeOfEmpiresUnitInfoboxWidgetInjector: WidgetInjector
---@field caller AgeOfEmpiresUnitInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit:setWidgetInjector(CustomInjector(unit))

	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	---@param input string?
	---@param label string
	---@return Widget?
	local costDisplay = function(input, label)
		if not input then return end
		return HtmlWidgets.Fragment{children = {
			input,
			' ',
			Link{link = label},
		}}
	end

	if id == 'custom' then
		local types = Array.map(caller:getAllArgsForBase(args, 'type'), function(unitType)
			return Link{link = unitType}
		end)

		local hasUpgradeSection = Logic.isNotEmpty(args['up food'])
			or Logic.isNotEmpty(args['up wood'])
			or Logic.isNotEmpty(args['up gold'])
			or Logic.isNotEmpty(args['up stone'])
			or Logic.isNotEmpty(args['up time'])

		return WidgetUtil.collect(
			Title{children = {mw.text.listToText(types, ', ', ' and ')}},
			Cell{name = 'Range', children = {args.range}},
			Cell{name = 'Restore time', children = {args.rest}},
			Cell{name = 'Conversion time', children = {args.convtime}},
			Cell{name = 'Minimum range', children = {args['min range']}},
			Cell{
				name = HtmlWidgets.Abbr{
					title = 'Number of frames between clicking to attack until the attack is followed through',
					children = {'Frame delay'},
				},
				children = {args['frame delay']},
			},
			Cell{name = 'Projectile Speed', children = {args['projectile speed']}},
			Cell{name = 'Accuracy', children = {args.accuracy and (args.accuracy .. '%') or nil}},
			Cell{name = 'Training time', children = {args.time}},
			Cell{name = 'Hit points', children = {args['hit points']}},

			Cell{name = 'Speed', children = {args['movement speed']}},
			Cell{name = 'Line of sight', children = WidgetUtil.collect(
				args['line of sight'],
				args.darkLos and {
					AgeIcon{age = 'Dark'},
					' ',
					args.darkLos,
				} or nil,
				args.feudalLos and {
					AgeIcon{age = 'Feudal'},
					' ',
					args.feudalLos,
				} or nil,
				args.castleLos and {
					AgeIcon{age = 'Castle'},
					' ',
					args.castleLos,
				} or nil,
				args.imperialLos and {
					AgeIcon{age = 'Imperial'},
					' ',
					args.imperialLos,
				} or nil
			)},
			hasUpgradeSection and Title{children = {'Upgrade Information'}} or nil,
			Cell{name = 'Upgrade cost', children = WidgetUtil.collect(
				costDisplay(args['up food'], 'Food'),
				costDisplay(args['up wood'], 'Wood'),
				costDisplay(args['up gold'], 'Gold'),
				costDisplay(args['up stone'], 'Stone')
			)},
			Cell{name = 'Research time', children = {args['up time']}},
			Cell{name = 'Required', children = {args.required}, options = {makeLink = true}},
			Chronology{
				title = 'Connected Units',
				links = Table.filterByKey(args, function(key)
					return type(key) == 'string' and (key:match('^previous%d?$') ~= nil or key:match('^next%d?$') ~= nil)
				end)
			}
		)
	elseif id == 'builtfrom' then
		return {
			Cell{name = 'First introduced', children = {
				ExpansionIcon{expansion = args.introduced},
				HtmlWidgets.I{children = {Link{link = args.introduced}}},
			}, options = {separator = ' '}},
			Cell{name = 'Civilizations', children = {args.civilizations or args.civs}},
			Cell{name = 'Available in', children = {
				AgeIcon{age = args.age},
				Link{link = args.age},
				args.age2,
			}, options = {separator = ' '}},
			Cell{
				name = 'Trained at',
				children = caller:getAllArgsForBase(args, 'builtfrom'),
				options = {makeLink = true, separator = ' '}
			},
		}
	elseif id == 'cost' then
		return {Cell{name = 'Cost', children = WidgetUtil.collect(
			costDisplay(args.food, 'Food'),
			costDisplay(args.wood, 'Wood'),
			costDisplay(args.gold, 'Gold'),
			costDisplay(args.stone, 'Stone')
		)}}
	elseif id == 'type' then return {}
	elseif id == 'attack' then
		return {
			Cell{name = 'Attack damage', children = {args.attack}},
			Cell{name = 'Attack type', children = {args['attack type']}},
			Cell{
				name = 'Hidden Attack bonuses:<br>(vs armor classes)',
				children = {args['attack bonus']},
				options = {suppressColon = true}
			},
			Cell{
				name = HtmlWidgets.Abbr{
					title = 'Reload time (in seconds)',
					children = {'Rate of Fire'},
				},
				children = {args['rate of fire']},
			},
			Cell{name = 'Blast Radius', children = {args['blast radius']}},
		}
	elseif id == 'defense' then
		return {
			Cell{name = 'Garrison', children = {args.garrison}},
			Cell{name = 'Armor', children = WidgetUtil.collect(
				args['melee armor'] and (args['melee armor'] .. ' melee') or nil,
				args['pierce armor'] and (args['pierce armor'] .. ' pierce') or nil
			)},
			Cell{
				name = '[[Armor class|Armor classes]]:<br><small>(besides [[Pierce armor (armor class)|Pierce armor]], '
					.. '[[Melee armor (armor class)|Melee armor]], [[Anti-Leitis (armor class)|Anti-Leitis]])</small>',
				children = {args['armor classes']},
				options = {suppressColon = true},
			},
		}
	end

	return widgets
end

---@param args table
---@return string[]
function CustomUnit:getWikiCategories(args)
	return {'Units (' .. Game.name{game = args.game} .. ')' }
end

return CustomUnit
