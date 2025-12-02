local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateScore = RemoteEvents:WaitForChild("UpdateScore")
local GameOverEvent = RemoteEvents:WaitForChild("GameOver")
local UpdateUI = RemoteEvents:WaitForChild("UpdateUI")
local LocalScoreUpdate = ReplicatedStorage:WaitForChild("LocalScoreUpdate") 

local scoreLabel = script.Parent.SideButtonsFrame:WaitForChild("ScoreLabel")
local pauseButton = script.Parent.SideButtonsFrame:WaitForChild("PauseButton")
local restartButton = script.Parent.SideButtonsFrame:WaitForChild("RestartButton")
local startButton = script.Parent.SideButtonsFrame:WaitForChild("StartButton")
-- Game Over
local finishBackground = script.Parent:WaitForChild("FinishBackground")
local finishrestartButton = script.Parent.FinishBackground:WaitForChild("FinishRestartButton")
local finishScoreLabel = script.Parent.FinishBackground:WaitForChild("FinishScoreLabel")
-- Leaderboard
local GetLeaderboard = RemoteEvents:WaitForChild("GetLeaderboard")
local leaderboardButton = script.Parent.FinishBackground:WaitForChild("LeaderboardButton")
local leaderboardFrame = script.Parent:WaitForChild("LeaderboardFrame")
local leaderboardList = leaderboardFrame:WaitForChild("LeaderboardList")
local template = leaderboardList:WaitForChild("LeaderboardItemTemplate")
local closeButton = leaderboardFrame:WaitForChild("CloseButton")
local hint = script.Parent.SideButtonsFrame:FindFirstChild("HintLabel")

-- Начальные значения
scoreLabel.Text = "Score: 0"
finishBackground.Visible = false
finishrestartButton.Visible = false
restartButton.Visible = false
startButton.Visible = false

local paused = false

-- ===========================
-- Анимация кнопок
-- ===========================
local TweenService = game:GetService("TweenService")

local function animateRoundButton(btn)
	local defaultSize = btn.Size
	local defaultStrokeColor = btn.UIStroke and btn.UIStroke.Color or Color3.new(1, 1, 1)
	local defaultBG = btn.BackgroundColor3

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = defaultSize + UDim2.new(0.015, 0, 0.015, 0), 
			BackgroundColor3 = defaultBG:lerp(Color3.new(1, 1, 1), 0.22), 
		}):Play()
		if btn.UIStroke then
			TweenService:Create(btn.UIStroke, TweenInfo.new(0.16), {Color = Color3.new(1,1,1)}):Play() 
		end
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = defaultSize,
			BackgroundColor3 = defaultBG,
		}):Play()
		if btn.UIStroke then
			TweenService:Create(btn.UIStroke, TweenInfo.new(0.14), {Color = defaultStrokeColor}):Play()
		end
	end)
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.10, Enum.EasingStyle.Quad), {
			Size = defaultSize + UDim2.new(0.05, 0, 0.05, 0), 
		}):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.10, Enum.EasingStyle.Quad), {
			Size = defaultSize + UDim2.new(0.03, 0, 0.03, 0), 
		}):Play()
	end)
end

animateRoundButton(pauseButton)
animateRoundButton(restartButton)
animateRoundButton(startButton)
animateRoundButton(finishrestartButton)
animateRoundButton(leaderboardButton)

