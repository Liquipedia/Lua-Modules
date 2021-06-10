std = {
	read_globals = {
		"mw",
		"require"
	}
}
exclude_files = {
	".install", -- package files
	".luarocks" -- package manager files
}

-- https://luacheck.readthedocs.io/en/stable/warnings.html#list-of-warnings
ignore = {
	"212" -- unused argument
}
