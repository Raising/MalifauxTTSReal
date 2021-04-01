

mini = nil

baseScale=1.2
health=7
imageScale=1.5
modelImage="http://cloud-3.steamusercontent.com/ugc/1651098259767449695/9ED8401B4B8DACE8465048EE03E0D3C120281A5D/"
modelScaleX=0.54
modelScaleY=0.54
name="Vasilisa"

prototypes = {
    base = '000000',
}
function destruct()
    if mini ~= nil and not mini.isDestroyed() then
        mini.destruct()
    end
end
function createModel()
    local pos = self.getPosition()
    pos = {x=pos.x, y=pos.y + 2, z=pos.z+2}

    if mini ~= nil then
        pos = mini.getPosition()
        pos = {x=pos.x, y=pos.y + 2, z=pos.z}
        mini.destruct()
    end
    objectData =  self.getData()

    -- print('NickName: ',objectData.Nickname)
    -- print('Desc: ',objectData.Description)
    -- print('Color: ',objectData.ColorDiffuse.r,objectData.ColorDiffuse.g,objectData.ColorDiffuse.b)
    -- print('Image: ',objectData.CustomImage.ImageURL)
    
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
        modelElement.setScale({x=modelScaleX, y=modelScaleY, z=0.2})
        model.addAttachment(modelElement)
    end
    model.setDescription(objectData.Description)
    model.setName(objectData.Nickname)
    model.script_state =  "{\"bars\":[[\"Health\",\"#55aa22\"," ..health .."," ..health..",true,true]],\"markers\":[]}"
    --  {bars={{'Health','#55aa22',health,health,true,true}},markers={}}
    
    mini = model
    rebuildUI()
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
    
    local ui = {
        {tag='Defaults', children={
            {tag='Text', attributes={color='#cccccc', fontSize='18', alignment='MiddleLeft'}},
            {tag='InputField', attributes={fontSize='24', preferredHeight='40'}},
            {tag='ToggleButton', attributes={fontSize='18', preferredHeight='40', colors='#ffcc33|#ffffff|#808080|#606060', selectedBackgroundColor='#dddddd', deselectedBackgroundColor='#999999'}},
            {tag='Button', attributes={fontSize='12',textColor='#111111', preferredHeight='40', colors='#dddddd|#ffffff|#808080|#f6f6f6'}},
            {tag='Toggle', attributes={textColor='#cccccc'}},
        }},
        
        {tag='button', attributes={onClick='ui_pingmini', image='ui_location',  colors='#ccccccff|#ffffffff|#404040ff|#808080ff', width='20', height='20', position='-40 -110 -5', rotation='0 0 180' }},
        {tag='button', attributes={onClick='createModel',text='Spawn Model',  colors='#ccccccff|#ffffffff|#404040ff|#808080ff', width='120', height='20', position='0 110 -5', rotation='0 0 180' }},
        UI_Overhead()
    }
    
    self.UI.setXmlTable(ui)
end

function onSave()
    miniguid = ''
    if mini ~= nil then
        miniguid = mini.getGUID()
    end
    local save = {
     mini = miniguid
    }
    return JSON.encode(save)
end


function onLoad(save)
    local data = JSON.decode(save)
    mini = getObjectFromGUID(data.mini)
    rebuildUI()
end

function UI_Overhead()
    print("uiOverhead");
	local w = 100; local orient = 'HORIZONTAL';
	local ui_overhead = { 
		tag='Panel', 
		attributes={
			childForceExpandHeight='false',
			position='0 -40 -250',
			rotation='-0 0 0',
			active=ui_mode=='0',
			scale='1 1 1',
			height=0,
			color='red',
			width=w
		},
		children={
			{
				tag='VerticalLayout',
				attributes={
					rotation='-15 0 0',
					rectAlignment='LowerCenter',
					childAlignment='LowerCenter',
					childForceExpandHeight=false,
					childForceExpandWidth=true,
					height='5000',
					spacing='5'
				},
				children={
					UI_Markers_Container(),
					UI_Bars_Container(),
				}
			},
			
		}
	}
	return ui_overhead;
end

function UI_Bars_Container()
	return {
		tag='VerticalLayout', 
		attributes={
			contentSizeFitter='vertical',
			childAlignment='LowerCenter',
			flexibleHeight='0'
			},
		children=UI_Bars()
	}
	end

function UI_Markers_Container()
    return {
        tag='GridLayout', 
        attributes={
            contentSizeFitter='vertical', 
            childAlignment='LowerLeft', 
            flexibleHeight='0', 
            cellSize='40 40', 
            padding='2 2 0 0'
        },
        children=UI_Markers()
    }
end

function UI_Markers()
    local markers = {}
    local modelMarkers = {};
    if mini ~= nil then
        local minimarkers = mini.call('getMarkers', {})
        for i,marker in pairs(minimarkers) do
            table.insert(markers,{tag='panel',attributes={},
            children={
                {tag='image',attributes={image=assetBuffer[marker[2]],color=marker[3],rectAlignment='LowerLeft',width='40',height='40'}},
                {tag='text',attributes={id='counter_mk_'..i,text=marker[4]>1 and marker[4]or'',color='#ffffff',rectAlignment='UpperRight',width='20',height='20'}}
            }
        });

        end;
    end
    return markers;
end
function UI_Bars()

    local bars = {};
    local modelBars = {};
    if mini ~= nil then
        for i,bar in pairs(mini.call('getBars', {})) do
            local per = ((bar[4] == 0) and 0 or (bar[3] / bar[4] * 100))

            local increaseButton = {tag='button', attributes={preferredHeight='20',preferredWidth='20',flexibleWidth='0',image='ui_plus',colors='#ccccccff|#ffffffff|#404040ff|#808080ff',onClick='ui_adjbar('..i..'|1)',visibility=PERMEDIT} };
            local decreaseButton = {tag='button', attributes={preferredHeight='20',preferredWidth='20',flexibleWidth='0',image='ui_minus',colors='#ccccccff|#ffffffff|#404040ff|#808080ff',onClick='ui_adjbar('..i..'|-1)',visibility=PERMEDIT} };
            local bar ={tag='panel', attributes={flexibleWidth='1',flexibleHeight='1'},
                children={
                    {tag='progressbar', attributes={width='100%',height='100%',id='bar_'..i,color='#00000080',fillImageColor=bar[2],percentage=per,textColor='transparent'} },
                    {tag='text', attributes={id='bar_'..i..'_text',text=bar[3]..' / '..bar[4],active=bar[5]or false,color='#ffffff',fontStyle='Bold',outline='#000000',outlineSize='1 1'} }
                }
            }
            
            table.insert(bars,
            {tag='horizontallayout', attributes={id='bar_'..i..'_container',minHeight=bar[6]and 40 ,childForceExpandWidth=false,childForceExpandHeight=false,childAlignment='MiddleCenter'},
                children={
                    decreaseButton,
                    bar,
                    increaseButton
                }
            })
        end
    end
	return bars;
end

