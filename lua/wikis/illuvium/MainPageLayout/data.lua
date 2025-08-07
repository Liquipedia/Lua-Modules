---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local WantToHelp = Lua.import('Module:Widget/MainPage/WantToHelp')

local CONTENT = {
	wantToHelp = {
		heading = 'Want To Help?',
		body = WantToHelp{},
		padding = true,
		boxid = 1504,
	},
}

return {
	banner = {
		lightmode = 'Illuvium full lightmode.svg',
		darkmode = 'Illuvium full darkmode.svg',
	},
	metadesc = 'Comprehensive Auto Chess wiki with articles covering everything from Illuvials, weapons, ' ..
		'to suits, to synergies, and gameplay.',
	title = 'Illuvium',
	navigation = {
		{
			file = 'Illuvium Arena.png',
			title = 'Gameplay',
			link = 'Portal:Gameplay',
		},
		{
			file = 'Illuvium Ebb.png',
			title = 'Illuvials',
			link = 'Portal:Illuvials',
			count = {
				method = 'CATEGORY',
				category = 'Illuvials',
			},
		},
		{
			file = 'Illuvium Psion.png',
			title = 'Classes',
			link = 'Portal:Classes',
			count = {
				method = 'CATEGORY',
				category = 'Classes',
			},
		},
		{
			file = 'Illuvium Air.png',
			title = 'Affinities',
			link = 'Portal:Affinities',
			count = {
				method = 'CATEGORY',
				category = 'Affinities',
			},
		},
		{
			file = 'Illuvium Exalted Biogenetic Suppressor.png',
			title = 'Augments',
			link = 'Portal:Augments',
			count = {
				method = 'CATEGORY',
				category = 'Augments',
			},
		},
		{
			file = 'Illuvium Dual Blades Neutral.png',
			title = 'Weapons',
			link = 'Portal:Weapons',
			count = {
				method = 'CATEGORY',
				category = 'Weapons',
			},
		},
		{
			file = 'Illuvium Biotic Sash Stage 3.png',
			title = 'Suits',
			link = 'Portal:Suits',
			count = {
				method = 'CATEGORY',
				category = 'Suits',
			},
		},
		{
			file = 'EWC 2024 PUBG Trophy.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
	},
	layouts = {
		main = {
			{
				children = {
					{
						mobileOrder = 1,
						content = CONTENT.wantToHelp,
					},
				},
			},
		},
	},
}
