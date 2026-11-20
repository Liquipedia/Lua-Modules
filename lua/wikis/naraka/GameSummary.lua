---
-- @Liquipedia
-- page=Module:GameSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--


local Lua = require('Module:Lua')
local Html = Lua.import('Module:Widget/Html')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')

local HeroPicks = Lua.import('Module:HeroPicks')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local SummaryHelper = Lua.import('Module:MatchSummary/Base/Ffa')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')

local CustomGameSummary = {}

local HERO_SLOT_COUNT = 3
local MARTIAL_ARTS_MAP = 'martial arts showdown'

local function isMartialArts(mapName)
	return type(mapName) == 'string'
		and mw.text.trim(mapName):lower():gsub('_', ' ') == MARTIAL_ARTS_MAP
end

local function heroAt(opponent, slot)
	local picks = (opponent.extradata or {}).heroes or {}
	return HeroPicks.lookup(picks[tostring(slot)] or picks[slot])
end

local function getHeroLayout(game)
	local lastSlot = 0
	local useThreeSlots = isMartialArts(game.map) or isMartialArts(game.mapDisplayName)
	local placeholder
	for _, opponent in ipairs(game.opponents or {}) do
		useThreeSlots = useThreeSlots or opponent.type == 'team'
		for slot = 1, HERO_SLOT_COUNT do
			local hero = heroAt(opponent, slot)
			if hero then
				placeholder = placeholder or hero
				lastSlot = math.max(lastSlot, slot)
			end
		end
	end
	if not placeholder then
		return nil
	end
	return {
		slotCount = (useThreeSlots or lastSlot > 1) and HERO_SLOT_COUNT or 1,
		placeholder = placeholder,
	}
end

local function renderHeroes(opponent, layout)
	local icons = {}
	for slot = 1, layout.slotCount do
		local hero = opponent and heroAt(opponent, slot)
		if hero then
			icons[slot] = Html.Span{
				classes = {'brkts-popup-side-color', 'brkts-popup-side-color--red'},
				children = IconImage{
					imageLight = hero.file,
					size = '60px',
					caption = hero.page,
					link = hero.page,
				},
			}
		else
			icons[slot] = Html.Span{
				classes = {'invisible'},
				attributes = {['aria-hidden'] = 'true'},
				children = IconImage{
					imageLight = layout.placeholder.file,
					size = '60px',
					link = '',
				},
			}
		end
	end

	return Html.Div{
		classes = {'brkts-champion-icon', 'justify-content-center'},
		children = icons,
	}
end

local function renderHeroHeader(layout)
	return Html.Div{
		classes = {'position-relative', 'd-flex', 'align-items-center', 'justify-content-center'},
		children = {
			renderHeroes(nil, layout),
			Html.Span{classes = {'position-absolute'}, children = 'Hero Pick'},
		},
	}
end

function CustomGameSummary.adjustGameStandingsColumns(defaultColumns, game)
	local layout = getHeroLayout(game)
	if not layout then
		return defaultColumns
	end

	local columns = {}
	for _, column in ipairs(defaultColumns) do
		if column.id == 'totalPoints' then
			table.insert(columns, {
				id = 'hero',
				header = {value = renderHeroHeader(layout)},
				row = {
					value = function(opponent)
						return renderHeroes(opponent, layout)
					end,
				},
			})
		end
		table.insert(columns, column)
	end
	return columns
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
