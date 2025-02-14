---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Ratings/Dropdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Widget = Lua.import('Module:Widget')

---@class RatingsDropdown: Widget
---@operator call(table): RatingsDropdown
local RatingsDropdown = Class.new(Widget)

--todo: rename to select instead of dropdown later
function RatingsDropdown.render()
    return HtmlWidgets.Div{
        attributes = {
            class = 'ranking-table__select-container',
            ['data-ranking-table'] = 'select-container',
        },
        children = {
            HtmlWidgets.Span{
                attributes = {
                    class = 'ranking-table__patch-label',
                    ['data-ranking-table'] = 'patch-label',
                },
            },
        },
    }
end

return RatingsDropdown
