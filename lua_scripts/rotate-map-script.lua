


function rotate_map()
    print("rotateMap");

    local allObjects = getAllObjects();

    for index,obj in pairs(allObjects) do
        local objPos = obj.getPosition();
        if math.abs(objPos.x) < 18 and math.abs(objPos.z) < 18 and objPos.y > 0 then
            obj.setLock(true);
            local objRotation = obj.getRotation()
            obj.setPosition(Vector(objPos.z,objPos.y,-objPos.x));
            obj.setRotation(objRotation + Vector(0,90,0));
        end
    end
end

function onLoad(save)
    rebuildUI()
end


function rebuildUI()
    
    local ui = {
        {tag='Defaults', children={
            {tag='Text', attributes={color='#cccccc', fontSize='18', alignment='MiddleLeft'}},
            {tag='InputField', attributes={fontSize='24', preferredHeight='40'}},
            {tag='ToggleButton', attributes={fontSize='18', preferredHeight='40', colors='#ffcc33|#ffffff|#808080|#606060', selectedBackgroundColor='#dddddd', deselectedBackgroundColor='#999999'}},
            {tag='Button', attributes={fontSize='12',textColor='#111111', preferredHeight='40', colors='#dddddd|#ffffff|#808080|#f6f6f6'}},
            {tag='Toggle', attributes={textColor='#cccccc'}},
        }},
        
       
        {tag='button', attributes={onClick='rotate_map',text='',  colors='#cccccc00|#ffffff00|#40404000|#80808000', width='300', height='300', position='0 0 0', rotation='0 0 0' }} 
    }
    
    self.UI.setXmlTable(ui)
end
