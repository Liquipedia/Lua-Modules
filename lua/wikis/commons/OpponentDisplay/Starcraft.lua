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
local StarcraftPlayerDisplay = Lua.import('Module:Player/Display/Starcraft')

--Display components for opponents used by the starcraft and starcraft 2 wikis
---@class StarcraftOpponentDisplay: OpponentDisplay
local StarcraftOpponentDisplay = Table.copy(OpponentDisplay)

---@class StarcraftInlineOpponentProps: InlineOpponentProps
---@field opponent StarcraftStandardOpponent
---@field showFaction boolean?

---@class StarcraftBlockOpponentProps: BlockOpponentProps
---@field opponent StarcraftStandardOpponent
---@field showFaction boolean?

---Display component for an opponent entry appearing in a bracket match.
---@class StarcraftBracketOpponentEntry
---@operator call(...): StarcraftBracketOpponentEntry
---@field content Html
---@field root Html
local BracketOpponentEntry = Class.new(
	---@param self self
	---@param opponent StarcraftStandardOpponent
	---@param options {forceShortName: boolean}
	function(self, opponent, options)
		local showFactionBackground = opponent.type == Opponent.solo
			or opponent.extradata.hasFactionOrFlag
			or opponent.type == Opponent.duo and opponent.isArchon

		self.content = mw.html.create('div'):addClass('brkts-opponent-entry-left')
			:addClass(showFactionBackground and Faction.bgClass(opponent.players[1].faction) or nil)

		if opponent.type == Opponent.team then
			self.content:node(OpponentDisplay.BlockTeamContainer({
				showLink = false,
				style = 'hybrid',
				team = opponent.team,
				template = opponent.template,
			}))
		else
			self.content:node(StarcraftOpponentDisplay.BlockOpponent({
				opponent = opponent,
				overflow = 'ellipsis',
				playerClass = 'starcraft-bracket-block-player',
				showLink = false,
			}))
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

---Displays an opponent as an inline element. Useful for describing opponents in prose.
---@param props StarcraftInlineOpponentProps
---@return Html|string|nil
function StarcraftOpponentDisplay.InlineOpponent(props)
	local opponent = props.opponent

	if Opponent.typeIsParty((opponent or {}).type) then
		return mw.html.create()
			:node(StarcraftOpponentDisplay.InlinePlayers(props))
			:node(props.note and mw.html.create('sup'):addClass('note'):wikitext(props.note) or '')
	end

	return OpponentDisplay.InlineOpponent(props)
end

---Displays an opponent as a block element. The width of the component is
---determined by its layout context, and not of the opponent.
---@param props StarcraftBlockOpponentProps
---@return Html
function StarcraftOpponentDisplay.BlockOpponent(props)
	local opponent = props.opponent
	opponent.extradata = opponent.extradata or {}
	-- Default TBDs to not show links
	local showLink = Logic.nilOr(props.showLink, not Opponent.isTbd(opponent))

	if opponent.type == Opponent.team then
		return OpponentDisplay.BlockTeamContainer({
			flip = props.flip,
			overflow = props.overflow,
			showLink = showLink,
			style = props.teamStyle,
			team = opponent.team,
			template = opponent.template or 'tbd',
		})
	elseif opponent.type == 'literal' and opponent.extradata.hasFactionOrFlag then
		return StarcraftOpponentDisplay.PlayerBlockOpponent(
			Table.merge(props, {showLink = showLink})
		)
	elseif opponent.type == 'literal' then
		return OpponentDisplay.BlockOpponent(props)
	else -- opponent.type == Opponent.solo Opponent.duo Opponent.trio Opponent.quad
		return StarcraftOpponentDisplay.PlayerBlockOpponent(
			Table.merge(props, {showLink = showLink})
		)
	end
end

---Displays a player opponent (solo, duo, trio, or quad) as an inline element.
---@param props StarcraftInlineOpponentProps
---@return Html
function StarcraftOpponentDisplay.PlayerInlineOpponent(props)
	local showFaction = props.showFaction ~= false
	local opponent = props.opponent

	local playerTexts = Array.map(opponent.players, function(player)
		local node = StarcraftPlayerDisplay.InlinePlayer({
			flip = props.flip,
			player = player,
			showFlag = props.showFlag,
			showLink = props.showLink,
			showFaction = showFaction and not opponent.isArchon,
		})
		return tostring(node)
	end)
	if props.flip then
		playerTexts = Array.reverse(playerTexts)
	end

	local playersNode = opponent.isArchon
		and '(' .. table.concat(playerTexts, ', ') .. ')'
		or table.concat(playerTexts, ' / ')

	local archonFactionNode
	if showFaction and opponent.isArchon then
		archonFactionNode = Faction.Icon{faction = opponent.players[1].faction}
	end

	return mw.html.create('span')
		:node(not props.flip and archonFactionNode or nil)
		:node(playersNode)
		:node(props.flip and archonFactionNode or nil)
end

---Displays a player opponent (solo, duo, trio, or quad) as a block element.
---@param props StarcraftBlockOpponentProps
---@return Html
function StarcraftOpponentDisplay.PlayerBlockOpponent(props)
	local opponent = props.opponent
	local showFaction = props.showFaction ~= false

	--only apply note to first player, hence extract it here
	local note = Table.extract(props, 'note')

	local playerNodes = Array.map(opponent.players, function(player, playerIndex)
		return StarcraftPlayerDisplay.BlockPlayer(Table.merge(props, {
			player = player,
			team = player.team,
			note = playerIndex == 1 and note or nil,
			showFaction = showFaction and not opponent.isArchon and not opponent.isSpecialArchon,
		})):addClass(props.playerClass)
	end)

	if #opponent.players == 1 then
		return playerNodes[1]

	elseif showFaction and opponent.isArchon then
		local factionIcon = Faction.Icon{size = 'large', faction = opponent.players[1].faction}
		return StarcraftOpponentDisplay.BlockArchon({
			flip = props.flip,
			playerNodes = playerNodes,
			factionNode = mw.html.create('div'):wikitext(factionIcon),
		})
		:addClass('block-players-wrapper')

	elseif showFaction and opponent.isSpecialArchon then
		local archonsNode = mw.html.create('div')
			:addClass('starcraft-special-archon-block-opponent')
			:addClass('block-players-wrapper')
		for archonIx = 1, #opponent.players / 2 do
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

			local archonNode = StarcraftOpponentDisplay.BlockArchon({
				flip = props.flip,
				playerNodes = Array.sub(playerNodes, 2 * archonIx - 1, 2 * archonIx),
				factionNode = factionNode,
			})
			archonsNode:node(archonNode)
		end
		return archonsNode

	else
		local playersNode = mw.html.create('div')
			:addClass('block-players-wrapper')
		for _, playerNode in ipairs(playerNodes) do
			playersNode:node(playerNode)
		end
		return playersNode
	end
end

---Displays a block archon opponent
---@param props {flip: boolean?, playerNodes: Html[], factionNode: Html}
---@return Html
function StarcraftOpponentDisplay.BlockArchon(props)
	props.factionNode:addClass('starcraft-block-archon-race')

	local playersNode = mw.html.create('div'):addClass('starcraft-block-archon-players')
	for _, node in ipairs(props.playerNodes) do
		playersNode:node(node)
	end

	return mw.html.create('div'):addClass('starcraft-block-archon')
		:addClass(props.flip and 'flipped' or nil)
		:node(props.factionNode)
		:node(playersNode)
end

StarcraftOpponentDisplay.CheckMark =
	Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', screenReaderHidden = true}

---Displays a score within the context of an inline element.
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
