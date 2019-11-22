-- this file will override functions to allow for more than 2 teams
-- a common pattern for getting the opposite team was "3 - team", but that doesn't work with more than 2 teams
-- we must get the opposite team more dynamically

-- override functions and variables

---------------------------
--  begin global variables
---------------------------

-- purchased cards
-- (hack to remove unlocking)
ifs_purchase_tech_cards = {
    [1] = {
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    },
    [2] = {
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    },
    [3] = {
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    },
    [4] = {
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    }
}

-- using cards
ifs_purchase_tech_using = {
    [1] = { 0, 0, 0 },
    [2] = { 0, 0, 0 },
    [3] = { 0, 0, 0 },
    [4] = { 0, 0, 0 }
}

ifs_purchase_unit_owned = {
    [1] = { soldier = true, pilot = true },
    [2] = { soldier = true, pilot = true },
    [3] = { soldier = true, pilot = true },
    [4] = { soldier = true, pilot = true }
}

---------------------------
--  end global variables
---------------------------

---------------------------
--  begin ifs_freeform_main
---------------------------

-- create a fleet with the specified team on the specified planet
ifs_freeform_main.CreateFleet = function(this, team, planet)
    -- add the fleet to the planet
    if not this.planetFleet[planet] then
        this.planetFleet[planet] = team
    elseif this.planetFleet[planet] ~= team and this.planetFleet[planet] == 0 and this.planetFleet[planet] ~= nil then
        -- use team 0 to indicate more than 1 team over a planet
        this.planetFleet[planet] = 0
    end

    -- create a fleet entity
    if not this.fleetPtr[team][planet] then
        this.fleetPtr[team][planet] = CreateEntity(this.fleetClass[team], this.modelMatrix[planet][team])
    end

    -- update the last fleet
    this.lastFleet[team] = planet
end

-- destroy a fleet with the specified team on the specified planet
ifs_freeform_main.DestroyFleet = function(this, team, planet)
    -- remove the fleet from the planet
    if this.planetFleet[planet] == 0 then
        this.planetFleet[planet] = this.otherTeam
    elseif this.planetFleet[planet] == team then
        this.planetFleet[planet] = nil
    end
    if this.fleetPtr[team][planet] then
        DeleteEntity(this.fleetPtr[team][planet])
        this.fleetPtr[team][planet] = nil
    end
end

-- move a fleet with the specified planet from the start planet to the next planet
ifs_freeform_main.MoveFleet = function(this, team, start, next)
    -- save the fleet object
    local fleetPtr = this.fleetPtr[team][start]

    -- remove the fleet from the start planet
    this.fleetPtr[team][start] = nil
    -- if you move away from a planet with 2 fleets then give it up to other team
    if this.planetFleet[start] == 0 then
        this.planetFleet[start] = this.otherTeam
    -- else no fleet is present
    elseif this.planetFleet[start] == team then
        this.planetFleet[start] = nil
    end

    -- update the fleet's position
    SetEntityMatrix(fleetPtr, this.modelMatrix[next][team])

    -- add the fleet to the next planet
    this.fleetPtr[team][next] = fleetPtr
    if not this.planetFleet[next] then
        this.planetFleet[next] = team
    elseif this.planetFleet[next] ~= team and this.planetFleet[next] ~= 0 and this.planetFleet[next] ~= nil then
        this.otherTeam = this.planetFleet[next]
        -- use team 0 to indicate more than 1 team over a planet
        this.planetFleet[next] = 0
    end

    -- update the last fleet
    this.lastFleet[team] = next
end

-- apply battle results for the specified planet
ifs_freeform_main.ApplyBattleResult = function(this, planet, winner)

    print("ifs_freeform_main.ApplyBattleResult ---------------------")

    -- save which team won
    this.winnerTeam = winner

    -- save whether the battle was a fleet battle
    this.fleetBattle = this.planetFleet[planet] == 0

    -- get the losing team
    local loser = 3 - winner

    if winner == this.attackTeam then
        loser = this.defendTeam
    elseif winner == this.defendTeam then
        loser = this.attackTeam
    else
        -- do nothing
    end

    print("ifs_freeform_main.ApplyBattleResult winner is " .. tostring(winner) .. " loser is " .. tostring(loser))

    -- create if necessary
    this.planetResources = this.planetResources or {}
    this.battleResources = this.battleResources or {}

    -- no planet resources yet
    for teamNumber, teamName in ipairs(this.teamCode) do
        this.planetResources[teamNumber] = 0
    end

    -- if the battle was a fleet battle...
    if this.fleetBattle then
        -- give winner and loser some resources
        this.battleResources[winner] = this.spaceValue.victory
        this.battleResources[loser] = this.spaceValue.defeat
    else
        -- if the planet is the loser's base, remove it from play
        -- otherwise, assign it to the winner
        this.planetTeam[planet] = planet == this.planetBase[loser] and 0 or winner

        -- give winner and loser planet resources
        this.battleResources[winner] = this.planetValue[planet].victory
        this.battleResources[loser] = this.planetValue[planet].defeat

        print("ifs_freeform_main.ApplyBattleResult got to not fleetbattle")

        -- add per-turn resource units per planet
        for planet, team in pairs(this.planetTeam) do
            if team ~= 0 then
                print("planet is " .. tostring(planet) .. " team is " .. tostring(team))
                print("planetResources " .. tostring(this.planetResources[team]) .. " planetValue " .. tostring(this.planetValue[planet].turn))
                this.planetResources[team] = this.planetResources[team] + this.planetValue[planet].turn
            end
        end
    end

    print("ifs_freeform_main.ApplyBattleResult got to 1")

    -- give each team its added resources
    this:AddResources(winner, this.battleResources[winner] + this.planetResources[winner])
    this:AddResources(loser, this.battleResources[loser] + this.planetResources[loser])

    print("ifs_freeform_main.ApplyBattleResult got to 2")

    -- remove the loser's fleet, if any
    if this.fleetBattle or this.planetFleet[planet] == loser then
        AttachEffectToMatrix(CreateEffect(this.fleetExplosion[loser]), this.modelMatrix[planet][loser])
    end
    this:DestroyFleet(loser, planet)

    print("ifs_freeform_main.ApplyBattleResult got to 3")

    -- add the planet to the battle list (for AI)
    this.recentPlanets = this.recentPlanets or {}
    if this.planetTeam[planet] and this.planetTeam[planet] > 0 then
        this.recentPlanets[3] = nil
        table.insert(this.recentPlanets, 1, planet)
    end
end

