local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateScore = RemoteEvents:WaitForChild("UpdateScore")
local GameOver = RemoteEvents:WaitForChild("GameOver")
local GetLeaderboard = RemoteEvents:WaitForChild("GetLeaderboard") 
local DataStoreService = game:GetService("DataStoreService")
local highscoreStore = DataStoreService:GetDataStore("TetrisHighscore")
local Players = game:GetService("Players")

local LEADERBOARD_KEY = "Leaderboard"

UpdateScore.OnServerEvent:Connect(function(player, score)
	local id = tostring(player.UserId)
	pcall(function()
		local oldScore = highscoreStore:GetAsync(id) or 0
		if typeof(score) ~= "number" then return end
		if score > oldScore then
			highscoreStore:SetAsync(id, score)
		end

		local leaderboard = highscoreStore:GetAsync(LEADERBOARD_KEY)
		if type(leaderboard) ~= "table" then leaderboard = {} end

		local found = false
		for _, entry in ipairs(leaderboard) do
			if tonumber(entry.UserId) == player.UserId then
				if score > (tonumber(entry.Score) or 0) then
					entry.Score = score
				end
				found = true
				break
			end
		end
		if not found then
			table.insert(leaderboard, {UserId = player.UserId, Score = score})
		end

		table.sort(leaderboard, function(a, b)
			return (tonumber(a.Score) or 0) > (tonumber(b.Score) or 0)
		end)
		while #leaderboard > 10 do
			table.remove(leaderboard)
		end

		highscoreStore:SetAsync(LEADERBOARD_KEY, leaderboard)
	end)
end)

GameOver.OnServerEvent:Connect(function(player, score)
	GameOver:FireClient(player, score)
end)

GetLeaderboard.OnServerInvoke = function(player)
	local leaderboard = {}
	local ok, data = pcall(function()
		return highscoreStore:GetAsync(LEADERBOARD_KEY)
	end)
	if ok and type(data) == "table" then
		leaderboard = data
	end

	local top = {}
	for i, entry in ipairs(leaderboard) do
		if entry.UserId and entry.Score then
			local userName = "Player" .. tostring(entry.UserId)
			pcall(function()
				userName = Players:GetNameFromUserIdAsync(entry.UserId)
			end)
			table.insert(top, {Name = userName, Score = entry.Score})
		end
	end
	return top
end
