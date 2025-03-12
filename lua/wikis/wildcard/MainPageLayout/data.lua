---
-- @Liquipedia
-- wiki=wildcard
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DateExt = require('Module:Date/Ext')
local Lua = require('Module:Lua')

local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local MatchTickerContainer = Lua.import('Module:Widget/Match/Ticker/Container')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')
local WidgetUtil = Lua.import('Module:Widget/Util')

local CONTENT = {
	updates = {
		heading = 'Updates',
		body = '<nowiki>\n</nowiki>{{Main Page Updates}}',
		padding = true,
		boxid = 1502,
	},
	usefulArticles = {
		heading = 'Useful Articles',
		body = '{{Liquipedia:Useful Articles}}',
		padding = true,
		boxid = 1503,
	},
	wantToHelp = {
		heading = 'Want To Help?',
		body = '{{Liquipedia:Want_to_help}}',
		padding = true,
		boxid = 1504,
	},
	champions = {
		heading = 'Champions',
		body = '{{Liquipedia:championTable}}',
		padding = true,
		boxid = 1501,

	},
return {
	banner = {
		lightmode = 'Wildcard full lightmode.svg',
		darkmode = 'Wildcard full darkmode.svg',
	},
	metadesc = 'Comprehensive Wildcard wiki with articles covering everything from champions and summons, to strategies, ' ..
	'to tournaments, to competitive players, and teams.',
	title = 'The Wildcard Wiki',
	navigation = {
		{
			file = 'Wildcard Characters 2.jpg',
			title = 'Champions',
			link = 'Portal:Champions',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::character]]',
			},
		},
		{
			file = 'Wildcard Characters 1.jpg ',
			title = 'Summons',
			link = 'Portal:Summons',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::summons]]',
			},
		},
		{
			file = 'Wildcard Lushland Arena.jpg',
			title = 'Arenas',
			link = 'Portal:Arenas',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::map]]',
			},
		},
		{
			file = 'Wildcard Frostburn Arena.jpg',
			title = 'Mechanics',
			link = 'Portal:Mechanics',
			count = {
				method = 'LPDB',
				table = 'mechanics',
			},
		},
		{
			file = 'Wildcards',
			title = 'Wildcards',
			link = 'Portal:Wildcards',
			count = {
				method = 'LPDB',
				table = 'wildcard',
			},
		},
		{
			file = 'Decks',
			title = 'Decks',
			link = 'Portal:Decks',
			count = {
				method = 'LPDB',
				table = 'deck',
			},
		},
	},
	layouts = {
		main = {
			{ -- Left
				size = 6,
				children = {
					{
						mobileOrder = 1,
						content = CONTENT.champions,
					},
					{
						mobileOrder = 4,
						content = CONTENT.wantToHelp,
					},
				}
			},
			{ -- Right
				size = 6,
					{
						mobileOrder = 2,
						content = CONTENT.updates,
					},
					{
						mobileOrder = 3,
						content = CONTENT.usefulArticles,
					},
				},
			},
		},
	},
}