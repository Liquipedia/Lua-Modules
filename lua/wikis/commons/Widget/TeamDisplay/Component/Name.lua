---
-- @Liquipedia
-- page=Module:Widget/TeamDisplay/Component/Name
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local Span = HtmlWidgets.Span

---@class TeamNameDisplayParameters
---@field additionalClasses string[]?
---@field displayName string?
---@field noLink boolean?
---@field page string?

---@class TeamNameDisplay: Widget
---@operator call(TeamNameDisplayParameters): TeamNameDisplay
---@field props TeamNameDisplayParameters
local TeamNameDisplay = Class.new(Widget)

---@return Widget?
function TeamNameDisplay:render()
	local displayName = self.props.displayName
	if String.isEmpty(displayName) then return end
	local page = self.props.page
	return Span{
		classes = Array.extend({ 'team-template-text' }, self.props.additionalClasses),
		children = {
			self.props.noLink and displayName or Link{
				children = displayName,
				link = page
			}
		}
	}
end

return TeamNameDisplay
