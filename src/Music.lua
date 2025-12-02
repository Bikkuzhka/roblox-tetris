local musicFolder = game:GetService("SoundService")

local musicTracks = {}
for _, sound in pairs(musicFolder:GetChildren()) do
	if sound:IsA("Sound") then
		table.insert(musicTracks, sound)
	end
end

local function playMusicInSequence()
	local trackIndex = 1
	while true do
		for _, tr in pairs(musicTracks) do
			tr:Stop()
		end

		local currentTrack = musicTracks[trackIndex]
		currentTrack.TimePosition = 0
		currentTrack.Volume = 1
		currentTrack.Looped = false
		currentTrack:Play()

		currentTrack.Ended:Wait()

		trackIndex = trackIndex + 1
		if trackIndex > #musicTracks then
			trackIndex = 1
		end
	end
end

playMusicInSequence()
