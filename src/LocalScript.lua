local character = script.Parent

local humanoid = character:FindFirstChildOfClass("Humanoid")
if humanoid then
	humanoid:Destroy()
end

local animateScript = character:FindFirstChild("Animate")
if animateScript then
	animateScript:Destroy()
end

for _, part in ipairs(character:GetDescendants()) do
	if part:IsA("BasePart") then
		part.Transparency = 1
		part.CanCollide = false
	end
end

if character.PrimaryPart then
	character.PrimaryPart.CFrame = CFrame.new(0, -1000, 0)
end
