---
-- @Liquipedia
-- page=Module:OpponentDisplay/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Faction = Lua.import('Module:Faction')
local Icon = Lua.import('Module:Icon')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Opponent = Lua.import('Module:Opponent')
local OpponentDisplay = Lua.import('Module:OpponentDisplay')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

--Display components for opponents used by the starcraft and starcraft 2 wikis
---@class StarcraftOpponentDisplay: OpponentDisplay
local StarcraftOpponentDisplay = Table.copy(OpponentDisplay)

---@class StarcraftBlockOpponentProps: BlockOpponentProps
---@field opponent StarcraftStandardOpponent

---Display component for an opponent entry appearing in a bracket match.
---@class StarcraftBracketOpponentEntry
---@operator call(...): StarcraftBracketOpponentEntry
---@field content Html
---@field root Html
local BracketOpponentEntry = Class.new(OpponentDisplay.BracketOpponentEntry,
	---@param self self
	---@param opponent StarcraftStandardOpponent
	---@param options {forceShortName: boolean, showTbd: boolean}
	function(self, opponent, options)
		local showFactionBackground = opponent.type == Opponent.solo
			or opponent.type == Opponent.duo and opponent.isArchon

		self.content = mw.html.create('div'):addClass('brkts-opponent-entry-left')
			:addClass(showFactionBackground and Faction.bgClass(opponent.players[1].faction) or nil)

		if opponent.type == Opponent.team then
			if options.showTbd ~= false or not Opponent.isTbd(opponent) then
				self:createTeam(opponent.template or 'tbd', options)
			end
		elseif Opponent.typeIsParty(opponent.type) then
			self.content:node(StarcraftOpponentDisplay.BlockOpponent{
				opponent = opponent,
				overflow = 'ellipsis',
				playerClass = 'starcraft-bracket-block-player',
				showLink = false,
				showTbd = options.showTbd,
			})
		else
			self:createLiteral(opponent.name or '')
		end

		self.root = mw.html.create('div'):addClass('brkts-opponent-entry')
			:node(self.content)
	end
)

---Adds scores to BracketOpponentEntry
---@param opponent StarcraftStandardOpponent
function BracketOpponentEntry:addScores(opponent)
	self.root:node(OpponentDisplay.BracketScore{
		isWinner = opponent.placement == 1 or opponent.advances,
		scoreText = StarcraftOpponentDisplay.InlineScore(opponent),
	})

	if opponent.score2 then
		self.root:node(OpponentDisplay.BracketScore{
			isWinner = opponent.placement2 == 1,
			scoreText = StarcraftOpponentDisplay.InlineScore2(opponent),
		})
	end

	if (opponent.placement2 or opponent.placement or 0) == 1
		or opponent.advances then
		self.content:addClass('brkts-opponent-win')
	end
end

StarcraftOpponentDisplay.BracketOpponentEntry = BracketOpponentEntry

---Displays an opponent as a block element. The width of the component is
---determined by its layout context, and not of the opponent.
---@param props StarcraftBlockOpponentProps
---@return Widget
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
		return HtmlWidgets.Fragment{}
	end
	return OpponentDisplay.BlockOpponent(props)
end

---Displays a player opponent (solo, duo, trio, or quad) as a block element.
---@param props StarcraftBlockOpponentProps
---@return Widget
function StarcraftOpponentDisplay.BlockPlayers(props)
	local opponent = props.opponent
	local showFaction = props.showFaction ~= false

	if not showFaction or (not opponent.isArchon and not opponent.isSpecialArchon) then
		return OpponentDisplay.BlockPlayers(props)
	end

	local playerNodes = OpponentDisplay.getBlockPlayerNodes(Table.merge(props, {showFaction = false}))

	if opponent.isArchon then
		local factionIcon = Faction.Icon{size = 'large', faction = opponent.players[1].faction}
		return StarcraftOpponentDisplay.BlockArchon{
			flip = props.flip,
			playerNodes = playerNodes,
			factionNode = mw.html.create('div'):wikitext(factionIcon),
			additionalClasses = {'block-players-wrapper'}
		}
	end

	-- remaining case: opponent.isSpecialArchon
	return HtmlWidgets.Div{
		classes = {'starcraft-special-archon-block-opponent', 'block-players-wrapper'},
		children = Array.map(Array.range(1, #opponent.players / 2), function (archonIx)
			local primaryFaction = opponent.players[2 * archonIx - 1].faction
			local secondaryFaction = opponent.players[2 * archonIx].faction
			local primaryIcon = Faction.Icon{size = 'large', faction = primaryFaction}
			local secondaryIcon
			if primaryFaction ~= secondaryFaction then
				secondaryIcon = mw.html.create('div')
					:css('position', 'absolute')
					:css('right', '1px')
					:css('bottom', '1px')
					:node(Faction.Icon{faction = secondaryFaction})
			end
			local factionNode = mw.html.create('div')
				:css('position', 'relative')
				:node(primaryIcon)
				:node(secondaryIcon)

			return StarcraftOpponentDisplay.BlockArchon({
				flip = props.flip,
				playerNodes = Array.sub(playerNodes, 2 * archonIx - 1, 2 * archonIx),
				factionNode = factionNode,
			})
		end)
	}
end

---Displays a block archon opponent
---@param props {flip: boolean?, playerNodes: Html[], factionNode: Html, additionalClasses: string[]?}
---@return Widget
function StarcraftOpponentDisplay.BlockArchon(props)
	props.factionNode:addClass('starcraft-block-archon-race')

	return HtmlWidgets.Div{
		classes = Array.extend(
			'starcraft-block-archon',
			props.flip and 'flipped' or nil,
			props.additionalClasses
		),
		children = WidgetUtil.collect(
			props.factionNode,
			HtmlWidgets.Div{
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
