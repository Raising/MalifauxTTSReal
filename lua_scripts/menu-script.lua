local MenuLayers = {};
local UIStatus = {};

function onObjectNumberTyped(object , color, number)
    if UIStatus[color] and UIStatus[color].active then
        PlayerPressButtonFlash(color, number)
        PlayerPressButton(color,number) 
        return true;
    end
end

function onLoad()
  InitUIStatus()
 
  local completeUi = string.gsub(ui(), "theguid", self.getGUID())
  self.UI.setXml(completeUi)
  Wait.frames(InitMenuLayers, 3)
end

function onUpdate()
    for _, player in ipairs(Player.getPlayers()) do
        if IsPlayerSuscribed(player.color) then
            if player.getHoverObject() then
                ActiveMenu(player,'true');
            else
                ActiveMenu(player,'false');
            end
        end
    end
end


function ActiveMenu(player,value)
    if  UIStatus[player.color].active ~= value or UIStatus[player.color].object_target ~= player.getHoverObject() then
        self.UI.setAttribute(player.color .. '_Menu','active',value)
        UIStatus[player.color].active = value;
        if value == 'true' then Player_AssignTargetObject(player) else Player_CleanTargetObject(player) end
    end
end

function Player_AssignTargetObject(player)
    SetMenuLayer(player.color,"Base")
    UIStatus[player.color].object_target = player.getHoverObject();
    UIStatus[player.color].object_target_guid =  UIStatus[player.color].object_target.getGUID();
    
end

function Player_CleanTargetObject(player)
    UIStatus[player.color].object_target = nil;
    UIStatus[player.color].object_target_guid = '-1';
end


function IsPlayerSuscribed(color)
    return UIStatus[color] ~= nil;
end

function SelectCondition(color,name)
    if UIStatus[color].selectedCondition == name then
        ModifySelectedCondition(color,1)
    else
        UIStatus[color].selectedCondition = name;
    end
end

function ModifySelectedCondition(color,amount)
    if  UIStatus[color].selectedCondition ~= "" then
        ModifyCondition(color,UIStatus[color].selectedCondition  , amount);
    end
end


function ModifyCondition(color,name,amount)
    UIStatus[color].object_target.call("ModifyCondition", {name =name  ,amount = amount});
end


function ModifyHealth(color,amount)
    UIStatus[color].object_target.call("ModifyHealth", {amount = amount});
end


function PlayerPressButton(color,number)
    MenuLayers[UIStatus[color].menu_layer]["_"..number].onSelect(color);
end

function PlayerPressButtonFlash(color,number)
    local buttonId = color .. [[_Option_]] .. number;
    self.UI.setAttribute(buttonId,'color',"#995500");
    Wait.frames(function() PlayerPressButtonFlashEnd(buttonId) end, 4)
end

function PlayerPressButtonFlashEnd(buttonId)
    self.UI.setAttribute(buttonId,'color',"#373737")
end


function ChangeLayerFlash(color)
    for i = 0,9,1 do 
       local buttonId = color .. [[_Option_]] .. i;
       self.UI.setAttribute(buttonId,'color',"#cc9900");
    end
    Wait.frames(function() ChangeLayerFlashEnd(color) end, 2)
end

function ChangeLayerFlashEnd(color) 
    for i = 0,9,1 do 
        local buttonId = color .. [[_Option_]] .. i;
        self.UI.setAttribute(buttonId,'color',"#373737");
     end
 
end

function InitMenuLayers()
    MenuLayers = {
        Base = BaseMenu(),
        Move = MoveMenu(), 
        ConditionToggle = ConditionToggleMenu(),
        ConditionStack = ConditionStackMenu(),
        Token = TokenMenu(),
        ModelManipulation = ModelManipulationMenu(),
    }

    SetMenuLayer('Red','Base')
    SetMenuLayer('Blue','Base')
end


function SetMenuLayer(color, LayerName)
    if UIStatus[color].menu_layer ~= LayerName then
        UIStatus[color].menu_layer = LayerName;
        print(LayerName);
        for key,value in pairs(MenuLayers[LayerName]) do
            local buttonId = color .. [[_Option]] .. key;
            local descId = color .. [[_Option]] .. key .. [[_Desc]];
            self.UI.setAttribute(descId,'text',value.desc)
        end
    end
    ChangeLayerFlash(color)
end



