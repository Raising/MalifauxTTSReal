TRH_Class = 'mini'

local state = {};
local PERMEDIT = 'Grey|Host|Admin|Black|White|Brown|Red|Orange|Yellow|Green|Teal|Blue|Purple|Pink|Clubs|Diamonds|Hearts|Spades|Jokers';
local PERMVIEW = 'Grey|Host|Admin|Black|White|Brown|Red|Orange|Yellow|Green|Teal|Blue|Purple|Pink|Clubs|Diamonds|Hearts|Spades|Jokers';
local ui_mode = '0';
local controller_obj;
local assetBuffer = {};
local arc_len = 1;
local base_radius = 1;
local arc_obj;
local init = false;
local rotateVector = function(a,b)
	local c=math.rad(b)local d=math.cos(c)*a[1]+math.sin(c)*a[2]local e=math.sin(c)*a[1]*-1+math.cos(c)*a[2]return{d,e,a[3]}
end
local indexOf = function(e, t)
	for k,v in pairs(t) do
		if (e == v) then return k end
	end
	return nil
end
function onUpdate()
	if init == false then
		base_radius = self.getData().Transform.scaleX /2

	end
end

function onDestroy()
	if (arc_obj ~= nil) then arc_obj.destruct() end
end

function onSave()
	local data={}
	data.bars=state.bars
	data.markers=state.markers
	return JSON.encode(data)
end

function onLoad(save)
	
	save = JSON.decode(save) or {}
	state.bars = save.bars or {}
	state.markers = save.markers or {}
	rebuildAssets()
	Wait.frames(rebuildUI, 3)
end

function recalculateModelSize()
	local desc = self.getData().Description
	print(desc)
	
	local attachments = self.getAttachments()
    for key,value in pairs(attachments) do
        modelElement = self.removeAttachment(0)
        modelElement.setCustomObject({
            -- image = modelImage,
            -- image_secondary = modelImage,
            image_scalar = tonumber(desc)
		})
		-- modelElement.getComponent('MeshCollider').set('enabled',false)
        self.addAttachment(modelElement)
    end
end

function ui_setmode(player,mode)
	if mode==ui_mode then
		mode='0'
	end
	ui_mode=mode
	if mode=='0' then
		rebuildAssets()
		Wait.frames(rebuildUI,3)
	else
		rebuildUI()
	end
end
function initiateLink(data)
	if (setController(data)) then
		return controller_obj.call('setMini', {guid=self.guid})
	end
	return false
end
function initiateUnlink()
	local theObj = unsetController()
	if (theObj ~= nil) then
		theObj.call('untrackMini', {guid = self.guid})
	end
end
function setController(data)
	local obj = data.object or getObjectFromGUID(data.guid or error('object or guid is required', 2)) or error('invalid object',2)
	if ((obj.getVar('TRH_Class') or '') ~= 'mini.controller') then
		error('object is not a mini controller',2)
	else
		controller_obj = obj
		return true
	end
	return false
end
function unsetController()
	if (controller_obj ~= nil) then
		local theObj = controller_obj
		controller_obj = nil
		return theObj
	end
	return nil
end
function moveCommit() end;
function moveCancel() end;
function moveStart() end;
function spawnGeometry() end;
function editGeometry(a) end;
function clearGeometry() end;
function showArc()
	self.UI.hide('btn_show_arc')
	self.UI.show('btn_hide_arc')
	self.UI.show('disp_arc_len')
	self.UI.show('btn_arc_sub')
	self.UI.show('btn_arc_add')
	local a=1*(arc_len+(base_radius))--based on model base size
	local me = self
	local clr = self.getColorTint()
 	arc_obj=spawnObject({
		type='custom_model',
		position=self.getPosition(),
		rotation=self.getRotation(),
		scale={a,1,a},
		mass=0,
		use_gravity=false,
		sound=false,
		snap_to_grid=false,
		callback_function=function(b)
			b.jointTo(me, {
				type='Fixed',
				collision=false
			})
			b.setColorTint(clr)
			b.setVar('parent',self)
			b.setLuaScript([[
				function onLoad() 
					(self.getComponent('BoxCollider') or self.getComponent('MeshCollider')).set('enabled',false)
					Wait.condition(
						function() 
							(self.getComponent('BoxCollider') or self.getComponent('MeshCollider')).set('enabled',false) 
						end, 
						function() 
							return not(self.loading_custom) 
						end
					) 
				end 
				function onUpdate() 
					if (parent ~= nil) then 
						if (not parent.resting) then 
							self.setPosition(parent.getPosition())
							self.setRotation(parent.getRotation()) 
						end 
					else 
						self.destruct() 
					end 
				end
			]])
			b.getComponent('MeshRenderer').set('receiveShadows',false)
			b.mass=0
			b.bounciness=0
			b.drag=0
			b.use_snap_points=false
			b.use_grid=false
			b.use_gravity=false
			b.auto_raise=false
			b.auto_raise=false
			b.sticky=false
			b.interactable=false
		end
	})
	arc_obj.setCustomObject({
		mesh='https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/components/arcs/round0.obj',
		collider='https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/utility/null_COL.obj',
		material=3,
		specularIntensity=0,
		cast_shadows=false
	})
