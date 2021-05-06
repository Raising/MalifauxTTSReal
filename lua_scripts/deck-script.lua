

------------- LIFE CICLE EVENTS --------------


function onLoad()
 
    rebuildAssets();
    print(ui());
    
    self.UI.setXml(ui());
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


---------------- DECK ACTIONS ----------------

function FlipCards(amount)
    local Deck = GetDeck()
end

function DiscardAll()
    print("discard All");
end

function TemporalDraw()
    -- Place card on the secondary hand
end


function GetDeck()
    local baseRotation = self.getRotation().y;
    local deckSlotOffset = Vector(2 * math.cos(baseRotation),0,2 * math.sin(baseRotation));
    local DeckBase = self.getPosition():add(deckSlotOffset);
    local hits = Physics.cast({
        origin       = DeckBase,
        direction    = {0,1,0},
        type         = 1,
        max_distance = 30,
    });

    print(hits[1]);
end

------------- UI SETUP -----------------------
local DeckOptions = {
    Flip1 = { action = function() FlipCards(1) end, x=0, y =0, image= "http://cloud-3.steamusercontent.com/ugc/1755816788596196197/1D640D73C228B945161222D9AAA500E6F59A9F16/" },
    Flip1 = { action = function() FlipCards(2) end, x=0, y =0, image= "http://cloud-3.steamusercontent.com/ugc/1755816788596196197/1D640D73C228B945161222D9AAA500E6F59A9F16/" },
    Flip1 = { action = function() FlipCards(3) end, x=0, y =0, image= "http://cloud-3.steamusercontent.com/ugc/1755816788596196197/1D640D73C228B945161222D9AAA500E6F59A9F16/" },
    Flip1 = { action = function() FlipCards(4) end, x=0, y =0, image= "http://cloud-3.steamusercontent.com/ugc/1755816788596196197/1D640D73C228B945161222D9AAA500E6F59A9F16/" },
    DiscardAll = { action = function() DiscardAll() end, x=0, y =0, image= "http://cloud-3.steamusercontent.com/ugc/1755816788596196197/1D640D73C228B945161222D9AAA500E6F59A9F16/" },
   -- Rebuild = { action = function() rebuildAssets() end, x=0, y=-1, image= "https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/ui/reload.png" },
    
}

function CallMenuAction(player,name)
    DeckOptions[name].action();
end

function rebuildAssets()
    local assets = {};
    for optionName,details in pairs(DeckOptions) do
        assets[#assets+1]={name=optionName , url = details.image};
    end
    self.UI.setCustomAssets(assets)
end

    
---------- Menu DOM ----------------

    function ui() 
        return [[
            <Panel color="#FFFFFFff" height="20000" width="50000" position="0 0 0" >]]..
        --        DeckMenu()..
            [[</Panel>
        ]];
    end

    function DeckMenu()
        local TextOptions = "";
        for optionName,details in pairs(DeckOptions) do
            TextOptions = TextOptions .. DeckMenuOption(optionName,details.x,details.y,details.action);
        end
        return TextOptions;
         -- [[<Panel id='General_Menu'  height="40" width="0" rectAlignment="UpperRight"   childForceExpandWidth="false">]]..TextOptions..[[</Panel>]]
    end


    function DeckMenuOption(name,x,y,fun)
        local id = "MenuOption_" .. name ;
        return [[<Button id="]] .. id ..[[" width="80" height="60" color="#aaaaaaff"  position=']] ..(x* (-45) -25).. [[ ]] .. (y*(-45)-90) .. [[ 0'  onClick="]].. self.getGUID()..[[/CallMenuAction(]] .. name .. [[)" >]] ..
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

