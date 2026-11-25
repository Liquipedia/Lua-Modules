---
-- @Liquipedia
-- page=Module:Widget/Infobox/Highlights
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@return Renderable?
local function Highlights(props)
	if Table.isEmpty(props.children) then
		return nil
	end
	local listItems = Array.map(props.children, function(child)
		return Html.Li{children = {child}}
	end)
	return Html.Div{
		children = Html.Div{
			children = {Html.Ul{children = listItems}},
		}
	}
end

return Component.component(Highlights)
