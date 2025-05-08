---
-- @Liquipedia
-- wiki=chess
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class ChessInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

local TITLES = {
	{code = "gm", name = "Grandmaster"},
	{code = "im", name = "International Master"},
	{code = "wgm", name = "Woman Grandmaster"},
	{code = "fm", name = "FIDE Master"},
	{code = "wim", name = "Woman International Master"},
	{code = "cm", name = "Candidate Master"},
	{code = "wfm", name = "Woman FIDE Master"},
	{code = "wcm", name = "Woman Candidate Master"},
}

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.id = player.args.id or player.args.romanized_name or player.args.name

	player.args.autoTeam = true
	player.args.history = TeamHistoryAuto.results{
		convertrole = true,
		addlpdbdata = true
	}

	-- Title.
	player.args.title = Array.find(
		TITLES,
		function (title, _)
			return Logic.isNotEmpty(player.args['title_' .. title.code])
		end
	)

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		-- Titles.
		local hasTitle = Logic.isNotEmpty(args.title)
		if hasTitle then
			Array.extendWith(widgets,
				{Title{children = 'Titles'}},
				Array.map(
					TITLES,
					function (title)
						return Cell{name = title.name, content = {args['title_' .. title.code]}}
					end
				)
			)
		end

	elseif id == 'region' then
		return {}
	end

	return widgets
end

---@param args table
function CustomPlayer:defineCustomPageVariables(args)
	Variables.varDefine('player_title', args.title and args.title.name or 'Player')
end

return CustomPlayer
