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
local Table = Lua.import('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local SummaryHelper = Lua.import('Module:MatchSummary/Base/Ffa')

local Html = Lua.import('Module:Widget/Html')
local MatchSummaryCharacter = Lua.import('Module:Widget/Match/Summary/Character')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local CustomGameSummary = {}

local HERO_SLOT_COUNT = 3
local HERO_IMAGE_SIZE = '60px'
local HERO_SLOT_SIZE = 24
local HERO_SLOT_GAP = 2
local MARTIAL_ARTS_MAP = 'martial arts showdown'

---@class NarakaSummaryOpponent
---@field score number?
---@field status string?
---@field placement number?
---@field narakaScoreRank integer?
---@field type string?
---@field extradata {heroes: table<string|integer, string>?, tiebreaker: number?}?

---@class NarakaSummaryGame
---@field narakaScoreRanking boolean?
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
---@field sortable boolean?
---@field sortType string?
---@field class string?
---@field icon string?
---@field show? fun(game: NarakaSummaryGame): boolean
---@field sortVal table?

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

-- Display-only ranking: never replace placement, which is used for scoring.
---@param opponent NarakaSummaryOpponent
---@return boolean
local function hasScore(opponent)
	return (not opponent.status or opponent.status == 'S') and tonumber(opponent.score) ~= nil
end

---@param opponent NarakaSummaryOpponent
---@return number
local function tiePriority(opponent)
	return tonumber((opponent.extradata or {}).tiebreaker) or 0
end

---@param opponent NarakaSummaryOpponent
---@return number
local function scoreValue(opponent)
	-- Ignore floating-point noise in calculated scores; leave the stored score untouched.
	return math.floor(tonumber(opponent.score) * 1000000 + 0.5) / 1000000
end

---@param game NarakaSummaryGame
local function updateScoreRanks(game)
	game.narakaScoreRanking = not (isMartialArts(game.map) or isMartialArts(game.mapDisplayName))
	if not game.narakaScoreRanking then
		return
	end

	local opponents = game.opponents or {}
	local originalOrder = {}
	Array.forEach(opponents, function(opponent, index)
		originalOrder[opponent] = index
	end)
	Array.sortInPlaceBy(opponents, FnUtil.identity, function(left, right)
		local leftHasScore, rightHasScore = hasScore(left), hasScore(right)
		if leftHasScore ~= rightHasScore then
			return leftHasScore
		end
		if leftHasScore then
			local leftScore, rightScore = scoreValue(left), scoreValue(right)
			if leftScore ~= rightScore then
				return leftScore > rightScore
			end
			if tiePriority(left) ~= tiePriority(right) then
				return tiePriority(left) > tiePriority(right)
			end
		end
		-- Preserve a stable display order without claiming another official tiebreak rule.
		return originalOrder[left] < originalOrder[right]
	end)

	local previousScore, previousPriority, rank
	Array.forEach(opponents, function(opponent, index)
		opponent.narakaScoreRank = nil
		if hasScore(opponent) then
			local score, priority = scoreValue(opponent), tiePriority(opponent)
			if score ~= previousScore or priority ~= previousPriority then
				rank = index
			end
			opponent.narakaScoreRank = rank
			previousScore, previousPriority = score, priority
		end
	end)
end

---@param opponent NarakaSummaryOpponent
---@return VNode|string
local function renderScoreRank(opponent)
	local rank = opponent.narakaScoreRank
	if not rank then
		return '-'
	end
	return Html.Fragment{children = {
		MatchSummaryWidgets.Trophy{place = rank, additionalClasses = {'panel-table__cell-icon'}},
		Html.Span{children = tostring(MatchSummaryWidgets.RankRange{rankStart = rank})},
	}}
end

---@param column NarakaSummaryColumn
---@return NarakaSummaryColumn
local function scoreRankColumn(column)
	local result = Table.copy(column)
	result.header = {value = 'Score Rank', mobileValue = 'Rank'}
	result.sortVal = {value = function(opponent)
		return opponent.narakaScoreRank or 999999
	end}
	result.row = {value = renderScoreRank}
	return result
end

---@param defaultColumns NarakaSummaryColumn[]
---@param game NarakaSummaryGame
---@return NarakaSummaryColumn[]
function CustomGameSummary.adjustGameStandingsColumns(defaultColumns, game)
	local layout = getHeroLayout(game)
	local martialArts = isMartialArts(game.map) or isMartialArts(game.mapDisplayName)
	return Array.flatMap(defaultColumns, function(column)
		if martialArts and column.id == 'kills' then
			return {}
		end
		if game.narakaScoreRanking and column.id == 'rank' then
			return {scoreRankColumn(column)}
		end
		if column.id ~= 'totalPoints' then
			return {column}
		end
		local columns = {}
		if layout then
			table.insert(columns, {
				id = 'hero',
				header = {value = renderHeroHeader(layout)},
				row = {value = FnUtil.curry(renderHeroes, layout)},
			})
		end
		table.insert(columns, column)
		return columns
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
	game.extradata = game.extradata or {}
	game.extradata.settings = (match.extradata or {}).settings

	SummaryHelper.updateGameOpponents(match, game)
	updateScoreRanks(game)

	return MatchSummaryWidgets.Tab{
		matchId = match.matchId,
		idx = props.gameIdx,
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameDetails{game = game},
			(isMartialArts(game.map) or isMartialArts(game.mapDisplayName))
				and game.extradata.placementinfo and MatchSummaryWidgets.PointsDistribution{
				scores = SummaryHelper.createScoringData{extradata = game.extradata},
			} or nil,
			MatchSummaryWidgets.Mvp(game.extradata.mvp),
			SummaryHelper.standardGame(game, CustomGameSummary)
		),
	}
end

return CustomGameSummary
