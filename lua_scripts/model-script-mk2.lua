RSS_Class = 'Model';

------ CLASS VARIABLES ----------------------

	local ChildObjs = {
		aura_obj = nil
	};
	local Conditions = {}
	local originalData = nil;
	local state = {
		conditions={Adversary = 0,Fast = 0,Poison = 0,Burning = 0,Focus = 0,Distracted = 0,Injured = 0,Staggered = 0,Stunned = 0,Shielded = 0, Aura=0,Activated =0	},
		tokens={},
		health={current=-1,max= 9},
		base={size=30,color=Color(1,0.5,1)},
		imageScale=1.5,
		
		moveHistory={},
		

		referenceCard = { GUID = '', obj = nil},
		move={
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
		}
	};

	local UIStatus = {
		Blue = {rotation = 0},
		Red = {rotation = 0},
		Grey= {rotation = 0},
	}

------ LIFE CICLE EVENTS --------------------
	function onDestroy()
		if (ChildObjs.aura_obj ~= nil) then ChildObjs.aura_obj.destruct() end
	end

	function onLoad(save)
		save = JSON.decode(save) or {}
		self.setDescription("RSS_Model");
		recoverState(save)

		rebuildAssets()
		self.UI.setXml(ui())
		RefreshModelShape()
		showAura()
	end
	
	function onSave()
		local data={}
		data.state = state;
		data.originalData = originalData ~= nil and originalData or state;
		
		return JSON.encode(data)
	end


	function onUpdate()
		for _, player in ipairs(Player.getPlayers()) do
			if IsPlayerSuscribed(player.color) then
				HUDLookAtPlayer(player);
			end
		end
	end

	function recoverState(save)
		if save.state ~= nil then
			state = save.state;
		else 
			originalData = save.originalData;
			state.health = originalData.health;
			state.base = originalData.base;
			state.imageScale = originalData.imageScale;
			state.base.color = Color(state.base.color); 
		end
		

		-- TODO Modify State With original Data
	end

------ STATE ACTIONS ------------------------

	function SetInitialState(newState) --Tobe called from the reference card
		state.state = newState.state;
		state.health = newState.health;
		state.base = newState.base;
		state.imageScale = newState.imageScale;
		state.referenceCard = newState.referenceCard;
		--state.name = state.name;
	end

	function ModifyHealth(params)
		state.health.current =math.max(0, math.min(state.health.max, state.health.current + params.amount));	
		SyncHealth()
	end

	function ModifyAura(params)
		state.conditions.Aura = math.max(0,state.conditions.Aura + params.amount);
		local newScale = 0;
		if state.conditions.Aura > 0 then
			newScale = state.conditions.Aura+(state.base.size/50);
		end

		ChildObjs.aura_obj.setScale(Vector(newScale,1,newScale));
		SyncCondition("Aura")
	end

	function ModifyCondition(params)
		local previousValue = state.conditions[params.name];
		if  params.amount == 0 then -- toggle
			state.conditions[params.name] = math.max(0,1 - state.conditions[params.name]);	
		else
			if Conditions[params.name].loop ~= nil  then
				state.conditions[params.name] = math.max(0,(state.conditions[params.name] + params.amount + Conditions[params.name].loop)% Conditions[params.name].loop) ;	
			else
				state.conditions[params.name] = math.max(0,state.conditions[params.name] + params.amount);	
			end
		end
		local states  = self.getData();
	
		print (self.getData().Nickname .. [[: ']] .. params.name .. [[' ]] .. previousValue .. [[->]] .. state.conditions[params.name])
		
		--Sync()
		SyncCondition(params.name)
	end

	function ModifyMoveRange(params)
		state.move.moveRange = math.max(0, state.move.moveRange + params.amount);
	end

