local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ammoStore = require("../stores/ammoStore")
local guns = require("../../shared/constants/guns")
local remotes = require("../../shared/remotes")

local function playSound(gun: Tool, name: string)
	local handle = gun:FindFirstChild("Handle")
	if not handle then
		return
	end

	local soundTemplate = handle:FindFirstChild(name)
	if not soundTemplate then
		return
	end

	local sound = soundTemplate:Clone()
	sound.Parent = handle
	sound:Destroy()
end

local function getGunOrigin(gun: Tool): Vector3?
	local shootPart = gun:FindFirstChild("ShootPart")
	if not shootPart or not shootPart:IsA("BasePart") then
		warn("Missing ShootPart in gun:", gun)
		return nil
	end

	return shootPart.Position
end

local function hideAmmoDisplay()
	ammoStore.setAmmoState({
		current = 0,
		max = 0,
		reloading = false,
		visible = false,
	})
end

local function updateAmmoDisplay(current: number, max: number, reloading: boolean)
	ammoStore.setAmmoState({
		current = current,
		max = max,
		reloading = reloading,
		visible = true,
	})
end

local function connect(equippedTool: Tool): () -> ()
	local player = Players.LocalPlayer
	local gunStats = guns.getGunByName(equippedTool.Name)
	if not gunStats then
		return function() end
	end

	local tool = equippedTool
	local hasAmmoLimit = guns.hasAmmoLimit(gunStats)
	local mouse: Mouse? = nil
	local holding = false
	local lastFire = 0
	local maxAmmo = gunStats.maxAmmo or 0
	local ammo = if hasAmmoLimit then maxAmmo else 0
	local reloading = false

	local fireDelay = 1 / gunStats.fireRate
	local reloadTime = gunStats.reloadTime
	local automatic = gunStats.automatic

	local activatedConnection: RBXScriptConnection? = nil
	local deactivatedConnection: RBXScriptConnection? = nil
	local reloadThread: thread? = nil

	local function getAimPosition(): Vector3?
		if not mouse then
			return nil
		end

		local hit = mouse.Hit
		return hit and hit.Position or (mouse.Target and mouse.Hit.Position) or nil
	end

	local function requestShot(origin: Vector3, targetPos: Vector3)
		if not origin or not targetPos then
			return
		end

		local ok, err = pcall(function()
			remotes.shootGun:FireServer(tool, origin, targetPos)
		end)
		if not ok then
			warn("Failed to fire shootGun: ", err)
		end
	end

	local function fireSingleShot()
		if reloading or (hasAmmoLimit and ammo <= 0) then
			return
		end

		local now = tick()
		if now - lastFire < fireDelay then
			return
		end
		lastFire = now

		local target = getAimPosition()
		local origin = getGunOrigin(tool)
		if target and origin then
			requestShot(origin, target)
			if hasAmmoLimit then
				ammo -= 1
				updateAmmoDisplay(ammo, maxAmmo, false)
			end
		end
	end

	local function startAutoFire()
		if holding == false then
			return
		end

		while holding and not reloading and (not hasAmmoLimit or ammo > 0) do
			local now = tick()
			if now - lastFire >= fireDelay then
				fireSingleShot()
			end
			RunService.Heartbeat:Wait()
		end
	end

	local function startReload()
		if not hasAmmoLimit then
			return
		end
		if reloading then
			return
		end
		if ammo >= maxAmmo then
			return
		end

		reloading = true
		updateAmmoDisplay(ammo, maxAmmo, true)
		playSound(tool, "Reload")

		if reloadThread then
			task.cancel(reloadThread)
		end

		reloadThread = task.delay(reloadTime, function()
			ammo = maxAmmo
			reloading = false
			reloadThread = nil
			updateAmmoDisplay(ammo, maxAmmo, false)
		end)
	end

	local function onActivated()
		if not hasAmmoLimit or ammo > 0 then
			if automatic then
				holding = true
				task.spawn(startAutoFire)
			else
				fireSingleShot()
			end
		else
			startReload()
		end
	end

	local function onDeactivated()
		holding = false
	end

	local function disconnectInput()
		holding = false
		if activatedConnection then
			activatedConnection:Disconnect()
			activatedConnection = nil
		end
		if deactivatedConnection then
			deactivatedConnection:Disconnect()
			deactivatedConnection = nil
		end
	end

	local function onEquipped()
		mouse = player:GetMouse()
		playSound(tool, "Equip")

		if hasAmmoLimit then
			updateAmmoDisplay(ammo, maxAmmo, false)
		else
			hideAmmoDisplay()
		end

		disconnectInput()
		activatedConnection = tool.Activated:Connect(onActivated)
		deactivatedConnection = tool.Deactivated:Connect(onDeactivated)
	end

	local function onUnequipped()
		holding = false
		mouse = nil
		disconnectInput()
		hideAmmoDisplay()
	end

	local equippedConnection = tool.Equipped:Connect(onEquipped)
	local unequippedConnection = tool.Unequipped:Connect(onUnequipped)
	local reloadConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.R and tool.Parent == player.Character then
			startReload()
		end
	end)

	if not hasAmmoLimit then
		hideAmmoDisplay()
	end

	if tool.Parent == player.Character then
		onEquipped()
	end

	return function()
		holding = false
		if reloadThread then
			task.cancel(reloadThread)
		end
		disconnectInput()
		equippedConnection:Disconnect()
		unequippedConnection:Disconnect()
		reloadConnection:Disconnect()
		hideAmmoDisplay()
	end
end

return {
	connect = connect,
}
