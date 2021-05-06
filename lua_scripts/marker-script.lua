RSS_Class = 'Marker';

------ CLASS VARIABLES ----------------------

	local ChildObjs = {
		aura_obj = nil
	};
	local Conditions = {}

	local state = {conditions={ Aura=0,Activated =0	}};

------ LIFE CICLE EVENTS --------------------

	function onDestroy()
		if (ChildObjs.aura_obj ~= nil) then ChildObjs.aura_obj.destruct() end
	end

	function onLoad(save)
		rebuildAssets()
		self.UI.setXml(ui())
		showAura()
	end
	
	function onSave()
	
	end


	function onUpdate()
	
	end


------ STATE ACTIONS ------------------------

	function SetInitialState(newState) --Tobe called from the reference card
	

	end

	function ModifyAura(params)
		local bound = self.getBoundsNormalized();
		state.conditions.Aura = math.max(0,state.conditions.Aura + params.amount);
		local newScale = 0;
		if state.conditions.Aura > 0 then
			newScale = state.conditions.Aura+(bound.size.x/2+0.02);
		end

		ChildObjs.aura_obj.setScale(Vector(newScale,1,newScale));
		SyncCondition("Aura")
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


------ UI GENERATION ------------------------
	
	function Sync()
		self.UI.setXml(ui())
		--propagateToReferenceCard()
	end
	
	function SyncCondition(name)
		local secondary = Conditions[name].secondary;
		local imageName = (secondary == nil and name or (state.conditions[name] > 1 and name or secondary));
		local color = 'All';
		
		self.UI.setAttributes(color.."_ConditionImage_".. name, {
			color= Conditions[imageName].color .. (state.conditions[name] > 0  and 'ff' or 'ff'),
			image= imageName,
		});
		self.UI.setAttributes(color.."_ConditionText_".. name, {
			active= (Conditions[name].stacks and state.conditions[name] > 0 and 'true' or 'false'),
			text= state.conditions[name] 
		});
	

		if name == "Activated" then
			RefreshBaseColor()
		end
	end	
	



	function ui() 
		return [[
			<Panel color="#FFFFFFff" height="0" width="0" rectAlignment="MiddleCenter" childForceExpandWidth="true" >]]..
			PlayerHUDPivot('All')..
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
			<Panel id=']]..color..[[_PlayerHUDPivot'  height="160" width="128" position='0 0 -10' rotation='0 0 0' rectAlignment="MiddleCenter"  childForceExpandWidth="false">
		
			]]..HUDConditions(color) ..[[
		</Panel>
		]]
	end

	-- function PlayerHUDContainer(color)
	-- 	return [[
	-- 		<Panel id='PlayerHUD_Container' active='true' height="80" width="100%" rectAlignment="MiddleCenter"  rotation='0 0 0' position='0 50 0' childForceExpandWidth="false">]]..
	-- 			HUDConditions(color) ..
	-- 		[[</Panel>
	-- 	]]
	-- end

	function HUDConditions(color)
		
		return [[<Panel width="100%" rectAlignment="MiddleLeft" position='0 0 0' rotation='0 0 180' scale='4 4 4' > ]]..
			HUDSingleCondition(color,"Aura", 0 ,0) ..
		[[</Panel>]]
	end

	function UI_ModifyAura(p,alt) if alt ~= '-3' then ModifyAura({amount= (alt == '-1' and 1 or (alt == '-2' and -1) or 0 ) }) end end
	

	function HUDSingleCondition(color,name,x,y)
		local id = "ConditionFrame_" .. name ;
		return [[<Panel id="]] .. id ..[[" width="30" height="30" alignment='LowerLeft' position=']] ..(x* 32 ).. [[ ]] .. y*(32) .. [[ 0' ]] .. 
		[[onClick='UI_Modify]] .. name ..[[()'>]] ..
			HUDSingleConditionBody(color,name)..
		[[</Panel>]];
	end

	function HUDSingleConditionBody(color,name)
		local secondary = Conditions[name].secondary;
		local imageName = (secondary == nil and name or (state.conditions[name] > 1 and name or secondary));
		return [[
			<Image id="]]..color ..[[_ConditionImage_]]..name ..[[" image="]] .. imageName .. [[" color="]] .. Conditions[imageName].color .. (state.conditions[name] > 0  and 'ff' or 'ff') .. [[" rectAlignment='LowerLeft' width='30' height='30'/>
			<Text  id="]]..color ..[[_ConditionText_]]..name ..[[" active=']] .. (Conditions[name].stacks and state.conditions[name] > 0 and 'true' or 'false')  ..[['  fontSize='22' text=']] .. state.conditions[name] .. [[' color='#ffffff' fontStyle='Bold'  rectAlignment='LowerLeft' outline='#000000' outlineSize='1 1' />
		]]
	end


	Conditions = {
		Aura = { url="https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/ui/movenode.png", color="#99aa22", stacks=true }
	}

------ Object SPAWMERS ----------------------

	function showAura()
		local bound = self.getBoundsNormalized();
		local a=(state.conditions.Aura > 0) and (state.conditions.Aura+(bound.size.x/2)+0.02) or 0; --based on model base size
	
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
					local clock = 2;
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
							if clock < 0 then
								clock = 2;
								if (not parent.resting or lastParent ~= parent) then 
									lastParent = parent
									self.setPosition(parent.getPosition())
									self.setRotation(parent.getRotation()) 
								end 
							else
								clock = clock - 1
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
