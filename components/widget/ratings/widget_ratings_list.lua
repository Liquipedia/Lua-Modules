---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Ratings/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local PlacementChange = Lua.import('Module:Widget/Standings/PlacementChange')
local RatingsStorageFactory = Lua.import('Module:Ratings/Storage/Factory')

---@class RatingsList: Widget
---@field _base Widget
---@operator call(table): RatingsList
local RatingsList = Class.new(Widget)

---@return Widget
function RatingsList:render()
	-- Simple check to verify that the input is a osdate
	assert(self.props.date and self.props.date.wday, 'Invalid date provided')
	---@type osdate
	local date = self.props.date
	local dateAsString = os.date('%F', os.time(date)) --[[@as string]]

	local teamLimit = tonumber(self.props.teamLimit) or self.defaultProps.teamLimit
	local progressionLimit = tonumber(self.props.progressionLimit) or self.defaultProps.progressionLimit
	local isSmallerVersion = Logic.readBool(self.props.isSmallerVersion)

	local getRankings = RatingsStorageFactory.createGetRankings {
		storageType = self.props.storageType,
		date = dateAsString,
		id = self.props.id,
	}
	local teams = getRankings(teamLimit, progressionLimit)

	local teamRows = Array.map(teams, function(team, rank)
		local streakText = team.streak > 1 and team.streak .. 'W' or (team.streak < -1 and (-team.streak) .. 'L') or '-'
		local streakClass = (team.streak > 1 and 'group-table-rank-change-up')
			or (team.streak < -1 and 'group-table-rank-change-down')
			or nil

		local changeText = (not team.change and 'NEW') or PlacementChange { change = team.change }

		local teamRow = WidgetUtil.collect(
			HtmlWidgets.Td { attributes = { ['data-ranking-table-cell'] = 'rank' }, children = rank },
			HtmlWidgets.Td { attributes = { ['data-ranking-table-cell'] = 'change' }, children = changeText },
			HtmlWidgets.Td {
				attributes = { ['data-ranking-table-cell'] = 'team' },
				children = OpponentDisplay.BlockOpponent { opponent = team.opponent, teamStyle = 'hybrid' }
			},
			HtmlWidgets.Td { attributes = { ['data-ranking-table-cell'] = 'rating' }, children = team.rating },
			HtmlWidgets.Td {
				attributes = { ['data-ranking-table-cell'] = 'region' },
				children = Flags.Icon(team.region) .. Flags.CountryName(team.region)
			},
			HtmlWidgets.Td {
				attributes = { ['data-ranking-table-cell'] = 'streak' },
				children = streakText,
				classes = { streakClass }
			}
		)

		local isEven = rank % 2 == 0
		local rowClasses = { 'ranking-table__row' }
		if isEven then
			table.insert(rowClasses, 'ranking-table__row--even')
		end
		if rank > 5 and isSmallerVersion then
			table.insert(rowClasses, 'ranking-table__row--overfive')
		end

		return {
			HtmlWidgets.Tr { children = teamRow, classes = rowClasses },
		}
	end)

	local formattedDate = os.date('%b %d, %Y', os.time(date)) --[[@as string]]
	local tableHeader = HtmlWidgets.Tr {
		children = HtmlWidgets.Th {
			attributes = { colspan = '7' },
			children = HtmlWidgets.Div {
				children = { 'Last updated: ' .. formattedDate, '[[File:DataProvidedSAP.svg|link=]]' }
			},
			classes = { 'ranking-table__top-row' },
		}
	}

	local buttonDiv = HtmlWidgets.Div {
		children = { 'See Rankings Page', Icon.makeIcon { iconName = 'goto' } },
	}

	local tableFooter = HtmlWidgets.Tr {
		children = HtmlWidgets.Th {
			attributes = { colspan = '7' },
			children = Link {
				link = 'Portal:Rating',
				linktype = 'internal',
				children = { buttonDiv },
			},
			classes = { 'ranking-table__footer-row' },
		}
	}

	return HtmlWidgets.Div {
		attributes = {
			['data-ranking-table'] = 'content',
		},
		children = WidgetUtil.collect(
			HtmlWidgets.Table {
				attributes = { ['data-ranking-table'] = 'table' },
				classes = { 'ranking-table', isSmallerVersion and 'ranking-table--small' or nil },
				children = WidgetUtil.collect(
					tableHeader,
					HtmlWidgets.Tr {
						children = WidgetUtil.collect(
							HtmlWidgets.Th { attributes = { ['data-ranking-table-cell'] = 'rank' }, children = 'Rank' },
							HtmlWidgets.Th { attributes = { ['data-ranking-table-cell'] = 'change' }, children = '+/-' },
							HtmlWidgets.Th { attributes = { ['data-ranking-table-cell'] = 'team' }, children = 'Team' },
							HtmlWidgets.Th { attributes = { ['data-ranking-table-cell'] = 'rating' }, children = 'Points' },
							HtmlWidgets.Th { attributes = { ['data-ranking-table-cell'] = 'region' }, children = 'Region' },
							HtmlWidgets.Th { attributes = { ['data-ranking-table-cell'] = 'streak' }, children = 'Streak' }
						),
						classes = { 'ranking-table__header-row' },
					},
					Array.flatten(teamRows),
					isSmallerVersion and tableFooter or nil
				)
			}
		)
	}
end

---@param error Error
---@return string
function RatingsList:getDerivedStateFromError(error)
	error.message = 'Could not load the selected week.'
	return self._base:getDerivedStateFromError(error)
end

return RatingsList
