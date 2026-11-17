---
-- @Liquipedia
-- page=Module:Widget/Match/Ticker/Opponents
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Info = Lua.import('Module:Info', {loadData = true})
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local MatchHeaderFfa = Lua.import('Module:Widget/Match/Header/Ffa')
local WidgetUtil = Lua.import('Module:Widget/Util')

local TeamTemplateDefaultImages = Info.games[Info.defaultGame].defaultTeamLogo

local MAX_FFA_PARTICIPANT_ICONS = 5
local PARTY_OPPONENTS_DIVIDER = Html.Hr{classes = {'match-ticker-card__divider'}}

local MatchTickerCardOpponents = {}

---@param props {match: MatchGroupUtilMatch}
---@return VNode?
function MatchTickerCardOpponents.render(props)
	local match = props.match

	if #match.opponents > 2 then
		---@cast match FFAMatchGroupUtilMatch
		return MatchTickerCardOpponents.buildFfaMatchOpponentsDisplay(match)
	end
	return MatchTickerCardOpponents.buildNormalMatchOpponentsDisplay(match)
end

---@param match MatchGroupUtilMatch
---@return VNode
function MatchTickerCardOpponents.buildNormalMatchOpponentsDisplay(match)
	local matchOpponents = match.opponents
	local opponentsDisplay = Array.map(
		match.opponents,
		FnUtil.curry(MatchTickerCardOpponents.buildNormalMatchOpponentDisplay, match)
	)
	local hasDivider = Array.any(matchOpponents, function (opponent)
		local opponentType = opponent.type
		return Opponent.typeIsParty(opponentType) and Opponent.partySize(opponentType) > 1
	end)
	return Html.Div{
		classes = {'match-ticker-card__opponents'},
		children = hasDivider and Array.interleave(opponentsDisplay, PARTY_OPPONENTS_DIVIDER) or opponentsDisplay
	}
end

---@param match MatchGroupUtilMatch
---@param opponent standardOpponent
---@param opponentIndex integer
---@return VNode
function MatchTickerCardOpponents.buildNormalMatchOpponentDisplay(match, opponent, opponentIndex)
	return Html.Div{
		classes = {
			'match-ticker-card__opponent',
			match.winner == opponentIndex and 'winner' or nil,
		},
		children = {
			OpponentDisplay.BlockOpponent{
				opponent = opponent,
				teamStyle = 'dynamic',
			},
			Html.Div{children = OpponentDisplay.InlineScore(opponent)},
		}
	}
end

---@param match FFAMatchGroupUtilMatch
---@return VNode?
function MatchTickerCardOpponents.buildFfaMatchOpponentsDisplay(match)
	if match.finished then
		return MatchHeaderFfa{match = match, teamStyle = 'dynamic'}
	end
	return MatchTickerCardOpponents.buildFfaParticipantsPreview(match)
end

---@param match FFAMatchGroupUtilMatch
---@return VNode
function MatchTickerCardOpponents.buildFfaParticipantsPreview(match)
	local participants = Array.filter(match.opponents, function (opponent)
		return not Opponent.isTbd(opponent)
	end)
	local iconOpponents = Array.sub(
		Array.filter(participants, function (opponent)
			if opponent.type ~= Opponent.team then
				return false
			end
			local teamTemplateData = TeamTemplate.getRaw(opponent.template)

			return (
				(
					teamTemplateData.image ~= TeamTemplateDefaultImages.lightMode or
					teamTemplateData.image:gsub(' ', '_') ~= TeamTemplateDefaultImages.lightMode
				) and
				(
					teamTemplateData.imagedark ~= TeamTemplateDefaultImages.darkMode or
					teamTemplateData.imagedark:gsub(' ', '_') ~= TeamTemplateDefaultImages.darkMode
				)
			)
		end),
		1,
		MAX_FFA_PARTICIPANT_ICONS
	)
	local remainingCount = #participants - #iconOpponents

	return Html.Div{
		classes = {'match-ticker-card__participants'},
		children = WidgetUtil.collect(
			#iconOpponents > 0 and Html.Div{
				classes = {'match-ticker-card__participants-icons'},
				children = Array.map(iconOpponents, function (opponent)
					return Html.Div{
						classes = {'match-ticker-card__participant-icon'},
						children = OpponentDisplay.BlockTeamContainer{
							template = opponent.template,
							showLink = false,
							style = 'icon',
						},
					}
				end)
			} or nil,
			remainingCount > 0 and Html.Span{
				classes = {'match-ticker-card__participants-count'},
				children = MatchTickerCardOpponents._getRemainingParticipantsText(
					participants,
					remainingCount,
					#iconOpponents > 0
				),
			} or nil
		)
	}
end

---@param participants standardOpponent[]
---@param remainingCount integer
---@param hasIcons boolean
---@return string
function MatchTickerCardOpponents._getRemainingParticipantsText(participants, remainingCount, hasIcons)
	local allTeams = Array.all(participants, function (opponent)
		return opponent.type == Opponent.team
	end)
	local noun = allTeams and 'team' or 'participant'
	return (hasIcons and '+ ' or '') .. remainingCount .. ' ' .. noun .. (remainingCount == 1 and '' or 's')
end

return Component.component(MatchTickerCardOpponents.render)
