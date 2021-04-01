TRH_Class = 'mini'

local radToDeg = 180 / math.pi
local degToRad = math.pi / 180
local state = {};
local PERMEDIT = 'Grey|Host|Admin|Black|White|Brown|Red|Orange|Yellow|Green|Teal|Blue|Purple|Pink|Clubs|Diamonds|Hearts|Spades|Jokers';
local PERMVIEW = 'Grey|Host|Admin|Black|White|Brown|Red|Orange|Yellow|Green|Teal|Blue|Purple|Pink|Clubs|Diamonds|Hearts|Spades|Jokers';
local ui_mode = '0';
local controller_obj;
local assetBuffer = {};
local arc_len = 1;
local base_radius = 1;
local arc_obj;
local flagged;

local init = false;

local indexOf = function(e, t)
	for k,v in pairs(t) do
		if (e == v) then return k end
	end
	return nil
	end

--LIFE CICLE EVENTS
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
--LIFE CYCLE EVENTS END

--ACTIONS

function recalculateModelSize()
		local desc = self.getData().Description
		
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
			-- b.jointTo(me, {
			-- 	type='Fixed',
			-- 	collision=false
			-- })
			b.setColorTint(clr)
			b.setVar('parent',self)
			b.setLuaScript([[
				local lastParent = nil
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
						if (not parent.resting or lastParent ~= parent) then 
							lastParent = parent
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

	


-- -- MOVE MANAGER

local move_obj;
local move_range_obj;
local selectingMovement = false;
local moveRange = 5;
local moving = false;
local player = nil;
local Move_Steps = {};
local free_moving = false;

local Current_Move_center = Vector(0,0,0);
local Current_Move_centerX =0;
local Current_Move_centerY =0;
local Current_Move_centerZ =0;
local Distance_Left = 5;

function start_move_flow(_player)
	selectingMovement = false;
	moving = true;
	player = _player;
	recalculate_move_center()
	spawnMoveShadow()
	self.setLock(true)
	self.UI.setAttribute('move_click_detection', 'visibility', _player.color)
	self.UI.show('move_click_detection')
end

function abort_move_flow()
	clean_move_flow()
end

function accept_move_flow()
	clean_move_flow()
	self.setPosition(Current_Move_center)
	ui_move_hide()
end

function clean_move_flow()
	selectingMovement = true;
	moving = false;
	free_moving = false;
	if arc_obj ~= nil then
		arc_obj.setVar('parent',self)
	end
	if move_obj ~= nil then
		move_obj.destruct();
	end
	if move_range_obj ~= nil then
		move_range_obj.destruct();
	end
	for key,step in pairs(Move_Steps) do
		if (step.shadow ~= nil) then
			step.shadow.destruct();
		end
	end
	Move_Steps = {};

	self.UI.hide('move_click_detection')
end

function recalculate_move_center()
	local previous_pos = self.getPosition();
	local distance_left = moveRange;
	for key,step in pairs(Move_Steps) do
		distance_left = distance_left - previous_pos:distance(step.pos);
		previous_pos = step.pos;

	end
	Current_Move_center = Vector(previous_pos.x,previous_pos.y,previous_pos.z);
	Current_Move_centerX = previous_pos.x;
	Current_Move_centerY = previous_pos.y;
	Current_Move_centerZ = previous_pos.z;
	Distance_Left = distance_left;

	if move_obj ~= nil then
		move_obj.setVar('centerX',Current_Move_centerX)
		move_obj.setVar('centerY',Current_Move_centerY)
		move_obj.setVar('centerZ',Current_Move_centerZ)
		move_obj.setVar('range',Distance_Left )
	end
	--spawnRangeCircle()
end

function add_move_step()
	if free_moving then
		destination = player.getPointerPosition();
		self.setPosition(destination);
	else
		if Distance_Left > 0.01 then
			destination = Current_Move_center:moveTowards(player.getPointerPosition(),Distance_Left)
			move_obj.setVar('lock',true)
			Move_Steps[#Move_Steps+1] = {pos = destination, shadow = move_obj};
			move_obj = nil;	
			recalculate_move_center();
			if Distance_Left > 0.01 then
				spawnMoveShadow(false)
			end
		end
	end
end

function remove_move_step()
	if free_moving then
		cancel_free_move()
	else
		if #Move_Steps > 0 then
			Move_Steps[#Move_Steps].shadow.destruct()
			table.remove(Move_Steps,#Move_Steps);
			recalculate_move_center();
			if move_obj ~= nil then
				move_obj.destruct()
				move_obj = nil;	
			end
			spawnMoveShadow(false)
		end
	end
end


function start_free_move(_player)
	player = _player;
	free_moving = true;
	
	recalculate_move_center();
	self.UI.setAttribute('move_click_detection', 'visibility', _player.color)
	self.UI.show('move_click_detection')
	spawnMoveShadow(true)

end
function cancel_free_move()
	free_moving = false;
	clean_move_flow();
	self.UI.show('btn_free_move')
	self.UI.hide('btn_cancel_free_move')
end

function spawnMoveShadow(free)

	local a=base_radius * 2;
	local me = self
	local clr = self.getColorTint()

	
	clr.a = 0.5;

		move_obj=spawnObject({
		type='custom_model',
		position=Current_Move_center,
		rotation=Vector(0,0,0),
		scale={a,1,a},
		mass=0,
		use_gravity=false,
		sound=false,
		snap_to_grid=false,
		callback_function=function(b)
			if arc_obj ~= nil then
				arc_obj.setVar('parent',b)
			end
			b.setColorTint(clr)
			b.setVar('model',self)
			b.setVar('player',player)
			-- b.setVar('center',{x=Current_Move_centerX,y=Current_Move_centerY,z=Current_Move_centerZ})
			b.setVar('centerX',Current_Move_centerX)
			b.setVar('centerY',Current_Move_centerY)
			b.setVar('centerZ',Current_Move_centerZ)
			b.setVar('range',free and 200 or Distance_Left)
			b.setVar('maxRange',free and 200 or moveRange)
			b.setVar('lock',false)
			

			b.setLuaScript([[
				local lastPointer = {};
				local UIinit = 2
				function onLoad() 
					(self.getComponent('BoxCollider') or self.getComponent('MeshCollider')).set('enabled',false)
					Wait.condition(
						function() 
							(self.getComponent('BoxCollider') or self.getComponent('MeshCollider')).set('enabled',false) 
							self.UI.setXmlTable({DirectionFeedBack()})
							
						end, 
						function() 
							return not(self.loading_custom) 
						end
					) 
				end 
				function onUpdate() 
					
					if (model ~= nil and player ~= nil) then 
						
						if lock == false and lastPointer ~= player.getPointerPosition() and UIinit < 0 then
							lastPointer = player.getPointerPosition()
							local center = Vector(centerX,centerY,centerZ);
							local destination = center:copy():moveTowards(lastPointer,range)
							self.setPosition(destination)
						
						
							 local angle = math.atan2(destination.z - center.z, center.x-destination.x  ) * 180 / math.pi  + 90;
							
							local zDist = destination.z - center.z;
							local xDist = center.x - destination.x ;
							local distance = math.sqrt(zDist* zDist + xDist * xDist)
							if ]].. (not free and 'true' or 'false') .. [[ then
							self.UI.setAttribute('move_trail','height',distance * 50 / ]]..base_radius..[[ )
							end
							self.UI.setAttribute('current_mov_dist','text',(maxRange - range + distance + 0.04)..'¨' )
							self.setRotation({x=0,y=angle,z=0})
						else
							UIinit = UIinit -1
						end
					else
						self.destruct() 
					end 
					
				end
								
				function DirectionFeedBack()
					local ui_direction = { 
						tag='Panel', 
						attributes={
							childForceExpandHeight='false',
							position='0 0 -10',
							rotation='0 0 0',
							scale='1 1 1',
							height=0,
							color='#aaaa3355',
							width=0
						},
						children={
							{
								tag='Panel',
								attributes={
									id='move_trail',
									rectAlignment='LowerCenter',
									height='0',
									width='100',
									spacing='5',
									color='#aaaa3355',
								}
							},
							{
								tag='text',
								attributes={
									id='current_mov_dist',
									height='30',
									width='30', 
									rectAlignment='MiddleCenter',
									text='¨', 
									offsetXY='0 0 -20',
									color='#22ee22',
									fontSize='20',
									outline='#000000'
								}
							}
						}
					}
					return ui_direction;
				end
				function ui_add_move_step()
					print("click on move step")
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
	move_obj.setCustomObject({
		-- mesh='https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/components/arcs/round0.obj',
		mesh='http://cloud-3.steamusercontent.com/ugc/922542758751649800/E140136A8F24712A0CE7E63CF05809EE5140A8B7/',
		collider='https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/utility/null_COL.obj',
		material=3,
		specularIntensity=0,
		cast_shadows=false
	})
end

function spawnRangeCircle()
	
	if move_range_obj ~= nil then
		move_range_obj.destruct();
	end
	local a=(base_radius  + Distance_Left );
	local me = self
	local clr = {r=0.2,g=0.9,b=0.3,a =0.5};
	
	-- clr.a = 0.3;

	move_range_obj=spawnObject({
		type='custom_model',
		position=Current_Move_center,
		rotation=Vector(0,0,0),
		scale={a,1.3,a},
		mass=0,
		use_gravity=false,
		sound=false,
		snap_to_grid=false,
		callback_function=function(b)
			b.setColorTint(clr)
			b.setVar('model',self)
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
					
					if (model == nil) then 
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
	move_range_obj.setCustomObject({
		mesh='https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/components/arcs/round0.obj',
		
		collider='https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/utility/null_COL.obj',
		material=3,
		specularIntensity=0,
		cast_shadows=false
	})
end

-- -- MOVE MANAGER END

--ACTIONS END


--UI GENERATION

--UI GENERATION END


--UI TRIGERED EVENTS
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
function ui_popmarker(player,value) popMarker({index=value}) end
function ui_clearmarkers(player) clearMarkers() end
--UI TRIGERED EVENTS END
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
	
	self.UI.setXmlTable({ UI_Move_Click_Detection(), UI_Floor(),UI_Overhead(), UI_Config()});
	end

function UI_Overhead()
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
					UI_Bars_Container(false),
				}
			},
			
		}
	}
	return ui_overhead;
	end

function UI_Floor()
	local ui_floor = { 
		tag='Panel', 
		attributes={
			childForceExpandHeight='false',
			position='0 0 -4',
			rotation='0 0 0',
			active=ui_mode=='0',
			scale='1 1 1',
			height=0,
			color='red',
			width=0
		},
		children={
			{
				tag='VerticalLayout',
				attributes={
					rectAlignment='MiddleCenter',
					childAlignment='MiddleCenter',
					childForceExpandHeight=true,
					childForceExpandWidth=true,
					height='5000',
					spacing='5'
				},
				children={
					UI_Buttons_Container()
				}
			}
		}
	}
	return ui_floor;
	end

function UI_Move_Click_Detection()
	local ui_move_detection = { 
		tag='Panel', 
		attributes={
			childForceExpandHeight='false',
			position='0 0 1000',
			rotation='0 0 0',
			scale='1 1 1',
			height=0,
			width=0,
		},
		children={
			{
				
					tag='button', 
					attributes={
						id='move_click_detection', 
						height='40000', 
						width='40000', 
						rectAlignment='MiddleCenter', 
						image='movenode', 
						offsetXY='0 0 40', 
						rotation= '0 0 0',
						colors='#cccccc00|#bbffbb00|#40404000|#80808000', 
						onClick='ui_add_move_step',
						active= moving
					}
				
			}
		}
	}
	return ui_move_detection;
	
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
function UI_Bars_Container(reverse)
	return {
		tag='VerticalLayout', 
		attributes={
			contentSizeFitter='vertical',
			childAlignment='LowerCenter',
			flexibleHeight='0'
			},
		children=UI_Bars(reverse)
	}
	end
function UI_Buttons_Container()
	return {
		tag='Panel',
		attributes={
			minHeight='0',
			flexibleHeight='0'
		}, 
		children=UI_Buttons_Circle() 
	}
	end
function UI_Config()
	local orient = 'HORIZONTAL';
	local ui_config = {tag='panel', attributes={id='ui_config',height='0',width=640,position='0 -140 -420',rotation=(orient=='HORIZONTAL'and'0 0 0'or'-90 0 0'),scale='0.6 0.6 0.6',active=(ui_mode ~= '0'),visibility=PERMEDIT},
		children={{tag='panel',attributes={id='ui_settings_markers', offsetXY='0 40', height='400', rectAlignment='LowerCenter', color='black', active=(ui_mode == 'markers')},
		children={
			{tag='VerticalScrollView',attributes={width=640,height='340',rotation='0.1 0 0',rectAlignment='UpperCenter',offsetXY='0 -30',color='transparent'},
				children={
					{tag='GridLayout',attributes={padding='6 6 6 6', cellSize='120 120', spacing='2 2', childForceExpandHeight='false', autoCalculateHeight='true'}, children=CONF_Markers()}
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
						children=CONF_Bars()
					}
				}
			},
			{tag='text', attributes={fontSize='24',height='30',text='BARS',color='#cccccc',rectAlignment='UpperLeft',alignment='MiddleCenter'} },
			{tag='Button', attributes={width='150',height='30',rectAlignment='LowerLeft',text='Add Bar',onClick='ui_addbar'} },
			{tag='Button', attributes={width='150',height='30',rectAlignment='LowerRight',text='Clear Bars',onClick='ui_clearbars'} }
		}
	},{tag='button', attributes={height='40', width='40', rectAlignment='LowerLeft', image='ui_bars', offsetXY='40 0', colors='#ccccccff|#ffffffff|#404040ff|#808080ff', onClick='ui_setmode(bars)'}},{tag='button', attributes={height='40', width='40', rectAlignment='LowerCenter', image='ui_close', offsetXY='0 0', colors='#ccccccff|#ffffffff|#404040ff|#808080ff', onClick='ui_setmode(0)'}}}
	}

	return ui_config;
	end


function UI_Buttons()
	local buttons = {};
	local mainButtonX = 20;
	local arcActive = arc_obj ~= nil;
	table.insert(buttons, UI_Button('btn_show_arc'	,not arcActive				,'MiddleLeft'	,'ui_arcs'	,mainButtonX..' 0'	,'ui_showarc'));
	table.insert(buttons, UI_Button('btn_hide_arc'	,arcActive					,'LowerLeft'	,'ui_arcs'	,mainButtonX..' 0'	,'ui_hidearc'));
	table.insert(buttons, UI_Button('btn_arc_sub'	,arcActive and arc_len > 0	,'LowerLeft'	,'ui_minus'	,'-70 0'			,'ui_arcsub'));
	table.insert(buttons, {tag='text', attributes={id='disp_arc_len', active=(arcActive), height='30', width='30', rectAlignment='LowerLeft', text=arc_len, offsetXY='-40 0', color='#ffffff', fontSize='20', outline='#000000', visibility=PERMEDIT}});
	table.insert(buttons, UI_Button('btn_arc_add'	,arcActive and arc_len < 16	,'LowerLeft'	,'ui_plus'	,'-10 0'			,'ui_arcadd'));

	table.insert(buttons, UI_Button('btn_markers',true,'MiddleRight','ui_gear','-50 0','ui_setmode(markers)'));
	table.insert(buttons, UI_Button('btn_refresh',true,'MiddleRight','ui_reload','-20 0','rebuildUI'));
	table.insert(buttons, UI_Button('btn_move',true,'LowerRight','ui_splitpath','0 0','rebuildUI'));
	
	return buttons;
	end



	

function ui_move_open()
	selectingMovement = true;
	moving = false
	self.UI.hide('btn_show_move')
	self.UI.show('btn_hide_move')
	self.UI.show('disp_mov_dist')
	self.UI.show('btn_move_sub')
	self.UI.show('btn_move_add')
	self.UI.show('btn_move_start')
	self.UI.hide('btn_move_abort')
	end
function ui_move_hide()
	selectingMovement = false;
	moving = false
	self.UI.show('btn_show_move')
	self.UI.hide('btn_hide_move')
	self.UI.hide('disp_mov_dist')
	self.UI.hide('btn_move_sub')
	self.UI.hide('btn_move_add')
	self.UI.hide('btn_move_start')
	self.UI.hide('btn_move_abort')
	self.UI.hide('btn_move_accept')
	end
function ui_move_sub()
	moveRange = math.min(30,moveRange - 1);
	
	self.UI.setAttribute('disp_mov_dist','text',moveRange .. '¨')
	end
function ui_move_add()
	moveRange = math.max(1,moveRange + 1);
		
	self.UI.setAttribute('disp_mov_dist','text',moveRange .. '¨')
	end
function ui_move_start(_player, _color, alt_click)
	start_move_flow(_player)
	self.UI.hide('btn_show_move')
	self.UI.hide('btn_hide_move')
	self.UI.hide('disp_mov_dist')
	self.UI.hide('btn_move_sub')
	self.UI.hide('btn_move_add')
	self.UI.hide('btn_move_start')
	self.UI.show('btn_move_abort')
	
end
function ui_add_move_step(_player,alt_click)
	if alt_click == '-1' then
		add_move_step()
	end
	if alt_click == '-2' then
		remove_move_step()
	end

	if #Move_Steps > 0 then
		self.UI.show('btn_move_accept')
	else
		self.UI.hide('btn_move_accept')
	end

end
function ui_move_abort()
	abort_move_flow()
	self.UI.hide('btn_show_move')
	self.UI.show('btn_hide_move')
	self.UI.show('disp_mov_dist')
	self.UI.show('btn_move_sub')
	self.UI.show('btn_move_add')
	self.UI.show('btn_move_start')
	self.UI.hide('btn_move_abort')
	self.UI.hide('btn_move_accept')
end

function ui_move_accept()
	accept_move_flow()
	self.UI.show('btn_show_move')
	self.UI.hide('btn_hide_move')
	self.UI.hide('disp_mov_dist')
	self.UI.hide('btn_move_sub')
	self.UI.hide('btn_move_add')
	self.UI.hide('btn_move_start')
	self.UI.hide('btn_move_abort')
	self.UI.hide('btn_move_accept')
end

function ui_move_free(_player)
	self.UI.hide('btn_free_move')
	self.UI.show('btn_cancel_free_move')
	start_free_move(_player)
end

function ui_cancel_move_free()
	self.UI.show('btn_free_move')
	self.UI.hide('btn_cancel_free_move')
	cancel_free_move(_player)
end

function toggleFlag()
	flagged = not flagged;
	if flagged then
		self.UI.show('btn_flag_true')
		self.UI.hide('btn_flag_false')
		self.UI.setAttribute('bar_1_container','color','#ffff0055');
		
	else
		self.UI.hide('btn_flag_true')
		self.UI.show('btn_flag_false')
		self.UI.setAttribute('bar_1_container','color','#ffff0000');
	end

end


function UI_Buttons_Circle()
	local buttons = {};
	local mainButtonX = 20;
	local arcActive = arc_obj ~= nil;
	local radius = 65;
	
	local angleStep = 30 * degToRad;

	-- arc UI
	table.insert(buttons, UI_Button('btn_show_arc'	,not arcActive				,'MiddleCenter'	,'ui_arcs'	,CircularOffset(angleStep * -1,radius)	,'ui_showarc',CircularRotation(angleStep * -1)));
	table.insert(buttons, UI_Button('btn_hide_arc'	,arcActive					,'MiddleCenter'	,'ui_arcs'	,CircularOffset(angleStep * -1,radius)	,'ui_hidearc',CircularRotation(angleStep * -1), '#cccc44ff|#ffff22ff|#404040ff|#808080ff'));

	table.insert(buttons, UI_Button('btn_arc_sub'	,arcActive and arc_len > 0	,'MiddleCenter'	,'ui_minus'	,CircularOffset(angleStep * -0.5,radius+25)				,'ui_arcsub',CircularRotation(angleStep * -1)));
	table.insert(buttons, {tag='text', attributes={id='disp_arc_len', active=(arcActive), height='30', width='30', rectAlignment='MiddleCenter', text=arc_len, offsetXY=CircularOffset(angleStep * -1,radius+20),rotation=CircularRotation(angleStep * -1), color='#ffffff', fontSize='20', outline='#000000'}});
	table.insert(buttons, UI_Button('btn_arc_add'	,arcActive and arc_len < 16	,'MiddleCenter'	,'ui_plus'	,CircularOffset(angleStep * -1.5,radius+25)				,'ui_arcadd',CircularRotation(angleStep * -1)));

	
	-- move config UI 
	table.insert(buttons, UI_Button('btn_show_move',not selectingMovement ,'MiddleCenter','ui_splitpath',CircularOffset(angleStep * 1,radius),'ui_move_open',CircularRotation(angleStep * 1)));
	table.insert(buttons, UI_Button('btn_hide_move'	,selectingMovement   ,'MiddleCenter'	,'ui_splitpath'	,CircularOffset(angleStep * 1,radius)	,'ui_move_hide',CircularRotation(angleStep * 1)));
	table.insert(buttons, UI_Button('btn_move_sub'	,selectingMovement and moveRange > 0	,'MiddleCenter'	,'ui_minus'	,CircularOffset(angleStep * 1.7,radius+5)				,'ui_move_sub',CircularRotation(angleStep * 1)));
	table.insert(buttons, UI_Button('btn_move_add'	,selectingMovement and moveRange < 30	,'MiddleCenter'	,'ui_plus'	,CircularOffset(angleStep * 0.3,radius+5)				,'ui_move_add',CircularRotation(angleStep * 1)));
	

	-- move start UI 
	table.insert(buttons, UI_Button('btn_move_start'	,selectingMovement	,'MiddleCenter'	,'movenode'	,CircularOffset(angleStep * 1,radius+20),'ui_move_start',CircularRotation(angleStep * 1+ math.pi)));
	table.insert(buttons, {tag='text', attributes={id='disp_mov_dist', active=(selectingMovement), height='30', width='30', rectAlignment='MiddleCenter', text=moveRange .. '¨', offsetXY=CircularOffset(angleStep * 1,radius+20),rotation=CircularRotation(angleStep * 1 ), color='#22ee22', fontSize='20', outline='#000000'}});
	table.insert(buttons, UI_Button('btn_move_abort'	,moving	,'MiddleCenter'	,'ui_plus'	,CircularOffset(angleStep * 0.5,radius),'ui_move_abort',CircularRotation(angleStep * 0.5+ math.pi/4), '#cc4444ff|#ff2222ff|#404040ff|#808080ff'));
	table.insert(buttons, UI_Button('btn_move_accept'	,moving and #Move_Steps > 0	,'MiddleCenter'	,'ui_check'	,CircularOffset(angleStep * 1.5,radius),'ui_move_accept',CircularRotation(angleStep * 1.5), '#44cc44ff|#22ff22ff|#404040ff|#808080ff'));
		

	-- move free
	table.insert(buttons, UI_Button('btn_free_move',not free_moving,'MiddleCenter','movenode',CircularOffset(angleStep * -3.5,radius),'ui_move_free',CircularRotation(angleStep * -3.5)));
	table.insert(buttons, UI_Button('btn_cancel_free_move',free_moving,'MiddleCenter','ui_plus',CircularOffset(angleStep * -3.5,radius),'ui_cancel_move_free',CircularRotation(angleStep * -3.5 + 45),'#cc4444ff|#ff2222ff|#404040ff|#808080ff'));

	-- config UI
	table.insert(buttons, UI_Button('btn_markers',true,'MiddleCenter','ui_gear',CircularOffset(angleStep * 3,radius),'ui_setmode(markers)',CircularRotation(angleStep * 2.5)));
	table.insert(buttons, UI_Button('btn_refresh',true,'MiddleCenter','ui_reload',CircularOffset(angleStep * -4.5,radius),'rebuildUI',CircularRotation(angleStep * -4.5)));

	table.insert(buttons, UI_Button('btn_flag_true',flagged,'MiddleCenter','ui_flag',CircularOffset(angleStep * -2.5,radius),'toggleFlag',CircularRotation(angleStep * -2.5), '#cccc44ff|#ffff22ff|#404040ff|#808080ff'));
	table.insert(buttons, UI_Button('btn_flag_false',not flagged,'MiddleCenter','ui_flag',CircularOffset(angleStep * -2.5,radius),'toggleFlag',CircularRotation(angleStep * -2.5)));

	
	return buttons;
	end
function CircularOffset(angle,radius)
	angle = angle + math.pi;
	return math.sin(angle)*radius .. ' ' .. math.cos(angle)*radius;
	end
function CircularRotation(angle,radius)
	angle = angle + math.pi;
	return '0 0 ' ..  (180 -angle * radToDeg );
	end
function UI_Button(id,active,alignment,img,offsetXY,onClick,rotation,paramcolor)
	local color = paramcolor or '#ccccccff|#bbffbbff|#404040ff|#808080ff';
	return {
		tag='button', 
		attributes={
			id=id, 
			active=active, 
			height='30', 
			width='30', 
			rectAlignment=alignment, 
			image=img, 
			offsetXY=offsetXY, 
			rotation= rotation,

			colors=color, 
			onClick=onClick
		}};
	end
function UI_Markers()
	local markers = {}
	for i,marker in pairs(state.markers) do
		table.insert(markers,{tag='panel',attributes={},
							children={
								{tag='image',attributes={image=assetBuffer[marker[2]],color=marker[3],rectAlignment='LowerLeft',width='40',height='40'}},
								{tag='text',attributes={id='counter_mk_'..i,text=marker[4]>1 and marker[4]or'',color='#ffffff',rectAlignment='UpperRight',width='20',height='20'}}
							}
						});

	end;
	return markers;
	end
	--TEST ERROR
function CONF_Markers()
	local markers = {};
	for i,marker in pairs(state.markers) do
	
		table.insert(markers,{tag='panel',attributes={color='#cccccc'},
						children={
							{tag='image',attributes={width=90,height=90,image=assetBuffer[marker[2]],color=marker[3],rectAlignment='MiddleCenter'}},
							{tag='text',attributes={id='disp_mk_'..i,width=30,height=30,fontSize=20,text=marker[4]>1 and marker[4]or'',rectAlignment='UpperLeft',alignment='MiddleLeft',offsetXY='5 0'}},
							{tag='button',attributes={width=30,height=30,image='ui_close',rectAlignment='UpperRight',colors='black|#808080|#cccccc',alignment='UpperRight',onClick='ui_popmarker('..i..')'}},
							{tag='text',attributes={width=110,height=30,rectAlignment='LowerCenter',resizeTextMinSize=10,resizeTextMaxSize=14,resizeTextForBestFit=true,fontStyle='Bold',text=marker[1],color='Black',alignment='LowerCenter'}}
						}
					});
	end;
	return markers;
	end
function UI_Bars(reverse)
	local bars = {};
	for i,bar in pairs(state.bars) do
		local per = ((bar[4] == 0) and 0 or (bar[3] / bar[4] * 100))

		local increaseButton = {tag='button', attributes={preferredHeight='20',preferredWidth='20',flexibleWidth='0',image='ui_plus',colors='#ccccccff|#ffffffff|#404040ff|#808080ff',onClick='ui_adjbar('..i..'|1)',visibility=PERMEDIT} };
		local decreaseButton = {tag='button', attributes={preferredHeight='20',preferredWidth='20',flexibleWidth='0',image='ui_minus',colors='#ccccccff|#ffffffff|#404040ff|#808080ff',onClick='ui_adjbar('..i..'|-1)',visibility=PERMEDIT} };
		local bar ={tag='panel', attributes={flexibleWidth='1',flexibleHeight='1'},
			children={
				{tag='progressbar', attributes={width='100%',height='25',id='bar_'..i,color='#00000080',fillImageColor=bar[2],percentage=per,textColor='transparent'} },
				{tag='text', attributes={id='bar_'..i..'_text',text=bar[3]..' / '..bar[4],active=bar[5]or false,color='#ffffff',fontStyle='Bold',outline='#000000',outlineSize='1 1'} }
			}
		}
		if reverse then
			local intermediate = increaseButton;
			increaseButton = decreaseButton;
			decreaseButton = intermediate;
			bar = {tag='panel', attributes={flexibleWidth='1',flexibleHeight='1'},
			children={
				{tag='progressbar', attributes={width='100%',height='100%',id='bar_'..i..'_b',color='#00000000',fillImageColor='#00000000',percentage=0,textColor='transparent'} },
				{tag='text', attributes={id='bar_'..i..'_text_b',text=' ',active=bar[5]or false,color='#ffffff00',fontStyle='Bold',outline='#00000000',outlineSize='1 1'} }
			}
		}
		end
		table.insert(bars,
		{tag='horizontallayout', 
			attributes={
				id='bar_'..i..'_container',
				minHeight= '28' ,
				childForceExpandWidth=false,
				childForceExpandHeight=false,
				childAlignment='MiddleCenter',
				
			},
			children={
				decreaseButton,
				bar,
				increaseButton
			}
		})
	end
	return bars;
	end
function CONF_Bars()
	local bars = {{tag='Row',attributes={preferredHeight='30'},children={
		{tag='Cell',children={{tag='Text',attributes={color='#cccccc',text='Name'}}}},
		{tag='Cell',children={{tag='Text',attributes={color='#cccccc',text='Color'}}}},
		{tag='Cell',children={{tag='Text',attributes={color='#cccccc',text='Current'}}}},
		{tag='Cell',children={{tag='Text',attributes={color='#cccccc',text='Max'}}}},
		{tag='Cell',children={{tag='Text',attributes={color='#cccccc',text='Text'}}}},
		{tag='Cell',children={{tag='Text',attributes={color='#cccccc',text='Big'}}}},
	}}}
	for i,bar in pairs(state.bars) do
		
		table.insert(bars,
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

	return bars;
end