-- set the active team
ifs_freeform_main.SetActiveTeam = function(this, team)
    this.playerTeam = team

    -- teams which are not playerTeam
    this.otherTeams = {}
    local otherTeamsLength = 0
    for teamNumber, teamString in ipairs(this.teamCode) do
        if teamNumber ~= this.playerTeam then
            table.insert(this.otherTeams, teamNumber)
            otherTeamsLength = otherTeamsLength + 1
        end
    end

    -- initialize it with a random value for now...
    if not this.otherTeam then
        this.otherTeam = this.otherTeams[math.random(1, otherTeamsLength)]
    end

    this.playerSide = this.teamCode[team]
    --this.otherSide = this.teamCode[3 - team]
    this.joystick = this.teamController[team]
    this.joystick_other = this.teamController[3 - team]
    ScriptCB_SetHotController((this.joystick or this.joystick_other or 0)+1)

    -- update dependent values
    ifs_freeform_purchase_unit:SetActiveSide()
end

-- go to the next turn
ifs_freeform_main.NextTurn = function(this)

    print("ifs_freeform_main.NextTurn -------------------")

    -- clear the screen stack
    ScriptCB_PopScreen("ifs_freeform_main")

    -- update metagame victory result
    if this.CheckVictory then
        this.teamVictory = this:CheckVictory()
    end

    -- on victory...
    if this.teamVictory then
        -- go to the end screen
        ScriptCB_PushScreen("ifs_freeform_end")
    else
        -- advance to the next turn
        this.turnNumber = this.turnNumber + 1

        -- switch teams
        this.lastSelected[this.playerTeam] = this.planetNext

        local nextTeam = this.playerTeam
        for teamNumber, teamString in ipairs(this.teamCode) do
            print("team number is " .. teamNumber)
            if teamNumber == this.playerTeam then
                -- if there is another team after this one select that team
                if this.teamCode[ teamNumber + 1 ] then
                    nextTeam = teamNumber + 1
                    print("selected for next team:" .. tostring(this.teamCode[teamNumber + 1]))
                else
                    -- else start at beginning team
                    nextTeam = 1 -- arrays start at 1
                    print("selected for next team:" .. tostring(this.teamCode[1]))
                end
            else
                -- do nothing, keep iterating
            end
        end

        this:SetActiveTeam(nextTeam)
        this:SelectPlanet(nil, this.lastSelected[this.playerTeam])

        -- clear state
        this.launchMission = nil
        this.activeBonus = {}

        -- clear remaster database of side info
        rema_database.matchinfo = nil

        -- if the team has a human player...
        if this.joystick then
            -- go to the fleet screen
            ScriptCB_PushScreen("ifs_freeform_fleet")
        else
            -- go to ai move
            ScriptCB_PushScreen("ifs_freeform_ai")
        end
    end
end

-- set up team colors
ifs_freeform_main.InitTeamColor = function(this)
    -- precomputed colors
    local colorWhite = { r=255, g=255, b=255 }
    local colorBlue = { r=32, g=96, b=255 }
    local colorRed = { r=255, g=32, b=32 }
    local colorGreen = { r=0, g=255, b=0 }
    local colorOrange = { r=255, g=150, b=0 }


    -- if AI versus team 2...
    this.teamColor = {}
    if not this.teamController[1] and this.teamController[2] then
        -- swapped colors: 1=red, 2=blue
        this.teamColor[1] = { [0] = colorWhite, [1] = colorRed, [2] = colorBlue, [3] = colorGreen, [4] = colorOrange }
        this.teamColor[2] = { [0] = colorWhite, [1] = colorRed, [2] = colorBlue, [3] = colorGreen, [4] = colorOrange }
        this.teamColor[3] = { [0] = colorWhite, [1] = colorRed, [2] = colorBlue, [3] = colorGreen, [4] = colorOrange }
        this.teamColor[4] = { [0] = colorWhite, [1] = colorRed, [2] = colorBlue, [3] = colorGreen, [4] = colorOrange }
    else
        -- absolute colors: 1=blue, 2=red
        this.teamColor[1] = { [0] = colorWhite, [1] = colorBlue, [2] = colorRed, [3] = colorGreen, [4] = colorOrange }
        this.teamColor[2] = { [0] = colorWhite, [1] = colorBlue, [2] = colorRed, [3] = colorGreen, [4] = colorOrange }
        this.teamColor[3] = { [0] = colorWhite, [1] = colorRed, [2] = colorBlue, [3] = colorGreen, [4] = colorOrange }
        this.teamColor[4] = { [0] = colorWhite, [1] = colorRed, [2] = colorBlue, [3] = colorGreen, [4] = colorOrange }
    end
end

-- set victory condition: planet limit
-- (default to 100% captured plus no enemy fleets remaining)
ifs_freeform_main.SetVictoryPlanetLimit = function(this, limit)
    print("SetVictoryPlanetLimit", limit)
    this.CheckVictory = function(this)
        print("CheckVictoryPlanetLimit", limit)
        local checkfleets = false
        if not limit then
            limit = 0
            for planet, team in pairs(this.planetTeam) do
                if team > 0 then
                    limit = limit + 1
                end
            end
            checkfleets = true
        end
        local counts = { [1] = 0, [2] = 0, [3] = 0, [4] = 0 }
        for planet, team in pairs(this.planetTeam) do
            if team > 0 then
                counts[team] = counts[team] + 1
                if counts[team] >= limit then
                    if checkfleets then
                        for planet, fleet in pairs(this.fleetPtr[3 - team]) do
                            return nil
                        end
                    end
                    return team
                end
            end
        end
        return nil
    end
end

-- save metagame state
ifs_freeform_main.SaveState = function(this)
    -- what's the current screen?
    if ScriptCB_IsScreenInStack("ifs_freeform_summary") then
        if ScriptCB_IsScreenInStack("ifs_freeform_result") then
            this.curScreen = "summary_result"
        else
            this.curScreen = "summary_fleet"
        end
    elseif ScriptCB_IsScreenInStack("ifs_freeform_result") then
        this.curScreen = "result"
    elseif ScriptCB_IsScreenInStack("ifs_freeform_battle_card") then
        if ifs_freeform_battle_card.defending then
            this.curScreen = "battle_card_2"
        else
            this.curScreen = "battle_card_1"
        end
    elseif ScriptCB_IsScreenInStack("ifs_freeform_battle_mode") then
        this.curScreen = "battle_mode"
    elseif ScriptCB_IsScreenInStack("ifs_freeform_battle") then
        if ScriptCB_IsScreenInStack("ifs_freeform_fleet") then
            this.curScreen = "battle_back"
        else
            this.curScreen = "battle_noback"
        end
    else
        this.curScreen = nil
    end

    -- map name to team as a hint
    local profileTeam = {}
    for joystick, team in pairs(this.controllerTeam) do
        local name = ScriptCB_ununicode(ScriptCB_GetProfileName(joystick+1))
        profileTeam[name] = team
    end

    -- save values to saved state
    ScriptCB_SaveMetagameState(
            this.custom,
            this.scenario,
            profileTeam,		--this.controllerTeam,
            this.lastSelected,
            this.lastFleet,
            this.planetTeam,
    --			this.planetPort,
            this.planetFleet,
            this.planetNext,
            this.teamResources,
            ifs_purchase_unit_owned,
            ifs_purchase_tech_cards,
            ifs_purchase_tech_using,
            this.playerTeam,
            this.otherTeams,
            this.otherTeam,
            this.attackTeam,
            this.defendTeam,
            this.turnNumber,
            this.curScreen,
            ifs_freeform_fleet.turnNumber,
            ifs_freeform_fleet.planetStart,
            ifs_freeform_fleet.planetNext,
            this.launchMission,
            this.activeBonus,
            this.winnerTeam,
            this.fleetBattle,
            this.recentPlanets,
            this.planetResources,
            this.battleResources,
            this.soakMode
    )
