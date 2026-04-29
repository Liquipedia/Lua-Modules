---
-- @Liquipedia
-- page=Module:FactionStatistics/MatchupDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MathUtil = Lua.import('Module:MathUtil')

local TableWidgets = Lua.import('Module:Widget/Table2/All')

local MatchupDisplay = {}

---@param matchupData {w: number, l: number}
---@return Widget[]
function MatchupDisplay.display(matchupData)
	local total = matchupData.w + matchupData.l

	---@return string
	local getPercentage = function()
		if total == 0 then
			return '-'
		end
		local percentage = 100 * matchupData.w / (total)
		return MathUtil.formatPercentage(percentage, 1)
	end

	return {
		TableWidgets.Cell{children = MatchupDisplay.dashIfZero(total)},
		TableWidgets.Cell{children = MatchupDisplay.dashIfZero(matchupData.w)},
		TableWidgets.Cell{children = MatchupDisplay.dashIfZero(matchupData.l)},
		TableWidgets.Cell{children = getPercentage()},
	}
end

---@param input integer|string
---@return integer|string
function MatchupDisplay.dashIfZero(input)
	return input == 0 and '-' or input
end

return MatchupDisplay
