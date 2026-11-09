---
-- @Liquipedia
-- page=Module:Standings/Parameters
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local StandingsOvertime = Lua.import('Module:Standings/Overtime')

---The template parameters of the standings tables, see Module:ArgSchema.
---Documentation contexts are `{tabletype: StandingsTableTypes}`, see Module:ArgSchema/Documentation.
local StandingsParameters = {}

local STATUSES = {'byeup', 'seedup', 'up', 'stayup', 'stay', 'staydown', 'down', 'dq'}
local OPPONENT_TEMPLATES = {
	'TeamOpponent', 'SoloOpponent', 'DuoOpponent', 'TrioOpponent', 'QuadOpponent', 'LiteralOpponent',
}

StandingsParameters.DEFAULT_POINTS = {
	swiss = {w = 1, d = 0.5, l = 0},
	group = {w = 3, d = 1, l = 0},
}
StandingsParameters.DEFAULT_OVERTIME_POINTS = {w = 3, d = 1.5, l = 0, otw = 2, otl = 1}
---@type table<StandingsTableTypes, string>
StandingsParameters.DEFAULT_TIEBREAKERS = {swiss = 'matchscore', group = 'points', ffa = 'points'}

---@param ... StandingsTableTypes
---@return fun(context: table): boolean
local function onlyFor(...)
	local tableTypes = {...}
	return function(context)
		return Array.any(tableTypes, function(tableType) return tableType == context.tabletype end)
	end
end

---@param bySwiss string
---@param byGroup string
---@param byFfa string
---@return fun(context: table): string
local function byTableType(bySwiss, byGroup, byFfa)
	local texts = {swiss = bySwiss, group = byGroup, ffa = byFfa}
	return function(context)
		return texts[context.tabletype] or bySwiss
	end
end

---@param input string|number|boolean
---@return integer?
local function readDisqualifiedFromRound(input)
	local fromRound = tonumber(input)
	if fromRound then
		assert(fromRound >= 1 and fromRound == math.floor(fromRound),
			'Invalid dq input: "' .. input .. '" is not a round')
		return fromRound
	end
	local disqualified = Logic.readBoolOrNil(input)
	assert(disqualified ~= nil, 'Invalid dq input: "' .. tostring(input) .. '" is neither a boolean nor a round')
	return disqualified and 1 or nil
end

---@param input string|boolean
---@return boolean
local function readOvertime(input)
	local overtime = Logic.readBool(input)
	if overtime and not StandingsOvertime.regulationRounds() then
		error('Overtime standings require `Info.config.standings.overtime.regulationRounds` to be configured')
	end
	return overtime
end

---@param input string|number
---@return number
local function readWidth(input)
	local width = tonumber((string.gsub(input, 'px$', '')))
	assert(width, 'Invalid width input: "' .. input .. '" is not a width in px')
	return width
end

---@type ArgSchemaParameter[]
StandingsParameters.round = {
	{
		name = 'title',
		description = byTableType(
			'The display title of this round.',
			'The display title of this round, used in the round selector.',
			'The display title of this round.'
		),
	},
	{
		name = 'started',
		type = 'boolean',
		description = 'Whether this round has started. By default, a round has started once any of its matches is no '
			.. 'longer upcoming. Set to <code>true</code> or <code>false</code> to override it.',
	},
	{
		name = 'finished',
		type = 'boolean',
		description = 'Whether this round has finished. By default, a round has finished once all of its matches are '
			.. 'finished. Set to <code>true</code> or <code>false</code> to override it. A finished round always counts '
			.. 'as started. A round without any matches has neither started nor finished, unless set manually.',
	},
	{
		name = 'sdate',
		type = 'timestamp',
		description = 'The start time of the round. Matches imported through {{para|matchgroups}} or {{para|stages}} '
			.. 'that are played before this time are not part of the round.',
	},
	{
		name = 'edate',
		type = 'timestamp',
		description = 'The end time of the round. Matches imported through {{para|matchgroups}} or {{para|stages}} '
			.. 'that are played after this time are not part of the round.',
	},
	{
		name = 'matches',
		type = 'list',
		description = 'Comma-separated list of match2matchid\'s that are linked to this round. Match ids that have '
			.. 'not been stored yet count as upcoming, so the round does not finish before they are played.',
	},
	{
		name = 'matchgroups',
		type = 'list',
		description = 'Comma-separated list of match2bracketid\'s that are linked to this round.',
	},
	{
		name = 'stages',
		type = 'list',
		description = 'Comma-separated list of page names of tournaments (stages) whose matches are linked to this round.',
	},
}

