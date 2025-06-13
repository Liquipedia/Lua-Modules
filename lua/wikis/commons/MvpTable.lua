---
-- @Liquipedia
-- page=Module:MvpTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local MvpTable = {}

---Entry point for MvpTable.
---Fetches mvpData for a given set of matchGroupIds or tournaments.
---Displays the fetched data as a table.
---@param args table
---@return Html|string|nil
function MvpTable.run(args)
	args = args or {}
	args = MvpTable._parseArgs(args)
	local conditions = MvpTable._buildConditions(args)
	local queryData = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = conditions,
		query = 'extradata, match2opponents',
		limit = 5000,
	})

	local mvpList

	if type(queryData) == 'table' and queryData[1] then
		--catch errors on incompatible match2 data (when not yet using standard storage)
		mvpList = Logic.tryCatch(
			function() return MvpTable.processData(queryData) end,
			function() return mw.logObject('MvpTable: match2 mvp data format invalid, querying match1 data instead') end
		)
	end

	--in case we catch it and in case we did not get match2 results
	if not mvpList then
		mvpList = MvpTable._queryMatch1(conditions)
	end

	if not mvpList then
		return
	end

	local output = mw.html.create('table')
		:addClass('wikitable prizepooltable collapsed')
		:css('text-align', 'center')
		:css('margin-top', args.margin .. 'px')
		:attr('data-opentext', 'place ' .. (args.cutafter + 1) .. ' to ' .. #mvpList)
		:attr('data-closetext', 'place ' .. (args.cutafter + 1) .. ' to ' .. #mvpList)
		:attr('data-cutafter', args.cutafter + (String.isNotEmpty(args.title) and 1 or 0))
		:attr('data-definedcutafter', '')
		:node(MvpTable._mainHeader(args))
		:node(MvpTable._subHeader(args))

	for _, item in ipairs(mvpList) do
		output:node(MvpTable._row(item, args))
	end

	return output
end

---@class mvpTableParsedArgs
---@field cutafter number
---@field margin number
---@field points boolean
---@field title string?
---@field matchGroupIds string[]
---@field tournaments string[]

---Parses the entered arguments to a table that can be used better further down the line
---@param args table
---@return mvpTableParsedArgs
function MvpTable._parseArgs(args)
	local parsedArgs = {
		cutafter = tonumber(args.cutafter) or 5,
		margin = Logic.nilOr(Logic.readBoolOrNil(args.margin), true) and 20 or 0,
		points = Logic.readBool(args.points),
		title = args.title,

		matchGroupIds = {},
		tournaments = {},
	}

	for _, matchGroupId in Table.iter.pairsByPrefix(args, 'id') do
		if String.isNotEmpty(matchGroupId) then
			table.insert(parsedArgs.matchGroupIds, matchGroupId)
		end
	end

	for _, tournament in Table.iter.pairsByPrefix(args, 'tournament', {requireIndex = false}) do
		tournament = mw.ext.TeamLiquidIntegration.resolve_redirect(tournament):gsub(' ', '_')
		table.insert(parsedArgs.tournaments, tournament)
	end

	if Table.isEmpty(parsedArgs.matchGroupIds) and Table.isEmpty(parsedArgs.tournaments) then
		table.insert(parsedArgs.tournaments, mw.title.getCurrentTitle().text)
	end

	return parsedArgs
end

---@param args mvpTableParsedArgs
---@return string
function MvpTable._buildConditions(args)
	local matchGroupIDConditions
	if Table.isNotEmpty(args.matchGroupIds) then
		matchGroupIDConditions = ConditionTree(BooleanOperator.any)
		for _, id in pairs(args.matchGroupIds) do
			matchGroupIDConditions:add{ConditionNode(ColumnName('match2bracketid'), Comparator.eq, id)}
		end
	end

	local tournamentConditions
	if Table.isNotEmpty(args.tournaments) then
		tournamentConditions = ConditionTree(BooleanOperator.any)
		for _, tournament in pairs(args.tournaments) do
			local page = mw.title.new(tournament)
			assert(page, 'Invalid page name "' .. tournament .. '"')
			tournamentConditions:add{
				ConditionTree(BooleanOperator.all):add{
					ConditionNode(ColumnName('pagename'), Comparator.eq, mw.ustring.gsub(page.text, ' ', '_')),
					ConditionNode(ColumnName('namespace'), Comparator.eq, page.namespace),
				},
			}
		end
	end

	local conditions = ConditionTree(BooleanOperator.all):add{
		tournamentConditions,
		matchGroupIDConditions,
	}

	return conditions:toString()
end

---Builds the main header of the MvpTable
---@param args mvpTableParsedArgs
---@return Html?
function MvpTable._mainHeader(args)
	if String.isEmpty(args.title) then
		return nil
	end

	local colspan = 2 + (args.points and 1 or 0)

	return mw.html.create('tr')
		:tag('th'):wikitext(args.title):attr('colspan', colspan):done():done()
end

---Builds the sub header of the MvpTable
---@param args mvpTableParsedArgs
---@return Html
function MvpTable._subHeader(args)
	local header = mw.html.create('tr')
		:tag('th'):wikitext('Player'):done()
		:tag('th'):wikitext('#MVPs'):done()

	if args.points then
		header:tag('th'):wikitext('Points'):done()
	end

	return header:done()
end

---Builds the display for a mvp row
---@param item table
---@param args mvpTableParsedArgs
---@return Html
function MvpTable._row(item, args)
	local row = mw.html.create('tr')
		:tag('td'):css('text-align', 'left'):node(OpponentDisplay.BlockOpponent{
			opponent = {type = Opponent.solo, players = {{
				displayName = item.displayName,
				flag = item.flag,
				pageName = item.name,
				team = item.team and TeamTemplate.resolve(item.team, DateExt.getContextualDateOrNow()) or nil,
			}}},
			showLink = true,
			overflow = 'ellipsis',
			showPlayerTeam = true,
		}):done()
		:tag('td'):wikitext(item.mvp):done()

	if args.points then
		row:tag('td'):wikitext(item.points):done()
	end

	return row:done()
end

---
-- Processes retrieved data
-- overwritable function via /Custom
---@param queryData table[]
---@return {points: number, mvp: number, displayName:string?, name:string, flag:string?, team:string?}[]
function MvpTable.processData(queryData)
	local playerList = {}
	local mvpList = {}

	for _, item in pairs(queryData) do
		local mvp = (item.extradata or {}).mvp
		if mvp then
			for _, player in pairs(mvp.players or {}) do
				if not playerList[player.name] then
					playerList[player.name] = {
						points = 0,
						mvp = 0,
						displayName = player.displayname,
						name = player.name,
						flag = player.flag,
						team = player.team
					}
				end
				playerList[player.name].mvp = playerList[player.name].mvp + 1
				playerList[player.name].points = playerList[player.name].points + (mvp.points or 0)
			end
		end
	end

	for _, item in Table.iter.spairs(playerList, MvpTable.sortFunction) do
		table.insert(mvpList, item)
	end

	return mvpList
end

---
-- Function to sort mvps
-- exported so it can be used in /Custom
---@param tbl table
---@param a string
---@param b string
---@return boolean
function MvpTable.sortFunction(tbl, a, b)
	return tbl[a].mvp > tbl[b].mvp or
		tbl[a].mvp == tbl[b].mvp and tbl[a].name < tbl[b].name
end

---
-- Function to legacy query data from match1 and process it
---@param conditions string
---@return {points: number, mvp: number, displayName:string?, name:string, flag:string?, team:string?}[]?
function MvpTable._queryMatch1(conditions)
	local queryData = mw.ext.LiquipediaDB.lpdb('match', {
		limit = 5000,
		conditions = conditions,
		order = 'date desc',
		query = 'opponent1players, opponent2players, opponent1, opponent2, extradata',
	})

	if type(queryData) ~= 'table' or not queryData[1] then
		return
	end

	local playerList = {}
	local mvpList = {}

	---@cast queryData table
	for _, match in pairs(queryData) do
		local players, points = string.match((match.extradata or {}).mvp or '', '([%w%(%) _,%w-]+);(%d+)')
		if players and points then
			for _, player in pairs(mw.text.split(players, ',')) do
				if String.isNotEmpty(player) then
					player = mw.text.trim(player)
					local redirectResolvedPlayer = mw.ext.TeamLiquidIntegration.resolve_redirect(player)
					local identifier = redirectResolvedPlayer:gsub(' ', '_')

					if not playerList[identifier] then
						playerList[identifier] = MvpTable._findPlayerInfo(match, {
							player:lower():gsub('_', ' '),
							player:lower():gsub(' ', '_'),
							redirectResolvedPlayer:lower(),
							identifier:lower(),
						}, identifier, player)
					end

					playerList[identifier].points = playerList[identifier].points + points
					playerList[identifier].mvp = playerList[identifier].mvp + 1
				end
			end
		end
	end

	for _, item in Table.iter.spairs(playerList, MvpTable.sortFunction) do
		table.insert(mvpList, item)
	end

	return mvpList
end

---
-- Function to find player info in match1 matches for a given lookup table
---@param match table
---@param lookupTable string[]
---@param link string
---@param displayName string
---@return {points: number, mvp: number, displayName:string, name:string, flag:string?, team:string?}
function MvpTable._findPlayerInfo(match, lookupTable, link, displayName)
	--basic information obtainable from mvp field without any lookup in opponent player data
	local playerData = {
		name = link,
		displayName = displayName,
		points = 0,
		mvp = 0,
	}

	for opponentIndex = 1, 2 do
		for prefix, player in Table.iter.pairsByPrefix(match['opponent' .. opponentIndex .. 'players'], 'p') do
			if String.isNotEmpty(player) and Table.includes(lookupTable, player:lower()) then
				playerData.flag = match['opponent' .. opponentIndex .. 'players'][prefix .. 'flag']
				playerData.displayName = match['opponent' .. opponentIndex .. 'players'][prefix .. 'dn'] or playerData.displayName
				playerData.team = match['opponent' .. opponentIndex]
				return playerData
			end
		end
	end

	return playerData
end

return Class.export(MvpTable, {exports = {'run'}})
