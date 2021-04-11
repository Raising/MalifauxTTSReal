local MoveState = {};

------------ LIFE CICLE EVENTS --------------------

	function onLoad()
	InitMoveState()
	end

	function onUpdate()
		
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
	}
end

function InitMoveState()
	MoveState.Blue = DefaultPlayer()
	MoveState.Red = DefaultPlayer()
end


------------- ACTIONS ------------------------------

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
	end

	function AbortMove(params)
		local color = params.color;
		clean_move_flow(color)
	end

	function CompleteMove(params)
		local color = params.color;
		local targetObj = params.obj;
		if #(MoveState[color].moveSteps) == 0 then
			AddMoveStep({color = color});
		end
		MoveState[color].object_target.setPosition(MoveState[color].currentMoveCenter)
		
		clean_move_flow(color)
	end
	
	function ModifyMoveRange(params)
		local color = params.color;
		local amount = params.amount;
		MoveState[color].moveRange = math.max(MoveState[color].moveRange + params.amount, 0);
		recalculate_move_center(color);
	end

	function AddMoveStep(params)
		local color = params.color;
		
		if MoveState[color].free_moving then
			MoveState[color].destination = MoveState[color].movingPlayer.getPointerPosition();
			MoveState[color].object_target.setPosition(MoveState[color].destination);
			recalculate_move_center(color);
		else
			if MoveState[color].distanceLeft > 0.01 then
				MoveState[color].destination = MoveState[color].currentMoveCenter:moveTowards(MoveState[color].movingPlayer.getPointerPosition(),MoveState[color].distanceLeft)
				MoveState[color].move_obj.setVar('lock',true)
				MoveState[color].moveSteps[#MoveState[color].moveSteps+1] = {pos = MoveState[color].destination, shadow = MoveState[color].move_obj};
				MoveState[color].move_obj = nil;	
				recalculate_move_center(color);
				if MoveState[color].distanceLeft > 0.01 then
					spawnMoveShadow(color,false)
				end
			end
		end
	end

	function RemoveMoveStep(params)
		local color = params.color;
		
		if MoveState[color].free_moving then
			cancel_free_move()
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

		for key,step in pairs(MoveState[color].moveSteps) do
			if (step.shadow ~= nil) then
				step.shadow.destruct();
			end
		end
		MoveState[color].moveSteps = {};
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
		--getBoundsNormalized
		local objectScale = MoveState[color].object_target.getScale().x;
		--local a=(state.base.size/50) * 2;
		local me = MoveState[color].object_target
		local clr = MoveState[color].object_target.getColorTint()
		
		clr.a = 0.5;

			MoveState[color].move_obj=spawnObject({
			type='custom_model',
			position=MoveState[color].currentMoveCenter,
			rotation=Vector(0,0,0),
			scale={objectScale,1,objectScale},
			mass=0,
			use_gravity=false,
			sound=false,
			snap_to_grid=false,
			callback_function=function(b)
				MoveState[color].object_target.call("AuraFollowObject",{obj = b});
				
				b.setColorTint(clr)
				b.setVar('model',MoveState[color].object_target)
				b.setVar('movingPlayer',MoveState[color].movingPlayer)
				-- b.setVar('center',{x=MoveState[color].currentMoveCenterX,y=MoveState[color].currentMoveCenterY,z=MoveState[color].currentMoveCenterZ})
				b.setVar('centerX',MoveState[color].currentMoveCenterX)
				b.setVar('centerY',MoveState[color].currentMoveCenterY)
				b.setVar('centerZ',MoveState[color].currentMoveCenterZ)
				b.setVar('range',free and 200 or MoveState[color].distanceLeft)
				b.setVar('maxRange',free and 200 or MoveState[color].moveRange)
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
						
						if (model ~= nil and movingPlayer ~= nil) then 
							
							if lock == false and lastPointer ~= movingPlayer.getPointerPosition() and UIinit < 0 then
								lastPointer = movingPlayer.getPointerPosition()
								local center = Vector(centerX,centerY,centerZ);
								local destination = center:copy():moveTowards(lastPointer,range)
								self.setPosition(destination)
							
							
								local angle = math.atan2(destination.z - center.z, center.x-destination.x  ) * 180 / math.pi  + 90;
								
								local zDist = destination.z - center.z;
								local xDist = center.x - destination.x ;
								local distance = math.sqrt(zDist* zDist + xDist * xDist)
								if ]].. (not free and 'true' or 'false') .. [[ then
								self.UI.setAttribute('move_trail','height',distance * 100/ ]]..objectScale..[[ )
								end
								self.UI.setAttribute('current_mov_dist','text',(math.floor((maxRange - range + distance + 0.04)*10)/10) .. '¨' )
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
										width='70', 
										rectAlignment='MiddleCenter',
										text='¨', 
										offsetXY='0 30 -20',
										rotation='0 0 180',
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
		MoveState[color].move_obj.setCustomObject({
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