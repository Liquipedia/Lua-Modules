---
-- @Liquipedia
-- page=Module:Widget/ExternalMedia/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')

local Widget = Lua.import('Module:Widget')
local ExternalMediaLinkDisplay = Lua.import('Module:Widget/ExternalMedia/Link')
local Link = Lua.import('Module:Widget/Basic/Link')
local UnorderedList = Lua.import('Module:Widget/List/Unordered')
local WidgetUtil = Lua.import('Module:Widget/Util')

local NON_BREAKING_SPACE = '&nbsp;'

---@class ExternalMediaListDisplay: Widget
---@operator call(table): ExternalMediaListDisplay
---@field props {data: externalmedialink[], showSubjectTeam: boolean?, showUsUk: boolean?, subject: string?}
local ExternalMediaListDisplay = Class.new(Widget)

---@return Widget?
function ExternalMediaListDisplay:render()
	local data = self.props.data
	if Logic.isEmpty(data) then
		return
	end
	return UnorderedList{children = Array.map(data, function (item)
		return self:_createListElement(item)
	end)}
end

---@private
---@param item externalmedialink
---@return (string|Widget)[]
function ExternalMediaListDisplay:_createListElement(item)
	return WidgetUtil.collect(
		{
			mw.text.nowiki('['),
			Link{link = 'Data:' .. item.pagename, children = 'e'},
			mw.text.nowiki(']'),
			NON_BREAKING_SPACE
		},
		self.props.showSubjectTeam and self:_displayTeam(item.date) or nil,
		ExternalMediaLinkDisplay{data = item, showUsUk = self.props.showUsUk}
	)
end

---Displays the subject's team for a given External Media Link
---@param date string
---@return Widget?
function ExternalMediaListDisplay:_displayTeam(date)
	local subject = self.props.subject
	if Logic.isEmpty(subject) then
		return
	end
	---@cast subject -nil
	local _, team = PlayerExt.syncTeam(subject, nil, {date = date})
	if not team then
		return
	end
	return OpponentDisplay.InlineTeamContainer{template = team, date = date, style = 'icon'}
end

return ExternalMediaListDisplay