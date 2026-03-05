---
-- @Liquipedia
-- page=Module:Infobox/Extension/Achievements/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local GSL_ICON = 'GSLLogo_small.png'
local GSL_CODE_A_ICON = 'GSL_CodeA.png'
local CODE_A = 'Code A'

return {
	noTemplate = true,
	onlyForFirstPrizePoolOfPage = true,
	--sc2 specific icon adjustments for GSL Code A
	adjustItem = function(item)
		item.icon = string.gsub(item.icon or '', 'File:', '') --just to be safe
		if item.icon == GSL_ICON and string.match(item.tournament, CODE_A) then
			item.icon = GSL_CODE_A_ICON
			item.icondark = GSL_CODE_A_ICON
		end

		return item
	end,
}
