-- Saved by UniversalSynSaveInstance https://discord.gg/wx4ThpAsmw

-- params : ...
1.	
2.	local v0 = {} -- this array is empty
4.	-- V nested upvalues[0] = v0
local function setBlock(p1, p2, p3, p4, p5, p6, p7, p8) -- [line 3]
	1.	local v1 = nil
	2.	local v2 = nil
	3.		-- V nested upvalues[0] = p6
	-- V nested upvalues[1] = p8
	-- V nested upvalues[2] = p4
	-- V nested upvalues[3] = p5
	local function block(p9) -- [line 11]
		1.	local v2 = Enum.UserInputState.Begin
		3.	if p9 == v2 then goto #33
		5.	local v4 = p6 -- get upval
		6.	local v3 = v4.punch
		8.	v2 = v3[-1]
		9.	v4 = "active"
		10.	
		12.	v2 = v2:GetAttribute(v4)
		13.	if v2 == false then goto #33
		15.	v3 = p8 -- get upval
		16.	v2 = v3.checkForCooldowns
		18.	v3 = p4 -- get upval
		19.	v4 = "knucklesBlockCooldown"
		20.	v2 = v2(v3, v4)
		21.	if v2 == false then goto #33
		23.	v3 = p8 -- get upval
		24.	v2 = v3.secureLocalCooldowns
		26.	v3 = p4 -- get upval
		27.	v4 = "knucklesBlockCooldown"
		28.	v2(v3, v4)
		29.	v2 = p5 -- get upval
		30.	v4 = "block"
		31.	
		33.	v2:FireServer(v4) -- referenced by #3, #13, #21
						end
						end
						end
		34.	return
	end
	[NEWCLOSURE] v3 = block
	4.	CAPTURE VAL R5

	5.	CAPTURE VAL R7

	6.	CAPTURE VAL R3

	7.	CAPTURE VAL R4

	8.	local v19 = v0 -- get upval
	9.	v19.block = v18
	11.		-- V nested upvalues[0] = p7
	-- V nested upvalues[1] = p8
	local function callBlock() -- [line 31]
		1.	local v19 = p7 -- get upval
		2.	local v18 = v19.block
		4.	local v17 = v18[-1]
		5.	v19 = "active"
		6.	local v20 = true
		7.	
		9.	v17:SetAttribute(v19, v20)
		10.	v18 = p8 -- get upval
		11.	v17 = v18.block
		13.	v19 = 0.1
		14.	
		16.	v17:Play(v19)
		17.	return
	end
	[NEWCLOSURE] v18 = callBlock
	12.	CAPTURE VAL R5

	13.	CAPTURE VAL R6

	14.	v27 = v0 -- get upval
	15.	v27.callBlock = v26
	17.	local v26 = p8.block
	19.	local v28 = "hit"
	20.	
	22.	v26 = v26:GetMarkerReachedSignal(v28)
	23.		-- V nested upvalues[0] = p3
	[NEWCLOSURE] v28 = function() -- [line 41]
		1.	local v26 = p3 -- get upval
		2.	local v25 = v26.blocking
		4.	
		6.	v25:Play()
		7.	return
	end

	24.	CAPTURE VAL R1

	25.	
	27.	v28 = v28:Connect(v30)
	28.	v26 = v28
	29.	v30 = "blocking"
	30.	
	32.	v28 = p4:GetInstanceAddedSignal(v30)
	33.		-- V nested upvalues[0] = p2
	-- V nested upvalues[1] = upvalues[0]
	-- V nested upvalues[2] = p4
	-- V nested upvalues[3] = p9
	[NEWCLOSURE] v30 = function(p10) -- [line 48]
		1.	local v27 = p2 -- get upval
		2.	if p10 == v27 then goto #39
		4.	local v28 = upvalues[0] -- get upval
		5.	v27 = v28.callBlock
		7.	v27(v28)
		8.	v27 = p4 -- get upval
		9.	local v29 = p2 -- get upval
		10.	local v30 = "blocking"
		11.	
		13.	v27 = v27:HasTag(v29, v30)
		14.	if v27 then goto #31
		15.	v27 = nil
		16.	v28 = p4 -- get upval
		17.	v30 = "blocking"
		18.	
		20.	v28 = v28:GetInstanceRemovedSignal(v30)
		21.			-- V nested upvalues[0] = upvalues[0]
		-- V nested upvalues[1] = upvalues[1]
		-- V nested upvalues[2] = upvalues[3]
		-- V nested upvalues[3] = v2
		[NEWCLOSURE] v30 = function(p11) -- [line 61]
			1.	local v28 = upvalues[0] -- get upval
			2.	if p11 == v28 then goto #16
			4.	local v29 = upvalues[1] -- get upval
			5.	v28 = v29.cancelBlock
			7.	v28(v29)
			8.	v29 = upvalues[3] -- get upval
			9.	v28 = v29.disconnectStuff
			11.	v29 = {} -- this array has (1)indexes by default
			13.	local v30 = v2 -- get upval
			14.	v29[1] = v30

			16.	v28(v29) -- referenced by #2
							end
			17.	return
		end

		22.	CAPTURE UPVAL U0

		23.	CAPTURE UPVAL U1

		24.	CAPTURE UPVAL U3

		25.	CAPTURE REF R1

		26.	
		28.	v35 = v35:Connect(v37)
		29.	v34 = v35
		30.	[CLOSEUPVALS]: clear captures from back until: 1
		31.	return -- referenced by #14
						end
		32.	v34 = warn
		34.	v35 = "the player is not tagged!"
		35.	v34(v35)
		36.	v35 = upvalues[0] -- get upval
		37.	v34 = v35.cancelBlock
		39.	v34(v35) -- referenced by #2
						end
		40.	return
	end

	34.	CAPTURE VAL R0

	35.	CAPTURE UPVAL U0

	36.	CAPTURE VAL R2

	37.	CAPTURE VAL R7

	38.	
	40.	v49 = v49:Connect(v51)
	41.	v48 = v49
	42.		-- V nested upvalues[0] = p9
	-- V nested upvalues[1] = p10
	-- V nested upvalues[2] = p6
	-- V nested upvalues[3] = p4
	-- V nested upvalues[4] = p8
	local function cancelBlock() -- [line 82]
		1.	local v50 = p9 -- get upval
		2.	local v49 = v50.block
		4.	local v48 = v49[-1]
		5.	v50 = "active"
		6.	local v51 = false
		7.	
		9.	v48:SetAttribute(v50, v51)
		10.	v49 = p10 -- get upval
		11.	v48 = v49.block
		13.	v50 = 0.2
		14.	
		16.	v48:Stop(v50)
		17.	v48 = p6 -- get upval
		18.	v50 = p4 -- get upval
		19.	v51 = "blocking"
		20.	
		22.	v48 = v48:HasTag(v50, v51)
		23.	if v48 then goto #28
		24.	v48 = p8 -- get upval
		25.	v50 = "cancelBlock"
		26.	
		28.	v48:FireServer(v50) -- referenced by #23
						end
		29.	return
	end
	[NEWCLOSURE] v49 = cancelBlock
	43.	CAPTURE VAL R5

	44.	CAPTURE VAL R6

	45.	CAPTURE VAL R2

	46.	CAPTURE VAL R0

	47.	CAPTURE VAL R4

	48.	v63 = v0 -- get upval
	49.	v63.cancelBlock = v62
	51.	return
end
[DUPCLOSURE] v60 = setBlock
5.	CAPTURE VAL R0

6.	v69.setBlock = v70
8.	return v69
