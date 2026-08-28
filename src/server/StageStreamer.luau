-- One-stage-at-a-time focus: hide other stage rooms + tighten fog.
-- Server sets Model/Folder.ModelStreamingMode isn't enough alone for our part folders,
-- so we toggle visibility/parenting of inactive rooms and retarget lighting fog.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local StageConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("StageConfig"))
local AuraTheme = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("AuraTheme"))

local StageStreamer = {}

local stagesRoot: Folder? = nil
local terrainRoot: Folder? = nil
local playerStage: { [number]: number } = {} -- userId → stageId (0 = lobby)

local function setFolderVisible(folder: Instance?, visible: boolean)
	if not folder then
		return
	end
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			-- Keep void kill always on
			if d.Name == "WorldVoidKill" or d.Name == "VoidVisual" then
				continue
			end
			if visible then
				local orig = d:GetAttribute("_OrigTrans")
				if typeof(orig) == "number" then
					d.Transparency = orig
				end
				d.LocalTransparencyModifier = 0
				-- restore collide if it was a gameplay/ground piece
				local oc = d:GetAttribute("_OrigCollide")
				if typeof(oc) == "boolean" then
					d.CanCollide = oc
				end
			else
				if d:GetAttribute("_OrigTrans") == nil then
					d:SetAttribute("_OrigTrans", d.Transparency)
					d:SetAttribute("_OrigCollide", d.CanCollide)
				end
				-- Soft hide: transparent + no collide (except we skip void)
				d.Transparency = 1
				d.CanCollide = false
				d.LocalTransparencyModifier = 1
			end
		elseif d:IsA("PointLight") or d:IsA("BillboardGui") then
			if d:IsA("PointLight") then
				d.Enabled = visible
			elseif d:IsA("BillboardGui") then
				d.Enabled = visible
			end
		end
	end
end

function StageStreamer.Init(stages: Folder, terrain: Folder)
	stagesRoot = stages
	terrainRoot = terrain
end

function StageStreamer.GetPlayerStage(player: Player): number
	return playerStage[player.UserId] or 0
end

function StageStreamer.Focus(player: Player, stageId: number)
	playerStage[player.UserId] = stageId

	-- Per-player visibility isn't native for parts without Replica/Viewport —
	-- we use a shared focus based on majority / last enter, PLUS attribute for client fog.
	player:SetAttribute("FocusedStage", stageId)

	-- Shared world focus: show the requested stage for everyone if only one player,
	-- or show all stages that any player is in.
	StageStreamer.RebuildVisibility()

	local def = StageConfig.Get(stageId)
	if def then
		-- Lighting bias toward that room (shared)
		pcall(function()
			Lighting.ClockTime = def.clockTime
			Lighting.FogColor = def.fogColor
			Lighting.FogStart = 40
			Lighting.FogEnd = AuraTheme.Room.FocusFogEnd
		end)
	elseif stageId == 0 then
		pcall(function()
			AuraTheme.ApplyLighting(Lighting)
			Lighting.FogEnd = AuraTheme.Room.LobbyFogEnd
		end)
	end
end

function StageStreamer.RebuildVisibility()
	if not stagesRoot then
		return
	end

	local needed: { [number]: boolean } = {}
	local any = false
	for _, plr in Players:GetPlayers() do
		local sid = playerStage[plr.UserId]
		if sid and sid > 0 then
			needed[sid] = true
			any = true
		end
	end
	-- Lobby always needed if someone is there or nobody focused
	local needLobby = false
	for _, plr in Players:GetPlayers() do
		local sid = playerStage[plr.UserId]
		if not sid or sid == 0 then
			needLobby = true
		end
	end
	if not any then
		needLobby = true
		-- show stage 1 as default preview
		needed[1] = true
	end

	for _, def in StageConfig.Stages do
		local folder = stagesRoot:FindFirstChild(StageConfig.FolderName(def.id))
		local show = needed[def.id] == true
		setFolderVisible(folder, show)
		if terrainRoot then
			local room = terrainRoot:FindFirstChild("Room" .. def.id)
			setFolderVisible(room, show)
		end
	end

	if stagesRoot then
		local lobby = stagesRoot:FindFirstChild("Lobby")
		setFolderVisible(lobby, needLobby or not any)
	end
	if terrainRoot then
		local lobbyDecor = terrainRoot:FindFirstChild("LobbyDecor")
		setFolderVisible(lobbyDecor, needLobby or not any)
		-- void always visible
		setFolderVisible(terrainRoot:FindFirstChild("WorldVoidKill"), true)
	end
end

function StageStreamer.ClearPlayer(player: Player)
	playerStage[player.UserId] = nil
	StageStreamer.RebuildVisibility()
end

return StageStreamer
