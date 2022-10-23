local PVPZONES = {
	[1] = "Wintergrasp",
	[2] = "Tol Barad",
	[3] = "The Battle for Gilneas",
	[4] = "Twin Peaks",
	[5] = "Arathi Basin",
	[6] = "Warsong Gulch",
	[7] = "Silverwing Hold",
	[8] = "Warsong Lumber Mill",
	[9] = "Eye of the Storm",
	[10] = "Alterac Valley",
	[11] = "Isle of Conquest",
	[12] = "Strand of the Ancients",
	[13] = "Silvershard Mines",
	[14] = "Temple of Kotmogu",
	[15] = "Deepwind Gorge",
	[16] = "Seething Shore",
	[17] = "Ruins of Lordaeron",
	[18] = "Nagrand Arena",
	[19] = "Blade's Edge Arena",
	[20] = "Dalaran Arena",
	[21] = "Ring of Valor",
	[22] = "Tol'viron Arena",
	[23] = "The Tiger's Peak",
	[24] = "Ashamane's Fall",
	[25] = "Black Rook Hold Arena",
	[26] = "Hook Point",
	[27] = "The Mugambala",
	[28] = "The Robodrome",
	[29] = "Empyrean Domain",
	[30] = "Maldraxxus Coliseum",
	[31] = "Enigma Crucible",
	[32] = "Nokhudon Proving Grounds",
	[33] = "Circle of Blood Arena"
}

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
	for i,pvpZone in ipairs(PVPZONES) do 
		if zoneText == pvpZone then
			PlaySoundFile("Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\startgame.ogg", "Master")
		end
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