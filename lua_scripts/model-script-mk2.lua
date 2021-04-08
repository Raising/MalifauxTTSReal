local RSS_Class = 'Model';

local radToDeg = 180 / math.pi
local degToRad = math.pi / 180
local Conditions = {}
local state = {
	conditions={Slow = 1,Adversary = 0,Fast = 0,Poison = 0,Burning = 15,Focus = 1,Distracted = 0,Injured = 0,Staggered = 0,Stunned = 0,Shielded = 0	},
	toekns={},
	health={current=9,max= 9},
	aura= 0,
	activated = true,
	moveHistory={},
};

local UIStatus = {
	Blue = {rotation = 0},
	Red = {rotation = 0},
}


local init = false;

function onDestroy()
	if (arc_obj ~= nil) then arc_obj.destruct() end
end


function onLoad()
  InitState();
  rebuildAssets()
  self.UI.setXml(ui())
end

function onUpdate()
    for _, player in ipairs(Player.getPlayers()) do
		if IsPlayerSuscribed(player.color) then
			HUDLookAtPlayer(player);
        end
    end
end

function calculatePlayerRotation()
	for _, player in ipairs(Player.getPlayers()) do
		UIStatus[player.color].rotation = player.getPointerRotation();
    end
end

function InitState()
	-- state = {
	-- 	conditions={Slow = 1,Adversary = 0,Fast = 0,Poison = 0,Burning = 5,Focus = 1,Distracted = 0,Injured = 0,Staggered = 0,Stunned = 0,Shielded = 0	},
		
	-- };
end

function ModifyHealth(params)
	state.health.current =math.max(0, math.min(state.health.max, state.health.current + params.amount));	
	self.UI.setXml(ui())
end

function ModifyCondition(params)
	print(params.name)
	if  params.amount == 0 then -- toggle
		state.conditions[params.name] = math.max(0,1 - state.conditions[params.name]);	
	else
		state.conditions[params.name] = math.max(0,state.conditions[params.name] + params.amount);	
	end
	self.UI.setXml(ui())
end

function activateScriptingButton(player, index)
	local peekerColor = player.color
	local selected = player.getSelectedObjects()
	if #selected > 0 then
	  for k, obj in pairs(getAllObjects()) do
		if obj.getVar("isMaster") then
		  obj.call("onScriptingButtonDownTable", {index = index, peekerColor = peekerColor})
		end
	  end
	end
  end
  

-- UI ------------------------

function IsPlayerSuscribed(color)
    return UIStatus[color] ~= nil;
end

function HUDLookAtPlayer(player)
	local pointerRotation = player.getPointerRotation();
	if pointerRotation ~= UIStatus[player.color].rotation then
		self.UI.setAttribute(player.color .. '_PlayerHUDPivot','rotation','0 0 '.. -pointerRotation  )
		UIStatus[player.color].rotation = pointerRotation;
	end
end


function ui() 
    return [[
        <Panel color="#FFFFFFff" height="100" width="110" rectAlignment="LowerCenter" childForceExpandWidth="true" >]]..
        PlayerHUDPivot('Blue')..
        PlayerHUDPivot('Red')..
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
        <Panel id=']]..color..[[_PlayerHUDPivot' visibility=']]..color..[[' height="160" width="100%" position='0 0 -220' rotation='0 0 ]] .. - UIStatus[color].rotation .. [[' rectAlignment="LowerCenter"  childForceExpandWidth="false">
       
        ]]..PlayerHUDContainer()..[[
      </Panel>
    ]]
end

function BaseButton(color,number)
    return  [[<Button id=']] .. color .. [[_Option_]]..number..[[' height="60" color="#373737" padding='4 4 4 4' >
                <Text id=']] .. color .. [[_Option_]]..number..[[_Desc' alignment='UpperLeft' fontSize="11" color="#d9ddde"   >   Description</Text>
                <Text alignment='UpperRight' fontSize="14" color="#d9ddde" >]]..number..[[</Text>
            </Button>]];
end