-- ===========================
-- Подсказка (HintLabel)
-- ===========================
if hint then
	hint.Visible = true
	hint.BackgroundTransparency = 1
	hint.TextTransparency = 1
	hint.TextStrokeTransparency = 1

	spawn(function()
		local t = 0
		local duration = 0.7
		while t < duration do
			t = t + RunService.RenderStepped:Wait()
			local alpha = t / duration
			hint.BackgroundTransparency = 1 - (1 - 0.15) * alpha
			hint.TextTransparency = 1 - alpha
			hint.TextStrokeTransparency = 1 - (1 - 0.4) * alpha
		end
		hint.BackgroundTransparency = 0.15
		hint.TextTransparency = 0
		hint.TextStrokeTransparency = 0.4
	end)

	local fading = false
	local function fadeOutHint()
		if fading or not hint.Visible then return end
		fading = true
		local t = 0
		local duration = 0.7
		local startBG = hint.BackgroundTransparency
		local startText = hint.TextTransparency
		local startStroke = hint.TextStrokeTransparency
		while t < duration do
			t = t + RunService.RenderStepped:Wait()
			local alpha = t / duration
			hint.BackgroundTransparency = startBG + (1 - startBG) * alpha
			hint.TextTransparency = startText + (1 - startText) * alpha
			hint.TextStrokeTransparency = startStroke + (1 - startStroke) * alpha
		end
		hint.Visible = false
	end

	local hintWasHidden = false
	local function safeFadeOut()
		if not hintWasHidden then
			hintWasHidden = true
			fadeOutHint()
		end
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed then
			safeFadeOut()
		end
	end)

	task.delay(4, safeFadeOut)
end


-- ===========================
-- События UI
-- ===========================
UpdateScore.OnClientEvent:Connect(function(score)
	finishScoreLabel.Text = "Score: " .. tostring(score)
end)

GameOverEvent.OnClientEvent:Connect(function(score)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://1846269541"
	sound.Volume = 1
	sound.Parent = workspace
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	finishBackground.Visible = true
	finishScoreLabel.Text = "Final Score: " .. tostring(score)
	finishrestartButton.Visible = true
	leaderboardButton.Visible = true
	scoreLabel.Visible = false
	restartButton.Visible = false
	pauseButton.Visible = false
	startButton.Visible = false
	paused = false
end)

UpdateUI.OnClientEvent:Connect(function(status)
	if status == "Pause" then
		paused = true
		scoreLabel.Visible = true
		restartButton.Visible = true
		startButton.Visible = true
		pauseButton.Visible = false
		finishBackground.Visible = false
	elseif status == "Resume" then
		paused = false
		scoreLabel.Visible = true
		finishBackground.Visible = false
		restartButton.Visible = false
		startButton.Visible = false
		pauseButton.Visible = true
	elseif status == "Restart" then
		finishBackground.Visible = false
		scoreLabel.Visible = true
		scoreLabel.Text = "Score: 0"
		restartButton.Visible = false
		startButton.Visible = false
		pauseButton.Visible = true
		paused = false
	end
end)

-- Leaderboard
local function updateLeaderboard()
	for _, child in ipairs(leaderboardList:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "LeaderboardItemTemplate" then
			child:Destroy()
		end
	end
	local top = GetLeaderboard:InvokeServer()
	for i, info in ipairs(top) do
		local item = template:Clone()
		item.Name = "Player_" .. tostring(i)
		item.PlayerName.Text = tostring(i)..". "..info.Name
		item.Score.Text = tostring(info.Score)
		item.Visible = true
		item.Parent = leaderboardList
	end
end

leaderboardButton.MouseButton1Click:Connect(function()
	leaderboardFrame.Visible = true
	updateLeaderboard()
end)
closeButton.MouseButton1Click:Connect(function()
	leaderboardFrame.Visible = false
end)

LocalScoreUpdate.Event:Connect(function(score)
	scoreLabel.Text = "Score: " .. tostring(score)
end)

pauseButton.MouseButton1Click:Connect(function()
	if not paused then
		UpdateUI:FireServer("Pause")
	else
		UpdateUI:FireServer("Resume")
	end
end)
startButton.MouseButton1Click:Connect(function()
	if paused then
		UpdateUI:FireServer("Resume")
	else
		UpdateUI:FireServer("Pause")
	end
end)
restartButton.MouseButton1Click:Connect(function()
	UpdateUI:FireServer("Restart")
end)
finishrestartButton.MouseButton1Click:Connect(function()
	UpdateUI:FireServer("Restart")
end)
