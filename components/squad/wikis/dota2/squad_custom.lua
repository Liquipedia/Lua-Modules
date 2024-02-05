---
-- @Liquipedia
-- wiki=dota2
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

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')

local CustomSquad = {}

local LANG = mw.getContentLanguage()

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
		:node(makeHeader('Position'))
		:node(makeHeader('Join Date'))
	if self.type == Squad.SquadTypes.INACTIVE then
		headerRow:node(makeHeader('Inactive Date'))
			:node(makeHeader('Active Team'))
	end
	if self.type == Squad.SquadTypes.FORMER_INACTIVE then
		headerRow:node(makeHeader('Inactive Date'))
			:node(makeHeader('Last Active Team'))
	end
	if self.type == Squad.SquadTypes.FORMER or self.type == Squad.SquadTypes.FORMER_INACTIVE then
		headerRow:node(makeHeader('Leave Date'))
			:node(makeHeader('New Team'))
	end

	self.content:node(headerRow)

	return self
end

---@class Dota2SquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@param args table
---@return self
function ExtendedSquadRow:position(args)
	local cell = mw.html.create('td')
	cell:addClass('Position')

	if String.isNotEmpty(args.position) or String.isNotEmpty(args.role) then
		cell:node(mw.html.create('div'):addClass('MobileStuff'):wikitext('Position:&nbsp;'))

		if String.isNotEmpty(args.position) then
			cell:wikitext(args.position)
			if String.isNotEmpty(args.role) then
				cell:wikitext('&nbsp;(' .. args.role .. ')')
			end
		elseif String.isNotEmpty(args.role) then
			cell:wikitext(args.role)
		end
	end

	self.content:node(cell)

	self.lpdbData.position = args.position
	self.lpdbData.role = args.role or self.lpdbData.role

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
		local row = ExtendedSquadRow()
		row:status(squad.type)
		row:id{
			player.id,
			flag = player.flag,
			link = player.link,
			captain = player.captain,
			role = player.role,
			team = player.team,
			teamrole = player.teamrole,
			date = player.leavedate or player.inactivedate or player.leavedate,
		}
			:name{name = player.name}
			:position{position = player.position, role = player.role and LANG:ucfirst(player.role) or nil}
			:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

		if squad.type == Squad.SquadTypes.INACTIVE or squad.type == Squad.SquadTypes.FORMER_INACTIVE then
			row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
			row:newteam{
				newteam = player.activeteam,
				newteamrole = player.activeteamrole,
				newteamdate = player.inactivedate
			}
		end
		if squad.type == Squad.SquadTypes.FORMER or squad.type == Squad.SquadTypes.FORMER_INACTIVE then
			row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
			row:newteam{
				newteam = player.newteam,
				newteamrole = player.newteamrole,
				newteamdate = player.newteamdate,
				leavedate = player.leavedate
			}
		end

		local link = mw.ext.TeamLiquidIntegration.resolve_redirect(player.link or player.id)
		squad:row(row:create(
			mw.title.getCurrentTitle().prefixedText
			.. '_' .. link .. '_'
			.. ReferenceCleaner.clean(player.joindate)
			.. (player.role and '_' .. player.role or '')
			.. '_' .. squad.type
		))
	end)

	return squad:create()
end

return CustomSquad
