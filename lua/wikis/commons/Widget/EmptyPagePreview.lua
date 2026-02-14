---
-- @Liquipedia
-- page=Module:Widget/EmptyPagePreview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = require('Module:Class')
local Namespace = Lua.import('Module:Namespace')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local EmptyTeamPagePreview = Lua.import('Module:Widget/EmptyPagePreview/Team')
local EmptyPersonPagePreview = Lua.import('Module:Widget/EmptyPagePreview/Person')
local Widget = require('Module:Widget')

---@class EmptyPagePreview: Widget
---@operator call(table): EmptyPagePreview
local EmptyPagePreview = Class.new(Widget)


---@return Widget?
function EmptyPagePreview:render()
	if not Namespace.isMain() then
		return
	end

	if TeamTemplate.exists(self.props.pageName or mw.title.getCurrentTitle().prefixedText) then
		return EmptyTeamPagePreview(self.props)
	end

	return EmptyPersonPagePreview(self.props)
end

return EmptyTeamPagePreview
