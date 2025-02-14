---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Ratings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--


local Class = require('Module:Class')
local Date = require('Module:Date/Ext')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local RatingsList = Lua.import('Module:Widget/Ratings/List')
local RatingsDropdown = Lua.import('Module:Widget/Ratings/Dropdown')

---@class Ratings: Widget
---@operator call(table): Ratings
local Ratings = Class.new(Widget)
Ratings.defaultProps = {
    teamLimit = 20,
    progressionLimit = 10,
    storageType = 'lpdb',
    date = Date.getContextualDateOrNow(),
    showGraph = true,
    isSmallerVersion = false,
}

---@return Widget
function Ratings:render()
    return HtmlWidgets.Div {
        attributes = {
            class = 'ranking-table__wrapper',
            ['data-ranking-table'] = 'wrapper',
        },
        children = {
            RatingsDropdown {},
            RatingsList {
                teamLimit = self.props.teamLimit,
                progressionLimit = self.props.progressionLimit,
                storageType = self.props.storageType,
                date = self.props.date,
                showGraph = self.props.showGraph,
                isSmallerVersion = self.props.isSmallerVersion,
            },
        },
    }
end

return Ratings
