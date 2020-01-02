---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Ben.
--- DateTime: 1/1/2020 8:23 PM
---

ifs_freeform_main.screenStack = {}

gOriginalPushScreen = ScriptCB_PushScreen

ScriptCB_PushScreen = function(screen)
    print("ScriptCB_PushScreen " .. tostring(screen))
    if screen then
        table.insert(ifs_freeform_main.screenStack, screen)
        tprint(ifs_freeform_main.screenStack)
        gOriginalPushScreen(screen)
    else
        print("ScriptCB_PushScreen: no screen provided. This should not happen?")
        gOriginalPushScreen()
    end
end

gOriginalPopScreen = ScriptCB_PopScreen

ScriptCB_PopScreen = function(screen)
    print("ScriptCB_PopScreen " .. tostring(screen))
    if screen then
        print("ScriptCB_PopScreen: is screen in stack? " .. tostring(ScriptCB_IsScreenInStack(screen)))

        --if ScriptCB_IsScreenInStack(screen) then
            local startIndex = nil
            for index, screenName in ipairs(ifs_freeform_main.screenStack) do
                if screenName == screen then
                    startIndex = index
                    print("popping screen " .. tostring(screen) .. " at index " .. index)
                end
            end

            if startIndex then
                print("start index is " .. tostring(startIndex))
                --count backwards clearing the stack
                for endIndex = table.getn(ifs_freeform_main.screenStack), startIndex, -1 do
                    print("popping index " .. tostring(endIndex))
                    table.remove(ifs_freeform_main.screenStack, endIndex)
                end
            end
            --for index, screenName in ipairs(ifs_freeform_main.screenStack) do
            --    if index >= startIndex then
            --        print("popping screen " .. tostring(screenName))
            --        screenName = nil
            --    end
            --end

        --end
        tprint(ifs_freeform_main.screenStack)
        gOriginalPopScreen(screen)
    else
        print("ScriptCB_PopScreen: popping last screen")
        table.remove(ifs_freeform_main.screenStack)
        tprint(ifs_freeform_main.screenStack)
        gOriginalPopScreen()
    end
end