---
-- @Liquipedia
-- wiki=valorant
-- page=Module:BigMatch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Match = require('Module:Match')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tabs = require('Module:Tabs')
local TemplateEngine = require('Module:TemplateEngine')

local CustomMatchGroupInput = Lua.import('Module:MatchGroup/Input/Custom', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})

---@class BigMatch
local BigMatch = Class.new()

mw.ext.LOLDB = {}
function mw.ext.LOLDB.get(apiId)
	return Json.parse(
		[[
			{
				"team1": "T1",
				"team2": "CLG",
				"team1Score": 3,
				"team2Score": 1,
				"matchTime": 1662701100,
				"patch": "21.2.16",
				"mvp": "Faker",
				"games": [
					{
						"length": 2000,
						"winner": 1,
						"team1Score": "W",
						"team2Score": "F",
						"mvp": "Zeus",
						"team1": {
							"name": "T1",
							"side": "blue",
							"towersKilled": 3,
							"inhibitorsKilled": 1,
							"baronsKilled": 0,
							"heraldsKills": 4,
							"dragonsKilled": [
								"cloud",
								"elder",
								"ocean"
							],
							"players": [
								{
									"id": "PlayerName",
									"role": "top",
									"champion": "Heimerdinger",
									"gold": 12345,
									"kills": 22,
									"deaths": 4,
									"assists": 2,
									"creepScore": 200,
									"damageDone": 56645,
									"runes": [
										"precision",
										"sorcery"
									],
									"summonerSpells": [
										"flash",
										"teleport"
									],
									"items": [
										"foo",
										"bar",
										"baz",
										"lorem",
										"ipsum",
										"AliceBobCharlie"
									]
								}
							]
						},
						"team2": {
						},
						"championVeto": [
							{
								"vetoNumber": 1,
								"champion": "Aatrox",
								"type": "ban",
								"team": 1
							}, 
							{
								"vetoNumber": 2,
								"champion": "Riven",
								"type": "ban",
								"team": 2
							},
							{
								"vetoNumber": 3,
								"champion": "Azir",
								"type": "ban",
								"team": 1
							}, 
							{
								"vetoNumber": 4,
								"champion": "Fiora",
								"type": "ban",
								"team": 2
							},
							{
								"vetoNumber": 5,
								"champion": "Akali",
								"type": "ban",
								"team": 1
							}, 
							{
								"vetoNumber": 6,
								"champion": "Urf",
								"type": "ban",
								"team": 2
							},
							{
								"vetoNumber": 7,
								"champion": "Heimerdinger",
								"type": "pick",
								"team": 1
							}, 
							{
								"vetoNumber": 8,
								"champion": "Jinx",
								"type": "pick",
								"team": 2
							},
							{
								"vetoNumber": 9,
								"champion": "Singed",
								"type": "pick",
								"team": 2
							}, 
							{
								"vetoNumber": 10,
								"champion": "Jayce",
								"type": "pick",
								"team": 1
							}
						]
					}
				]
			}
		]]
	)
end

function BigMatch.templateHeader()
	return
[=[
<div class="fb-match-page-header">
	<div class="fb-match-page-header-tournament">
		[[{{link}}|{{name}}]]
	</div>
	<div class="fb-match-page-header-teams row">
		<div class="fb-match-page-header-team-container col-sm-4 col-xs-6 col-sm-pull-4">
			<div class="fb-match-page-header-team">
				{{match2opponents.1.iconDisplay}}
				<br>
				[[{{match2opponents.1.name}}]]
			</div>
			<div class="fb-match-page-header-score">
				{{match2opponents.1.score}}
			</div>
		</div>
		<div class="fb-match-page-header-team-container col-sm-4 col-xs-6 col-sm-pull-4">
			<div class="fb-match-page-header-team">
				{{match2opponents.2.iconDisplay}}
				<br>
				[[{{match2opponents.2.name}}]]
			</div>
			<div class="fb-match-page-header-score">
				{{match2opponents.2.score}}
			</div>
		</div>
	</div>
</div>
]=]
end

function BigMatch.templateGame()
	return
[=[
<div>
	{{match2opponents.1.name}}
	{{winner}}
	{{match2opponents.2.name}}
</div>
]=]
end

function BigMatch.templateFooter()
	return
