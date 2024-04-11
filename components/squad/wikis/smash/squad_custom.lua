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
local Lua = require('Module:Lua')
local SquadPlayerData = require('Module:SquadPlayer/data')
local Variables = require('Module:Variables')
local Widget = require('Module:Infobox/Widget/All')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local Injector = Lua.import('Module:Infobox/Widget/Injector')

local CustomSquad = {}
local CustomInjector = Class.new(Injector)

function CustomInjector:parse(id, widgets)
	if id == 'header_role' then
		return {
			Widget.TableCellNew{content = {'Main'}, header = true}
		}
	elseif id == 'header_name' then
		return {}
	end

	return widgets
end

---@class SmashSquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@param args table
---@return self
function ExtendedSquadRow:mains(args)
	local characters = {}
	Array.forEach(args.mains, function(main)
		table.insert(characters, Characters.GetIconAndName{main, game = args.game, large = true})
	end)

	table.insert(self.children, Widget.TableCellNew{
		css = {['text-align'] = 'center'},
		content = characters,
	})

	return self
end

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local squad = Squad():init(frame, CustomInjector()):title():header()

	local tableGame = squad.args.game

	local players = SquadUtils.parsePlayers(squad.args)

	Array.forEach(players, function(player)
		local row = ExtendedSquadRow()

		local game = player.game and mw.text.split(player.game:lower(), ',')[1] or tableGame
		local mains = SquadPlayerData.get{link = player.link, player = player.id, game = game} or player.mains

		row:status(squad.type)
		row:id{
			player.id,
			flag = Variables.varDefault('nationality') or player.flag,
			link = player.link,
			team = player.activeteam,
			name = Variables.varDefault('name') or player.name,
			date = player.leavedate or player.inactivedate,
		}
		row:mains{mains = mw.text.split(mains or '', ','), game = game}
		row:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

		if squad.type == SquadUtils.SquadType.FORMER then
			row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
			row:newteam{
				newteam = player.newteam,
				newteamrole = player.newteamrole,
				newteamdate = player.newteamdate,
				leavedate = player.leavedate
			}
		elseif squad.type == SquadUtils.SquadType.INACTIVE then
			row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
		end

		squad:row(row:create())

		Variables.varDefine('nationality', '')
		Variables.varDefine('name', '')
	end)

	return squad:create()
end

return CustomSquad
