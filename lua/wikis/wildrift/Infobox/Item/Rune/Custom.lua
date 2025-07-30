---
-- @Liquipedia
-- page=Module:Infobox/Item/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Item = Lua.import('Module:Infobox/Item')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class WildriftItemInfoboxRune: ItemInfobox
local CustomItem = Class.new(Item)
---@class WildriftItemInfoboxRuneInjector: WidgetInjector
---@field caller WildriftItemInfoboxRune
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomItem.run(frame)
	local item = CustomItem(frame)
	item:setWidgetInjector(CustomInjector(item))

	return item:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'info' then
		return Array.append({},
			args.runename and Center{
				children = {
					Template.safeExpand(mw.getCurrentFrame(), 'RuneIcons', {args.runename}),
					HtmlWidgets.Br{},
					args.runetext,
				},
			} or nil,
			Title{children = args.informationType .. ' Information'}
		)
	elseif id == 'custom' then
		return WidgetUtil.collect(
			Cell{name = 'Path', content = {args.path}},
			Cell{name = 'Slot', content = {args.slot}},
			Array.map(caller:getAllArgsForBase(args, 'description'), function(desc)
				return Center{children = {desc}}
			end),
			Cell{name = 'Cooldown', content = {args.cooldown}},
			Cell{name = 'Account level', content = {args.level}}
		)
	end

	return widgets
end

---@param args table
---@return string[]
function CustomItem:getWikiCategories(args)
	if not Namespace.isMain() then return {} end

	return {'Runes'}
end

---@param args table
---@return string?
function CustomItem:nameDisplay(args)
	return args.runename or self.name
end

return CustomItem
