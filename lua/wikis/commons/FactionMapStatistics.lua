---
-- @Liquipedia
-- page=Module:FactionMapStatistics
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Faction = Lua.import('Module:Faction')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local MathUtil = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local Link = Lua.import('Module:Widget/Basic/Link')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DEFAULT_MAP_NAME = 'Unknown'
local SUM_ABBR = HtmlWidgets.Abbr{title = 'Sum of', children = 'Σ'}
local NUMBER_OF_ABBR = HtmlWidgets.Abbr{title = 'Number of', children = '#'}

local MapStatistics = {}

---@param frame Frame
---@return Widget?
function MapStatistics.run(frame)
	local args = Arguments.getArgs(frame)

	local matchUps = MapStatistics._getMatchups()
	local mapsData = MapStatistics._fetchData(args, matchUps)
	if Logic.isEmpty(mapsData) then
		return
	end
	---@cast mapsData -nil

	if args.mode == 'mapStats' then
		Array.forEach(mapsData, MapStatistics._store)
	end

	return TableWidgets.Table{
		sortable = true,
		columns = WidgetUtil.collect(
			{align = 'left'},
			Array.rep({align = 'right'}, 1 + 4 * #matchUps.vs + #matchUps.mirrors)
		),
		children = {
			MapStatistics._header(matchUps),
			TableWidgets.TableBody{
				children = Array.map(mapsData, FnUtil.curry(MapStatistics._row, matchUps))
			}
		}
	}
end

---@return {vs: string[], mirrors: string[]}
function MapStatistics._getMatchups()
	local vs = {}
	local done = {}

	---@param faction1 string
	---@param faction2 string
	---@return boolean
	local alreadyDone = function(faction1, faction2)
		if done[faction1 .. ',' .. faction2] then
			return true
		end
		done[faction1 .. ',' .. faction2] = true
		if done[faction2 .. ',' .. faction1] then
			return true
		end
		done[faction2 .. ',' .. faction1] = true
		return false
	end

	--- this loop is only wanted/needed so that each faction is on the left at least once...
	Array.forEach(Faction.coreFactions, function(faction, factionIndex)
		local nextFaction = Faction.coreFactions[factionIndex + 1] or Faction.coreFactions[1]
		if faction == nextFaction or alreadyDone(faction, nextFaction) then
			return
		end
		table.insert(vs, faction .. ',' .. nextFaction)
	end)

	Array.forEach(Faction.coreFactions, function(faction1)
		Array.forEach(Faction.coreFactions, function(faction2)
			if not alreadyDone(faction1, faction2) then
				table.insert(vs, faction1 .. ',' .. faction2)
			end
		end)
	end)

	return {
		vs = vs,
		mirrors = Table.copy(Faction.coreFactions), -- copy to remove the metatable which breaks some stuff
	}
end

---@param args table
---@param matchUps {vs: string[], mirrors: string[]}
---@return {map: string, mapDisplayName: string?, total: integer,
---vs: table<string, {w: integer, l: integer}>, mirrors: table<string, integer>}[]?
function MapStatistics._fetchData(args, matchUps)
	---@param gameData match2game?
	---@return {map: string, mapDisplayName: string?, total: integer,
	---vs: table<string, {w: integer, l: integer}>, mirrors: table<string, integer>}?
	local makeInitialMapData = function(gameData)
		return {
			map = (gameData or {}).map or 'total',
			mapDisplayName = ((gameData or {}).extradata or {}).displayname,
			total = 0,
			vs = Table.map(matchUps.vs, function(index, key) return key, {w = 0, l = 0} end),
			mirrors = Table.map(matchUps.mirrors, function(index, key) return key, 0 end),
		}
	end

	---@param gameData match2game
	---@return boolean
	local isValidGame = function(gameData)
		local map = gameData.map
		return map ~= 'skip'
			and (map or ''):lower() ~= 'submatch'
			and #gameData.opponents == 2
			and Array.all(gameData.opponents, function(opponent)
				return opponent.status == 'S'
			end)
	end

	local data = {total = makeInitialMapData()}

	---@param map string
	---@param faction1 string
	---@param faction2 string
	---@param winnerScore integer
	---@param loserScore integer
	local apply = function(map, faction1, faction2, winnerScore, loserScore)
		if faction1 == faction2 then
			data[map].mirrors[faction1] = data[map].mirrors[faction1] + winnerScore + loserScore
			data[map].total = data[map].total + winnerScore + loserScore
			return
		end

		local matchUp = faction1 .. ',' .. faction2
		if not data[map].vs[matchUp] then
			matchUp = faction2 .. ',' .. faction1
			winnerScore, loserScore = loserScore, winnerScore
		end

		data[map].vs[matchUp].w = data[map].vs[matchUp].w + winnerScore
		data[map].vs[matchUp].l = data[map].vs[matchUp].l + loserScore
		data[map].total = data[map].total + winnerScore + loserScore
	end

	Lpdb.executeMassQuery('match2game', {
		conditions = MapStatistics._buildConditions(args),
		query = 'map, extradata, opponents, winner',
	}, function(gameData)
		if not isValidGame(gameData) then
			return
		end

		local map = gameData.map

		if Logic.isEmpty(map) or string.lower(map) == 'tbd' then
			map = DEFAULT_MAP_NAME
		end
		data[map] = data[map] or makeInitialMapData(gameData)

		local winnerFaction = gameData.extradata.winnerfaction
		if not Table.includes(Faction.coreFactions, winnerFaction) then
			return
		end

		local loserFaction = gameData.extradata.loserfaction
		if not Table.includes(Faction.coreFactions, loserFaction) then
			return
		end

		local winnerIndex = tonumber(gameData.winner) or 0
		local loserIndex = 3 - winnerIndex
		local winnerScore = gameData.opponents[winnerIndex].score or 0
		local loserScore = gameData.opponents[loserIndex].score or 0

		apply(map, winnerFaction, loserFaction, winnerScore, loserScore)
		apply('total', winnerFaction, loserFaction, winnerScore, loserScore)
	end)

	local total = Table.extract(data, 'total')
	local unknown = Table.extract(data, DEFAULT_MAP_NAME)
	local mapsData = Array.extractValues(data)

	return Array.appendWith(
		mapsData,
		Logic.nilOr(Logic.readBoolOrNil(args.unknown), true) and unknown or nil,
		#mapsData > 1 and total or nil
	)
end

---@param args table
---@return string
function MapStatistics._buildConditions(args)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('status'), Comparator.eq, ''),
		ConditionNode(ColumnName('mode'), Comparator.eq, '1v1'),
	}

	local startDate = DateExt.readTimestamp(args.sdate)
	if startDate then
		conditions:add(ConditionNode(ColumnName('date'), Comparator.ge, startDate))
	end
	local endDate = DateExt.readTimestamp(args.edate)
	if endDate then
		conditions:add(ConditionNode(ColumnName('date'), Comparator.le, endDate))
	end

	local mapsInput = args.maps or args.map
		or args.mode == 'mapStats' and mw.title.getCurrentTitle().text
		or nil
	local maps = Array.parseCommaSeparatedString(mapsInput)
	maps = Array.filter(maps, function(map) return map ~= 'TBD' end)
	if Logic.isNotEmpty(maps) then
		conditions:add(ConditionUtil.anyOf(ColumnName('map'), maps))
	end

	local parents = Array.parseCommaSeparatedString(args.parents or args.parent)
	if Logic.isNotEmpty(parents) then
		conditions:add(ConditionUtil.anyOf(ColumnName('parent'), Array.map(parents, Page.pageifyLink)))
	end

	local tournaments = MapStatistics._getTournaments(args)
	if Logic.isNotEmpty(tournaments) then
		---@cast tournaments -nil
		conditions:add(ConditionUtil.anyOf(ColumnName('pagename'), Array.map(tournaments, Page.pageifyLink)))
	end

	return tostring(conditions)
