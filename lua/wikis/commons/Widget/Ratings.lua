---
-- @Liquipedia
-- page=Module:Widget/Ratings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local RatingsList = Lua.import('Module:Widget/Ratings/List')

local defaultProps = {
	teamLimit = 20,
	storageType = 'lpdb',
	showGraph = true,
	isSmallerVersion = false,
}

---@param props {teamLimit: integer?, storageType: string?, showGraph: boolean?, isSmallerVersion: boolean?}
---@return Widget
local function Ratings(props)
	return Html.Div {
		attributes = {
			class = 'ranking-table__wrapper',
		},
		children = {
			RatingsList {
				teamLimit = props.teamLimit,
				storageType = props.storageType,
				showGraph = props.showGraph,
				isSmallerVersion = props.isSmallerVersion,
			},
		},
	}
end

return Component.component(Ratings, defaultProps)
