-- initialize for Clone Wars
ifs_freeform_init_gdb = function(this, REP, CIS, ALL, IMP)

	-- common init
	ifs_freeform_init_common(this)

	-- default victory condition (take all planets)
	this:SetVictoryPlanetLimit(nil)

	-- associate codes with teams
	this.teamCode = {
		[REP] = "rep",
		[CIS] = "cis",
		[ALL] = "all",
		[IMP] = "imp"
	}

	-- use CW setup
	this.Setup = function(this)
		-- remove unused planets
		--DeleteEntity("end")
		--DeleteEntity("hot")
		--DeleteEntity("end_system")
		--DeleteEntity("hot_system")
		DeleteEntity("kam_star")
		DeleteEntity("geo_star")
		DeleteEntity("tantive")

		DeleteEntity("end_star")
		DeleteEntity("hot_star")

		-- create the connectivity graph
		this.planetDestination = {
			["cor"] = { "star20", "myg", "star17" },
			["dag"] = { "star05", "star06", "nab" },
			--["end_star"] = { "star20", "star18" },
			["fel"] = { "star13", "yav"},
			["geo"] = { "star07", "tat" },
			--["hot_star"] = { "star01", "star02" },
			["kas"] = { "star12", "star13", "star15", "star17" },
			["kam"] = { "star12", "star13", "tat" },
			["mus"] = { "star02", "star04", "star05" },
			["myg"] = { "star17", "cor", "star15", "star18" },
			["nab"] = { "star07", "star12", "star17", "dag" },
			["pol"] = { "star04", "star02", "star03" },
			["tat"] = { "geo", "kam" },
			["uta"] = { "star04", "star05", "star06" },
			["yav"] = { "star15", "fel" },
			--["star01"] = { "end_star", "star02" },
			["star02"] = { "mus", "star20", "pol", "hot" },
			["star03"] = { "hot", "pol" },
			["star04"] = { "mus", "pol", "uta" },
			["star05"] = { "mus", "uta", "dag" },
			["star06"] = { "uta", "dag", "star07" },
			["star07"] = { "nab", "geo", "star06" },
			--["star08"] = { "star06", "geo" },
			--["star09"] = { "tat", "geo" },
			["star10"] = { "star12", "geo", "tat" },
			--["star11"] = { "tat", "kam" },
			["star12"] = { "kam", "nab", "kas" },
			["star13"] = { "kas", "kam", "fel" },
			--["star14"] = { "fel", "yav" },
			["star15"] = { "kas", "yav", "myg" },
			--["star16"] = { "yav", "myg" },
			["star17"] = { "cor", "myg", "kas", "nab" },
			["star18"] = { "cor", "myg", "end" },
			--["star19"] = { "end_star", "star18" },
			["end"] = { "star20", "star18" },
			["hot"] = { "star02", "star03" },
			["star20"] = { "star02", "cor", "end" }
		}

		-- resource value for each planet
		this.planetValue = {
			["cor"] = { victory = 60, defeat = 20, turn = 3 },
			["dag"] = { victory = 50, defeat = 20, turn = 3 },
			["fel"] = { victory = 50, defeat = 20, turn = 3 },
			["geo"] = { victory = 100, defeat = 35, turn = 10 },
			["kas"] = { victory = 50, defeat = 20, turn = 3 },
			["kam"] = { victory = 100, defeat = 35, turn = 10 },
			["mus"] = { victory = 60, defeat = 20, turn = 3 },
			["myg"] = { victory = 50, defeat = 20, turn = 3 },
			["nab"] = { victory = 60, defeat = 20, turn = 3 },
			["pol"] = { victory = 50, defeat = 20, turn = 3 },
			["tat"] = { victory = 50, defeat = 20, turn = 3 },
			["uta"] = { victory = 60, defeat = 20, turn = 3 },
			["yav"] = { victory = 50, defeat = 20, turn = 3 },
			["end"] = { victory = 100, defeat = 35, turn = 10 },
			["hot"] = { victory = 100, defeat = 35, turn = 10 },
		}

		this.spaceValue = {
			victory = 30, defeat = 10,
		}


		-- mission(s) to launch for each planet
		this.spaceMission = {
			["con"] = { "spa3c_ass", "spa6c_ass", "spa7c_ass" }
		}
		this.planetMission = {
			["cor"] = {
				["con"] = "cor1tc_con",
			},
			["dag"] = {
				["con"] = "dag1tc_con",
			},
			["fel"] = {
				["con"] = "fel1tc_con",
			},
			["geo"] = {
				["con"] = "geo1tc_con",
			},
			["kam"] = {
				["con"] = "kam1tc_con",
			},
			["kas"] = {
				["con"] = "kas2tc_con",
			},
			["mus"] = {
				["con"] = "mus1c_con",
			},
			["myg"] = {
				["con"] = "myg1c_con",
			},
			["nab"] = {
				["con"] = "nab2tc_con",
			},
			["pol"] = {
				["con"] = "pol1c_con",
			},
			["tat"] = {
				["con"] = "tat2tc_con",
			},
			["uta"] = {
				["con"] = "uta1c_con",
			},
			["yav"] = {
				["con"] = "yav1c_con",
			},
			["end"] = {
				["con"] = "end1tc_con", --TODO, this map still crashes
			},
			["hot"] = {
				["con"] = "hot1g_con",
				--				["1flag"] = "hot1g_1flag",
				--TODO change to clone wars
			},
		}

		-- associate names with teams
		this.teamName = {
			[0] = "",
			[REP] = "common.sides.rep.name",
			[CIS] = "common.sides.cis.name",
			[ALL] = "common.sides.all.name",
			[IMP] = "common.sides.imp.name"
		}

		-- associate names with team bases
		this.baseName = {
			[REP] = "ifs.freeform.base.rep",
			[CIS] = "ifs.freeform.base.cis",
			[ALL] = "ifs.freeform.base.all",
			[IMP] = "ifs.freeform.base.imp"
		}

		-- associate names with team fleets
		this.fleetName = {
			[0] = "",
			[REP] = "ifs.freeform.fleet.rep",
			[CIS] = "ifs.freeform.fleet.cis",
			[ALL] = "ifs.freeform.fleet.all",
			[IMP] = "ifs.freeform.fleet.imp"
		}

		-- associate entity class with team fleets
		this.fleetClass = {
			[REP] = "gal_prp_assaultship",
			[CIS] = "gal_prp_fedcruiser",
			[ALL] = "gal_prp_moncalamaricruiser",
			[IMP] = "gal_prp_stardestroyer"
		}

		-- associate icon textures with team fleets
		this.fleetIcon = {
			[REP] = "rep_fleet_normal_icon",
			[CIS] = "cis_fleet_normal_icon",
			[ALL] = "all_fleet_normal_icon",
			[IMP] = "imp_fleet_normal_icon"
		}
		this.fleetStroke = {
			[REP] = "rep_fleet_normal_stroke",
			[CIS] = "cis_fleet_normal_stroke",
			[ALL] = "all_fleet_normal_stroke",
			[IMP] = "imp_fleet_normal_stroke"
		}

		-- set the explosion effect for each team
		this.fleetExplosion = {
			[REP] = "gal_sfx_assaultship_exp",
			[CIS] = "gal_sfx_fedcruiser_exp",
			[ALL] = "gal_sfx_moncalamaricruiser_exp",
			[IMP] = "gal_sfx_stardestroyer_exp"
		}

		-- team base planets
		this.planetBase = {
			[REP] = "kam",
			[CIS] = "geo",
			[ALL] = "hot",
			[IMP] = "end"
		}

		-- team potential starting locations
		-- team owned planets are set in this.planetTeam
		this.planetStart = {
			[REP] = { "kam", "nab", "kas" },
			[CIS] = { "geo", "uta", "mus" },
			[ALL] = { "hot", "yav", "dag" },
			[IMP] = { "end", "cor", "myg"}
		}
	end
end
