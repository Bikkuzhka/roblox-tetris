local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tetrominoes = ReplicatedStorage:WaitForChild("Tetrominoes")
local ActiveFolder = workspace:WaitForChild("ActiveTetromino")
local FixedBlocks = workspace:WaitForChild("FixedBlocks")
local GameField = workspace:WaitForChild("GameField")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateScore = RemoteEvents:WaitForChild("UpdateScore")
local GameOverEvent = RemoteEvents:WaitForChild("GameOver")
local UpdateUI = RemoteEvents:WaitForChild("UpdateUI")
local LocalScoreUpdate = ReplicatedStorage:WaitForChild("LocalScoreUpdate")

local FIELD_SIZE = Vector3.new(10, 22, 1)
local BLOCK_SIZE = 4

local FLOOR_Y = GameField.Position.Y + GameField.Size.Y / 2
local GRID_ORIGIN = Vector3.new(
	GameField.Position.X - (GameField.Size.X / 2) + (BLOCK_SIZE / 2),
	FLOOR_Y + (BLOCK_SIZE / 2),
	GameField.Position.Z - (GameField.Size.Z / 2) + (BLOCK_SIZE / 2)
)

local function roundToBlock(v) return math.floor(v / BLOCK_SIZE + 0.5) * BLOCK_SIZE end
local function snap(v)
	local rel = v - GRID_ORIGIN
	return GRID_ORIGIN + Vector3.new(
		roundToBlock(rel.X),
		roundToBlock(rel.Y),
		roundToBlock(rel.Z)
	)
end

local function getParts(model)
	local t = {}
	if not model or not model.GetChildren then return t end
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") then table.insert(t, p) end
	end
	return t
end

local function randomBag()
	local bag = {"L","J","Z","S","T","O","I"}
	for i = #bag, 2, -1 do
		local j = math.random(i)
		bag[i], bag[j] = bag[j], bag[i]
	end
	return bag
end

local function centerX() return GRID_ORIGIN.X + ((FIELD_SIZE.X - 1) / 2) * BLOCK_SIZE end
local function centerZ() return GRID_ORIGIN.Z + ((FIELD_SIZE.Z - 1) / 2) * BLOCK_SIZE end
local SPAWN_OFFSET = 2
local TOP_Y = GRID_ORIGIN.Y + (FIELD_SIZE.Y - SPAWN_OFFSET) * BLOCK_SIZE

local function move(model, delta)
	for _, part in ipairs(getParts(model)) do
		part.Position = snap(part.Position + delta)
	end
end

local function rotateZ(model)
	local parts = getParts(model)
	if #parts == 0 then return end
	local pivot = parts[1].Position
	for _, part in ipairs(parts) do
		local rel = part.Position - pivot
		local newRel = Vector3.new(-rel.Y, rel.X, rel.Z)
		part.Position = snap(pivot + newRel)
	end
end

local function blocks(model)
	local t = {}
	for _, p in ipairs(getParts(model)) do
		table.insert(t, snap(p.Position))
	end
	return t
end

local function valid(posList, occ)
	for _, v in ipairs(posList) do
		local x, y, z = v.X, v.Y, v.Z
		if x < GRID_ORIGIN.X
			or x >= GRID_ORIGIN.X + FIELD_SIZE.X * BLOCK_SIZE
			or y < GRID_ORIGIN.Y
			or y >= GRID_ORIGIN.Y + FIELD_SIZE.Y * BLOCK_SIZE
			or z < GRID_ORIGIN.Z
			or z >= GRID_ORIGIN.Z + FIELD_SIZE.Z * BLOCK_SIZE then
			return false
		end
		if occ[x] and occ[x][y] and occ[x][y][z] then return false end
	end
	return true
end

local function spawnTetromino(name)
	ActiveFolder:ClearAllChildren()
	local sourceModel = Tetrominoes:FindFirstChild(name)
	if not sourceModel then
		return nil
	end
	local m = sourceModel:Clone()
	m.Parent = ActiveFolder
	local parts = getParts(m)
	if #parts == 0 then
		m:Destroy()
		return nil
	end
	local spawnPos = Vector3.new(centerX(), TOP_Y, centerZ())
	local modelPivot = m:GetPivot().Position
	local offset = spawnPos - modelPivot
	for _, p in ipairs(parts) do
		p.Anchored = true
		p.Orientation = Vector3.new(0, 0, 0)
		p.Position = snap(p.Position + offset)
	end
	return m
end

local function rebuildOccupied()
	local occ = {}
	for _, model in ipairs(FixedBlocks:GetChildren()) do
		for _, part in ipairs(model:GetChildren()) do
			if part:IsA("BasePart") then
				local snapped = snap(part.Position)
				local x, y, z = snapped.X, snapped.Y, snapped.Z
				occ[x] = occ[x] or {}
				occ[x][y] = occ[x][y] or {}
				occ[x][y][z] = true
			end
		end
	end
	return occ
end

local function resetField()
	for _, model in ipairs(FixedBlocks:GetChildren()) do
		model:Destroy()
	end
	ActiveFolder:ClearAllChildren()
end