end

-- load metagame state
ifs_freeform_main.LoadState = function(this)
    local profileTeam
    local screen

    -- load values from saved state
    this.custom,
    this.scenario,
    profileTeam,		--this.controllerTeam,
    this.lastSelected,
    this.lastFleet,
    this.planetTeam,
    --		this.planetPort,
    this.planetFleet,
    this.planetNext,
    this.teamResources,
    ifs_purchase_unit_owned,
    ifs_purchase_tech_cards,
    ifs_purchase_tech_using,
    this.playerTeam,
    this.otherTeams,
    this.otherTeam,
    this.attackTeam,
    this.defendTeam,
    this.turnNumber,
    this.curScreen,
    ifs_freeform_fleet.turnNumber,
    ifs_freeform_fleet.planetStart,
    ifs_freeform_fleet.planetNext,
    this.launchMission,
    this.activeBonus,
    this.winnerTeam,
    this.fleetBattle,
    this.recentPlanets,
    this.planetResources,
    this.battleResources,
    this.soakMode
    = ScriptCB_LoadMetagameState()

    -- create a blank list if empty
    this.recentPlanets = this.recentPlanets or {}

    -- if loading a mission... (HACK)
    if ScriptCB_GetLastBattleVictory() < 0 then
        -- set mission name
        if this.launchMission then
            ScriptCB_SetMissionNames(this.launchMission, nil)
        end

        -- activate team bonuses
        for team, bonus in pairs(this.activeBonus) do
            ActivateBonus(team, bonus)
        end
    end

    -- start appropriate scenario
    local start = _G["ifs_freeform_start_" .. this.scenario]
    if start then
        start(this, this.custom)
    else
        assert("undefined scenario type \""..this.scenario.."\"")
    end

    -- discard the unused start function
    this.Start = nil

    -- restore profile teams
    local controllerTeam = {}
    for joystick, team in pairs(this.controllerTeam) do
        local name = ScriptCB_ununicode(ScriptCB_GetProfileName(joystick+1))
        local newteam = profileTeam[name]
        print (joystick, team, newteam, name)
        controllerTeam[joystick] = newteam or team
    end
    ifs_freeform_controllers(this, controllerTeam)
end

ifs_freeform_main.OneTimeInit = function(this, showLoadDisplay)
    -- restore any saved metagame state
    if ScriptCB_IsMetagameStateSaved() then
        this:LoadState()
    end

    if not this.planetDestination then

        -- set up memory pools (HACK)
        SetMemoryPoolSize("EntitySoundStream", 2)

        SetMemoryPoolSize("ParticleTransformer::PositionTr", 700)
        SetMemoryPoolSize("ParticleTransformer::SizeTransf", 751)
        SetMemoryPoolSize("ParticleTransformer::ColorTrans", 1176)

        SetMemoryPoolSize("ParticleEmitterObject", 16)
        SetMemoryPoolSize("ParticleEmitterInfoData", 128)
        SetMemoryPoolSize("ParticleEmitter", 128)

        -- show the load display
        if showLoadDisplay then
            -- stop any streaming
            ScriptCB_StopMovie()
            ScriptCB_CloseMovie()
            ScriptCB_SetShellMusic()

            -- do loading
            SetupTempHeap(2 * 1024 * 1024)
            ScriptCB_ShowLoadDisplay(true)
        end

        -- load sides
        ifs_purchase_load_data(this.teamCode[1], this.teamCode[2])

        -- read the galaxy map level
        ReadDataFile("gal\\gal1.lvl")

        -- read the galaxy map level
        ReadDataFile("sound\\gal.lvl;gal_vo")

        this.streamVoice = OpenAudioStream("sound\\gal.lvl", "gal_vo_slow")
        this.streamMusic = OpenAudioStream("sound\\gal.lvl", "gal_music")

        ScriptCB_PostLoadHack()

        -- hide the load display
        if showLoadDisplay then
            ScriptCB_ShowLoadDisplay(false)
            ClearTempHeap()
        end

        -- perform one-time setup
        this:Setup()

        -- create empty port array
        this.portPtr = { }

        -- create empty fleet array
        this.fleetPtr = { [1] = {}, [2] = {} , [3] = {}, [4] = {} }

        -- create planet, fleet, and port matrices
        this.planetMatrix = {}
        this.modelMatrix = {}
        for planet, _ in pairs(this.planetDestination) do
            local planetMatrix = GetEntityMatrix(planet)
            this.planetMatrix[planet] = {}
            this.planetMatrix[planet][0] = planetMatrix
            this.planetMatrix[planet][1] = CreateMatrix(-2.25, 0.0, 1.0, 0.0, 10.0, 4.0, -8.0, planetMatrix)
            this.planetMatrix[planet][2] = CreateMatrix(2.25, 0.0, 1.0, 0.0, -10.0, 4.0, -8.0, planetMatrix)
            this.planetMatrix[planet][3] = CreateMatrix(0.0, 0.0, 0.0, 0.0, 0.0, 16.0, 0.0, planetMatrix)
            this.planetMatrix[planet][4] = CreateMatrix(0.0, 0.0, 0.0, 0.0, 0.0, 16.0, 0.0, planetMatrix)
            this.modelMatrix[planet] = {}
            this.modelMatrix[planet][1] = GetEntityMatrix(planet .. "_fleet1") or this.planetMatrix[planet][1]
            this.modelMatrix[planet][2] = GetEntityMatrix(planet .. "_fleet2") or this.planetMatrix[planet][2]
            this.modelMatrix[planet][3] = GetEntityMatrix(planet .. "_fleet3") or this.planetMatrix[planet][3]
            this.modelMatrix[planet][4] = GetEntityMatrix(planet .. "_fleet4") or this.planetMatrix[planet][4]
        end

        -- show side setup screen?
        this.setupSides = (this.custom ~= nil)

        -- initialize team colors
        this:InitTeamColor()
    end
end

