

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

local prototypes = {
    base = '000000',
}
function destruct()
    if mini ~= nil then
        mini.destruct()    
    end
end
function ui_createModel()
    createModel(self.getPosition())
end


function createModel(position)
    local pos = position:add(Vector(0,2,0))

    if mini ~= nil then
        pos = mini.getPosition()
        pos = {x=pos.x, y=pos.y + 2, z=pos.z}
        mini.destruct()
    end
    objectData =  self.getData()

    modelPrototype = getObjectFromGUID(prototypes.base)
    model = modelPrototype.clone({position=pos})

    model.setScale({x=baseScale, y=1, z=baseScale})
    attachments = model.getAttachments()
    for key,value in pairs(attachments) do
        modelElement = model.removeAttachment(0)
        modelElement.setCustomObject({
            image = modelImage,
            image_secondary = modelImage,
            image_scalar = imageScale
        })
        modelElement.setScale(Vector(0.40 * baseScale, 0.40 * baseScale, 0.2 ));
        model.addAttachment(modelElement)
    end
    model.setDescription(objectData.Description)
    model.setName(name)
    model.script_state =  "{\"bars\":[[\"Health\",\"#55aa22\"," ..health .."," ..health..",true,true]]," .. "\"markers\":[]," .. "\"baseScale\":".. baseScale .."," .."\"imageScale\":" .. imageScale  .."," .."\"name\":\"" .. name  .."\"," .."\"faction\":\"" .. faction  .."\"," .."\"playerColor\":\"" .. playerColor  .."\"" .. "}";
    --  {bars={{'Health','#55aa22',health,health,true,true}},markers={}}
    -- model.call('setController',{guid:controllerGUID})
    mini = model
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

    assetBuffer = {}
    local bufLen = 0
    for idx,guid in pairs(mapI2G) do
        local mini = getObjectFromGUID(guid)
        if (mini ~= nil) then
            for i,marker in pairs(mini.call('getMarkers', {})) do
                if (assetBuffer[marker.url] == nil) then
                    bufLen = bufLen + 1
                    assetBuffer[marker.url] = self.guid..'_mk_'..bufLen
                    table.insert(assets, {name=self.guid..'_mk_'..bufLen, url=marker.url})
                end
            end
        end
    end
    self.UI.setCustomAssets(assets)
end

function rebuildUI()
    self.setCustomObject({
        image = cardFrontImage,
        image_secondary = cardBackImage,
    });

    local ui = {
        {tag='Defaults', children={
            {tag='Text', attributes={color='#cccccc', fontSize='18', alignment='MiddleLeft'}},
            {tag='InputField', attributes={fontSize='24', preferredHeight='40'}},
            {tag='ToggleButton', attributes={fontSize='18', preferredHeight='40', colors='#ffcc33|#ffffff|#808080|#606060', selectedBackgroundColor='#dddddd', deselectedBackgroundColor='#999999'}},
            {tag='Button', attributes={fontSize='12',textColor='#111111', preferredHeight='40', colors='#dddddd|#ffffff|#808080|#f6f6f6'}},
            {tag='Toggle', attributes={textColor='#cccccc'}},
        }},
        
        {tag='button', attributes={onClick='ui_pingmini', image='ui_location',  colors='#ccccccff|#ffffffff|#404040ff|#808080ff', width='20', height='20', position='-40 -110 -5', rotation='0 0 180' }},
        {tag='button', attributes={onClick='ui_createModel',text='Spawn Model',  colors='#ccccccff|#ffffffff|#404040ff|#808080ff', width='120', height='20', position='0 110 -5', rotation='0 0 180' }} 
    }
    
    self.UI.setXmlTable(ui)
end

function onSave()
    miniguid = ''
    if mini ~= nil then
        miniguid = mini.getGUID()
    end
    local save = {
        mini = miniguid,
        baseScale = baseScale,
        health = health,
        imageScale = imageScale,
        modelImage = modelImage,
        name = name,
        playerColor = playerColor, 
        faction = faction,
        cardFrontImage = cardFrontImage,
        cardBackImage = cardBackImage,
    }
    return JSON.encode(save)
end


function onLoad(save)
    local data = JSON.decode(save)
    mini = getObjectFromGUID(data.mini)
    baseScale = data.baseScale;
    health = data.health;
    imageScale = data.imageScale;
    modelImage = data.modelImage;
    cardFrontImage = data.cardFrontImage;
    cardBackImage =data.cardBackImage;
    name = data.name;
    faction = data.faction or 'Arcanist';
    playerColor = data.playerColor or 'Blue';

    rebuildUI()
end

