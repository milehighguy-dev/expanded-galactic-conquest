-- override main script

ifs_freeform_main.OneTimeInit = function(this, showLoadDisplay)

    print(">>>>>>>>>>>>>>>>>>>> IN OneTimeInit")
    print(">>>>>>>>>>>>>>>>>>>> about to load state")
    -- restore any saved metagame state
    if ScriptCB_IsMetagameStateSaved() then
      this:LoadState()
    end
    print(">>>>>>>>>>>>>>>>>>>> finished loading state")


    -- plandest is the connectivity graph between planets
    local plandest = tostring(this.planetDestination) or "nil"
    print(">>>>>>>>>>>>>>>>>>>> OneTimeInit: this.planetDestination is: " .. tostring(plandest))
    --check if planetDestination is not nil
    if not this.planetDestination then
      print(">>>>>>>>> OneTimeInit: in not planetDestination")
      
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

        print(">>>>>>>>>>>>>>>> about to print this.teamCode")
        tprint(this.teamCode, 3)
      -- load sides
      ifs_purchase_load_data(this.teamCode[1], this.teamCode[2])

      -- read the galaxy map level
      ReadDataFile("gal\\gal1.lvl")
      
      -- read the galaxy map level
      ReadDataFile("sound\\gal.lvl;gal_vo")
      
      this.streamVoice = OpenAudioStream("sound\\gal.lvl",  "gal_vo_slow")
      this.streamMusic = OpenAudioStream("sound\\gal.lvl",  "gal_music")

      ScriptCB_PostLoadHack()

      -- hide the load display
      if showLoadDisplay then
        ScriptCB_ShowLoadDisplay(false)
        ClearTempHeap()
      end 

      print("about to do this.Setup")
      -- perform one-time setup
      this:Setup()
      
      -- create empty port array
      this.portPtr = { }
      
      -- create empty fleet array
      this.fleetPtr = { [1] = {}, [2] = {}, [3] = {}, [4] = {} }
      
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

    print(">>>>>>>>>>>>>>> starting Enter function")

    if bFwd then
        -- stop any playing movie
        ifelem_shellscreen_fnStopMovie()

        -- disable split screen
        this.wasSplit = ScriptCB_GetNumCameras()
        print(">>>>>>>>>>> was it split screen? " .. this.wasSplit)

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
            print(">>>>>>>>>>>> about to print this.planetBase")
            tprint(this.planetBase,3)
            for team, planet in pairs(this.planetBase) do
                if not this.lastSelected[team] then
                    this.lastSelected[team] = planet
                end
            end



            -- set the active team to that of the starting controller
            this:SetActiveTeam(this.controllerTeam[this.startController])
            this.planetNext = this.lastSelected[this.playerTeam]


            print(">>>>>>>>>>>>>>>>>> about to print this.planetNext " .. tostring(this.planetNext))
            print(">>>>>>>>>>>>>>>>>>>>>>>>>>>> about to print this.lastSelected")
            tprint(this.lastSelected, 3)

            -- clear state
            this.launchMission = nil
            this.activeBonus = {}
            this.recentPlanets = {}
        end

        -- if the last battle had a winner...
        local winner = ScriptCB_GetLastBattleVictory()
        if this.soakMode and ScriptCB_IsMetagameStateSaved() then
            winner = math.random(2)
        end
        if winner > 0 then
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
        this.fleetPtr = { [1] = {}, [2] = {}, [3] = {}, [4] = {} }
        for planet, team in pairs(this.planetFleet) do
            if team == 0 then
                this.fleetPtr[1][planet] = CreateEntity(this.fleetClass[1], this.modelMatrix[planet][1])
                this.fleetPtr[2][planet] = CreateEntity(this.fleetClass[2], this.modelMatrix[planet][2])
                this.fleetPtr[3][planet] = CreateEntity(this.fleetClass[2], this.modelMatrix[planet][3])
                this.fleetPtr[4][planet] = CreateEntity(this.fleetClass[2], this.modelMatrix[planet][4])
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