ifs_freeform_main.Enter = function(this, bFwd)
    gIFShellScreenTemplate_fnEnter(this, bFwd)

    print("ifs_freeform_main.Enter ---------------------")

    if bFwd then
        -- stop any playing movie
        ifelem_shellscreen_fnStopMovie()

        -- disable split screen
        this.wasSplit = ScriptCB_GetNumCameras()
        ScriptCB_SetSplitscreen(nil)

        -- enable metagame rules
        ScriptCB_SetGameRules("metagame")

        -- clear out saved screen
        this.curScreen = nil

        -- perform one-time init
        -- (does nothing if already loaded)
        this:OneTimeInit(true)

        ScriptCB_SetShellMusic("metagame_menu_music")

        -- set build screens to campaign mode
        ifs_freeform_purchase_unit:SetFreeformMode()
        ifs_freeform_purchase_tech:SetFreeformMode()

        -- if metagame state was saved...
        if ScriptCB_IsMetagameStateSaved() then
            -- set the active team
            this:SetActiveTeam(this.playerTeam)
        else
            -- set initial state
            this:Start()

            -- get selected planet and fleet for each side
            this.lastSelected = {}
            this.lastFleet = {}
            for planet, team in pairs(this.planetFleet) do
                if team > 0 then
                    this.lastSelected[team] = planet
                    this.lastFleet[team] = planet
                end
            end
            for team, planet in pairs(this.planetBase) do
                if not this.lastSelected[team] then
                    this.lastSelected[team] = planet
                end
            end

            -- set the active team to that of the starting controller
            this:SetActiveTeam(this.controllerTeam[this.startController])
            this.planetNext = this.lastSelected[this.playerTeam]

            -- clear state
            this.launchMission = nil
            this.activeBonus = {}
            this.recentPlanets = {}
        end

        -- if the last battle had a winner...
        -- ScriptCB_GetLastBattleVictory() will only return 1 for attacker and 2 for defender (or whatever is specified in planet script maybe)
        -- TODO map 1 and 2 to the actual number for team involved
        local winner = ScriptCB_GetLastBattleVictory()
        if this.soakMode and ScriptCB_IsMetagameStateSaved() then
            winner = math.random(2)
        end
        if winner > 0 then

            print("ifs_freeform_main.Enter winner before mapping winner is " .. tostring(winner))
            -- get winner and loser
            -- assuming playerTeam is defending and vice versa
            if winner == 1 then
                winner = this.attackTeam
            elseif winner == 2 then
                winner = this.defendTeam
            else
                print("ifs_freeform_main.Enter ERROR could not determine winner")
            end

            print("ifs_freeform_main.Enter winner after mapping winner is " .. tostring(winner))

            print("ifs_freeform_main.Enter playerTeam is " .. tostring(this.playerTeam) .. " otherTeam is " .. tostring(this.otherTeam))
            -- apply battle results
            this:ApplyBattleResult(this.planetNext, winner)

            -- clear battle result
            ScriptCB_SetLastBattleVictoryValid(false)

            -- go to the result screen
            ScriptCB_PushScreen("ifs_freeform_result")

            -- trigger save request on next turn
            this.requestSave = true

            -- if setting up sides...
        elseif this.setupSides then

            -- go to the side setup screen
            ScriptCB_PushScreen("ifs_freeform_sides")

            -- otherwise...
        else

            -- go to the saved screen
            if this.curScreen == "summary_result" then
                ScriptCB_PushScreen("ifs_freeform_result")
                ScriptCB_PushScreen("ifs_freeform_summary")
            elseif this.curScreen == "summary_fleet" then
                ScriptCB_PushScreen("ifs_freeform_fleet")
                ScriptCB_PushScreen("ifs_freeform_summary")
            elseif this.curScreen == "result" then
                ScriptCB_PushScreen("ifs_freeform_result")
            elseif this.curScreen == "battle_card_2" then
                ifs_freeform_battle_card.defending = 1
                ScriptCB_PushScreen("ifs_freeform_battle")
                ScriptCB_PushScreen("ifs_freeform_battle_mode")
                ScriptCB_PushScreen("ifs_freeform_battle_card")
            elseif this.curScreen == "battle_card_1" then
                ifs_freeform_battle_card.defending = nil
                ScriptCB_PushScreen("ifs_freeform_battle")
                ScriptCB_PushScreen("ifs_freeform_battle_mode")
                ScriptCB_PushScreen("ifs_freeform_battle_card")
            elseif this.curScreen == "battle_mode" then
                ScriptCB_PushScreen("ifs_freeform_battle")
                ScriptCB_PushScreen("ifs_freeform_battle_mode")
            elseif this.curScreen == "battle_back" then
                ScriptCB_PushScreen("ifs_freeform_fleet")
                ScriptCB_PushScreen("ifs_freeform_battle")
            elseif this.curScreen == "battle_noback" then
                ScriptCB_PushScreen("ifs_freeform_battle")
                -- if the team has a human player...
            elseif this.joystick then
                -- go to the fleet screen
                ScriptCB_PushScreen("ifs_freeform_fleet")
            else
                -- go to ai move
                ScriptCB_PushScreen("ifs_freeform_ai")
            end

        end

        -- set up build screen
        ifs_purchase_build_screen()

        -- initialize ai state (HACK)
        ifs_freeform_ai:Init()

        --			-- create port entities (HACK)
        --			for planet, port in pairs(this.portPtr) do
        --				DeleteEntity(port)
        --			end
        --			this.portPtr = { }
        --			for planet, team in pairs(this.planetPort) do
        --				this.portPtr[planet] = CreateEntity(this.portClass[team], this.modelMatrix[planet][3])
        --			end

        -- create fleet entities (HACK)
        for team, list in pairs(this.fleetPtr) do
            for planet, fleet in pairs(list) do
                DeleteEntity(fleet)
            end
        end
        this.fleetPtr = { [1] = {}, [2] = {} , [3] = {}, [4] = {} }
        for planet, team in pairs(this.planetFleet) do
            if team == 0 then
                this.fleetPtr[1][planet] = CreateEntity(this.fleetClass[1], this.modelMatrix[planet][1])
                this.fleetPtr[2][planet] = CreateEntity(this.fleetClass[2], this.modelMatrix[planet][2])
            else
                this.fleetPtr[team][planet] = CreateEntity(this.fleetClass[team], this.modelMatrix[planet][team])
            end
        end

        -- select the initial planet
        this:SelectPlanet(nil, this.planetNext)

        -- set camera offset for each zoom level
        SetMapCameraOffset(0, 0, 200, 480)
        SetMapCameraPitch(0, -0.05)
        SetMapCameraOffset(1, 0, 100, 150)
        SetMapCameraPitch(1, -0.025)

        -- enable the 3D scene
        ScriptCB_EnableScene(true)
    end
end

------------------------
-- end ifs_freeform_main
------------------------

------------------------
-- begin ifs_freeform_fleet
------------------------

