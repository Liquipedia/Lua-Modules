---
-- @Liquipedia
-- wiki=commons
-- page=Module:Opponent
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Flags = require('Module:Flags')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')
local TypeUtil = require('Module:TypeUtil')

--[[
Structural type representation of an opponent.

Examples:
{type = Opponent.solo, players = {displayName = 'Neeb'}}
{type = Opponent.team, template = 'alpha x 2020'}
{type = Opponent.literal, name = 'B2'}

See Opponent.types.Opponent for the exact encoding scheme and required fields.

- For opponent display components, see Module:OpponentDisplay.
- For input from wikicode, use {{1Opponent|...}}, {{TeamOpponent|...}} etc.
- Used by: PrizePool, GroupTableLeague, match2 Matchlist/Bracket,
StarcraftMatchSummary
- Wikis may add additional wiki-specific fields to the opponent representation.

]]
local Opponent = {types = {}}

Opponent.team = 'team'
Opponent.solo = 'solo'
Opponent.duo = 'duo'
Opponent.trio = 'trio'
Opponent.quad = 'quad'
Opponent.literal = 'literal'

Opponent.partyTypes = {Opponent.solo, Opponent.duo, Opponent.trio, Opponent.quad}
Opponent.types = Array.extend(Opponent.partyTypes, {Opponent.team, Opponent.literal})

Opponent.partySizes = {
	solo = 1,
	duo = 2,
	trio = 3,
	quad = 4,
}

Opponent.types.Player = TypeUtil.struct({
	displayName = 'string',
	flag = 'string?',
	pageName = 'string?',
})

Opponent.types.TeamOpponent = TypeUtil.struct({
	template = 'string',
	type = TypeUtil.literal(Opponent.team),
})

Opponent.types.PartyOpponent = TypeUtil.struct({
	players = TypeUtil.array(Opponent.types.Player),
	type = TypeUtil.literalUnion(unpack(Opponent.partyTypes)),
})

Opponent.types.LiteralOpponent = TypeUtil.struct({
	name = 'string',
	type = TypeUtil.literal(Opponent.literal),
})

Opponent.types.Opponent = TypeUtil.union(
	Opponent.types.TeamOpponent,
	Opponent.types.PartyOpponent,
	Opponent.types.LiteralOpponent
)

function Opponent.typeIsParty(type)
	return Opponent.partySizes[type] ~= nil
end

--[[
Returns the player count for a party type, or nil otherwise.

Opponent.partySize(Opponent.duo) == 2
]]
function Opponent.partySize(type)
	return Opponent.partySizes[type]
end

--[[
Creates a blank literal opponent, or a blank opponent of the specified type
]]
function Opponent.blank(type)
	if type == Opponent.team then
		return {type = type, template = 'tbd'}
	elseif Opponent.typeIsParty(type) then
		return {
			type = type,
			players = Array.map(
				Array.range(1, Opponent.partySize(type)),
				function(_) return {displayName = ''} end
			),
		}
	else
		return {type = Opponent.literal, name = ''}
	end
end

--[[
Creates a blank TBD opponent, or a TBD opponent of the specified type
]]
function Opponent.tbd(type)
	if type == Opponent.team then
		return {type = type, template = 'tbd'}
	elseif Opponent.typeIsParty(type) then
		return {
			type = type,
			players = Array.map(
				Array.range(1, Opponent.partySize(type)),
				function(_) return {displayName = 'TBD'} end
			),
		}
	else
		return {type = Opponent.literal, name = 'TBD'}
	end
end

--[[
Whether an opponent is TBD
]]
function Opponent.isTbd(opponent)
	if opponent.type == Opponent.team then
		return opponent.template == 'tbd'

			-- The following can't occur in valid opponents, but we check for them anyway
			or opponent.name == 'TBD'
			or String.isEmpty(opponent.template)

	elseif opponent.type == Opponent.literal then
		return true

	else
		return Array.any(opponent.players, Opponent.playerIsTbd)
	end
end