-- set the active team
ifs_freeform_main.SetActiveTeam = function(this, team)
    print(">>>>>>>> in setActiveTeam")
    print(">>>>>>>>> team is " .. team)
    this.playerTeam = team
    this.playerSide = this.teamCode[team]
    print(">>>>>>>>> playerSide is " .. this.playerSide)
    --this.otherSide = this.teamCode[3 - team]
    --print(">>>>>>>>> otherSide is " .. this.otherSide)

    print(">>>>>>>>>>>>>>> printing this.teamController")
    tprint(this.teamController, 3)

    this.joystick = this.teamController[team]
    print(">>>>>>>>> joystick is " .. tostring(this.joystick))
    --TODO update joystick_other
    this.joystick_other = this.teamController[3 - team]
    print(">>>>>>>>> joystick_other is " .. tostring(this.joystick_other))
    ScriptCB_SetHotController((this.joystick or this.joystick_other or 0)+1)

    print(">>>>>>>>>>>> about to print this.planetFleet")
    tprint(this.planetFleet,3)
    print(">>>>>>>>>>>>>>> about to print this.planetTeam")
    tprint(this.planetTeam, 3)

    -- update dependent values
    ifs_freeform_purchase_unit:SetActiveSide()
end

-- set up team colors
ifs_freeform_main.InitTeamColor = function(this)
    print(">>>>>>>>>>> in InitTeamColor")

    -- precomputed colors
    local colorWhite = { r=255, g=255, b=255 }
    local colorBlue = { r=32, g=96, b=255 }
    local colorRed = { r=255, g=32, b=32 }
    local colorGreen = { r=0, g=255, b=0 }
    local colorOrange = { r=255, g=150, b=0 }

    if this.teamController then
        print(">>>>>>>>>> printing teamController")
        tprint(this.teamController, 3)
    end
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

-- NEW function
-- will check if there is an enemy fleet at current position and return that team
-- if no enemy fleet will check the team of the enemy planet and return that team
-- if there is no enemy at the destination returns 0 (neutral team)
ifs_freeform_main.GetEnemyTeam = function(this, planet, team)
    --the team that
    local myTeam = team

    print(">>>>>>>>>>>>>>>>> IN GET ENEMY TEAM")

    -- team of the fleet at current planet/ star. May or may not have a fleet here
    local teamOfFleetAtPlanet = this.planetFleet[planet]

    -- team of the planet we are at
    local teamOfPlanet = this.planetTeam[planet]

    -- if there is such a fleet
    if teamOfFleetAtPlanet then
        print(">>>>>>>>>>>>>>>>>> Fleet exists at planet " .. tostring(planet) .. " team is " .. tostring(teamOfFleetAtPlanet))
        -- if it is not my team
        if teamOfFleetAtPlanet ~= myTeam and teamOfFleetAtPlanet ~= 0 then

            -- return the team
            return teamOfFleetAtPlanet
        end
    end
    -- the planet has a team
    if teamOfPlanet then
        print(">>>>>>>>>>>>>>>>>> Planet " .. tostring(planet) .. " team is " .. tostring(teamOfPlanet))
        --if it is not my team
        if teamOfPlanet ~= myTeam and teamOfPlanet ~= 0 then

            --return the team
            return teamOfPlanet
        end
    end

    print(">>>>>>>>>>>>>> GetEnemyTeam: Neutral Team at planet " .. tostring(planet))
    return 0

end

-- create a fleet with the specified team on the specified planet
ifs_freeform_main.CreateFleet = function(this, team, planet)
    -- add the fleet to the planet
    if not this.planetFleet[planet] then
        this.planetFleet[planet] = team
    elseif this.planetFleet[planet] ~= team and this.planetFleet[planet] ~= 0 and this.planetTeam[planet] ~= nil then
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

    local enemyTeam = 3 - team

    --select the enemy team based on last teams involved
    for i, team in ipairs(ifs_freeform_main.lastTeamList) do
        print( tostring(ifs_freeform_main.lastTeamList[i]))
        if ifs_freeform_main.lastTeamList[i] ~= team then
            enemyTeam = ifs_freeform_main.lastTeamList[i]
        end
    end

    -- remove the fleet from the planet
    if this.planetFleet[planet] == 0 then
        this.planetFleet[planet] = enemyTeam
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

    print(" >>>>>>>>>>>>>>>>>>>>>>>>>> IN MOVEFLEET <<<<<<<<<<<<<<<<<<<<<<<")

    print(">>>>>>>>>>>>>>>>>>>>>>>>>>> this fleetPtr is " .. tostring(this.fleetPtr[team][start]))

    -- save the fleet object
    local fleetPtr = this.fleetPtr[team][start]

    -- remove the fleet from the start planet
    this.fleetPtr[team][start] = nil
    if this.planetFleet[start] == 0 then
        this.planetFleet[start] = this:GetEnemyTeam(start, team)
    elseif this.planetFleet[start] == team then
        this.planetFleet[start] = nil
    end

    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MOVEFLEET: got here 1")

    -- update the fleet's position
    SetEntityMatrix(fleetPtr, this.modelMatrix[next][team])

    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MOVEFLEET: got here 2")

    -- add the fleet to the next planet
    this.fleetPtr[team][next] = fleetPtr
    if not this.planetFleet[next] then
        print(">>>>>>>>>>>>>>>>>>>>>>>>> adding " .. tostring(team) .. " to planet " .. tostring(next))
        this.planetFleet[next] = team
    elseif this.planetFleet[next] ~= team and this.planetFleet[next] ~= 0 and this.planetFleet[next] ~= nil then
        print(">>>>>>>>>>>>>>>>>>>>>>>> ENEMY team found at next planet " .. tostring(next) .. " team is " .. tostring(this.planetFleet[next]))
        this.lastTeamList = { team, this.planetFleet[next] }
        --TODO figure out if this is the best place to get the current team and enemy team before they engage in battle

        this.planetFleet[next] = 0
    end

    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MOVEFLEET: got here 3")

    -- update the last fleet
    this.lastFleet[team] = next
