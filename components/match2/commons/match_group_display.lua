local MatchGroupDisplay = {}
local MatchGroupUtil
local getArgs = require('Module:Arguments').getArgs

function MatchGroupDisplay.bracket(frame)
	local args = getArgs(frame)
	return MatchGroupDisplay.luaBracket(frame, args)
end

function MatchGroupDisplay.customBracket(frame, args, matches)
	if not args then
		args = getArgs(frame)
	end

	if not matches or #matches == 0 then
		args[1] = args.id or args[1] or ''
		matches = MatchGroupDisplay._getMatches(args[1])
	end

	if args.title ~= '' and args.title ~= nil then
		matches[1].bracketData.title = args.title
	end

	for index, match in ipairs(matches) do
		local round, matchInRound = MatchGroupDisplay._getMatchIndexFromMatchId(match.matchId, args[1])

		if round and matchInRound then
			local matchId = 'R' .. round .. 'M' .. matchInRound
			if args[matchId .. 'header'] ~= '' and args[matchId .. 'header'] ~= nil then
				matches[index].bracketData.header = args[matchId .. 'header']
			end
		end
	end

	return MatchGroupDisplay.luaBracket(frame, args, matches)
end

function MatchGroupDisplay.luaBracket(frame, args, matches)
	mw.log("drawing from lua")
	local BracketDisplay = require('Module:Brkts/WikiSpecific').getMatchGroupModule('bracket')
	return BracketDisplay.luaGet(frame, args, matches)
end

function MatchGroupDisplay.matchlist(frame)
	local args = getArgs(frame)
	return MatchGroupDisplay.luaMatchlist(frame, args)
end

function MatchGroupDisplay.customMatchlist(frame, args, matches)
	if not args then
		args = getArgs(frame)
	end

	if not matches or #matches == 0 then
		args[1] = args.id or args[1] or ''
		matches = MatchGroupDisplay._getMatches(args[1])
	end

	if args.title ~= '' and args.title ~= nil then
		matches[1].bracketData.title = args.title
	end

	for index, _ in ipairs(matches) do
		if args['M' .. index .. 'header'] ~= '' and args['M' .. index .. 'header'] ~= nil then
			matches[index].bracketData.header = args['M' .. index .. 'header']
		end
	end

	return MatchGroupDisplay.luaMatchlist(frame, args, matches)
end

function MatchGroupDisplay.luaMatchlist(frame, args, matches)
	local MatchlistDisplay = require('Module:Brkts/WikiSpecific').getMatchGroupModule('matchlist')
	return MatchlistDisplay.luaGet(frame, args, matches)
end

-- display MatchGroup (Bracket/MatchList) from ID
function MatchGroupDisplay.Display(frame)
	local args = getArgs(frame)
	args[1] = args.id or args[1] or ''
	local bracketId = args[1]

	local matches = MatchGroupDisplay._getMatches(bracketId)

	local matchGroupType = matches[1].bracketData.type

	local MatchGroupModule = require('Module:Brkts/WikiSpecific').getMatchGroupModule(matchGroupType)
	return MatchGroupModule.luaGet(frame, args, matches)
end

function MatchGroupDisplay.DisplayDev(frame)
	require('Module:DevFlags').matchGroupDev = true
	return MatchGroupDisplay.Display(frame)
end

--Helper functions for custom Bracket/Matchlist options
function MatchGroupDisplay._getMatches(id)
	if not MatchGroupUtil then
		MatchGroupUtil = require('Module:MatchGroup/Util')
	end
	local matches = MatchGroupUtil.fetchMatches(id)
	if #matches == 0 then
		error('No data found for bracketId=' .. id)
	end
	return matches
end

function MatchGroupDisplay._getMatchIndexFromMatchId(matchId, bracketId)
	matchId = string.gsub(matchId, bracketId .. '_', '')
	local round, matchInRound = string.match(matchId, '^R(%d+)%-M(%d+)$')
	return tonumber(round or ''), tonumber(matchInRound or '')
end

return MatchGroupDisplay