function PlayerHUDContainer()
    return [[
		<Panel id='PlayerHUD_Container' active='true' height="80" width="100%" rectAlignment="MiddleCenter"  rotation='-35 0 0' childForceExpandWidth="false">]]..
			HUDConditions() ..
			[[<ProgressBar width="100%" height="30" id="HealthBar" color='#00000080' fillImageColor="#44AA22FF" percentage="]] ..(state.health.current / state.health.max * 100) .. [[" textColor="#00000000"/>  ]] ..
			[[<Text id='HealthBar_Text' fontSize='25' text=']] .. state.health.current.. [[/]] .. state.health.max.. [[' color='#ffffff' fontStyle='Bold' outline='#000000' outlineSize='1 1' />]] ..
        [[</Panel>
    ]]
end


function HUDConditions()
	
	return [[<Panel width="100%" rectAlignment="MiddleLeft" position='0 0 0' > ]]..
	HUDSingleCondition("Burning", 0 , 1) ..
	HUDSingleCondition("Poison", 1 , 1) ..
	HUDSingleCondition("Injured", 2 , 1) ..
	HUDSingleCondition("Distracted", 3 , 1) ..

	HUDSingleCondition("Slow", 0 , -1) ..
	HUDSingleCondition("Fast", 0 , -1) ..
	HUDSingleCondition("Stunned", 1 , -1) ..
	HUDSingleCondition("Staggered", 2 , -1) ..
	HUDSingleCondition("Adversary", 3 , -1) ..
	
	HUDSingleCondition("Focus", -0.7 ,0) ..
	HUDSingleCondition("Shielded", 3.7 ,0) ..
	[[</Panel>]]
end

function HUDSingleCondition(name,x,y)

	return [[<Panel active=']] .. (state.conditions[name] > 0  and 'true' or 'false')  ..[['  width="30" height="30" alignment='LowerLeft' position=']] ..(x* 32 - 48).. [[ ]] .. y*(32) .. [[ 0'>
	<Image  image="]] .. name .. [[" color="]] .. Conditions[name].color .. [[" rectAlignment='LowerLeft' width='30' height='30'/>
	<Text  active=']] ..  (Conditions[name].stacks and 'true' or 'false')  ..[['  fontSize='22' text=']] .. state.conditions[name] .. [[' color='#ffffff' fontStyle='Bold'  rectAlignment='LowerLeft' outline='#000000' outlineSize='1 1' />
	[[</Panel>]]
end




Conditions = {
	Slow = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554366701/F479B20690BB037348F53B802F99B9B68ACFCCEA/", color="#B8B8B8", stacks=false },
	Adversary = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554346517/81BCB3804E00F22B1E40D6A84C85C26F04F3C5CC/", color="#DF2020", stacks=false },
	Fast = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554385209/698B13597E185E6ACA0AB19C13A118A3C1BEEB4D/", color="#E2D064", stacks=false },
	Poison = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554095214/37B3943D3C71EE6BFD13027145BDE00D0D56ED3B/", color="#83CD4D", stacks=true },
	Burning = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554318009/A00031DC30FDC7D6EB7AEA3DFCF8AAD0754CD4CB/", color="#DB8E47", stacks=true },
	Focus = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554725833/7B52C3AD5915BFC06B7E68025F5448C2862E0789/", color="#9A37D3", stacks=true },
	Distracted = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554407310/DA85F94D429B073CEB18B2AB4F24FC0041F1CF30/", color="#FF42CF", stacks=true },
	Injured = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554292969/5474B842DEC8F08CB249F3B24683FE95D58332FC/", color="#920606", stacks=true },
	Staggered = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554150868/60F4FB8B23A6586775CB50311E1F7DD6BC0C1620/", color="#138C01", stacks=false },
	Stunned = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554191671/98EB8191C3884783E74F6FF8066097D2D7296CBF/", color="#FFFFFF", stacks=false },
	Shielded = { url="http://cloud-3.steamusercontent.com/ugc/1019447087554495459/45E41E4CF603049EEF4B3EAB39DC0B3DC93DFE78/", color="#6AC3FF", stacks=true },
}