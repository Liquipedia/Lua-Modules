---
-- @Liquipedia
-- page=Module:Widget/Match/Page/OpponentDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Opponent = Lua.import('Module:Opponent/Custom')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local SeriesDots = Lua.import('Module:Widget/Match/Page/SeriesDots')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MatchPageOpponentDisplayParameters
---@field opponent MatchPageOpponent
---@field flip boolean?

---@class MatchPageOpponentDisplay: Widget
---@operator call(MatchPageOpponentDisplayParameters): MatchPageOpponentDisplay
---@field props MatchPageOpponentDisplayParameters
local MatchPageOpponentDisplay = Class.new(Widget)

---@return Widget?
function MatchPageOpponentDisplay:render()
	return Div{
		classes = self:_getClasses(),
		children = self:_buildDisplay(),
	}
end

---@private
---@return boolean
function MatchPageOpponentDisplay:_isPartyType()
	return Opponent.typeIsParty(self.props.opponent.type)
end

---@private
---@return string[]
function MatchPageOpponentDisplay:_getClasses()
	local opponent = self.props.opponent
	local classes = {'match-bm-match-header-opponent'}

	if opponent.type ~= Opponent.literal then
		Array.extendWith(
			classes,
			'match-bm-match-header-' .. (self:_isPartyType() and 'party' or 'team')
		)
	end

	return classes
end

---@private
---@return Widget|Widget[]?
function MatchPageOpponentDisplay:_buildDisplay()
	local opponent = self.props.opponent
	if Opponent.isEmpty(opponent) then
		return
	elseif opponent.type == Opponent.literal then
		return Div{
			classes = {'match-bm-match-header-opponent-literal'},
			children = opponent.name
		}
	end

	return WidgetUtil.collect(
		opponent.iconDisplay,
		Div{
			classes = {'match-bm-match-header-opponent-group'},
			children = WidgetUtil.collect(
				self:_isPartyType()
					and self:_buildPartyDisplay()
					or self:_buildTeamDisplay(),
				SeriesDots{seriesDots = opponent.seriesDots}
			)
		}
	)
end

---@private
---@return Widget[]
function MatchPageOpponentDisplay:_buildTeamDisplay()
	local opponent = self.props.opponent

	local data = self.props.opponent.teamTemplateData
	assert(data, TeamTemplate.noTeamMessage(opponent.template))
	local hideLink = Opponent.isTbd(opponent)
	return {
		Div{
			classes = { 'match-bm-match-header-team-long' },
			children = { hideLink and data.name or Link{ link = data.page, children = data.name } }
		},
		Div{
			classes = { 'match-bm-match-header-team-short' },
			children = { hideLink and data.shortname or Link{ link = data.page, children = data.shortname } }
		}
	}
end

---@private
---@return Widget
function MatchPageOpponentDisplay:_buildPartyDisplay()
	local opponent = self.props.opponent
	return Div{
		classes = { 'match-bm-match-header-opponent-group-container' },
		children = Array.map(opponent.players, function (player)
			return PlayerDisplay.BlockPlayer{player = player, flip = self.props.flip}
		end)
	}
end

return MatchPageOpponentDisplay
