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
	if not vehiclesFolder then return nil end

	local character = playersService.LocalPlayer and playersService.LocalPlayer.Character
	if not character then return nil end

	local humanoid = character:FindFirstChildOfClass('Humanoid')
	if not humanoid then return nil end

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
	if not vehiclesFolder then return nil end

	local character = playersService.LocalPlayer and playersService.LocalPlayer.Character
	if not character then return nil end

	local humanoid = character:FindFirstChildOfClass('Humanoid')
	if not humanoid then return nil end

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

-- Tracks when we first saw each vehicle (for the 10s grace period)
local vehicleFirstSeen = {}

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

						-- Mark current car so we never touch it (even after we exit)
						if myVehicle then
							myVehicle:SetAttribute('MyVehicle', true)
						end

						if vehiclesFolder then
							-- Clean dead entries occasionally
							for veh in pairs(vehicleFirstSeen) do
								if not veh.Parent then
									vehicleFirstSeen[veh] = nil
								end
							end

							for _, vehicle in ipairs(vehiclesFolder:GetChildren()) do
								-- Record first time we see this vehicle
								if not vehicleFirstSeen[vehicle] then
									vehicleFirstSeen[vehicle] = os.clock()
								end

								local age = os.clock() - vehicleFirstSeen[vehicle]

								-- RULES:
								-- 1. Never touch my car (current or previously marked)
								-- 2. Never touch a car that is younger than 10 seconds
								if vehicle == myVehicle
									or vehicle:GetAttribute('MyVehicle')
									or age < 10 then
									continue
								end

								-- Only disable collision on other, older vehicles
								local count = 0
								for _, descendant in ipairs(vehicle:GetDescendants()) do
									if descendant:IsA('BasePart') and descendant.CanCollide then
										descendant.CanCollide = false
									end
									count += 1
									if count % 40 == 0 then
										task.wait() -- spread the work
									end
								end
							end
						end

						task.wait(0.15)
					end
				end)
			else
				-- Module disabled → clear tracking
				table.clear(vehicleFirstSeen)
			end
		end,
		Tooltip = 'Disables collisions on other vehicles. Never touches your own car or any car younger than 10 seconds.'
	})
end)

run(function()
	local VehicleBoost
	local wDown = false
	local sDown = false
	local currentSeat = nil
	local BOOST_ACCEL = 200

	local function onInputBegan(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		if input.KeyCode == Enum.KeyCode.W then
			wDown = true
			currentSeat = findMySeat()
		elseif input.KeyCode == Enum.KeyCode.S then
			sDown = true
			currentSeat = findMySeat()
		end
	end

	local function onInputEnded(input)
		if input.KeyCode == Enum.KeyCode.W then
			wDown = false
		elseif input.KeyCode == Enum.KeyCode.S then
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
					if not (wDown or sDown) then return end
					if inputService:GetFocusedTextBox() then return end

					-- Refresh seat if we lost it
					if not currentSeat or not currentSeat.Parent or currentSeat.Occupant == nil then
						currentSeat = findMySeat()
					end

					if currentSeat and currentSeat.Occupant then
						local look = currentSeat.CFrame.LookVector
						local force = look * BOOST_ACCEL * dt
						if wDown then
							currentSeat.AssemblyLinearVelocity += force
						elseif sDown then
							currentSeat.AssemblyLinearVelocity -= force
						end
					end
				end))
			else
				wDown = false
				sDown = false
				currentSeat = nil
			end
		end,
		Tooltip = 'Hold W / S while seated to apply forward / reverse boost.'
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
								rawset(v, 'BulletSpreadDegrees', 0)
								rawset(v, 'ShotgunSpreadDegrees', 0)
								rawset(v, 'ThirdPersonCameraRecoilFactor', 0)
								rawset(v, 'FirstPersonCameraRecoilFactor', 0)
								rawset(v, 'Range', 10000)
							end
						end
						task.wait(0.25)
					end
				end)
			end
		end,
		Tooltip = 'Forces Automatic fire mode + zero spread/recoil + high range on weapon tables.'
	})
end)