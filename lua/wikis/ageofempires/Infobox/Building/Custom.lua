---
-- @Liquipedia
-- page=Module:Infobox/Building/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Injector = Lua.import('Module:Widget/Injector')
local Building = Lua.import('Module:Infobox/Building')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Chronology = Widgets.Chronology
local Title = Widgets.Title
local AgeIcon = Lua.import('Module:Widget/Infobox/AgeIcon')
local ExpansionIcon = Lua.import('Module:Widget/Infobox/ExpansionIcon')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Image = require('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class AoEBuildingInfobox: BuildingInfobox
local CustomBuilding = Class.new(Building)
---@class AoEBuildingInfoboxInjector: WidgetInjector
---@field caller AoEBuildingInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomBuilding.run(frame)
	local building = CustomBuilding(frame)
	building:setWidgetInjector(CustomInjector(building))

	return building:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'cost' then
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

		return {
			Cell{name = 'Cost', content = WidgetUtil.collect(
				costDisplay(args['food'], 'Food'),
				costDisplay(args['wood'], 'Wood'),
				costDisplay(args['gold'], 'Gold'),
				costDisplay(args['stone'], 'Stone')
			)},
			Cell{name = 'Construction time', children = {args.time}},
		}
	elseif id == 'custom' then
		local types = Array.map(caller:getAllArgsForBase(args, 'type'), function(unitType)
			return tostring(Link{link = unitType})
		end)

		local ageIconWithText = function(keyPrefix, age)
			local key = keyPrefix .. ' ' .. age
			if Logic.isEmpty(args[key]) then return end
			return HtmlWidgets.Fragment{
				children = {
					AgeIcon{age = age},
					' ',
					args[key],
				}
			}
		end

		return {
			Cell{name = 'First introduced', children = {
				ExpansionIcon{expansion = args.introduced},
				HtmlWidgets.I{children = {Link{link = args.introduced}}},
			}, options = {separator = ' '}},
			Cell{name = 'Civilizations', children = {args.civilizations}},
			Cell{name = 'Available in', children = {
				AgeIcon{age = args.age},
				Link{link = args.age and (args.age .. ' Age') or nil},
				args.age2,
			}, options = {separator = ' '}},
			Cell{name = 'Use', children = {args.use}},
			Logic.isNotEmpty(types) and Title{children = {mw.text.listToText(types, ', ', ' and ') .. ' unit'}} or nil,
			Cell{name = 'Required building', children = {args['required building']}},
			Cell{name = 'Required technologie', children = {args['required tech']}},
			Cell{name = 'Size', children = {args.size}},
			Cell{name = Link{link = 'Hit Points'}, children = {args['hit points']}},
			Cell{name = 'Hit points', children = WidgetUtil.collect(
				ageIconWithText('hit', 'dark'),
				ageIconWithText('hit', 'feudal'),
				ageIconWithText('hit', 'castle'),
				ageIconWithText('hit', 'imperial')
			)},
			Cell{
				name = HtmlWidgets.Abbr{title = 'Number of units that can be garrisoned inside the building', children = {'Garrison'}},
				children = {args.garrison and (args.garrison .. ' units') or nil}
			},
			Cell{
				name = HtmlWidgets.Fragment{
					children = {
						Link{link = 'Armor class'},
						'es:',
						HtmlWidgets.Br{},
						HtmlWidgets.Small{
							children = {
								'besides ',
								Link{link = 'Pierce armor (armor class)', children = {'Pierce armor'}},
								', ',
								Link{link = 'Melee armor (armor class)', children = {'Melee armor'}},
								', ',
								Link{link = 'Anti-Leitis (armor class)', children = {'Anti-Leitis'}},
							}
						}
					}
				},
				options = {suppressColon = true},
				children = {args['armor classes']}
			},
			Cell{name = Link{link = 'Melee armor'}, children = {args['melee armor']}},
			Cell{name = Link{link = 'Pierce armor'}, children = {args['pierce armor']}},
			Cell{name = 'Melee armor', children = WidgetUtil.collect(
				ageIconWithText('melee', 'dark'),
				ageIconWithText('melee', 'feudal'),
				ageIconWithText('melee', 'castle'),
				ageIconWithText('melee', 'imperial')
			)},
			Cell{name = 'Pierce armor', children = WidgetUtil.collect(
				ageIconWithText('pierce', 'dark'),
				ageIconWithText('pierce', 'feudal'),
				ageIconWithText('pierce', 'castle'),
				ageIconWithText('pierce', 'imperial')
			)},



			Cell{name = 'Use', children = {args.use}},
			Cell{name = 'Use', children = {args.use}},
			Cell{name = 'Use', children = {args.use}},
			Cell{name = 'Use', children = {args.use}},
			Cell{name = 'Use', children = {args.use}},
			Cell{name = 'Use', children = {args.use}},
			Cell{name = 'Use', children = {args.use}},
			Cell{name = 'Use', children = {args.use}},
			Cell{name = 'Use', children = {args.use}},
		}
	end

	return widgets
end

---@param args table
---@return string[]
function CustomBuilding:getWikiCategories(args)
	if args.civilizations == 'All' then
		return {'Buildings (Age of Empires II)'}
	end
	return {'Unique Buildings (Age of Empires II)'}
end

return CustomBuilding
