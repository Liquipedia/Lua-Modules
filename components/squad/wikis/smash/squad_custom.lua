---
-- @Liquipedia
-- wiki=smash
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Characters = require('Module:Characters')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local SquadPlayerData = require('Module:SquadPlayer/data')
local Variables = require('Module:Variables')
local Widget = require('Module:Infobox/Widget/All')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')

local CustomSquad = {}
local ExtendedSquad = Class.new(Squad)

---@return self
function ExtendedSquad:header()
	local isInactive = self.type == Squad.SquadType.INACTIVE or self.type == Squad.SquadType.FORMER_INACTIVE
	local isFormer = self.type == Squad.SquadType.FORMER or self.type == Squad.SquadType.FORMER_INACTIVE
	local cellArgs = {classes = {'divCell'}}
	table.insert(self.rows, Widget.TableRow{
		classes = {'HeaderRow'},
		css = {['font-weight'] = 'bold'},
		cells = {
			Widget.TableCell(cellArgs):addContent('Player'),
			Widget.TableCell(cellArgs),
			Widget.TableCell(cellArgs):addContent('Main'),
			Widget.TableCell(cellArgs):addContent('Join Date'),
			isInactive and Widget.TableCell(cellArgs):addContent('Inactive Date') or nil,
			isFormer and Widget.TableCell(cellArgs):addContent('Leave Date') or nil,
			isFormer and Widget.TableCell(cellArgs):addContent('New Team') or nil,
		}
	})

	return self
end

---@class SmashSquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@param args table
---@return self
function ExtendedSquadRow:mains(args)
	local cell = Widget.TableCell{}
	cell:css('text-align', 'center')

	Array.forEach(args.mains, function(main)
		cell:addContent(Characters.GetIconAndName{main, game = args.game, large = true})
	end)
	self.content:addCell(cell)

	return self
end

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local squad = ExtendedSquad()
	squad:init(frame):title():header()

	local args = squad.args
	local tableGame = args.game

	local players = Array.mapIndexes(function(index)
		return Json.parseIfString(args[index])
	end)

	Array.forEach(players, function(player)
		local row = ExtendedSquadRow()

		local game = player.game and mw.text.split(player.game:lower(), ',')[1] or tableGame
		local mains = SquadPlayerData.get{link = player.link, player = player.id, game = game, returnType = 'lua'}
			or player.mains

		row:status(squad.type)
		row:id{
			player.id,
			flag = Variables.varDefault('nationality') or player.flag,
			link = player.link,
			team = player.activeteam,
			name = Variables.varDefault('name') or player.name,
			date = player.leavedate or player.inactivedate or player.leavedate,
		}
		row:mains{mains = mw.text.split(mains or '', ','), game = game}
		row:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

		if squad.type == Squad.SquadType.FORMER then
			row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
			row:newteam{
				newteam = player.newteam,
				newteamrole = player.newteamrole,
				newteamdate = player.newteamdate,
				leavedate = player.leavedate
			}
		elseif squad.type == Squad.SquadType.INACTIVE then
			row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
		end

		squad:row(row:create(
			mw.title.getCurrentTitle().prefixedText
			.. '_' .. player.id .. '_' .. ReferenceCleaner.clean(player.joindate)
			.. (player.role and '_' .. player.role or '')
			.. '_' .. squad.type
		))

		Variables.varDefine('nationality', '')
		Variables.varDefine('name', '')
	end)

	return squad:create()
end

return CustomSquad