end

---@param mapData {map: string, mapDisplayName: string?, total: integer,
---vs: table<string, {w: integer, l: integer}>, mirrors: table<string, integer>}
function MapStatistics._store(mapData)
	if Lpdb.isStorageDisabled() or mapData.map == 'Unknown' then
		return
	end

	local ratios = {}
	for key, winData in pairs(mapData.vs) do
		local factions = Array.parseCommaSeparatedString(key)
		local total = winData.w + winData.l
		local ratio = total ~= 0 and (winData.w / total) or nil
		ratios[factions[1] .. factions[2]] = ratio
		ratios[factions[2] .. factions[1]] = ratio and (1 - ratio) or nil
	end

	mw.ext.LiquipediaDB.lpdb_datapoint(
		'map_winrates_' .. mapData.map,
		{
			name = mapData.map,
			type = 'map_winrates',
			extradata = Json.stringify(ratios),
		}
	)
end

---@param args table
---@return string[]?
function MapStatistics._getTournaments(args)
	---@param series string?
	---@return string[]?
	local fromSeries = function(series)
		if Logic.isEmpty(series) then
			return
		end
		local tournaments = mw.ext.LiquipediaDB.lpdb('tournament', {
			conditions = tostring(ConditionNode(ColumnName('seriespage'), Comparator.eq, Page.pagifyLink(series))),
			query = 'pagename',
			limit = 5000
		})
		return Array.map(tournaments, Operator.property('pagename'))
	end

	return Logic.nilIfEmpty(Array.parseCommaSeparatedString(args.tournaments or args.tournament))
		or Logic.nilIfEmpty(fromSeries(args.series))
		or args.mode == 'tournamentStats' and {mw.title.getCurrentTitle().text}
		or nil
