--[[
	GroupTableLeague for the new match2 system
	- supports both opponent-types depending on wiki custom implementation
	- by default it supports team and player matches
	- switches between opponent types via "|type=solo/team/duo/..."
	- supports queries from non main space name spaces via |ns=
		--> ns needs the number of the name space the data should be queried from, e.g.
				0 = Main (this is the default)
				2 = User
				4 = Liquipedia
				134 = Portal
				136 = Data
]]

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Countdown = require('Module:Countdown')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Lua = require('Module:Lua')
local Template = require('Module:Template')
local Custom = Lua.requireIfExists('Module:GroupTableLeague/Custom',
	require('Module:GroupTableLeague/Custom/Base'))

local _aliasList = {}

local _RANKING_CHANGE_ARROW_UP = '&#x25B2;'
local _RANKING_CHANGE_ARROW_DOWN = '&#x25BC;'
local _EMPTY_MATCH = {
	date = '',
	finished = 0,
	match2opponents = {
		[1] = {
			name = 'Definitions',
			score = 0,
			status = 'S',
		},
		[2] = {
			name = 'Definitions',
			score = 0,
			status = 'S',
		}
	}
}

local _lpdbBaseConditions

local GroupTableLeague = {}

function GroupTableLeague._formatDate(date, format)
	local dateString = date or ''
	local timezone = String.split(
		String.split(dateString, 'data%-tz%=\"')[2] or '',
			'\"')[1] or String.split(
		String.split(dateString, 'data%-tz%=\'')[2] or '',
			'\'')[1] or ''
	local Date = String.explode(dateString, '<', 0):gsub('-', '')
	date = Date .. timezone
	date = mw.getContentLanguage():formatDate(format or 'r', date)

	return date
end

function GroupTableLeague._getLpdbResults(args, tournaments, opponents, mode, id)
	local baseConditions, dateConditions = GroupTableLeague.lpdbBaseConditions(args, tournaments, id)
	local lpdbConditions, lpdbBaseConditions = Custom.lpdbConditions(args, opponents, mode, baseConditions, dateConditions)
	_lpdbBaseConditions = lpdbBaseConditions

	local matches = mw.ext.LiquipediaDB.lpdb('match2', {
		limit = 1000,
		order = 'date asc',
		conditions = lpdbConditions
	})

	return matches
end

function GroupTableLeague.lpdbBaseConditions(args, tournaments, ids)
	local baseConditions = {}
	local dateConditions = {}

	if not String.isEmpty(ids) then
		ids = mw.text.split(ids, ',')
		for key, item in pairs(ids) do
			ids[key] = mw.text.trim(item)
		end
		table.insert(baseConditions, '([[match2bracketid::' ..
			table.concat(ids, ']] OR [[match2bracketid::')
			.. ']])'
		)
	else
		if Table.isEmpty(tournaments) then
			tournaments = args.tournaments or args.tournament
			if String.isEmpty(tournaments) then
				tournaments = mw.title.getCurrentTitle().text
			end
			tournaments = mw.text.split(tournaments, ',')
		end
		for key, item in pairs(tournaments) do
			tournaments[key] = string.gsub(mw.text.trim(item) or '', '%s', '_')
		end
		table.insert(baseConditions, '([[pagename::' ..
			table.concat(tournaments, ']] OR [[pagename::')
			.. ']])'
		)
	end

	local nameSpaceNumber = tonumber(args.ns or 0) or 0
	if nameSpaceNumber > 1 then
		table.insert(baseConditions, '[[namespace::' .. nameSpaceNumber .. ']]')
	end

	if not String.isEmpty(args.sdate) then
		table.insert(dateConditions,
			'([[date::>' .. GroupTableLeague._formatDate(args.sdate) ..
			']] OR [[date::' .. GroupTableLeague._formatDate(args.sdate) .. ']])'
		)
	end
	if not String.isEmpty(args.edate) then
		table.insert(dateConditions,
			'([[date::<' .. GroupTableLeague._formatDate(args.edate) ..
			']] OR [[date::' .. GroupTableLeague._formatDate(args.edate) .. ']])'
		)
	end

	return table.concat(baseConditions, ' AND '), table.concat(dateConditions, ' AND ')
end

local Score = {}
function Score.dq(opponent)
	return opponent.disqualified and 0 or 1
end

function Score.points(opponent)
	return opponent.tiebreaker * 30 + opponent.points
end

function Score.diff(opponent)
	return opponent.tiebreaker * 30 + opponent.diff
end

function Score.series(opponent)
	return opponent.tiebreaker * 30 + opponent.series.won - 0.1 * opponent.series.loss
end

function Score.gamesWon(opponent)
	return opponent.tiebreaker * 30 + opponent.games.won
end

function Score.gamesLoss(opponent)
	return opponent.tiebreaker * 30 - 0.1 * opponent.games.loss
end

function Score.seriesPercent(opponent)
	local percentage = 0
	local playedSerieses = opponent.series.won + opponent.series.loss
	if playedSerieses > 0 then
		percentage = 10 * opponent.series.won / playedSerieses
	end
	return opponent.tiebreaker * 30 + percentage
end

function Score.seriesDiff(opponent)
	return opponent.tiebreaker * 30 + opponent.series.won - opponent.series.loss
end

