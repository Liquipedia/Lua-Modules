---
-- @Liquipedia
-- page=Module:GameSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local HeroPicks = Lua.import('Module:HeroPicks')
local Opponent = Lua.import('Module:Opponent/Custom')
local String = Lua.import('Module:StringUtils')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local SummaryHelper = Lua.import('Module:MatchSummary/Base/Ffa')

local Html = Lua.import('Module:Widget/Html')
local MatchSummaryCharacter = Lua.import('Module:Widget/Match/Summary/Character')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')

local CustomGameSummary = {}

local HERO_SLOT_COUNT = 3
local HERO_IMAGE_SIZE = '60px'
local HERO_SLOT_SIZE = 24
local HERO_SLOT_GAP = 2
local MARTIAL_ARTS_MAP = 'martial arts showdown'

---@class NarakaSummaryOpponent
---@field type string?
---@field extradata {heroes: table<string|integer, string>?}?

---@class NarakaSummaryGame
---@field map string?
---@field mapDisplayName string?
---@field date string?
---@field opponents NarakaSummaryOpponent[]?

---@class NarakaHeroLayout
---@field slotCount integer
---@field date string?

---@class NarakaSummaryColumn
---@field id string
---@field header table?
---@field row table?

---@param mapName string?
---@return boolean
local function isMartialArts(mapName)
	return type(mapName) == 'string'
		and String.trim(mapName):lower():gsub('_', ' ') == MARTIAL_ARTS_MAP
end

---@param opponent NarakaSummaryOpponent
---@param slot integer
---@param date string?
---@return NarakaHeroPick?
local function heroAt(opponent, slot, date)
	local picks = (opponent.extradata or {}).heroes or {}
	return HeroPicks.lookup(picks[tostring(slot)] or picks[slot], date)
end

---@param date string?
---@param opponent NarakaSummaryOpponent
---@return boolean
local function hasHero(date, opponent)
	return Array.any(Array.range(1, HERO_SLOT_COUNT), function(slot)
		return heroAt(opponent, slot, date) ~= nil
	end)
end

---@param date string?
---@param opponent NarakaSummaryOpponent
---@return boolean
local function hasAdditionalHero(date, opponent)
	return Array.any(Array.range(2, HERO_SLOT_COUNT), function(slot)
		return heroAt(opponent, slot, date) ~= nil
	end)
end

---@param game NarakaSummaryGame
---@return NarakaHeroLayout?
local function getHeroLayout(game)
	local opponents = game.opponents or {}

	if not Array.any(opponents, FnUtil.curry(hasHero, game.date)) then
		return nil
	end

	-- Preserve the existing three-slot rule.
	local useThreeSlots = isMartialArts(game.map) or isMartialArts(game.mapDisplayName)
		or Array.any(opponents, function(opponent)
			return opponent.type == Opponent.team
		end)
		or Array.any(opponents, FnUtil.curry(hasAdditionalHero, game.date))

	return {
		slotCount = useThreeSlots and HERO_SLOT_COUNT or 1,
		date = game.date,
	}
end

---@return VNode
local function renderEmptyHeroSlot()
	local size = HERO_SLOT_SIZE .. 'px'

	return Html.Span{
		attributes = {['aria-hidden'] = 'true'},
		css = {
			display = 'block',
			width = size,
			height = size,
			flex = '0 0 ' .. size,
		},
	}
end

---@param layout NarakaHeroLayout
---@param opponent NarakaSummaryOpponent
---@return VNode
local function renderHeroes(layout, opponent)
	local icons = Array.mapRange(1, layout.slotCount, function(slot)
		local hero = heroAt(opponent, slot, layout.date)

		if not hero then
			return renderEmptyHeroSlot()
		end

		return MatchSummaryCharacter{
			character = hero.page,
			date = layout.date,
			size = HERO_IMAGE_SIZE,
			bg = 'brkts-popup-side-color--red',
			classes = {'brkts-popup-side-color'},
		}
	end)

	return Html.Div{
		classes = {'brkts-champion-icon', 'justify-content-center'},
		children = icons,
	}
end

---@param layout NarakaHeroLayout
---@return VNode
local function renderHeroHeader(layout)
	local width = layout.slotCount * HERO_SLOT_SIZE
		+ (layout.slotCount - 1) * HERO_SLOT_GAP

	return Html.Div{
		css = {
			display = 'flex',
			['align-items'] = 'center',
			['justify-content'] = 'center',
			['min-width'] = width .. 'px',
			['min-height'] = HERO_SLOT_SIZE .. 'px',
		},
		children = 'Hero Pick',
	}
end

---@param defaultColumns NarakaSummaryColumn[]
---@param game NarakaSummaryGame
---@return NarakaSummaryColumn[]
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
					value = FnUtil.curry(renderHeroes, layout),
				},
			},
			column,
		}
	end)
end

---@param props {bracketId: string, matchId: string, gameIdx: integer}
---@return VNode
function CustomGameSummary.getGameByMatchId(props)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)
	---@cast match FFAMatchGroupUtilMatch

	local game = match.games[props.gameIdx]
	assert(game, 'Error Game ID ' .. tostring(props.gameIdx) .. ' not found')

	game.date = game.date or match.date
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
