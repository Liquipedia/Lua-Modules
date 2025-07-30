---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterWinLoss = Lua.import('Module:CharacterWinLoss')
local Class = Lua.import('Module:Class')
local ClassIcon = Lua.import('Module:ClassIcon', { loadData = true })
local Logic = Lua.import('Module:Logic')
local Math = Lua.import('Module:MathUtil')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')

local Character = Lua.import('Module:Infobox/Character')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local IconImageWidget = Lua.import('Module:Widget/Image/Icon/Image')
local Title = Widgets.Title
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class HOKHeroInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
---@class HOKHeroInfoboxWidgetInjector: WidgetInjector
---@field caller HOKHeroInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Hero'
	return character:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'role' then
		return {
            Cell{
				name = 'Lane',
				content = WidgetUtil.collect(
					self:_toCellContent('lane1'),
					self:_toCellContent('lane2')
				)
			},
			Cell{
				name = 'Role',
				content = WidgetUtil.collect(
					self:_toCellContent('role1'),
					self:_toCellContent('role2')
				)
			},
		}
	elseif id == 'custom' then
		return WidgetUtil.collect(
			self.caller:_getCustomCells()
		)
    end
	return widgets
end

---@param key string
---@return Widget?
function CustomInjector:_toCellContent(key)
	local args = self.caller.args
	if String.isEmpty(args[key]) then return end
	local iconData = ClassIcon[args[key]:lower()]
	return Logic.isNotEmpty(iconData) and HtmlWidgets.Fragment{
		children = {
			IconImageWidget{
				imageLight = iconData.icon,
				link = iconData.link
			},
			' ',
			iconData.displayName
		}
	} or nil
end

---@return Widget[]
function CustomCharacter:_getCustomCells()
	local args = self.args
	local widgets = {
		Center{children = {Page.makeExternalLink('Official Hero Page', args.page)}},
	}

	local wins, loses = CharacterWinLoss.run(args.name)
	if wins + loses == 0 then return widgets end

	local winPercentage = Math.round(wins * 100 / (wins + loses), 2)

	return Array.append(widgets,
		Title{children = 'Esports Statistics'},
		Center{children = {wins .. ' Wins : ' .. loses .. ' Loses (' .. winPercentage .. '%)'}}
	)
end

---@param lpdbData table
---@param args table
---@return table
function CustomCharacter:addToLpdb(lpdbData, args)
	lpdbData.extradata.lane1 = args.lane1
	lpdbData.extradata.lane2 = args.lane2
	lpdbData.extradata.role1 = args.role1
	lpdbData.extradata.role2 = args.role2

	return lpdbData
end

return CustomCharacter
