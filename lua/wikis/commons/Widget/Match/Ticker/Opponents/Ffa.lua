---
-- @Liquipedia
-- page=Module:Widget/Match/Ticker/Opponents/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Game = Lua.import('Module:Game')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Trophy = Lua.import('Module:Widget/Match/Summary/Ffa/Trophy')
local Div = Html.Div

local Placement = Lua.import('Module:Placement')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MAX_FFA_PARTICIPANT_ICONS = 5

local FFAMatchTickerCardOpponents = {}

---@param props {match: FFAMatchGroupUtilMatch}
---@return VNode?
function FFAMatchTickerCardOpponents.buildFfaMatchOpponentsDisplay(props)
	local match = props.match
	if match.finished then
		return FFAMatchTickerCardOpponents.buildFfaMatchResultsDisplay(match)
	end
	return FFAMatchTickerCardOpponents.buildFfaParticipantsPreview(match)
end

---@param match FFAMatchGroupUtilMatch
---@return VNode?
function FFAMatchTickerCardOpponents.buildFfaMatchResultsDisplay(match)
	local topThree = Array.sub(
		Array.sortBy(
			Array.filter(
				match.opponents,
				Operator.property('placement')
			),
			Operator.property('placement')
		),
		1, 3
	)

	local positionRows = Array.map(topThree, function(opponent, i)
		return Div {
			classes = { 'match-info-headerbr-positionrow' },
			children = {
				Div {
					classes = { 'match-info-headerbr-positionholder' },
					children = {
						Trophy{ place = i },
						Placement._makeOrdinal({ i })[1]
					}
				},
				Div {
					classes = { 'match-info-headerbr-opponent' },
					children = {
						OpponentDisplay.BlockOpponent {
							opponent = opponent,
							teamStyle = 'dynamic',
							overflow = 'ellipsis',
						}
					}
				}
			}
		}
	end)

	return Div {
		classes = { 'match-info-headerbr' },
		children = positionRows
	}
end

---@param match FFAMatchGroupUtilMatch
---@return VNode
function FFAMatchTickerCardOpponents.buildFfaParticipantsPreview(match)
	local participants = Array.filter(match.opponents, function (opponent)
		return not Opponent.isTbd(opponent)
	end)
	local iconOpponents = Array.sub(
		Array.filter(participants, function (opponent)
			if opponent.type ~= Opponent.team then
				return false
			end
			local teamTemplateData = TeamTemplate.getRaw(opponent.template)

			return Array.all(
				{
					teamTemplateData.image,
					teamTemplateData.imagedark,
				},
				function (image)
					return not Game.isDefaultTeamLogo{logo = image}
				end
			)
		end),
		1,
		MAX_FFA_PARTICIPANT_ICONS
	)
	local remainingCount = #participants - #iconOpponents

	return Html.Div{
		classes = {'match-ticker-card__opponents-ffa-container'},
		children = Html.Div{
			classes = {'match-ticker-card__opponents-ffa'},
			children = WidgetUtil.collect(
				#iconOpponents > 0 and Html.Div{
					classes = {'match-ticker-card__opponents-ffa-icons'},
					children = Array.map(iconOpponents, function (opponent)
						return Html.Div{
							classes = {'match-ticker-card__opponent-ffa-icon'},
							children = OpponentDisplay.BlockTeamContainer{
								template = opponent.template,
								showLink = false,
								style = 'icon',
							},
						}
					end)
				} or nil,
				remainingCount > 0 and Html.Span{
					classes = {'match-ticker-card__opponents-ffa-count'},
					children = FFAMatchTickerCardOpponents._getRemainingParticipantsText(
						participants,
						remainingCount,
						#iconOpponents > 0
					),
				} or nil
			)
		}
	}
end

---@param participants standardOpponent[]
---@param remainingCount integer
---@param hasIcons boolean
---@return string
function FFAMatchTickerCardOpponents._getRemainingParticipantsText(participants, remainingCount, hasIcons)
	local allTeams = Array.all(participants, function (opponent)
		return opponent.type == Opponent.team
	end)
	local noun = allTeams and 'team' or 'participant'
	return (hasIcons and '+ ' or '') .. remainingCount .. ' ' .. noun .. (remainingCount == 1 and '' or 's')
end

return Component.component(FFAMatchTickerCardOpponents.render)
