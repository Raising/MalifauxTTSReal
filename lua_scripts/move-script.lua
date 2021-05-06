local MoveState = {};

local MenuManager = nil
local MenuManagerGUID = "15fc7f";

------------ LIFE CICLE EVENTS --------------------

	function onLoad()
		MenuManager = getObjectFromGUID(MenuManagerGUID);
		InitMoveState()
	end

------------ STATE INITIALIZATION ------------------

function DefaultPlayer()
	return {
		active = false,
		object_target = nil,
		object_target_guid = '-1',
		
		moving = false,
		movingPlayer = '',
		currentMoveCenter = Vector(0,0,0),
		moveSteps = {},
		moveRange = 5,
		currentMoveCenterX = 0,
		currentMoveCenterY = 0,
		currentMoveCenterZ = 0,
		distanceLeft = 0,
		free_moving = false,
		destination	= Vector(0,0,0),

		move_obj = nil,
		mouse_obj = nil,
		doubleClickDetector = false,
	}
end

function InitMoveState()
	MoveState.Blue = DefaultPlayer()
	MoveState.Red = DefaultPlayer()
	MoveState.Black = DefaultPlayer()
end


------------- ACTIONS ------------------------------

	function SetMenuManager(params)
		MenuManager = params.menuManager;
	end
	function SelectPlayerMovingObject(color,objectGUID)
	end

