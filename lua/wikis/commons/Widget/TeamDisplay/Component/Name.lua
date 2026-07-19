---
-- @Liquipedia
-- page=Module:Widget/TeamDisplay/Component/Name
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local String = Lua.import('Module:StringUtils')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class TeamNameDisplayParameters
---@field additionalClasses string[]?
---@field displayName string?
---@field noLink boolean?
---@field page string?

---@param props TeamNameDisplayParameters
---@return VNode?
local function TeamNameDisplay(props)
	local displayName = props.displayName
	if String.isEmpty(displayName) then return end
	local page = props.page
	return Html.Span{
		classes = Array.extend({ 'team-template-text' }, props.additionalClasses),
		children = {
			props.noLink and displayName or Link{
				children = displayName,
				link = page
			}
		}
	}
end

return Component.component(TeamNameDisplay)
