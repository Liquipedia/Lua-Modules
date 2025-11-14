---
-- @Liquipedia
-- page=Module:Widget/Match/Page/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Image = Lua.import('Module:Image')
local Logic = Lua.import('Module:Logic')
local StreamLinks = Lua.import('Module:Links/Stream')

local Info = Lua.import('Module:Info', {loadData = true})
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local StreamsContainer = Lua.import('Module:Widget/Match/StreamsContainer')
local PartyDisplay = Lua.import('Module:Widget/Match/Page/PartyDisplay')
local TeamDisplay = Lua.import('Module:Widget/Match/Page/TeamDisplay')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MatchPageHeaderParameters
---@field countdownBlock Html?
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

---@class MatchPageHeader: Widget
---@operator call(MatchPageHeaderParameters): MatchPageHeader
---@field props MatchPageHeaderParameters
local MatchPageHeader = Class.new(Widget)

---@private
---@return Widget
function MatchPageHeader:_makeResultDisplay()
	local opponent1 = self.props.opponent1
	local opponent2 = self.props.opponent2
	local phase = self.props.phase

	return Div{
		classes = { 'match-bm-match-header-result' },
		children = WidgetUtil.collect(
			self:_showScore() and (
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
---@return boolean
function MatchPageHeader:_showScore()
	if self.props.phase == 'upcoming' then
		return false
	end
	if self.props.isBestOfOne then
		return Info.config.match2.gameScoresIfBo1
	end
	return true
end

---@private
---@return Widget?
function MatchPageHeader:_showMvps()
	local mvpData = self.props.mvp
	if Logic.isEmpty(mvpData) then return end
	---@cast mvpData -nil
	local points = tonumber(mvpData.points)
	return Div{
		classes = { 'match-bm-match-mvp' },
		children = WidgetUtil.collect(
			HtmlWidgets.B{ children = { 'MVP' } },
			Array.interleave(Array.map(mvpData.players, function (player)
				return Link{ link = player.name, children = player.displayname }
			end), ' '),
			points and points > 1 and ' (' .. points .. ' pts)' or nil
		)
	}
end

---@private
---@return Widget?
function MatchPageHeader:_showStreams()
	local phase = self.props.phase
	if phase == 'finished' then
		return
	end
	return Div{
		classes = {'match-info-links'},
		children = StreamsContainer{
			streams = StreamLinks.filterStreams(self.props.stream),
			matchIsLive = self.props.phase == 'ongoing',
			growButtons = true,
		}
	}
end

---@return Widget[]
function MatchPageHeader:render()
	local opponent1 = self.props.opponent1
	local opponent2 = self.props.opponent2

	---@param opponent standardOpponent
	---@return Widget
	local function createOpponentDisplay(opponent)
		if opponent.type == Opponent.team or opponent.type == Opponent.literal then
			return TeamDisplay{opponent = opponent}
		end
		return PartyDisplay{opponent = opponent}
	end

	return Div{
		classes = { 'match-bm-match-header' },
		children = WidgetUtil.collect(
			self.props.poweredBy and Div{
				classes = { 'match-bm-match-header-powered-by' },
				children = {
					'Data provided by ',
					Image.display(self.props.poweredBy, nil, {link = '', alt = 'SAP'})
				}
			} or nil,
			Div{
				classes = { 'match-bm-match-header-date' },
				children = { self.props.countdownBlock }
			},
			Div{
				classes = { 'match-bm-match-header-overview' },
				children = {
					createOpponentDisplay(opponent1),
					self:_makeResultDisplay(),
					createOpponentDisplay(opponent2)
				}
			},
			Div{
				classes = Array.extend(
					'match-bm-match-header-tournament',
					self.props.highlighted and 'tournament-highlighted-bg' or nil
				),
				children = {
					Link{ link = self.props.parent, children = self.props.tournamentName }
				}
			},
			self:_showMvps(),
			self:_showStreams()
		),
	}
end

return MatchPageHeader
