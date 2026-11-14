---
-- @Liquipedia
-- page=Module:Widget/Infobox/ExpansionIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Image = Lua.import('Module:Image')

local Component = Lua.import('Module:Widget/Component')

local EXPANSIONS = {
	kin = 'The Age of Kings',
	con = 'The Conquerors',
	['for'] = 'The Forgotten',
	afr = 'The African Kingdoms',
	ris = 'Rise of the Rajas',
	lor = 'Lords of the West',
	daw = 'Dawn of the Dukes',
	las = 'The Last Khans',
	kha = 'The Last Khans',
}
EXPANSIONS['the age of kings'] = EXPANSIONS.kin
EXPANSIONS['the conquerors'] = EXPANSIONS.con
EXPANSIONS['the forgotten'] = EXPANSIONS['for']
EXPANSIONS['the african kingdoms'] = EXPANSIONS.afr
EXPANSIONS['rise of the rajas'] = EXPANSIONS.ris
EXPANSIONS['lords of the west'] = EXPANSIONS.lor
EXPANSIONS['dawn of the dukes'] = EXPANSIONS.daw
EXPANSIONS.kha = EXPANSIONS.las
EXPANSIONS['the last khans'] = EXPANSIONS.las
EXPANSIONS['definitive edition'] = EXPANSIONS.las

---@class AoeExpansionIconProps
---@field expansion string?

---@param props AoeExpansionIconProps
---@return string?
local function AoeExpansionIcon(props)
	local exp = EXPANSIONS[(props.expansion or ''):lower()]
	if not exp then
		return
	end

	return Image.display(
		'Aoe2 ' .. exp .. ' Icon.png',
		'Aoe2 ' .. exp .. ' Icon.png',
		{
			link = exp,
			size = '18',
		}
	)
end

return Component.component(AoeExpansionIcon)