end
function setArcValue(a)
	if arc_obj~=nil then
		arc_len=tonumber(a.value) or arc_len;
		arc_obj.setScale({1*(arc_len+(base_radius)),1,1*(arc_len+(base_radius))})
		self.UI.setAttribute('disp_arc_len','text',arc_len)
	end
end
function arcSub()
	if arc_obj~=nil then
		arc_len=math.max(1,arc_len-1)
		arc_obj.setScale({1*(arc_len+(base_radius)),1,1*(arc_len+(base_radius))})
		self.UI.setAttribute('disp_arc_len','text',arc_len)
	end
end
function arcAdd()
	if arc_obj~=nil then
		arc_len=math.min(16,arc_len+1)
		arc_obj.setScale({1*(arc_len+(base_radius)),1,1*(arc_len+(base_radius))})
		self.UI.setAttribute('disp_arc_len','text',arc_len)
	end
end
function ui_arcadd(player) arcAdd() end;
function ui_arcsub(player) arcSub() end;
function hideArc()
            		if arc_obj ~=nil then
            			arc_obj.destruct()
            		end
            		self.UI.show('btn_show_arc')
            		self.UI.hide('btn_hide_arc')
            		self.UI.hide('disp_arc_len')
            		self.UI.hide('btn_arc_sub')
            		self.UI.hide('btn_arc_add')
            	end
function ui_showarc(player) showArc() end;
function ui_hidearc(player) hideArc() end;
function toggleFlag() end;
function editFlag() end;
function clearFlag() end;
function addMarker(data)
            	    local added = false
            	    local found = false
            	    local count = data.count or 1
            	    for i,each in pairs(state.markers) do
            	        if (each[1] == data.name) then
            	            found=true
            	            if (data.stacks or false) then
            	                cur = (state.markers[i][4] or 1) + count
            	                state.markers[i][4] = cur
            	                self.UI.setAttribute('counter_mk_'..i, 'text', cur)
            	                self.UI.setAttribute('disp_mk_'..i, 'text', cur > 1 and cur or '')
            	                if (controller_obj ~= nil) then controller_obj.call('syncAdjMiniMarker', { guid = self.guid, index=i, count=cur }) end
            	                added = true
            	            end
            	            break
            	        end
            	    end
            	    if (found == false) then
            	        table.insert(state.markers, {data.name, data.url, data.color or '#ffffff', (data.stacks or false) and count or 1, data.stacks or false})
                        if (controller_obj ~= nil) then controller_obj.call('syncMiniMarkers', {}) end
            	        rebuildAssets()
            	        Wait.frames(rebuildUI, 3)
            	        added = true
            	    end
            	    return added
            	end
            	
function getMarkers()
            	    res = {}
            	    for i,v in pairs(state.markers) do
            	        res[i] = {
            	            name = v[1],
            	            url = v[2],
            	            color = v[3],
            	            count = v[4] or 1,
            	            stacks = v[5] or false,
            	        }
            	    end
            	    return res
            	end
