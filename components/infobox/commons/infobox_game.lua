---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Game
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')

local BasicInfobox = Lua.import('Module:Infobox/Basic', {requireDevIfEnabled = true})
local Links = Lua.import('Module:Links', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder

---@class GameInfobox: BasicInfobox
local Game = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function Game.run(frame)
	local game = Game(frame)
	return game:createInfobox()
end

---@return Html
function Game:createInfobox()
	local infobox = self.infobox
	local args = self.args
	local links = Links.transform(args)

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{content = {args.caption}},
		Title{name = 'Game Information'},
		Customizable{
			id = 'developer',
			children = {
				Builder{
					builder = function()
						local developers = self:getAllArgsForBase(args, 'developer', {makeLink = true})
						return {
							Cell{
								name = #developers > 1 and 'Developers' or 'Developer',
								content = developers,
							}
						}
					end
				}
			}
		},
		Customizable{
			id = 'publisher',
			children = {
				Builder{
					builder = function()
						local publishers = self:getAllArgsForBase(args, 'publisher', {makeLink = true})
						return {
							Cell{
								name = #publishers > 1 and 'Publishers' or 'Publisher',
								content = publishers,
							}
						}
					end
				}
			}
		},
		Cell{name = 'Release Date(s)', content = self:getAllArgsForBase(args, 'releasedate')},
		Customizable{
			id = 'platform',
			children = {
				Builder{
					builder = function()
						local platforms = self:getAllArgsForBase(args, 'platform', {makeLink = true})
						return {
							Cell{
								name = #platforms > 1 and 'Platforms' or 'Platform',
								content = platforms,
							}
						}
					end
				}
			}
		},
		Customizable{id = 'custom', children = {}},
		Builder{
			builder = function()
				if not Table.isEmpty(links) then
					return {
						Title{name = 'Links'},
						Widgets.Links{content = links}
					}
				end
			end
		},
		Center{content = {args.footnotes}},
	}

	if Namespace.isMain then
		infobox:categories('Games')
		self:_setLpdbData(args, links)
	end

	return infobox:widgetInjector(self:createWidgetInjector()):build(widgets)
end

---@param args table
---@param links table
function Game:_setLpdbData(args, links)
	local lpdbData = {
		name = args.romanized_name or self.name,
		image = args.image,
		imagedark = args.imagedark,
		date = args.releasedate,
		type = 'game',
	}

	local extradata = {}
	local addToExtradata = function(prefix)
		args[prefix .. 1] = args[prefix .. 1] or Table.extract(args, prefix)
		extradata = Table.merge(extradata, Table.filterByKey(
			args, function(key) return string.match(key, '^' .. prefix .. '%d+$') end)
		)
	end

	addToExtradata('publisher')
	addToExtradata('platform')
	addToExtradata('developer')

	lpdbData.extradata = extradata

	lpdbData = self:addToLpdb(lpdbData, args)

	mw.ext.LiquipediaDB.lpdb_datapoint('game_' .. self.name, Table.merge(lpdbData, {
		extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.extradata),
	}))
end

--- Allows for overriding this functionality
---@param lpdbData table
---@param args table
---@return table
function Game:addToLpdb(lpdbData, args)
	return lpdbData
end

return Game
