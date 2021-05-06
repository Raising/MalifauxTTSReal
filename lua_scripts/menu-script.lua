
------------- MENU STATE ---------------------
    
    local MenuLayers = {};
    local UIState = {
        deployment = {mode=0,rotation=0};

    };
    local MoveManager = nil;
    local DeploymentOverlay = nil;

    function InitUIState()
        UIState.Blue = DefaultPlayer()
        UIState.Red = DefaultPlayer()
        UIState.Black = DefaultPlayer()
    end

    function DefaultPlayer()
        return {
            active = 'false',
            object_target = nil,
            object_target_guid = '-1',
            menu_layer = "Base",
            selectedCondition = "",
            lockOpen = false,
        }
    end

------------- LIFE CICLE EVENTS --------------

    function onNumberInput(params)
        local color = params.color;
        local number = params.number;
        if UIState[color] and UIState[color].active then
            -- PlayerPressButtonFlash(color, number)
            PlayerPressButton(color,number) 
        end
    end

    function onScriptingButtonDown(number, color)
        if UIState[color] and UIState[color].active == 'true' then
            -- PlayerPressButtonFlash(color, number)
            PlayerPressButton(color,number) 
            return true;
        end
    end

    function onLoad()
        MoveManager = getObjectFromGUID("17aadb");
        DeploymentOverlay = getObjectFromGUID("02c08b");
        
        MoveManager.call("SetMenuManager",{menuManager = self})
        rebuildAssets();
        InitUIState();
        InitMenuLayers();
        UI.setXml(ui());
    end

    function onUpdate()
        for _, player in ipairs(Player.getPlayers()) do
            if IsPlayerSuscribed(player.color) then
                local hoveredElement = player.getHoverObject();
                local RSS_Class = hoveredElement and hoveredElement.getVar("RSS_Class") or 'no Hover';
                
                if RSS_Class == "Model" or RSS_Class == "Marker" then
                    ActiveMenu(player,'true');
                else
                    ActiveMenu(player,'false');
                end
            end
        end
    end

------------- MENU STATE ACTIONS -------------

    function ActiveMenu(player,value)
        if UIState[player.color].lockOpen == false then
            if UIState[player.color].active ~= value or UIState[player.color].object_target ~= player.getHoverObject() then
                -- UI.setAttribute(player.color .. '_Menu','active',value)
                SetMenuLayer(player.color,'Base');
                UIState[player.color].active = value;
                if value == 'true' then Player_AssignTargetObject(player) else Player_CleanTargetObject(player) end
            end
        end
    end

    function Player_AssignTargetObject(player)
        SetMenuLayer(player.color,"Base")
        UIState[player.color].selectedCondition = "";
        UIState[player.color].object_target = player.getHoverObject();
        UIState[player.color].object_target_guid =  UIState[player.color].object_target.getGUID(); 
    end

    function Player_CleanTargetObject(player)
        UIState[player.color].object_target = nil;
        UIState[player.color].object_target_guid = '-1';
    end

    function IsPlayerSuscribed(color)
        return UIState[color] ~= nil;
    end

    function SelectCondition(color,name)
        if UIState[color].selectedCondition == name then
            ModifySelectedCondition(color,1)
        else
            UIState[color].selectedCondition = name;
        end
    end

------------- MODEL COMUNICATION -------------

    function ModifySelectedCondition(color,amount)
        if  UIState[color].selectedCondition ~= "" then
            ModifyCondition(color,UIState[color].selectedCondition  , amount);
        end
    end


    function ModifyCondition(color,name,amount)
        UIState[color].object_target.call("ModifyCondition", {name =name  ,amount = amount});
    end


    function ModifyHealth(color,amount)
        UIState[color].object_target.call("ModifyHealth", {amount = amount});
    end


    function ModifyAura(color,amount)
        UIState[color].object_target.call("ModifyAura", {amount = amount});
    end

