local run = function(func)
	func()
end
local cloneref = cloneref or function(obj)
	return obj
end
local vape = shared.vape
local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local runService = cloneref(game:GetService('RunService'))

local function waitForVape()
	repeat
		task.wait()
	until shared.vape and shared.vape.Categories and shared.vape.Categories.Blatant and shared.vape.Categories.Combat
	return shared.vape
end

local function getMyVehicle()
	local vehiclesFolder = workspace:FindFirstChild('Vehicles')
	if not vehiclesFolder then
		return nil
	end

	local player = playersService.LocalPlayer
	local character = player and player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass('Humanoid')
	if not humanoid then
		return nil
	end

	for _, vehicle in ipairs(vehiclesFolder:GetChildren()) do
		local body = vehicle:FindFirstChild('Body')
		local seats = body and body:FindFirstChild('Seats')
		local vehicleSeat = seats and seats:FindFirstChild('VehicleSeat')

		if vehicleSeat and vehicleSeat:IsA('VehicleSeat') and vehicleSeat.Occupant == humanoid then
			return vehicle
		end
	end

	return nil
end

local function findMySeat()
	local vehiclesFolder = workspace:FindFirstChild('Vehicles')
	if not vehiclesFolder then
		return nil
	end

	local player = playersService.LocalPlayer
	local character = player and player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass('Humanoid')
	if not humanoid then
		return nil
	end

	for _, vehicle in ipairs(vehiclesFolder:GetChildren()) do
		local body = vehicle:FindFirstChild('Body')
		local seats = body and body:FindFirstChild('Seats')
		local vehicleSeat = seats and seats:FindFirstChild('VehicleSeat')

		if vehicleSeat and vehicleSeat:IsA('VehicleSeat') and vehicleSeat.Occupant == humanoid then
			return vehicleSeat
		end
	end

	return nil
end

run(function()
	vape = waitForVape()
	local VehicleCollisionIgnore
	VehicleCollisionIgnore = vape.Categories.Blatant:CreateModule({
		Name = 'VehicleCollisionIgnore',
		Function = function(callback)
			if callback then
				task.spawn(function()
					while VehicleCollisionIgnore.Enabled do
						local vehiclesFolder = workspace:FindFirstChild('Vehicles')
						local myVehicle = getMyVehicle()
						if myVehicle then
							myVehicle:SetAttribute('MyVehicle', true)
						end

						if vehiclesFolder then
							for _, vehicle in ipairs(vehiclesFolder:GetChildren()) do
								if vehicle == myVehicle or vehicle:GetAttribute('MyVehicle') then
									continue
								end

								for _, descendant in ipairs(vehicle:GetDescendants()) do
									if descendant:IsA('BasePart') and descendant.CanCollide then
										descendant.CanCollide = false
									end
								end
							end
						end

						task.wait()
					end
				end)
			end
		end,
		Tooltip = 'Disable collisions on other vehicles while keeping yours intact.'
	})
end)

run(function()
	local VehicleBoost
	local wDown = false
	local sDown = false
	local currentSeat = nil
	local BOOST_ACCEL = 200

	local function onInputBegan(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end

		if input.KeyCode == Enum.KeyCode.W then
			wDown = true
			currentSeat = findMySeat()
		end

		if input.KeyCode == Enum.KeyCode.S then
			sDown = true
			currentSeat = findMySeat()
		end
	end

	local function onInputEnded(input)
		if input.KeyCode == Enum.KeyCode.W then
			wDown = false
		end

		if input.KeyCode == Enum.KeyCode.S then
			sDown = false
		end
	end

	VehicleBoost = vape.Categories.Blatant:CreateModule({
		Name = 'VehicleBoost',
		Function = function(callback)
			if callback then
				VehicleBoost:Clean(inputService.InputBegan:Connect(onInputBegan))
				VehicleBoost:Clean(inputService.InputEnded:Connect(onInputEnded))
				VehicleBoost:Clean(runService.Heartbeat:Connect(function(dt)
					if not (wDown or sDown) then
						return
					end

					if inputService:GetFocusedTextBox() then
						return
					end

					if not currentSeat or currentSeat.Occupant == nil then
						currentSeat = findMySeat()
					end

					if currentSeat then
						local lookVector = currentSeat.CFrame.LookVector
						if wDown then
							currentSeat.AssemblyLinearVelocity = currentSeat.AssemblyLinearVelocity + (lookVector * BOOST_ACCEL * dt)
						elseif sDown then
							currentSeat.AssemblyLinearVelocity = currentSeat.AssemblyLinearVelocity - (lookVector * BOOST_ACCEL * dt)
						end
					end
				end))
			end
		end,
		Tooltip = 'Hold W or S while seated in a vehicle to apply a forward or reverse thrust boost.'
	})

	local BoostForce = VehicleBoost:CreateSlider({
		Name = 'Boost Force',
		Min = 50,
		Max = 500,
		Default = 200,
		Suffix = 'studs/s²',
		Function = function(val)
			BOOST_ACCEL = val
		end
	})
	BOOST_ACCEL = BoostForce.Value or 200
end)

run(function()
	local GunModifications
	GunModifications = vape.Categories.Combat:CreateModule({
		Name = 'GunModifications',
		Function = function(callback)
			if callback then
				task.spawn(function()
					while GunModifications.Enabled do
						for _, v in pairs(getgc(true)) do
							if type(v) == 'table' and rawget(v, 'FireMode') then
								rawset(v, 'FireMode', 'Automatic')
								rawset(v, 'BulletSpreadDegrees', 0.0)
								rawset(v, 'ThirdPersonCameraRecoilFactor', 0.0)
								rawset(v, 'FirstPersonCameraRecoilFactor', 0.0)
								rawset(v, 'Range', 10000.0)
							end
						end
						task.wait(0.1)
					end
				end)
			end
		end,
		Tooltip = 'Apply automatic fire and remove recoil/spread/range restrictions for weapon tables.'
	})
end)
