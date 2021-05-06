referenceCardsContainerGUID = "000888"
upgradeContainerGUID = "000777"
controllerGUID = "e894f6"

referenceCardsContainerObject = nil
upgradeContainerObject = nil
playerColor = ''
local workInProgress = false;

basePositionBlue = {x= -22, y=1.5,z=14}
basePositionRed = {x= 22, y=1.5,z=-14}

spawnedRefCards = {}
local Factions = {};
Factions["Explorer's Society"] = Color(0/255, 114/255, 111/255);
Factions["Resurrectionist"] = Color(37/255, 136/255, 69/255);
Factions["Arcanists"] = Color(0/255, 90/255, 154/255);
Factions["Guild"] = Color(191/255, 26/255, 33/255);
Factions["Outcasts"] = Color(181/255, 143/255, 18/255);
Factions["Neverborn"] = Color(95/255, 53/255, 129/255);
Factions["Bayou"] = Color(145/255, 93/255, 35/255);
Factions["Ten Thunders"] = Color(208/255, 95/255, 36/255);

function onload(saved_data)
    createAll()
end

function updateSave()
end

function createAll()
    s_color = {0.5, 0.5, 0.5, 95}
    f_color = {0,0,0,1}
    self.createButton({
      label="Retrieve Crew",
      click_function="retrieve_crew_ui",
      tooltip=ttText,
      function_owner=self,
      position={0,1,0.6},
      height=30,
      width=300,
      
      scale={x=-0.6, y=1, z=-0.6},
      font_size=30,
      font_color=f_color,
      color={0.8,0.8,0.9,1}
      })
end

function removeAll()
    self.removeButton(0)
end

function reloadAll()
    removeAll()
    createAll()
    updateSave()
end

function retrieve_crew_ui(_obj, _color, alt_click)
    if workInProgress == false then
        workInProgress = true;
        Wait.time( function() workInProgress =false;end,10);
        if _color ~= 'Red' and _color ~= 'Blue' then
            broadcastToAll("Please Select Color first, only Blue and Red are Valid");
        else
            playerColor = _color
            retrieve_crew()
        
        end
    else
        GetPlayerFromColor(playerColor).broadcast("Retrieving the crew wait 10 seconds pls",_color)
    end
end

function retrieve_crew()
    for key,refCard in pairs(spawnedRefCards) do
        if refCard ~= nil and not refCard.isDestroyed() then
            refCard.call("destruct", {})
            refCard.destruct()
        end
    end
    spawnedRefCards = {}
    local placingReferences = false
   
    if referenceCardsContainerObject == nil then
        referenceCardsContainerObject = getObjectFromGUID(referenceCardsContainerGUID)
    end
    if upgradeContainerObject == nil then
        upgradeContainerObject = getObjectFromGUID(upgradeContainerGUID)
    end

    local modelPosition = 0
   local description = self.getData().Description
   local separatedCrew = mysplit(description)
   
   local faction = getFaction(separatedCrew[1])
   GetPlayerFromColor(playerColor).broadcast("Retrieving '"..separatedCrew[1].."' crew ",Color[playerColor])
   for key,value in pairs(separatedCrew) do
    local starterCharacter = string.sub(value, 1, 2)
    if starterCharacter == '  ' then
      local entity = string.sub(value, 3)
      local secondCharacter = string.sub(entity, 1, 2)
      if secondCharacter == '  ' then
        spawnUpgrade(string.sub(entity, 3),modelPosition)
        print('upgrade: ' .. string.sub(entity, 3))
      else
        spawnModel(entity,modelPosition,faction,placingReferences)
        print('model: ' .. entity)
        if placingReferences == false then
            modelPosition = modelPosition +1
        end
        
      end
    else
        if value == 'References:' then
            placingReferences = true    
            modelPosition = modelPosition + 2
        end

    end
    
   end
end
-- player board
--2 - Guild, 3 - Arcanist, 4 - Resurrectionnists, 5 - Neverborn, 6 -Ten thunders, 7 - Outcast, 8 - Explorer, 9 - Bayou

function getFaction(firstCrewLine)
    for faction,color in pairs(Factions) do
        if ends_with(firstCrewLine,"(".. faction ..")") then
            return faction;
        end
    end
end

function spawnModel ( modelName,modelSlot,faction,isReference)
    ismodel = false;
    local found = 0;
    local color = Factions[faction];
    for key,containedObject in pairs(referenceCardsContainerObject.getObjects()) do
        local isEquivalentModel = containedObject.name == modelName;
        if isReference then
            isEquivalentModel = starts_with(containedObject.name,modelName);
            
        end
        if isEquivalentModel then
            ismodel = true
            referenceCardsContainerObject.takeObject({
                index = containedObject.index - found,
                position =  getSlotPosition(modelSlot):add(Vector(0,1,0)),
                rotation = getSlotRotation(),
                callback_function = function(spawnedObject)
                    spawnedObject.clone({position=referenceCardsContainerObject.getPosition(),rotation={x=0,y=180,z=0}})
                    spawnedObject.call("rt_createModel", {faction=faction,r = color.r,g = color.g,b = color.b,isReference=isReference})
                    table.insert(spawnedRefCards, spawnedObject)
                end,
            })
            found = found +1;
            if isReference == false then
                break 
            else
             
            end
        else
            if isReference and found > 3 then
                break
            end
        end
    end

    if ismodel == false then
        spawnUpgrade ( modelName,modelSlot )
    end

end


function spawnUpgrade ( modelName,modelSlot)
    for key,containedObject in pairs(upgradeContainerObject.getObjects()) do
        if containedObject.name == modelName then

            upgradeContainerObject.takeObject({
                index = containedObject.index,
                position = getSlotPosition(modelSlot-1.2),
                rotation = getSlotRotation(),
                callback_function = function(spawnedObject)
                    spawnedObject.clone({position=upgradeContainerObject.getPosition(),rotation={x=0,y=180,z=0}})
                    table.insert(spawnedRefCards, spawnedObject)
                end,
            })
            break 
        end
    end
end

function getSlotPosition(modelSlot)
    local row = 0
    local targetPos = modelSlot
    while targetPos >= 9.5 do
        row = row + 1
        targetPos = targetPos - 10
    end

    if playerColor == 'Red' then
        return Vector( basePositionRed.x+ row * 6,basePositionRed.y  ,basePositionRed.z + ((targetPos) * ( 3.5)))
    end
    if playerColor == 'Blue' then
        return Vector( basePositionBlue.x+ row * -6,basePositionBlue.y  ,basePositionBlue.z + ((targetPos) * ( -3.5)))
    end
end


function getSlotRotation(modelSlot)
    if playerColor == 'Red' then
        return {x=0,y=90,z=0}
    end
    if playerColor == 'Blue' then
        return {x=0,y=-90,z=0}
    end
end


function mysplit (inputstr, sep)
    if sep == nil then
            sep = "%c"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function updateVal()
    if tooltip_show then
        ttText = "     " .. val .. "\n" .. self.getName()
    else
        ttText = self.getName()
    end

    self.editButton({
        index = 0,
        label = tostring(val),
        tooltip = ttText
        })
end

function reset_val()
    val = 0
    updateVal()
    updateSave()
end

function starts_with(str, start)
    return str:sub(1, #start) == start
end

function ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

function GetPlayerFromColor(color)
    for _, player in pairs(Player.getPlayers()) do
        if player.color == color then
            return player;
        end
    end
end