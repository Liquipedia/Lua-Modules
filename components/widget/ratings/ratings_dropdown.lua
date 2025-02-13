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
    return HtmlWidgets.Select {
        attributes = { id = 'weekSelector' },
        children = {
            HtmlWidgets.Option {
                attributes = { value = 'week1' },
                children = { 'Week 1' },
            },
            HtmlWidgets.Option {
                attributes = { value = 'week2' },
                children = { 'Week 2' },
            },
        },
    }
end

return RatingsDropdown