function popMarker(data)
            	    local i = tonumber(data.index)
            	    local cur = state.markers[i][4] or 1
            	    if (cur > 1) then
            	        cur = cur - (data.amount or 1)
            	        state.markers[i][4] = cur
            	        self.UI.setAttribute('counter_mk_'..i, 'text', ((cur > 1) and cur or ''))
            	        self.UI.setAttribute('disp_mk_'..i, 'text', ((cur > 1) and cur or ''))
            	        if (controller_obj ~= nil) then controller_obj.call('syncAdjMiniMarker', { guid = self.guid, index=i, count=cur }) end
            	    else
            	        table.remove(state.markers, i)
            	        if (controller_obj ~= nil) then controller_obj.call('syncMiniMarkers', {}) end
            	        rebuildUI()
            	    end
            	end
function removeMarker(data)
            		local index = tonumber(data.index) or error('index must be numeric');
            	    local tmp = {}
            	    for i,marker in pairs(state.markers) do
            	        if (i ~= data.index) then
            	            table.insert(tmp, marker)
            	        end
            	    end
            	    state.markers = tmp
                    if (controller_obj ~= nil) then controller_obj.call('syncMiniMarkers', {}) end
            	    rebuildUI()
            	end
function clearMarkers()
            	    state.markers={}
                    if (controller_obj ~= nil) then controller_obj.call('syncMiniMarkers', {}) end
            	    rebuildUI()
            	end
function ui_popmarker(player,value) popMarker({index=value}) end
function ui_clearmarkers(player) clearMarkers() end
function addBar(data)
            		local def = tonumber(data.current or data.maximum or 10)
            		local cur = data.current or def
            		local max = data.maximum or def
            		if (cur < 0) then cur = 0 end
            		if (max < 1) then max = 10 end
            		if (cur > max) then cur = max end
            		table.insert(state.bars, {
            			data.name or 'Name',
            			data.color or '#ffffff',
            			cur,
            			max,
            			data.text or false,
                        data.big or false,
            		})
                    if (controller_obj ~= nil) then controller_obj.call('syncBars', {}) end
                    rebuildUI()
            	end
function getBars()
            	    res = {}
            	    for i,v in pairs(state.bars) do
            	        local isBig = false
            	        local hasText = false
            	        if (v[5] ~= nil) then
            	            hasText = v[5]
            	        end
            	        if (v[6] ~= nil) then
            	            isBig = v[6]
            	        end
            	        res[i] = {
            	            name = v[1],
            	            color = v[2],
            	            current = v[3],
            	            maximum = v[4],
            	            text = hasText,
                            big = isBig,
            	        }
            	    end
            	    return res
            	end
function editBar(data)
            	    local index = tonumber(data.index) or error('index must be numeric', 2)
            	    local bar = state.bars[index]
            	    local max = tonumber(data.maximum) or bar[4]
            	    local cur = math.min(max, tonumber(data.current) or bar[3])
            	    local name = data.name or bar[1]
            	    local color = data.color or bar[2]
            	    local isBig = false
            	    local hasText = false
                    if (bar[5] ~= nil) then
            	        hasText = bar[5]
            	    end
            	    if (data.text ~= nil) then
            	        hasText = data.text
            	    end
            	    if (bar[6] ~= nil) then
            	        isBig = bar[6]
            	    end
            	    if (data.big ~= nil) then
            	        isBig = data.big
            	    end

            	    local per = (max == 0) and 0 or cur / max * 100

            	    self.UI.setAttribute('inp_bar_'..index..'_name', 'value', name)
            	    self.UI.setAttribute('inp_bar_'..index..'_color', 'value', color)
            	    self.UI.setAttribute('inp_bar_'..index..'_current', 'value', cur)
            	    self.UI.setAttribute('inp_bar_'..index..'_max', 'value', max)
                    self.UI.setAttribute('inp_bar_'..index..'_text', 'isOn', hasText)
            	    self.UI.setAttribute('inp_bar_'..index..'_big', 'isOn', isBig)

            	    self.UI.setAttribute('bar_'..index, 'percentage', per)
            	    self.UI.setAttribute('bar_'..index, 'fillImageColor', color)
            	    self.UI.setAttribute('bar_'..index..'_container', 'minHeight', isBig and 35 or 15)
            	    self.UI.setAttribute('bar_'..index..'_text', 'active', hasText)
            	    self.UI.setAttribute('bar_'..index..'_text', 'text', cur..' / '..max)

            	    state.bars[index][1] = name
            	    state.bars[index][2] = color
            	    state.bars[index][3] = cur
            	    state.bars[index][4] = max
                    state.bars[index][5] = hasText
            	    state.bars[index][6] = isBig

                    if (controller_obj ~= nil) then
                        controller_obj.call('syncBarValues', {
                            object = self,
                            index = index,
                            name = name,
                            color = color,
                            current = cur,
                            maximum = max,
                            text = hasText,
                            big = isBig
                        })
                    end
            	end