function Score.tempTies(opponent)
	return opponent.tiebreaker * 30 + (opponent.temp.tiebreaker or 0)
end

local StatefulScore = {}
function StatefulScore.h2hSeries(results, startIndex, endIndex, lpdbConditions)
	for i = startIndex, endIndex do
		results[i].tiebreaker = results[i].tiebreaker * 30
	end
	for opponent1Index = startIndex, endIndex-1 do
		for opponent2Index = opponent1Index+1, endIndex do
			-- opponent1 vs opponent2 / opponent2 vs opponent1
			local opp1 = GroupTableLeague._getH2HOppCond(results, opponent1Index)
			local opp2 = GroupTableLeague._getH2HOppCond(results, opponent2Index)
			local match = mw.ext.LiquipediaDB.lpdb('match2', {
				limit = 1000,
				order = 'date asc',
				conditions = lpdbConditions .. GroupTableLeague._mergeOpponentConditions(opp1, opp2)
			})
			for _, item in ipairs(match) do
				if Table.includes(opp1, item.match2opponents[1].name) then
					if item.winner == '1' then
						results[opponent1Index].tiebreaker = results[opponent1Index].tiebreaker + 1
						results[opponent2Index].tiebreaker = results[opponent2Index].tiebreaker - 1
					elseif item.winner == '2' then
						results[opponent2Index].tiebreaker = results[opponent2Index].tiebreaker + 1
						results[opponent1Index].tiebreaker = results[opponent1Index].tiebreaker - 1
					end
				else
					if item.winner == '2' then
						results[opponent1Index].tiebreaker = results[opponent1Index].tiebreaker + 1
						results[opponent2Index].tiebreaker = results[opponent2Index].tiebreaker - 1
					elseif item.winner == '1' then
						results[opponent2Index].tiebreaker = results[opponent2Index].tiebreaker + 1
						results[opponent1Index].tiebreaker = results[opponent1Index].tiebreaker - 1
					end
				end
			end
		end
	end
end

function StatefulScore.h2hGames(results, startIndex, endIndex, lpdbConditions)
	for i = startIndex, endIndex do
		results[i].tiebreaker = results[i].tiebreaker * 30
	end
	for opponent1Index = startIndex, endIndex-1 do
		for opponent2Index = opponent1Index+1, endIndex do
			-- opponent1 vs opponent2 / opponent2 vs opponent1
			local opp1 = GroupTableLeague._getH2HOppCond(results, opponent1Index)
			local opp2 = GroupTableLeague._getH2HOppCond(results, opponent2Index)
			local match = mw.ext.LiquipediaDB.lpdb('match2', {
				limit = 1000,
				order = 'date asc',
				conditions = lpdbConditions .. GroupTableLeague._mergeOpponentConditions(opp1, opp2)
			})
			for _, item in ipairs(match) do
				if item.match2opponents[1].score ~= -1 and item.match2opponents[2].score ~= -1 then
					if Table.includes(opp1, item.match2opponents[1].name) then
						results[opponent1Index].tiebreaker = results[opponent1Index].tiebreaker
							+ tonumber(item.match2opponents[1].score)
							- 0.01 * tonumber(item.match2opponents[2].score)
						results[opponent2Index].tiebreaker = results[opponent2Index].tiebreaker
							+ tonumber(item.match2opponents[2].score)
							- 0.01 * tonumber(item.match2opponents[1].score)
					else
						results[opponent1Index].tiebreaker = results[opponent1Index].tiebreaker
							+ tonumber(item.match2opponents[2].score)
							- 0.01 * tonumber(item.match2opponents[1].score)
						results[opponent2Index].tiebreaker = results[opponent2Index].tiebreaker
							+ tonumber(item.match2opponents[1].score)
							- 0.01 * tonumber(item.match2opponents[2].score)
					end
				end
			end
		end
	end
end

function StatefulScore.h2hGamesDiff(results, startIndex, endIndex, lpdbConditions)
	for i = startIndex, endIndex do
		results[i].tiebreaker = results[i].tiebreaker * 30
	end
	for opponent1Index = startIndex, endIndex-1 do
		for opponent2Index = opponent1Index+1, endIndex do
			-- opponent1 vs opponent2 / opponent2 vs opponent1
			local opp1 = GroupTableLeague._getH2HOppCond(results, opponent1Index)
			local opp2 = GroupTableLeague._getH2HOppCond(results, opponent2Index)
			local match = mw.ext.LiquipediaDB.lpdb('match2', {
				limit = 1000,
				order = 'date asc',
				conditions = lpdbConditions .. GroupTableLeague._mergeOpponentConditions(opp1, opp2)
			})
			for _, item in ipairs(match) do
				if item.match2opponents[1].score ~= -1 and item.match2opponents[2].score ~= -1 then
					if Table.includes(opp1, item.match2opponents[1].name) then
						results[opponent1Index].tiebreaker = results[opponent1Index].tiebreaker
							+ tonumber(item.match2opponents[1].score)
							- tonumber(item.match2opponents[2].score)
						results[opponent2Index].tiebreaker = results[opponent2Index].tiebreaker
							+ tonumber(item.match2opponents[2].score)
							- tonumber(item.match2opponents[1].score)
					else
						results[opponent1Index].tiebreaker = results[opponent1Index].tiebreaker
							+ tonumber(item.match2opponents[2].score)
							- tonumber(item.match2opponents[1].score)
						results[opponent2Index].tiebreaker = results[opponent2Index].tiebreaker
							+ tonumber(item.match2opponents[1].score)
							- tonumber(item.match2opponents[2].score)
					end
				end
			end
		end
	end
