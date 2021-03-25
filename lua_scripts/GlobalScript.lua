--Runs whenever game is saved/autosaved
selectedModel = nil

function onSave()
    local data_to_save = {}
    saved_data = JSON.encode(data_to_save)
    --saved_data = "" --Remove -- at start + save to clear save data
    return saved_data
end

--Runs when game is loaded.
function onLoad(saved_data)
    --Loads the tracking for if the game has started yet
    --This recalls the state of the "toggle"
    
    if saved_data ~= "" then
        local loaded_data = JSON.decode(saved_data)
        selectedModel = nil
    else
        selectedModel = nil
    end
    --This hides the roll buttons on launch if the tool was toggled off
    
    UI.setAttribute("moveButtons", "active", false)
    UI.setAttribute("modelGlobalHud", "height", 40)
    
    --If you intend to use this, I would recommend using math.randomseed here
end

--Hides the welcome message
function hideWelcome()
    UI.hide("welcome")
end

function openModelGlobalHUD(player)
    selectedModel = player.getSelectedObjects()
    print(selectedModel.getGUID())
    UI.setAttribute("moveButtons", "active", true)
    UI.setAttribute("modelGlobalHud", "height", 280)
end

function closesModelGlobalHUD()
    selectedModel = nil
    UI.setAttribute("moveButtons", "active", false)
    UI.setAttribute("modelGlobalHud", "height", 40)
end

-- --This toggles showing or hiding the roll buttons
-- function toggleRollerButtons()
--     if rollerToggle then
--         --UI.show("rollerButtons")
--         UI.setAttribute("moveButtons", "active", true)
--         UI.setAttribute("modelGlobalHud", "height", 280)
--     else
--         --UI.hide("rollerButtons")
--         UI.setAttribute("moveButtons", "active", false)
--         UI.setAttribute("modelGlobalHud", "height", 40)
--     end
--     --This flips between true/false for show/hide
--     rollerToggle = not rollerToggle
-- end

--Activated by roll buttons, this gets a random value and prints it
function moveModel(player, _, idValue)
    --idValue is the "id" value of the XML button
    roll = math.random(idValue)
    str = player.steam_name .. " rolled a " .. roll .. " out of " .. idValue
    broadcastToAll(str, {1,1,1})
end