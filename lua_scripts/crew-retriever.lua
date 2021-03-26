referenceCardsContainerGUID = "000888"
upgradeContainerGUID = "000777"
controllerGUID = "e894f6"

referenceCardsContainerObject = nil
upgradeContainerObject = nil
color = ''


basePositionBlue = {x= -22, y=1.5,z=14}
basePositionRed = {x= 22, y=1.5,z=-14}

spawnedRefCards = {}

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

    print(_color)
    if _color ~= 'Red' and _color ~= 'Blue' then
        broadcastToAll("Please Select Color first, only Blue and Red are Valid");
    else
        color = _color
        retrieve_crew()
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
    local placeReferences = false
   
    if referenceCardsContainerObject == nil then
        referenceCardsContainerObject = getObjectFromGUID(referenceCardsContainerGUID)
    end
    if upgradeContainerObject == nil then
        upgradeContainerObject = getObjectFromGUID(upgradeContainerGUID)
    end

    local modelPosition = 0
   local description = self.getData().Description
   local separatedCrew = mysplit(description)
   for key,value in pairs(separatedCrew) do
    local starterCharacter = string.sub(value, 1, 2)
    if starterCharacter == '  ' then
      local entity = string.sub(value, 3)
      local secondCharacter = string.sub(entity, 1, 2)
      if secondCharacter == '  ' then
        spawnUpgrade(string.sub(entity, 3),modelPosition)
        print('upgrade: ' .. string.sub(entity, 3))
      else
        spawnModel(entity,modelPosition)
        print('model: ' .. entity)
        if placeReferences == false then
            modelPosition = modelPosition +1
        end
        
      end
    else
        if value == 'References:' then
            placeReferences = true    
            modelPosition = modelPosition + 2
        end

    end
    
   end
end

function spawnModel ( modelName,modelSlot)
    ismodel = false;

    for key,containedObject in pairs(referenceCardsContainerObject.getObjects()) do
        if containedObject.name == modelName then
            ismodel = true
           
            referenceCardsContainerObject.takeObject({
                index = containedObject.index,
                position =  getSlotPosition(modelSlot):add(Vector(0,1,0)),
                rotation = getSlotRotation(),
                callback_function = function(spawnedObject)
                    spawnedObject.clone({position=referenceCardsContainerObject.getPosition(),rotation={x=0,y=180,z=0}})
                    spawnedObject.call("createModel", controllerGUID)
                    table.insert(spawnedRefCards, spawnedObject)
                end,
            })
            break 
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

    if color == 'Red' then
        return Vector( basePositionRed.x+ row * 6,basePositionRed.y  ,basePositionRed.z + ((targetPos) * ( 3.5)))
    end
    if color == 'Blue' then
        return Vector( basePositionBlue.x+ row * -6,basePositionBlue.y  ,basePositionBlue.z + ((targetPos) * ( -3.5)))
    end
end


function getSlotRotation(modelSlot)
    if color == 'Red' then
        return {x=0,y=90,z=0}
    end
    if color == 'Blue' then
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