------------- MOVEMENT COMUNICATION ----------

    function StartControledMove(color,range)
        SetMenuLayer(color, "Move")
        UIState[color].lockOpen = true;
        MoveManager.call("StartControledMove", {color = color, obj = UIState[color].object_target  });
        if range ~= nil then
            MoveManager.call("SetMoveRange", {color = color, amount = range });
        end
    end

    function StartFreeMove(color)
        SetMenuLayer(color, "FreeMove")
        UIState[color].lockOpen = true;
        MoveManager.call("StartFreeMove", {color = color, obj = UIState[color].object_target  });
    end
    
    function CleanMovement(params)
        local color = params.color;
        SetMenuLayer(color, "Base")
        UIState[color].lockOpen = false;
    end


    function AbortMove (color)
        SetMenuLayer(color, "Base")
        UIState[color].lockOpen = false;
        MoveManager.call("AbortMove", {color = color, obj = UIState[color].object_target  });
    end
    
    function CompleteMove (color)
        SetMenuLayer(color, "Base")
        UIState[color].lockOpen = false;
        MoveManager.call("CompleteMove", {color = color, obj = UIState[color].object_target  });
    end
    
    function AddMoveStep (color)
        MoveManager.call("AddMoveStep", {color = color, obj = UIState[color].object_target  });
    end
    
    function RemoveMoveStep (color)
        MoveManager.call("RemoveMoveStep", {color = color, obj = UIState[color].object_target  });
    end

    function ModifyMoveRange(color, amount)
        MoveManager.call("ModifyMoveRange", {color = color, amount = amount });
    end


------------- UI FEEDBACK---------------------

    function PlayerPressButton(color,number)
        MenuLayers[UIState[color].menu_layer]["_"..number].onSelect(color);
    end

    -- function PlayerPressButtonFlash(color,number)
    --     local buttonId = color .. [[_Option_]] .. number;
    --     UI.setAttribute(buttonId,'color',"#995500");
    --     Wait.frames(function() PlayerPressButtonFlashEnd(buttonId) end, 4)
    -- end

    -- function PlayerPressButtonFlashEnd(buttonId)
    --     UI.setAttribute(buttonId,'color',"#373737")
    -- end


    -- function ChangeLayerFlash(color)
    --     for i = 0,9,1 do 
    --     local buttonId = color .. [[_Option_]] .. i;
    --     UI.setAttribute(buttonId,'color',"#cc9900");
    --     end
    --     Wait.frames(function() ChangeLayerFlashEnd(color) end, 2)
    -- end

    -- function ChangeLayerFlashEnd(color) 
    --     for i = 0,9,1 do 
    --         local buttonId = color .. [[_Option_]] .. i;
    --         UI.setAttribute(buttonId,'color',"#373737");
    --     end
    
    -- end

------------ DEPLOYMENT ----------------------

function FindDeploymentOverlay()
    if DeploymentOverlay == nil then
        for key,guid in pairs {"c2c330" ,"3eed6c","57825b","02c08b"} do
            DeploymentOverlay = getObjectFromGUID(guid);
            if DeploymentOverlay ~= nil then
                break;
            end
        end
    end
end

function StateToDeployment(depState)
    if     depState == 1 then return "Corner"
    elseif depState == 2 then return "Wedge"
    elseif depState == 3 then return "Standard"
    elseif depState == 4 then return "Flank"
    else   return "????"
    end
end
function ChangeModeDeployment()
    FindDeploymentOverlay();
    UIState.deployment.mode = (UIState.deployment.mode +1)%5;
    if UIState.deployment.mode == 0 then
        DeploymentOverlay.setScale(Vector(0.1,1,0.1))
        DeploymentOverlay.setPosition(Vector(0,-10,0))
    else
        DeploymentOverlay.setScale(Vector(18,1,18));
        DeploymentOverlay.setPosition(Vector(0,0.95,0))
        DeploymentOverlay.setRotation(Vector(0, UIState.deployment.rotation * 90,0));
        DeploymentOverlay = DeploymentOverlay.setState(UIState.deployment.mode);
        print('Deployment set to "' .. StateToDeployment( UIState.deployment.mode) .. '"');
    end
