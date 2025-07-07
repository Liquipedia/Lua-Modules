---
-- @Liquipedia
-- page=Module:Infobox/Expansion
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Namespace = Lua.import('Module:Namespace')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local BasicInfobox = Lua.import('Module:Infobox/Basic')
local Links = Lua.import('Module:Links')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder
local Chronology = Widgets.Chronology

---@class ExpansionInfobox: BasicInfobox
local Expansion = Class.new(BasicInfobox)

---@return string
function Expansion:createInfobox()
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
		Title{children = 'Information'},
		Customizable{
			id = 'basegame',
			children = {
				Cell{name = 'Base game', children = {args.game}},
			},
		},
		Customizable{
			id = 'type',
			children = {
				Cell{name = 'Type', children = {args.informationType or 'Expansion'}},
			},
		},
		Customizable{
			id = 'version',
			children = {
				Cell{name = 'Version', children = {args.version}},
			},
		},
		Customizable{
			id = 'developer',
			children = {
				Builder{
					builder = function()
						local developers = self:getAllArgsForBase(args, 'developer')
						return {
							Cell{
								name = #developers > 1 and 'Developers' or 'Developer',
								children = developers,
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
								children = publishers,
							}
						}
					end
				}
			}
		},
		Customizable{
			id = 'platform',
			children = {
				Cell{name = 'Platforms published', children = self:getAllArgsForBase(args, 'platform')},
			}
		},
		Builder{
			builder = function()
				local releaseDates = self:getAllArgsForBase(args, 'releasedate')
				return {
					Cell{
						name = #releaseDates > 1 and 'Release Dates' or 'Release Date',
						children = releaseDates,
					}
				}
			end
		},
		Builder{
			builder = function()
				local completionDates = self:getAllArgsForBase(args, 'completiondate')
				return {
					Cell{
						name = #completionDates > 1 and 'Completion Dates' or 'Completion Date',
						children = completionDates,
					}
				}
			end
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
		Customizable{id = 'chronology', children = {
				Chronology{
					title = self:chronologyTitle(),
					links = Table.filterByKey(args, function(key)
						return type(key) == 'string' and (key:match('^previous%d?$') ~= nil or key:match('^next%d?$') ~= nil)
					end)
				}
			}
		},
	}

	if Namespace.isMain() then
		self:categories((args.informationType or 'Expansion') .. 's')
		self:setLpdbData(args)
	end

	return self:build(widgets)
end

--- Allows for overriding this functionality
---@param args table
function Expansion:setLpdbData(args)
end

---@return string
function Expansion:chronologyTitle()
	return 'Chronology'
end

return Expansion
