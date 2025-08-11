---
-- @Liquipedia
-- page=Module:Widget/ThisDay/Patch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local ThisDayQuery = Lua.import('Module:ThisDay/Query')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local UnorderedList = Lua.import('Module:Widget/List/Unordered')
local Widget = Lua.import('Module:Widget')

local HEADER = HtmlWidgets.H3{children = 'Patches'}
local TODAY = os.date("*t")

---@class ThisDayPatchParameters: ThisDayParameters
---@field hideIfEmpty boolean?

---@class ThisDayPatch: Widget
---@operator call(table): ThisDayPatch
---@field props ThisDayPatchParameters
local ThisDayPatch = Class.new(Widget)
ThisDayPatch.defaultProps = {
	hideIfEmpty = true,
	month = TODAY.month,
	day = TODAY.day
}

---@return (string|Widget)[]?
function ThisDayPatch:render()
	local month = self.props.month
	local day = self.props.day
	assert(month, 'Month not specified')
	assert(day, 'Day not specified')

	local patchData = ThisDayQuery.patch(month, day)

	if Logic.isEmpty(patchData) then
		if self.props.hideIfEmpty then return end
		return {
			HEADER,
			'There were no patches on this day'
		}
	end
	local lines = Array.map(patchData, function (patch)
		local patchYear = patch.releaseDate.year
		return {
			HtmlWidgets.B{
				children = {patchYear}
			},
			': ',
			Link{link = patch.pageName, children = patch.displayName},
			' released'
		}
	end)

	return UnorderedList{ children = lines }
end

return ThisDayPatch
