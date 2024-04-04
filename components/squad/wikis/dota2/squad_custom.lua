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
local Widget = require('Module:Infobox/Widget/All')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')

local CustomSquad = {}
local ExtendedSquad = Class.new(Squad)

local LANG = mw.getContentLanguage()

---@return self
function ExtendedSquad:header()
	local isInactive = self.type == Squad.SquadType.INACTIVE or self.type == Squad.SquadType.FORMER_INACTIVE
	local isFormer = self.type == Squad.SquadType.FORMER or self.type == Squad.SquadType.FORMER_INACTIVE
	local cellArgs = {classes = {'divCell'}}
	table.insert(self.rows, Widget.TableRow{
		classes = {'HeaderRow'},
		css = {['font-weight'] = 'bold'},
		cells = {
			Widget.TableCell(cellArgs):addContent('ID'),
			Widget.TableCell(cellArgs), -- "Team Icon" (most commmonly used for loans)
			Widget.TableCell(cellArgs):addContent('Name'),
			Widget.TableCell(cellArgs):addContent('Position'),
			Widget.TableCell(cellArgs):addContent('Join Date'),
			isInactive and Widget.TableCell(cellArgs):addContent('Inactive Date') or nil,
			isInactive and Widget.TableCell(cellArgs):addContent('Active Team') or nil,
			isFormer and Widget.TableCell(cellArgs):addContent('Leave Date') or nil,
			isFormer and Widget.TableCell(cellArgs):addContent('New Team') or nil,
		}
	})

	return self
end

---@class Dota2SquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@param args table
---@return self
function ExtendedSquadRow:position(args)
	local cell = Widget.TableCell{}
	cell:addClass('Position')

	if String.isNotEmpty(args.position) or String.isNotEmpty(args.role) then
		cell:addContent(mw.html.create('div'):addClass('MobileStuff'):wikitext('Position:&nbsp;'))

		if String.isNotEmpty(args.position) then
			cell:addContent(args.position)
			if String.isNotEmpty(args.role) then
				cell:addContent('&nbsp;(' .. args.role .. ')')
			end
		elseif String.isNotEmpty(args.role) then
			cell:addContent(args.role)
		end
	end

	self.content:addCell(cell)

	self.lpdbData.position = args.position
	self.lpdbData.role = args.role or self.lpdbData.role

	return self
end

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local squad = ExtendedSquad()

	squad:init(frame):title()

	local args = squad.args

	local players = Array.mapIndexes(function(index)
		return Json.parseIfString(args[index])
	end)

	---@param player table
	---@return boolean
	local hasInactive = function(player)
		return Logic.isNotEmpty(player.inactivedate)
	end

	if squad.type == Squad.SquadType.FORMER and Array.any(players, hasInactive) then
		squad.type = Squad.SquadType.FORMER_INACTIVE
	end

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

		if squad.type == Squad.SquadType.INACTIVE or squad.type == Squad.SquadType.FORMER_INACTIVE then
			row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
			row:newteam{
				newteam = player.activeteam,
				newteamrole = player.activeteamrole,
				newteamdate = player.inactivedate
			}
		end
		if squad.type == Squad.SquadType.FORMER or squad.type == Squad.SquadType.FORMER_INACTIVE then
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