function BaseMenu()
    return {
        _Tittle = {desc='Model Menu'},
        _1 = MenuOption("MOVE",         function(color) SetMenuLayer(color, "Move") end),
        _2 = MenuOption("HEALTH -",     function(color) ModifyHealth(color,-1) end),
        _3 = MenuOption("HEALTH +",     function(color) ModifyHealth(color,1) end),
        _4 = MenuOption("AURA -",       function(color) print("Aura - ") end),
        _5 = MenuOption("AURA +",       function(color) print("Aura + ") end),
        _6 = MenuOption("COND STACK",   function(color) SetMenuLayer(color, "ConditionStack") end),
        _7 = MenuOption("COND TOGGLE",  function(color) SetMenuLayer(color, "ConditionToggle") end),
        _8 = MenuOption("ACTIVATED",    function(color) print("Toggle Activated ") end),
        _9 = MenuOption("TOKENS",       function(color) SetMenuLayer(color, "Token") end),
        _0 = MenuOption("CANCEL",       function(color) SetMenuLayer(color, "ModelManipulation") end),
    }
end

function MoveMenu()
    return {
        _Tittle = {desc='Movement Tools'},
        _1 = MenuOption("BACK",function(color) SetMenuLayer(color, "Base") end),
        _2 = MenuOption("ACCEPT",function(color) print("option2 ") end),
        _3 = MenuOption("UNDO",function(color) print("option3 ") end),
        _4 = MenuOption("MOUSE WAYPOINT",function(color) print("option4 ") end),
        _5 = MenuOption("PUSH 1¨",function(color) print("option5 ") end),
        _6 = MenuOption("PUSH 1/2¨",function(color) print("option6 ") end),
        _7 = MenuOption("TOWARDS/AWAY",function(color) print("option7 ") end),
        _8 = MenuOption("SEVERE/NORMAL",function(color) print("option8 ") end),
        _9 = MenuOption(" ",function(color) print("option9 ") end),
        _0 = MenuOption("CANCEL",function(color) print("option0 ") end),
    }
end

function ConditionToggleMenu()
    return {
        _Tittle = {desc='Toggleable Conditions'},
        _1 = MenuOption("BACK",function(color) SetMenuLayer(color, "Base") end),
        _2 = MenuOption("SLOW",function(color) ModifyCondition(color,"Slow",0) end),
        _3 = MenuOption("FAST",function(color) ModifyCondition(color,"Fast",0) end),
        _4 = MenuOption("STUNNED",function(color) ModifyCondition(color,"Stunned",0) end),
        _5 = MenuOption("STAGGERED",function(color) ModifyCondition(color,"Staggered",0) end),
        _6 = MenuOption("ADVERSARY",function(color) ModifyCondition(color,"Adversary",0) end),
        _7 = MenuOption(" ",function(color) print("option7 ") end),
        _8 = MenuOption(" ",function(color) print("option8 ") end),
        _9 = MenuOption(" ",function(color) print("option9 ") end),
        _0 = MenuOption("CANCEL",function(color) print("option0 ") end),
    }
end


function ConditionStackMenu()
    return {
        _Tittle = {desc='Stackable Conditions'},
        _1 = MenuOption("BACK",function(color) SetMenuLayer(color, "Base") end),
        _2 = MenuOption("REMOVE",function(color) ModifySelectedCondition(color,-1) end),
        _3 = MenuOption("FOCUS",function(color) SelectCondition(color,'Focus') end),
        _4 = MenuOption("SHIELD",function(color) SelectCondition(color,'Shielded') end),
        _5 = MenuOption("BURN",function(color) SelectCondition(color,'Burning') end),
        _6 = MenuOption("POISON",function(color) SelectCondition(color,'Poison') end),
        _7 = MenuOption("INJURED",function(color) SelectCondition(color,'Injured') end),
        _8 = MenuOption("DISTRACTED",function(color) SelectCondition(color,'Distracted') end),
        _9 = MenuOption("ADD",function(color) ModifySelectedCondition(color,1) end),
        _0 = MenuOption("CANCEL",function(color) print("option0 ") end),
    }
end

