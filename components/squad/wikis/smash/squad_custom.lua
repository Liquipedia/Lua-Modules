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
local ReferenceCleaner = require('Module:ReferenceCleaner')
local SquadPlayerData = require('Module:SquadPlayer/data')
local Variables = require('Module:Variables')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param self Squad
---@return Squad
function CustomSquad.header(self)
	local makeHeader = function(wikiText)
		return mw.html.create('th'):wikitext(wikiText):addClass('divCell')
	end

	local headerRow = mw.html.create('tr'):addClass('HeaderRow')

	headerRow:node(makeHeader('Player'))
		:node(makeHeader(''))
		:node(makeHeader('Main'))
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
---@class SmashSquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@param args table
---@return self
function ExtendedSquadRow:mains(args)
	local cell = mw.html.create('td')
	cell:css('text-align', 'center')

	Array.forEach(args.mains, function(main)
		cell:wikitext(Characters.GetIconAndName{main, game = args.game, large = true})
	end)
	self.content:node(cell)

	return self
end

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local squad = Squad()
	squad:init(frame):title()

	squad.mains = CustomSquad.mains
	squad.header = CustomSquad.header
	squad:header()

	local tableGame = squad.args.game

	local players = SquadUtils.parsePlayers(squad.args)

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
