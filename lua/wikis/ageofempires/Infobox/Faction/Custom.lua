---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Infobox/Faction/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local Page = require('Module:Page')

local Injector = Lua.import('Module:Widget/Injector')
local FactionInfobox = Lua.import('Module:Infobox/Faction')

local Widgets = require('Module:Widget/All')
local WidgetsHtml = require('Module:Widget/Html/All')
local Cell = Widgets.Cell
local Fragment = WidgetsHtml.Fragment
local Image = require('Module:Widget/Image/Icon/Image')

---@class CustomFactionInfobox: FactionInfobox
---@field game string
local CustomFactionInfobox = Class.new(FactionInfobox)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomFactionInfobox.run(frame)
	local infobox = CustomFactionInfobox(frame)

	infobox.args.informationType = 'Civilization'
	infobox.args.lpdbType = 'civ'

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
	---@type CustomFactionInfobox
	local caller = self.caller
	local args = caller.args

	if id == 'release' then
		return {
			args.introduced and Cell{
				name = 'First introduced',
				content = {
					Fragment{
						caller:_makeIntroducedIcon(args.introduced),
						Page.makeInternalLink(args.introduced)
					}
				}
			} or nil
		}
	elseif id == 'custom' then
		Array.appendWith(widgets,
			Cell{
				name = Page.makeInternalLink('Architectural Style', 'Architectures (building styles)'),
				content = {args.architecture}
			},
			Cell{name = 'Continent', content = {args.continent}},
			Cell{
				name = Page.makeInternalLink('Ingame classification', 'Civilizations classification'),
				content = Array.map(
					caller:getAllArgsForBase(args, 'type'),
					function (t)
						return t .. ' civilization'
					end
				)
			},
			Cell{
				name = 'Unique buildings',
				content = Array.map(
					caller:getAllArgsForBase(args, 'building'),
					Page.makeInternalLink
				)
			},
			Cell{
				name = 'Unique units',
				content = Array.map(
					caller:getAllArgsForBase(args, 'unit'),
					Page.makeInternalLink
				)
			},
			args.tech1 and Cell{
				name = 'Unique technologies',
				content = {
					Fragment{
						caller:_makeAgeIcon('Castle'),
						Page.makeInternalLink(args.tech1)
					},
					Fragment{
						caller:_makeAgeIcon('Imperial'),
						Page.makeInternalLink(args.tech2)
					}
				}
			}
		)
	end

	return widgets
end

---@param introduced string?
---@return Widget?
function CustomFactionInfobox:_makeIntroducedIcon(introduced)
	if self.game ~= 'Ae of Empires II' then
		return
	end
	return Image{
		imageLight = 'Aoe2 ' .. introduced .. ' Icon.png',
		size = '18',
		link = introduced
	}
end

---@param age string?
---@return Widget?
function CustomFactionInfobox:_makeAgeIcon(age)
	if self.game ~= 'Age of Empires II' then
		return
	end
	return Image{
		imageLight = age .. ' Age AoE2 logo.png',
		size = '18',
		link = age .. ' Age'
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
		'Civilization',
		self.game and ('Civilization ' .. (self.game)) or nil
	}
end

---@param args table
---@return string?
function CustomFactionInfobox:nameDisplay(args)
	return Game.icon{game = self.game, size = '32px'} .. '&nbsp;' .. self.name
end

return CustomFactionInfobox