------ MOVEMENT RUTINE ----------------------

	function StartControledMove(params)
		local color = params.color;
		local targetObj = params.obj;

		print( 'player ' .. color .. ' ctrl moving  '.. targetObj.getGUID()  );
		MoveState[color].active = 'true';
		MoveState[color].moving = true;
		MoveState[color].movingPlayer = GetPlayerFromColor(color);
		MoveState[color].object_target = params.obj;
		MoveState[color].object_target_guid = params.obj.getGUID();

		recalculate_move_center(color)
		spawnMoveShadow(color,false)
		spawnMouseChaser(color)
		MoveState[color].object_target.setLock(true) -- TODO Lock model?
		MoveState[color].object_target.setRotation(Vector(0,MoveState[color].object_target.getRotation().y,0))
	end

	function StartFreeMove(params)
		local color = params.color;
		local targetObj = params.obj;
		print( 'player ' .. color .. ' ctrl moving  '.. targetObj.getGUID()  );

		MoveState[color].active = true;
		MoveState[color].free_moving = true;
		MoveState[color].movingPlayer =  GetPlayerFromColor(color);
		MoveState[color].object_target = params.obj;
		MoveState[color].object_target_guid = params.obj.getGUID();
		
		recalculate_move_center(color);
		MoveState[color].object_target.setLock(true) -- TODO Lock model?
		MoveState[color].object_target.setRotation(Vector(0,MoveState[color].object_target.getRotation().y,0))
		
		spawnMoveShadow(color,true)
		spawnMouseChaser(color)
	end

	function AbortMove(params)
		local color = params.color;
		clean_move_flow(color)
	end

	function CompleteMove(params)
		local color = params.color;
		
		if #(MoveState[color].moveSteps) == 0 then
			MoveState[color].destination = MoveState[color].movingPlayer.getPointerPosition();
			MoveState[color].object_target.setPosition(MoveState[color].destination)
		else
			MoveState[color].object_target.setPosition(MoveState[color].currentMoveCenter)
		end
		
		clean_move_flow(color)
	end
	
	function ModifyMoveRange(params)
		local color = params.color;
		local amount = params.amount;
		MoveState[color].moveRange = math.max(MoveState[color].moveRange + params.amount, 0);
		recalculate_move_center(color);
	end

	function SetMoveRange(params)
		local color = params.color;
		local amount = params.amount;
		MoveState[color].moveRange = params.amount;
		recalculate_move_center(color);
	end

	function AddMoveStep(params)
		local color = params.color;

		if MoveState[color].free_moving then
			CompleteMove(params)
		else
			if MoveState[color].distanceLeft > 0.01 then
				local horizontalTarget = MoveState[color].movingPlayer.getPointerPosition();
				horizontalTarget.y = MoveState[color].currentMoveCenter.y;
				MoveState[color].destination = MoveState[color].currentMoveCenter:moveTowards(horizontalTarget,MoveState[color].distanceLeft)
			
				local hits = Physics.cast({
					origin       = MoveState[color].destination:add(Vector(0,20,0)),
					direction    = {0,-1,0},
					type         = 1,
					max_distance = 30,
				});
				local index = 1;
				
				while hits[index].hit_object.getVar("RSS_Class") ~= nil do
					index = index +1;
				end
				MoveState[color].destination.y  = hits[index].point.y;

				MoveState[color].move_obj.setVar('lock',true)
				MoveState[color].move_obj.setPosition(MoveState[color].destination);
				MoveState[color].moveSteps[#MoveState[color].moveSteps+1] = {pos = MoveState[color].destination, shadow = MoveState[color].move_obj};
				MoveState[color].move_obj = nil;	
				recalculate_move_center(color);
				spawnMoveShadow(color,false)
			end

			if MoveState[color].doubleClickDetector == true then
				CompleteMove(params);
			else	
				Wait.time( function() MoveState[color].doubleClickDetector =false;end,0.3);
				MoveState[color].doubleClickDetector = true;
			end
		end
	end

	function RemoveMoveStep(params)
		local color = params.color;
		
		if MoveState[color].free_moving then
			AbortMove({color=color})
		else
			if #MoveState[color].moveSteps > 0 then
				MoveState[color].moveSteps[#MoveState[color].moveSteps].shadow.destruct()
				table.remove(MoveState[color].moveSteps,#MoveState[color].moveSteps);
				recalculate_move_center(color);
				if MoveState[color].move_obj ~= nil then
					MoveState[color].move_obj.destruct()
					MoveState[color].move_obj = nil;	
				end
				spawnMoveShadow(color,false)
			else
				AbortMove({color=color})
			end
		end
	end

	function clean_move_flow(color)
		MoveState[color].active = false;
		MoveState[color].moving = false;
		MoveState[color].free_moving = false;
		MoveState[color].object_target.call("AuraResetFollow");
		MoveState[color].object_target = nil;
		MoveState[color].object_target_guid = '-1';

		if MoveState[color].move_obj ~= nil then
			MoveState[color].move_obj.destruct();
		end

		if MoveState[color].mouse_obj ~= nil then
			MoveState[color].mouse_obj.destruct();
		end
		for key,step in pairs(MoveState[color].moveSteps) do
			if (step.shadow ~= nil) then
				step.shadow.destruct();
			end
		end
		MoveState[color].moveSteps = {};
		MenuManager.call('CleanMovement',{color=color})
	end

	function recalculate_move_center(color)
		local previous_pos = MoveState[color].object_target.getPosition();
		local distDiff = MoveState[color].moveRange;
		for key,step in pairs(MoveState[color].moveSteps) do
			distDiff = distDiff - previous_pos:distance(step.pos);
			previous_pos = step.pos;
		end
		MoveState[color].currentMoveCenter = Vector(previous_pos.x,previous_pos.y,previous_pos.z);
		MoveState[color].currentMoveCenterX = previous_pos.x;
		MoveState[color].currentMoveCenterY = previous_pos.y;
		MoveState[color].currentMoveCenterZ = previous_pos.z;
		MoveState[color].distanceLeft = distDiff;

		if MoveState[color].move_obj ~= nil then
			MoveState[color].move_obj.setVar('centerX',MoveState[color].currentMoveCenterX)
			MoveState[color].move_obj.setVar('centerY',MoveState[color].currentMoveCenterY)
			MoveState[color].move_obj.setVar('centerZ',MoveState[color].currentMoveCenterZ)
			MoveState[color].move_obj.setVar('range',MoveState[color].free_moving and 200 or MoveState[color].distanceLeft)
			MoveState[color].move_obj.setVar('maxRange',MoveState[color].free_moving and 200 or MoveState[color].moveRange)
		end
	end


----------- OBJECT SPAWNER --------------------------

	function spawnMoveShadow(color,free)
		local bound = MoveState[color].object_target.getBoundsNormalized();
		
		local objectScale = MoveState[color].object_target.getScale().x;
		--local a=(state.base.size/50) * 2;
		local me = MoveState[color].object_target
		local clr = MoveState[color].object_target.getColorTint()
		--PrintTable(bound.size,"bound");
		clr.a = 0.5;

			MoveState[color].move_obj=spawnObject({
			type='custom_model',
			position=MoveState[color].currentMoveCenter,
			rotation=Vector(0,0,0),
			scale={bound.size.x,1,bound.size.z},
			mass=0,
			use_gravity=false,
			sound=false,
			snap_to_grid=false,
			callback_function=function(b)
				MoveState[color].object_target.call("AuraFollowObject",{obj = b});
				
				b.setColorTint(clr)
				b.setVar('model',MoveState[color].object_target)
				
				b.setVar('movingPlayer',MoveState[color].movingPlayer)
				b.setVar('centerX',MoveState[color].currentMoveCenterX)
				b.setVar('centerY',MoveState[color].currentMoveCenterY)
				b.setVar('centerZ',MoveState[color].currentMoveCenterZ)
				b.setVar('range',free and 200 or MoveState[color].distanceLeft)
				b.setVar('maxRange',free and 200 or MoveState[color].moveRange)
				b.setVar('lock',false)
				

				b.setLuaScript([[
					local lastPointer = Vector(0,0,0);
					local UIinit = 2
					local clock = 5;
		
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
						
							if (model ~= nil and movingPlayer ~= nil) then 
								
								if lock == false and movingPlayer.getPointerPosition():distance(lastPointer) and UIinit < 0 then
									lastPointer = movingPlayer.getPointerPosition()
									local center = Vector(centerX,centerY,centerZ);
									local horizontalPointer = lastPointer:copy();
									horizontalPointer.y = centerY;
									local destination = center:copy():moveTowards(horizontalPointer,range)
								
									self.setPosition(destination)
									local angle = math.atan2(destination.z - center.z, center.x-destination.x  ) * 180 / math.pi  + 90;
									self.setRotation({x=0,y=angle,z=0})
									
									if (clock < 0) then
										clock = 1;
										local zDist = destination.z - center.z;
										local xDist = center.x - destination.x ;
										local distance = math.sqrt(zDist* zDist + xDist * xDist)
										if ]].. (not free and 'true' or 'false') .. [[ then
											self.UI.setAttribute('move_trail','height',distance * 100/ ]]..bound.size.x..[[ )
										end
										self.UI.setAttribute('current_mov_dist','text',(math.floor((maxRange - range + distance + 0.04)*10)/10) .. '¨' )
									else
										clock = clock -1;
									end
									
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
										width='70', 
										rectAlignment='MiddleCenter',
										text='¨', 
										offsetXY='0 0 0',
										rotation='0 0 180',
										color='#22ee22',
										fontSize='20',
										outline='#000000',
									}
								}
							}
						}
						return ui_direction;
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
		MoveState[color].move_obj.setCustomObject({
			-- mesh='https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/components/arcs/round0.obj',
			mesh='http://cloud-3.steamusercontent.com/ugc/922542758751649800/E140136A8F24712A0CE7E63CF05809EE5140A8B7/',
			collider='https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/utility/null_COL.obj',
			material=3,
			specularIntensity=0,
			cast_shadows=false
		})
	end

	function spawnMouseChaser(color,free)
		
		local me = MoveState[color].object_target
	
		local clr = MoveState[color].object_target.getColorTint()
		
		clr.a = 0;

			MoveState[color].mouse_obj=spawnObject({
			type='custom_model',
			position=MoveState[color].currentMoveCenter,
			rotation=Vector(0,0,0),
			scale={1,1,1},
			mass=0,
			use_gravity=false,
			sound=false,
			snap_to_grid=false,
			callback_function=function(b)
				
				
				b.setColorTint(clr)
				
				b.setVar('moveManager',self)
				b.setVar('movingPlayer',MoveState[color].movingPlayer)
				
				b.setLuaScript([[
					local lastPointer = Vector(0,0,0);
					local UIinit = 2
					local clock = 5
					function onLoad() 
						(self.getComponent('BoxCollider') or self.getComponent('MeshCollider')).set('enabled',false)
						Wait.condition(
							function() 
								(self.getComponent('BoxCollider') or self.getComponent('MeshCollider')).set('enabled',false) 
								self.UI.setXmlTable({ClickHolder()})
								
							end, 
							function() 
								return not(self.loading_custom) 
							end
						) 
					end 
					function onUpdate() 
						if (movingPlayer ~= nil) then 
							if clock < 0 then
								clock = 10;
								if movingPlayer.getPointerPosition():distance(lastPointer) > 0.1 then
									lastPointer = movingPlayer.getPointerPosition()
									self.setPosition(lastPointer:add(Vector(0,0.3,0)))
								end
							else
								clock = clock -1;
							end
						else
							self.destruct() 
						end 
					end
									
					function ClickHolder()
						local ui_click_holder = { 
							tag='Panel', 
							attributes={
								childForceExpandHeight='false',
								position='0 0 0',
								rotation='0 0 0',
								scale='1 1 1',
								height=200,
								color='#00000000',
								width=200,
								onClick='sendClick',
								visibility=']]..color..[['
							}
						}
						return ui_click_holder;
					end

					function sendClick(player,alt_click)
						if alt_click == '-1' then
							moveManager.call("AddMoveStep",{color=player.color})
						else
							if alt_click == '-2' then
								moveManager.call("RemoveMoveStep",{color=player.color})
							end
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
		MoveState[color].mouse_obj.setCustomObject({
			-- mesh='https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/components/arcs/round0.obj',
			mesh='http://cloud-3.steamusercontent.com/ugc/922542758751649800/E140136A8F24712A0CE7E63CF05809EE5140A8B7/',
			collider='https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/utility/null_COL.obj',
			material=3,
			specularIntensity=0,
			cast_shadows=false
		})
	end

	--------------- UTILITY -----------------------------

	function GetPlayerFromColor(color)
		for _, player in pairs(Player.getPlayers()) do
			if player.color == color then
				return player;
			end
		end
	end

	function PrintTable(table, name)
		if name ~= nil then
			print("-------" .. name .. "---------")
		end
		for key,val in pairs(table) do
			print(key .. "-> " .. val)
		end
	end