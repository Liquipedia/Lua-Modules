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

function RatingsDropdown.render()
    return HtmlWidgets.Div{
        attributes = {
            attributes = {
                class = 'rankings-table__dropdown',
                ['data-ranking-table'] = 'dropdown-container',
            },
        },
        --children = {
        --    HtmlWidgets.Option{
        --        attributes = {value = 'week1'},
        --        children = {'Week 1'},
        --    },
        --    HtmlWidgets.Option{
        --        attributes = {value = 'week2'},
        --        children = {'Week 2'},
        --    },
        --},
        --// create a span with text
        HtmlWidgets.Span{
            attributes = {
                class = 'rankings-table__patch-label',
                ['data-ranking-table'] = 'patch-label',
            },
            children = { 'Patch 7.36a' },
        },
    }
end

return RatingsDropdown
