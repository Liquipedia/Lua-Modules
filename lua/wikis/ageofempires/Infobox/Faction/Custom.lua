---
-- @Liquipedia
-- page=Module:Infobox/Faction/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')
local Page = Lua.import('Module:Page')

local Injector = Lua.import('Module:Widget/Injector')
local FactionInfobox = Lua.import('Module:Infobox/Faction')

local Widgets = Lua.import('Module:Widget/All')
local WidgetsHtml = Lua.import('Module:Widget/Html/All')
local Cell = Widgets.Cell
local Fragment = WidgetsHtml.Fragment
local AgeIcon = Lua.import('Module:Widget/Infobox/AoeAgeIcon')
local Image = Lua.import('Module:Widget/Image/Icon/Image')

---@class AoECustomFactionInfobox: FactionInfobox
---@field game string
local CustomFactionInfobox = Class.new(FactionInfobox)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return string
function CustomFactionInfobox.run(frame)
	local infobox = CustomFactionInfobox(frame)

	infobox.args.informationType = 'Civilization'

	local subpageText = mw.title.getCurrentTitle().subpageText
	infobox.game = Game.toIdentifier{
		game = infobox.args.game or subpageText
	}

	if infobox.game == subpageText then
		infobox.name = mw.title.getCurrentTitle().baseText
	end

	infobox:setWidgetInjector(CustomInjector(infobox))

	return infobox:createInfobox()
end

function CustomInjector:parse(id, widgets)
	---@type AoECustomFactionInfobox
	local caller = self.caller
	local args = caller.args

	if id == 'release' then
		return {
			args.introduced and Cell{
				name = 'First introduced',
				children = {
					Fragment{
						children = {
							caller:_makeIntroducedIcon(args.introduced),
							Page.makeInternalLink(args.introduced)
						}
					}
				}
			} or Fragment{}
		}
	elseif id == 'custom' then
		Array.appendWith(widgets,
			Cell{
				name = Page.makeInternalLink('Architectural Style', 'Architectures (building styles)'),
				children = {args.architecture}
			},
			Cell{name = 'Continent', children = {args.continent}},
			Cell{
				name = Page.makeInternalLink('Ingame classification', 'Civilizations classification'),
				children = Array.map(
					caller:getAllArgsForBase(args, 'type'),
					function (t)
						return t .. ' civilization'
					end
				)
			},
			Cell{
				name = 'Unique buildings',
				children = caller:getAllArgsForBase(args, 'building', {makeLink = true})
			},
			Cell{
				name = 'Unique units',
				children = caller:getAllArgsForBase(args, 'unit', {makeLink = true})
			},
			args.tech1 and Cell{
				name = 'Unique technologies',
				children = {
					Fragment{
						children = {
							AgeIcon{age = 'Castle', checkGame = true, game = caller.game},
							Page.makeInternalLink(args.tech1)
						}
					},
					Fragment{
						children = {
							AgeIcon{age = 'Imperial', checkGame = true, game = caller.game},
							Page.makeInternalLink(args.tech2)
						}
					}
				}
			}
		)
	end

	return widgets
end

---@param introduced string?
---@return Widget
function CustomFactionInfobox:_makeIntroducedIcon(introduced)
	if self.game ~= 'Age of Empires II' then
		return Fragment{}
	end
	return Image{
		imageLight = 'Aoe2 ' .. introduced .. ' Icon.png',
		size = '18',
		link = introduced
	}
end

---@param lpdbData table
---@param args table
---@return table
function CustomFactionInfobox:addToLpdb(lpdbData, args)
	lpdbData.extradata.game = self.game
	return lpdbData
end

---@param args table
---@return string[]
function CustomFactionInfobox:getWikiCategories(args)
	return {
		self.game and ('Civilization (' .. self.game .. ')') or nil
	}
end

---@param args table
---@return string?
function CustomFactionInfobox:nameDisplay(args)
	return Game.icon{game = self.game, size = '32px'} .. '&nbsp;' .. self.name
end

return CustomFactionInfobox