function adjustBar(data)
            	    local index = tonumber(data.index) or error('index must numeric')
            	    local val = tonumber(data.amount) or error('amount must be numeric')
            	    local bar = state.bars[index]
            	    local max = tonumber(bar[4]) or 0
            	    local cur = math.max(0, math.min(max, (tonumber(bar[3]) or 0) + val))
            	    local per = (max == 0) and 0 or cur / max * 100
            	    self.UI.setAttribute('bar_'..index, 'percentage', per)
            	    self.UI.setAttribute('bar_'..index..'_text', 'text', cur..' / '..max)
            	    self.UI.setAttribute('inp_bar_'..index..'_current', 'text', cur)
            	    state.bars[index][3] = cur

                    if (controller_obj ~= nil) then
                        controller_obj.call('syncBarValues', {
                            object = self,
                            index = index,
                            name = bar[1],
                            color = bar[2],
                            current = cur,
                            maximum = max,
                            text = bar[5],
                            big = bar[6]
                        })
                    end

            	end
function removeBar(data)
            		local index = tonumber(data.index) or error('index must be numeric')
            	    local tmp = {}
            	    for i,bar in pairs(state.bars) do
            	        if (i ~= index) then
            	            table.insert(tmp, bar)
            	        end
            	    end
            	    state.bars = tmp
                    if (controller_obj ~= nil) then controller_obj.call('syncBars', {}) end
            	    rebuildUI()
            	end
function clearBars(data)
	state.bars={}
	rebuildUI()
	if (controller_obj ~= nil) then controller_obj.call('syncBars', {}) end
end
function ui_addbar(player)
	addBar({name='Name', color='#ffffff', current=10, maximum=10, big=false, text=false})
end
function ui_removebar(player, index)
	removeBar({index=index})
end
function ui_editbar(player, val, id)
	local args = {}
	for a in string.gmatch(id, '([^%_]+)') do
		table.insert(args,a)
	end
	local index = tonumber(args[3])
	local key = args[4]
	if (key == 'name') then
		editBar({index=index, name=val})
	elseif (key == 'color') then
		editBar({index=index, color=val})
	elseif (key == 'current') then
		editBar({index=index, current=val})
	elseif (key == 'max') then
		editBar({index=index, maximum=val})
	elseif (key == 'big') then
		editBar({index=index, big=(val == 'True')})
	elseif (key == 'text') then
		editBar({index=index, text=(val == 'True')})
	end
end
function ui_adjbar(player, id)
	local args = {}
	for a in string.gmatch(id, '([^%|]+)') do
		table.insert(args,a)
	end
	local index = tonumber(args[1]) or 1
	local amount = tonumber(args[2]) or 1
	adjustBar({index=index, amount=amount})
end
function ui_clearbars(player)
	clearBars()
end;

function rebuildAssets()
	local root = 'https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/ui/';
	local assets = {
		{name='ui_gear', url=root..'gear.png'},
		{name='ui_close', url=root..'close.png'},
		{name='ui_plus', url=root..'plus.png'},
		{name='ui_minus', url=root..'minus.png'},
		{name='ui_hide', url=root..'hide.png'},
		{name='ui_bars', url=root..'bars.png'},
		{name='ui_stack', url=root..'stack.png'},
		{name='ui_effects', url=root..'effects.png'},
		{name='ui_reload', url=root..'reload.png'},
		{name='ui_arcs', url=root..'arcs.png'},
		{name='ui_flag', url=root..'flag.png'},
		{name='ui_arrow_l', url=root..'arrow_l.png'},
		{name='ui_arrow_r', url=root..'arrow_r.png'},
		{name='ui_arrow_u', url=root..'arrow_u.png'},
		{name='ui_arrow_d', url=root..'arrow_d.png'},
		{name='ui_check', url=root..'check.png'},
		{name='ui_block', url=root..'block.png'},
		{name='ui_splitpath', url=root..'splitpath.png'},
		{name='ui_cube', url=root..'cube.png'},
		{name='movenode', url=root..'movenode.png'},
		{name='moveland', url=root..'moveland.png'},
		{name='ui_shield', url=root..'shield.png'},
	}
	assetBuffer = {}
	local bufLen = 0
	for i,marker in pairs(state.markers) do
			if (assetBuffer[marker[2]] == nil) then
				bufLen = bufLen + 1
				assetBuffer[marker[2]] = self.guid..'_asset_'..bufLen
				table.insert(assets, {name=self.guid..'_asset_'..bufLen, url=marker[2]})
			end
		end
		self.UI.setCustomAssets(assets)
