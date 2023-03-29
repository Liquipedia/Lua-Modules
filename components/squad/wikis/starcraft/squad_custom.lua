---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local String = require('Module:StringUtils')

local Squad = Lua.import('Module:Squad', {requireDevIfEnabled = true})
local SquadRow = Lua.import('Module:Squad/Row', {requireDevIfEnabled = true})

local CustomSquad = {}

function CustomSquad:headerTlpb()
	local makeHeader = function(wikiText)
		return mw.html.create('th'):wikitext(wikiText):addClass('divCell')
	end

	local headerRow = mw.html.create('tr'):addClass('HeaderRow')

	headerRow:node(makeHeader('ID'))
		:node(makeHeader(''))
		:node(makeHeader('Name'))
		:node(makeHeader('ELO'))
		:node(makeHeader('ELO Peak'))

	self.content:node(headerRow)

	return self
end

local ExtendedSquadRow = Class.new(SquadRow)
function ExtendedSquadRow:elo(args)
	self.content:node(mw.html.create('td'):wikitext(args.eloCurrent and (args.eloCurrent .. ' pts') or '-'))
	self.content:node(mw.html.create('td'):wikitext(args.eloPeak and (args.eloPeak .. ' pts') or '-'))

	return self
end

function CustomSquad.run(frame)
	local squad = Squad()
	squad:init(frame)

	local args = squad.args

	local tlpb = Logic.readBool(args.tlpb)
	if tlpb then
		squad.header = CustomSquad.headerTlpb
	else
		squad:title()
	end
	
	squad:header()

	local players = Array.mapIndexes(function (index)
		return Json.parseIfString(args[index])
	end)

	Array.forEach(players, function (player)
		local row = ExtendedSquadRow()

		local faction = CustomSquad._queryTLPB(player.id, 'race') or player.race
		local id = CustomSquad._queryTLPB(player.id, 'name') or player.id
		local link = player.link or player.altname or id
		local currentTeam = CustomSquad._queryTLPB(player.id, 'team_name')
		local name = CustomSquad._queryTLPB(player.id, 'name_korean') or ''
		local localizedName = CustomSquad._queryTLPB(player.id, 'name_romanized') or player.name or ''
		local elo = CustomSquad._queryTLPB(player.id, 'elo')
		local eloPeak = CustomSquad._queryTLPB(player.id, 'peak_elo')

		row:id{
			id,
			race = faction,
			link = link,
			team = currentTeam,
			flag = player.flag,
			captain = player.captain,
			role = player.role,
		}
		row:name{name = name .. ' ' .. localizedName}

		if tlpb then
			row:elo{eloCurrent = elo, eloPeak = eloPeak}
		else
			row:role{role = player.role}
			row:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

			if squad.type == Squad.TYPE_FORMER then
				row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
				row:newteam{
					newteam = player.newteam,
					newteamrole = player.newteamrole,
					newteamdate = player.newteamdate,
					leavedate = player.leavedate
				}
			elseif squad.type == Squad.TYPE_INACTIVE then
				row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
			end
		end

		squad:row(row:create(
			mw.title.getCurrentTitle().prefixedText
			.. '_' .. player.id .. '_' .. ReferenceCleaner.clean(player.joindate)
			.. (player.role and '_' .. player.role or '')
		))
	end)

	return squad:create()
end

function CustomSquad._queryTLPB(id, value)
	if not Logic.isNumeric(id) then
		return
	end

	return String.nilIfEmpty(mw.getCurrentFrame():callParserFunction{
		name = '#external_info:tlpd_player',
		args = {id, value}
	})
end

return CustomSquad
