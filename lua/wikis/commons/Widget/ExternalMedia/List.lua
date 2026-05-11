---
-- @Liquipedia
-- page=Module:Widget/ExternalMedia/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')

local Component = Lua.import('Module:Widget/Component')
local ExternalMediaLinkDisplay = Lua.import('Module:Widget/ExternalMedia/Link')
local Link = Lua.import('Module:Widget/Basic/Link')
local ListWidgets = Lua.import('Module:Widget/List')
local WidgetUtil = Lua.import('Module:Widget/Util')

local NON_BREAKING_SPACE = '&nbsp;'

---@class ExternalMediaListDisplayProps
---@field data externalmedialink[]
---@field showSubjectTeam boolean?
---@field showUsUk boolean?
---@field subject string?

local ExternalMediaListDisplay = {}

---@param props ExternalMediaListDisplayProps
---@return Widget?
function ExternalMediaListDisplay.render(props)
	local data = props.data
	if Logic.isEmpty(data) then
		return
	end
	return ListWidgets.Unordered{
		children = Array.map(data, FnUtil.curry(ExternalMediaListDisplay._createListElement, props))
	}
end

---@private
---@param props ExternalMediaListDisplayProps
---@param item externalmedialink
---@return Renderable[]
function ExternalMediaListDisplay._createListElement(props, item)
	return WidgetUtil.collect(
		{
			mw.text.nowiki('['),
			Link{link = 'Data:' .. item.pagename, children = 'e'},
			mw.text.nowiki(']'),
			NON_BREAKING_SPACE
		},
		props.showSubjectTeam and ExternalMediaListDisplay._displayTeam(props.subject, item.date) or nil,
		ExternalMediaLinkDisplay{data = item, showUsUk = props.showUsUk}
	)
end

---Displays the subject's team for a given External Media Link
---@param subject string?
---@param date string
---@return VNode?
function ExternalMediaListDisplay._displayTeam(subject, date)
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

return Component.component(ExternalMediaListDisplay.render)