end
function rebuildUI()
	recalculateModelSize()
local w = 133.33333333333; local orient = 'HORIZONTAL';
local mainButtons = {};
local mainButtonX = 20;
local arcActive = arc_obj ~= nil;
table.insert(mainButtons, {tag='button', attributes={id='btn_show_arc', active=(not arcActive), height='30', width='30', rectAlignment='MiddleLeft', image='ui_arcs', offsetXY=mainButtonX..' 0', colors='#ccccccff|#ffffffff|#404040ff|#808080ff', onClick='ui_showarc', visibility=PERMEDIT}});
table.insert(mainButtons, {tag='button', attributes={id='btn_hide_arc', active=(arcActive), height='30', width='30', rectAlignment='LowerLeft', image='ui_arcs', offsetXY=mainButtonX..' 0', colors='#ccccccff|#ffffffff|#404040ff|#808080ff', onClick='ui_hidearc', visibility=PERMEDIT}});
table.insert(mainButtons, {tag='button', attributes={id='btn_arc_sub', active=(arcActive and arc_len > 0), height='30', width='30', rectAlignment='LowerLeft', image='ui_minus', offsetXY='-70 0', colors='#ccccccff|#ffffffff|#404040ff|#808080ff', onClick='ui_arcsub', visibility=PERMEDIT}});
table.insert(mainButtons, {tag='text', attributes={id='disp_arc_len', active=(arcActive), height='30', width='30', rectAlignment='LowerLeft', text=arc_len, offsetXY='-40 0', color='#ffffff', fontSize='20', outline='#000000', visibility=PERMEDIT}});
table.insert(mainButtons, {tag='button', attributes={id='btn_arc_add', active=(arcActive and arc_len < 16), height='30', width='30', rectAlignment='LowerLeft', image='ui_plus', offsetXY='-10 0', colors='#ccccccff|#ffffffff|#404040ff|#808080ff', onClick='ui_arcadd', visibility=PERMEDIT}});
mainButtonX = mainButtonX + 30;
table.insert(mainButtons, {tag='button', attributes={height='30', width='30', rectAlignment='MiddleRight', image='ui_gear', offsetXY='-50 0', colors='#ccccccff|#ffffffff|#404040ff|#808080ff', onClick='ui_setmode(markers)', visibility=PERMEDIT}});
table.insert(mainButtons, {tag='button', attributes={height='30', width='30', rectAlignment='MiddleRight', image='ui_reload', offsetXY='-20 0', colors='#ccccccff|#ffffffff|#404040ff|#808080ff', onClick='rebuildUI', visibility=PERMVIEW}});

local mainlist_markers = {}
local settingslist_markers = {}
for i,marker in pairs(state.markers) do
table.insert(mainlist_markers,{tag='panel',attributes={},
        				children={
        					{tag='image',attributes={image=assetBuffer[marker[2]],color=marker[3],rectAlignment='LowerLeft',width='40',height='40'}},
        					{tag='text',attributes={id='counter_mk_'..i,text=marker[4]>1 and marker[4]or'',color='#ffffff',rectAlignment='UpperRight',width='20',height='20'}}
        				}
        			});
table.insert(settingslist_markers,{tag='panel',attributes={color='#cccccc'},
        				children={
        					{tag='image',attributes={width=90,height=90,image=assetBuffer[marker[2]],color=marker[3],rectAlignment='MiddleCenter'}},
        					{tag='text',attributes={id='disp_mk_'..i,width=30,height=30,fontSize=20,text=marker[4]>1 and marker[4]or'',rectAlignment='UpperLeft',alignment='MiddleLeft',offsetXY='5 0'}},
        					{tag='button',attributes={width=30,height=30,image='ui_close',rectAlignment='UpperRight',colors='black|#808080|#cccccc',alignment='UpperRight',onClick='ui_popmarker('..i..')'}},
        					{tag='text',attributes={width=110,height=30,rectAlignment='LowerCenter',resizeTextMinSize=10,resizeTextMaxSize=14,resizeTextForBestFit=true,fontStyle='Bold',text=marker[1],color='Black',alignment='LowerCenter'}}
        				}
        			});