function TokenMenu()
    return {
        _Tittle = {desc='Tokens'},
        _1 = MenuOption("BACK",function(color) SetMenuLayer(color, "Base") end),
        _2 = MenuOption("ADD",function(color) print("option2 ") end),
        _3 = MenuOption("REMOVE",function(color) print("option3 ") end),
        _4 = MenuOption("BLOOD TOKEN",function(color) print("option4 ") end),
        _5 = MenuOption("DARK TOKEN",function(color) print("option5 ") end),
        _6 = MenuOption("BALANCE TOKEN",function(color) print("option6 ") end),
        _7 = MenuOption("GREEN TOKEN",function(color) print("option7 ") end),
        _8 = MenuOption("CORRUPTION TOKEN",function(color) print("option8 ") end),
        _9 = MenuOption("GOLD TOKEN",function(color) print("option9 ") end),
        _0 = MenuOption("POWER TOKEN",function(color) print("option0 ") end),
    }
end

function ModelManipulationMenu()
    return {
        _Tittle = {desc='Model Manipulation'},
        _1 = MenuOption("BACK",function(color) SetMenuLayer(color, "Base") end),
        _2 = MenuOption("ACCEPT",function(color) print("option2 ") end),
        _3 = MenuOption("UNDO",function(color) print("option3 ") end),
        _4 = MenuOption("MOUSE WAYPOINT",function(color) print("option4 ") end),
        _5 = MenuOption("TOWARDS 1¨",function(color) print("option5 ") end),
        _6 = MenuOption("TOWARDS 1/2¨",function(color) print("option6 ") end),
        _7 = MenuOption("AWAY 1¨",function(color) print("option7 ") end),
        _8 = MenuOption("AWAY 1/2¨",function(color) print("option8 ") end),
        _9 = MenuOption(" ",function(color) print("option9 ") end),
        _0 = MenuOption("CANCEL",function(color) print("option0 ") end),
    }
end


function MenuOption(desc,exe)
    return {
            onSelect = exe,
            desc = desc, 
    }
end


function DefaultPlayer()
    return {
        active = 'false',
        object_target = nil,
        object_target_guid = '-1',
        menu_layer = "Base",
        selectedCondition = "",
    }
end



function ui() 
    return [[
        <Panel color="#FFFFFF00" height="100%" width="100%" rectAlignment="LowerCenter" childForceExpandWidth="true" >]]..
        PlayerMenu('Blue')..
        PlayerMenu('Red')..
        [[</Panel>
    ]];
end

function PlayerMenu(color)
    return [[
        <VerticalLayout id=']]..color..[[_Menu' active='false' visibility=']]..color..[[' height="160" width="50%" rectAlignment="LowerCenter"  childForceExpandWidth="false">
        <Text id=']] .. color .. [[_Option_Tittle_Desc' alignment='LowerCenter' fontSize="25" color="#d9ddde" outline='#000000'   >   Model Menu</Text>
        ]]..MenuButtons(color)..[[
      </VerticalLayout>
    ]]
end

function BaseButton(color,number)
    return  [[<Button id=']] .. color .. [[_Option_]]..number..[[' height="60" color="#373737" padding='4 4 4 4' >
                <Text id=']] .. color .. [[_Option_]]..number..[[_Desc' alignment='UpperLeft' fontSize="11" color="#d9ddde"   >   Description</Text>
                <Text alignment='UpperRight' fontSize="14" color="#d9ddde" >]]..number..[[</Text>
            </Button>]];
end


function MenuButtons(color)
    return [[
        <HorizontalLayout id=']] .. color .. [[_Menu_Layer' active='true' height="80" width="100%" rectAlignment="LowerCenter"  childForceExpandWidth="true">]]..
            BaseButton(color,1) ..
            BaseButton(color,2) ..
            BaseButton(color,3) ..
            BaseButton(color,4) ..
            BaseButton(color,5) ..
            BaseButton(color,6) ..
            BaseButton(color,7) ..
            BaseButton(color,8) ..
            BaseButton(color,9) ..
            BaseButton(color,0) ..
        [[</HorizontalLayout>
    ]]
end




function InitUIStatus()
    UIStatus.Blue = DefaultPlayer()
    UIStatus.Red = DefaultPlayer()
end


function activateScriptingButton(player, index)
  local peekerColor = player.color
  local selected = player.getSelectedObjects()
  if #selected > 0 then
    for k, obj in pairs(getAllObjects()) do
      if obj.getVar("isMaster") then
        obj.call("onScriptingButtonDownTable", {index = index, peekerColor = peekerColor})
      end
    end
  end
end