------ MODEL MANIPULATION -------------------
	
	function AuraFollowObject(params)
		if ChildObjs.aura_obj ~= nil then
			ChildObjs.aura_obj.setVar('parent',params.obj);
		end
	end

	function AuraResetFollow()
		if ChildObjs.aura_obj ~= nil then
			ChildObjs.aura_obj.setVar('parent',self);
		end
	end

	function RefreshModelShape()
		local attachments = self.getAttachments()
		for key,value in pairs(attachments) do
			modelElement = self.removeAttachment(0)
			modelElement.setCustomObject({
				image_scalar = tonumber(state.imageScale * 1.2)
			});
			-- modelElement.getComponent('MeshCollider').set('enabled',false)
			self.addAttachment(modelElement)
		end 
		local baseScale = state.base.size / 25;
		self.setScale(Vector(baseScale,1,baseScale))
		RefreshBaseColor()
	end
	
	function RefreshBaseColor()
		
		if state.conditions.Activated == 0 then
			self.setColorTint(state.base.color)
		else
			self.setColorTint( Color(state.base.color):lerp(Color.Orange, 0.85) )
		end
	end
------ UI GENERATION ------------------------
	function calculatePlayerRotation()
		for _, player in ipairs(Player.getPlayers()) do
			UIStatus[player.color].rotation = player.getPointerRotation() - self.getRotation().y + 180;
		end
	end
	function Sync()
		self.UI.setXml(ui())
		--propagateToReferenceCard()
	end
	
	function SyncCondition(name)
		local secondary = Conditions[name].secondary;
		local imageName = (secondary == nil and name or (state.conditions[name] > 1 and name or secondary));
	
		for k,color in pairs({'Red', 'Blue','Grey|Black'}) do
			self.UI.setAttributes(color.."_ConditionImage_".. name, {
				color= Conditions[imageName].color .. (state.conditions[name] > 0  and 'ff' or '22'),
				image= imageName,
			});
			self.UI.setAttributes(color.."_ConditionText_".. name, {
				active= (Conditions[name].stacks and state.conditions[name] > 0 and 'true' or 'false'),
				text= state.conditions[name] 
			});
		end

		if name == "Activated" then
			RefreshBaseColor()
		end
	end	
	
	function SyncHealth()
		for k,color in pairs({'Red', 'Blue','Grey|Black'}) do
			self.UI.setAttributes( color .. "_HealthBar_Text", {
				text = state.health.current.. [[/]] .. state.health.max
			});
			self.UI.setAttributes(color .. "_HealthBar", {
				percentage= (state.health.current / state.health.max * 100)
			});
		end
	end	

	function IsPlayerSuscribed(color)
		-- print(color .. " -> " ..  ((UIStatus[color] ~= nil) and 'true' or 'false') )
		return UIStatus[color] ~= nil;
	end

	function HUDLookAtPlayer(player)
		local playerRotation  = player.getPointerRotation();
		if playerRotation == nil then playerRotation = 0 end;
		local pointerRotation =playerRotation - self.getRotation().y +180;
		if pointerRotation ~= UIStatus[player.color].rotation then
			self.UI.setAttribute(player.color .. '_PlayerHUDPivot','rotation','0 0 '.. -pointerRotation  )
			UIStatus[player.color].rotation = pointerRotation;
		end
	end

	function ui() 
		return [[
			<Panel color="#FFFFFFff" height="0" width="0" rectAlignment="MiddleCenter" childForceExpandWidth="true" >]]..
			PlayerHUDPivot('Blue')..
			PlayerHUDPivot('Red')..
			PlayerHUDPivot('Grey')..
			[[</Panel>
		]];
	end

	function rebuildAssets()
		local assets = {};
		for conditionName, value in pairs(Conditions) do
			assets[#assets+1]={name=conditionName , url = value.url};
		end

		self.UI.setCustomAssets(assets)
	end

	function PlayerHUDPivot(color)
		return [[
			<Panel id=']]..color..[[_PlayerHUDPivot' visibility=']]..color..[[' height="160" width="128" position='0 0 -280' rotation='0 0 ]] .. - UIStatus[color].rotation .. [[' rectAlignment="MiddleCenter"  childForceExpandWidth="false">
		
			]]..PlayerHUDContainer(color)..[[
		</Panel>
		]]
	end

	function PlayerHUDContainer(color)
		return [[
			<Panel id='PlayerHUD_Container' active='true' height="80" width="100%" rectAlignment="MiddleCenter"  rotation='-35 0 0' position='0 50 0' childForceExpandWidth="false">]]..
				HUDConditions(color) ..
				[[<ProgressBar width="100%" height="30" id="]] .. color .. [[_HealthBar" color='#00000080' fillImageColor="#44AA22FF" percentage="]] ..(state.health.current / state.health.max * 100) .. [[" textColor="#00000000"/>  ]] ..
				[[<Text id=']] .. color .. [[_HealthBar_Text' fontSize='25' height="30" onClick='UI_ModifyHealth' text=']] .. state.health.current.. [[/]] .. state.health.max.. [[' color='#ffffff' fontStyle='Bold' outline='#000000' outlineSize='1 1' />]] ..
			[[</Panel>
		]]
	end

	function HUDConditions(color)
		
		return [[<Panel width="100%" rectAlignment="MiddleLeft" position='0 0 0' > ]]..
		HUDSingleCondition(color,"Burning", 0 , 1) ..
		HUDSingleCondition(color,"Poison", 1 , 1) ..
		HUDSingleCondition(color,"Injured", 2 , 1) ..
		HUDSingleCondition(color,"Distracted", 3 , 1) ..

		--HUDSingleCondition(color,"Slow", 0 , -1) ..
		HUDSingleCondition(color,"Fast", 0 , -1) ..
		HUDSingleCondition(color,"Stunned", 1 , -1) ..
		HUDSingleCondition(color,"Staggered", 2 , -1) ..
		HUDSingleCondition(color,"Adversary", 3 , -1) ..
		
		HUDSingleCondition(color,"Focus", -1 ,0.5) ..
		HUDSingleCondition(color,"Shielded", -1 ,-0.5) ..

		HUDSingleCondition(color,"Aura", 4 ,-0.5) ..
		HUDSingleCondition(color,"Activated", 4 ,0.5) ..
		
		[[</Panel>]]
	end


	function UI_ModifyCondition(alt,name) if alt ~= '-3' then ModifyCondition({name=name,amount= (alt == '-1' and 1 or (alt == '-2' and -1) or 0 ) }) end end
	function UI_ModifyAura(p,alt) if alt ~= '-3' then ModifyAura({amount= (alt == '-1' and 1 or (alt == '-2' and -1) or 0 ) }) end end
	function UI_ModifyHealth(p,alt) if alt ~= '-3' then ModifyHealth({amount= (alt == '-1' and 1 or (alt == '-2' and -1) or 0 ) }) end end

	function UI_ModifyBurning(p,alt) UI_ModifyCondition(alt,"Burning") end
	function UI_ModifyPoison(p,alt) UI_ModifyCondition(alt,"Poison") end
	function UI_ModifyInjured(p,alt) UI_ModifyCondition(alt,"Injured") end
	function UI_ModifyDistracted(p,alt) UI_ModifyCondition(alt,"Distracted") end

	
	function UI_ModifyFast(p,alt) UI_ModifyCondition(alt,"Fast") end
	function UI_ModifyStunned(p,alt) UI_ModifyCondition("0","Stunned") end
	function UI_ModifyStaggered(p,alt) UI_ModifyCondition("0","Staggered") end
	function UI_ModifyAdversary(p,alt) UI_ModifyCondition("0","Adversary") end
	function UI_ModifyActivated(p,alt) UI_ModifyCondition("0","Activated") end

	function UI_ModifyFocus(p,alt) UI_ModifyCondition(alt,"Focus") end
	function UI_ModifyShielded(p,alt) UI_ModifyCondition(alt,"Shielded") end


	function HUDSingleCondition(color,name,x,y)
		local id = "ConditionFrame_" .. name ;
		return [[<Panel id="]] .. id ..[[" width="30" height="30" alignment='LowerLeft' position=']] ..(x* 32 - 49).. [[ ]] .. y*(32) .. [[ 0' ]] .. 
		[[onClick='UI_Modify]] .. name ..[[()'>]] ..
			HUDSingleConditionBody(color,name)..
		[[</Panel>]];
	end

	function HUDSingleConditionBody(color,name)
		local secondary = Conditions[name].secondary;
		local imageName = (secondary == nil and name or (state.conditions[name] > 1 and name or secondary));
		return [[
			<Image id="]]..color ..[[_ConditionImage_]]..name ..[[" image="]] .. imageName .. [[" color="]] .. Conditions[imageName].color .. (state.conditions[name] > 0  and 'ff' or '22') .. [[" rectAlignment='LowerLeft' width='30' height='30'/>
			<Text  id="]]..color ..[[_ConditionText_]]..name ..[[" active=']] .. (Conditions[name].stacks and state.conditions[name] > 0 and 'true' or 'false')  ..[['  fontSize='22' text=']] .. state.conditions[name] .. [[' color='#ffffff' fontStyle='Bold'  rectAlignment='LowerLeft' outline='#000000' outlineSize='1 1' />
		]]
	end


	Conditions = {
		Fast = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554385209/698B13597E185E6ACA0AB19C13A118A3C1BEEB4D/", color="#E2D064", stacks=false, loop = 3 , secondary = "Slow"},
		Slow = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554366701/F479B20690BB037348F53B802F99B9B68ACFCCEA/", color="#B8B8B8", stacks=false, loop = 3 },
		Adversary = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554346517/81BCB3804E00F22B1E40D6A84C85C26F04F3C5CC/", color="#DF2020", stacks=false },
		Poison = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554095214/37B3943D3C71EE6BFD13027145BDE00D0D56ED3B/", color="#83CD4D", stacks=true },
		Burning = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554318009/A00031DC30FDC7D6EB7AEA3DFCF8AAD0754CD4CB/", color="#DB8E47", stacks=true },
		Focus = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554725833/7B52C3AD5915BFC06B7E68025F5448C2862E0789/", color="#9A37D3", stacks=true },
		Distracted = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554407310/DA85F94D429B073CEB18B2AB4F24FC0041F1CF30/", color="#FF42CF", stacks=true },
		Injured = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554292969/5474B842DEC8F08CB249F3B24683FE95D58332FC/", color="#920606", stacks=true },
		Staggered = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554150868/60F4FB8B23A6586775CB50311E1F7DD6BC0C1620/", color="#138C01", stacks=false },
		Stunned = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554191671/98EB8191C3884783E74F6FF8066097D2D7296CBF/", color="#FFFFFF", stacks=false },
		Shielded = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554495459/45E41E4CF603049EEF4B3EAB39DC0B3DC93DFE78/", color="#6AC3FF", stacks=true },
		Aura = { url="https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/ui/movenode.png", color="#99aa22", stacks=true },
		Activated  = { url="https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/ui/flag.png", color="#bbbb22", stacks=false },
	}

------ Object SPAWMERS ----------------------

	function showAura()

		local a=(state.conditions.Aura > 0) and (state.conditions.Aura+(state.base.size/50)) or 0; --based on model base size
	
		local me = self
		local clr = self.getColorTint()
			ChildObjs.aura_obj=spawnObject({
			type='custom_model',
			position=self.getPosition(),
			rotation=self.getRotation(),
			scale={a,1,a},
			mass=0,
			use_gravity=false,
			sound=false,
			snap_to_grid=false,
			callback_function=function(b)
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
		ChildObjs.aura_obj.setCustomObject({
			mesh='https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/components/arcs/round0.obj',
			collider='https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/utility/null_COL.obj',
			material=3,
			specularIntensity=0,
			cast_shadows=false
		})
	end

------ END ----------------------------------