function Opponent.playerIsTbd(player)
	return player.displayName == '' or player.displayName == 'TBD'
end

function Opponent.isType(type)
	return Table.includes(Opponent.types, type)
end

function Opponent.readType(type)
	return Table.includes(Opponent.types, type) and type or nil
end

--[[
Asserts that an arbitary value is a valid representation of an opponent
]]
function Opponent.assertOpponent(opponent)
	assert(Opponent.isOpponent(opponent), 'Invalid opponent')
end

--[[
Coerces an arbitary table into an opponent
]]
function Opponent.coerce(opponent)
	assert(type(opponent) == 'table')

	opponent.type = Opponent.isType(opponent.type) and opponent.type or Opponent.literal
	if opponent.type == Opponent.literal then
		opponent.name = type(opponent.name) == 'string' and opponent.name or ''
	elseif opponent.type == Opponent.team then
		if String.isEmpty(opponent.template) or type(opponent.template) ~= 'string' then
			opponent.template = 'tbd'
		end
	else
		if type(opponent.players) ~= 'table' then
			opponent.players = {}
		end
		local partySize = Opponent.partySize(opponent.type)
		opponent.players = Array.sub(opponent.players, 1, partySize)
		for _, player in ipairs(opponent.players) do
			if type(player.displayName) ~= 'string' then
				player.displayName = ''
			end
		end
		for i = #opponent.players + 1, partySize do
			opponent.players[i] = {displayName = ''}
		end
	end
end

--[[
Returns the match mode for two or more opponent types.

Example:

Opponent.toMode(Opponent.duo, Opponent.duo) == '2_2'
]]
function Opponent.toMode(...)
	local modeParts = Array.map(arg, function(opponentType)
		return Opponent.partySize(opponentType) or opponentType
	end)
	return table.concat(modeParts, '_')
end

--[[
Returns the legacy match mode for two or more opponent types.

Used by LPDB placement and tournament records, and smw records.

Example:

Opponent.toLegacyMode(Opponent.duo, Opponent.duo) == '2v2'
]]
function Opponent.toLegacyMode(...)
	local modeParts = Array.map(arg, function(opponentType)
		return Opponent.partySize(opponentType) or opponentType
	end)
	local mode = table.concat(modeParts, 'v')
	if mode == 'teamvteam' then
		return Opponent.team
	else
		return mode
	end
end

--[[
Resolves the identifiers of an opponent.

For team opponents, this resolves the team template to a particular date. For
party opponents, this fills in players' pageNames using their displayNames,
using data stored in page variables if present.
]]
function Opponent.resolve(opponent, date)
	if opponent.type == Opponent.team then
		opponent.template = TeamTemplate.resolve(opponent.template, date) or 'tbd'
	elseif Opponent.typeIsParty(opponent.type) then
		local PlayerExt = require('Module:Player/Ext')
		for _, player in ipairs(opponent.players) do
			PlayerExt.populatePageName(player)
		end
	end
	return opponent
end

--[[
Converts a opponent to a name. The name is the same as the one used in the
match2opponent.name field.

Returns nil if the team template does not exist.
]]
function Opponent.toName(opponent)
	if opponent.type == Opponent.team then
		return TeamTemplate.getPageName(opponent.template)
	elseif Opponent.typeIsParty(opponent.type) then
		local pageNames = Array.map(opponent.players, function(player)
			return player.pageName or player.displayName
		end)
		return table.concat(pageNames, ' / ')
	else -- opponent.type == Opponent.literal
		return opponent.name
	end
end

