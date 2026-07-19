---
-- @Liquipedia
-- page=Module:Widget/Match/Page/AdditionalSection
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@class MatchPageAdditionalSectionParameters
---@field header? Renderable|Renderable[]
---@field css? table<string, (string|number)?>
---@field bodyClasses? string[]
---@field children? Renderable|Renderable[]

---@param props MatchPageAdditionalSectionParameters
---@return HtmlNode?
local function MatchPageAdditionalSection(props)
	if Logic.isDeepEmpty(props.children) then return end
	return Div{
		classes = {'match-bm-match-additional-section'},
		css = props.css,
		children = {
			Div{
				classes = { 'match-bm-match-additional-section-header' },
				children = props.header
			},
			Div{
				classes = Array.extend('match-bm-match-additional-section-body', props.bodyClasses),
				children = props.children
			},
		}
	}
end

return Component.component(MatchPageAdditionalSection)