local function checkLinesAndScore(occupied)
	local scoreInc = 0
	local linesCleared = 0

	local yRowMap = {}
	local partsList = {}
	for _, model in ipairs(FixedBlocks:GetChildren()) do
		for _, part in ipairs(model:GetChildren()) do
			if part:IsA("BasePart") and math.abs(part.Position.Z - GRID_ORIGIN.Z) < 0.1 then
				local y = math.floor((part.Position.Y - GRID_ORIGIN.Y) / BLOCK_SIZE + 0.5) * BLOCK_SIZE + GRID_ORIGIN.Y
				local x = math.floor((part.Position.X - GRID_ORIGIN.X) / BLOCK_SIZE + 0.5) * BLOCK_SIZE + GRID_ORIGIN.X
				yRowMap[y] = yRowMap[y] or {}
				yRowMap[y][x] = true
				table.insert(partsList, {part = part, y = y, x = x})
			end
		end
	end

	local fullYs = {}
	for y, xmap in pairs(yRowMap) do
		local filled = true
		for x = GRID_ORIGIN.X, GRID_ORIGIN.X + (FIELD_SIZE.X - 1) * BLOCK_SIZE, BLOCK_SIZE do
			if not xmap[x] then
				filled = false
				break
			end
		end
		if filled then
			table.insert(fullYs, y)
		end
	end
	if #fullYs == 0 then
		return 0, occupied
	end

	for _, info in ipairs(partsList) do
		for _, yFull in ipairs(fullYs) do
			if math.abs(info.y - yFull) < 0.1 then
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://9116394876"
				sound.Volume = 0.5
				sound.Parent = game:GetService("SoundService") 
				sound:Play()
				sound.Ended:Connect(function()
					sound:Destroy()
				end)
				info.part:Destroy()
			end
		end
	end

	table.sort(fullYs)
	for _, info in ipairs(partsList) do
		local shift = 0
		for _, yFull in ipairs(fullYs) do
			if info.y > yFull and info.part.Parent ~= nil then
				shift = shift + 1
			end
		end
		if shift > 0 and info.part.Parent ~= nil then
			info.part.Position = snap(info.part.Position - Vector3.new(0, BLOCK_SIZE * shift, 0))
		end
	end

	occupied = rebuildOccupied()
	linesCleared = #fullYs
	scoreInc = linesCleared * 10
	return scoreInc, occupied
end

local paused = false
local gameRunning = false
local stopGame = false

local function play()
	if gameRunning then return end
	gameRunning = true
	stopGame = false

	local score, fall = 0, 0.7
	local bag, occupied = {}, {}
	local moveKeys = {
		[Enum.KeyCode.A] = Vector3.new(-BLOCK_SIZE, 0, 0),
		[Enum.KeyCode.D] = Vector3.new(BLOCK_SIZE, 0, 0),
		[Enum.KeyCode.S] = Vector3.new(0, -BLOCK_SIZE, 0),
	}
	local currentTetromino = nil
	local canMove = true

	local UserInputService = game:GetService("UserInputService")
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if not currentTetromino or not canMove or paused or stopGame then return end
		if moveKeys[input.KeyCode] then
			move(currentTetromino, moveKeys[input.KeyCode])
			if not valid(blocks(currentTetromino), occupied) then move(currentTetromino, -moveKeys[input.KeyCode]) end
		elseif input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Space then
			rotateZ(currentTetromino)
			if not valid(blocks(currentTetromino), occupied) then
				rotateZ(currentTetromino); rotateZ(currentTetromino); rotateZ(currentTetromino)
			end
		end
	end)

	while not stopGame do
		if #bag == 0 then bag = randomBag() end
		currentTetromino = spawnTetromino(table.remove(bag, 1))
		if not valid(blocks(currentTetromino), occupied) then
			UpdateScore:FireServer(score)
			GameOverEvent:FireServer(score)
			gameRunning = false
			break
		end

		canMove = true
		while not stopGame do
			local t = 0
			while t < fall do
				if paused then
					repeat wait(0.05) until not paused or stopGame
				end
				if stopGame then break end
				wait(0.05)
				t = t + 0.05
			end
			if stopGame then break end

			move(currentTetromino, Vector3.new(0, -BLOCK_SIZE, 0))
			if not valid(blocks(currentTetromino), occupied) then
				move(currentTetromino, Vector3.new(0, BLOCK_SIZE, 0))
				canMove = false
				for _, v in ipairs(blocks(currentTetromino)) do
					local x, y, z = v.X, v.Y, v.Z
					occupied[x] = occupied[x] or {}
					occupied[x][y] = occupied[x][y] or {}
					occupied[x][y][z] = true
				end
				local fixedModel = Instance.new("Model")
				fixedModel.Name = "Tetromino"
				fixedModel.Parent = FixedBlocks
				for _, part in ipairs(getParts(currentTetromino)) do
					part.Parent = fixedModel
					part.Anchored = true
				end
				currentTetromino:Destroy()
				local scoreInc, occNew = checkLinesAndScore(occupied)
				score = score + scoreInc

				-- Ускорение при определённых очках:
				if score >= 300 then
					fall = 0.15
				elseif score >= 200 then
					fall = 0.25
				elseif score >= 100 then
					fall = 0.35
				else
					fall = 0.7
				end

				LocalScoreUpdate:Fire(score)
				occupied = occNew
				break
			end
		end
	end
	gameRunning = false
end

UpdateUI.OnClientEvent:Connect(function(status)
	if status == "Pause" then
		paused = true
	elseif status == "Resume" then
		paused = false
	elseif status == "Restart" then
		paused = false
		stopGame = true
		resetField()
		spawn(function()
			wait(0.1)
			play()
		end)
	end
end)

play()
