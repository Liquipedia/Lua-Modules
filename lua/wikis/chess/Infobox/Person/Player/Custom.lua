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
local Page = require('Module:Page')
local Ratings = require('Module:Ratings')
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

	-- Rating IDs.
	player.args.rating_id1 = player.args.rating_id or player.args.rating_id1 or player.args.fide
	player.args.rating_ids = {}
	for _, id, _ in Table.iter.pairsByPrefix(player.args, 'rating_id') do
		table.insert(player.args.rating_ids, id)
	end

	if Table.isNotEmpty(player.args.rating_ids) then
		-- Player ratings.
		player.args.rating_classical = Ratings.getRecent(player.args.rating_ids, 'Classical')
		player.args.rating_classical_peak = Ratings.getPeak(player.args.rating_ids, 'Classical')
		player.args.rating_rapid = Ratings.getRecent(player.args.rating_ids, 'Rapid')
		player.args.rating_rapid_peak = Ratings.getPeak(player.args.rating_ids, 'Rapid')
		player.args.rating_blitz = Ratings.getRecent(player.args.rating_ids, 'Blitz')
		player.args.rating_blitz_peak = Ratings.getPeak(player.args.rating_ids, 'Blitz')
	end

	if Logic.isNotEmpty(player.args.image) and Logic.isEmpty(player.args.caption) then
		table.insert(player.warnings, 'Player photo is missing caption!')
	end

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

		-- Player ratings.
		local hasRating = args.rating_classical or args.rating_classical_peak or args.rating_rapid or
			args.rating_rapid_peak or args.rating_blitz or args.rating_blitz_peak
		if hasRating then
			Array.appendWith(widgets,
				Title{children = 'Ratings'},
				Cell{name = 'Classical', content = {Ratings.format(args.rating_classical)}},
				Cell{name = 'Classical (Peak)', content = {Ratings.format(args.rating_classical_peak)}},
				Cell{name = 'Rapid', content = {Ratings.format(args.rating_rapid)}},
				Cell{name = 'Rapid (Peak)', content = {Ratings.format(args.rating_rapid_peak)}},
				Cell{name = 'Blitz', content = {Ratings.format(args.rating_blitz)}},
				Cell{name = 'Blitz (Peak)', content = {Ratings.format(args.rating_blitz_peak)}}
			)
		end
	elseif id == 'region' then
		return {}
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.extradata.rating_ids = args.rating_ids

	-- Player ratings.
	lpdbData.extradata.rating_classical = args.rating_classical
	lpdbData.extradata.rating_rapid = args.rating_rapid
	lpdbData.extradata.rating_blitz = args.rating_blitz

	return lpdbData
end

---@param args table
function CustomPlayer:defineCustomPageVariables(args)
	Variables.varDefine('player_title', args.title and args.title.name or 'Player')
	Variables.varDefine('rating_ids', Json.stringify(args.rating_ids))
end

return CustomPlayer
