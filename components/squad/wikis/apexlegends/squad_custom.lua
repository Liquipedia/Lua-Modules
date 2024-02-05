---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local ReferenceCleaner = require('Module:ReferenceCleaner')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')

local CustomSquad = {}

---@param self Squad
---@return table
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
	if self.type == Squad.SquadTypes.INACTIVE or self.type == Squad.SquadTypes.FORMER_INACTIVE then
		headerRow:node(makeHeader('Inactive Date'))
	end
	if self.type == Squad.SquadTypes.FORMER or self.type == Squad.SquadTypes.FORMER_INACTIVE then
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

	local args = squad.args

	local players = Array.mapIndexes(function(index)
		return Json.parseIfString(args['p' .. index] or args[index])
	end)

	---@param player table
	---@return boolean
	local hasInactive = function(player)
		return Logic.isNotEmpty(player.inactivedate)
	end

	if squad.type == Squad.SquadTypes.FORMER and Array.any(players, hasInactive) then
		squad.type = Squad.SquadTypes.FORMER_INACTIVE
	end

	squad.header = CustomSquad.header
	squad:header()

	Array.forEach(players, function(player)
		local row = SquadRow{useTemplatesForSpecialTeams = true}
		row:status(squad.type)
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
			:name{name = player.name}
			:role({role = player.role})
			:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

		if squad.type == Squad.SquadTypes.INACTIVE or squad.type == Squad.SquadTypes.FORMER_INACTIVE then
			row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
		end
		if squad.type == Squad.SquadTypes.FORMER or squad.type == Squad.SquadTypes.FORMER_INACTIVE then
			row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
			row:newteam{
				newteam = player.newteam,
				newteamrole = player.newteamrole or player.newrole,
				newteamdate = player.newteamdate,
				leavedate = player.leavedate
			}
		end

		squad:row(row:create(
			mw.title.getCurrentTitle().prefixedText ..
			'_' .. player.id .. '_' ..
			ReferenceCleaner.clean(player.joindate)
			.. (player.role and '_' .. player.role or '')
			.. '_' .. squad.type
		))
	end)

	return squad:create()
end

return CustomSquad
