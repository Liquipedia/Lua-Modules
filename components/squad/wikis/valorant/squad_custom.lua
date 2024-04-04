---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Table = require('Module:Table')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param self Squad
---@return Squad
function CustomSquad.header(self)
	local makeHeader = function(wikiText)
		local headerCell = mw.html.create('th')

		if wikiText == nil then
			return headerCell
		end

		return headerCell:wikitext(wikiText):addClass('divCell')
	end

	local headerRow = mw.html.create('tr'):addClass('HeaderRow')

	headerRow:node(makeHeader('ID'))
		:node(makeHeader())
		:node(makeHeader('Name'))
		:node(makeHeader()) -- "Role"
		:node(makeHeader('Join Date'))
	if self.type == Squad.SquadType.INACTIVE or self.type == Squad.SquadType.FORMER_INACTIVE then
		headerRow:node(makeHeader('Inactive Date'))
	end
	if self.type == Squad.SquadType.FORMER or self.type == Squad.SquadType.FORMER_INACTIVE then
		headerRow:node(makeHeader('Leave Date'))
			:node(makeHeader('New Team'))
	end

	self.content:node(headerRow)

	return self
end

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local squad = Squad()

	squad:init(frame):title()

	local players = SquadUtils.parsePlayers(squad.args)

	if squad.type == Squad.SquadType.FORMER and SquadUtils.anyInactive(players) then
		squad.type = Squad.SquadType.FORMER_INACTIVE
	end

	squad.header = CustomSquad.header
	squad:header()

	Array.forEach(players, function(player)
		squad:row(CustomSquad._playerRow(player, squad.type))
	end)

	return squad:create()
end

---@param playerList table[]
---@param squadType integer
---@return Html?
function CustomSquad.runAuto(playerList, squadType)
	if Table.isEmpty(playerList) then
		return
	end

	local squad = Squad()
	squad:init(mw.getCurrentFrame())

	squad.type = squadType

	squad:title():header()

	Array.forEach(playerList, function(player)
		squad:row(CustomSquad._playerRow(SquadUtils.convertAutoParameters(player), squad.type))
	end)

	return squad:create()
end

---@param player table
---@param squadType integer
---@return Html
function CustomSquad._playerRow(player, squadType)
	local row = SquadRow{useTemplatesForSpecialTeams = true}

	row:status(squadType)
	row:id{
		player.id,
		flag = player.flag,
		link = player.link,
		captain = player.captain or player.igl,
		role = player.role,
		team = player.team,
		teamrole = player.teamrole,
		date = player.leavedate or player.inactivedate or player.leavedate,
	}
	row:name{name = player.name}
	row:role{role = player.role}
	row:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

	if squadType == Squad.SquadType.INACTIVE or squadType == Squad.SquadType.FORMER_INACTIVE then
		row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
	end

	if squadType == Squad.SquadType.FORMER or squadType == Squad.SquadType.FORMER_INACTIVE then
		row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
		row:newteam{
			newteam = player.newteam,
			newteamrole = player.newteamrole or player.newrole,
			newteamdate = player.newteamdate,
			leavedate = player.leavedate
		}
	end

	return row:create(
		mw.title.getCurrentTitle().prefixedText
		.. '_' .. player.id .. '_'
		.. ReferenceCleaner.clean(player.joindate)
		.. (player.role and '_' .. player.role or '')
		.. '_' .. squadType
	)
end

return CustomSquad