ifs_freeform_fleet.AttemptMove = function(this, team, start, next)

    print("ifs_freeform_fleet.AttemptMove() ----------------------------")

    -- fail invalid move
    if not this:IsValidMove(team, start, next) then
        return false
    end

    -- move the fleet
    ifs_freeform_main:MoveFleet(team, start, next)

    -- select the planet
    ifs_freeform_main:SelectPlanet(this.info, next)

    -- save the fleet's move
    this.turnNumber = ifs_freeform_main.turnNumber
    this.planetStart = start
    this.planetNext = next

    -- if the destination planet is an enemy, or there is a fleet battle...
    if (ifs_freeform_main.planetTeam[next] ~= team and ifs_freeform_main.planetTeam[next] ~= 0 and ifs_freeform_main.planetTeam[next] ~= nil) or
            ifs_freeform_main.planetFleet[next] == 0 then

        -- loop through fleetPtr to see if there is an enemy fleet at the next planet
        local otherFleet
        for fleetTeam, fleetPlanet in ipairs(ifs_freeform_main.fleetPtr) do
            print("fleet team is " .. tostring(fleetTeam))
            if fleetTeam ~= team and fleetTeam ~= 0 and fleetTeam ~= nil
                    and ifs_freeform_main.fleetPtr[fleetTeam][next]then
                otherFleet = fleetTeam
                print("ifs_freeform_fleet.AttemptMove otherFleet is " .. tostring(otherFleet))
            end
        end

        if otherFleet then
            ifs_freeform_main.otherTeam = otherFleet
        elseif ifs_freeform_main.planetTeam[next] then
            ifs_freeform_main.otherTeam = ifs_freeform_main.planetTeam[next]
        else
            print("ifs_freeform_fleet.AttemptMove ERROR could not determine otherTeam")
        end

        ifs_freeform_main.attackTeam = ifs_freeform_main.playerTeam
        ifs_freeform_main.defendTeam = ifs_freeform_main.otherTeam

        rema_database.matchinfo = {
            attackteam = {
                number = ifs_freeform_main.attackTeam
            },
            defendteam = {
                number = ifs_freeform_main.defendTeam
            }
        }

        -- jump to the battle screen
        this.nextScreen = "ifs_freeform_battle"
    else
        -- go to the summary page
        this.nextScreen = "ifs_freeform_summary"
    end

    -- start the display timer timer
    this.displayTimer = 1.0

    -- deselect the fleet
    this:DeselectFleet()

    return true
end

------------------------
-- end ifs_freeform_fleet
------------------------

------------------------
-- begin ifs_freeform_battle
------------------------

ifs_freeform_battle.Enter = function(this, bFwd)
    gIFShellScreenTemplate_fnEnter(this, bFwd) -- call default enter function

    ifs_freeform_main:SetZoom(2)
    MoveCameraToEntity(ifs_freeform_main.planetSelected .. "_camera")

    IFObj_fnSetVis(this.title, nil)

    -- remove player group
    IFObj_fnSetVis(this.player, nil)

    -- allow back only if coming from player fleet movement
    this.allowBack = ifs_freeform_main.joystick and ScriptCB_IsScreenInStack("ifs_freeform_fleet")

    -- update button status
    ifs_freeform_SetButtonVis( this, "back", this.allowBack )
    if ifs_freeform_main.joystick then
        ifs_freeform_SetButtonName( this, "accept", "ifs.freeform.attack" )
        ifs_freeform_SetButtonName( this, "back", "ifs.freeform.noattack" )
    else
        ifs_freeform_SetButtonName( this, "accept", "common.next" )
    end
    ifs_freeform_SetButtonVis( this, "misc", nil )
    ifs_freeform_SetButtonVis(this, "help", nil)

    -- play appropriate VO messages and display caption and info text
    --if it's a deep space battle
    if not ifs_freeform_main.planetTeam[ifs_freeform_main.planetSelected] then
        if ifs_freeform_main.joystick then
            ifs_freeform_main:PlayVoice(string.format(ifs_battle_fleet_sound, ifs_freeform_main.playerSide, "us"))
        else
            ifs_freeform_main:PlayVoice(string.format(ifs_battle_fleet_sound, ifs_freeform_main.teamCode[ifs_freeform_main.otherTeam], "them"))
        end
        IFObj_fnSetVis(this.info, true)
        IFText_fnSetString(this.info.caption, "ifs.freeform.spacebattle")
        IFObj_fnSetVis(this.info.text, false)
        --if it's a space battle over a planet
    elseif ifs_freeform_main.planetFleet[ifs_freeform_main.planetSelected] == 0 then
        if ifs_freeform_main.joystick then
            ifs_freeform_main:PlayVoice(string.format(ifs_battle_fleet_sound, ifs_freeform_main.playerSide, "us"))
        else
            ifs_freeform_main:PlayVoice(string.format(ifs_battle_fleet_sound, ifs_freeform_main.teamCode[ifs_freeform_main.otherTeam], "them"))
        end
        IFObj_fnSetVis(this.info, true)
        IFText_fnSetString(this.info.text, "ifs.freeform.planetdesc." .. ifs_freeform_main.planetSelected)
        IFObj_fnSetVis(this.info.text, true)
        IFText_fnSetUString(this.info.caption,
                ScriptCB_usprintf("ifs.freeform.fleetbattle",
                        ScriptCB_getlocalizestr("planetname." .. ifs_freeform_main.planetSelected)
                )
        )
        --if it's a planet battle
    else
        if ifs_freeform_main.joystick then
            ifs_freeform_main:PlayVoice(string.format(ifs_battle_planet_sound, ifs_freeform_main.playerSide, ifs_freeform_main.planetSelected, "us"))
        else
            ifs_freeform_main:PlayVoice(string.format(ifs_battle_planet_sound, ifs_freeform_main.teamCode[ifs_freeform_main.otherTeam], ifs_freeform_main.planetSelected, "them"))
        end
        IFObj_fnSetVis(this.info, 1)
        IFText_fnSetString(this.info.text, "ifs.freeform.planetdesc." .. ifs_freeform_main.planetSelected)
        IFObj_fnSetVis(this.info.text, true)
        IFText_fnSetUString(this.info.caption,
                ScriptCB_usprintf("ifs.freeform.planetbattle",
                        ScriptCB_getlocalizestr("planetname." .. ifs_freeform_main.planetSelected)
                )
        )
    end

    -- if in soak mode...
    if ifs_freeform_main.soakMode then
        -- start a display timer
        this.displayTimer = 5
    end
end

------------------------
-- end ifs_freeform_battle
------------------------

------------------------
-- begin ifs_freeform_battle_card
------------------------

