referenceCardsContainerGUID = "000888"
referenceCardsContainerObject = nil
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
      click_function="retrieve_crew",
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

function retrieve_crew(_obj, _color, alt_click)
    if referenceCardsContainerObject == nil then
        referenceCardsContainerObject = getObjectFromGUID(referenceCardsContainerGUID)
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
        print('upgrade: ' .. string.sub(entity, 3))
      else
        spawnModel(entity,modelPosition)
        print('model: ' .. entity)
        modelPosition = modelPosition +1
      end
    end
    
   end
end

function spawnModel ( modelName,modelPosition)
    local pos = self.getPosition()
    print(modelPosition)
    pos = {x=pos.x + 4 + modelPosition * 3, y=pos.y+1 , z=pos.z}
    for key,containedObject in pairs(referenceCardsContainerObject.getObjects()) do
        if containedObject.name == modelName then

            referenceCardsContainerObject.takeObject({
                index = containedObject.index,
                position = pos,
                callback_function = function(spawnedObject)
                    spawnedObject.clone({position=referenceCardsContainerObject.getPosition()})
                end,
            })
           
            break -- Stop iterating
        end
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
