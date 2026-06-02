---
-- @Liquipedia
-- page=Module:Widget/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@class ListWidgetProps
---@field children (Renderable|Renderable[])[]?

local ListWidgets = {}

---@package
---@param listType HtmlComponent
function ListWidgets._create(listType)
	---@param props ListWidgetProps
	---@return VNode?
	local function renderList(props)
		local children = props.children
		if Logic.isEmpty(children) then
			return
		end
		---@cast children -nil
		return listType{
			children = Array.map(children, function (item)
				return Html.Li{
					children = item
				}
			end)
		}
	end

	return Component.component(renderList)
end

ListWidgets.Ordered = ListWidgets._create(Html.Ol)
ListWidgets.Unordered = ListWidgets._create(Html.Ul)

return ListWidgets
