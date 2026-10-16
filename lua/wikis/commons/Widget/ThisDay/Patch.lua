---
-- @Liquipedia
-- page=Module:Widget/ThisDay/Patch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local ThisDayQuery = Lua.import('Module:ThisDay/Query')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local ListWidgets = Lua.import('Module:Widget/List')

local HEADER = Html.H3{children = 'Patches'}
local TODAY = os.date("*t")

---@class ThisDayPatchParameters: ThisDayParameters
---@field hideIfEmpty boolean?

local defaultProps = {
	hideIfEmpty = true,
	month = TODAY.month,
	day = TODAY.day
}

---@param props ThisDayPatchParameters
---@return Renderable[]?
local function ThisDayPatch(props)
	local month = props.month
	local day = props.day
	assert(month, 'Month not specified')
	assert(day, 'Day not specified')

	local patchData = ThisDayQuery.patch(month, day)

	if Logic.isEmpty(patchData) then
		if props.hideIfEmpty then return end
		return {
			HEADER,
			'There were no patches on this day'
		}
	end
	local lines = Array.map(patchData, function (patch)
		local patchYear = patch.releaseDate.year
		return {
			Html.B{
				children = {patchYear}
			},
			': ',
			Link{link = patch.pageName, children = patch.displayName},
			' released'
		}
	end)

	return {
		HEADER,
		ListWidgets.Unordered{ children = lines }
	}
end

return Component.component(ThisDayPatch, defaultProps)