end

-- apply battle results for the specified planet
ifs_freeform_main.ApplyBattleResult = function(this, planet, winner)
    -- save which team won
    this.winnerTeam = winner

    print(">>>>>>>>>>>>> ApplyBattleResult, winning team is: " .. tostring(winner))

    -- save whether the battle was a fleet battle
    this.fleetBattle = this.planetFleet[planet] == 0
    print(">>>>>>>>>>>>>ApplyBattleResult, fleetBattle team is: " .. tostring(this.fleetBattle))

    print(">>>>>>>>>>>>>>>>>ApplyBattleResult, lastTeamList is " .. tostring(this.lastTeamList))
    -- get the losing team
    local loser = this.lastTeamList[1]

    local tempTeamList = this.lastTeamList

    for i, team in ipairs(tempTeamList) do
        print( tempTeamList[i])
        if tempTeamList[i] ~= winner then
            loser = tempTeamList[i]
        end
    end

    -- clear out this variable
    --this.lastTeamList = nil

    --this:GetEnemyTeam(planet, winner)

    print(">>>>>>>>>>>>> ApplyBattleResult, losing team is: " .. tostring(loser))

    ---- debug

    print(">>>>>>>>>>>> about to print this.planetFleet")
    tprint(this.planetFleet,3)
    print("LALALALALA  >>>>>>>>>>>>>>> about to print this.planetTeam")
    tprint(this.planetTeam, 3)

    print(">>>>>>>>>>>>>>>>>> about to print this.planetNext " .. tostring(this.planetNext))
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>> about to print this.lastSelected")
    tprint(this.lastSelected, 3)
    ----

    -- create if necessary
    this.planetResources = this.planetResources or {}
    this.battleResources = this.battleResources or {}

    -- no planet resources yet
    this.planetResources[winner] = 0
    this.planetResources[loser] = 0

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

        -- add per-turn resource units per planet
        for planet, team in pairs(this.planetTeam) do
            if team ~= 0 then
                this.planetResources[team] = this.planetResources[team] + this.planetValue[planet].turn
            end
        end
    end

    -- give each team its added resources
    this:AddResources(winner, this.battleResources[winner] + this.planetResources[winner])
    this:AddResources(loser, this.battleResources[loser] + this.planetResources[loser])

    -- remove the loser's fleet, if any
    if this.fleetBattle or this.planetFleet[planet] == loser then
        AttachEffectToMatrix(CreateEffect(this.fleetExplosion[loser]), this.modelMatrix[planet][loser])
    end
    this:DestroyFleet(loser, planet)

    -- add the planet to the battle list (for AI)
    this.recentPlanets = this.recentPlanets or {}
    if this.planetTeam[planet] and this.planetTeam[planet] > 0 then
        this.recentPlanets[3] = nil
        table.insert(this.recentPlanets, 1, planet)
    end
end