[=[
<h3>Additional Information</h3>
<div>
{{#links}}
	{{.}}
{{/links}}
</div>
<br>
<div>
	[[{{patch}}]]
</div>
]=]
end

function BigMatch.run(frame)
	local args = Arguments.getArgs(frame)

	---@type BigMatch
	local bigMatch = BigMatch()

	local apiId = args.apiid

	local matchInput = mw.ext.LOLDB.get(apiId)

	matchInput = bigMatch:_apiToMatch2(matchInput)
	matchInput = Table.merge(args, matchInput)

	local match = CustomMatchGroupInput.processMatch(matchInput, {isStandalone = true})

	local bracketId, matchId = bigMatch:_getId()
	match.bracketid, match.matchid = 'MATCH_' .. bracketId, matchId

	-- Don't store match1 as BigMatch records are not complete
	Match.store(match, {storeMatch1 = false, storeSmw = false})

	-- Retrieve tournament link from the bracket
	if String.isEmpty(args.tournamentlink) then
		args.tournamentlink = bigMatch:_fetchTournamentLinkFromMatch{bracketId, matchId}
	end

	local tournamentData = bigMatch:_fetchTournamentInfo(args.tournamentlink)

	match.patch = match.patch or tournamentData.patch
	local tournament = {
		name = args.tournament or tournamentData.name,
		link = args.tournamentlink or tournamentData.pagename,
	}

	mw.logObject(match, 'After match2')
	return bigMatch:render(match, tournament)
end

-- TODO: WIP
function BigMatch:_apiToMatch2(apiInput)
	mw.logObject(apiInput, 'input')
	local match2Input = {}

	match2Input.date = DateExt.toCountdownArg(apiInput.matchTime)
	match2Input.patch = apiInput.patch
	match2Input.opponent1 = {
		apiInput.team1,
		type = Opponent.team,
		score = apiInput.score1,
	}
	match2Input.opponent2 = {
		apiInput.team2,
		type = Opponent.team,
		score = apiInput.score2,
	}

	local parsedGames = Array.map(apiInput.games, function(game)
		local newGame = {}
		newGame.winner = game.winner
		newGame.length = math.floor(game.length/60) .. ":" .. (game.length%60)
		newGame.team1side = game.team1.side
		newGame.team2side = game.team1.side
		return newGame
	end)
	Table.mergeInto(match2Input, Table.map(parsedGames, function(index, game) return "map".. index, game end))
	mw.logObject(match2Input, 'output')

	return match2Input
end

function BigMatch:render(match, tournament)
	local overall = mw.html.create('div'):addClass('fb-match-page-overall')

	overall :wikitext(self:header(match, tournament))
			:wikitext(self:games(match))
			:wikitext(self:footer(match))

	return overall
end

function BigMatch:header(match, tournament)
	return TemplateEngine():render(BigMatch.templateHeader(), Table.merge(match, tournament))
end

function BigMatch:games(match)
	local games = Array.map(match.match2games, function (game)
		if game.resulttype == 'np' then
			return
		end

		return TemplateEngine():render(BigMatch.templateGame(), Table.merge(match, game))
	end)

	---@type table<string, any>
	local tabs = {
		This = 1,
		['hide-showall'] = true
	}

	Array.forEach(games, function (game, idx)
		tabs['name' .. idx] = 'Map ' .. idx
		tabs['content' .. idx] = tostring(game)
	end)

	return Tabs.dynamic(tabs)
end

function BigMatch:footer(match)
	return TemplateEngine():render(BigMatch.templateFooter(), match)
end

function BigMatch:_getId()
	local title = mw.title.getCurrentTitle().text

	-- Match alphanumeric pattern 10 characters long, followed by space and then the match id
	local staticId = string.match(title, '%w%w%w%w%w%w%w%w%w%w .*')
	local fullBracketId = string.match(title, '%w%w%w%w%w%w%w%w%w%w')
	local matchId = string.sub(staticId, 12)

	return fullBracketId, matchId
end

function BigMatch:_fetchTournamentInfo(page)
	if not page then
		return {}
	end

	return mw.ext.LiquipediaDB.lpdb('tournament', {
		query = 'pagename, name, patch',
		conditions = '[[pagename::'.. page .. ']]',
	})[1] or {}
end

function BigMatch:_fetchTournamentLinkFromMatch(identifiers)
	local data = mw.ext.LiquipediaDB.lpdb('match2', {
		query = 'parent, pagename',
		conditions = '[[match2id::'.. table.concat(identifiers, '_') .. ']]',
	})[1] or {}
	return Logic.emptyOr(data.parent, data.pagename)
end

return BigMatch
