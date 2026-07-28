---
-- @Liquipedia
-- page=Module:OpponentDisplay/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Faction = Lua.import('Module:Faction')
local Icon = Lua.import('Module:Icon')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Opponent = Lua.import('Module:Opponent')
local OpponentDisplay = Lua.import('Module:OpponentDisplay')

local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

--Display components for opponents used by the starcraft and starcraft 2 wikis
---@class StarcraftOpponentDisplay: OpponentDisplay
local StarcraftOpponentDisplay = Table.copy(OpponentDisplay)

---@class StarcraftBlockOpponentProps: BlockOpponentProps
---@field opponent StarcraftStandardOpponent

---Displays an opponent as a block element. The width of the component is
---determined by its layout context, and not of the opponent.
---@param props StarcraftBlockOpponentProps
---@return Renderable
function StarcraftOpponentDisplay.BlockOpponent(props)
	local opponent = props.opponent
	opponent.extradata = opponent.extradata or {}
	-- Default TBDs to not show links
	local showLink = Logic.nilOr(props.showLink, not Opponent.isTbd(opponent))

	if Opponent.typeIsParty(opponent.type) then
		return StarcraftOpponentDisplay.BlockPlayers(
			Table.merge(props, {showLink = showLink})
		)
	end

	if props.showTbd == false and Opponent.isTbd(opponent) then
		return Html.Fragment{}
	end
	return OpponentDisplay.BlockOpponent(props)
end

---@param props {css: HtmlStyleProps?, children: Renderable|Renderable[]?}
---@return VNode
local function createFactionNode(props)
	return Html.Div{
		classes = {'starcraft-block-archon-race'},
		css = props.css,
		children = props.children,
	}
end

---Displays a player opponent (solo, duo, trio, or quad) as a block element.
---@param props StarcraftBlockOpponentProps
---@return Renderable
function StarcraftOpponentDisplay.BlockPlayers(props)
	local opponent = props.opponent
	local showFaction = props.showFaction ~= false

	if not showFaction or (not opponent.isArchon and not opponent.isSpecialArchon) then
		return OpponentDisplay.BlockPlayers(props)
	end

	local playerNodes = OpponentDisplay.getBlockPlayerNodes(Table.merge(props, {showFaction = false}))

	if opponent.isArchon then
		return StarcraftOpponentDisplay.BlockArchon{
			flip = props.flip,
			playerNodes = playerNodes,
			factionNode = createFactionNode{
				children = Faction.Icon{size = 'large', faction = opponent.players[1].faction}
			},
			additionalClasses = {'block-players-wrapper'}
		}
	end

	-- remaining case: opponent.isSpecialArchon
	return Html.Div{
		classes = {'starcraft-special-archon-block-opponent', 'block-players-wrapper'},
		children = Array.mapRange(1, #opponent.players / 2, function (archonIx)
			local primaryFaction = opponent.players[2 * archonIx - 1].faction
			local secondaryFaction = opponent.players[2 * archonIx].faction
			local primaryIcon = Faction.Icon{size = 'large', faction = primaryFaction}
			local secondaryIcon
			if primaryFaction ~= secondaryFaction then
				secondaryIcon = Html.Div{
					css = {
						position = 'absolute',
						right = '1px',
						bottom = '1px',
					},
					children = Faction.Icon{faction = secondaryFaction}
				}
			end
			local factionNode = createFactionNode{
				css = {position = 'relative'},
				children = {primaryIcon, secondaryIcon}
			}

			return StarcraftOpponentDisplay.BlockArchon({
				flip = props.flip,
				playerNodes = Array.sub(playerNodes, 2 * archonIx - 1, 2 * archonIx),
				factionNode = factionNode,
			})
		end)
	}
end

---Displays a block archon opponent
---@param props {flip: boolean?, playerNodes: Html[], factionNode: VNode, additionalClasses: string[]?}
---@return Widget
function StarcraftOpponentDisplay.BlockArchon(props)
	return Html.Div{
		classes = Array.extend(
			'starcraft-block-archon',
			props.flip and 'flipped' or nil,
			props.additionalClasses
		),
		children = WidgetUtil.collect(
			props.factionNode,
			Html.Div{
				classes = {'starcraft-block-archon-players'},
				children = props.playerNodes
			}
		)
	}
end

StarcraftOpponentDisplay.CheckMark =
	Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', screenReaderHidden = true}

---Displays a score within the context of an inline element
---@param opponent StarcraftStandardOpponent
---@return string
function StarcraftOpponentDisplay.InlineScore(opponent)
	local scoreDisplay = OpponentDisplay.InlineScore(opponent)

	if Logic.readBool(opponent.extradata.noscore) then
		return (opponent.placement == 1 or opponent.advances)
			and StarcraftOpponentDisplay.CheckMark
			or ''
	end

	---@param value number
	---@param TitleStart string
	---@return string?
	local makeAbbrScoreInfo = function(value, TitleStart)
		if opponent.status ~= 'S' or value <= 0 then
			return
		end
		local title = TitleStart .. ' of ' .. value .. ' game' .. (value > 1 and 's' or '')
		return '<abbr title="' .. title .. '">' .. scoreDisplay .. '</abbr>'
	end
	local advantage = tonumber(opponent.extradata.advantage) or 0
	local penalty = tonumber(opponent.extradata.penalty) or 0
	return makeAbbrScoreInfo(advantage, 'Advantage') or makeAbbrScoreInfo(penalty, 'Penalty') or scoreDisplay
end

return StarcraftOpponentDisplay