-- go to the next turn
ifs_freeform_main.NextTurn = function(this)
    -- clear the screen stack
    ScriptCB_PopScreen("ifs_freeform_main")

    print(">>>>>>>>>>>>>>>>>>>>>>> about to print this.fleetPtr")
    tprint(this.fleetPtr, 3)

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

        --TODO iterate through all teams

        local nextTeam = this.playerTeam
        for teamNumber, teamString in ipairs(this.teamCode) do

            print("team number is " .. teamNumber)

            if teamNumber == this.playerTeam then

                print("team is the same as player team")

                -- if there is another team after this one select that
                if this.teamCode[ teamNumber + 1 ] then
                    nextTeam = teamNumber + 1
                    print(">>>>>>>>>>>>>>>>> selected for next team:" .. tostring(this.teamCode[teamNumber + 1]))
                else
                    -- else start at beginning
                    nextTeam = 1 -- arrays start at 1
                    print(">>>>>>>>>>>>>>>>> selected for next team:" .. tostring(this.teamCode[1]))
                end
            else
                print("ERROR: player team not found in this.teamCode table")
            end
        end

        this:SetActiveTeam(nextTeam)

        this:SelectPlanet(nil, this.lastSelected[this.playerTeam])

        -- clear state
        this.launchMission = nil
        this.activeBonus = {}

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

ifs_freeform_fleet.AttemptMove = function(this, team, start, next)
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

    print(">>>>>>>>>>>>AttemptMove: about to print this.planetFleet")
    tprint(ifs_freeform_main.planetFleet,3)
    print(">>>>>>>>>>>>>>>AttemptMove: about to print this.planetTeam")
    tprint(ifs_freeform_main.planetTeam, 3)
    print(">>>>>>>>>>>>>>>AttemptMove: about to print this.lastFleet " .. tostring(ifs_freeform_main.lastFleet))
    tprint(ifs_freeform_main.lastFleet, 3)

    print(">>>>>>>>>>>>>>>AttemptMove: about to print this.lastSelected " .. tostring(ifs_freeform_main.lastSelected))
    tprint(ifs_freeform_main.lastSelected, 3)

    print(">>>>>>>>>>>>>>>>>>AttemptMove: MY team " .. tostring(team))
    print(">>>>>>>>>>>>>>>>>>AttemptMove: TEAM AT DESTINATION PLANET team " .. tostring(ifs_freeform_main.planetTeam[next]))
    print(">>>>>>>>>>>>>>>>>>AttemptMove: TEAM AT DESTINATION FLEET team " .. tostring(ifs_freeform_main.planetFleet[next]))
    -- if the destination planet is an enemy, or there is a fleet battle...
    --TODO add this nil check to other similar checks
    if ifs_freeform_main.planetTeam[next] ~= team and ifs_freeform_main.planetTeam[next] ~= 0 and ifs_freeform_main.planetTeam[next] ~= nil or
            ifs_freeform_main.planetFleet[next] == 0 then
        print(">>>>>>>>>>>>>>>>>>>> ATTEMPT MOVE: MOVING TO BATTLE SCREEN, planet team is " .. tostring(ifs_freeform_main.planetTeam[next])
        .. "planet fleet is " .. tostring(ifs_freeform_main.planetFleet[next]))
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
    this.turnNumber,
    this.curScreen,
    ifs_freeform_fleet.turnNumber,
    ifs_freeform_fleet.planetStart,
    ifs_freeform_fleet.planetNext,
    this.launchMission,
    this.activeBonus,
    this.winnerTeam,
    this.lastTeamList,
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
            this.turnNumber,
            this.curScreen,
            ifs_freeform_fleet.turnNumber,
            ifs_freeform_fleet.planetStart,
            ifs_freeform_fleet.planetNext,
            this.launchMission,
            this.activeBonus,
            this.winnerTeam,
            this.lastTeamList,
            this.fleetBattle,
            this.recentPlanets,
            this.planetResources,
            this.battleResources,
            this.soakMode
    )
end

