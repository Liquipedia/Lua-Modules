---
-- @Liquipedia
-- wiki=commons
-- page=Module:MvpTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Flags = require('Module:Flags')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Team = require('Module:Team')

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local _PAGENAME = mw.title.getCurrentTitle().text

local MvpTable = {}

function MvpTable.run(args)
	args = MvpTable._parseArgs(args)
	local conditions = MvpTable._buildConditions(args)
	local queryData = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = conditions,
		query = 'extradata, match2opponents',
		limit = 5000,
	})

	if type(queryData) ~= 'table' or not queryData[1] then
		return ''
	end

	local mvpList = MvpTable.processData(queryData)

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

function MvpTable._parseArgs(args)
	local parsedArgs = {
		cutafter = tonumber(args.cutafter) or 5,
		margin = Logic.readBool(args.margin or true) and 20 or 0,
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

	args.tournament1 = args.tournament or args.tournament1
	for _, tournament in Table.iter.pairsByPrefix(args, 'tournament') do
		tournament = tournament:gsub(' ', '_')
		table.insert(parsedArgs.tournaments, tournament)
	end
	if Table.isEmpty(parsedArgs.matchGroupIds) and Table.isEmpty(parsedArgs.tournaments) then
		table.insert(parsedArgs.tournaments, _PAGENAME)
	end

	return parsedArgs
end

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
		--ConditionNode(ColumnName('extradata_mvp'), Comparator.neq, ''),
	}

	return conditions:toString()
end

function MvpTable._mainHeader(args)
	if String.isEmpty(args.title) then
		return nil
	end

	local colspan = 2 + (args.points and 1 or 0)

	return mw.html.create('tr')
		:tag('th'):wikitext(args.title):attr('colspan', colspan):done():done()
end

function MvpTable._subHeader(args)
	local header = mw.html.create('tr')
		:tag('th'):wikitext('Player'):done()
		:tag('th'):wikitext('#MVPs'):done()

	if args.points then
		header:tag('th'):wikitext('Points'):done()
	end

	return header:done()
end

function MvpTable._row(item, args)
	local playerCell = mw.html.create('td')
		:css('text-align', 'left')
		:wikitext(Flags.Icon{flag = item.flag})
		:wikitext('&nbsp;')
		:wikitext('[[' .. item.name .. '|' .. item.displayName .. ']]')
		:wikitext('&nbsp;')
		:wikitext(Team.part(mw.getCurrentFrame(), item.team or ''))

	local row = mw.html.create('tr')
		:node(playerCell)
		:tag('td'):wikitext(item.mvp):done()

	if args.points then
		row = mw.html.create('tr')
			:tag('td'):wikitext(item.points):done()
	end

	return row:done()
end

-- overwritable function via /Custom
function MvpTable.processData(queryData)
	local playerList = {}
	local mvpList = {}

	for _, item in pairs(queryData) do
		local mvp = (item.extradata or {}).mvp
		if mvp then
			for _, player in pairs(mvp.players or {}) do
				if not playerList[player] then
					playerList[player] = MvpTable.createPlayer(item.match2opponents, player)
				end
				playerList[player].mvp = playerList[player].mvp + 1
				playerList[player].points = playerList[player].points + (mvp.points or 0)
			end
		end
	end

	for _, item in Table.iter.spairs(playerList, MvpTable.sortFunction) do
		table.insert(mvpList, item)
	end

	return mvpList
end

-- overwritable function via /Custom
function MvpTable.createPlayer(opponents, mvp)
	local player = {
		points = 0,
		mvp = 0,
		displayName = mvp,
		name = mvp,
	}

	for _, opponent in pairs(opponents) do
		local players = opponent.match2players or {}
		-- this function call is currently needed due to wikis currently storing mvp sometimes as `link|display`
		mvp = MvpTable.pageFromMvp(mvp)
		for _, matchPlayer in pairs(players) do
			if mvp == matchPlayer.name then
				player.displayName = matchPlayer.displayname
				player.flag = matchPlayer.flag
				player.name = matchPlayer.name
				player.team = opponent.template

				return player
			end
		end
	end

	return player
end

-- exported so it can be used in /Custom
function MvpTable.pageFromMvp(mvp)
	mvp = mw.text.split(mvp, '|')

	return mw.ext.TeamLiquidIntegration.resolve_redirect(mvp[1]):gsub(' ', '_')
end

-- exported so it can be used in /Custom
function MvpTable.sortFunction(tbl, a, b)
	return tbl[a].mvp > tbl[b].mvp or
		tbl[a].mvp == tbl[b].mvp and tbl[a].name < tbl[b].name
end

return Class.export(MvpTable)