ifs_freeform_battle_card.Next = function(this)
    if this.defending then
        -- switch to the attacker
        this.defending = nil
        ifs_freeform_main:SetActiveTeam(ifs_freeform_main.attackTeam)

        -- restore split screen
        ScriptCB_SetSplitscreen(ifs_freeform_main.wasSplit)

        -- save state
        ifs_freeform_main:SaveState()

        -- save mission setup
        ifs_freeform_main:SaveMissionSetup()

        -- if in soak mode...
        if ifs_freeform_main.soakMode then
            -- enter the selected mission as a demo
            ScriptCB_LaunchDemo(ifs_freeform_main.launchMission)
        else
            -- enter the selected mission
            ScriptCB_EnterMission()
        end
    else
        -- switch to the defender
        this.defending = true
        ifs_freeform_main:SetActiveTeam(ifs_freeform_main.defendTeam)

        -- re-enter as the defender
        ScriptCB_PushScreen("ifs_freeform_battle_card")
    end
end

------------------------
-- end ifs_freeform_battle_card
------------------------

------------------------
-- begin ifs_freeform_result
------------------------

ifs_freeform_result.Enter = function(this, bFwd)
    print("ifs_freeform_result.Enter ----------------------")
    gIFShellScreenTemplate_fnEnter(this, bFwd) -- call default enter function

    ifs_freeform_main:SetZoom(2)
    MoveCameraToEntity(ifs_freeform_main.planetSelected .. "_camera")
    SnapMapCamera()


    IFObj_fnSetVis(this.info, false)

    IFText_fnSetString(this.title.text, "ifs.freeform.battleresult")

    --		--display appropriate caption
    --		--if it's a space battle over a planet
    --		if ifs_freeform_main.planetFleet[ifs_freeform_main.planetSelected] == 0 then
    --			IFText_fnSetUString(this.title.text,
    --				ScriptCB_usprintf("ifs.freeform.resultstring",
    --					ScriptCB_getlocalizestr("planetname." .. ifs_freeform_main.planetSelected),
    --					ScriptCB_getlocalizestr("ifs.freeform.spacebattleresult")
    --				)
    --			)
    --		--if it's a planet or deep-space battle
    --		else
    --			IFText_fnSetUString(this.title.text,
    --				ScriptCB_usprintf("ifs.freeform.resultstring",
    --					ScriptCB_getlocalizestr("planetname." .. ifs_freeform_main.planetSelected),
    --					ScriptCB_getlocalizestr("ifs.freeform.battleresult")
    --				)
    --			)
    --		end

    ifs_freeform_SetButtonVis(this, "back", nil)
    ifs_freeform_SetButtonVis(this, "misc", nil)
    ifs_freeform_SetButtonName(this, "accept", "ifs.freeform.done")
    ifs_freeform_SetButtonVis(this, "help", nil)


    IFObj_fnSetVis(this.player, nil)

    if bFwd then
        -- if the active team won...
        if ifs_freeform_main.playerTeam == ifs_freeform_main.winnerTeam then
            -- if the battle was a fleet battle...
            if ifs_freeform_main.fleetBattle then
                -- play appropriate VO
                if ifs_freeform_main.joystick then
                    ifs_freeform_main:PlayVoice(string.format(ifs_result_fleet_won_sound, ifs_freeform_main.playerSide))
                else
                    ifs_freeform_main:PlayVoice(string.format(ifs_result_fleet_lost_sound, ifs_freeform_main.teamCode[ifs_freeform_main.otherTeam]))
                end
            else
                -- play appropriate VO
                if ifs_freeform_main.joystick then
                    ifs_freeform_main:PlayVoice(string.format(ifs_result_planet_won_sound, ifs_freeform_main.playerSide, ifs_freeform_main.planetSelected))
                else
                    ifs_freeform_main:PlayVoice(string.format(ifs_result_planet_lost_sound, ifs_freeform_main.teamCode[ifs_freeform_main.otherTeam], ifs_freeform_main.planetSelected))
                end
            end
        else
            -- play appropriate VO
            if ifs_freeform_main.joystick then
                ifs_freeform_main:PlayVoice(string.format(ifs_result_fleet_lost_sound, ifs_freeform_main.playerSide))
            elseif ifs_freeform_main.fleetBattle then
                ifs_freeform_main:PlayVoice(string.format(ifs_result_fleet_defend_sound, ifs_freeform_main.teamCode[ifs_freeform_main.otherTeam]))
            else
                ifs_freeform_main:PlayVoice(string.format(ifs_result_planet_defend_sound, ifs_freeform_main.teamCode[ifs_freeform_main.otherTeam], ifs_freeform_main.planetSelected))
            end
        end
    end

    -- update player results
    this:UpdateResult(this.player_result, ifs_freeform_main.playerTeam, ifs_freeform_main.joystick)
    this:UpdateResult(this.enemy_result, ifs_freeform_main.otherTeam, ifs_freeform_main.joystick_other)

    -- if in soak mode...
    if ifs_freeform_main.soakMode then
        -- start a display timer
        this.displayTimer = 5
    end

    -- prompt for save if necessary
    ifs_freeform_main:PromptSave()
end

ifs_freeform_result.Input_Accept = function(this, joystick)
    if(gPlatformStr == "PC") then
        --print( "this.CurButton = ", this.CurButton )
        if( this.CurButton == "_accept" ) then
            -- purchase the item
        else
            return
        end
    end

    ifelm_shellscreen_fnPlaySound(this.acceptSound)

    -- if the player just won a fleet battle over an enemy planet...
    if ifs_freeform_main.planetFleet[ifs_freeform_main.planetNext] == ifs_freeform_main.playerTeam
            and ifs_freeform_main.planetTeam[ifs_freeform_main.planetNext] ~= ifs_freeform_main.playerTeam
            and ifs_freeform_main.planetTeam[ifs_freeform_main.planetNext] ~= 0
            and ifs_freeform_main.planetTeam[ifs_freeform_main.planetNext] ~= nil then


        -- should already be set
        --ifs_freeform_main.otherTeam = ifs_freeform_main.planetTeam[ifs_freeform_main.planetNext]

        -- go to the battle screen again
        ScriptCB_PopScreen()
        ScriptCB_PushScreen("ifs_freeform_battle")
    else
        -- go to the summary screen
        ScriptCB_PushScreen("ifs_freeform_summary")
    end
end

------------------------
-- end ifs_freeform_result
------------------------

------------------------
-- begin ifs_freeform_ai
------------------------