ifs_freeform_main.SetVictoryPlanetLimit = function(this, limit)
    print("SetVictoryPlanetLimit" .. tostring(limit))
    this.CheckVictory = function(this)
        print("CheckVictoryPlanetLimit" .. tostring(limit))
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

                        --TODO loop through all fleets in fleetPtr that do not belong to 'team'. return nil if any exist
                        --that way we know there are no enemy fleets left

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

    --select the otherside based on last teams involved
    for i, team in ipairs(ifs_freeform_main.lastTeamList) do
        print( tostring(ifs_freeform_main.lastTeamList[i]))
        if ifs_freeform_main.lastTeamList[i] ~= winner then
            ifs_freeform_main.otherSide = ifs_freeform_main.lastTeamList[i]
        end
    end

    -- play appropriate VO messages and display caption and info text
    --if it's a deep space battle
    if not ifs_freeform_main.planetTeam[ifs_freeform_main.planetSelected] then
        if ifs_freeform_main.joystick then
            ifs_freeform_main:PlayVoice(string.format(ifs_battle_fleet_sound, ifs_freeform_main.playerSide, "us"))
        else
            ifs_freeform_main:PlayVoice(string.format(ifs_battle_fleet_sound, ifs_freeform_main.otherSide, "them"))
        end
        IFObj_fnSetVis(this.info, true)
        IFText_fnSetString(this.info.caption, "ifs.freeform.spacebattle")
        IFObj_fnSetVis(this.info.text, false)
        --if it's a space battle over a planet
    elseif ifs_freeform_main.planetFleet[ifs_freeform_main.planetSelected] == 0 then
        if ifs_freeform_main.joystick then
            ifs_freeform_main:PlayVoice(string.format(ifs_battle_fleet_sound, ifs_freeform_main.playerSide, "us"))
        else
            ifs_freeform_main:PlayVoice(string.format(ifs_battle_fleet_sound, ifs_freeform_main.otherSide, "them"))
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
            ifs_freeform_main:PlayVoice(string.format(ifs_battle_planet_sound, ifs_freeform_main.otherSide, ifs_freeform_main.planetSelected, "them"))
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

ifs_freeform_result.Enter = function(this, bFwd)
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

    --select the otherside based on last teams involved
    for i, team in ipairs(ifs_freeform_main.lastTeamList) do
        print( tostring(ifs_freeform_main.lastTeamList[i]))
        if ifs_freeform_main.lastTeamList[i] ~= winner then
            ifs_freeform_main.otherSide = ifs_freeform_main.lastTeamList[i]
        end
    end

    if bFwd then
        -- if the active team won...
        if ifs_freeform_main.playerTeam == ifs_freeform_main.winnerTeam then
            -- if the battle was a fleet battle...
            if ifs_freeform_main.fleetBattle then
                -- play appropriate VO
                if ifs_freeform_main.joystick then
                    ifs_freeform_main:PlayVoice(string.format(ifs_result_fleet_won_sound, ifs_freeform_main.playerSide))
                else
                    ifs_freeform_main:PlayVoice(string.format(ifs_result_fleet_lost_sound, ifs_freeform_main.otherSide))
                end
            else
                -- play appropriate VO
                if ifs_freeform_main.joystick then
                    ifs_freeform_main:PlayVoice(string.format(ifs_result_planet_won_sound, ifs_freeform_main.playerSide, ifs_freeform_main.planetSelected))
                else
                    ifs_freeform_main:PlayVoice(string.format(ifs_result_planet_lost_sound, ifs_freeform_main.otherSide, ifs_freeform_main.planetSelected))
                end
            end
        else
            -- play appropriate VO
            if ifs_freeform_main.joystick then
                ifs_freeform_main:PlayVoice(string.format(ifs_result_fleet_lost_sound, ifs_freeform_main.playerSide))
            elseif ifs_freeform_main.fleetBattle then
                ifs_freeform_main:PlayVoice(string.format(ifs_result_fleet_defend_sound, ifs_freeform_main.otherSide))
            else
                ifs_freeform_main:PlayVoice(string.format(ifs_result_planet_defend_sound, ifs_freeform_main.otherSide, ifs_freeform_main.planetSelected))
            end
        end
    end

    -- update player results
    this:UpdateResult(this.player_result, ifs_freeform_main.playerTeam, ifs_freeform_main.joystick)
    this:UpdateResult(this.enemy_result, ifs_freeform_main.otherSide, ifs_freeform_main.joystick_other)

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
            and ifs_freeform_main.planetTeam[ifs_freeform_main.planetNext] ~= 0 then

        -- go to the battle screen again
        ScriptCB_PopScreen()
        ScriptCB_PushScreen("ifs_freeform_battle")
    else
        -- go to the summary screen
        ScriptCB_PushScreen("ifs_freeform_summary")
    end
end -- Input_Accept

ifs_freeform_ai.UpdateMoveFleet = function(this, fDt)
    -- get the start and next planet
    local start = ifs_freeform_main.planetSelected
    local next = ifs_freeform_main.planetNext

    -- for each starting planet...
    local playerTeam = ifs_freeform_main.playerTeam
    --local enemyTeam = 3 - playerTeam
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
            -- if the destination planet is an enemy, or there is a fleet battle...
            if ifs_freeform_main.planetTeam[next] ~= ifs_freeform_main.playerTeam and ifs_freeform_main.planetTeam[next] ~= 0 or
                    ifs_freeform_main.planetFleet[next] == 0 then

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

