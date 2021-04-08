local RSS_Class = 'ReferenceCard';


local mini = nil
local faction;
local baseScale;
local cardFrontImage;
local cardBackImage;
local health;
local imageScale;
local modelImage;
local name;
local playerColor='green';


local state = {};

local prototypes = {
    base = '000000',
}

function defaultModelStatus()
    return {
        Variables = {Health = 8, Position = Vector(0,0,0), Aura = 0,  Maxhealth = 8},
        Conditions = { Fast = 0, Slow = 0, Stunned = 0, Staggered = 0, Adversary = 0, Burn = 0, Poision = 0, Injured = 0, Distracted = 0, Focus = 0, Shield = 0},
        Tokens = { Blood = 0, Dark =0, Balance = 0,Green = 0, Corruption = 0, Gold = 0, Power = 0},
        Figurine = { BaseSize = 1.2, ImageScale = 1.5, CardFront = "", CardBack = "", BaseColor = "#995522", ModelImage = "" }
        
    }
end


function onSave()
	local data={}
    data.modelStatus = state.modelStatus or nil;
    data.modelInstance = state.modelInstance or nil;
    if data.modelInstance ~= nil then
        data.modelInstance.ModelGuid = data.modelStatus.Model.getGUID();
        data.modelInstance.Model = nil;
    end

	return JSON.encode(data)
end

function onLoad(save)
    status = {};
    save = JSON.decode(save) or {}
    if (save.modelStatus ~= nil) then
        status.modelStatus= save.modelStatus;
    else
        status.modelStatus = defaultModelStatus()
    end
    
    if (save.modelInstance ~= nil) then
        status.modelInstance.Model = getObjectFromGUID(save.modelInstance.ModelGuid);
        status.modelInstance.ModelGuid  = save.modelInstance.ModelGuid;
    else
        status.modelInstance ={Model = nil,  ModelGuid = '-1'}
    end
    
	rebuildAssets()
	Wait.frames(rebuildUI, 3)
end

function destruct()
    if status.modelInstance.Model ~= nil then
        status.modelInstance.Model.destruct()    
    end
end

function ui_createModel()
    createModel(self.getPosition())
end


function createModel(position)
    local vectPos = Vector(position.x,position.y,position.z);
    local pos = position:add(Vector(0,2,0))

    if mini ~= nil then
        pos = mini.getPosition()
        pos = {x=pos.x, y=pos.y + 2, z=pos.z}
        mini.destruct()
    end
    objectData =  self.getData()

    modelPrototype = getObjectFromGUID(prototypes.base)
    print(pos);
    model = modelPrototype.clone({position=pos})

    model.setScale(Vector(status.modelStatus.Figurine.BaseSize, 1, status.modelStatus.Figurine.BaseSize))
    attachments = model.getAttachments()
    for key,value in pairs(attachments) do
        modelElement = model.removeAttachment(0)
        modelElement.setCustomObject({
            image = status.modelStatus.Figurine.ModelImage,
            image_secondary = status.modelStatus.Figurine.ModelImage,
            image_scalar = status.modelStatus.Figurine.ImageScale
        })
        modelElement.setScale(Vector(0.40 * status.modelStatus.Figurine.BaseSize, 0.40 * status.modelStatus.Figurine.BaseSize, 0.2 ));
        model.addAttachment(modelElement)
    end
    model.setDescription(objectData.Description)
    model.setName(name)
    --model.script_state = JSON.encode(status.modelStatus); -- 
    model.script_state = JSON.encode({
        status.modelStatus
        
        baseScale= status.modelStatus.Figurine.BaseSize ,
        imageScale= status.modelStatus.Figurine.ImageScale,
        name='nomae',
        faction="Faction_NAME",
        playerColor="Blue"
    });
     
    --  {bars={{'Health','#55aa22',health,health,true,true}},markers={}}
    -- model.call('setController',{guid:controllerGUID})
    status.modelInstance.Model = model;
    status.modelInstance.ModelGuid = model.getGUID();
    
    -- end
end

function ui_pingmini(player)
    if (mini ~= nil) then
        if (player.pingTable ~= nil) then
            player.pingTable(mini.getPosition())
        end
    end
end

function rebuildAssets()
    local root = 'https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/ui/';

    --TODO ADD ALL ICONS FROM conditions and tokens
    local assets = {
        {name='ui_power', url=root..'power.png'},
        {name='ui_gear', url=root..'gear.png'},
        {name='ui_close', url=root..'close.png'},
        {name='ui_plus', url=root..'plus.png'},
        {name='ui_minus', url=root..'minus.png'},
        {name='ui_reload', url=root..'reload.png'},
        {name='ui_location', url=root..'location.png'},
        {name='ui_bars_new', url=root..'bars_new.png'},
        {name='ui_arrow_u', url=root..'arrow_u.png'},
        {name='ui_arrow_d', url=root..'arrow_d.png'},
        {name='ui_arrow_l', url=root..'arrow_l.png'},
        {name='ui_arrow_r', url=root..'arrow_r.png'},
    }

    -- assetBuffer = {}
    -- local bufLen = 0
    -- for idx,guid in pairs(mapI2G) do
    --     local mini = getObjectFromGUID(guid)
    --     if (mini ~= nil) then
    --         for i,marker in pairs(mini.call('getMarkers', {})) do
    --             if (assetBuffer[marker.url] == nil) then
    --                 bufLen = bufLen + 1
    --                 assetBuffer[marker.url] = self.guid..'_mk_'..bufLen
    --                 table.insert(assets, {name=self.guid..'_mk_'..bufLen, url=marker.url})
    --             end
    --         end
    --     end
    -- end
    self.UI.setCustomAssets(assets)
end


function ui() 
    return [[
        <Panel color="#FFFFFF00" height="100%" width="100%" rectAlignment="LowerCenter" childForceExpandWidth="true" >
            <Button onClick="ui_createModel" text="Spawn Model"  colors="#ccccccff|#ffffffff|#404040ff|#808080ff" width="120" height="20" position="0 110 -5" rotation="0 0 180" ></Button>
        </Panel>]];
end


function rebuildUI()
    self.setCustomObject({
        image = cardFrontImage,
        image_secondary = cardBackImage,
    });

    -- local ui = {
   
        
    --     {tag='button', attributes={onClick='ui_pingmini', image='ui_location',  colors='#ccccccff|#ffffffff|#404040ff|#808080ff', width='20', height='20', position='-40 -110 -5', rotation='0 0 180' }},
    --     {tag='button', attributes={onClick='ui_createModel',text='Spawn Model',  colors='#ccccccff|#ffffffff|#404040ff|#808080ff', width='120', height='20', position='0 110 -5', rotation='0 0 180' }} 
    -- }
    
    self.UI.setXml(ui())
end