local WORLD_WG = "Wintergrasp"
local WORLD_TB = "Tol Barad"
local BG_BFG = "The Battle for Gilneas"
local BG_TP = "Twin Peaks"
local BG_AB = "Arathi Basin"
local BG_WG = "Warsong Gulch"
local BG_WGA = "Silverwing Hold"
local BG_WGH = "Warsong Lumber Mill"
local BG_EOTS = "Eye of the Storm"
local BG_AV = "Alterac Valley"
local BG_IOC = "Isle of Conquest"
local BG_SOTA = "Strand of the Ancients"
local BG_SLVSM = "Silvershard Mines"
local BG_TOK = "Temple of Kotmogu"
local BG_DG = "Deepwind Gorge"
local BG_SHORE = "Seething Shore"
local ARENA_LORD = "Ruins of Lordaeron"
local ARENA_NAGRAND = "Nagrand Arena"
local ARENA_BEM = "Blade's Edge Arena"
local ARENA_DAL = "Dalaran Arena"
local ARENA_ROV = "Ring of Valor"
local ARENA_TOL = "Tol'viron Arena"
local ARENA_TP = "The Tiger's Peak"

local BUFF_BERSERKING = GetSpellInfo(23505)
local hasBerserking
local hasPlayedBerserking = false

local BUFF_RESTORATION = GetSpellInfo(23493)
local hasRegeneration
local hasPlayedRegenSound = false

local killResetTime = 5
local killStreak = 0
local multiKill = 0
local killTime = 0
local soundUpdate = 0
local nextSound
local bit_band = bit.band
local bit_bor = bit.bor

local spreeSounds = {
	[1] = "1_kills",
	[2] = "2_kills",
	[3] = "3_kills",
	[4] = "4_kills",
	[5] = "5_kills",
	[6] = "6_kills",
	[7] = "7_kills",
	[8] = "8_kills",
	[9] = "9_kills",
	[10] = "10_kills",
	[11] = "11_kills"
}
local multiSounds = {
	[2] = "double_kill",
	[3] = "triple_kill",
	[4] = "quad_kill",
}

local function hasFlag(flags, flag)
	return bit_band(flags, flag) == flag
end

function hasRegen()
	local result = false
	for i=1,40 do
		local name, _, _, _, _, duration = UnitBuff("player", i)
		if name == BUFF_RESTORATION then
			result = true
			break
		end
	end
	return result 
end

function hasBerserk()
	local result = false
	for i=1,40 do
		local name, _, _, _, _, duration = UnitBuff("player", i)
		if name == BUFF_BERSERKING then
			result = true
			break
		end
	end
	return result 
end

local onEvent = function(self, event, ...)
	self[event](event, CombatLogGetCurrentEventInfo())
	local hasRegen = hasRegen()
	local hasBerserk = hasBerserk()
	if hasRegen and not hasPlayedRegenSound then
		PlaySoundFile("Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\powerup_regeneration.ogg", "Master")
		hasPlayedRegenSound = true
	elseif not hasRegen then
		hasPlayedRegenSound = false
	end
	if hasBerserk and not hasPlayedBerserking then
		PlaySoundFile("Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\powerup_doubledamage.ogg", "Master")
		hasPlayedBerserking = true
	elseif not hasBerserk then
		hasPlayedBerserking = false
	end
end

local onUpdate = function(self, elapsed)
	soundUpdate = soundUpdate + elapsed
	if soundUpdate > 2 then
		soundUpdate = 0
		if nextSound then
			PlaySoundFile(nextSound)
			nextSound = nil
		end
	end
end

HoNAnnouncer = CreateFrame("Frame")
HoNAnnouncer:SetScript("OnEvent", onEvent)
HoNAnnouncer:SetScript("OnUpdate", onUpdate)
HoNAnnouncer:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
HoNAnnouncer:RegisterEvent("ZONE_CHANGED_NEW_AREA")
HoNAnnouncer:RegisterEvent("PLAYER_DEAD")
		
function HoNAnnouncer:PLAYER_DEAD()
	killStreak = 0
	hasBerserking = false
	hasRegeneration = false
	PlaySoundFile("Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\defeat.ogg", "Master")
end

function HoNAnnouncer:ZONE_CHANGED_NEW_AREA()
	local zoneText = GetZoneText();
	if (zoneText == ARENA_TP or zoneText == BG_DG or zoneText == BG_SLVSM or zoneText == BG_TOK or zoneText == ARENA_TOL or zoneText == BG_TP or zoneText == BG_BFG or zoneText == WORLD_TB or zoneText == WORLD_WG or zoneText == BG_AB or zoneText == BG_WG or zoneText == BG_WGA or zoneText == BG_WGH or zoneText == BG_EOTS or zoneText == BG_AV or zoneText == BG_IOC or zoneText == BG_SOTA or zoneText == ARENA_LORD or zoneText == ARENA_NAGRAND or zoneText == ARENA_BEM or zoneText == ARENA_DAL or zoneText == ARENA_ROV or zoneText == BG_SHORE) then
		PlaySoundFile("Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\startgame.ogg", "Master")
	end
	killStreak = 0
end

function HoNAnnouncer:COMBAT_LOG_EVENT_UNFILTERED(event, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, auraType, ...)
	if eventType == "PARTY_KILL" and hasFlag(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) and hasFlag(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) then
		local now = GetTime()
		if killTime + killResetTime > now then
			multiKill = multiKill + 1
		else
			multiKill = 1
		end
		if (UnitHealth("player") / UnitHealthMax("player") * 100 <= 5) and (UnitHealth("player") > 1) then
			PlaySoundFile("Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\smackdown.ogg", "Master")
		end
		killTime = now
		killStreak = killStreak + 1
		
		-- PlaySounds
		local path = "Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\%s.ogg"
		local multiKillLocation = multiSounds[math.min(4, multiKill)]
		local killSpreeLocation = spreeSounds[math.min(11, killStreak)]

		if multiKillLocation then
			local multiKillPath = string.format(path, multiKillLocation)
			PlaySoundFile(multiKillPath, "Master")
		elseif killSpreeLocation then
			local killSpreePath = string.format(path, killSpreeLocation)
			if not multiKillLocation then
				PlaySoundFile(killSpreePath, "Master")
			else
				nextSound = killSpreePath
			end
		end
	
	end
	if eventType == "SPELL_CAST_SUCCESS" and hasFlag(sourceFlags, COMBATLOG_OBJECT_TARGET) and hasFlag(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) and spellName == "Divine Shield" then
		PlaySoundFile("Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\rage_quit.ogg", "Master")
	end
	if eventType == "SPELL_AURA_APPLIED" and hasFlag(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) and (spellName == "Speed" or spellName == "Speed Up") then
		PlaySoundFile("Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\powerup_haste.ogg", "Master")
	end
end