end

function RotateDeployment()
    FindDeploymentOverlay();
    UIState.deployment.rotation = (UIState.deployment.rotation +1)%4;
    DeploymentOverlay.setRotation(Vector(0, UIState.deployment.rotation * 90,0));
end

------------- UI SETUP -----------------------
    local GeneralMenuOptions = {
       -- Rebuild = { action = function() rebuildAssets() end, x=0, y=-1, image= "https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/ui/reload.png" },
        ChangeDeployment = { action = function() ChangeModeDeployment() end, x=0, y =0, image= "http://cloud-3.steamusercontent.com/ugc/1755816788596196197/1D640D73C228B945161222D9AAA500E6F59A9F16/" },
        RotateDeployment = { action = function() RotateDeployment() end, x=1, y =0, image= "https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/ui/reload.png" }  
    }

    function CallMenuAction(player,name)
        GeneralMenuOptions[name].action();
    end

    function rebuildAssets()
        local assets = {};
        for optionName,details in pairs(GeneralMenuOptions) do
            assets[#assets+1]={name=optionName , url = details.image};
        end

        UI.setCustomAssets(assets)
    end
    ------------ Menu Layers ----------------
        function InitMenuLayers()
            MenuLayers = {
                --Base = BaseMenu(),
                Base = QUICKMoveMenu(),
                Move = MoveMenu(), 
                FreeMove = FreeMoveMenu(), 
                ConditionToggle = ConditionToggleMenu(),
                ConditionStack = ConditionStackMenu(),
                Token = TokenMenu(),
                ModelManipulation = ModelManipulationMenu(),
            }

            SetMenuLayer('Red','Base')
            SetMenuLayer('Blue','Base')
            SetMenuLayer('Black','Base')
        end

        function SetMenuLayer(color, LayerName)
            if UIState[color].menu_layer ~= LayerName then
                UIState[color].lockOpen = false;
                UIState[color].menu_layer = LayerName;
                for key,value in pairs(MenuLayers[LayerName]) do
                    local buttonId = color .. [[_Option]] .. key;
                    local descId = color .. [[_Option]] .. key .. [[_Desc]];
                    UI.setAttribute(descId,'text',value.desc)
                end
            end
            --ChangeLayerFlash(color)
        end

        function BaseMenu()
            return {
                _Tittle = {desc='Model Menu'},
                _10 = MenuOption("ACTIVATED",    function(color) ModifyCondition(color,"Activated",0)  end),
                _1 = MenuOption("COND STACK",   function(color) SetMenuLayer(color, "ConditionStack") end),
                _2 = MenuOption("COND TOGGLE",  function(color) SetMenuLayer(color, "ConditionToggle") end),
                _3 = MenuOption("TOKEN",        function(color) SetMenuLayer(color, "Token") end),
                _4 = MenuOption("CONTROLED MOVE", function(color) StartControledMove(color) end),-- SetMenuLayer(color, "Move") end),
                _5 = MenuOption("HEALTH -",     function(color) ModifyHealth(color,-1) end),
                _6 = MenuOption("AURA -",       function(color) ModifyAura(color,-1) end),
                _7 = MenuOption("FREE MOVE",    function(color) StartFreeMove(color) end),
                _8 = MenuOption("HEALTH +",     function(color) ModifyHealth(color,1) end),
                _9 = MenuOption("AURA +",       function(color) ModifyAura(color,1) end),
            }
        end

        function MoveMenu()
            return {
                _Tittle = {desc='Controled Movement'},
                -- _1 = MenuOption("REMOVE WAYPOINT",  function(color) RemoveMoveStep(color) end),
                -- _2 = MenuOption("Push 1¨",          function(color) print("not implemented push1¨") end),
                -- _3 = MenuOption("Push 1/2¨",        function(color) print("not implemented push1/2¨") end),
                
                -- _4 = MenuOption("ADD WAYPOINT",     function(color) AddMoveStep(color) end),
                -- _5 = MenuOption("TOWARDS/AWAY",     function(color) print("Not implemented swap directions") end),
                -- _6 = MenuOption("DEC RANGE",        function(color)  ModifyMoveRange(color,-1) end),
                
                -- _7 = MenuOption("COMPLETE",         function(color) CompleteMove(color) end),
                -- _8 = MenuOption("SEVERE/NORMAL",    function(color) print("Not Implemented add servere cost") end),
                -- _9 = MenuOption("ADD RANGE",        function(color) ModifyMoveRange(color,1) end),
                 
                _1 = MenuOption("REMOVE WAYPOINT",  function(color) AbortMove(color) end),
                _2 = MenuOption("Push 1¨",          function(color) AbortMove(color)  end),
                _3 = MenuOption("Push 1/2¨",        function(color) AbortMove(color)  end),
                
                _4 = MenuOption("ADD WAYPOINT",     function(color) AbortMove(color) end),
                _5 = MenuOption("TOWARDS/AWAY",     function(color) AbortMove(color)  end),
                _6 = MenuOption("DEC RANGE",        function(color) AbortMove(color) end),
                
                _7 = MenuOption("COMPLETE",         function(color) AbortMove(color) end),
                _8 = MenuOption("SEVERE/NORMAL",    function(color) AbortMove(color)  end),
                _9 = MenuOption("ADD RANGE",        function(color) AbortMove(color) end),
                
                _10 = MenuOption("CANCEL",  function(color) AbortMove(color) end),
            }
        end

        function QUICKMoveMenu()
            return {
                _Tittle = {desc='Controled Movement'},
                _1 = MenuOption("Move 1¨",  function(color) StartControledMove(color,1) end),
                _2 = MenuOption("Move 2¨",  function(color) StartControledMove(color,2) end),
                _3 = MenuOption("Move 3¨",  function(color) StartControledMove(color,3) end),
                
                _4 = MenuOption("Move 4¨",  function(color) StartControledMove(color,4) end),
                _5 = MenuOption("Move 5¨",  function(color) StartControledMove(color,5) end),
                _6 = MenuOption("Move 6¨",  function(color) StartControledMove(color,6) end),
                
                _7 = MenuOption("Move 7¨",  function(color) StartControledMove(color,7) end),
                _8 = MenuOption("Move 8¨",  function(color) StartControledMove(color,8) end),
                _9 = MenuOption("Move 9¨",  function(color) StartControledMove(color,9) end),
                
                _10 = MenuOption("Free Move",  function(color) StartFreeMove(color) end),
            }
        end

        function FreeMoveMenu()
            return {
                _Tittle = {desc='Free Movement'},
                _1 = MenuOption("COMPLETE", function(color) CompleteMove(color) end),
                _2 = MenuOption(" ",        function(color) print('not implemented') end ),
                _3 = MenuOption(" ",        function(color) print('not implemented') end ),
                
                _4 = MenuOption(" ",        function(color) print('not implemented') end ),
                _5 = MenuOption(" ",        function(color) print('not implemented') end ),
                _6 = MenuOption(" ",        function(color) print('not implemented') end ),
                
                _7 = MenuOption("COMPLETE", function(color) CompleteMove(color) end),
                _8 = MenuOption(" ",        function(color) print('not implemented') end ),
                _9 = MenuOption(" ",        function(color) print('not implemented') end ),
                _10 = MenuOption("CANCEL",  function(color) AbortMove(color) end),
            }
        end

        function ConditionToggleMenu()
            return {
                _Tittle = {desc='Toggleable Conditions'},
                _1 = MenuOption("BACK",function(color) SetMenuLayer(color, "Base") end),
                _2 = MenuOption("FAST/SLOW",function(color) ModifyCondition(color,"Fast",1) end),
                _3 = MenuOption("STUNNED",function(color) ModifyCondition(color,"Stunned",0) end),
                _4 = MenuOption("STAGGERED",function(color) ModifyCondition(color,"Staggered",0) end),
                _5 = MenuOption("ADVERSARY",function(color) ModifyCondition(color,"Adversary",0) end),
                _6 = MenuOption(" ",function(color) print("option6 ") end),
                _7 = MenuOption(" ",function(color) print("option7 ") end),
                _8 = MenuOption(" ",function(color) print("option8 ") end),
                _9 = MenuOption(" ",function(color) print("option9 ") end),
                _10 = MenuOption("CANCEL",function(color) print("option0 ") end),
            }
        end

        function ConditionStackMenu()
            return {
                _Tittle = {desc='Stackable Conditions'},
                _10 = MenuOption("CANCEL",function(color) SetMenuLayer(color, "Base") end),
                _1 = MenuOption("REMOVE",function(color) ModifySelectedCondition(color,-1) end),
                _2 = MenuOption("ADD",function(color) ModifySelectedCondition(color,1) end),
                _3 = MenuOption("CLEAN",function(color) ModifySelectedCondition(color,-100) end),
                _4 = MenuOption("FOCUS",function(color) SelectCondition(color,'Focus') end),
                _5 = MenuOption("SHIELD",function(color) SelectCondition(color,'Shielded') end),
                _6 = MenuOption("BURN",function(color) SelectCondition(color,'Burning') end),
                _7 = MenuOption("POISON",function(color) SelectCondition(color,'Poison') end),
                _8 = MenuOption("INJURED",function(color) SelectCondition(color,'Injured') end),
                _9 = MenuOption("DISTRACTED",function(color) SelectCondition(color,'Distracted') end),
            }
        end

        function TokenMenu()
            return {
                _Tittle = {desc='Tokens'},
                _10 = MenuOption("BACK",function(color) SetMenuLayer(color, "Base") end),
                _1 = MenuOption("POWER TOKEN",function(color) print("option0 ") end),
                _2 = MenuOption("ADD",function(color) print("option2 ") end),
                _3 = MenuOption("REMOVE",function(color) print("option3 ") end),
                _4 = MenuOption("BLOOD TOKEN",function(color) print("option4 ") end),
                _5 = MenuOption("DARK TOKEN",function(color) print("option5 ") end),
                _6 = MenuOption("BALANCE TOKEN",function(color) print("option6 ") end),
                _7 = MenuOption("GREEN TOKEN",function(color) print("option7 ") end),
                _8 = MenuOption("CORRUPTION TOKEN",function(color) print("option8 ") end),
                _9 = MenuOption("GOLD TOKEN",function(color) print("option9 ") end),
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
                _10 = MenuOption("CANCEL",function(color) print("option0 ") end),
            }
        end

        function MenuOption(desc,exe)
            return {
                    onSelect = exe,
                    desc = desc, 
            }
        end

    ---------- GENERAL MENU -------------
        
    ---------- Menu DOM ----------------

        function ui() 
            return [[
                <Panel color="#FFFFFF00" height="100%" width="100%" rectAlignment="LowerRight" childForceExpandWidth="true" >]]..
                GeneralMenu()..
                -- PlayerMenu('Blue')..
                -- PlayerMenu('Red')..
                -- PlayerMenu('Black')..
                [[</Panel>
            ]];
        end

        function GeneralMenu()
            local TextOptions = "";
            for optionName,details in pairs(GeneralMenuOptions) do
                TextOptions = TextOptions .. GeneralMenuOption(optionName,details.x,details.y,details.action);
            end
            return [[<Panel id='General_Menu'  height="40" width="0" rectAlignment="UpperRight"   childForceExpandWidth="false">]]..TextOptions..[[</Panel>]]
        end


        function GeneralMenuOption(name,x,y,fun)
            local id = "MenuOption_" .. name ;
            return [[<Button id="]] .. id ..[[" width="40" height="40" color="#aaaaaaff"  position=']] ..(x* (-45) -25).. [[ ]] .. (y*(-45)-90) .. [[ 0'  onClick="]].. self.getGUID()..[[/CallMenuAction(]] .. name .. [[)" >]] ..
            -- [[<Text  id="OptionText_]]..name ..[["  alignment='UpperRight' fontSize="15" color="#d9ddde" outline='#000000' >]].. name ..[[</Text>]]..
                [[<Image  id="OptionImage_]]..name ..[[" image="]] .. name .. [[" color="#ffffffff" rectAlignment='MiddleCenter' width='35' height='35'/>]]..
            [[</Button>]];
        end
    
        -- function HUDSingleConditionBody(color,name)
        --     local secondary = Conditions[name].secondary;
        --     local imageName = (secondary == nil and name or (state.conditions[name] > 1 and name or secondary));
        --     return [[
        --         <Image id="]]..color ..[[_ConditionImage_]]..name ..[[" image="]] .. imageName .. [[" color="]] .. Conditions[imageName].color .. (state.conditions[name] > 0  and 'ff' or '22') .. [[" rectAlignment='LowerLeft' width='30' height='30'/>
        --         <Text  id="]]..color ..[[_ConditionText_]]..name ..[[" active=']] .. (Conditions[name].stacks and state.conditions[name] > 0 and 'true' or 'false')  ..[['  fontSize='22' text=']] .. state.conditions[name] .. [[' color='#ffffff' fontStyle='Bold'  rectAlignment='LowerLeft' outline='#000000' outlineSize='1 1' />
        --     ]]
        -- end



        function PlayerMenu(color)
            return [[
                <VerticalLayout id=']]..color..[[_Menu' active='false' visibility=']]..color..[[' height="160" width="0" rectAlignment="LowerRight"  childForceExpandWidth="false">
                    <Text id=']] .. color .. [[_Option_Tittle_Desc' alignment='UpperRight' fontSize="25" color="#d9ddde" outline='#000000'   >   Model Menu</Text>
                ]]..MenuButtons(color)..[[
            </VerticalLayout>
            ]]
        end

        function BaseButton(color,number,x,y,width)
            return  [[<Panel id=']] .. color .. [[_Option_]]..number..[[' height="80" width="]]..(80 * width)..[["  alignment='LowerLeft'  position=']] ..(x* 82 - 270 + (40 * width)).. [[ ]] .. (30 + y*(82)) .. [[ 0'  color="#373737" padding='4 4 4 4' >
                        <Text id=']] .. color .. [[_Option_]]..number..[[_Desc' alignment='UpperLeft' fontSize="11" color="#d9ddde"   >  ]].. MenuLayers.Base["_"..number].desc ..[[</Text>
                        <Text alignment='UpperRight' fontSize="14" color="#d9ddde" >]]..number..[[</Text>
                    </Panel>]];
        end


        function MenuButtons(color)
            return [[
                <Panel id=']] .. color .. [[_Menu_Layer' active='true' height="80" width="0" position='0 0 0' rectAlignment="LowerRight"  childForceExpandWidth="true">]]..
                    BaseButton(color,10,0,0,2) ..
                    BaseButton(color,1,0,1,1) ..
                    BaseButton(color,2,1,1,1) ..
                    BaseButton(color,3,2,1,1) ..
                    BaseButton(color,4,0,2,1) ..
                    BaseButton(color,5,1,2,1) ..
                    BaseButton(color,6,2,2,1) ..
                    BaseButton(color,7,0,3,1) ..
                    BaseButton(color,8,1,3,1) ..
                    BaseButton(color,9,2,3,1) ..
                [[</Panel>
            ]]
        end
