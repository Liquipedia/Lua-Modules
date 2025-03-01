---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local FilterButtons = Lua.import('Module:FilterButtons')
local MatchTickerContainer = Lua.import('Module:Widget/Match/Ticker/Container')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')
local TransferList = Lua.import('Module:TransferList')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Fragment = HtmlWidgets.Fragment
local Link = Lua.import('Module:Widget/Basic/Link')
local Span = HtmlWidgets.Span

---@return string
local function getTransferPage()
	return 'Special:EditPage/Player Transfers/' .. os.date('%Y') .. '/' .. os.date('%B')
end

local CENTER_DOT = Span{
	css = {
		['font-style'] = 'normal',
		['padding'] = '0 5px',
	},
	children = { '&#8226;' }
}

local CONTENT = {
	theGame = {
		heading = 'The Game',
		body = '{{Liquipedia:The Game}}',
		padding = true,
		boxid = 1503,
	},
	transfers = {
		heading = 'Transfers',
		body = Fragment{
			children = {
				TransferList{ limit = 15 }:fetch():create(),
				Div{
					css = { display = 'block', ['text-align'] = 'center', padding = '0.5em' },
					children = {
						Div{
							css = { display = 'inline', float = 'left', ['font-style'] = 'italic' },
							children = { Link{ children = 'Back to top', link = '#Top'} }
						},
						Div{
							classes = { 'plainlinks', 'smalledit' },
							css = { display = 'inline', float = 'right' },
							children = { '&#91;', Link{ children = 'edit', link = getTransferPage() }, '&#93;' },
						},
						Div{
							css = {
								['white-space'] = 'nowrap',
								display = 'inline',
								margin = '0 10px',
								['font-size'] = '15px',
								['font-style'] = 'italic'
							},
							children = {
								Link{ children = 'See more transfers', link = 'Portal:Transfers' },
								CENTER_DOT,
								Link{ children = 'Transfer query', link = 'Special:RunQuery/Transfer_history' },
								CENTER_DOT,
								Link{ children = 'Input Form', link = 'lpcommons:Special:RunQuery/Transfer' },
								CENTER_DOT,
								Link{ children = 'Rumours', link = 'Portal:Rumours' },
							}
						},
					}
				}
			}
		},
		boxid = 1509,
	},
	specialEvents = {
		noPanel = true,
		body = '{{Liquipedia:Special Event}}',
	},
	filterButtons = {
		noPanel = true,
		body = Div{
			css = { width = '100%', ['margin-bottom'] = '8px' },
			children = { FilterButtons.getFromConfig() }
		}
	},
	matches = {
		heading = 'Matches',
		body = Fragment{
			children = {
				MatchTickerContainer{},
				Div{
					css = {
						['white-space'] = 'nowrap',
						display = 'block',
						margin = '0 10px',
						['font-size'] = '15px',
						['font-style'] = 'italic',
						['text-align'] = 'center',
					},
					children = { Link{ children = 'See more matches', link = 'Liquipedia:Matches'} }
				}
			}
		},
		padding = true,
		boxid = 1507,
		panelAttributes = {
			['data-switch-group-container'] = 'countdown',
		},
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 21,
			completedDays = 14,
		},
		padding = true,
		boxid = 1508,
	},
}

return {
	banner = {
		lightmode = 'VALORANT.svg',
		darkmode = 'VALORANT-darkmode.svg',
	},
	metadesc = 'The VALORANT esports wiki covering everything from players, teams and transfers, ' ..
		'to tournaments and results, to maps, weapons, and agents.',
	title = 'VALORANT',
	navigation = {
		{
			file = 'ShopifyRebellion VCT Game Changers Championship 2024.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'Valorant-champions-seoul-2024.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'Valorant-champions-trophy-2024-2.jpeg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'Raze-lockin-2023.jpeg',
			title = 'Agents',
			link = 'Portal:Agents',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::character]]',
			},
		},
		{
			file = 'EDward Gaming VALORANT Masters Shanghai 2024.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'MIBR GC Coaches VCT GC Championship 2024.jpg',
			title = 'Statistics',
			link = 'Portal:Statistics',
		},
		{
			file = 'Sunset Map.png',
			title = 'Maps',
			link = 'Portal:Maps',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::map]]',
			},
		},
	},
	layouts = {
		main = {
			{ -- Left
				size = 6,
				children = {
					{
						mobileOrder = 2,
						content = CONTENT.specialEvents,
					},
					{
						mobileOrder = 4,
						content = CONTENT.transfers,
					},
					{
						mobileOrder = 7,
						content = CONTENT.wantToHelp,
					},
				}
			},
			{ -- Right
				size = 6,
				children = {
					{
						mobileOrder = 3,
						children = {
							{
								children = {
									{
										noPanel = true,
										content = CONTENT.filterButtons,
									},
								},
							},
							{
								size = 6,
								children = {
									{
										noPanel = true,
										content = CONTENT.matches,
									},
								},
							},
							{
								size = 6,
								children = {
									{
										noPanel = true,
										content = CONTENT.tournaments,
									},
								},
							},
						},
					},
				},
			},
			{
				children = {
					{
						mobileOrder = 8,
						content = CONTENT.theGame,
					},
				},
			},
		},
	},
}
