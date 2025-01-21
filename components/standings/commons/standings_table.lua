---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Lua = require('Module:Lua')

local StandingsParseWiki = Lua.import('Module:Standings/Parse/Wiki')
local StandingsParser = Lua.import('Module:Standings/Parser')
local StandingsStorage = Lua.import('Module:Standings/Storage')

local Display = Lua.import('Module:Widget/Standings')

local StandingsTable = {}

---@param frame Frame
---@return Widget
function StandingsTable.fromTemplate(frame)
	local args = Arguments.getArgs(frame)
	local tableType = args.tabletype
	if tableType ~= 'ffa' then
		error('Unknown Standing Table Type')
	end
	local parsedData = StandingsParseWiki.parseWikiInput(args)
	return StandingsTable.ffa(
		parsedData.rounds,
		parsedData.opponents,
		parsedData.bgs,
		args.title,
		parsedData.matches
	)
end

---@param rounds any
---@param opponents any
---@param bgs any
---@param title any
---@param matches any
---@return Widget
function StandingsTable.ffa(rounds, opponents, bgs, title, matches)
	local standingsTable = StandingsParser.parse(rounds, opponents, bgs, title, matches)
	StandingsStorage.run(standingsTable)
	return Display{pageName = mw.title.getCurrentTitle().text, standingsIndex = standingsTable.standingsindex}
end

return StandingsTable