--TODO update enemy team calc
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
    for unit, owned in pairs(ifs_purchase_unit_owned[3-myteam]) do
        if owned then
            print ("opponent unit", unit, ifs_purchase_unit_cost[unit])
            enemy_units = enemy_units + ifs_purchase_unit_cost[unit]
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
        for _, using in pairs(ifs_purchase_tech_using[3-myteam]) do
            if using > 0 then
                local tech = ifs_purchase_tech_table[using]
                print ("opponent tech", tech.name, tech.cost[true])
                enemy_tech = enemy_tech + tech.cost[true]
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

ifs_freeform_battle_card.Next = function(this)


    --select the enemy team based on last teams involved
    local enemyTeam = 3 - ifs_freeform_main.playerTeam

    for i, team in ipairs(ifs_freeform_main.lastTeamList) do
        print( tostring(ifs_freeform_main.lastTeamList[i]))
        if ifs_freeform_main.lastTeamList[i] ~= ifs_freeform_main.playerTeam then
            enemyTeam = ifs_freeform_main.lastTeamList[i]
        end
    end

    if this.defending then
        -- switch to the attacker
        this.defending = nil
        ifs_freeform_main:SetActiveTeam(enemyTeam)

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
        ifs_freeform_main:SetActiveTeam(enemyTeam)

        -- re-enter as the defender
        ScriptCB_PushScreen("ifs_freeform_battle_card")
    end
end

--TODO probably dont need to update since we will not use cheat menu
ifs_freeform_cheat.Input_Accept = function(this)
    -- If base class handled this work, then we're done
    if(gShellScreen_fnDefaultInputAccept(this)) then
        return
    end

    ifelm_shellscreen_fnPlaySound(this.acceptSound)

    if (this.CurButton == "nextturn") then
        this.main:NextTurn()
    elseif (this.CurButton == "10credits") then
        this.main:AddResources(this.main.playerTeam, 10)
    elseif (this.CurButton == "100credits") then
        this.main:AddResources(this.main.playerTeam, 100)
    elseif (this.CurButton == "1000credits") then
        this.main:AddResources(this.main.playerTeam, 1000)
    elseif (this.CurButton == "setplayerplanet") then
        this.main.planetTeam[this.main.planetSelected] = this.main.playerTeam
    elseif (this.CurButton == "addplayerfleet") then
        this.main:CreateFleet(this.main.playerTeam, this.main.planetSelected)
    elseif (this.CurButton == "delplayerfleet") then
        this.main:DestroyFleet(this.main.playerTeam, this.main.planetSelected)
    elseif (this.CurButton == "setenemyplanet") then
        this.main.planetTeam[this.main.planetSelected] = 3 - this.main.playerTeam
    elseif (this.CurButton == "addenemyfleet") then
        this.main:CreateFleet(3 - this.main.playerTeam, this.main.planetSelected)
    elseif (this.CurButton == "delenemyfleet") then
        this.main:DestroyFleet(3 - this.main.playerTeam, this.main.planetSelected)
    end
end

ifs_freeform_end.Enter = function(this)
    gIFShellScreenTemplate_fnEnter(this, bFwd)

    --select the enemy team based on last teams involved
    local enemyTeam = 3 - ifs_freeform_main.playerTeam

    for i, team in ipairs(ifs_freeform_main.lastTeamList) do
        print( tostring(ifs_freeform_main.lastTeamList[i]))
        if ifs_freeform_main.lastTeamList[i] ~= ifs_freeform_main.playerTeam then
            enemyTeam = ifs_freeform_main.lastTeamList[i]
        end
    end

    -- switch teams if on the AI's turn
    if not ifs_freeform_main.joystick and ifs_freeform_main.joystick_other then
        ifs_freeform_main:SetActiveTeam(enemyTeam)
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

    --TODO finish this part
    -- for team in teamCode
    --local nextTeam = this.playerTeam
    --for teamNumber, teamString in ipairs(this.teamCode) do
    --
    --    -- set side titles
    --    IFText_fnSetString(this.team1.text, ifs_freeform_main.teamName[teamNumber])
    --
    --    -- set side icons
    --    IFImage_fnSetTexture(this.team1.icon, "seal_" .. ifs_freeform_main.teamCode[teamNumber])
    --    IFObj_fnSetColor(this.team1.icon, ifs_freeform_main:GetTeamColor(teamNumber))
    --
    --end

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