end;
local mainlist_bars = {}
        		local settingslist_bars = {{tag='Row',attributes={preferredHeight='30'},children={
        			{tag='Cell',children={{tag='Text',attributes={color='#cccccc',text='Name'}}}},
        			{tag='Cell',children={{tag='Text',attributes={color='#cccccc',text='Color'}}}},
        			{tag='Cell',children={{tag='Text',attributes={color='#cccccc',text='Current'}}}},
        			{tag='Cell',children={{tag='Text',attributes={color='#cccccc',text='Max'}}}},
        			{tag='Cell',children={{tag='Text',attributes={color='#cccccc',text='Text'}}}},
                    {tag='Cell',children={{tag='Text',attributes={color='#cccccc',text='Big'}}}},
        		}}}
        		for i,bar in pairs(state.bars) do
        			local per = ((bar[4] == 0) and 0 or (bar[3] / bar[4] * 100))
        			table.insert(mainlist_bars,
        	        {tag='horizontallayout', attributes={id='bar_'..i..'_container',minHeight=bar[6]and 30 or 15,childForceExpandWidth=false,childForceExpandHeight=false,childAlignment='MiddleCenter'},
        	            children={
        	                {tag='button', attributes={preferredHeight='20',preferredWidth='20',flexibleWidth='0',image='ui_minus',colors='#ccccccff|#ffffffff|#404040ff|#808080ff',onClick='ui_adjbar('..i..'|-1)',visibility=PERMEDIT} },
        	                {tag='panel', attributes={flexibleWidth='1',flexibleHeight='1'},
        	                    children={
        	                        {tag='progressbar', attributes={width='100%',height='100%',id='bar_'..i,color='#00000080',fillImageColor=bar[2],percentage=per,textColor='transparent'} },
        	                        {tag='text', attributes={id='bar_'..i..'_text',text=bar[3]..' / '..bar[4],active=bar[5]or false,color='#ffffff',fontStyle='Bold',outline='#000000',outlineSize='1 1'} }
        	                    }
        	                },
        	                {tag='button', attributes={preferredHeight='20',preferredWidth='20',flexibleWidth='0',image='ui_plus',colors='#ccccccff|#ffffffff|#404040ff|#808080ff',onClick='ui_adjbar('..i..'|1)',visibility=PERMEDIT} }
        	            }
        	        })
        			table.insert(settingslist_bars,
        			    {tag='Row', attributes={preferredHeight='30'},
        			        children={
        			            {tag='Cell',children={{tag='InputField',attributes={id='inp_bar_'..i..'_name',onEndEdit='ui_editbar',text=bar[1]or''}}}},
        			            {tag='Cell',children={{tag='InputField',attributes={id='inp_bar_'..i..'_color',onEndEdit='ui_editbar',text=bar[2]or'#ffffff'}}}},
        			            {tag='Cell',children={{tag='InputField',attributes={id='inp_bar_'..i..'_current',onEndEdit='ui_editbar',text=bar[3]or 10}}}},
        			            {tag='Cell',children={{tag='InputField',attributes={id='inp_bar_'..i..'_max',onEndEdit='ui_editbar',text=bar[4]or 10}}}},
                                {tag='Cell',children={{tag='Toggle',attributes={id='inp_bar_'..i..'_text',onValueChanged='ui_editbar',isOn=bar[5]or false}}}},
        			            {tag='Cell',children={{tag='Toggle',attributes={id='inp_bar_'..i..'_big',onValueChanged='ui_editbar',isOn=bar[6]or false}}}},
        			            {tag='Cell',children={{tag='Button',attributes={onClick='ui_removebar('..i..')',image='ui_close',colors='#cccccc|#ffffff|#808080'}}}}
        			        }
        			    })
        			end
