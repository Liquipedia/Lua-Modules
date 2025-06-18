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
local Variables = Lua.import('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Item = Lua.import('Module:Infobox/Item')

local HtmlWidgets = require('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local VERSION_DATA = {
	['4.5'] = {version = '4.5', date = '2018-07-03'},
	['5.0'] = {version = '5.0', date = '2018-07-17'},
	['5.10'] = {version = '5.10', date = '2018-07-24'},
	['5.10 (Content Update)'] = {version = '5.10 (Content Update)', date = '2018-07-31'},
	['5.20'] = {version = '5.20', date = '2018-08-07'},
	['5.21'] = {version = '5.21', date = '2018-08-15'},
	['5.30'] = {version = '5.30', date = '2018-08-23'},
	['5.30 (Content Update)'] = {version = '5.30 (Content Update)', date = '2018-08-28'},
	['5.40'] = {version = '5.40', date = '2018-09-06'},
}
VERSION_DATA['2018-07-03'] = VERSION_DATA['4.5']
VERSION_DATA['2018-07-17'] = VERSION_DATA['5.0']
VERSION_DATA['2018-07-24'] = VERSION_DATA['5.10']
VERSION_DATA['2018-07-31'] = VERSION_DATA['5.10 (Content Update)']
VERSION_DATA['2018-08-07'] = VERSION_DATA['5.20']
VERSION_DATA['2018-08-15'] = VERSION_DATA['5.21']
VERSION_DATA['2018-08-23'] = VERSION_DATA['5.30']
VERSION_DATA['2018-08-28'] = VERSION_DATA['5.30 (Content Update)']
VERSION_DATA['2018-09-06'] = VERSION_DATA['5.40']

---@class FortniteItemInfobox: ItemInfobox
local CustomItem = Class.new(Item)
---@class FortniteItemInfoboxInjector
---@field caller FortniteItemInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomItem.run(frame)
	local item = CustomItem(frame)
	local args = item.args
	args.release = CustomItem._getVersionDisplay(args.release --[[@as string?]])
	item.rarities = item:getAllArgsForBase(args, 'rarity')
	if Logic.readBool(args['generate description']) then
		item:_description()
	end

	item:setWidgetInjector(CustomInjector(item))

	return item:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		table.insert(widgets, Cell{name = 'Removed', children = {CustomItem._getVersionDisplay(args.removed)}})
	end

	return widgets
end

---@private
---@param input string?
---@return Widget|string?
function CustomItem._getVersionDisplay(input)
	local versionData = VERSION_DATA[input]
	if not versionData then return input end

	return HtmlWidgets.Fragment{
		children = {
			Link{
				link = 'Version ' .. versionData.version,
				children = {versionData.version},
			},
			'&nbsp;',
			HtmlWidgets.I{
				children = {HtmlWidgets.Small{
					children = {
						'(',
						versionData.date,
						')',
					}
				}}
			}
		}
	}
end

---@private
function CustomItem:_description()
	local description = '<b>' .. self.name .. '</b> is an item that is available in  '
		.. mw.text.listToText(self.rarities, ', ', ' and ')
		.. (#self.rarities > 1 and 'rarities' or 'rarity')

	Variables.varDefine('description', description)
end

---@param args table
---@return string[]
function CustomItem:getWikiCategories(args)
	return Array.map(self.rarities, function(rarity)
		return rarity .. ' Items'
	end)
end

return CustomItem
