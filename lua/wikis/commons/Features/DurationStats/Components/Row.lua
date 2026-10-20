---
-- @Liquipedia
-- page=Module:Features/DurationStats/Components/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Util = Lua.import('Module:Features/DurationStats/Lib/Util')

local Component = Lua.import('Module:Widget/Component')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DurationStatsVodLink = Lua.import('Module:Features/DurationStats/Components/VodLink')

---@param opponent standardOpponent?
---@return Renderable?
local function displayOpponent(opponent)
	if not opponent then return end
	return OpponentDisplay.BlockOpponent{opponent = opponent, teamStyle = 'short'}
end

---@param props {entry: DurationStatsEntry, showVod: boolean?}
---@return Renderable
local function DurationStatsRow(props)
	local entry = props.entry
	local game = entry.game
	local winner, loser = Util.getWinnerAndLoser(entry.match, game.winner)

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.Cell{children = DateExt.toYmdInUtc(game.date)},
			TableWidgets.Cell{children = Link{link = game.pagename, children = Util.getStageName(entry.match)}},
			TableWidgets.Cell{children = game.match2gameid},
			TableWidgets.Cell{children = displayOpponent(winner)},
			TableWidgets.Cell{children = displayOpponent(loser)},
			TableWidgets.Cell{children = game.length},
			Logic.readBool(props.showVod) and TableWidgets.Cell{children = DurationStatsVodLink.display(entry)} or nil
		)
	}
end

return Component.component(DurationStatsRow)