ifs_freeform_ai.UpdateMoveFleet = function(this, fDt)
    print("ifs_freeform_ai.UpdateMoveFleet --------------------------")

    -- get the start and next planet
    local start = ifs_freeform_main.planetSelected
    local next = ifs_freeform_main.planetNext

    -- for each starting planet...
    local playerTeam = ifs_freeform_main.playerTeam
    --local enemyTeam = 3 - playerTeam

    --local helper function to see in tale contains value
    local function has_value (table, val)
        for index, value in ipairs(table) do
            if value == val then
                return true
            end
        end

        return false
    end

    for planet1, destinations in pairs(ifs_freeform_main.planetDestination) do
        -- for each potential destination...
        for _, planet2 in ipairs(destinations) do
            if planet1 < planet2 then
                --					-- get the link team
                --					local planet1Team = ifs_freeform_main.planetFleet[planet1] or ifs_freeform_main.planetTeam[planet1]
                --					local planet2Team = ifs_freeform_main.planetFleet[planet2] or ifs_freeform_main.planetTeam[planet2]
                --					local linkTeam
                --					if planet1Team == planet2Team then
                --						linkTeam = planet1Team
                --					elseif planet1Team == enemyTeam or planet2Team == enemyTeam then
                --						linkTeam = enemyTeam
                --					else
                --						linkTeam = 0
                --					end
                -- color the lane based on the link team
                --					local r,g,b = ifs_freeform_main:GetTeamColor(linkTeam)
                local a = 200
                local shift = 0
                local repetitions = 1
                if planet1 ~= start and planet2 ~= start then
                    a = 32
                elseif next ~= start and (planet1 == next or planet2 == next) then
                    a = 255
                    if planet1 == next then
                        shift = 2 * ScriptCB_GetMissionTime()
                    else
                        shift = -2 * ScriptCB_GetMissionTime()
                    end
                    repetitions = 8
                end
                DrawBeamBetween(
                        ifs_freeform_main.planetMatrix[planet1][0],
                        ifs_freeform_main.planetMatrix[planet2][0],
                        "lane_selected", 1.0, 255, 255, 255, a, shift, repetitions
                )
            end
        end
    end

    this.displayTime = this.displayTime - fDt
    if this.displayTime <= 0 then
        if start ~= next then
            -- move the fleet
            ifs_freeform_main:MoveFleet(playerTeam, start, next)
            ifs_freeform_main:SelectPlanet(nil, next)

            -- show the result
            if this.autoaccept then
                this.displayTime = 1.0
            else
                this.displayTime = 1e38
            end
        else
            -- if the destination planet has another team, or there is a fleet battle...
            if has_value( ifs_freeform_main.otherTeams, ifs_freeform_main.planetTeam[next] ) or
                    ifs_freeform_main.planetFleet[next] == 0 then


                tprint(ifs_freeform_main.fleetPtr, 1)
                -- loop through fleetPtr to see if there is an enemy fleet at the next planet
                local otherFleet
                for fleetTeam, fleetPlanet in ipairs(ifs_freeform_main.fleetPtr) do
                    print("fleet team is " .. tostring(fleetTeam))
                    if fleetTeam ~= playerTeam and fleetTeam ~= 0 and fleetTeam ~= nil
                            and ifs_freeform_main.fleetPtr[fleetTeam][next]then
                        otherFleet = fleetTeam
                        print("ifs_freeform_ai.UpdateMoveFleet otherFleet is " .. tostring(otherFleet))
                    end
                end

                if otherFleet then
                    ifs_freeform_main.otherTeam = otherFleet
                elseif ifs_freeform_main.planetTeam[next] then
                    ifs_freeform_main.otherTeam = ifs_freeform_main.planetTeam[next]
                else
                    print("ifs_freeform_ai.UpdateMoveFleet ERROR could not determine otherTeam")
                end

                ifs_freeform_main.attackTeam = ifs_freeform_main.playerTeam
                ifs_freeform_main.defendTeam = ifs_freeform_main.otherTeam

                rema_database.matchinfo = {
                    attackteam = {
                        number = ifs_freeform_main.attackTeam
                    },
                    defendteam = {
                        number = ifs_freeform_main.defendTeam
                    }
                }

                -- jump to the battle screen
                ScriptCB_PushScreen("ifs_freeform_battle")
            else
                -- jump to the summary page
                ScriptCB_PushScreen("ifs_freeform_summary")
            end
        end
    else
        if start ~= next then
            ifs_freeform_main:DrawFleetIcon(next, playerTeam, true, true)
        end
    end

    -- call common update
    this:UpdateCommon(fDt)
end

-- determine which item to buy
ifs_freeform_ai.CalculatePurchaseItem = function(this, fDt)
    -- default to calculate build fleet
    this.displayTime = -1
    this.Update = this.CalculateBuildFleet

    -- get my team
    local myteam = ifs_freeform_main.playerTeam

    -- selection table
    local totalWeight = 0
    local itemWeight = {}

    local funds = ifs_freeform_main.teamResources[myteam]
    print("funds:", funds)

    print("purchase unit/tech?")

    -- count value of opponent's units
    local enemy_units = 100		-- bias
    for index, teamNumber in ipairs(ifs_freeform_main.otherTeams) do
        for unit, owned in pairs(ifs_purchase_unit_owned[teamNumber]) do
            if owned then
                print ("opponent unit", unit, ifs_purchase_unit_cost[unit])
                enemy_units = enemy_units + ifs_purchase_unit_cost[unit]
            end
        end
    end
    print ("unit scale", enemy_units)

    -- for each potential unit...
    for _, unit in ipairs(ifs_purchase_unit_types) do
        -- if not already owned...
        if not ifs_purchase_unit_owned[myteam][unit] and ifs_purchase_unit_cost[unit] <= funds then
            -- add to the list
            local weight = enemy_units / ifs_purchase_unit_cost[unit]
            local unit = unit		--fix closure
            print ("unit weight", unit, weight)
            itemWeight[function() this:PurchaseUnit(myteam, unit) end] = weight
            totalWeight = totalWeight + weight
        end
    end

    -- check if using slots are free
    local using_free = false
    for slot, using in ipairs(ifs_purchase_tech_using[myteam]) do
        if using == 0 then
            using_free = true
            break
        end
    end

    -- if there are free slots...
    if using_free then
        -- count value of opponent's tech
        local enemy_tech = 40		-- bias
        for index, teamNumber in ipairs(ifs_freeform_main.otherTeams) do
            for _, using in pairs(ifs_purchase_tech_using[teamNumber]) do
                if using > 0 then
                    local tech = ifs_purchase_tech_table[using]
                    print ("opponent tech", tech.name, tech.cost[true])
                    enemy_tech = enemy_tech + tech.cost[true]
                end
            end

        end
        print ("tech scale", enemy_tech)

        -- for each potential tech...
        local totalWeight = 0
        local techWeight = {}
        for index, tech in ipairs(ifs_purchase_tech_table) do
            -- get whether the tech is owned
            local owned = ifs_purchase_tech_cards[myteam][index]

            if tech.cost[owned] <= funds then
                -- add to the list
                local weight = enemy_tech / tech.cost[owned]
                local index = index		-- fix closure
                print ("tech weight", tech.name, weight)
                itemWeight[function() this:PurchaseTech(myteam, index) end] = weight
                totalWeight = totalWeight + weight
            end
        end
    end

    -- pick an item
    local randomWeight = math.random() * totalWeight
    print ("scaled weight:", totalWeight, randomWeight)
    for item, weight in pairs(itemWeight) do
        randomWeight = randomWeight - weight
        if randomWeight <= 0 then
            item()
            break
        end
    end

    -- perform visible update
    this:Update(fDt)
