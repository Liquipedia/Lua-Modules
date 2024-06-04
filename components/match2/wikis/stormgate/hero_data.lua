---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:HeroData
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local heroData = {
	--example from warcraft:
	--[[
	archmage = {
		aliases = {'am'},
		icon = 'Wc3BTNHeroArchMage.png',
		name = 'Archmage',
		faction = 'h'
	},
	]]

	default = {
		icon = 'Transparent icon.png',
		name = '',
		faction = 'neutral',
	},
}

local resolvedHeroData = {}
for key, item in pairs(heroData) do
	for _, alias in pairs(item.aliases or {}) do
		resolvedHeroData[alias] = item
	end
	resolvedHeroData[key] = item
end

return resolvedHeroData
