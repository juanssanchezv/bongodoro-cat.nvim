local M = {}

local function clone(frame)
	return vim.deepcopy(frame)
end

local function replace_at(line, col, text)
	return vim.fn.strcharpart(line, 0, col - 1) .. text .. vim.fn.strcharpart(line, col - 1 + vim.fn.strchars(text))
end

local function overlay(frame, line, col, text)
	frame[line] = replace_at(frame[line], col, text)
end

local left_small = {
	[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
	[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
	[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣴⠿⠁⠈⢻⣧⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
	[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣶⠟⠋⠁⠀⠀⠀⠀⠀⠀⠉⠙⠻⠷⣶⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
	[[⠀⠀⠀⠀⠀⠀⢀⣴⠿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠻⣶⣤⣤⡶⢿⣷⠀⠀]],
	[[⠀⠀⠀⠀⢀⣴⠟⠁⠀⠀⠀⠀⣴⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⠀⢸⡟⠀⠀]],
	[[⠀⠀⠀⣰⡟⠁⠀⠀⠀⠀⠀⠀⠉⠉⠘⠷⢾⣧⣤⠀⠀⠀⢀⠀⣠⣶⠶⣦⣄⠀⠀⠀⣿⠁⠀⠀]],
	[[⠀⠀⢸⡏⠀⠀⠀⠀⢀⣀⣤⣤⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠿⢧⣿⠀⠀⠈⠻⡆⠀⠸⣿⡀⠀⠀]],
	[[⠰⢿⣛⠿⠶⠶⠶⠟⠛⠉⠁⠉⠉⠙⠛⠻⠶⢶⣤⣤⣀⣀⡀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠘⣷⡀⠀]],
	[[⠀⠛⠋⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠛⠛⠿⠶⣶⣤⣤⣀⣀⠀⠀⠸⣷⠀]],
	[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠙⠛⠻⠷⠿⠆]],
	[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
}

local right_small = {
	[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
	[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
	[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣴⠿⠁⠈⢻⣧⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
	[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣶⠟⠋⠁⠀⠀⠀⠀⠀⠀⠉⠙⠻⠷⣶⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
	[[⠀⠀⠀⣴⡿⠛⠻⣷⡿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠻⣶⣤⣤⡶⢿⣷⠀⠀]],
	[[⠀⠀⠀⣿⠀⠀⠀⠈⠛⠀⠀⠀⣴⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⠀⢸⡟⠀⠀]],
	[[⠀⠀⠀⣿⣀⡀⠀⠀⠀⠀⠀⠀⠉⠉⠘⠷⢾⣧⣤⠀⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠁⠀⠀]],
	[[⠀⠀⠀⠉⠉⠛⠻⠷⠶⣦⣤⣤⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠿⠇⠀⠀⠀⠀⠀⠀⠀⠸⣿⡀⠀⠀]],
	[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠙⠛⠻⠶⢶⣤⣤⣀⣀⣠⣤⠀⠀⠀⠀⠀⠀⠀⠀⠘⣷⡀⠀]],
	[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⢹⡟⠁⠀⠀⠀⢀⣀⣠⣄⡀⠀⠸⣷⠀]],
	[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣤⡌⠻⠶⠶⠶⠟⠛⠉⠉⠙⠛⠻⠷⠿⠆]],
	[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠿⠄⠀⠸⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
}

M.left = clone(left_small)
M.right = clone(right_small)

M.idle = M.right
M.left_hit = M.left
M.right_hit = M.right
M.both_hit = M.left
M.left_recover = M.left
M.right_recover = M.right
M.both_recover = M.right

M.sleep_a = clone(M.left)
overlay(M.sleep_a, 2, 32, "z")
overlay(M.sleep_a, 3, 30, "Zz")
overlay(M.sleep_a, 6, 13, "⣤")
overlay(M.sleep_a, 6, 14, "⣀")
overlay(M.sleep_a, 7, 13, " ")
overlay(M.sleep_a, 7, 23, " ")
overlay(M.sleep_a, 8, 23, "⠶")
overlay(M.sleep_a, 8, 24, "⢦")

M.sleep_b = clone(M.right)
overlay(M.sleep_b, 2, 30, "Z")
overlay(M.sleep_b, 3, 32, "zZ")
overlay(M.sleep_b, 6, 13, "⣤")
overlay(M.sleep_b, 6, 14, "⣀")
overlay(M.sleep_b, 7, 13, " ")
overlay(M.sleep_b, 7, 23, " ")
overlay(M.sleep_b, 8, 23, "⠶")
overlay(M.sleep_b, 8, 24, "⣦")

M.sleep = M.sleep_a
M.save = clone(M.right)
overlay(M.save, 1, 31, "⣿⣿⠛⣿⣿⣦")
overlay(M.save, 2, 31, "⣿⣿⠛⠛⣿⣿")
overlay(M.save, 3, 31, "⣿⣿⣤⣤⣿⣿")
M.error = clone(M.right)
overlay(M.error, 1, 29, " ⣤⣀⢀⣾⢇⣶⠀")
overlay(M.error, 2, 29, "⠺⢾⣽⠛⠋⣾⡋⠀")
overlay(M.error, 3, 29, " ⢠⣿⢣⣶⣭⣛⠷")
overlay(M.error, 4, 29, " ⠛⢡⡿⠁⠈⠙⠁")

M.order = {
	"left",
	"right",
	"idle",
	"left_hit",
	"left_recover",
	"right_hit",
	"right_recover",
	"both_hit",
	"both_recover",
	"sleep_a",
	"sleep_b",
	"sleep",
	"save",
	"error",
}

function M.get(name)
	return M[name] or M.idle
end

function M.dimensions()
	local width = 0
	local height = 0

	for _, name in ipairs(M.order) do
		local frame = M[name]
		if frame then
			height = math.max(height, #frame)

			for _, line in ipairs(frame) do
				width = math.max(width, vim.fn.strdisplaywidth(line))
			end
		end
	end

	return width, height
end

return M
