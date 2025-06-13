---
-- @Liquipedia
-- page=Module:Infobox/Game
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')
local Json = require('Module:Json')

local BasicInfobox = Lua.import('Module:Infobox/Basic')
local Links = Lua.import('Module:Links')

local Widgets = require('Module:Widget/All')
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

---@return string
function Game:createInfobox()
	local args = self.args
	local links = Links.transform(args)

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = 'Game Information'},
		Customizable{
			id = 'developer',
			children = {
				Builder{
					builder = function()
						local developers = self:getAllArgsForBase(args, 'developer')
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
						local publishers = self:getAllArgsForBase(args, 'publisher')
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
						local platforms = self:getAllArgsForBase(args, 'platform')
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
						Title{children = 'Links'},
						Widgets.Links{links = links}
					}
				end
			end
		},
		Center{children = {args.footnotes}},
	}

	if Namespace.isMain() then
		self:categories('Games')
		self:_setLpdbData(args)
	end

	return self:build(widgets)
end

---@param args table
function Game:_setLpdbData(args)
	local lpdbData = {
		name = args.romanized_name or self.name,
		image = args.image,
		imagedark = args.imagedark,
		date = args.releasedate,
		type = 'game',
	}

	local extradata = {}
	local addToExtradata = function(prefix)
		local data = Table.map(self:getAllArgsForBase(args, prefix),
			function(idx, value) return prefix .. idx, value end
		)
		extradata = Table.merge(extradata, data)
	end

	addToExtradata('publisher')
	addToExtradata('platform')
	addToExtradata('developer')

	lpdbData.extradata = extradata

	lpdbData = self:addToLpdb(lpdbData, args)

	mw.ext.LiquipediaDB.lpdb_datapoint('game_' .. self.name, Json.stringifySubTables(lpdbData))
end

--- Allows for overriding this functionality
---@param lpdbData table
---@param args table
---@return table
function Game:addToLpdb(lpdbData, args)
	return lpdbData
end

return Game