local ui_overhead = { tag='Panel', attributes={childForceExpandHeight='false',visibility=PERMVIEW,position='0 -40 -400',rotation=orient=='HORIZONTAL'and'0 0 0'or'-90 0 0',active=ui_mode=='0',scale='0.6 0.6 0.6',height=0,color='red',width=w},
	children={
		{tag='VerticalLayout',attributes={rectAlignment='LowerCenter',childAlignment='LowerCenter',childForceExpandHeight=false,childForceExpandWidth=true,height='5000',spacing='5'},
			children={{tag='GridLayout', attributes={contentSizeFitter='vertical', childAlignment='LowerLeft', flexibleHeight='0', cellSize='50 50', padding='10 10 0 0'}, children=mainlist_markers},{tag='VerticalLayout', attributes={contentSizeFitter='vertical', childAlignment='LowerCenter', flexibleHeight='0'}, children=mainlist_bars},{tag='Panel',attributes={minHeight='30',flexibleHeight='0'}, children=mainButtons }}
		}
	}
}
local ui_settings = {tag='panel', attributes={id='ui_settings',height='0',width=640,position='0 -140 -420',rotation=(orient=='HORIZONTAL'and'0 0 0'or'-90 0 0'),scale='0.6 0.6 0.6',active=(ui_mode ~= '0'),visibility=PERMEDIT},
        			children={{tag='panel',attributes={id='ui_settings_markers', offsetXY='0 40', height='400', rectAlignment='LowerCenter', color='black', active=(ui_mode == 'markers')},
        			children={
        				{tag='VerticalScrollView',attributes={width=640,height='340',rotation='0.1 0 0',rectAlignment='UpperCenter',offsetXY='0 -30',color='transparent'},
        					children={
        						{tag='GridLayout',attributes={padding='6 6 6 6', cellSize='120 120', spacing='2 2', childForceExpandHeight='false', autoCalculateHeight='true'}, children=settingslist_markers}
        					}
        				},
        				{ tag='text', attributes={fontSize='24', height='30', text='MARKERS', color='#cccccc', rectAlignment='UpperLeft', alignment='MiddleCenter'}},
        				{ tag='Button', attributes={width='150', height='30', rectAlignment='LowerRight', text='Clear Markers', onClick='ui_clearmarkers'}},
        			}
        		},{tag='button', attributes={height='40', width='40', rectAlignment='LowerLeft', image='ui_stack', offsetXY='0 0', colors='#ccccccff|#ffffffff|#404040ff|#808080ff', onClick='ui_setmode(markers)'}},{tag='panel', attributes={id='ui_settings_bars',offsetXY='0 40',height='400',rectAlignment='LowerCenter',color='black',active=ui_mode=='bars'},
        			children={
        				{tag='VerticalScrollView', attributes={width=640,height='340',rotation='0.1 0 0',rectAlignment='UpperCenter',color='transparent',offsetXY='0 -30'},
        					children={
        						{tag='TableLayout', attributes={columnWidths='0 100 60 60 30 30 30',childForceExpandHeight='false',cellBackgroundColor='transparent',autoCalculateHeight='true',padding='6 6 6 6'},
        							children=settingslist_bars
        						}
        					}
        				},
        				{tag='text', attributes={fontSize='24',height='30',text='BARS',color='#cccccc',rectAlignment='UpperLeft',alignment='MiddleCenter'} },
        				{tag='Button', attributes={width='150',height='30',rectAlignment='LowerLeft',text='Add Bar',onClick='ui_addbar'} },
        				{tag='Button', attributes={width='150',height='30',rectAlignment='LowerRight',text='Clear Bars',onClick='ui_clearbars'} }
        			}
        		},{tag='button', attributes={height='40', width='40', rectAlignment='LowerLeft', image='ui_bars', offsetXY='40 0', colors='#ccccccff|#ffffffff|#404040ff|#808080ff', onClick='ui_setmode(bars)'}},{tag='button', attributes={height='40', width='40', rectAlignment='LowerCenter', image='ui_close', offsetXY='0 0', colors='#ccccccff|#ffffffff|#404040ff|#808080ff', onClick='ui_setmode(0)'}}}
        		}
local ui_movement = {};
local ui_shields = {}
self.UI.setXmlTable({ui_shields, ui_movement, ui_overhead, ui_settings});
end
