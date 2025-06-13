---
-- @Liquipedia
-- page=Module:Widget/MainPage/InMemoryOf
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')

local Condition = Lua.import('Module:Condition')
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Fragment = HtmlWidgets.Fragment
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class InMemoryOfWidget: Widget
---@field props {pageLink: string}
---@operator call(table): InMemoryOfWidget
local InMemoryOfWidget = Class.new(Widget)

---@private
---@return {firstName: string?, lastName: string?, id: string?}
function InMemoryOfWidget:_loadFromLPDB()
	local pageLink = self.props.pageLink
	assert(String.isNotEmpty(pageLink), 'Empty page link')
	local player = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = tostring(
			ConditionNode(ColumnName('pagename'), Comparator.eq, Page.pageifyLink(pageLink))
		),
		query = 'name, id, nationality, extradata, deathdate',
		limit = 1,
	})[1]
	assert(player, 'Player with pageLink="' .. pageLink .. '" not found')
	assert(player.deathdate ~= DateExt.defaultDate, 'Widget cannot be used with people that are alive')

	local extradata = player.extradata or {}
	local nameArray = String.isNotEmpty(player.name)
		and mw.text.split(player.name, ' ')
		or {}

	return {
		firstName = extradata.firstname or nameArray[1],
		lastName = extradata.lastname or (#nameArray > 1 and nameArray[#nameArray] or nil),
		id = player.name ~= player.id and player.id or nil
	}
end

---@return Widget
function InMemoryOfWidget:render()
	local nameData = self:_loadFromLPDB()

	return HtmlWidgets.Div{
		classes = { 'sadbox' },
		children = {
			Link {
				link = self.props.pageLink,
				children = Fragment{children = Array.interleave(
					WidgetUtil.collect(
						'In memory of',
						nameData.firstName,
						nameData.id and Fragment{children = {
							'"',
							HtmlWidgets.Strong{
								children = { nameData.id }
							},
							'"'
						}} or nil,
						nameData.lastName,
						'🖤'
					),
					' '
				)}
			}
		}
	}
end

return InMemoryOfWidget