end

---@param matchUps {vs: string[], mirrors: string[]}
---@return Widget
function MapStatistics._header(matchUps)
	---@param key string
	---@return Widget
	local makeFactionHeader = function(key)
		local factions = Array.parseCommaSeparatedString(key)

		return TableWidgets.CellHeader{
			colspan = 4,
			align = 'center',
			children = {
				Faction.Icon{faction = factions[1]},
				' vs. ',
				Faction.Icon{faction = factions[2]},
			},
		}
	end

	---@param key string
	---@return Widget[]
	local makeMatchUpHeader = function(key)
		local factions = Array.parseCommaSeparatedString(key)
		return {
			TableWidgets.CellHeader{children = SUM_ABBR},
			TableWidgets.CellHeader{children = Faction.Icon{faction = factions[1]}},
			TableWidgets.CellHeader{children = Faction.Icon{faction = factions[2]}},
			TableWidgets.CellHeader{
				children = {
					Faction.Icon{faction = factions[1]},
					'%'
				}
			},
		}
	end

	return TableWidgets.TableHeader{
		children = {
			TableWidgets.Row{
				children = WidgetUtil.collect(
					TableWidgets.CellHeader{children = '', colspan = 2},
					Array.map(matchUps.vs, makeFactionHeader),
					TableWidgets.CellHeader{children = 'Mirrors', align = 'center', colspan = #matchUps.mirrors}
				)
			},
			TableWidgets.Row{
				children = WidgetUtil.collect(
					TableWidgets.CellHeader{children = 'Map'},
					TableWidgets.CellHeader{children = NUMBER_OF_ABBR},
					Array.flatMap(matchUps.vs, makeMatchUpHeader),
					Array.map(matchUps.mirrors, function(faction)
						return TableWidgets.CellHeader{children = Faction.Icon{faction = faction}}
					end)
				)
			}
		},
	}
end

---@param matchUps {vs: string[], mirrors: string[]}
---@param mapData {map: string, mapDisplayName: string?, total: integer,
---vs: table<string, {w: integer, l: integer}>, mirrors: table<string, integer>}
---@return Widget?
function MapStatistics._row(matchUps, mapData)
	if Logic.isEmpty(mapData) then
		return
	end

	---@param input integer|string
	---@return integer|string
	local dashIfZero = function(input)
		return input == 0 and '-' or input
	end

	---@param matchUpData {w: integer, l: integer}
	---@return string
	local getPercentage = function(matchUpData)
		local total = matchUpData.w + matchUpData.l
		if total == 0 then
			return '-'
		end
		local percentage = 100 * matchUpData.w / (total)
		return MathUtil.formatRounded{precision = 1, value = percentage}
	end

	---@return Renderable[]|Renderable
	local makeMapCell = function()
		if mapData.map == DEFAULT_MAP_NAME then
			return DEFAULT_MAP_NAME
		end
		if mapData.map == 'total' then
			return {
				'Total Sum (',
				SUM_ABBR,
				')'
			}
		end
		return Link{link = mapData.map, children = mapData.mapDisplayName}
	end

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.Cell{
				children = makeMapCell()
			},
			TableWidgets.Cell{children = dashIfZero(mapData.total)},
			Array.flatMap(matchUps.vs, function(key)
				local matchUpData = mapData.vs[key]
				return {
					TableWidgets.Cell{children = dashIfZero(matchUpData.w + matchUpData.l)},
					TableWidgets.Cell{children = dashIfZero(matchUpData.w)},
					TableWidgets.Cell{children = dashIfZero(matchUpData.l)},
					TableWidgets.Cell{children = getPercentage(matchUpData)},
				}
			end),
			Array.map(matchUps.mirrors, function(faction)
				return TableWidgets.Cell{children = dashIfZero(mapData.mirrors[faction])}
			end)
		)
	}
end

return MapStatistics
