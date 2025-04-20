-- Saved by UniversalSynSaveInstance https://discord.gg/wx4ThpAsmw

-- params : ...
1.	
2.	local v0 = {} -- this array is empty
4.	-- V nested upvalues[0] = v0
local function setPunch(p1, p2, p3, p4, p5, p6, p7, p8) -- [line 3]
	1.	local v1 = {} -- this array is empty
	3.	local v2 = p7.linkSwingToAnimation
	5.	local v3 = p5.punch
	7.	local v4 = p2.swing
	9.	v2(v3, v4)
	10.		-- V nested upvalues[0] = p6
	-- V nested upvalues[1] = p7
	-- V nested upvalues[2] = p3
	-- V nested upvalues[3] = upvalues[0]
	-- V nested upvalues[4] = p4
	local function punch(p9) -- [line 12]
		1.	local v2 = Enum.UserInputState.Begin
		3.	if p9 == v2 then goto #37
		5.	local v4 = p6 -- get upval
		6.	local v3 = v4.block
		8.	v2 = v3[-1]
		9.	v4 = "active"
		10.	
		12.	v2 = v2:GetAttribute(v4)
		13.	if v2 == false then goto #37
		15.	v3 = p7 -- get upval
		16.	v2 = v3.checkForCooldowns
		18.	v3 = p3 -- get upval
		19.	v4 = "knucklesPunchCooldown"
		20.	v2 = v2(v3, v4)
		21.	if v2 == false then goto #37
		23.	v3 = upvalues[0] -- get upval
		24.	v2 = v3.callPunch
		26.	v2(v3)
		27.	v3 = p7 -- get upval
		28.	v2 = v3.secureLocalCooldowns
		30.	v3 = p3 -- get upval
		31.	v4 = "knucklesPunchCooldown"
		32.	v2(v3, v4)
		33.	v2 = p4 -- get upval
		34.	v4 = "punch"
		35.	
		37.	v2:FireServer(v4) -- referenced by #3, #13, #21
						end
						end
						end
		38.	return
	end
	[NEWCLOSURE] v2 = punch
	11.	CAPTURE VAL R5

	12.	CAPTURE VAL R6

	13.	CAPTURE VAL R2

	14.	CAPTURE UPVAL U0

	15.	CAPTURE VAL R3

	16.	v20 = v0 -- get upval
	17.	v20.punch = v19
	19.		-- V nested upvalues[0] = p7
	-- V nested upvalues[1] = p6
	-- V nested upvalues[2] = p5
	-- V nested upvalues[3] = p8
	-- V nested upvalues[4] = p2
	-- V nested upvalues[5] = v1
	-- V nested upvalues[6] = p9
	local function callPunch() -- [line 34]
		1.	local v21 = p7 -- get upval
		2.	local v20 = v21.punch
		4.	local v19 = v20[-1]
		5.	v21 = "active"
		6.	local v22 = true
		7.	
		9.	v19:SetAttribute(v21, v22)
		10.	v19 = nil
		11.	v22 = p6 -- get upval
		12.	v21 = v22.punch
		14.	v20 = v21.Stopped
		16.			-- V nested upvalues[0] = upvalues[1]
		-- V nested upvalues[1] = upvalues[2]
		-- V nested upvalues[2] = upvalues[0]
		-- V nested upvalues[3] = upvalues[3]
		-- V nested upvalues[4] = v2
		[NEWCLOSURE] v22 = function() -- [line 43]
			1.	local v22 = upvalues[1] -- get upval
			2.	local v21 = v22.punch
			4.	local v20 = v21.IsPlaying
			6.	if not v20 then goto #36
			7.	v20 = upvalues[2] -- get upval
			8.	v22 = "cancelPunch"
			9.	
			11.	v20:FireServer(v22)
			12.	v22 = upvalues[0] -- get upval
			13.	v21 = v22.punch
			15.	v20 = v21[-1]
			16.	v22 = "active"
			17.	local v23 = false
			18.	
			20.	v20:SetAttribute(v22, v23)
			21.	v21 = upvalues[3] -- get upval
			22.	v20 = v21.disconnectStuff
			24.	v21 = {} -- this array has (1)indexes by default
			26.	v22 = v2 -- get upval
			27.	v21[1] = v22

			29.	v20(v21)
			30.	v21 = upvalues[1] -- get upval
			31.	v20 = v21.punch
			33.	v22 = 0.2
			34.	
			36.	v20:Stop(v22) -- referenced by #6
							end
			37.	return
		end

		17.	CAPTURE UPVAL U1

		18.	CAPTURE UPVAL U2

		19.	CAPTURE UPVAL U0

		20.	CAPTURE UPVAL U3

		21.	CAPTURE REF R0

		22.	
		24.	v37 = v37:Connect(v39)
		25.	v36 = v37
		26.	v38 = p8 -- get upval
		27.	v37 = v38.syncHitboxes
		29.	v39 = p6 -- get upval
		30.	v38 = v39.punch
		32.	v39 = {} -- this array has (1)indexes by default
		34.	local v41 = p2 -- get upval
		35.	local v40 = v41.hitbox
		37.	v39[1] = v40

		39.	v40 = v1 -- get upval
		40.	v41 = p9 -- get upval
		41.	local v42 = false
		42.	local v43 = 1.3
		43.	v37(v38, v39, v40, v41, v42, v43)
		44.	v37 = table.clear
		46.	v38 = v1 -- get upval
		47.	v37(v38)
		48.	[CLOSEUPVALS]: clear captures from back until: 0
		49.	return
	end
	[NEWCLOSURE] v36 = callPunch
	20.	CAPTURE VAL R5

	21.	CAPTURE VAL R4

	22.	CAPTURE VAL R3

	23.	CAPTURE VAL R6

	24.	CAPTURE VAL R0

	25.	CAPTURE VAL R8

	26.	CAPTURE VAL R7

	27.	v60 = v0 -- get upval
	28.	v60.callPunch = v59
	30.		-- V nested upvalues[0] = p6
	local function cancelPunch() -- [line 67]
		1.	local v60 = p6 -- get upval
		2.	local v59 = v60.punch
		4.	local v61 = 0.2
		5.	
		7.	v59:Stop(v61)
		8.	return
	end
	[NEWCLOSURE] v59 = cancelPunch
	31.	CAPTURE VAL R4

	32.	v63 = v0 -- get upval
	33.	v63.cancelPunch = v62
	35.	v62 = nil
	36.	v63 = p5.OnClientEvent
	38.		[DUPCLOSURE] v65 = function(p10, p11) -- [line 75]
		1.	if p11 == "punch" then goto #2
						end
		3.	return
	end

	39.	
	41.	v63 = v63:Connect(v65)
	42.	v62 = v63
	43.	return
end
[DUPCLOSURE] v61 = setPunch
5.	CAPTURE VAL R0

6.	v70.setPunch = v71
8.	return v70
