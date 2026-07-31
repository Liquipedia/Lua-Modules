---
-- @Liquipedia
-- page=Module:Widget/Match/Page/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Image = Lua.import('Module:Image')
local Logic = Lua.import('Module:Logic')
local StreamLinks = Lua.import('Module:Links/Stream')

local Info = Lua.import('Module:Info', {loadData = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local MatchPageOpponentDisplay = Lua.import('Module:Widget/Match/Page/OpponentDisplay')
local StreamsContainer = Lua.import('Module:Widget/Match/StreamsContainer')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MatchPageHeaderParameters
---@field countdownBlock Renderable?
---@field isBestOfOne boolean
---@field mvp {players: MatchGroupMvpPlayer[], points: integer?}?
---@field opponent1 MatchPageOpponent
---@field opponent2 MatchPageOpponent
---@field parent string?
---@field phase 'finished'|'ongoing'|'upcoming'
---@field stream table?
---@field tournamentName string?
---@field poweredBy string?
---@field highlighted boolean?

local MatchPageHeader = {}

---@private
---@param props MatchPageHeaderParameters
---@return VNode
function MatchPageHeader._makeResultDisplay(props)
	local opponent1 = props.opponent1
	local opponent2 = props.opponent2
	local phase = props.phase

	return Div{
		classes = { 'match-bm-match-header-result' },
		children = WidgetUtil.collect(
			MatchPageHeader._showScore(props) and (
				OpponentDisplay.InlineScore(opponent1) .. '&nbsp;:&nbsp;' .. OpponentDisplay.InlineScore(opponent2)
			) or '',
			Div{
				classes = { 'match-bm-match-header-result-text' },
				children = { phase == 'ongoing' and 'live' or phase }
			}
		)
	}
end

---@private
---@param props MatchPageHeaderParameters
---@return boolean
function MatchPageHeader._showScore(props)
	if props.phase == 'upcoming' then
		return false
	end
	if props.isBestOfOne then
		return Info.config.match2.gameScoresIfBo1
	end
	return true
end

---@private
---@param props MatchPageHeaderParameters
---@return VNode?
function MatchPageHeader._showMvps(props)
	local mvpData = props.mvp
	if Logic.isEmpty(mvpData) then return end
	---@cast mvpData -nil
	local points = tonumber(mvpData.points)
	return Div{
		classes = {'match-bm-match-mvp'},
		children = WidgetUtil.collect(
			Html.B{children = 'MVP'},
			Array.interleave(Array.map(mvpData.players, function (player)
				return Link{link = player.name, children = player.displayname}
			end), ' '),
			points and points > 1 and ' (' .. points .. ' pts)' or nil
		)
	}
end

---@private
---@param props MatchPageHeaderParameters
---@return VNode?
function MatchPageHeader._showStreams(props)
	local phase = props.phase
	if phase == 'finished' then
		return
	end
	return Div{
		classes = {'match-info-links'},
		children = StreamsContainer{
			streams = StreamLinks.filterStreams(props.stream),
			matchIsLive = props.phase == 'ongoing',
			growButtons = true,
		}
	}
end

---@param props MatchPageHeaderParameters
---@return VNode
function MatchPageHeader.render(props)
	local opponent1 = props.opponent1
	local opponent2 = props.opponent2

	return Div{
		classes = { 'match-bm-match-header' },
		children = WidgetUtil.collect(
			props.poweredBy and Div{
				classes = { 'match-bm-match-header-powered-by' },
				children = {
					'Data provided by ',
					Image.display(props.poweredBy, nil, {link = '', alt = 'SAP'})
				}
			} or nil,
			Div{
				classes = { 'match-bm-match-header-date' },
				children = props.countdownBlock
			},
			Div{
				classes = { 'match-bm-match-header-overview' },
				children = {
					MatchPageOpponentDisplay{
						opponent = opponent1,
						flip = true
					},
					MatchPageHeader._makeResultDisplay(props),
					MatchPageOpponentDisplay{
						opponent = opponent2
					},
				}
			},
			Div{
				classes = Array.extend(
					'match-bm-match-header-tournament',
					props.highlighted and 'tournament-highlighted-bg' or nil
				),
				children = Link{ link = props.parent, children = props.tournamentName }
			},
			MatchPageHeader._showMvps(props),
			MatchPageHeader._showStreams(props)
		),
	}
end

return Component.component(MatchPageHeader.render)
