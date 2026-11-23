---
-- @Liquipedia
-- page=Module:GameSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local HeroPicks = Lua.import('Module:HeroPicks')
local Opponent = Lua.import('Module:Opponent')
local String = Lua.import('Module:StringUtils')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local SummaryHelper = Lua.import('Module:MatchSummary/Base/Ffa')

local Html = Lua.import('Module:Widget/Html')
local MatchSummaryCharacter = Lua.import('Module:Widget/Match/Summary/Character')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')

local CustomGameSummary = {}

local HERO_SLOT_COUNT = 3
local MARTIAL_ARTS_MAP = 'martial arts showdown'

---@param mapName string?
---@return boolean
local function isMartialArts(mapName)
	return type(mapName) == 'string'
		and String.trim(mapName):lower():gsub('_', ' ') == MARTIAL_ARTS_MAP
end

---@param opponent table
---@param slot integer
---@return table?
local function heroAt(opponent, slot)
	local picks = (opponent.extradata or {}).heroes or {}
	return HeroPicks.lookup(picks[tostring(slot)] or picks[slot])
end

---@param game table
---@return table?
local function getHeroLayout(game)
	local opponents = game.opponents or {}

	local useThreeSlots = isMartialArts(game.map) or isMartialArts(game.mapDisplayName)
		or Array.any(opponents, function(opponent)
			return opponent.type == Opponent.team
		end)

	local placeholder
	Array.forEach(opponents, function(opponent)
		if placeholder then
			return
		end

		for heroIndex = 1, HERO_SLOT_COUNT do
			local hero = heroAt(opponent, heroIndex)
			if hero then
				placeholder = hero
				return
			end
		end
	end)

	if not placeholder then
		return nil
	end

	local hasMoreThan1Slot = Array.any(opponents, function(opponent)
		return Array.any(Array.range(2, HERO_SLOT_COUNT), function(heroIndex)
			return heroAt(opponent, heroIndex) ~= nil
		end)
	end)

	return {
		slotCount = (useThreeSlots or hasMoreThan1Slot) and HERO_SLOT_COUNT or 1,
		placeholder = placeholder,
	}
end

---@param layout table
---@param opponent table?
---@return VNode
local function renderHeroes(layout, opponent)
	local icons = Array.mapRange(1, layout.slotCount, function(slot)
		local hero = opponent and heroAt(opponent, slot)

		if hero then
			return MatchSummaryCharacter{
				character = hero.page,
				size = '60px',
				bg = 'brkts-popup-side-color--red',
				classes = {'brkts-popup-side-color'},
			}
		end

		return Html.Span{
			classes = {'invisible'},
			attributes = {['aria-hidden'] = 'true'},
			children = MatchSummaryCharacter{
				character = layout.placeholder.page,
				size = '60px',
			},
		}
	end)

	return Html.Div{
		classes = {'brkts-champion-icon', 'justify-content-center'},
		children = icons,
	}
end

---@param layout table
---@return VNode
local function renderHeroHeader(layout)
	return Html.Div{
		classes = {'position-relative', 'd-flex', 'align-items-center', 'justify-content-center'},
		children = {
			renderHeroes(layout),
			Html.Span{
				classes = {'position-absolute'},
				children = 'Hero Pick',
			},
		},
	}
end

---@param defaultColumns table[]
---@param game table
---@return table[]
function CustomGameSummary.adjustGameStandingsColumns(defaultColumns, game)
	local layout = getHeroLayout(game)
	if not layout then
		return defaultColumns
	end

	return Array.flatMap(defaultColumns, function(column)
		if column.id ~= 'totalPoints' then
			return {column}
		end

		return {
			{
				id = 'hero',
				header = {value = renderHeroHeader(layout)},
				row = {
					value = function(opponent)
						return renderHeroes(layout, opponent)
					end,
				},
			},
			column,
		}
	end)
end

---@param props {bracketId: string, matchId: string, gameIdx: integer}
---@return Html
function CustomGameSummary.getGameByMatchId(props)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)
	---@cast match FFAMatchGroupUtilMatch

	local game = match.games[props.gameIdx]
	assert(game, 'Error Game ID ' .. tostring(props.gameIdx) .. ' not found')

	game.stream = match.stream
	game.extradata.settings = match.extradata.settings

	SummaryHelper.updateGameOpponents(match, game)

	return MatchSummaryWidgets.Tab{
		matchId = match.matchId,
		idx = props.gameIdx,
		children = {
			MatchSummaryWidgets.GameDetails{game = game},
			MatchSummaryWidgets.Mvp(game.extradata.mvp),
			SummaryHelper.standardGame(game, CustomGameSummary),
		},
	}
end

return CustomGameSummary