end

function StatefulScore.h2hGamesWon(results, startIndex, endIndex, lpdbConditions)
	for i = startIndex, endIndex do
		results[i].tiebreaker = results[i].tiebreaker * 30
	end
	for opponent1Index = startIndex, endIndex-1 do
		for opponent2Index = opponent1Index+1, endIndex do
			-- opponent1 vs opponent2 / opponent2 vs opponent1
			local opp1 = GroupTableLeague._getH2HOppCond(results, opponent1Index)
			local opp2 = GroupTableLeague._getH2HOppCond(results, opponent2Index)
			local match = mw.ext.LiquipediaDB.lpdb('match2', {
				limit = 1000,
				order = 'date asc',
				conditions = lpdbConditions .. GroupTableLeague._mergeOpponentConditions(opp1, opp2)
			})
			for _, item in ipairs(match) do
				if item.match2opponents[1].score ~= -1 and item.match2opponents[2].score ~= -1 then
					if Table.includes(opp1, item.match2opponents[1].name) then
						results[opponent1Index].tiebreaker = results[opponent1Index].tiebreaker
							+ tonumber(item.match2opponents[1].score)
						results[opponent2Index].tiebreaker = results[opponent2Index].tiebreaker
							+ tonumber(item.match2opponents[2].score)
					else
						results[opponent1Index].tiebreaker = results[opponent1Index].tiebreaker
							+ tonumber(item.match2opponents[2].score)
						results[opponent2Index].tiebreaker = results[opponent2Index].tiebreaker
							+ tonumber(item.match2opponents[1].score)
					end
				end
			end
		end
	end
end

function StatefulScore.h2hGamesLoss(results, startIndex, endIndex, lpdbConditions)
	for i = startIndex, endIndex do
		results[i].tiebreaker = results[i].tiebreaker * 30
	end
	for opponent1Index = startIndex, endIndex-1 do
		for opponent2Index = opponent1Index+1, endIndex do
			-- opponent1 vs opponent2 / opponent2 vs opponent1
			local opp1 = GroupTableLeague._getH2HOppCond(results, opponent1Index)
			local opp2 = GroupTableLeague._getH2HOppCond(results, opponent2Index)
			local match = mw.ext.LiquipediaDB.lpdb('match2', {
				limit = 1000,
				order = 'date asc',
				conditions = lpdbConditions .. GroupTableLeague._mergeOpponentConditions(opp1, opp2)
			})
			for _, item in ipairs(match) do
				if item.match2opponents[1].score ~= -1 and item.match2opponents[2].score ~= -1 then
					if Table.includes(opp1, item.match2opponents[1].name) then
						results[opponent1Index].tiebreaker = results[opponent1Index].tiebreaker
							- tonumber(item.match2opponents[2].score)
						results[opponent2Index].tiebreaker = results[opponent2Index].tiebreaker
							- tonumber(item.match2opponents[1].score)
					else
						results[opponent1Index].tiebreaker = results[opponent1Index].tiebreaker
							- tonumber(item.match2opponents[1].score)
						results[opponent2Index].tiebreaker = results[opponent2Index].tiebreaker
							- tonumber(item.match2opponents[2].score)
					end
				end
			end
		end
	end
end

function GroupTableLeague._readScoreSpec(args)
	local spec = {}
	for i = 1, 10 do
		local key = args['tiebreaker' .. tostring(i)] or ''
		if key == 'points' or key == 'pts' then
			table.insert(spec, 'points')
		elseif key == 'series' then
			table.insert(spec, 'series')
		elseif key == 'diff' then
			table.insert(spec, 'diff')
		elseif key == 'games won' then
			table.insert(spec, 'gamesWon')
		elseif key == 'games loss' then
			table.insert(spec, 'gamesLoss')
		elseif
			key == 'h2h series' or
			key == 'head-to-head series' or
			key == 'head to head series'
		then
			table.insert(spec, 'h2hSeries')
		elseif
			key == 'h2h games' or
			key == 'head-to-head games' or
			key == 'head to head games'
		then
			table.insert(spec, 'h2hGames')
		elseif
			key == 'h2h games diff' or
			key == 'head-to-head games' or
			key == 'head to head games'
		then
			table.insert(spec, 'h2hGamesDiff')
		elseif
			key == 'h2h games won' or
			key == 'head-to-head games won' or
			key == 'head to head games won'
		then
			table.insert(spec, 'h2hGamesWon')
		elseif
			key == 'h2h games loss' or
			key == 'head-to-head games loss' or
			key == 'head to head games loss'
		then
			table.insert(spec, 'h2hGamesLoss')
		elseif
			key == 'series percentage' or
			key == 'series%' or
			key == 'series-percentage'
		then
			table.insert(spec, 'seriesPercent')
		elseif key == 'series diff' then
			table.insert(spec, 'seriesDiff')
		end
	end

	if #spec == 0 then
		spec = Array.extend(
			Logic.readBool(args.show_p) and 'points' or nil,
			'series',
			'diff',
			'h2hSeries',
			'h2hGames',
			'gamesWon',
			'gamesLoss'
		)
	end
	table.insert(spec, 1, 'dq')
	table.insert(spec, 'tempTies')

	return spec
