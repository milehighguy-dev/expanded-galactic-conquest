

--overrided for more than 2 teams
ifs_freeform_start_common = function(this)
	-- initialize turn counter
	this.turnNumber = 1

	-- create team resources (high now for debug)
	this.teamResources = {
		[1] = 100,
		[2] = 100,
		[3] = 100,
		[4] = 100
	}

	-- create team items
	this.teamItems = {
		[1] = { soldier = true, pilot = true},
		[2] = { soldier = true, pilot = true},
		[3] = { soldier = true, pilot = true},
		[4] = { soldier = true, pilot = true}
	}

	-- no victory yet
	this.teamVictory = nil

	-- clear out any saved state
	ScriptCB_ClearMetagameState()
	ScriptCB_ClearCampaignState()
	ScriptCB_ClearMissionSetup()
	ScriptCB_SetLastBattleVictoryValid(nil)
end

-- start balanced clone wars
function ifs_freeform_start_gdb(this)

	-- save scenario type
	--must match last 3 characters of this script
	this.scenario = "gdb"
	
	-- assigned teams
	local REP = 1
	local CIS = 2

	-- added teams

	local ALL = 3
	local IMP = 4
	
	-- CW init
	--ifs_freeform_init_gdb(this, REP, CIS)
	ifs_freeform_init_gdb(this, REP, CIS, ALL, IMP)

	-- set to versus play
	--ifs_freeform_controllers(this, { [0] = REP, [1] = CIS, [2] = REP, [3] = CIS })

	ifs_freeform_controllers(this, { [0] = ALL, [1] = CIS, [2] = REP, [3] = CIS })
	-- balanced CW start
	this.Start = function(this)

		print(">>>>>>>>>> in this.Start")

		-- perform common start
		ifs_freeform_start_common(this)

		-- set team for each planet
		--this.planetTeam = {
		--	["cor"] = REP,
		--	["dag"] = REP,
		--	["fel"] = CIS,
		--	["geo"] = CIS,
		--	["kam"] = REP,
		--	["kas"] = REP,
		--	["mus"] = CIS,
		--	["myg"] = CIS,
		--	["nab"] = REP,
		--	["pol"] = REP,
		--	["tat"] = REP,
		--	["uta"] = CIS,
		--	["yav"] = CIS,
   		--}

		this.planetTeam = {
			["cor"] = IMP,
			["dag"] = ALL,
			["fel"] = CIS,
			["geo"] = CIS,
			["kam"] = REP,
			["kas"] = REP,
			["mus"] = CIS,
			["myg"] = IMP,
			["nab"] = REP,
			["pol"] = CIS,
			["tat"] = REP,
			["uta"] = CIS,
			["yav"] = ALL,
			["hot"] = ALL,
			["end"] = IMP,
		}
		
--		-- create starting starports for each team
--		this.planetPort = {
--			["kam"] = REP,
--			["geo"] = CIS,
--		}
		
		-- create starting fleets for each team
		--this.planetFleet = {
		--	["kam"] = REP,
		--	["geo"] = CIS,
		--	["hot"] = ALL,
		--	["cor"] = IMP
		--}

		-- create starting fleets for each team
		print("initializing planetFleet -----------------")
		this.planetFleet = {
			["tat"] = REP,
			["fel"] = CIS,
			["hot"] = ALL,
			["cor"] = IMP
		}

		-- create starting fleet information for each team
		this.planetFleetInfo = {
			["tat"] = {this.fleet:makeNewFleet(nil,REP)},
			["fel"] = {this.fleet:makeNewFleet(nil,CIS)},
			["hot"] = {this.fleet:makeNewFleet(nil,ALL)},
			["cor"] = {this.fleet:makeNewFleet(nil,IMP)}
		}
	end
end
