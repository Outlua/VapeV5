local vape = shared.vape
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
<<<<<<< HEAD:games/131465939650733.lua
			return game:HttpGet('https://raw.githubusercontent.com/Outlua/VapeV5/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
=======
			return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
>>>>>>> 90c6aa9d081af9d42b76e428da60d778cd915ace:src/games/frontlines/131465939650733 - versus ffa.lua
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

vape.Place = 5938036553
if isfile('newvape/games/'..vape.Place..'.lua') then
	loadstring(readfile('newvape/games/'..vape.Place..'.lua'), 'frontlines')()
else
	if not shared.VapeDeveloper then
		local suc, res = pcall(function()
<<<<<<< HEAD:games/131465939650733.lua
			return game:HttpGet('https://raw.githubusercontent.com/Outlua/VapeV5/'..readfile('newvape/profiles/commit.txt')..'/games/'..vape.Place..'.lua', true)
=======
			return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/'..readfile('newvape/profiles/commit.txt')..'/games/'..vape.Place..'.lua', true)
>>>>>>> 90c6aa9d081af9d42b76e428da60d778cd915ace:src/games/frontlines/131465939650733 - versus ffa.lua
		end)
		if suc and res ~= '404: Not Found' then
			loadstring(downloadFile('newvape/games/'..vape.Place..'.lua'), 'frontlines')()
		end
	end
end