end

function GroupTableLeague._resolveTies(args, opponentList, results, date)
	local scoreSpec = GroupTableLeague._readScoreSpec(args)

	local tiesResolved = false
	local scoreSpecIndex = 1

	local lpdbConditions = _lpdbBaseConditions .. ' AND ([[date::<' .. date .. ']] OR [[date::' .. date .. ']])'

	local statefulScoreNames = {
		'h2hSeries',
		'h2hGames',
		'h2hGamesDiff',
		'h2hGamesWon',
		'h2hGamesLoss'
	}
	repeat
		local startIndex, endIndex = 1, 1

		repeat
			while (endIndex < #opponentList and results[endIndex].tiebreaker == results[endIndex+1].tiebreaker) do
				endIndex = endIndex + 1
			end

			-- calculate tiebreaker value for each tied opponent
			local tiedRankings = {}

			local scoreName = scoreSpec[scoreSpecIndex]
			if endIndex - startIndex > 0 then
				if Table.includes(statefulScoreNames, scoreName) then
					StatefulScore[scoreName](results, startIndex, endIndex, lpdbConditions)
					for i = startIndex, endIndex do
						table.insert(tiedRankings, results[i])
					end
				else
					for i = startIndex, endIndex do
						results[i].tiebreaker = Score[scoreName](results[i])
						table.insert(tiedRankings, results[i])
					end
				end
				table.sort(tiedRankings,
					function(item1, item2) return
						item1.tiebreaker > item2.tiebreaker or
						(item1.tiebreaker == item2.tiebreaker and
							string.lower(item1.opponent) < string.lower(item2.opponent))
					end
				)
				for i = startIndex, endIndex do
					results[i] = tiedRankings[ i - startIndex + 1 ]
				end
			end
			endIndex = endIndex + 1
			startIndex = endIndex
		until (endIndex > #opponentList)
		scoreSpecIndex = scoreSpecIndex + 1

		if (scoreSpecIndex > 2 and startIndex == 1 and endIndex == #opponentList) then
			tiesResolved = true
		end

	until (scoreSpecIndex > #scoreSpec or tiesResolved == true)

	-- update opponentList to match results
	for key, item in ipairs(results) do
		opponentList[item.opponent] = key
	end
end

function GroupTableLeague.create(frame, args, data)
	local divWrapper
	local opponentList = {}
	local tournaments = {}
	local customPoints = {}
	local rounds = {}
	local roundNumber = 1
	local opponents = {}
	local countWinPoints = 1

	if not args then
		args = Arguments.getArgs(frame)
	end
	local tableType, mode, typeParams = Custom.convertType(args['type'])

	-- parse parameters tournamentX and opponentX and X-X_p
	for key, item in pairs(args) do
		if item == '' or item == '\n' then
			args[key] = nil
		end

		if type(key) == 'string' and item ~= '' then
			-- tournamentX
			if key:match('^tournament(%d*)$') then
				table.insert(tournaments, (mw.ext.TeamLiquidIntegration.resolve_redirect(item):gsub('%s','_')) )
			end

			-- paramX associated with opponentX
			if key:match('^r?o?u?n?d?%d-([^%d]*%d*)$') then
				local roundIndex, param, opponentIndex = key:match('^r?o?u?n?d?(%d-)([^%d]*)(%d*)$')

				if roundIndex == '' then
					roundIndex = 0
				end
				roundIndex, opponentIndex = tonumber(roundIndex), tonumber(opponentIndex)

				if not rounds[roundIndex] then
					rounds[roundIndex] = {
						date = nil, --todayDate,
						temp = {
							series = {
								won = {},
								tied = {},
								loss = {},
							},
							games = {
								won = {},
								loss = {},
							},
							points = {},
							tiebreaker = {},
							diff = {}
						},
						params = {
							disqualified = {},
							bg = {}
						}
					}
				end

				-- opponentX
				if param == 'opponent' or Table.includes(typeParams, param) then
					local opponentAlias
					opponentList[opponentIndex], opponentAlias, opponents = Custom.parseOpponentInput[tableType](
						param,
						opponentIndex,
						item,
						args,
						opponents
					)
					opponentList[opponentList[opponentIndex].opponent] = opponentIndex
					for _, alias in pairs(opponentAlias or {}) do
						if mw.text.trim(alias) ~= '' then
							local aliasName = mw.ext.TeamLiquidIntegration.resolve_redirect(alias)
							_aliasList[aliasName] = opponentList[opponentIndex].opponent
							opponents[#opponents + 1] = aliasName
						end
					end

				-- rNdateX
				elseif param == 'edate' or param == 'date' or param == 'ate' then
					rounds[roundIndex].date = tonumber(GroupTableLeague._formatDate(item, 'U'))

				-- rNbgX
				elseif param == 'bg' then
					rounds[roundIndex].params.bg[opponentIndex] = item

				-- temp_pX
				elseif param == 'temp_p' and opponentIndex then
					rounds[roundIndex].temp.points[opponentIndex] = item

				-- temp_tieX
				elseif param == 'temp_tie' and opponentIndex then
					rounds[roundIndex].temp.tiebreaker[opponentIndex] = item

				-- temp_diffX
				elseif param == 'temp_diff' and opponentIndex then
					rounds[roundIndex].temp.diff[opponentIndex] = item

				-- temp_win_mX
				elseif param == 'temp_win_m' and opponentIndex then
					rounds[roundIndex].temp.series.won[opponentIndex] = item
				elseif param == 'temp_tie_m' and opponentIndex then
					rounds[roundIndex].temp.series.tied[opponentIndex] = item
				elseif param == 'temp_lose_m' and opponentIndex then
					rounds[roundIndex].temp.series.loss[opponentIndex] = item
				elseif param == 'temp_win_g' and opponentIndex then
					rounds[roundIndex].temp.games.won[opponentIndex] = item
				elseif param == 'temp_lose_g' and opponentIndex then
					rounds[roundIndex].temp.games.loss[opponentIndex] = item

				-- dqX
				elseif
					param == 'dq'
					and opponentIndex and item == 'true'
				then
					rounds[roundIndex].params.disqualified[opponentIndex] = true
				end

			-- X-Y_p
			elseif key:match('^(%d+-%d+)_p$') then
				countWinPoints = 0
				table.insert(customPoints, {score1 = key:match('^(%d+)-%d+_p'), score2 = key:match('^%d+-(%d+)_p'), points = item})
			end
		end
	end

	if args.exclusive == 'false' then
		opponents = {}
	end

	-- parse parameters
	countWinPoints = (args.countWinPoints == '1' or args.countWinPoints == 'true') and 1 or countWinPoints
	args.win_p = tonumber(args.win_p) or countWinPoints * 3
	args.tie_p = tonumber(args.tie_p) or countWinPoints * 1
	args.lose_p = tonumber(args.lose_p) or 0
	args.walkover_win = tonumber(args.walkover_win) or 0
	args.ties = args.ties or 'false'
	args.show_p = args.show_p or 'false'
	args.diff = args.diff or 'true'
	args.show_g = args.show_g or 'true'
	args.exclusive = args.exclusive or 'true'
	args.roundtitle = args.roundtitle or 'Round'
	args.roundwidth = tonumber(args.roundwidth) or 90

	if not data then
		data = GroupTableLeague._getLpdbResults(args, tournaments, opponents, mode, args.id or '')
	end

	--if no data is set and no data is found we set an empty match to avoid errors
	if not data[1] then
		data[1] = _EMPTY_MATCH
	end

	if type(data) == 'table' then
		-- final date
		table.sort(rounds, function(item1, item2) return item1.date < item2.date end)
		local isMidTournament = false
		local todayDate = tonumber(mw.language.getContentLanguage():formatDate('U', os.date()))
		local lastDate = todayDate
		if next(data) then
			lastDate = tonumber(GroupTableLeague._formatDate(data[#data].date, 'U'))
			for key, item in ipairs(rounds) do
				if item.date > todayDate then
					if isMidTournament then
						rounds[key] = nil
					else
						isMidTournament = true
					end
				elseif item.date > lastDate then
					rounds[key] = nil
				end
			end
		end

		if not(rounds[1]) or (rounds[#rounds].date < lastDate and not(isMidTournament)) then
			if rounds[0] then
				rounds[0].date = todayDate
				rounds[(#rounds or 0) + 1] = rounds[0]
			else
				rounds[(#rounds or 0) + 1] = {
					date = todayDate,
					temp = {
						series = {
							won = {},
							tied = {},
							loss = {},
						},
						games = {
							won = {},
							loss = {},
						},
						points = {},
						tiebreaker = {},
						diff = {}
					},
					params = {
						disqualified = {},
						bg = {}
					}
				}
			end
		end

		local output, header = GroupTableLeague._createHeader(frame, args, #rounds, isMidTournament)

		--store (s)date as match date to be passed to the matches entered after this group table
		local storeToVarDate = args.sdate or ''
		if storeToVarDate == '' then
			storeToVarDate = args.date or ''
		end
		if storeToVarDate ~= '' then
			storeToVarDate = GroupTableLeague._formatDate(storeToVarDate, 'Y-m-d H:i:s')
			Variables.varDefine('matchDate', storeToVarDate)
		end

		-- get list of unique opponents if no set opponents
		if not next(opponentList) then
			local k = 0
			for _, item in ipairs(data) do
				if not opponentList[item.match2opponents[1].name] then
					k = k + 1
					opponentList[k] = {opponent = item.match2opponents[1].name, opponentArg = item.match2opponents[1].name}
				end
				if not opponentList[item.match2opponents[2].name] then
					k = k + 1
					opponentList[k] = {opponent = item.match2opponents[2].name, opponentArg = item.match2opponents[2].name}
				end
			end
		end
		-- additional opponent 'discard' for discarded results
		opponentList[0] = ''

		local oppdate = args.edate or args.date or Variables.varDefault('tournament_enddate', todayDate)

		local results = GroupTableLeague._initializeResults(opponentList, tableType, oppdate)

		-- calculations
		if not next(data) then
			GroupTableLeague._resolveTies(args, opponentList, results, todayDate)
			GroupTableLeague._printResults(args, header, results, rounds, roundNumber)
		end
		for key, item in ipairs(data) do
			local index1
			if _aliasList[item.match2opponents[1].name] then
				index1 = opponentList[_aliasList[item.match2opponents[1].name]]
			else
				index1 = opponentList[item.match2opponents[1].name]
			end
			local index2
			if _aliasList[item.match2opponents[2].name] then
				index2 = opponentList[_aliasList[item.match2opponents[2].name]]
			else
				index2 = opponentList[item.match2opponents[2].name]
			end
			local update = false

			if (args.exclusive ~= 'false' and index1 and index2) then
				update = true
			elseif (args.exclusive == 'false' and (index1 or index2)) then
				update = true
				if not index1 then
					index1 = 0 --discard results
				elseif not index2 then
					index2 = 0 --discard results
				end
			end

			if (update == true) then
				local score1 = tonumber(item.match2opponents[1].score)
				local score2 = tonumber(item.match2opponents[2].score)
				if
					(Logic.readBool(item.finished) or item.finished == 't') and
					(score1 > 0 or score2 > 0 or (not String.isEmpty(item.winner)) or (not String.isEmpty(item.resulttype)))
				then
					results, args = GroupTableLeague._calculateResults(
						results,
						index1,
						index2,
						item,
						args.walkover_win,
						customPoints,
						args
					)
				end
			end

			--add a catch to fix an error (ugly af!)
			local roundIsEmpty
			if not rounds[roundNumber] then
				roundIsEmpty = true
				rounds[roundNumber] = rounds[roundNumber - 1]
				rounds[roundNumber].date = 9999999999
			end

			if key == #data or tonumber(GroupTableLeague._formatDate(data[key+1].date, 'U')) > rounds[roundNumber].date then
				results = GroupTableLeague._updateResults(results, rounds, args, #opponentList, roundNumber)

				-- tiebreakers
				GroupTableLeague._resolveTies(args, opponentList, results, rounds[roundNumber].date)

				-- update rankings
				results = GroupTableLeague._updateRankings(results)

				if roundIsEmpty then
					rounds[roundNumber] = nil
				end

				if roundNumber == #rounds then
					GroupTableLeague._printResults(args, output, results, rounds, roundNumber, isMidTournament)
				else
					GroupTableLeague._printResults(args, output, results, rounds, roundNumber)
				end
				roundNumber = roundNumber + 1
				if roundNumber > #rounds or roundIsEmpty then
					break;
				end
			end
		end

		divWrapper = mw.html.create('div')
			:addClass('table-responsive toggle-area toggle-area-' .. #rounds)
			:attr('data-toggle-area', #rounds)
			:node(output)
	else
		error(data)
	end

	return divWrapper
end

function GroupTableLeague._initializeResults(opponentList, tableType, oppdate)
	local results = {}
	for key = 0, #opponentList do
		results[key] = {
			index = key,
			opponent = opponentList[key].opponent or opponentList[key],
			opponentArg = opponentList[key].opponentArg or opponentList[key],
			opponentDisplay = Custom.display[tableType](opponentList[key], oppdate) or '',
			note = opponentList[key].note or '',
			ranking = 0,
			rankingChange = 0,
			tiebreaker = 0, -- score used to determine ranking between opponents
			points = 0,
			customPoints = 0,
			diff = 0,
			series = {
				won = 0,
				tied = 0,
				loss = 0,
			},
			games = {
				won = 0,
				loss = 0,
			},
			temp = {
				tiebreaker = 0,
				points = 0,
				diff = 0
			}
		}
	end
	return results
end

function GroupTableLeague._printResults(args, output, results, rounds, roundNumber, isMidTournament)
	for key, item in ipairs(results) do
		local row = output:tag('tr')
			:attr('data-toggle-area-content',roundNumber)
		local bgclass = string.lower(item.bg or '')
		row:tag('th')
			:addClass('bg-' .. string.lower(args['pbg' .. key] or bgclass or ''))
			:css('width', '28px')
			:wikitext(item.ranking ~= 0 and (item.ranking .. '.') or '')

		local opponentColspan = 3
		if (args.show_g == 'false') then
			opponentColspan = opponentColspan + 1
		end
		if (args.diff == 'false') then
			opponentColspan = opponentColspan + 1
		end
		if (args.show_p == 'true') then
			opponentColspan = opponentColspan - 1
		end

		local opponenttext = item.opponentDisplay
		if (item.disqualified == true) then
			opponenttext = '<s>' .. opponenttext .. '</s>'
		end
		if (item.note or '') ~= '' then
			opponenttext = opponenttext .. '&nbsp;<sup><b>' .. item.note .. '</b></sup>'
		end

		local rankingChange = item.rankingChange
		if rankingChange == 0 then
			rankingChange = ''
		elseif rankingChange > 0 then
			rankingChange = '<span class="ranking-change-up">' ..
				_RANKING_CHANGE_ARROW_UP .. rankingChange .. '</span>'
		else
			rankingChange = '<span class="ranking-change-down">' ..
				_RANKING_CHANGE_ARROW_DOWN .. -rankingChange .. '</span>'
		end

		row:tag('td')
			:addClass('grouptableslot')
			:addClass('bg-' .. bgclass)
			:attr('colspan', opponentColspan)
			:attr('align', 'left')
			:wikitext(opponenttext .. rankingChange)

		local seriesScore
		if (args.ties == 'true') then
			seriesScore = item.series.won .. '-' .. item.series.tied .. '-' .. item.series.loss
		else
			seriesScore = item.series.won .. '-' .. item.series.loss
		end
		row:tag('td')
			:addClass('bg-' .. bgclass)
			:attr('width', '35px')
			:attr('align', 'center')
			:css('white-space', 'pre')
			:wikitext('<b>' .. seriesScore .. '</b>')

		if (args.show_g ~= 'false') then
			row:tag('td')
				:addClass('bg-' .. bgclass)
				:attr('width', '35px')
				:attr('align', 'center')
				:css('white-space', 'pre')
				:wikitext(item.games.won .. '-' .. item.games.loss)
		end

		if (args.diff ~= 'false') then
			if (item.diff > 0) then
				item.diff = '+' .. item.diff
			end
			if item.has_temp_diff then
				item.diff = item.diff .. '*'
			end
			row:tag('td')
				:addClass('bg-' .. bgclass)
				:attr('width', '35px')
				:attr('align', 'center')
				:css('white-space', 'pre')
				:wikitext('\'\'' .. item.diff .. '\'\'')
		end

		if (args.show_p == 'true') then
			row:tag('td')
				:addClass('bg-' .. bgclass)
				:attr('width', '32px')
				:attr('align', 'center')
				:css('white-space', 'pre')
				:wikitext('<b>' .. item.points .. 'p</b>')
		end
	end
end

function GroupTableLeague._createHeader(frame, args, numberOfRounds, isMidTournament)
	local class = 'wikitable wikitable-bordered grouptable'
	if Logic.readBool(args.hide) then
		class = class .. ' collapsible collapsed'
	elseif args.hide == 'false' then
		class = class .. ' collapsible'
	elseif args.hide then
		class = class .. ' ' .. args.hide
	end

	local output = mw.html.create('table')
		:addClass(class)
		:css('width', args.width or '300px')
		:css('margin', '0px')

	-- create table header
	local titleText = ''
	if args.location then
		titleText = '<span style="padding-right:3px;">' ..
			Template.safeExpand(frame, 'Played in', {args.location}, '')
			.. '</span>'
	end
	titleText = titleText .. (args.title or mw.title.getCurrentTitle().text)

	local title = mw.html.create('span')
		:wikitext(titleText)
	if numberOfRounds > 1 then
		title:css('margin-left', '-70px')
			:css('vertical-align', 'middle')
	end

	local headerIconsWrapper = Custom.getHeaderIcons(args)

	local dropDownWrapper = GroupTableLeague._createDropDown(
		args,
		isMidTournament,
		numberOfRounds
	)

	local header = output:tag('tr')
	header:tag('th')
		:attr('colspan', args.colspan or '7')
		:css('text-align', 'center')
		:wikitext(tostring(title) .. tostring(headerIconsWrapper) .. tostring(dropDownWrapper))

	-- secondary header for date and streams
	local dateheader
	if args.date then
		dateheader = output:tag('tr')
		dateheader:tag('td')
			:attr('colspan', args.colspan or '7')
			:addClass('grouptable-start-date')
			:wikitext(Countdown._create{
				date = GroupTableLeague._formatDate(args.date, 'F j, Y - H:i'),
				finished = args.finished,
				stream = args.stream,
				twitch = args.twitch,
				afreeca = args.afreeca,
				afreecatv = args.afreecatv,
				dailymotion = args.dailymotion,
				douyu = args.douyu,
				smashcast = args.smashcast,
				youtube = args.youtube,
				facebook = args.facebook,
				trovo = args.trovo,
				rawdatetime = args.rawdatetime,
			})
	end

	return output, header
end

function GroupTableLeague._createDropDown(args, isMidTournament, numberOfRounds)
	local dropDownWrapper = mw.html.create('div')
		:addClass('dropdown-box-wrapper')
		:css('float','left')
	dropDownWrapper:tag('span')
		:addClass('dropdown-box-button btn btn-primary')
		:css('width', args.roundwidth .. 'px')
		:css('padding-top', '2px')
		:css('padding-bottom', '2px')
		:wikitext(
			(isMidTournament and 'Current' or args.roundtitle .. ' ' .. numberOfRounds)
			.. ' <span class="caret"></span>'
		)
	if numberOfRounds <= 1 then
		dropDownWrapper:css('display','none')
	end
	local dropDownButton = dropDownWrapper:tag('div')
		:addClass('dropdown-box')
		:css('padding', '0px')
		:css('border', '0px')
	for i=1,numberOfRounds do
		local buttonText
		if i == numberOfRounds and isMidTournament then
			buttonText = 'Current'
		else
			buttonText = args.roundtitle .. ' ' .. tostring(i)
		end

		dropDownButton:tag('div')
			:addClass('toggle-area-button btn btn-primary')
			:attr('data-toggle-area-btn', tostring(i))
			:css('width', args.roundwidth .. 'px')
			:css('padding-top', '2px')
			:css('padding-bottom', '2px')
			:css('border-top-width', '0px')
			:wikitext(buttonText)
	end

	return dropDownWrapper
end

function GroupTableLeague._calculateResults(results, index1, index2, item, gamesByWalkoverWin, customPoints, args)
	-- add game win/loss
	if item.resulttype ~= '' and item.resulttype ~= 'draw' then
		if item.winner == '1' then
			results[index1].games.won = results[index1].games.won
				+ gamesByWalkoverWin
			results[index2].games.loss = results[index2].games.loss
			+ gamesByWalkoverWin
		elseif item.winner == '2' then
			results[index2].games.won = results[index2].games.won
			+ gamesByWalkoverWin
			results[index1].games.loss = results[index1].games.loss
			+ gamesByWalkoverWin
		end
	else
		results[index1].games.won = results[index1].games.won
			+ tonumber(item.match2opponents[1].score)
		results[index1].games.loss = results[index1].games.loss
			+ tonumber(item.match2opponents[2].score)

		results[index2].games.won = results[index2].games.won
			+ tonumber(item.match2opponents[2].score)
		results[index2].games.loss = results[index2].games.loss
			+ tonumber(item.match2opponents[1].score)
	end

	-- add series win/loss
	if item.winner == '1' then
		results[index1].series.won = results[index1].series.won + 1
		results[index2].series.loss = results[index2].series.loss + 1
	elseif item.winner == '2' then
		results[index1].series.loss = results[index1].series.loss + 1
		results[index2].series.won = results[index2].series.won + 1
	elseif (item.match2opponents[1].score == item.match2opponents[2].score) then
		results[index1].series.tied = results[index1].series.tied + 1
		results[index2].series.tied = results[index2].series.tied + 1
		args.ties = 'true'
	end

	-- add points based on series score
	for _, item_p in pairs(customPoints) do
		if
			tostring(item.match2opponents[1].score) == item_p.score1
			and tostring(item.match2opponents[2].score) == item_p.score2
		then
			results[index1].customPoints = results[index1].customPoints + tonumber(item_p.points)
		end
		if
			tostring(item.match2opponents[2].score) == item_p.score1
			and tostring(item.match2opponents[1].score) == item_p.score2
		then
			results[index2].customPoints = results[index2].customPoints + tonumber(item_p.points)
		end
	end

	return results, args
end

function GroupTableLeague._updateResults(results, rounds, args, numberOfOpponents, roundNumber)
	for i=1,numberOfOpponents do
		local opponentIndex = results[i].index
		results[i].series.won = results[i].series.won
			+ (rounds[roundNumber].temp.series.won[opponentIndex] or 0)
		results[i].series.tied = results[i].series.tied
			+ (rounds[roundNumber].temp.series.tied[opponentIndex] or 0)
		results[i].series.loss = results[i].series.loss
			+ (rounds[roundNumber].temp.series.loss[opponentIndex] or 0)
		results[i].games.won = results[i].games.won
			+ (rounds[roundNumber].temp.games.won[opponentIndex] or 0)
		results[i].games.loss = results[i].games.loss
			+ (rounds[roundNumber].temp.games.loss[opponentIndex] or 0)

		results[i].temp.points = results[i].temp.points
			+ (rounds[roundNumber].temp.points[opponentIndex] or 0)
		results[i].points = results[i].temp.points
			+ results[i].customPoints
			+ args.win_p * results[i].series.won
			+ args.tie_p * results[i].series.tied
			+ args.lose_p * results[i].series.loss

		results[i].temp.diff = results[i].temp.diff
			+ (rounds[roundNumber].temp.diff[opponentIndex] or 0)
		results[i].diff = results[i].temp.diff
			+ results[i].games.won - results[i].games.loss

		results[i].temp.tiebreaker = results[i].temp.tiebreaker
			+ (rounds[roundNumber].temp.tiebreaker[opponentIndex] or 0)

		if rounds[roundNumber].params.bg[opponentIndex] then
			results[i].bg = rounds[roundNumber].params.bg[opponentIndex]
		end
		if rounds[roundNumber].params.disqualified[opponentIndex] then
			results[i].disqualified = rounds[roundNumber].params.disqualified[opponentIndex]
		end
	end

	return results
end

function GroupTableLeague._updateRankings(results)
	local rank = 1
	for index, oppResult in ipairs(results) do
		if oppResult.ranking ~= 0 and oppResult.ranking ~= rank and type(oppResult.ranking) == 'number' then
			oppResult.rankingChange = oppResult.ranking - rank
		else
			oppResult.rankingChange = 0
		end

		if (oppResult.disqualified == true) then
			oppResult.ranking = 'DQ'
		-- if they've played any matches, show a ranking
		elseif (oppResult.series.won + oppResult.series.tied + oppResult.series.loss ~= 0) then
			oppResult.ranking = rank
		end
		if (index == #results or results[index+1].tiebreaker ~= results[index].tiebreaker) then
			rank = index + 1
		end
		oppResult.tiebreaker = 0
	end
	return results
end

function GroupTableLeague._getH2HOppCond(results, index)
	local oppEntry = _aliasList[results[index].opponent] or results[index].opponent
	local opp = {oppEntry}
	--aliases
	if _aliasList[results[index].opponent] then
		for aliasEntry, cleanEntry in pairs(_aliasList) do
			if cleanEntry == oppEntry then
				table.insert(opp, aliasEntry)
			end
		end
	end
	return opp
end

function GroupTableLeague._mergeOpponentConditions(opp1, opp2)
	return ' AND ([[opponent::' ..
		table.concat(opp1, ']] OR [[opponent::') .. ']]) AND ([[opponent::' ..
		table.concat(opp2, ']] OR [[opponent::') .. ']])'
end

return GroupTableLeague