end

-- determine if and where to build a fleet
ifs_freeform_ai.CalculateBuildFleet = function(this, fDt)
    print("ifs_freeform_ai.CalculateBuildFleet -----------------")

    -- default to calculate move fleet
    this.displayTime = -1
    this.Update = this.CalculateMoveFleet

    -- get my team
    local myteam = ifs_freeform_main.playerTeam

    -- update fleet cost
    ifs_freeform_fleet:UpdateFleetCost()

    -- if there is enough resources to build a fleet...
    local funds = ifs_freeform_main.teamResources[myteam]
    local cost = ifs_freeform_fleet.fleetCost
    print("funds:", funds, "fleet cost:", cost)
    if cost and funds >= cost then
        print("purchase fleet?")

        -- create baseline value for my non-fleet planets
        local fleetWeight = {}
        for planet, team in pairs(ifs_freeform_main.planetTeam) do
            if team == myteam and not ifs_freeform_main.planetFleet[planet] then
                fleetWeight[planet] = 1
            end
        end

        -- for each fleet in the galaxy...
        for planet, fleet in pairs(ifs_freeform_main.planetFleet) do
            -- decrease weight for friendly fleets, increase for enemy fleets
            local weight = fleet == myteam and -1 or 1
            -- spread weight around
            for p, scale in pairs(this.weightScale[planet]) do
                if fleetWeight[p] then
                    fleetWeight[p] = fleetWeight[p] + weight * scale
                end
            end
        end

        -- for each potential location...
        local totalWeight = 0
        for planet, weight in pairs(fleetWeight) do
            -- scale by planet value
            fleetWeight[planet] = math.pow(2, 0.2 * this.planetValue[planet] + 2 * fleetWeight[planet])
            print ("planet weight", planet, weight, fleetWeight[planet])
            totalWeight = totalWeight + fleetWeight[planet]
        end
        print ("total weight:", totalWeight)

        -- pick a location
        local scaledWeight = cost == 0 and totalWeight or totalWeight * funds / (funds - cost * 0.75)	--+ (cost - ifs_freeform_fleet_cost[0]) * cost / funds
        local randomWeight = math.random() * scaledWeight
        print ("scaled weight:", scaledWeight, randomWeight)
        for planet, weight in pairs(fleetWeight) do
            randomWeight = randomWeight - weight
            if randomWeight <= 0 then
                print ("purchase fleet:", planet)

                print("before select")
                -- go to update build port
                ifs_freeform_main:SelectPlanet(nil, planet)
                print("after select")
                this.displayTime = 2.0
                this.Update = this.UpdateBuildFleet
                break
            end
        end
    end

    print("before update")
    -- perform visible update
    this:Update(fDt)
    print("after update")
end

------------------------
-- end ifs_freeform_ai
------------------------

------------------------
-- begin ifs_freeform_sides
------------------------

ifs_freeform_sides.Enter = function(this, bFwd)
    gIFShellScreenTemplate_fnEnter(this, bFwd) -- call default enter function

    -- read all controllers
    this.wasRead = ScriptCB_ReadAllControllers(1)

    -- zoom all the way out
    ifs_freeform_main:SetZoom(0)

    -- set side titles
    IFText_fnSetString(this.team1.text, ifs_freeform_main.teamName[1])
    IFText_fnSetString(this.team2.text, ifs_freeform_main.teamName[2])

    -- set side icons
    IFImage_fnSetTexture(this.team1.icon, "seal_" .. ifs_freeform_main.teamCode[1])
    IFObj_fnSetColor(this.team1.icon, ifs_freeform_main:GetTeamColor(1))
    IFImage_fnSetTexture(this.team2.icon, "seal_" .. ifs_freeform_main.teamCode[2])
    IFObj_fnSetColor(this.team2.icon, ifs_freeform_main:GetTeamColor(2))

    -- for each controller...
    this.controllerTeam = {}
    this.controllerReady = {}
    local controllers = ScriptCB_GetMaxControllers()
    for controller = 0,controllers-1 do
        -- if the controller is bound...
        if ScriptCB_IsControllerBound(controller+1) then
            -- set as not ready
            this:SetPlayerReady(controller, 0)

            -- set team
            this:SetPlayerTeam(controller, ifs_freeform_main.controllerTeam[controller])

            -- show name
            IFText_fnSetUString(this.players[controller], ScriptCB_GetProfileName(controller+1))
            IFObj_fnSetVis(this.players[controller], 1)
        else
            -- hide name
            IFObj_fnSetVis(this.players[controller], nil)
        end
    end
end

------------------------
-- end ifs_freeform_sides
------------------------

------------------------
-- begin ifs_freeform_end
------------------------

-- will be called when the galactic conquest game is over (a team overall victory)
ifs_freeform_end.Enter = function(this)
    gIFShellScreenTemplate_fnEnter(this, bFwd)

    print("ifs_freeform_end.Enter() ----------------------------------")

    --TODO figure out how to go back to human player team
    -- switch teams if on the AI's turn
    if not ifs_freeform_main.joystick and ifs_freeform_main.joystick_other then
        ifs_freeform_main:SetActiveTeam(3 - ifs_freeform_main.playerTeam)
    end

    -- if the active player won...
    if ifs_freeform_main.teamVictory == ifs_freeform_main.playerTeam then
        -- show the victory display
        IFImage_fnSetUVs(this.message.image, 0, 0, 1, 0.5)
    else
        -- show the defeat display
        IFImage_fnSetUVs(this.message.image, 0, 0.5, 1, 1)
    end

    -- set the appropriate color
    IFObj_fnSetColor(this.message.image, ifs_freeform_main:GetTeamColor(ifs_freeform_main.teamVictory))

    -- set the message text
    local sideVictory = ifs_freeform_main.teamCode[ifs_freeform_main.teamVictory]
    IFText_fnSetString(this.message.text, "ifs.freeform.victory." .. sideVictory)

    -- set alpha to zero
    IFObj_fnSetVis(this.message, true)
    IFObj_fnSetAlpha(this.message.image, 0)
    IFObj_fnSetAlpha(this.message.text, 0)

    -- play a movie
    gMovieAlwaysPlay = 1
    ScriptCB_CloseMovie()
    ScriptCB_OpenMovie(gMovieStream, "")
    ifelem_shellscreen_fnStartMovie("gcwin" .. sideVictory .. "1", 0, nil, 1)
    if ScriptCB_IsMoviePlaying() then
        this.moviePlaying = true
        ScriptCB_EnableScene(false)
        ScriptCB_SetShellMusic()
        ScriptCB_SndBusFade("shellfx", 0.0, 0.0)
        StopAudioStream(gVoiceOverStream, 0)
        StopAudioStream(gMusicStream, 0)
    else
        this.moviePlaying = false
    end

    -- display timer
    this.displayTimer = 0
end

------------------------
-- end ifs_freeform_end
------------------------