---@param name string
---@param what string
---@return ArgSchemaParameter
local function adjustment(name, what)
	return {
		name = 'r{round}' .. name,
		aliases = {name},
		type = 'number',
		description = 'Adds ' .. what .. ' to the opponent from that round onwards, on top of the ones from the '
			.. 'matches. Without a round, e.g. {{para|' .. name .. '}}, it applies to the final round. '
			.. 'Adjustments of several rounds add up. Positive or negative numbers can be entered.',
	}
end

---@type ArgSchemaParameter[]
StandingsParameters.opponent = {
	{
		name = 'r{round}',
		description = 'The points of the opponent in that round, or <code>-</code> if the opponent did not take part '
			.. 'in it. Takes priority over the points imported from the matches.',
	},
	{
		name = 'aliases',
		type = 'list',
		separator = ';',
		description = 'Team opponents only. List of other team templates of this team, separated by <code>;</code>. '
			.. 'Matches played under any of these templates are counted for this team. Example: '
			.. '{{para|aliases|<nowiki>oldname;othername</nowiki>}}.',
	},
	{
		name = 'startingpoints',
		type = 'number',
		description = 'Points the opponent starts the standings with, before the first round.',
	},
	{
		name = 'dq',
		read = readDisqualifiedFromRound,
		description = 'Disqualifies the opponent. {{para|dq|true}} disqualifies from the first round, {{para|dq|3}} '
			.. 'from round 3 onwards. Disqualified opponents are placed at the bottom and get the '
			.. '{{bgcolortext|dq|dq}} status.',
	},
	{
		name = 'r{round}status',
		aliases = {'r{round}bg'},
		type = 'enum',
		values = STATUSES,
		description = 'Manually sets the status of the opponent from this round onwards, overriding {{para|bg}}. '
			.. 'Example: {{para|r3status|up}} for an opponent that has secured advancement in round 3. '
			.. '{{para|r3bg}} is an older name of it.',
	},
	{
		name = 'r{round}minstatus',
		type = 'enum',
		values = STATUSES,
		description = 'Sets the worst status the opponent can still end up with, from this round onwards. Shown as a '
			.. 'label as long as no status is set. Example: {{para|r3minstatus|stay}} for an opponent that can no '
			.. 'longer be eliminated.',
	},
	adjustment('points', 'points'),
	adjustment('tiebreaker', 'a score for the <code>manual</code> tiebreaker, where higher values are placed higher,'),
	adjustment('matchwins', 'match wins'),
	adjustment('matchdraws', 'match draws'),
	adjustment('matchlosses', 'match losses'),
	adjustment('gamewins', 'game wins'),
	adjustment('gamedraws', 'game draws'),
	adjustment('gamelosses', 'game losses'),
	adjustment('roundwins', 'round wins'),
	adjustment('roundlosses', 'round losses'),
}

---A round parameter, which the header takes when there are no rounds.
---@param name string
---@return ArgSchemaParameter
local function withoutRounds(name)
	local parameter = Array.find(StandingsParameters.round, function(roundParameter)
		return roundParameter.name == name
	end)
	return Table.merge(parameter, {
		description = 'Without rounds, the header is the only round and takes the {{para|' .. name .. '}} of a '
			.. '[[#Round|round]].',
	})
end

