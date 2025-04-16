---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/SingleGame
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DisplayUtil = require('Module:DisplayUtil')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local SingleGameDisplay = {}

---@class SingleGameConfigOptions
---@field GameSummaryContainer function?

---@param args table
---@return table
function SingleGameDisplay.configFromArgs(args)
	return {}
end

---Display component for a single game. The single game is specified by matchID + gameIdx.
---The component fetches the match&game data from LPDB.
---@param props {matchId: string, gameIdx: integer, config: SingleGameConfigOptions}
---@return Html
function SingleGameDisplay.SingleGameContainer(props)
	local bracketId, _ = MatchGroupUtil.splitMatchId(props.matchId)

	assert(bracketId, 'Missing or invalid matchId')
	assert(props.gameIdx, 'Missing gameIdx')

	local match = MatchGroupUtil.fetchMatchForBracketDisplay(bracketId, props.matchId)
	return match
		and SingleGameDisplay.SingleGame({
			config = props.config,
			match = match,
			gameIdx = props.gameIdx,
		})
		or mw.html.create()
end

---Display component for a singleGame. Match & Game data is specified in the input.
---@param props {config: SingleGameConfigOptions, match: MatchGroupUtilMatch, gameIdx: integer}
---@return Html
function SingleGameDisplay.SingleGame(props)
	local propsConfig = props.config or {}
	local config = {
		GameSummaryContainer = propsConfig.GameSummaryContainer or DisplayHelper.DefaultGameSummaryContainer,
	}

	return SingleGameDisplay.Game{
		GameSummaryContainer = config.GameSummaryContainer,
		match = props.match,
		gameIdx = props.gameIdx,
	}
end

---Display component for a match in a single game. Consists of the game summary.
---@param props {GameSummaryContainer: function, match: MatchGroupUtilMatch, gameIdx: integer}
---@return Html
function SingleGameDisplay.Game(props)
	local bracketId = MatchGroupUtil.splitMatchId(props.match.matchId)
	return DisplayUtil.TryPureComponent(props.GameSummaryContainer, {
		bracketId = bracketId,
		matchId = props.match.matchId,
		gameIdx = props.gameIdx,
	}, require('Module:Error/Display').ErrorList)
end

return SingleGameDisplay