--[[
Parses an argument table of an Opponent input template into an opponent struct.
Returns nil if the input is invalid.

Opponent input templates include Template:TeamOpponent, Template:SoloOpponent,
Template:LiteralOpponent, and etc.

Wikis sometimes provide variants of this function that include wiki specific
transformations.
]]
function Opponent.readOpponentArgs(args)
	local partySize = Opponent.partySize(args.type)

	if args.type == Opponent.team then
		local template = args.template or args[1]
		return template and {
			type = Opponent.team,
			template = template:lower():gsub('_', ' '),
		}

	elseif partySize == 1 then
		local player = {
			displayName = args[1] or args.p1 or args.name or '',
			flag = String.nilIfEmpty(Flags.CountryName(args.flag)),
			pageName = args.link,
		}
		return {type = Opponent.solo, players = {player}}

	elseif partySize then
		local players = Array.map(Array.range(1, partySize), function(i)
			return {
				displayName = args[i] or args['p' .. i] or '',
				flag = String.nilIfEmpty(Flags.CountryName(args['p' .. i .. 'flag'])),
				pageName = args['p' .. i .. 'link'],
			}
		end)
		return {type = args.type, players = players}

	elseif args.type == Opponent.literal then
		return {type = Opponent.literal, name = args.name or args[1] or ''}

	end
end

--[[
Creates an opponent struct from a match2opponent record. Returns nil if
unsuccessful.

Wikis sometimes provide variants of this function that include wiki specific
transformations.
]]
function Opponent.fromMatch2Record(record)
	if record.type == Opponent.team then
		return {type = Opponent.team, template = record.template}

	elseif Opponent.typeIsParty(record.type) then
		return {
			type = record.type,
			players = Array.map(record.match2players, function(playerRecord)
				return {
					displayName = playerRecord.displayname,
					flag = String.nilIfEmpty(Flags.CountryName(playerRecord.flag)),
					pageName = String.nilIfEmpty(playerRecord.name),
				}
			end),
		}

	elseif record.type == Opponent.literal then
		return {type = Opponent.literal, name = record.name or ''}

	else
		return nil
	end
end

--[[
Reads an opponent struct and builds a storage struct for standing/prizePool from it
]]
function Opponent.toLpdbStruct(opponent, resolveTeamToPageName)
	local storageStruct = {
		opponentname = opponent.name,
		opponenttemplate = opponent.template,
		opponenttype = opponent.type,
	}

	if opponent.type == Opponent.team then
		if resolveTeamToPageName then
			storageStruct.opponentname = Opponent.teamTemplateResolveRedirect(opponent.template)
		end
	elseif Opponent.typeIsParty(opponent.type) then
		local players = {}
		for playerIndex, player in ipairs(opponent.players) do
			players['p' .. playerIndex .. 'dn'] = player.displayName
			players['p' .. playerIndex .. 'flag'] = player.flag
			players['p' .. playerIndex] = player.pageName
			players['p' .. playerIndex .. 'team'] = resolveTeamToPageName
				and Opponent.teamTemplateResolveRedirect(player.team)
				or player.team
			players['p' .. playerIndex .. 'template'] = resolveTeamToPageName
				and player.team or nil
		end
		storageStruct.opponentplayers = players
	end

	return storageStruct
end

function Opponent.teamTemplateResolveRedirect(template)
	if String.isEmpy(template) then
		return nil
	end

	if mw.ext.TeamTemplate.teamexists(template) then
		local page = mw.ext.TeamTemplate.raw(template).page
		return mw.ext.TeamLiquidIntegration.resolve_redirect(page)
	end

	return template
end

--[[
Reads a standing/prizePool storage struct and builds an opponent struct from it
]]
function Opponent.fromLpdbStruct(storageStruct)
	local partySize = Opponent.partySize(storageStruct.type)
	if partySize then
		local players = storageStruct.opponentplayers
		local function playerFromLpdbStruct(playerIndex)
			return {
				displayName = players['p' .. playerIndex .. 'dn'],
				flag = Flags.CountryName(players['p' .. playerIndex .. 'flag']),
				pageName = players['p' .. playerIndex],
				team = players['p' .. playerIndex .. 'team'],
			}
		end
		local opponent = {
			players = Array.map(Array.range(1, partySize), playerFromLpdbStruct),
			type = storageStruct.type,
		}
		return opponent
	else
		return {
			name = storageStruct.opponentname,
			template = storageStruct.opponenttemplate,
			type = storageStruct.opponenttype,
		}
	end
end

return Opponent
