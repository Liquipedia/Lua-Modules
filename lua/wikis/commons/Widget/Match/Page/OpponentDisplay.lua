---
-- @Liquipedia
-- page=Module:Widget/Match/Page/OpponentDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Opponent = Lua.import('Module:Opponent/Custom')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local SeriesDots = Lua.import('Module:Widget/Match/Page/SeriesDots')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MatchPageOpponentDisplay = {}

---@param props {opponent: MatchPageOpponent, flip: boolean?}
---@return VNode?
function MatchPageOpponentDisplay.render(props)
	return Div{
		classes = MatchPageOpponentDisplay._getClasses(props.opponent),
		children = MatchPageOpponentDisplay._buildDisplay(props.opponent, props.flip),
	}
end

---@private
---@param opponent standardOpponent
---@return boolean
function MatchPageOpponentDisplay._isPartyType(opponent)
	return Opponent.typeIsParty(opponent.type)
end

---@private
---@param opponent standardOpponent
---@return string[]
function MatchPageOpponentDisplay._getClasses(opponent)
	local classes = {'match-bm-match-header-opponent'}

	if opponent.type ~= Opponent.literal then
		Array.extendWith(
			classes,
			'match-bm-match-header-' .. (MatchPageOpponentDisplay._isPartyType(opponent) and 'party' or 'team')
		)
	end

	return classes
end

---@private
---@param opponent MatchPageOpponent
---@param flip boolean?
---@return Renderable|Renderable[]?
function MatchPageOpponentDisplay._buildDisplay(opponent, flip)
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
				MatchPageOpponentDisplay._isPartyType(opponent)
					and MatchPageOpponentDisplay._buildPartyDisplay(opponent, flip)
					or MatchPageOpponentDisplay._buildTeamDisplay(opponent),
				SeriesDots{seriesDots = opponent.seriesDots}
			)
		}
	)
end

---@private
---@param opponent MatchPageOpponent
---@return VNode[]
function MatchPageOpponentDisplay._buildTeamDisplay(opponent)
	local data = opponent.teamTemplateData
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
---@param opponent MatchPageOpponent
---@param flip boolean?
---@return VNode
function MatchPageOpponentDisplay._buildPartyDisplay(opponent, flip)
	return Div{
		classes = { 'match-bm-match-header-opponent-group-container' },
		children = Array.map(opponent.players, function (player)
			return PlayerDisplay.BlockPlayer{player = player, flip = flip}
		end)
	}
end

return Component.component(MatchPageOpponentDisplay.render)
