---
-- @Liquipedia
-- page=Module:Widget/Basic/Link
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class LinkComponentProps
---@field children? Renderable|Renderable[]
---@field link? string
---@field linktype? 'internal'|'external'

local defaultProps = {
	linktype = 'internal',
}

---@param props LinkComponentProps
---@return Renderable[]?
local function Link(props)
	if not props.link then
		return
	end
	if props.linktype == 'external' then
		return WidgetUtil.collect(
			'[',
			(props.link:gsub(' ', '%%20')),
			' ',
			props.children,
			']'
		)
	end

	return WidgetUtil.collect(
		'[[',
		props.link,
		'|',
		props.children or props.link,
		']]'
	)
end

return Component.component(Link, defaultProps)
