warn("RUNNING SCRIPT LOADER.LUA")
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local function resolveRepoPath(path)
    if path:find('^newvape/games/') then
        return path:gsub('^newvape/games/', 'src/games/')
    end

    if path:find('^newvape/guis/') then
        return path:gsub('^newvape/guis/', 'src/guis/')
    end

    if path:find('^newvape/libraries/') then
        return path:gsub('^newvape/libraries/', 'src/libraries/')
    end

    return path:gsub('^newvape/', 'src/')
end


local function downloadFile(path, func)
    if not isfile(path) then
        local suc, res = pcall(function()
            return game:HttpGet(
                'https://raw.githubusercontent.com/Outlua/VapeV5/' ..
                readfile('newvape/profiles/commit.txt') ..
                '/' ..
                resolveRepoPath(path),
                true
            )
        end)

        if not suc or res == '404: Not Found' then
            error(res)
        end

        if path:find('.lua') then
            res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n' .. res
        end

        writefile(path, res)
    end

    return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

if not shared.VapeDeveloper then
	local _, subbed = pcall(function() 
		return game:HttpGet('https://github.com/Outlua/VapeV5') 
	end)
	local commit = subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'
	if commit == 'main' or (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit then
		wipeFolder('newvape')
		wipeFolder('newvape/games')
		wipeFolder('newvape/guis')
		wipeFolder('newvape/libraries')
	end
	writefile('newvape/profiles/commit.txt', commit)
end

return loadstring(downloadFile('src/main.lua'), 'main')()
