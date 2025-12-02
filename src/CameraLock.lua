local camera = workspace.CurrentCamera
local gameField = workspace:WaitForChild("GameField")
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 60

game:GetService("RunService").RenderStepped:Connect(function()
	local center = gameField.Position
	local heightOffset = 43  
	local camPos = center + Vector3.new(0, heightOffset, 80)  
	local lookAt = center + Vector3.new(0, heightOffset, 0)  
	camera.CFrame = CFrame.new(camPos, lookAt)
end)