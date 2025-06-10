---
-- @Liquipedia
-- page=Module:Gallery
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Image = require('Module:Image')
local Json = require('Module:Json')
local Logic = require('Module:Logic')

local DEFAULT_HEIGHT = 200

local Gallery = {}

function Gallery.template(frame)
	return Gallery.run(Arguments.getArgs(frame))
end

---@param args table?
---@return Html?
function Gallery.run(args)
	args = args or {}

	local height = tonumber((string.gsub(args.height or '', 'px$', ''))) or DEFAULT_HEIGHT

	---@param index integer
	---@return {imageLightMode: string, imageDarkMode: string?, caption: string, below: string|Html?, link: string?}?
	local processImageInput = function(index)
		local rawInput = args[index]
		local input = type(rawInput) == 'table' and rawInput or Json.parseIfTable(args[index])
		if Logic.isEmpty(input) then return end
		---@cast input -nil

		local imageLightMode = input.lightmode or input[1]
		if Logic.isEmpty(imageLightMode) then return end

		return {
			imageLightMode = imageLightMode,
			imageDarkMode = input.darkmode,
			caption = input.caption,
			link = input.link,
			below = input.below,
		}
	end

	local images = Array.mapIndexes(processImageInput)

	if Logic.isEmpty(images) then return end

	local gallery = mw.html.create('ul')
		:addClass('gallery mw-gallery-packed')

	Array.forEach(images, function(imageData)
		gallery:node(Gallery._makeImage(imageData, height))
	end)

	return gallery
end

---@param input {imageLightMode: string, imageDarkMode: string?, caption: string, below: string|Html?, link: string?}
---@param height number
---@return Html
function Gallery._makeImage(input, height)
	local imageLightMode = input.imageLightMode
	local imageDarkMode = input.imageDarkMode

	local width = Gallery._calculateWidth(imageLightMode, height)

	local image = Image.display(imageLightMode, imageDarkMode, {
		link = input.link,
		alt = input.caption,
		caption = input.caption,
		size = width,
	})

	local thumb = mw.html.create('div')
		:addClass('thumb')
		:css('width', width .. 'px')
		:tag('div')
			:css('margin', '0px auto')
			:node(image)
			:done()

	local text = (input.below or input.caption) and
		mw.html.create('div'):addClass('gallerytext'):node(input.below or input.caption)
		or nil

	local extendedWidth = width + 4

	return mw.html.create('li')
		:addClass('gallerybox')
		:css('vertical-align', 'top')
		:css('display', 'inline-block')
		:css('width', extendedWidth .. 'px')
		:tag('div')
			:css('width', extendedWidth .. 'px')
			:node(thumb)
			:node(text)
		:done()
end

---@param imageLightMode string
---@param height number
---@return number
function Gallery._calculateWidth(imageLightMode, height)
	local title = mw.title.new('File:' .. imageLightMode)
	assert(title, '"File:' .. imageLightMode .. '" does not exist')
	local fileInfo = title.file
	local fileWidth = tonumber(fileInfo.width)
	local fileHeight = tonumber(fileInfo.height)
	return math.ceil(height * fileWidth / fileHeight)
end

return Gallery
