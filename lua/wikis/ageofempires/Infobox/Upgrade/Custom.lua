---
-- @Liquipedia
-- page=Module:Infobox/Upgrade/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')

local Upgrade = Lua.import('Module:Infobox/Upgrade')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title
local AgeIcon = Lua.import('Module:Widget/Infobox/AgeIcon')
local ExpansionIcon = Lua.import('Module:Widget/Infobox/ExpansionIcon')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

local AGE_TITLE = {
	['feudalage'] = 'Researched at age',
	default = 'Starting age',
}
AGE_TITLE.castleage = AGE_TITLE.feudalage
AGE_TITLE.imperialage = AGE_TITLE.feudalage

---@class AoeUpgradeInfobox: UpgradeInfobox
local CustomUpgrade = Class.new(Upgrade)

---@class AoeUpgradeInfoboxWidgetInjector: WidgetInjector
---@field caller AoeUpgradeInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUpgrade.run(frame)
	local upgrade = CustomUpgrade(frame)
	upgrade.args.informationType = 'Tech'
	upgrade:setWidgetInjector(CustomInjector(upgrade))
	return upgrade:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args  = self.caller.args
	if id == 'introduced' then
		---@param introduced string?
		---@return (string|Widget)[]?
		local introducedDisplay = function(introduced)
			if not introduced then return end
			return {
				ExpansionIcon{expansion = introduced},
				HtmlWidgets.I{children = {Link{link = introduced}}},
			}
		end
		return {
			Cell{name = 'First introduced', children = introducedDisplay(args.introduced), options = {separator = ' '}},
		}
	elseif id == 'research' then
		local civilizations = args.civilizations or args.civs

		-- args.name usage is correct (copied from template code!)
		local ageTitle = AGE_TITLE[(args.name or ''):lower():gsub(' ', '')] or AGE_TITLE.default
		local ageDisplay = function(age)
			if not age then return end
			return {
				AgeIcon{age = age},
				Link{link = age .. ' Age'},
			}
		end
		return Array.extend(
			{
				Cell{name = 'Civilizations', children = {civilizations}},
				Cell{name = ageTitle, children = ageDisplay(args.age), options = {separator = ' '}},
			},
			widgets
		)
	elseif id == 'cost' then
		return {
			Cell{name = 'Cost', children = Array.append({},
				args.food and (args.food .. ' [[Food]]') or nil,
				args.wood and (args.wood .. ' [[Wood]]') or nil,
				args.gold and (args.gold .. ' [[Gold]]') or nil,
				args.stone and (args.stone .. ' [[Stone]]') or nil
			)},
			Cell{name = 'Research time', children = {args.time}},
		}
	elseif id == 'effect' then
		local makeDescription = function(text, subTitle)
			if not text then return end
			return {
				Title{children = {
					'Effect',
					' ',
					HtmlWidgets.Small{children = {
						'(',
						subTitle,
						')'
					}}
				}},
				Center{children = {text}}
			}
		end
		return Array.extend({},
			makeDescription(args.effect, 'ingame description'),
			makeDescription(args['effect-specified'], 'specified')
		)
	end

	return widgets
end

---@return string
function CustomUpgrade:chronologyTitle()
	return 'Connected Techs'
end

---@param args table
---@return string[]
function CustomUpgrade:getWikiCategories(args)
	return {'Technologies (' .. Game.name{game = args.game} .. ')'}
end

return CustomUpgrade
