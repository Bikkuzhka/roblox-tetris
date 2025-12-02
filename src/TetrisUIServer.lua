local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateUI = RemoteEvents:WaitForChild("UpdateUI")

UpdateUI.OnServerEvent:Connect(function(player, status)
	UpdateUI:FireClient(player, status)
end)