---@type ArgSchemaParameter[]
StandingsParameters.header = {
	{
		name = 'tabletype',
		type = 'enum',
		values = {'swiss', 'group', 'ffa'},
		hidden = true,
		description = 'The type of the table.',
	},
	{
		name = 'title',
		description = 'Sets the title of the table.',
	},
	{
		name = 'bg',
		description = function(context)
			local example = byTableType('1=up, 2-8=stayup, 9-16=down', '1-2=up, 3-4=down', '1-10=stay, 11-20=down')
			return 'Background of placements. Format is as {{para|bg|<nowiki>placementStart-placementEnd=type, '
				.. 'placement=anotherType</nowiki>}} (Example: {{para|bg|<nowiki>' .. example(context) .. '</nowiki>}}). '
				.. 'A single placement can be given instead of a range. Available colors are: '
				.. table.concat(Array.map(STATUSES, function(status)
					return '{{bgcolortext|' .. status .. '|' .. status .. '}}'
				end), ', ')
		end,
	},
	{
		name = 'tiebreakers',
		type = 'json',
		templates = {'Json'},
		description = function(context)
			local usage = byTableType(
				'Example {{para|tiebreakers|<nowiki>{{Json|matchscore|buchholz|ml.matchdiff}}</nowiki>}}.',
				'Example {{para|tiebreakers|<nowiki>{{Json|points|ml.points|gamediff}}</nowiki>}}.',
				'Only tiebreakers over all matches can be used, not head-to-head ones.'
			)
			return 'The tiebreakers used in this standings, in the order they are applied. Defaults to <code>'
				.. StandingsParameters.DEFAULT_TIEBREAKERS[context.tabletype] .. '</code>. ' .. usage(context)
				.. ' See [[#Tiebreakers|Tiebreakers]] for the available tiebreakers.'
		end,
	},
	{
		name = 'points',
		condition = onlyFor('swiss', 'group'),
		description = function(context)
			local points = StandingsParameters.DEFAULT_POINTS[context.tabletype]
			local defaults = 'win=' .. points.w .. ', draw=' .. points.d .. ', loss=' .. points.l
			return table.concat({
				'Customize the amount of points received for a given outcome or score. Defaults to {{para|points|'
					.. '<nowiki>' .. defaults .. '</nowiki>}}. Available keys:',
				'* <code>win</code>, <code>draw</code> and <code>loss</code>: Points for the result of a match.',
				'* <code>X-Y</code> (e.g. <code>2-0=4</code>): Points for an opponent that scored X against Y. When a '
					.. 'score key matches, the generic result points are not applied. Only applies to finished matches '
					.. 'between two opponents with a numeric score.',
				'* <code>otwin</code> and <code>otloss</code>: Points for an overtime win or loss. '
					.. 'Requires {{para|overtime|true}}, see [[#Overtime|Overtime]].',
				'Keys that are not given keep their default value.',
			}, '\n')
		end,
	},
	{
		name = 'p{placement}',
		type = 'number',
		condition = onlyFor('ffa'),
		description = 'Points for a placement in an imported match, e.g. {{para|p1|10}}. '
			.. 'Without {{para|p1}}, the score of the opponent in the match is used.',
	},
	{
		name = 'import',
		type = 'boolean',
		default = true,
		description = byTableType(
			'Import the results of the opponents from the matches of the rounds. Required to be '
				.. '{{para|import|true}} in Swiss setup.',
			'Import the results of the opponents from the matches of the rounds.',
			'Import the results of the opponents from the matches of the rounds.'
		),
	},
	{
		name = 'importopponents',
		type = 'boolean',
		description = 'By default uses the same value as {{para|import}}. Set to <code>false</code> to only show the '
			.. 'opponents that are listed manually, while still importing their results from the matches.',
	},
	{
		name = 'exclusive',
		type = 'boolean',
		default = false,
		description = 'By default, a match is counted if at least one of its opponents is part of the standings. '
			.. "Set to <code>true</code> to only count matches where '''all''' opponents are part of the standings.",
	},
	{
		name = 'matchdraws',
		type = 'boolean',
		description = 'Whether match draws are shown (W-D-L instead of W-L). By default this is detected from the '
			.. 'matches. Set to <code>true</code> or <code>false</code> to force it.',
	},
	{
		name = 'walkovergames',
		type = 'nonNegativeInteger',
		description = 'The number of games a walkover (W, FF, DQ or L) counts as in the game tiebreakers. With '
			.. '{{para|walkovergames|2}}, a walkover counts as 2 game wins for the winner and 2 game losses for the '
			.. 'loser. By default, walkovers do not count towards the games.',
	},
	{
		name = 'walkoverrounds',
		type = 'nonNegativeInteger',
		description = 'The number of rounds a walkover of a game counts as in the round tiebreakers, won by the '
			.. 'winner and lost by the loser. By default, walkovers do not count towards the rounds.',
	},
	{
		name = 'overtime',
		read = readOvertime,
		default = false,
		description = 'Track overtime results separately from regulation results. Only available on wikis that '
			.. 'configured overtime. See [[#Overtime|Overtime]].',
	},
	{
		name = 'format',
		condition = onlyFor('swiss', 'group'),
		description = 'The format of the standings, used to show the placements an opponent can still reach. '
			.. '<code>gsl</code> for a GSL group, <code>swiss&lt;N&gt;</code> for a swiss where opponents advance with N wins '
			.. 'and are eliminated with N losses, or {{para|format|<nowiki>{{Json|swiss|adv=3|elim=2}}</nowiki>}} '
			.. 'when the wins and losses differ. Opponents only meet opponents with the same record.',
	},
	{
		name = 'tiebreakerreset',
		type = 'boolean',
		default = false,
		description = 'By default, opponents that are still tied after a tiebreaker continue with the next one. Set to '
			.. '<code>true</code> to resolve every group of opponents that a tiebreaker splits again from the first '
			.. 'tiebreaker, so head-to-head tiebreakers are applied again among the smaller group.',
	},
	{
		name = 'placements',
		condition = onlyFor('swiss'),
		description = 'Shared placements of the final standings, used when importing the standings into a prize pool. '
			.. 'Format is a list of placements or placement ranges separated by <code>;</code>, e.g. '
			.. '{{para|placements|<nowiki>1;2;3-4;5-8;9-16</nowiki>}}. Every placement from 1 to the number of opponents '
			.. 'has to be covered exactly once, otherwise the input is ignored and a warning is logged.',
	},
	{
		name = 'date',
		type = 'timestamp',
		description = 'The date used to resolve the opponents (e.g. which team template applies). '
			.. 'Defaults to the date of the tournament.',
	},
	{
		name = 'store',
		type = 'boolean',
		default = true,
		description = 'Set to <code>false</code> to not store the standings in LPDB.',
	},
	{
		name = 'width',
		read = readWidth,
		description = 'The width of the table in px, e.g. {{para|width|600}}. The same as the width of a matchlist.',
	},
	{
		name = 'matches',
		type = 'list',
		description = 'Comma-separated list of match2matchid\'s of the standings, in addition to the ones of the '
			.. 'rounds. Without rounds, these are the matches of the only round.',
	},
	{
		name = 'round{round}',
		type = 'json',
		templates = {'Round'},
		description = 'The rounds of the standings, as {{para|round1|<nowiki>{{Round|...}}</nowiki>}}. '
			.. 'See [[#Round|Round]].',
	},
	withoutRounds('started'),
	withoutRounds('finished'),
	withoutRounds('sdate'),
	withoutRounds('edate'),
	withoutRounds('matchgroups'),
	withoutRounds('stages'),
	{
		name = '{opponent}',
		type = 'json',
		templates = OPPONENT_TEMPLATES,
		example = '{{TeamOpponent|...}}',
		description = 'One per opponent. See [[#Opponent|Opponent]].',
	},
}

return StandingsParameters
