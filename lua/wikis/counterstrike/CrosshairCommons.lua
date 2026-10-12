local CrosshairCommons = {}

CrosshairCommons.stylesExplanation = {
	[0] = "<code><abbr title='Global Offensive dynamic'>0</abbr></code>",
	[1] = "<code><abbr title='Global Offensive static'>1</abbr></code>",
	[2] = "<code><abbr title='Classic dynamic'>2</abbr></code>",
	[3] = "<code><abbr title='Classic fully dynamic'>3</abbr></code>",
	[4] = "<code><abbr title='Classic static'>4</abbr></code>",
	[5] = "<code><abbr title='Classic 1.6-style dynamic'>5</abbr></code>",
	[6] = "<code><abbr title='Classic semi-dynamic'>6</abbr></code>"
}

CrosshairCommons.colorsExplanation = {
	[0] = "Red",
	[1] = "Green",
	[2] = "Yellow",
	[3] = "Blue",
	[4] = "Light blue",
	[5] = "",
}

CrosshairCommons.crosshairColors = {
	[0] = "rgb(250,50,50)",
	[1] = "rgb(50,250,50)",
	[2] = "rgb(250,250,50)",
	[3] = "rgb(50,50,250)",
	[4] = "rgb(50,250,250)",
	[5] = "",
}

function CrosshairCommons.isBrightCrosshair(crosshairColor, red, green, blue)
	if crosshairColor == 3 then
		return false
	elseif crosshairColor < 5 then
		return true
	end
	-- if color is 5 look at rgb
	return math.sqrt(0.299 * (red * red) + 0.587 * (green * green) + 0.114 * (blue * blue)) > 127.5
end

return CrosshairCommons
