-- KRATOS UPDATE30 V3: farm controller + remote-only random fruit
--!nocheck
--[[
    V34 WRD SAFE + AUTO RANDOM + SABER FIX
    Loader simplificado: opções estáveis/técnicas ficam internas no Kaitun.

==========================================================================================
    KRATOS ULTIMATE HUB v2.0 | V34 WRD SAFE
    Arquivo: .lua
    Ambiente: Roblox
    FarmSpeed: 190
    TweenSpeed: 190
==========================================================================================
--]]

--[[
==========================================================================================
                         KRATOS ULTIMATE HUB v2.0
                         PREMIUM RED THEME - COMBINED SYSTEM
==========================================================================================

This is the ultimate Kaitun combining:
- KRATOS KAITUN HUB: Advanced quest system, combat hover, safety systems
- Speed Hub X: Advanced auto farm, bring mobs, skill monitoring, server hopping

Main features:
- Complete quest system with dynamic workspace searching
- Advanced auto farm with priority-based feature stacking
- Bring mobs system with intelligent grouping
- Combat hover system for boss safety
- Auto stats, auto skills, auto fruit collection
- Material farming and boss hunting
- Saber and Pole V1 automation
- Multi-sea support (Sea 1, 2, 3)
- Advanced watchdog and error recovery
- Dynamic mapper system
- Server hopping capabilities
- Premium red theme UI
- 20+ modular systems

==========================================================================================
]]

-- Global environment references for Roblox/exploit environments.
-- IMPORTANT: Roblox native classes/functions must NOT be created in _G as `{}`,
-- because doing so replaces the real APIs (for example CFrame.new / Color3.fromRGB).
local getgenv = getgenv or function()
    return _G
end

local UDim2 = UDim2
local Color3 = Color3
local Vector3 = Vector3
local CFrame = CFrame
local Vector2 = Vector2
local Enum = Enum
local Instance = Instance
local UDim = UDim
local ColorSequence = ColorSequence
local ColorSequenceKeypoint = ColorSequenceKeypoint
local TweenInfo = TweenInfo

local tick = tick
local task = task
local typeof = typeof
local pcall = pcall
local math = math
local table = table
local string = string
local pairs = pairs
local ipairs = ipairs
local next = next
local select = select
local unpack = unpack
local error = error
local warn = warn
local print = print
local gethui = gethui
local RaycastParams = RaycastParams
local workspace = workspace
local game = game
local sethiddenproperty = sethiddenproperty or function() end
local firetouchinterest = firetouchinterest
local fireclickdetector = fireclickdetector
local fireproximityprompt = fireproximityprompt

--=====================================================================================
-- [0.5] PERFORMANCE PROFILE
-- The farm scheduler, combat scanning, movement, Haki, safety, UI and spawn lookups
-- all run on independent throttles to prevent 100Hz hot loops and repeated full-tree scans.
--=====================================================================================
-- [1] CONFIG
--=====================================================================================

getgenv().Config = {
    -- Team selection
    Team = "Pirates",
    AutoTeam = true,
    ForceTeamSet = true,

    -- Auto farm settings
    AutoFarm = true,
    AutoQuest = true,
    -- Keep the real quest tracker synchronized with QuestSystem.Current.
    -- If an old/wrong mission is still active after a boss dies or the level changes,
    -- abandon it before attacking the next mob.
    StrictQuestSync = true,
    QuestMismatchAbandonInterval = 0.35,
    FastAttack = true,
    UseSkills = false,
    SkillsEnabled = false,
    NoClip = true,
    BringMobs = false,
    BringMobCount = 2,
    BringMobRadius = 500,

    -- Nearby chest collection:
    -- briefly pauses level farming, collects every chest inside this radius,
    -- returns to the previous farm position, then resumes normally.
    AutoCollectNearbyChests = true,
    ChestCollectRadius = 350,
    ChestScanInterval = 0.75,
    ChestPickupDistance = 5.5,
    ChestPickupTimeout = 2.0,
    ChestRetryCooldown = 6.0,
    ChestReturnToFarm = true,

    -- Combat / ability settings
    AutoHaki = true,
    AutoActiveKen = true, -- auto-activate Instinct/Observation once owned

    -- Ability Teacher / Instinct Teacher auto-buy.
    -- Remote names follow the current game calls used by Redz / Speed Hub X.
    AutoBuyAirJump = true,      -- Geppo / Air Jump: 10,000 Beli
    AutoBuyAura = true,         -- Buso / Aura: 25,000 Beli
    AutoBuyFlashStep = true,    -- Soru / Flash Step: 100,000 Beli
    AutoBuyInstinctV1 = true,   -- Ken / Instinct V1: 750,000 Beli + Lv300 + Saber
    AbilityBuyInterval = 2.0,
    KenActivateInterval = 1.0,

    -- Normal shop purchases are part of the Kaitun's internal default progression.
    -- Kept out of the Settings Loader to avoid unnecessary configuration clutter.
    AutoBuyShopItems = {
        ["Katana"] = true,
        ["Cutlass"] = true,
        ["Dual Katana"] = true,
        ["Iron Mace"] = true,
        ["Triple Katana"] = true,
        ["Pipe"] = true,
        ["Dual-Headed Blade"] = true,
        ["Soul Cane"] = true,
        ["Bisento"] = true,
        ["Musket"] = true,
        ["Slingshot"] = true,
        ["Flintlock"] = true,
        ["Refined Slingshot"] = true,
        ["Refined Flintlock"] = true,
        ["Cannon"] = true,
        ["Black Cape"] = true,
        ["Swordsman Hat"] = true,
        ["Tomoe Ring"] = true,
    },
    ShopItemRetryInterval = 15.0,
    ShopInventoryRefreshInterval = 5.0,

    AutoStats = true,

    -- Fruit collection: only fruits in FruitFilter are collected.
    AutoFruit = true,
    FruitAutoStore = true,
    FruitAutoRandom = true,
    FruitAutoRandomInterval = 15.0,
    -- Collection whitelist only controls which world fruits are chased.
    -- AutoStore stores any real fruit already owned, even if it is not whitelisted.
    FruitStoreAnyOwned = true,
    FruitStoreScanInterval = 0.25,
    FruitStoreRetryInterval = 1.25,
    FruitStoreMaxAttempts = 4,
    FruitScanInterval = 0.75,
    FruitPickupDistance = 5.5,
    FruitPickupTimeout = 5.0, -- close-range pickup/contact timeout
    FruitTravelGrace = 10.0, -- extra time added to calculated flight ETA
    FruitTravelMaxTime = 90.0,
    FruitNoProgressTimeout = 7.0,
    FruitRetryCooldown = 6.0,

    -- Fruit ESP: independent from AutoCollect/filter.
    FruitESP = true,
    FruitESPShowDistance = true,
    FruitESPShowRarity = true,
    FruitESPMaxDistance = 10000,
    FruitESPRefreshInterval = 0.30,
    FruitESPMetadataRefresh = 60,
    FruitESPResolveGrace = 6.0, -- newly spawned fruits can replicate name/attributes a moment later
    FruitESPDeepIndexCooldown = 12.0,

    -- If a physical fruit still cannot be identified after the grace window,
    -- collect it anyway instead of leaving a potentially valuable fruit behind.
    FruitCollectUnknown = true,
    FruitUnknownCollectDelay = 6.0,
    -- Unknown fruits are only a fallback. Do not let a distant/unresolved object
    -- pause the entire level farm from another part of the island.
    FruitUnknownMaxDistance = 350,
    FruitUnknownFailureCooldown = 45.0,

    -- Update 30 Colosseum secret added large Champion statues, including a
    -- Fruit-themed statue. These are scenery/puzzle objects, never pickups.
    FruitIgnorePuzzleObjects = true,
    FruitUnknownModelMaxSize = 5.25,

    FruitFilter = {
        "Kitsune",
        "Yeti",
        "Tiger",
    },

    AutoMelee = true,
    PrioritizeBlackLeg = true,
    BlackLegPrice = 150000,

    -- REDZ-style automatic fighting-style progression
    AutoFightingStyles = true,
    FightingStyleMasteryTarget = 400,
    FightingStyleBuyInterval = 2.0,
    FightingStyleMasteryCheckInterval = 0.35,
    FightingStylePreferCurrentSea = true,
    PostCombatMastery = 400,
    AutoRedeemCodes = true,
    CodeRedeemDelay = 0.28,
    CodeStartDelay = 2.0,
    BlackLegVillageCFrame = CFrame.new(-1122.34998, 14.78709, 3855.91992),
    BlackLegTeacherYOffset = 3,
    BlackLegPurchaseDistance = 8,
    BlackLegRetryInterval = 1.25,
    BlackLegReturnDistance = 12,

    -- Attack settings
    -- AttackSpeed remains the combat cooldown, while the farm scheduler runs separately.
    AttackSpeed = 0.07,
    -- Main farm logic no longer needs to run every rendered frame. FastAttack has
    -- its own lightweight worker below, so a 0.10s scheduler reduces client hitching
    -- without slowing attacks.
    FarmTickInterval = 0.10,
    CombatScanInterval = 0.20,
    CombatMoveInterval = 0.10,
    BringUpdateInterval = 0.12,

    -- Internal combat/performance throttles (kept out of Settings Loader on purpose).
    QuestGuiCheckInterval = 0.24,
    TargetLockInterval = 0.12,
    AttackWorkerInterval = 0.03,
    AttackNoDamageFallback = 0.70,
    AttackFallbackClickInterval = 0.22,
    FarmLevelBaseMode = true,
    FarmOrbitRadius = 24, -- closer horizontal orbit to keep server combat engaged
    FarmOrbitSpeed = 380, -- faster orbit for quicker NPC/boss farming
    FarmQuestDistance = 5,

    -- Speed Hub X style level farm:
    -- try StartQuest remotely first, immediately leave for the mob spawn,
    -- and only fall back to physically visiting the quest NPC if needed.
    FastQuestMode = true,
    FastQuestRetryInterval = 0.22,
    FastQuestMaxRemoteAttempts = 4,
    FastQuestFallbackReset = 3.0,
    FastQuestSpawnCycleInterval = 0.45,

    -- Reworked Prison / Head Jailer safety.
    -- Update 30's quest NPC position can make a direct tween finish too close
    -- to the floor/wall. Use one stable approach point beside and above the NPC.
    PrisonSafeQuestMovement = true,
    QuestGiverSafeRadius = 4.0,
    QuestGiverSafeHeight = 3.5,
    QuestGiverInteractDistance = 8.0,
    PrisonPromptRetryInterval = 0.65,
    PrisonQuestConfirmTimeout = 2.0,

    -- Update 30 Prison secret protection.
    -- Before the first normal Prison quest unlocks, never route the player to
    -- Prison/Jail Keeper. Keep farming the final Skylands quest (Dark Master).
    IgnorePrisonSecretQuest = true,
    PrisonEntryLevel = 190,
    PrePrisonFallbackMinLevel = 175,
    PrePrisonFallbackMob = "Dark Master",

    RuthlessPrisonFarmCFrame = CFrame.new(5191, 10, 692),

    -- SKIP FARM LEVEL:
    -- true = skip weak early quests and power-level directly on stronger mobs.
    -- Lv 1-24  -> Dark Master
    -- Lv 25-59 -> Royal Squad
    -- Lv 60+   -> return to normal quest progression.
    SkipFarmLevel = true,

    -- Global Auto Checkpoint is intentionally automatic/internal.
    -- Whenever Auto Farm reaches the real combat area, the Kaitun attempts
    -- to save the current spawn (including Fishman/Underwater City).
    AutoCheckpoint = true,

    -- Second Sea story progression.
    -- Bartilo: 50 Swan Pirates -> Jeremy -> 8-plate puzzle.
    AutoBartiloQuest = true,

    AllowSpecialInterruptFarm = false,

    -- Stable level-farm combat
    FarmOneMobAtATime = true,
    FarmWeaponType = "Melee",
    LockTargetAtSpawn = true,
    TargetLockTolerance = 1.5,
    TargetEquipRetry = 0.20,
    FarmAboveHeight = 7.5,
    FarmAboveApproachDistance = 14,
    CombatHoverP = 18000,
    CombatHoverD = 1200,
    CombatHoverMaxForce = 1000000000,
    StatusMinHold = 0.30,
    HakiInterval = 5.0,
    MeleeCheckInterval = 2.5,
    EquipCheckInterval = 1.25,
    SafetyCheckInterval = 0.25,
    UIRefreshInterval = 0.75,
    StatusUpdateInterval = 0.12,
    SpawnScanInterval = 3.0,

    -- New map boss-spawn countdown display
    BossTimerScanInterval = 2.0,
    BossTimerMaxDistance = 3500,

    -- Boss farm behavior:
    -- never park at an empty boss spawn; farm the best normal quest until
    -- the boss model actually appears in the world.
    BossFallbackToNormalFarm = true,
    BossFallbackStatusTimer = true,
    -- Never accept/re-accept a normal boss quest while its respawn timer is active.
    BossAvoidQuestWhileRespawning = true,
    -- Force an immediate level-quest refresh after a chest detour finishes.
    BossRefreshAfterChest = true,

    -- Raid Boss override for First/Second Sea.
    -- Detects the [Raid Boss] tag dynamically, with known-name fallbacks.
    -- These bosses do not need a normal level quest, so they override Farm Level.
    AutoRaidBosses = true,
    AutoGreybeard = true, -- legacy compatibility; AutoRaidBosses is authoritative

    -- Brand image supplied by the user.
    HubImageURL = "https://ik.imagekit.io/w4ohyg5ry/veltrix/kratoshubv2_pgLfWsISi.png",
    HubImageFile = "kratoshubv2_pgLfWsISi.png",

    FarmSpeed = 190,
    TweenSpeed = 190,
    FarmDistance = 12, -- vertical orbit height above the NPC

    -- Safety settings
    AntiWater = true,
    WaterSafetyY = 5.5,
    WaterRecoveryHeight = 18,
    HPSafety = 25,

    -- Global combat HP safety: disabled by default.
    -- When false, the Kaitun keeps farming even at low HP instead of entering "Recovering HP".
    CombatHPSafety = false,
    CombatRetreatHealth = 0.40,
    CombatResumeHealth = 0.85,
    CombatSafeHeight = 65,
    CombatSafeHoldP = 32000,
    CombatSafeHoldD = 2000,
    CombatSafeMaxForce = 1000000000,

    -- Movement settings
    -- Normal island/NPC travel always uses TweenSpeed; instant TP is not used for travel.
    TpInst = false,
    FlightTweenEnabled = true, -- Normal travel mode: TweenSpeed / flying.
    FlightCruiseHeight = 65,
    FlightLongDistance = 250,
    TravelNoClip = true,
    -- Same movement owner may keep its current tween while the destination moves
    -- slightly (combat orbit, moving NPC, etc). Prevents cancel/recreate stalls.
    TravelRepathDistance = 35,
    TravelMinDuration = 0.10,

    -- Portal routing is automatic/internal. It is deliberately not exposed
    -- as Settings Loader tuning because the Kaitun decides the safest route.

    SearchRadius = 8000,

    -- Hover combat
    HoverEnabled = true,
    HoverHeight = 9,
    FixedHoverHeight = true,
    BossLowHealthHoverHeight = 50,
    BossLowHealthThreshold = 0.40,
    BossEscapeDistance = 30,
    HoverResponsiveness = 80,
    UprightLock = true,
    UprightSnapThreshold = 0.70,
    HoverMaxForce = 1000000,
    HoverMaxVelocity = 450,

    -- Patrol settings
    PatrolRadius = 45,
    PatrolHeight = 12,
    PatrolWait = 0.10,

    -- Combat recovery
    CombatRecovery = true,
    CombatRecoveryTimeout = 4.0,
    CombatRecoveryStepDistance = 8,
    CombatRecoveryMaxAttempts = 3,
    BlockStuckTargetTime = 2.5,

    -- Skill settings
    AutoDodgeSkill = true,
    DodgeTime = 0,

    -- Server settings
    ServerHopEnabled = false, -- normal Farm Level never server-hops
    MaxPlayersPerServer = 5,
    ServerHopRegion = "Singapore",

    -- Temporary server hop used ONLY by required Saber bosses.
    SaberBossServerHop = false,
    SaberBossWaitBeforeHop = 3,
    SaberBossHopCooldown = 4,
    SaberBossHopMaxPlayers = 11,
    SaberBossHopPages = 8,
    SaberBossDisappearGrace = 1.50,
    SaberBossDeathRewardGrace = 3.00,
    SaberBossAttackSpeed = 0.08,

    -- Saber Expert uses a dedicated fixed hover above the boss.
    -- Only the local player is moved; the boss physics are never modified.
    SaberExpertHoverCombat = true,
    SaberExpertHoverHeight = 20,
    SaberExpertApproachDistance = 6,
    SaberExpertHoldP = 32000,
    SaberExpertHoldD = 2200,
    SaberExpertHoldMaxForce = 1000000000,

    -- Special quests
    AutoSaber = true,

    -- Saber Torch / Desert curtain
    SaberTorchDistance = 4.0,
    SaberTorchHoldTime = 0.75,
    SaberTorchRetryInterval = 0.65,
    SaberTorchSideMargin = 1.35,

    -- Stable ground interaction for Torch / Cup / Relic.
    SaberGroundHoldP = 22000,
    SaberGroundHoldD = 1800,
    SaberGroundHoldMaxForce = 1000000000,
    SaberGroundRayHeight = 16,
    SaberGroundRayDepth = 80,
    SaberCupInteractDistance = 5.5,

    -- Saber progression verification
    SaberTorchPickupCheckTime = 2.0,
    SaberTorchPickupRadius = 8,
    SaberCupPickupCheckTime = 2.0,
    SaberCupPickupRadius = 8,
    SaberCupPickupContactInterval = 0.35,
    SaberCupPickupSnapYOffset = 0.0,
    SaberCupPickupSweepRadius = 1.15,
    SaberCupPickupAttemptHold = 0.10,

    -- Updated Cup water / droplet positions.
    -- Try #1 first; if the Cup does not fill, automatically try #2.
    SaberCupWaterPosition1 = CFrame.new(1330.90918, 45.12243, -1289.55664),
    SaberCupWaterTryTime = 3.0,

    -- Exact tested position for the Saber Cup water drop.
    SaberCupLiftHeight = 0.0,
    SaberCupHandleAlign = true,
    SaberCupHandleOffset = Vector3.new(0, 0, 0),
    SaberCupLiftHoldTime = 0.85,
    SaberCupReliftDelay = 0.45,

    -- Saber story NPC / boss progression.
    SaberNPCInteractDistance = 7.5,
    SaberNPCInteractCooldown = 0.85,
    SaberMapCacheInterval = 0.75,
    SaberProgressCheckInterval = 1.50,
    SaberInventoryCheckInterval = 3.00,
    SaberSickManCFrame = CFrame.new(1458.54285, 88.2521744, -1390.34912),
    -- Rich Man position confirmed in-game by Kratos.
    SaberRichManCFrame = CFrame.new(-943.8, 27.6, 4115.5),
    SaberMobLeaderCFrame = CFrame.new(-2848.59399, 7.4272871, 5342.44043),
    SaberMobLeaderHopConfirmDistance = 85, -- only consider hopping once physically near the spawn

    -- Mob Leader fights under/near cliff geometry. Do not farm directly above him:
    -- that can place the character inside the rock ceiling and starve FastAttack.
    SaberMobLeaderCombatRadius = 8,
    SaberMobLeaderCombatHeight = 3,
    SaberMobLeaderAttackRange = 18,
    SaberRelicSlotCFrame = CFrame.new(-1405.41956, 29.8519993, 5.62435055),
    SaberRelicInteractDistance = 7.0,

    AutoPole = false,
    AutoSea2 = true,
    Sea2RequiredLevel = 700,
    Sea2RequireElectroMastery = true,
    Sea2ElectroMasteryTarget = 400,
    Sea2TransitionInteractDistance = 7.0,
    Sea2TransitionActionCooldown = 0.85,

    -- Material farming
    AutoFarmMaterial = false,
    MaterialType = "Angel Wings",

    -- Boss hunting
    AutoAttackBoss = false,
    AutoAttackAllBoss = false,
    BossList = {},

    -- Misc settings
    StackFarmingEnabled = true,

    -- AUTO CHAT
    -- Sends the configured public chat message at the selected interval.
    AutoChatEnabled = false,
    AutoChatText = "NatAov Hub On Top !",
    AutoChatDelay = 20,

    -- FARM FRAGMENTS
    -- Second/Third Sea: when enabled and Lv1100+, raid farming temporarily
    -- overrides normal level farm until this fragment target is reached.
    FarmFragmentsEnabled = false,
    FarmFragmentsTarget = 50000,

    -- OPTIMIZE FIX LAG
    -- User-facing options. Heavy implementation details remain internal.
    OptimizeWhiteScreen = false,
    OptimizeBlackScreen = false,
    OptimizeCleanMap = false,
    OptimizeLockFpsEnabled = false,
    OptimizeLockFps = 20,

    -- FPS BOOST EXTREMO
    -- false = visual normal / boost desligado
    -- true  = remove efeitos visuais pesados localmente
    FPSBoost = false,
    FPSBoostHideMap = true,
    FPSBoostKeepEnemies = true,
    FPSBoostKeepNPCs = true,
    FPSBoostHideOtherPlayers = true,
    FPSBoostBatchSize = 400,

    -- UI cleanup
    -- Automatically advances real NPC dialogue only; never clicks generic screen text.
    HideNPCDialogues = true,
    DialogueRequireRealContainer = true,
    IgnoreEscapedPrisoners = true,

    -- Blox Fruits notification cleanup.
    -- true = hides game toast/pop-up notifications such as money/reward messages.
    -- Does not hide the Kratos interface or the quest tracker.
    HideBloxNotifications = true,

    -- Saber Cup water drop. One forward dash is attempted before precision alignment.
    SaberCupDashOnFill = true,
    SaberCupDashDelay = 0.22,

    Debug = false,

    -- Quest settings
    QuestRefresh = 0.25,
    TargetRefresh = 0.10,
    QuestInteractDistance = 12,
    QuestApproachDistance = 7,
    QuestAcquireRetries = 6,
    QuestNpcRescanTimeout = 12,
    QuestTravelTimeout = 90,
    QuestGuiGrace = 0.90,

    -- Watchdog settings
    WatchdogStuckTime = 4.5,
    WatchdogNoProgressTime = 12,
    WatchdogMoveEpsilon = 2.5,

    -- Mapper settings
    AutoMap = false,
    MapScanInterval = 2.0,
    MapRadius = 2200,
    MapWriteFile = true,
    MapFileName = "Kratos_Ultimate_LiveMap.json",
}

local Config = getgenv().Config

-- Internal tuning values are implementation details, not user settings.
-- Keep the public Config/Settings Loader focused on useful on/off choices.
local InternalTuning = {
    SkipFarm = {
        DarkMasterMaxLevel = 25,
        RoyalSquadMaxLevel = 60,
        EntranceCooldown = 1.25,
        ArrivalDistance = 180,
        LowerSkyEntrance = Vector3.new(-4607.8228, 872.5425, -1667.5569),
        UpperSkyFarmCFrame = CFrame.new(-7654.2514648438, 5637.1079101563, -1407.7550048828),
        UpperSkyEntrance = Vector3.new(-7894.6177, 5547.1416, -380.2912),
    },
    Checkpoint = {
        TargetDistance = 220,
        Retries = 2,
        FishmanRetries = 4,
        RetryDelay = 0.12,
    },
    Portal = {
        Enabled = true,
        MinDistance = 3000,
        MinSavings = 750,
        Cooldown = 1.25,
        SettleTime = 0.90,
        FailureBackoff = 8.0,
        ConfirmMoveDistance = 40,
        UpperSkyConfirmY = 3500,
        UpperSkyConfirmRadius = 1600,
    },
    Fragments = {
        RaidType = "Flame",
        MinHostLevel = 1100,
        ChipRetry = 4.0,
        ChipFallbackRetry = 18.0,
        StartRetry = 3.0,
        IslandMoveDistance = 220,
        EnemySearchRadius = 1800,
        IslandYOffset = 35,
        -- Only these cheap/common stored fruits may be loaded as a microchip
        -- cooldown fallback. Valuable stored fruits are never touched.
        CheapFruitKeys = {
            "Rocket-Rocket",
            "Spin-Spin",
            "Blade-Blade",
            "Chop-Chop", -- legacy name fallback
            "Spring-Spring",
            "Bomb-Bomb",
            "Smoke-Smoke",
        },
    },
}

-- Naming migration: AutoActiveKen is the canonical option.
-- Older loaders that still set AutoKen/AutoObservation remain compatible,
-- but all current code uses Config.AutoActiveKen only.
if Config.AutoActiveKen == nil then
    if Config.AutoKen ~= nil then
        Config.AutoActiveKen = Config.AutoKen == true
    elseif Config.AutoObservation ~= nil then
        Config.AutoActiveKen = Config.AutoObservation == true
    else
        Config.AutoActiveKen = true
    end
end


--=====================================================================================
-- [1.5] EXTERNAL SettingFarm CONFIG BRIDGE
-- Allows a tiny loader to configure the full Kaitun before loadstring() executes it.
-- Missing keys always keep the internal defaults above.
--=====================================================================================
local ExternalSettingFarm = getgenv().SettingFarm

-- Stats defaults remain identical to the current Kaitun unless overridden.
if Config.AutoStatsMelee == nil then Config.AutoStatsMelee = true end
if Config.AutoStatsDefense == nil then Config.AutoStatsDefense = true end
if Config.AutoStatsSword == nil then Config.AutoStatsSword = true end
if Config.AutoStatsGun == nil then Config.AutoStatsGun = false end
if Config.AutoStatsBloxFruit == nil then Config.AutoStatsBloxFruit = false end
if Config.StatPointsPerTick == nil then Config.StatPointsPerTick = 1 end
if Config.HideUI == nil then Config.HideUI = false end

local function SFSection(...)
    if type(ExternalSettingFarm) ~= "table" then
        return nil
    end

    for i = 1, select("#", ...) do
        local name = select(i, ...)
        local value = ExternalSettingFarm[name]
        if type(value) == "table" then
            return value
        end
    end

    return nil
end

local function SFFirst(section, keys, fallback)
    if type(section) ~= "table" then
        return fallback
    end

    for _, key in ipairs(keys) do
        local value = section[key]
        if value ~= nil then
            return value
        end
    end

    return fallback
end

local function SFBool(value, fallback)
    if value == nil then
        return fallback
    end
    return value == true
end

local function SFNumber(value, fallback, minValue, maxValue)
    local n = tonumber(value)
    if not n then
        return fallback
    end
    if minValue ~= nil then n = math.max(minValue, n) end
    if maxValue ~= nil then n = math.min(maxValue, n) end
    return n
end

local function SFPercent(value, fallback)
    local n = tonumber(value)
    if not n then
        return fallback
    end
    if n > 1 then
        n = n / 100
    end
    return math.clamp(n, 0, 1)
end

if type(ExternalSettingFarm) == "table" then
    local main = SFSection("Main", "Main Farm")
    local farm = SFSection("Farm")
    local items = SFSection("Get Items")
    local mastery = SFSection("Farm Mastery")
    local stats = SFSection("Auto Stats", "Stats")
    local fruits = SFSection("Fruits", "Fruit", "Farm Fruit")
    local chests = SFSection("Chests", "Chest", "Chest Farm")
    local combat = SFSection("Combat")
    local abilities = SFSection("Abilities", "Ability Teacher", "Auto Buy Abilities")
    local shopItems = SFSection("Shop Items", "Buy Items", "Items Shop")
    local safety = SFSection("Safety")
    local movement = SFSection("Movement")
    local performance = SFSection("Performance", "FPS") -- legacy compatibility
    local autoChat = SFSection("Auto Chat", "AutoChat", "Chat")
    local fragmentFarm = SFSection("Farm Fragments", "FarmFragments", "Fragments")
    local optimize = SFSection("Optimize Fix Lag", "Optimize", "Fix Lag")
    local codes = SFSection("Codes", "Promo Codes", "Redeem Codes")
    local bosses = SFSection("Bosses", "Boss")
    local server = SFSection("Server")
    local prison = SFSection("Prison", "Prison Safety", "Prison Progression")
    local quests = SFSection("Quests", "Special Quests")
    local ui = SFSection("UI")

    -- Main farm
    Config.AutoFarm = SFBool(SFFirst(main, {"AutoFarm", "Auto Farm", "Enabled"}, nil), Config.AutoFarm)
    Config.AutoQuest = SFBool(SFFirst(main, {"AutoQuest", "Auto Quest"}, nil), Config.AutoQuest)
    Config.FastAttack = SFBool(SFFirst(main, {"FastAttack", "Fast Attack"}, nil), Config.FastAttack)
    Config.AutoTeam = SFBool(SFFirst(main, {"AutoTeam", "Auto Team"}, nil), Config.AutoTeam)
    Config.ForceTeamSet = SFBool(SFFirst(main, {"ForceTeam", "Force Team"}, nil), Config.ForceTeamSet)

    local team = SFFirst(main, {"Team"}, nil)
    if team == "Pirates" or team == "Marines" then
        Config.Team = team
    end

    -- Core farm tuning. Primary values may live in Main; Farm remains supported
    -- for compatibility with older loaders.
    local externalFarmSpeed = SFNumber(
        SFFirst(main, {"FarmSpeed", "Farm Speed"}, SFFirst(farm, {"FarmSpeed", "Farm Speed", "Speed"}, nil)),
        Config.FarmSpeed,
        50,
        500
    )
    Config.FarmSpeed = externalFarmSpeed
    Config.TweenSpeed = externalFarmSpeed

    Config.FarmDistance = SFNumber(
        SFFirst(main, {"FarmDistance", "Farm Distance"}, SFFirst(farm, {"FarmDistance", "Farm Distance"}, nil)),
        Config.FarmDistance,
        5,
        150
    )
    Config.FarmOrbitRadius = SFNumber(
        SFFirst(farm, {"FarmOrbitRadius", "OrbitRadius", "Orbit Radius"}, nil),
        Config.FarmOrbitRadius,
        5,
        100
    )
    Config.FarmOrbitSpeed = SFNumber(
        SFFirst(farm, {"FarmOrbitSpeed", "OrbitSpeed", "Orbit Speed"}, nil),
        Config.FarmOrbitSpeed,
        30,
        720
    )
    Config.StrictQuestSync = SFBool(
        SFFirst(farm, {"StrictQuestSync", "Strict Quest Sync", "QuestSync", "Quest Sync"}, nil),
        Config.StrictQuestSync
    )
    Config.QuestMismatchAbandonInterval = SFNumber(
        SFFirst(farm, {"QuestMismatchAbandonInterval", "Quest Mismatch Abandon Interval"}, nil),
        Config.QuestMismatchAbandonInterval,
        0.15,
        2.0
    )
    Config.FarmAboveApproachDistance = Config.FarmDistance

    Config.BringMobs = SFBool(
        SFFirst(farm, {"BringMobs", "Bring Mobs"}, nil),
        Config.BringMobs
    )
    Config.BringMobCount = SFNumber(
        SFFirst(farm, {"BringMobCount", "Bring Mob Count"}, nil),
        Config.BringMobCount,
        1,
        25
    )
    Config.BringMobRadius = SFNumber(
        SFFirst(farm, {"BringMobRadius", "Bring Mob Radius"}, nil),
        Config.BringMobRadius,
        25,
        2000
    )

    Config.SkipFarmLevel = SFBool(
        SFFirst(
            main,
            {"SkipFarmLevel", "Skip Farm Level"},
            SFFirst(
                farm,
                {"SkipFarmLevel", "Skip Farm Level", "SkylandRush", "Skyland Rush", "RushSkyland"},
                nil
            )
        ),
        Config.SkipFarmLevel
    )

    -- Special quest progression
    Config.AutoBartiloQuest = SFBool(
        SFFirst(quests, {"Bartilo", "BartiloQuest", "Bartilo Quest", "AutoBartilo"}, nil),
        Config.AutoBartiloQuest
    )

    -- Nearby chest collection
    Config.AutoCollectNearbyChests = SFBool(
        SFFirst(chests, {"AutoCollect", "Auto Collect", "Enabled"}, nil),
        Config.AutoCollectNearbyChests
    )
    Config.ChestCollectRadius = SFNumber(
        SFFirst(chests, {"Radius", "CollectRadius", "Collect Radius"}, nil),
        Config.ChestCollectRadius,
        25,
        2000
    )
    Config.ChestReturnToFarm = SFBool(
        SFFirst(chests, {"ReturnToFarm", "Return To Farm"}, nil),
        Config.ChestReturnToFarm
    )

    -- Saber is a primary progression toggle in the clean loader.
    Config.AutoSaber = SFBool(
        SFFirst(main, {"Saber", "AutoSaber", "Auto Saber"}, SFFirst(items, {"Saber"}, nil)),
        Config.AutoSaber
    )

    -- Melee mastery / fighting style progression
    local meleeMasteryEnabled = SFFirst(mastery, {"Melee"}, nil)
    if meleeMasteryEnabled ~= nil then
        Config.AutoMelee = SFBool(meleeMasteryEnabled, Config.AutoMelee)
        Config.AutoFightingStyles = SFBool(meleeMasteryEnabled, Config.AutoFightingStyles)
    end
    Config.FightingStyleMasteryTarget = SFNumber(
        SFFirst(mastery, {"Target", "Mastery", "MasteryTarget", "Mastery Target"}, nil),
        Config.FightingStyleMasteryTarget,
        1,
        600
    )

    -- Auto Stats. Default remains Melee + Defense + Sword, as requested.
    Config.AutoStats = SFBool(SFFirst(stats, {"Enabled"}, nil), Config.AutoStats)
    Config.AutoStatsMelee = SFBool(SFFirst(stats, {"Melee"}, nil), Config.AutoStatsMelee)
    Config.AutoStatsDefense = SFBool(SFFirst(stats, {"Defense"}, nil), Config.AutoStatsDefense)
    Config.AutoStatsSword = SFBool(SFFirst(stats, {"Sword"}, nil), Config.AutoStatsSword)
    Config.AutoStatsGun = SFBool(SFFirst(stats, {"Gun"}, nil), Config.AutoStatsGun)
    Config.AutoStatsBloxFruit = SFBool(SFFirst(stats, {"BloxFruit", "Blox Fruit", "Demon Fruit"}, nil), Config.AutoStatsBloxFruit)
    Config.StatPointsPerTick = SFNumber(
        SFFirst(stats, {"PointsPerTick", "Points Per Tick", "Points"}, nil),
        Config.StatPointsPerTick,
        1,
        100
    )

    -- Fruit collection. Filter is a whitelist; empty means collect no fruits.
    Config.AutoFruit = SFBool(
        SFFirst(fruits, {"AutoCollect", "Auto Fruit", "AutoFruit", "Enabled"}, nil),
        Config.AutoFruit
    )
    Config.FruitAutoStore = SFBool(
        SFFirst(fruits, {"AutoStore", "Auto Store", "Store"}, nil),
        Config.FruitAutoStore
    )
    Config.FruitAutoRandom = SFBool(
        SFFirst(fruits, {"AutoRandom", "Auto Random"}, nil),
        Config.FruitAutoRandom
    )
    Config.FruitStoreAnyOwned = SFBool(
        SFFirst(fruits, {"StoreAnyOwned", "Store Any Owned", "AutoStoreAny"}, nil),
        Config.FruitStoreAnyOwned
    )
    Config.FruitStoreScanInterval = SFNumber(
        SFFirst(fruits, {"StoreScanInterval", "Store Scan Interval"}, nil),
        Config.FruitStoreScanInterval,
        0.05,
        5.0
    )
    Config.FruitStoreRetryInterval = SFNumber(
        SFFirst(fruits, {"StoreRetryInterval", "Store Retry Interval"}, nil),
        Config.FruitStoreRetryInterval,
        0.10,
        15.0
    )
    Config.FruitStoreMaxAttempts = SFNumber(
        SFFirst(fruits, {"StoreMaxAttempts", "Store Max Attempts"}, nil),
        Config.FruitStoreMaxAttempts,
        1,
        20
    )
    Config.FruitIgnorePuzzleObjects = SFBool(
        SFFirst(fruits, {"IgnorePuzzleObjects", "Ignore Puzzle Objects", "IgnoreStatues"}, nil),
        Config.FruitIgnorePuzzleObjects
    )
    Config.FruitUnknownModelMaxSize = SFNumber(
        SFFirst(fruits, {"UnknownModelMaxSize", "Unknown Model Max Size"}, nil),
        Config.FruitUnknownModelMaxSize,
        1,
        20
    )
    Config.FruitESP = SFBool(
        SFFirst(fruits, {"ESP", "FruitESP", "Fruit ESP"}, nil),
        Config.FruitESP
    )
    Config.FruitESPShowDistance = SFBool(
        SFFirst(fruits, {"ESPDistance", "ESP Distance", "ShowDistance", "Show Distance"}, nil),
        Config.FruitESPShowDistance
    )
    Config.FruitESPShowRarity = SFBool(
        SFFirst(fruits, {"ESPRarity", "ESP Rarity", "ShowRarity", "Show Rarity"}, nil),
        Config.FruitESPShowRarity
    )
    Config.FruitESPMaxDistance = SFNumber(
        SFFirst(fruits, {"ESPMaxDistance", "ESP Max Distance", "MaxDistance"}, nil),
        Config.FruitESPMaxDistance,
        100,
        50000
    )
    Config.FruitCollectUnknown = SFBool(
        SFFirst(fruits, {"CollectUnknown", "Collect Unknown", "UnknownFallback"}, nil),
        Config.FruitCollectUnknown
    )
    Config.FruitUnknownCollectDelay = SFNumber(
        SFFirst(fruits, {"UnknownCollectDelay", "Unknown Collect Delay"}, nil),
        Config.FruitUnknownCollectDelay,
        0,
        30
    )
    Config.FruitUnknownMaxDistance = SFNumber(
        SFFirst(fruits, {"UnknownMaxDistance", "Unknown Max Distance", "UnknownCollectMaxDistance"}, nil),
        Config.FruitUnknownMaxDistance,
        25,
        5000
    )
    Config.FruitUnknownFailureCooldown = SFNumber(
        SFFirst(fruits, {"UnknownFailureCooldown", "Unknown Failure Cooldown"}, nil),
        Config.FruitUnknownFailureCooldown,
        3,
        300
    )

    local fruitFilter = SFFirst(fruits, {"Filter", "Whitelist", "FruitFilter", "Fruit Filter"}, nil)
    if type(fruitFilter) == "table" then
        Config.FruitFilter = {}
        for _, fruitName in ipairs(fruitFilter) do
            if type(fruitName) == "string" and fruitName ~= "" then
                table.insert(Config.FruitFilter, fruitName)
            end
        end
    end

    -- Combat. Primary user-facing controls may live in Main; Combat remains
    -- accepted for backwards compatibility.
    Config.AutoHaki = SFBool(
        SFFirst(main, {"AutoHaki", "Auto Haki", "Haki"}, SFFirst(combat, {"AutoHaki", "Auto Haki", "Haki"}, nil)),
        Config.AutoHaki
    )
    Config.AutoActiveKen = SFBool(
        SFFirst(
            main,
            {"AutoActiveKen", "Auto Active Ken", "AutoActivateKen", "Auto Activate Ken", "AutoKen", "Auto Ken", "AutoObservation", "Auto Observation", "Observation"},
            SFFirst(combat, {"AutoActiveKen", "Auto Active Ken", "AutoActivateKen", "Auto Activate Ken", "AutoKen", "Auto Ken", "AutoObservation", "Auto Observation", "Observation"}, nil)
        ),
        Config.AutoActiveKen
    )

    -- Ability purchases are separate from activation. AutoActiveKen activates Instinct;
    -- AutoBuyInstinctV1 purchases it when Lv300 + Saber + 750k are available.
    Config.AutoBuyAirJump = SFBool(
        SFFirst(abilities, {"AirJump", "Air Jump", "Geppo", "AutoBuyAirJump"}, nil),
        Config.AutoBuyAirJump
    )
    Config.AutoBuyAura = SFBool(
        SFFirst(abilities, {"Aura", "Buso", "AutoBuyAura"}, nil),
        Config.AutoBuyAura
    )
    Config.AutoBuyFlashStep = SFBool(
        SFFirst(abilities, {"FlashStep", "Flash Step", "Soru", "AutoBuyFlashStep"}, nil),
        Config.AutoBuyFlashStep
    )
    Config.AutoBuyInstinctV1 = SFBool(
        SFFirst(abilities, {"InstinctV1", "Instinct V1", "ObservationV1", "Observation V1", "Ken", "AutoBuyInstinctV1"}, nil),
        Config.AutoBuyInstinctV1
    )
    Config.AbilityBuyInterval = SFNumber(
        SFFirst(abilities, {"BuyInterval", "Buy Interval", "RetryInterval", "Retry Interval"}, nil),
        Config.AbilityBuyInterval,
        0.5,
        30
    )
    Config.KenActivateInterval = SFNumber(
        SFFirst(abilities, {"KenActivateInterval", "Ken Activate Interval", "ActivationInterval"}, nil),
        Config.KenActivateInterval,
        0.25,
        10
    )

    if type(shopItems) == "table" then
        Config.AutoBuyShopItems = Config.AutoBuyShopItems or {}
        for itemName, fallback in pairs(Config.AutoBuyShopItems) do
            local external = shopItems[itemName]
            if external ~= nil then
                Config.AutoBuyShopItems[itemName] = external == true
            else
                Config.AutoBuyShopItems[itemName] = fallback == true
            end
        end

        Config.ShopItemRetryInterval = SFNumber(
            SFFirst(shopItems, {"RetryInterval", "Retry Interval"}, nil),
            Config.ShopItemRetryInterval,
            2,
            120
        )
        Config.ShopInventoryRefreshInterval = SFNumber(
            SFFirst(shopItems, {"InventoryRefreshInterval", "Inventory Refresh Interval"}, nil),
            Config.ShopInventoryRefreshInterval,
            2,
            60
        )
    end

    Config.AttackSpeed = SFNumber(
        SFFirst(main, {"AttackSpeed", "Attack Speed"}, SFFirst(combat, {"AttackSpeed", "Attack Speed"}, nil)),
        Config.AttackSpeed,
        0.05,
        1.00
    )

    local useSkills = SFFirst(main, {"UseSkills", "Use Skills", "Skills"}, SFFirst(combat, {"UseSkills", "Use Skills", "Skills"}, nil))
    if useSkills ~= nil then
        Config.UseSkills = SFBool(useSkills, Config.UseSkills)
        Config.SkillsEnabled = SFBool(useSkills, Config.SkillsEnabled)
    end

    -- Promo / XP codes
    Config.AutoRedeemCodes = SFBool(
        SFFirst(codes, {"AutoRedeem", "Auto Redeem", "Enabled"}, nil),
        Config.AutoRedeemCodes
    )
    Config.CodeRedeemDelay = SFNumber(
        SFFirst(codes, {"RedeemDelay", "Redeem Delay", "Delay"}, nil),
        Config.CodeRedeemDelay,
        0.10,
        2.00
    )

    -- Safety
    Config.AntiWater = SFBool(SFFirst(safety, {"AntiWater", "Anti Water"}, nil), Config.AntiWater)
    Config.CombatHPSafety = SFBool(SFFirst(safety, {"HPSafety", "HP Safety"}, nil), Config.CombatHPSafety)
    Config.CombatRetreatHealth = SFPercent(
        SFFirst(safety, {"RetreatHP", "Retreat HP", "Retreat Health"}, nil),
        Config.CombatRetreatHealth
    )
    Config.CombatResumeHealth = SFPercent(
        SFFirst(safety, {"ResumeHP", "Resume HP", "Resume Health"}, nil),
        Config.CombatResumeHealth
    )
    Config.CombatSafeHeight = SFNumber(
        SFFirst(safety, {"SafeHeight", "Safe Height"}, nil),
        Config.CombatSafeHeight,
        10,
        250
    )

    -- Movement
    Config.TweenSpeed = SFNumber(
        SFFirst(movement, {"Tween Speed", "Speed"}, nil),
        Config.TweenSpeed,
        50,
        500
    )
    Config.FlightTweenEnabled = SFBool(
        SFFirst(movement, {"Flight Tween", "Fly"}, nil),
        Config.FlightTweenEnabled
    )
    Config.TravelNoClip = SFBool(
        SFFirst(main, {"No Clip", "NoClip", "Noclip"}, SFFirst(movement, {"No Clip", "NoClip", "Noclip"}, nil)),
        Config.TravelNoClip
    )
    -- Portal routing is intentionally internal.
    -- Settings Loader does not expose portal tuning; the Kaitun automatically
    -- decides when requestEntrance is worthwhile.

    -- Auto Chat
    Config.AutoChatEnabled = SFBool(
        SFFirst(autoChat, {"Enabled", "AutoChat", "Auto Chat"}, nil),
        Config.AutoChatEnabled
    )
    local externalChatText = SFFirst(autoChat, {"Text", "Message"}, nil)
    if externalChatText ~= nil then
        Config.AutoChatText = tostring(externalChatText)
    end
    Config.AutoChatDelay = SFNumber(
        SFFirst(autoChat, {"Delay", "Interval"}, nil),
        Config.AutoChatDelay,
        5,
        3600
    )

    -- Farm Fragments: target-based raid farming.
    Config.FarmFragmentsEnabled = SFBool(
        SFFirst(fragmentFarm, {"Enabled", "Auto", "Farm"}, nil),
        Config.FarmFragmentsEnabled
    )
    Config.FarmFragmentsTarget = SFNumber(
        SFFirst(fragmentFarm, {"Fragment", "Fragments", "Target", "Amount"}, nil),
        Config.FarmFragmentsTarget,
        0,
        1000000000
    )

    -- Optimize Fix Lag
    Config.OptimizeWhiteScreen = SFBool(
        SFFirst(optimize, {"White Screen", "WhiteScreen"}, nil),
        Config.OptimizeWhiteScreen
    )
    Config.OptimizeBlackScreen = SFBool(
        SFFirst(optimize, {"Black Screen", "BlackScreen"}, nil),
        Config.OptimizeBlackScreen
    )
    Config.OptimizeCleanMap = SFBool(
        SFFirst(optimize, {"Clean Map", "CleanMap"}, nil),
        Config.OptimizeCleanMap
    )

    local lockFps = SFFirst(optimize, {"Lock Fps", "Lock FPS", "FPS Lock"}, nil)
    if type(lockFps) == "table" then
        Config.OptimizeLockFpsEnabled = SFBool(
            SFFirst(lockFps, {"Enabled", "Enable"}, nil),
            Config.OptimizeLockFpsEnabled
        )
        Config.OptimizeLockFps = SFNumber(
            SFFirst(lockFps, {"FPS", "Fps", "Value"}, nil),
            Config.OptimizeLockFps,
            10,
            360
        )
    end

    -- Performance (legacy loader compatibility). Clean Map reuses the existing
    -- reversible FPSBoost optimizer instead of maintaining a second map cleaner.
    Config.FPSBoost = SFBool(SFFirst(performance, {"FPSBoost", "FPS Boost", "Enabled"}, nil), Config.FPSBoost)
    Config.FPSBoostHideMap = SFBool(SFFirst(performance, {"Hide Map"}, nil), Config.FPSBoostHideMap)
    Config.FPSBoostKeepEnemies = SFBool(SFFirst(performance, {"Keep Enemies"}, nil), Config.FPSBoostKeepEnemies)
    Config.FPSBoostKeepNPCs = SFBool(SFFirst(performance, {"Keep NPCs"}, nil), Config.FPSBoostKeepNPCs)
    Config.FPSBoostHideOtherPlayers = SFBool(
        SFFirst(performance, {"Hide Other Players"}, nil),
        Config.FPSBoostHideOtherPlayers
    )
    if Config.OptimizeCleanMap then
        Config.FPSBoost = true
        Config.FPSBoostHideMap = true
        Config.FPSBoostKeepEnemies = true
        Config.FPSBoostKeepNPCs = true
    end

    -- Boss handling
    Config.BossFallbackToNormalFarm = SFBool(
        SFFirst(bosses, {"FarmNormalWhileWaiting", "Farm Normal While Waiting", "Fallback To Normal Farm"}, nil),
        Config.BossFallbackToNormalFarm
    )
    Config.BossFallbackStatusTimer = SFBool(
        SFFirst(bosses, {"Show Timer", "Boss Timer"}, nil),
        Config.BossFallbackStatusTimer
    )
    Config.BossAvoidQuestWhileRespawning = SFBool(
        SFFirst(bosses, {"AvoidQuestWhileRespawning", "Avoid Boss Quest While Respawning", "No Reaccept Boss Quest"}, nil),
        Config.BossAvoidQuestWhileRespawning
    )
    Config.BossRefreshAfterChest = SFBool(
        SFFirst(bosses, {"RefreshAfterChest", "Refresh Boss After Chest"}, nil),
        Config.BossRefreshAfterChest
    )
    local legacyGreybeard = SFFirst(bosses, {"Greybeard", "AutoGreybeard", "Auto Greybeard"}, nil)
    Config.AutoRaidBosses = SFBool(
        SFFirst(bosses, {"RaidBosses", "AutoRaidBosses", "Raid Bosses", "Auto Raid Bosses"}, legacyGreybeard),
        Config.AutoRaidBosses
    )
    Config.AutoGreybeard = Config.AutoRaidBosses

    -- Server behavior
    Config.ServerHopEnabled = SFBool(SFFirst(server, {"ServerHop", "Server Hop"}, nil), Config.ServerHopEnabled)
    Config.SaberBossServerHop = SFBool(SFFirst(server, {"SaberBossHop", "Saber Boss Hop"}, nil), Config.SaberBossServerHop)

    -- Prison / secret-quest protection
    Config.PrisonSafeQuestMovement = SFBool(
        SFFirst(prison, {"SafeQuestMovement", "Safe Quest Movement"}, nil),
        Config.PrisonSafeQuestMovement
    )
    Config.QuestGiverInteractDistance = SFNumber(
        SFFirst(prison, {"QuestInteractDistance", "Quest Interact Distance", "InteractDistance"}, nil),
        Config.QuestGiverInteractDistance,
        3,
        20
    )
    Config.PrisonPromptRetryInterval = SFNumber(
        SFFirst(prison, {"PromptRetryInterval", "Prompt Retry Interval"}, nil),
        Config.PrisonPromptRetryInterval,
        0.10,
        5.0
    )
    Config.PrisonQuestConfirmTimeout = SFNumber(
        SFFirst(prison, {"QuestConfirmTimeout", "Quest Confirm Timeout"}, nil),
        Config.PrisonQuestConfirmTimeout,
        0.5,
        10.0
    )
    Config.IgnorePrisonSecretQuest = SFBool(
        SFFirst(prison, {"IgnoreSecretQuest", "Ignore Prison Secret Quest", "IgnorePrisonSecretQuest"}, nil),
        Config.IgnorePrisonSecretQuest
    )
    Config.PrisonEntryLevel = SFNumber(
        SFFirst(prison, {"EntryLevel", "Prison Entry Level", "PrisonEntryLevel"}, nil),
        Config.PrisonEntryLevel,
        1,
        700
    )
    Config.PrePrisonFallbackMinLevel = SFNumber(
        SFFirst(prison, {"FallbackMinLevel", "Fallback Min Level", "PrePrisonFallbackMinLevel"}, nil),
        Config.PrePrisonFallbackMinLevel,
        1,
        700
    )
    local fallbackMob = SFFirst(prison, {"FallbackMob", "Fallback Mob", "PrePrisonFallbackMob"}, nil)
    if type(fallbackMob) == "string" and fallbackMob ~= "" then
        Config.PrePrisonFallbackMob = fallbackMob
    end

    -- UI
    Config.HideNPCDialogues = SFBool(
        SFFirst(ui, {"HideNPCDialogues", "Hide NPC Dialogues", "Hide Dialogues"}, nil),
        Config.HideNPCDialogues
    )
    Config.IgnoreEscapedPrisoners = SFBool(
        SFFirst(ui, {"IgnoreEscapedPrisoners", "Ignore Escaped Prisoners"}, nil),
        Config.IgnoreEscapedPrisoners
    )
    Config.HideBloxNotifications = SFBool(
        SFFirst(ui, {"HideBloxNotifications", "Hide Blox Notifications", "Hide Notifications"}, nil),
        Config.HideBloxNotifications
    )
    Config.HideUI = SFBool(
        SFFirst(ui, {"Hide UI"}, ExternalSettingFarm["Hide UI"]),
        Config.HideUI
    )
end

-- Legacy/simple Kaitun config compatibility.
-- Example:
-- getgenv().Configs = {
--     SkipFarmLevel = true
-- }
local LegacyConfigs = getgenv().Configs
if type(LegacyConfigs) == "table" then
    if LegacyConfigs.SkipFarmLevel ~= nil then
        Config.SkipFarmLevel = LegacyConfigs.SkipFarmLevel == true
    end
    if LegacyConfigs.BartiloQuest ~= nil then
        Config.AutoBartiloQuest = LegacyConfigs.BartiloQuest == true
    elseif LegacyConfigs.AutoBartiloQuest ~= nil then
        Config.AutoBartiloQuest = LegacyConfigs.AutoBartiloQuest == true
    end
end

-- Prevent multiple executions.
-- Stop the previous Kratos instance before starting this one so an old tween
-- cannot keep pulling the character toward Skylands.
local __KRATOS_ENV = getgenv()
local __PREVIOUS_KRATOS_CLEANUP = __KRATOS_ENV.__KRATOS_CLEANUP
if type(__PREVIOUS_KRATOS_CLEANUP) == "function" then
    pcall(__PREVIOUS_KRATOS_CLEANUP)
end
__KRATOS_ENV.__KRATOS_CLEANUP = nil

local __KRATOS_SESSION = tostring(os.clock()) .. "_" .. tostring(math.random(100000, 999999))
__KRATOS_ENV.__KRATOS_ACTIVE_SESSION = __KRATOS_SESSION

local function IsCurrentSession()
    return __KRATOS_ENV.__KRATOS_ACTIVE_SESSION == __KRATOS_SESSION
end

-- Forward declaration for SetupTeam
local SetupTeam
local LastTeamSetAt = 0

--=====================================================================================
-- [2] SERVICES
--=====================================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local StatsService = game:GetService("Stats")
local TeleportService = game:GetService("TeleportService")
local TextChatService = game:GetService("TextChatService")

-- LocalPlayer can still be nil for a few frames even after game:IsLoaded().
-- Resolve it once here because many Kaitun systems depend on it.
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.10)
    LocalPlayer = Players.LocalPlayer
end

-- VELTRIX ANTI-AFK
-- Uses Roblox's idle signal and a low-frequency fallback pulse.
local AntiAFK = {
    Enabled = true,
    Connection = nil,
}

local function AntiAFKPulse()
    if not AntiAFK.Enabled then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(math.huge, math.huge))
    end)
end

local function StartAntiAFK()
    if AntiAFK.Connection or not LocalPlayer then
        return
    end

    -- Some executors expose LocalPlayer a little late or can fail when binding
    -- directly to Idled. Keep the event path protected and retain the fallback.
    local ok, connection = pcall(function()
        return LocalPlayer.Idled:Connect(function()
            AntiAFKPulse()
        end)
    end)

    if ok then
        AntiAFK.Connection = connection
    end

    task.spawn(function()
        while AntiAFK.Enabled and IsCurrentSession() do
            task.wait(600)

            if not AntiAFK.Enabled or not IsCurrentSession() then
                break
            end

            AntiAFKPulse()
        end
    end)
end

StartAntiAFK()

local PLACE_ID = game.PlaceId

local function GetCommF()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then
        return nil
    end
    return remotes:FindFirstChild("CommF_")
end

local function WaitForCommF(timeout)
    local deadline = tick() + (timeout or 30)

    while tick() < deadline do
        local remote = GetCommF()
        if remote then
            return remote
        end
        task.wait(0.1)
    end

    return GetCommF()
end

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local CommF_ = GetCommF()

local Modules = ReplicatedStorage:FindFirstChild("Modules")
local Net = Modules and Modules:FindFirstChild("Net")

--=====================================================================================
local Logger = {}
local UI = {}
local Utils = {}
local Teleport = {}
local Attack = {}
local Combat = {}
local QuestSystem = {}
local QuestData = {}
local HakiSystem = {}
HakiSystem.LastBuso = 0
HakiSystem.LastKen = 0
local AbilitySystem = {}
local StatsSystem = {}
local FruitSystem = {}
local FruitESPSystem = {}
local ChestSystem = {}
local CheckpointSystem = {}
local SkipFarmLevelSystem = {}
local BartiloSystem = {}
local MeleeSystem = {}
local CodeSystem = {}
local SaberSystem = {}

-- Dynamic setter keeps Saber runtime cache fields compatible with both
-- strict Luau type checking and plain-Lua obfuscators. Function parameters
-- are intentionally untyped so heterogeneous runtime values do not seal the table.
local _rawset = rawset
local function SaberDynamicSet(key, value)
    _rawset(SaberSystem, key, value)
end
local PoleSystem = {}
local Sea2System = {}
local SafetySystem = {}
local CameraSystem = {}
local MapperSystem = {}
local FarmEngine = {}
local FarmContext = {}
local FPSBoostSystem = {}
local ItemCheckSystem = {}
local Watchdog = {}
local SkillSystem = {}
local DialogueSuppressor = {}
local GameNotificationSuppressor = {}
local ServerSystem = {}
local MaterialSystem = {}
local BossSystem = {}
local RaidSystem = {}
local AutoChatSystem = {}
local FragmentFarmSystem = {}
local OptimizeFixLagSystem = {}
local EnemySpawns = nil
local EnemyCDKSpawns = nil

local function NormalizeInventoryItemName(value)
    return tostring(value or ""):lower():gsub("[^%w]", "")
end

local function InventoryHasItem(inventory, wantedName)
    if type(inventory) ~= "table" then
        return false
    end

    local wanted = NormalizeInventoryItemName(wantedName)
    local seen = {}

    local function scan(value, depth)
        if depth > 5 then
            return false
        end

        if type(value) == "string" then
            return NormalizeInventoryItemName(value) == wanted
        end

        if type(value) ~= "table" or seen[value] then
            return false
        end

        seen[value] = true

        for _, field in ipairs({"Name", "name", "DisplayName", "StorageKey", "ItemName"}) do
            local fieldValue = value[field]
            if type(fieldValue) == "string"
                and NormalizeInventoryItemName(fieldValue) == wanted then
                return true
            end
        end

        for key, child in pairs(value) do
            if type(key) == "string" and NormalizeInventoryItemName(key) == wanted then
                if child == true or child == 1 or type(child) == "table" or type(child) == "string" then
                    return true
                end
            end

            if type(child) == "table" and scan(child, depth + 1) then
                return true
            end
        end

        return false
    end

    return scan(inventory, 0)
end

local function FetchPlayerInventory()
    if not CommF_ then
        CommF_ = WaitForCommF(2)
    end

    if not CommF_ then
        return nil
    end

    -- Current/open-source Blox Fruits scripts use lower-case getInventory.
    -- Keep GetInventory as a compatibility fallback for older builds.
    for _, command in ipairs({"getInventory", "GetInventory"}) do
        local ok, inventory = pcall(function()
            return CommF_:InvokeServer(command)
        end)

        if ok and type(inventory) == "table" then
            return inventory
        end
    end

    return nil
end

local function FetchStoredWeaponInventory()
    if not CommF_ then
        CommF_ = WaitForCommF(2)
    end

    if not CommF_ then
        return nil
    end

    local ok, inventory = pcall(function()
        return CommF_:InvokeServer("getInventoryWeapons")
    end)

    if ok and type(inventory) == "table" then
        return inventory
    end

    return nil
end

-- Forward declaration: Bartilo checks quest UI before the quest helpers are defined.
local IsGuiActuallyVisible = function() return false end
-- Early module contracts.
-- These keys are declared before any UI/initialization code can reference them.
PoleSystem.Has = false
SaberSystem.Has = false
SaberSystem.PlatesCache = nil

FarmEngine.Activity = "Idle"
FarmEngine.State = "INITIALIZING"
FarmEngine.Running = false

-- Central movement gate. A farm tick that was already executing when the
-- user presses OFF must not be able to recreate a tween/hover afterwards.
local function AutomationMovementAllowed()
    return Config.AutoFarm ~= false
        and FarmEngine.Running == true
        and (UI.KaitunEnabled == nil or UI.KaitunEnabled == true)
end

QuestSystem.Current = nil
QuestSystem.LastUpdate = 0
QuestSystem.LastQuestAction = 0
QuestSystem.LocalKills = 0
QuestSystem.FallbackMode = false
QuestSystem.FallbackMob = nil
QuestSystem.SpawnCache = {}
QuestSystem.GiverCache = {}
QuestSystem.LastSearch = 0
QuestSystem.LastMove = 0
QuestSystem.ActiveQuestCache = false
QuestSystem.ActiveQuestCheckAt = 0
QuestSystem.RequireQuestClear = false
QuestSystem.QuestSwitchFrom = nil
QuestSystem.QuestSwitchTo = nil
QuestSystem.LastMismatchAbandonAt = 0
QuestSystem.LastPrisonInteractAt = 0
QuestSystem.PrisonWaitingSince = 0
QuestSystem.PendingBossName = nil
QuestSystem.PendingBossTimer = nil
QuestSystem.AnyQuestCheckAt = 0
QuestSystem.AnyQuestCache = false

AbilitySystem.Inventory = {}

Combat.HealthRetreatActive = false
Combat.LastFallbackQuest = nil
Combat.LastFallbackScan = 0
Combat.FallbackCache = {}
Combat.ReleaseHealthRetreat = function() end
Combat.ResetAnchor = function() end
Combat.StopAboveHead = function() end

Attack.RefreshRemotes = function() return false end
Attack.PrimeHitToken = function() return false end
HakiSystem.ActivateBuso = function() end

-- Forward-compatible defaults. Real implementations are assigned later.
QuestSystem.GetQuestProgress = function()
    return 0, 0
end

QuestSystem.HasValidQuest = function()
    return QuestSystem.Current ~= nil
end

QuestSystem.Update = function()
end

QuestSystem.Acquire = function()
    return false
end

QuestSystem.FindSpawnPosition = function()
    return nil
end

QuestSystem.GoToFarmAfterAcquire = function()
    return false
end

Combat.FindNearestEnemy = function()
    return nil
end

Combat.Tick = function()
end

Attack.Init = function()
end

SkillSystem.Animations = {}

SkillSystem.MonitorSkills = function()
end

FarmEngine.Start = function()
end

FarmEngine.Stop = function()
end

local function LoggerJoin(...)
    local values = {...}
    local output = {}
    for i, value in ipairs(values) do
        output[i] = tostring(value)
    end
    return table.concat(output, " ")
end

function Logger.info(...)
    local message = LoggerJoin(...)
    pcall(function()
        _G.print("[KRATOS][INFO] " .. message)
    end)
end

function Logger.warn(...)
    local message = LoggerJoin(...)
    pcall(function()
        _G.warn("[KRATOS][WARN] " .. message)
    end)
end

function Logger.error(...)
    local message = LoggerJoin(...)
    pcall(function()
        _G.warn("[KRATOS][ERROR] " .. message)
    end)
end

-- [2.5] TEAM SELECTION
--=====================================================================================

function SetupTeam()
    if not Config.AutoTeam then
        return
    end

    -- Do not call SetTeam again when the player is already on the requested team.
    -- Re-sending SetTeam on script re-execution can respawn the character and
    -- make the farm appear to "jump" back to another island/spawn.
    if tostring(LocalPlayer.Team) == tostring(Config.Team) then
        LastTeamSetAt = tick()
        return
    end

    local now = tick()
    if (now - LastTeamSetAt) < 5.0 and tostring(LocalPlayer.Team) == tostring(Config.Team) then
        return
    end

    -- Wait for CommF to be available
    local remote = WaitForCommF(10)
    if not remote then
        Logger.warn("Could not find CommF_ for team selection")
        return
    end
    
    -- Update global CommF_
    CommF_ = remote

    -- Force team selection with retry logic
    local maxRetries = 10
    for i = 1, maxRetries do
        pcall(function()
            CommF_:InvokeServer("SetTeam", Config.Team)
        end)
        
        task.wait(0.8)
        
        -- Verify team was set
        local currentTeam = tostring(LocalPlayer.Team)
        if currentTeam == Config.Team then
            Logger.info("Team set to:", Config.Team)
            LastTeamSetAt = tick()
            return
        end
        
        Logger.warn("Team selection attempt", i, "failed, retrying...")
    end
    
    Logger.warn("Failed to set team after", maxRetries, "attempts")
end

--=====================================================================================
-- [3] MODULES
--=====================================================================================


--=====================================================================================
-- [4] UI - PREMIUM RED THEME
--=====================================================================================

UI.ScreenGui = nil
UI.Panel = nil
UI.StatusLabel = nil
UI.ActivityLabel = nil
UI.StatLabels = {}
UI.SpecialStatus = {}
UI.ItemStatus = {}
UI.TopStatusPanel = nil
UI.TopTitleLabel = nil
UI.TopFarmLabel = nil
UI.TopItemLabel = nil
UI.BlurEffect = nil
UI.DiscordLabel = nil
UI.ToggleButton = nil
UI.ControlHolder = nil

UI.BossTimerLastScan = 0
UI.BossTimerName = "-"
UI.BossTimerValue = "--:--"
UI.BossTimerDistance = 0
UI.NamedBossTimerCache = {}

UI.BrandAsset = nil
UI.BrandLoading = false
UI.BrandTargets = {}

UI.PanelBubble = nil
UI.PowerBubble = nil
UI.KaitunEnabled = Config.AutoFarm ~= false

Utils.LastEquipCheck = 0
Utils.LastEquippedWeapon = "None"

UI.IsMinimized = false
UI.PanelPosition = UDim2.new(0.72, -250, 0.48, -135)
UI.LastStatusText = nil
UI.LastStatusAt = 0
UI.LastRenderAt = 0

local UI_COLORS = {
    Background = Color3.fromRGB(15, 15, 20),
    Panel = Color3.fromRGB(15, 15, 20),
    Panel2 = Color3.fromRGB(22, 22, 28),
    Stroke = Color3.fromRGB(255, 170, 0),
    Red = Color3.fromRGB(255, 170, 0),
    RedSoft = Color3.fromRGB(255, 215, 0),
    Text = Color3.fromRGB(255, 255, 255),
    Muted = Color3.fromRGB(205, 205, 205),
    Success = Color3.fromRGB(65, 220, 125),
    Warning = Color3.fromRGB(255, 193, 64),
    Danger = Color3.fromRGB(245, 74, 95),
    Disabled = Color3.fromRGB(120, 126, 136),
}

local function UIAddCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end

local function UIAddStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or UI_COLORS.Stroke
    s.Thickness = thickness or 1.5
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function UIAddTextStroke(label, color, transparency)
    if not label then
        return nil
    end

    label.TextStrokeColor3 = color or Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = transparency or 0.75
    return label
end

local function UIAddPadding(parent, left, right, top, bottom)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or left or 0)
    p.PaddingTop = UDim.new(0, top or left or 0)
    p.PaddingBottom = UDim.new(0, bottom or top or left or 0)
    p.Parent = parent
    return p
end

function UI.FormatNumber(value)
    local n = tonumber(value) or 0
    local sign = n < 0 and "-" or ""
    n = math.abs(math.floor(n))
    local s = tostring(n)
    local formatted = s
    while true do
        local nextValue, count = formatted:gsub("^(%-?%d+)(%d%d%d)", "%1,%2")
        formatted = nextValue
        if count == 0 then
            break
        end
    end
    return sign .. formatted
end

function UI.GetDataValue(name, fallback)
    local data = LocalPlayer:FindFirstChild("Data")
    local obj = data and data:FindFirstChild(name)
    if obj then
        local value = obj.Value
        if value ~= nil and value ~= "" then
            return value
        end
    end
    return fallback
end

function UI.GetLevel()
    return UI.GetDataValue("Level", 1)
end

function UI.GetBeli()
    return UI.GetDataValue("Beli", 0)
end

function UI.GetFragments()
    return UI.GetDataValue("Fragments", 0)
end

function UI.GetRace()
    return tostring(UI.GetDataValue("Race", "Unknown"))
end

function UI.GetPoints()
    return UI.GetDataValue("Points", 0)
end

function UI.MakeDraggable(handle, target)
    if not handle or not target then
        return
    end

    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPosition = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = target.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput then
            return
        end

        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPosition.X.Scale or 0,
            (startPosition.X.Offset or 0) + delta.X,
            startPosition.Y.Scale or 0,
            (startPosition.Y.Offset or 0) + delta.Y
        )
    end)
end

function UI.GetSeaLabel()
    local sea = 1

    if MeleeSystem and type(MeleeSystem.GetSea) == "function" then
        local ok, value = pcall(MeleeSystem.GetSea)
        if ok and tonumber(value) then
            sea = tonumber(value)
        end
    end

    if sea >= 3 then
        return "Third Sea"
    elseif sea == 2 then
        return "Second Sea"
    end

    return "First Sea"
end

function UI.HasTool(toolName)
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")

    if char and char:FindFirstChild(toolName) then
        return true
    end

    if backpack and backpack:FindFirstChild(toolName) then
        return true
    end

    return false
end

-- Reads the already-cached Blox Fruits inventory without invoking a remote from
-- the UI refresh loop. AbilitySystem refreshes this cache independently.
function UI.HasInventoryItem(...)
    local wanted = {...}
    local inventory = AbilitySystem and AbilitySystem.Inventory or nil

    -- Equipped/backpack tools should turn green immediately even before the
    -- inventory cache has completed its first refresh.
    for _, name in ipairs(wanted) do
        if UI.HasTool(name) then
            return true
        end
    end

    if type(inventory) ~= "table" then
        return false
    end

    for _, name in ipairs(wanted) do
        if inventory[name] == true then
            return true
        end
    end

    -- Tolerate punctuation/capitalization differences returned by GetInventory.
    local normalizedWanted = {}
    for _, name in ipairs(wanted) do
        normalizedWanted[tostring(name):lower():gsub("[^%w]", "")] = true
    end

    for inventoryName, owned in pairs(inventory) do
        if owned == true then
            local normalized = tostring(inventoryName):lower():gsub("[^%w]", "")
            if normalizedWanted[normalized] then
                return true
            end
        end
    end

    return false
end

-- Pull Lever is progression rather than a physical inventory item. Keep this
-- lightweight and best-effort until the dedicated Race V4 automation is added.
function UI.HasPullLeverProgress()
    local possibleNames = {
        "PullLever",
        "PulledLever",
        "LeverPulled",
        "RaceV4Lever",
        "V4Lever",
    }

    local containers = {LocalPlayer, LocalPlayer:FindFirstChild("Data")}
    for _, container in ipairs(containers) do
        if container then
            for _, name in ipairs(possibleNames) do
                local attr = container:GetAttribute(name)
                if attr == true or tonumber(attr) == 1 then
                    return true
                end

                local valueObject = container:FindFirstChild(name)
                if valueObject and valueObject:IsA("ValueBase") then
                    local value = valueObject.Value
                    if value == true or tonumber(value) == 1 then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function UI.RefreshStats()
    if not UI.ScreenGui then
        return
    end

    local level = UI.GetLevel()
    local beli = UI.GetBeli()
    local fragments = UI.GetFragments()
    local race = UI.GetRace()

    if UI.StatLabels.Level then
        UI.StatLabels.Level.Text = UI.FormatNumber(level)
    end

    if UI.StatLabels.Sea then
        UI.StatLabels.Sea.Text = UI.GetSeaLabel()
    end

    if UI.StatLabels.Race then
        UI.StatLabels.Race.Text = race
    end

    if UI.StatLabels.Beli then
        UI.StatLabels.Beli.Text = "$" .. UI.FormatNumber(beli)
    end

    if UI.StatLabels.Fragments then
        UI.StatLabels.Fragments.Text = UI.FormatNumber(fragments)
    end
end

function UI.SetItemState(key, state, text)
    local item = UI.ItemStatus and UI.ItemStatus[key]

    if not item then
        return
    end

    local color = UI_COLORS.Disabled

    if state == "success" then
        color = UI_COLORS.Success
    elseif state == "warning" then
        color = UI_COLORS.Warning
    elseif state == "danger" then
        color = UI_COLORS.Danger
    end

    item.Dot.BackgroundColor3 = color

    if text then
        item.Label.Text = tostring(text)
    end

    item.Label.TextColor3 = UI_COLORS.Text
end

function UI.RefreshSpecialStatus()
    if not UI.ScreenGui then
        return
    end

    local level = tonumber(UI.GetLevel()) or 1

    -- DARK STEP / BLACK LEG
    local darkOwned = false
    local darkMastery = 0

    if MeleeSystem then
        if type(MeleeSystem.IsOwned) == "function" then
            pcall(function()
                darkOwned = MeleeSystem.IsOwned("Black Leg") == true
            end)
        end

        if type(MeleeSystem.GetMastery) == "function" then
            pcall(function()
                darkMastery = tonumber(MeleeSystem.GetMastery("Black Leg")) or 0
            end)
        end
    end

    if darkOwned then
        UI.SetItemState(
            "DarkStep",
            darkMastery >= 400 and "success" or "warning",
            "Dark Step " .. tostring(darkMastery) .. "/400"
        )
    else
        UI.SetItemState("DarkStep", "danger", "Dark Step")
    end

    -- SABER
    local hasSaber = SaberSystem and SaberSystem.Has == true

    if not hasSaber and SaberSystem and type(SaberSystem.HasTool) == "function" then
        pcall(function()
            hasSaber = SaberSystem.HasTool("Saber") == true
        end)
    end

    if hasSaber then
        UI.SetItemState("Saber", "success", "Saber")
    elseif SaberSystem and SaberSystem.Active then
        local rawStep = tostring(SaberSystem.CurrentStep or "Quest")
        local saberStepLabels = {
            PLATES = "Jungle Plates",
            LOAD_PLATES = "Loading Jungle Plates",
            GET_TORCH = "Getting Torch",
            EQUIP_TORCH = "Equipping Torch",
            BURN_DOOR = "Burning Desert Door",
            GET_CUP = "Getting Cup",
            EQUIP_CUP = "Equipping Cup",
            FILL_CUP = "Filling Cup",
            SICK_MAN = "Sick Man",
            CHECK_SICK_MAN = "Checking Sick Man",
            RICH_MAN = "Rich Man",
            MOB_LEADER = "Mob Leader",
            GET_RELIC = "Getting Relic",
            PLACE_RELIC = "Placing Relic",
            SABER_EXPERT = "Saber Expert",
            COMPLETED = "Completed",
        }

        UI.SetItemState(
            "Saber",
            "warning",
            "Saber • " .. tostring(saberStepLabels[rawStep] or rawStep)
        )
    else
        UI.SetItemState("Saber", "danger", "Saber")
    end

    -- POLE V1
    local hasPole = UI.HasTool("Pole (1st Form)")
        or UI.HasTool("Pole V1")
        or (PoleSystem and PoleSystem.Has == true)

    if hasPole then
        UI.SetItemState("Pole", "success", "Pole V1")
    elseif level >= 575 then
        UI.SetItemState("Pole", "warning", "Pole V1")
    else
        UI.SetItemState("Pole", "danger", "Pole V1")
    end

    -- END-GAME / FUTURE KAITUN CHECKLIST
    -- These stay visible from low level onward so the panel becomes a persistent
    -- account-progress checklist while later Sea 2 / Sea 3 automation is built.
    local hasGodhuman = UI.HasInventoryItem("Godhuman", "God Human")
    if not hasGodhuman and MeleeSystem and type(MeleeSystem.IsOwned) == "function" then
        pcall(function()
            hasGodhuman = MeleeSystem.IsOwned("Godhuman") == true
        end)
    end
    UI.SetItemState("GodHuman", hasGodhuman and "success" or "danger", "GodHuman")

    UI.SetItemState(
        "CDK",
        UI.HasInventoryItem("Cursed Dual Katana", "CursedDualKatana") and "success" or "danger",
        "Cursed Dual Katana"
    )

    UI.SetItemState(
        "ValkyrieHelm",
        UI.HasInventoryItem("Valkyrie Helm", "ValkyrieHelm") and "success" or "danger",
        "Valkyrie Helm"
    )

    UI.SetItemState(
        "SoulGuitar",
        UI.HasInventoryItem("Soul Guitar", "SoulGuitar") and "success" or "danger",
        "Soul Guitar"
    )

    UI.SetItemState(
        "MirrorFractal",
        UI.HasInventoryItem("Mirror Fractal", "MirrorFractal") and "success" or "danger",
        "Mirror Fractal"
    )

    UI.SetItemState(
        "PullLever",
        UI.HasPullLeverProgress() and "success" or "danger",
        "Pull Lever"
    )

    -- SABER QUEST ITEMS
    UI.SetItemState(
        "Torch",
        UI.HasTool("Torch") and "success"
            or ((SaberSystem and SaberSystem.ProgressFlags
                and SaberSystem.ProgressFlags.TorchCollected) and "warning" or "danger"),
        "Torch"
    )

    UI.SetItemState(
        "Cup",
        UI.HasTool("Cup") and "success"
            or ((SaberSystem and SaberSystem.ProgressFlags
                and SaberSystem.ProgressFlags.CupCollected) and "warning" or "danger"),
        "Cup"
    )

    UI.SetItemState(
        "Relic",
        UI.HasTool("Relic") and "success" or "danger",
        "Relic"
    )
end

function UI.Truncate(value, maxLen)
    local s = tostring(value or "-")
    local limit = tonumber(maxLen) or 72

    if #s <= limit then
        return s
    end

    return string.sub(s, 1, math.max(1, limit - 3)) .. "..."
end

function UI.PrettyWords(textValue)
    local text = tostring(textValue or "-")

    local replacements = {
        ["GET_TORCH"] = "Get Torch",
        ["CHECK_TORCH"] = "Check Torch",
        ["EQUIP_TORCH"] = "Equip Torch",
        ["BURN_DOOR"] = "Burn Door",
        ["GET_CUP"] = "Get Cup",
        ["CHECK_SICK_MAN"] = "Check Saber Progress",
        ["EQUIP_CUP"] = "Equip Cup",
        ["FILL_CUP"] = "Fill Cup",
        ["GET_WATER"] = "Get Water",
        ["OFF • Kaitun paused"] = "Kaitun Paused",
        ["going to Cup water #1"] = "Moving to water drop",
        ["Going to Cup water point #1"] = "Moving to water drop",
        ["Filling Cup at point #1"] = "Trying to fill cup",
        ["Cup did not fill at point #1"] = "Water drop did not trigger",
        ["Switching to water point #1"] = "Switching to water drop",
        ["Checking Torch inventory"] = "Checking torch progress",
        ["Cup obtained"] = "Cup collected",
        ["Cup filled"] = "Cup filled",
    }

    if replacements[text] then
        return replacements[text]
    end

    text = text:gsub("_", " ")
    text = text:gsub("%s+", " ")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")

    text = string.lower(text)
    text = text:gsub("(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. string.lower(rest)
    end)

    return text
end

function UI.GetStatusFarmText()
    if not UI.KaitunEnabled or not FarmEngine.Running then
        return "Kaitun Paused"
    end

    if SaberSystem
        and SaberSystem.Active
        and not SaberSystem.Has then

        local step = tostring(SaberSystem.CurrentStep or "WAITING")
        local saberActions = {
            ["WAIT_MAP"] = "Auto Quest Get Saber",
            ["LOAD_PLATES"] = "Auto Quest Get Saber",
            ["PLATES"] = "Auto Quest Get Saber",
            ["GET_TORCH"] = "Auto Quest Get Saber",
            ["CHECK_TORCH"] = "Auto Quest Get Saber",
            ["EQUIP_TORCH"] = "Auto Quest Get Saber",
            ["BURN_DOOR"] = "Auto Quest Get Saber",
            ["GET_CUP"] = "Auto Quest Get Saber",
            ["CHECK_SICK_MAN"] = "Auto Quest Get Saber",
            ["EQUIP_CUP"] = "Auto Quest Get Saber",
            ["FILL_CUP"] = "Auto Quest Get Saber",
            ["SICK_MAN"] = "Auto Quest Get Saber",
            ["MOB_LEADER"] = "Killing Boss Mob Leader",
            ["PLACE_RELIC"] = "Auto Quest Get Saber",
            ["SABER_EXPERT"] = "Killing Boss Saber Expert",
        }

        return saberActions[step] or "Auto Quest Get Saber"
    end

    local activity = tostring(FarmEngine.Activity or "Idle")
    local lower = string.lower(activity)
    local quest = QuestSystem.Current
    local mob = quest and tostring(quest.Mob or "Mob") or "Mob"

    if string.find(lower, "recovering hp", 1, true) then
        return activity
    end

    if string.find(lower, "farming 1 mob", 1, true) then
        if quest and quest.Boss then
            return "Killing Boss " .. mob
        end

        return "Killing Mob " .. mob
    end

    if string.find(lower, "going to npc", 1, true)
        or string.find(lower, "finding quest giver", 1, true) then
        return "Going Quest NPC " .. mob
    end

    if string.find(lower, "accepting quest", 1, true)
        or string.find(lower, "quest started", 1, true)
        or string.find(lower, "quest active", 1, true) then
        return "Getting Quest " .. mob
    end

    if string.find(lower, "flying to spawn", 1, true)
        or string.find(lower, "searching spawn", 1, true)
        or string.find(lower, "scouting", 1, true)
        or string.find(lower, "searching for", 1, true) then
        return "Going To Mob " .. mob
    end

    if string.find(lower, "waiting for", 1, true)
        and string.find(lower, "spawn", 1, true) then

        if quest and quest.Boss then
            return "Waiting Boss " .. mob
        end

        return "Waiting Mob " .. mob
    end

    if string.find(lower, "spawned - going to fight", 1, true) then
        return "Going To Boss " .. mob
    end

    if string.find(lower, "patrolling for", 1, true) then
        return "Searching Boss " .. mob
    end

    if string.find(lower, "fighting style", 1, true)
        or string.find(lower, "dark step", 1, true) then
        return "Getting Fighting Style"
    end

    if string.find(lower, "anti-water", 1, true) then
        return "Returning To Farm"
    end

    if activity == "Idle" or activity == "Starting" then
        return quest and ("Preparing Mob " .. mob) or "Preparing Farm Level"
    end

    return UI.PrettyWords(activity)
end

function UI.GetStatusItemText()
    if FruitSystem.RandomStatus and tick() < (FruitSystem.RandomStatusUntil or 0) then
        return "Random Fruit | " .. tostring(FruitSystem.RandomStatus)
    end
    local targetMastery = tonumber(Config.FightingStyleMasteryTarget) or 400
    local darkPrice = tonumber(Config.BlackLegPrice) or 150000
    local beli = tonumber(UI.GetBeli()) or 0

    local darkOwned = false
    local darkMastery = 0

    if MeleeSystem then
        if type(MeleeSystem.IsOwned) == "function" then
            pcall(function()
                darkOwned = MeleeSystem.IsOwned("Black Leg") == true
                    or MeleeSystem.IsOwned("Dark Step") == true
            end)
        end

        if type(MeleeSystem.GetMastery) == "function" then
            pcall(function()
                darkMastery = tonumber(MeleeSystem.GetMastery("Black Leg"))
                    or tonumber(MeleeSystem.GetMastery("Dark Step"))
                    or 0
            end)
        end
    end

    if not darkOwned then
        if beli < darkPrice then
            return "Farm Beli "
                .. UI.FormatNumber(beli)
                .. " / "
                .. UI.FormatNumber(darkPrice)
                .. " Buy Dark Step"
        end

        return "Buying Dark Step"
    end

    if darkMastery < targetMastery then
        return "Farm Mastery Melee "
            .. tostring(darkMastery)
            .. " / "
            .. tostring(targetMastery)
            .. " ( Dark Step )"
    end

    -- After Dark Step is finished, show the current fighting-style goal.
    if MeleeSystem and MeleeSystem.ActiveStyleName then
        local styleName = tostring(MeleeSystem.ActiveStyleName)
        local mastery = 0

        if type(MeleeSystem.GetMastery) == "function" then
            pcall(function()
                mastery = tonumber(MeleeSystem.GetMastery(styleName)) or 0
            end)
        end

        if mastery < targetMastery then
            return "Farm Mastery Melee "
                .. tostring(mastery)
                .. " / "
                .. tostring(targetMastery)
                .. " ( "
                .. styleName
                .. " )"
        end
    end

    if SaberSystem and SaberSystem.Active and not SaberSystem.Has then
        return "Auto Quest Get Saber"
    end

    if SaberSystem and SaberSystem.Has then
        return "Saber Acquired"
    end

    return "Fighting Style Ready"
end


function UI.TrimText(value)
    local text = tostring(value or "")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

function UI.ExtractBossTimer(value)
    local text = tostring(value or "")

    local timer = string.match(text, "%[(%d%d?:%d%d)%]")
        or string.match(text, "(%d%d?:%d%d)")

    if timer then
        local minutes, seconds = string.match(timer, "^(%d+):(%d%d)$")

        if minutes and seconds then
            local sec = tonumber(seconds)

            if sec and sec >= 0 and sec <= 59 then
                return timer
            end
        end
    end

    return nil
end

function UI.CleanBossTimerName(value, timer)
    local text = tostring(value or "")

    if timer and timer ~= "" then
        text = text:gsub("%[" .. timer:gsub(":", "%%:") .. "%]", "")
        text = text:gsub(timer:gsub(":", "%%:"), "")
    end

    text = text:gsub("[|•%-]+$", "")
    text = UI.TrimText(text)

    if text == "" then
        return nil
    end

    -- Ignore common timer-only/status words.
    local lower = string.lower(text)

    if lower == "boss"
        or lower == "spawn"
        or lower == "respawn"
        or lower == "timer"
        or lower == "time"
        or lower == "boss timer" then
        return nil
    end

    return text
end

function UI.GetGuiWorldPosition(gui)
    if not gui then
        return nil
    end

    local adornee = nil

    pcall(function()
        adornee = gui.Adornee
    end)

    if adornee and adornee:IsA("BasePart") then
        return adornee.Position
    elseif adornee and adornee:IsA("Model") then
        local cf = adornee:GetPivot()
        return cf.Position
    end

    local parent = gui.Parent

    if parent and parent:IsA("BasePart") then
        return parent.Position
    elseif parent and parent:IsA("Model") then
        local ok, cf = pcall(function()
            return parent:GetPivot()
        end)

        if ok and cf then
            return cf.Position
        end
    end

    return nil
end

function UI.IsLikelyBossName(value)
    local textValue = UI.TrimText(value)

    if textValue == "" or UI.ExtractBossTimer(textValue) then
        return false
    end

    local lower = string.lower(textValue)

    -- Common non-boss texts that must never qualify a random countdown.
    local blocked = {
        ["quest"] = true,
        ["mission"] = true,
        ["menu"] = true,
        ["spawn"] = true,
        ["respawn"] = true,
        ["timer"] = true,
        ["time"] = true,
        ["boss timer"] = true,
        ["first sea"] = true,
        ["second sea"] = true,
        ["third sea"] = true,
        ["desert"] = true,
        ["jungle"] = true,
        ["pirate village"] = true,
        ["frozen village"] = true,
        ["marine fortress"] = true,
        ["skylands"] = true,
    }

    if blocked[lower] then
        return false
    end

    -- Known / common Blox Fruits boss names.
    local exactBosses = {
        ["chef"] = true,
        ["the gorilla king"] = true,
        ["gorilla king"] = true,
        ["bobby"] = true,
        ["yeti"] = true,
        ["mob leader"] = true,
        ["vice admiral"] = true,
        ["warden"] = true,
        ["chief warden"] = true,
        ["swan"] = true,
        ["magma admiral"] = true,
        ["fishman lord"] = true,
        ["wysper"] = true,
        ["thunder god"] = true,
        ["cyborg"] = true,
        ["saber expert"] = true,
        ["greybeard"] = true,
        ["ice admiral"] = true,
        ["diamond"] = true,
        ["jeremy"] = true,
        ["fajita"] = true,
        ["don swan"] = true,
        ["smoke admiral"] = true,
        ["cursed captain"] = true,
        ["darkbeard"] = true,
        ["order"] = true,
        ["awakened ice admiral"] = true,
        ["tide keeper"] = true,
        ["stone"] = true,
        ["island empress"] = true,
        ["captain elephant"] = true,
        ["beautiful pirate"] = true,
        ["longma"] = true,
        ["cake queen"] = true,
        ["soul reaper"] = true,
        ["rip_indra"] = true,
        ["rip indra"] = true,
        ["cake prince"] = true,
        ["dough king"] = true,
    }

    if exactBosses[lower] then
        return true
    end

    -- Strong boss-role words. These are deliberately stricter than accepting
    -- any nearby text label such as "Desert Bandit".
    local bossWords = {
        " boss",
        "boss ",
        "chef",
        "chief",
        "warden",
        "admiral",
        " king",
        "king ",
        " queen",
        "queen ",
        " lord",
        "lord ",
        "leader",
        "commander",
        "empress",
        "emperor",
        "reaper",
        "god",
        "captain",
        "expert",
        "tyrant",
    }

    for _, token in ipairs(bossWords) do
        if string.find(lower, token, 1, true) then
            return true
        end
    end

    return false
end

function UI.GuiHasBossMarker(gui)
    local current = gui

    for _ = 1, 6 do
        if not current then
            break
        end

        local objectName = string.lower(tostring(current.Name or ""))

        if string.find(objectName, "boss", 1, true)
            or string.find(objectName, "chef", 1, true) then
            return true
        end

        local marked = false

        pcall(function()
            if current:GetAttribute("IsBoss") == true
                or current:GetAttribute("Boss") == true
                or current:GetAttribute("BossTimer") == true
                or current:GetAttribute("BossName") ~= nil then
                marked = true
            end
        end)

        if marked then
            return true
        end

        current = current.Parent
    end

    return false
end

UI.WorldTimerGuiCache = UI.WorldTimerGuiCache or setmetatable({}, {__mode = "k"})
UI.WorldTimerGuiCacheReady = UI.WorldTimerGuiCacheReady or false
UI.WorldTimerGuiConnection = UI.WorldTimerGuiConnection or nil

function UI.GetWorldTimerGuis()
    if not UI.WorldTimerGuiCacheReady then
        for _, instance in ipairs(workspace:GetDescendants()) do
            if instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then
                UI.WorldTimerGuiCache[instance] = true
            end
        end

        UI.WorldTimerGuiCacheReady = true

        UI.WorldTimerGuiConnection = workspace.DescendantAdded:Connect(function(instance)
            if instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then
                UI.WorldTimerGuiCache[instance] = true
            end
        end)
    end

    local result = {}
    for gui in pairs(UI.WorldTimerGuiCache) do
        if gui and gui.Parent then
            result[#result + 1] = gui
        else
            UI.WorldTimerGuiCache[gui] = nil
        end
    end

    return result
end

function UI.ScanBossTimers(force)
    local now = tick()
    local interval = tonumber(Config.BossTimerScanInterval) or 0.75

    if not force
        and (now - (UI.BossTimerLastScan or 0)) < interval then
        return
    end

    UI.BossTimerLastScan = now

    local hrp = Utils.HRP()
    local playerPosition = hrp and hrp.Position or nil
    local maxDistance = tonumber(Config.BossTimerMaxDistance) or 3500

    local bestName = nil
    local bestTimer = nil
    local bestDistance = math.huge

    local function inspectGui(gui)
        -- Only world-attached timers are valid. A random PlayerGui countdown
        -- must never become a Boss Timer.
        local worldPosition = UI.GetGuiWorldPosition(gui)

        if not worldPosition then
            return
        end

        local distance = 0

        if playerPosition then
            distance = (playerPosition - worldPosition).Magnitude

            if distance > maxDistance then
                return
            end
        end

        local timer = nil
        local inlineName = nil
        local allTexts = {}

        for _, desc in ipairs(gui:GetDescendants()) do
            if desc:IsA("TextLabel")
                or desc:IsA("TextButton")
                or desc:IsA("TextBox") then

                local raw = UI.TrimText(desc.Text)

                if raw ~= "" then
                    table.insert(allTexts, raw)
                end

                local foundTimer = UI.ExtractBossTimer(raw)

                if foundTimer and not timer then
                    timer = foundTimer
                    inlineName = UI.CleanBossTimerName(raw, foundTimer)
                end
            end
        end

        if not timer then
            return
        end

        local bossMarked = UI.GuiHasBossMarker(gui)
        local name = nil

        if inlineName and UI.IsLikelyBossName(inlineName) then
            name = inlineName
        end

        -- The boss title can be a separate label above the timer.
        if not name then
            for _, raw in ipairs(allTexts) do
                if not UI.ExtractBossTimer(raw)
                    and UI.IsLikelyBossName(raw) then
                    name = raw
                    break
                end
            end
        end

        -- Strict rule: a naked [06:16] is NOT a boss timer.
        -- It needs either a valid boss title or an explicit boss marker.
        if not name and not bossMarked then
            return
        end

        if not name then
            -- A marked BossTimer object without a title can still be valid,
            -- but do not invent an island/mob name from unrelated labels.
            name = "Boss"
        end

        if distance < bestDistance then
            bestDistance = distance
            bestTimer = timer
            bestName = name
        end
    end

    -- New boss countdowns are attached to the world/map.
    -- PlayerGui fallback was intentionally removed to prevent false positives.
    for _, instance in ipairs(UI.GetWorldTimerGuis()) do
        inspectGui(instance)
    end

    if bestTimer then
        UI.BossTimerName = tostring(bestName or "Boss")
        UI.BossTimerValue = tostring(bestTimer)
        UI.BossTimerDistance = bestDistance ~= math.huge and bestDistance or 0
    else
        UI.BossTimerName = "-"
        UI.BossTimerValue = "--:--"
        UI.BossTimerDistance = 0
    end
end


function UI.NormalizeBossName(value)
    local textValue = string.lower(tostring(value or ""))
    textValue = textValue:gsub("%[lv%.?%s*[%d,]+%]", "")
    textValue = textValue:gsub("[^%w]", "")
    return textValue
end

function UI.TimerToSeconds(timer)
    local minutes, seconds = string.match(tostring(timer or ""), "^(%d+):(%d%d)$")

    if not minutes or not seconds then
        return nil
    end

    return (tonumber(minutes) or 0) * 60 + (tonumber(seconds) or 0)
end

function UI.FindBossTimerForName(bossName, force)
    local normalizedWanted = UI.NormalizeBossName(bossName)

    if normalizedWanted == "" then
        return nil, nil
    end

    local now = tick()
    local interval = tonumber(Config.BossTimerScanInterval) or 0.75
    local cached = UI.NamedBossTimerCache[normalizedWanted]

    if not force
        and cached
        and (now - (cached.At or 0)) < interval then
        return cached.Timer, cached.Seconds
    end

    local foundTimer = nil
    local foundSeconds = nil
    local bestDistance = math.huge

    local hrp = Utils.HRP()
    local playerPosition = hrp and hrp.Position or nil
    local maxDistance = tonumber(Config.BossTimerMaxDistance) or 3500

    local function guiMentionsBoss(gui)
        local matched = false

        for _, desc in ipairs(gui:GetDescendants()) do
            if desc:IsA("TextLabel")
                or desc:IsA("TextButton")
                or desc:IsA("TextBox") then

                local raw = tostring(desc.Text or "")
                local normalizedText = UI.NormalizeBossName(raw)

                if normalizedText ~= ""
                    and (
                        normalizedText == normalizedWanted
                        or string.find(normalizedText, normalizedWanted, 1, true)
                        or string.find(normalizedWanted, normalizedText, 1, true)
                    ) then
                    matched = true
                    break
                end
            end
        end

        if matched then
            return true
        end

        local current = gui

        for _ = 1, 6 do
            if not current then
                break
            end

            local normalizedObjectName = UI.NormalizeBossName(current.Name)

            if normalizedObjectName ~= ""
                and (
                    normalizedObjectName == normalizedWanted
                    or string.find(normalizedObjectName, normalizedWanted, 1, true)
                ) then
                return true
            end

            local attrName = nil
            pcall(function()
                attrName = current:GetAttribute("BossName")
            end)

            if attrName
                and UI.NormalizeBossName(attrName) == normalizedWanted then
                return true
            end

            current = current.Parent
        end

        return false
    end

    local function inspectGui(gui)
        if not guiMentionsBoss(gui) then
            return
        end

        local worldPosition = UI.GetGuiWorldPosition(gui)

        if not worldPosition then
            return
        end

        local distance = 0

        if playerPosition then
            distance = (playerPosition - worldPosition).Magnitude

            if distance > maxDistance then
                return
            end
        end

        local timer = nil

        for _, desc in ipairs(gui:GetDescendants()) do
            if desc:IsA("TextLabel")
                or desc:IsA("TextButton")
                or desc:IsA("TextBox") then

                timer = UI.ExtractBossTimer(desc.Text)

                if timer then
                    break
                end
            end
        end

        if not timer then
            return
        end

        if distance < bestDistance then
            bestDistance = distance
            foundTimer = timer
            foundSeconds = UI.TimerToSeconds(timer)
        end
    end

    for _, instance in ipairs(UI.GetWorldTimerGuis()) do
        inspectGui(instance)
    end

    UI.NamedBossTimerCache[normalizedWanted] = {
        Timer = foundTimer,
        Seconds = foundSeconds,
        At = now,
    }

    return foundTimer, foundSeconds
end

function UI.GetPendingBossTimerStatus()
    if not QuestSystem
        or not QuestSystem.PendingBossName
        or not Config.BossFallbackStatusTimer then
        return nil
    end

    local timer = QuestSystem.PendingBossTimer

    if not timer then
        timer = UI.FindBossTimerForName(QuestSystem.PendingBossName, false)
    end

    if not timer then
        return nil
    end

    return tostring(QuestSystem.PendingBossName)
        .. " ["
        .. tostring(timer)
        .. "]"
end

function UI.LoadRemoteBrandAsset()
    if UI.BrandAsset then
        return UI.BrandAsset
    end

    if UI.BrandLoading then
        return nil
    end

    UI.BrandLoading = true

    local env = getgenv()
    local requestFn = env.request
        or env.http_request
        or (env.syn and env.syn.request)

    local writeFile = env.writefile
    local isFile = env.isfile
    local getAsset = env.getcustomasset or env.getsynasset

    if type(writeFile) ~= "function"
        or type(getAsset) ~= "function" then
        UI.BrandLoading = false
        return nil
    end

    local fileName = tostring(Config.HubImageFile or "kratoshub_NSD4_EEcy.png")
    local hasFile = false

    if type(isFile) == "function" then
        pcall(function()
            hasFile = isFile(fileName) == true
        end)
    end

    if not hasFile then
        local body = nil

        if type(requestFn) == "function" then
            local ok, response = pcall(function()
                return requestFn({
                    Url = tostring(Config.HubImageURL),
                    Method = "GET",
                })
            end)

            if ok and type(response) == "table" then
                body = response.Body or response.body
            end
        end

        if not body then
            pcall(function()
                body = game:HttpGet(tostring(Config.HubImageURL))
            end)
        end

        if type(body) == "string" and #body > 128 then
            pcall(function()
                writeFile(fileName, body)
            end)
        end
    end

    local asset = nil

    pcall(function()
        asset = getAsset(fileName)
    end)

    if asset then
        UI.BrandAsset = asset
    end

    UI.BrandLoading = false
    return UI.BrandAsset
end

function UI.ApplyRemoteBrandImage()
    if UI.BrandAsset then
        for _, imageObject in ipairs(UI.BrandTargets or {}) do
            if imageObject and imageObject.Parent then
                imageObject.Image = UI.BrandAsset
                imageObject.Visible = true
            end
        end
        return
    end

    task.spawn(function()
        local asset = UI.LoadRemoteBrandAsset()

        if not asset then
            return
        end

        for _, imageObject in ipairs(UI.BrandTargets or {}) do
            if imageObject and imageObject.Parent then
                imageObject.Image = asset
                imageObject.Visible = true
            end
        end
    end)
end

function UI.GetPositionStatus()
    local hrp = Utils.HRP()

    if not hrp then
        return "X -- | Y -- | Z --"
    end

    local p = hrp.Position

    return string.format(
        "X %.1f | Y %.1f | Z %.1f",
        p.X,
        p.Y,
        p.Z
    )
end

function UI.GetBossTimerStatus()
    UI.ScanBossTimers(false)

    if UI.BossTimerValue == "--:--" then
        return "Boss Timer: --"
    end

    return tostring(UI.BossTimerName)
        .. "  ["
        .. tostring(UI.BossTimerValue)
        .. "]"
end


function UI.EscapeRichText(value)
    local textValue = tostring(value or "")
    textValue = textValue:gsub("&", "&amp;")
    textValue = textValue:gsub("<", "&lt;")
    textValue = textValue:gsub(">", "&gt;")
    return textValue
end

function UI.GetCompactBossTimer()
    UI.ScanBossTimers(false)

    if UI.BossTimerValue == "--:--" then
        return nil
    end

    return tostring(UI.BossTimerName or "Boss")
        .. " ["
        .. tostring(UI.BossTimerValue)
        .. "]"
end

function UI.RenderStatus()
    local now = tick()

    if UI.LastRenderAt and (now - UI.LastRenderAt) < 0.08 then
        return
    end

    UI.LastRenderAt = now

    local farmText = UI.GetStatusFarmText()
    local itemText = UI.GetStatusItemText()
    local bossTimer = UI.GetCompactBossTimer()
    local pendingBossTimer = UI.GetPendingBossTimerStatus()

    if pendingBossTimer
        and (string.find(string.lower(farmText), "boss", 1, true) == nil) then
        farmText = farmText .. "  •  " .. pendingBossTimer
    elseif bossTimer
        and (string.find(string.lower(farmText), "boss", 1, true) ~= nil) then
        farmText = farmText .. "  •  " .. bossTimer
    end

    if UI.TopFarmLabel then
        UI.TopFarmLabel.Text =
            '<font color="#FFD700"><b>Status Farm :</b></font> '
            .. '<font color="#FFD700"><b>'
            .. UI.EscapeRichText(UI.Truncate(farmText, 88))
            .. '</b></font>'
    end

    if UI.TopItemLabel then
        UI.TopItemLabel.Text =
            '<font color="#FFD700"><b>Status Item :</b></font> '
            .. '<font color="#FFD700"><b>'
            .. UI.EscapeRichText(UI.Truncate(itemText, 92))
            .. '</b></font>'
    end

    -- Compatibility field is intentionally not allowed to overwrite
    -- the RichText labels created above.
    if UI.StatusLabel
        and UI.StatusLabel ~= UI.TopFarmLabel
        and UI.StatusLabel ~= UI.TopItemLabel then
        UI.StatusLabel.Text = farmText
    end
end

function UI.SetStatus(text, force)
    local newText = tostring(text or "Idle")
    local now = tick()

    -- Do not let independent background systems alternate the status label
    -- every farm tick. A message stays visible briefly unless explicitly forced.
    if UI.LastStatusText ~= newText
        and not force
        and (now - (UI.LastStatusAt or 0)) < (tonumber(Config.StatusMinHold) or 0.30) then
        return
    end

    if UI.LastStatusText == newText
        and (now - (UI.LastStatusAt or 0)) < (tonumber(Config.StatusUpdateInterval) or 0.12) then
        return
    end

    UI.LastStatusText = newText
    UI.LastStatusAt = now
    FarmEngine.Activity = newText
    UI.RenderStatus()
end

function UI.RefreshPowerButton()
    if not UI.PowerBubble then
        return
    end

    local enabled = UI.KaitunEnabled == true and FarmEngine.Running == true

    UI.PowerBubble.Text = enabled and "ON" or "OFF"
    UI.PowerBubble.BackgroundColor3 = enabled
        and Color3.fromRGB(42, 150, 83)
        or Color3.fromRGB(150, 47, 58)

    local stroke = UI.PowerBubble:FindFirstChildOfClass("UIStroke")

    if stroke then
        stroke.Color = enabled and UI_COLORS.Success or UI_COLORS.Danger
    end
end

function UI.SetKaitunEnabled(enabled)
    enabled = enabled == true
    UI.KaitunEnabled = enabled
    Config.AutoFarm = enabled

    if enabled then
        -- Resume from the avatar's current real position, not from a stale
        -- Prison approach/tween cached before the pause.
        QuestSystem.GiverApproachCache = {}
        QuestSystem.GiverCache = {}
        QuestSystem.ActiveQuestCheckAt = 0
        QuestSystem.AcceptedGraceUntil = 0
        QuestSystem.LastAcceptedQuestKey = nil
        QuestSystem.PrisonWaitingSince = 0
        QuestSystem.LastPrisonInteractAt = 0

        if FarmEngine and type(FarmEngine.Start) == "function" then
            FarmEngine.Start()
        end

        UI.SetStatus("Kaitun ON | resuming automation", true)
    else
        if FarmEngine and type(FarmEngine.Stop) == "function" then
            FarmEngine.Stop()
        end

        QuestSystem.PrisonWaitingSince = 0
        QuestSystem.LastPrisonInteractAt = 0

        pcall(function()
            Utils.RestoreLocalMovement()
        end)

        UI.SetStatus("Kaitun OFF | automation paused", true)
    end

    UI.RefreshPowerButton()
    UI.RenderStatus()
end


function UI.Build()
    local parent = (gethui and gethui())
        or LocalPlayer:WaitForChild("PlayerGui")

    local old = parent:FindFirstChild("KratosUltimateHub")
    if old then
        old:Destroy()
    end

    local oldBlur = Lighting:FindFirstChild("KratosVeltrixBlur")
        or Lighting:FindFirstChild("VeltrixBlur")

    if oldBlur then
        oldBlur:Destroy()
    end

    UI.StatLabels = {}
    UI.SpecialStatus = {}
    UI.ItemStatus = {}

    -- =========================================================
    -- Blur from the supplied base.
    -- =========================================================
    local blurEffect = Instance.new("BlurEffect")
    blurEffect.Name = "KratosVeltrixBlur"
    blurEffect.Size = 18
    blurEffect.Enabled = true
    blurEffect.Parent = Lighting
    UI.BlurEffect = blurEffect

    -- =========================================================
    -- Main ScreenGui with maximum practical priority.
    -- =========================================================
    local gui = Instance.new("ScreenGui")
    gui.Name = "KratosUltimateHub"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = false
    gui.Parent = parent
    gui.Enabled = Config.HideUI ~= true
    UI.ScreenGui = gui

    local statusOnlyMode = (Config.HideUI == false)
    local isOpen = not statusOnlyMode

    -- =========================================================
    -- Floating controls. Each bubble is an independent object.
    -- Moving the logo never moves ON/OFF, and vice-versa.
    -- =========================================================
    UI.ControlHolder = nil

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 58, 0, 58)
    toggleButton.Position = UDim2.new(0, 20, 0.5, -68)
    toggleButton.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    toggleButton.Text = "⚡"
    toggleButton.TextColor3 = Color3.fromRGB(255, 215, 0)
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = 25
    toggleButton.AutoButtonColor = false
    toggleButton.BorderSizePixel = 0
    toggleButton.Active = true
    toggleButton.ZIndex = 101
    toggleButton.Parent = gui
    UIAddTextStroke(toggleButton, Color3.fromRGB(255, 255, 255), 0.78)
    UI.ToggleButton = toggleButton
    UIAddCorner(toggleButton, 58)
    UIAddStroke(toggleButton, Color3.fromRGB(255, 170, 0), 2, 0)

    local toggleBrand = Instance.new("ImageLabel")
    toggleBrand.Name = "BrandImage"
    toggleBrand.Size = UDim2.new(1, -8, 1, -8)
    toggleBrand.Position = UDim2.new(0, 4, 0, 4)
    toggleBrand.BackgroundTransparency = 1
    toggleBrand.Image = ""
    toggleBrand.ScaleType = Enum.ScaleType.Fit
    toggleBrand.Visible = false
    toggleBrand.ZIndex = 103
    toggleBrand.Parent = toggleButton
    table.insert(UI.BrandTargets, toggleBrand)

    local powerBubble = Instance.new("TextButton")
    powerBubble.Name = "PowerBubble"
    powerBubble.Size = UDim2.new(0, 50, 0, 50)
    powerBubble.Position = UDim2.new(0, 24, 0.5, 8)
    powerBubble.BackgroundColor3 = Color3.fromRGB(42, 150, 83)
    powerBubble.Text = "ON"
    powerBubble.TextColor3 = Color3.fromRGB(255, 255, 255)
    powerBubble.Font = Enum.Font.GothamBold
    powerBubble.TextSize = 11
    powerBubble.AutoButtonColor = false
    powerBubble.BorderSizePixel = 0
    powerBubble.Active = true
    powerBubble.ZIndex = 101
    powerBubble.Parent = gui
    UIAddTextStroke(powerBubble, Color3.fromRGB(255, 255, 255), 0.78)
    UI.PowerBubble = powerBubble
    UIAddCorner(powerBubble, 50)
    UIAddStroke(powerBubble, UI_COLORS.Success, 2, 0)

    -- =========================================================
    -- Fixed Farm Status panel.
    -- =========================================================
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "FarmStatusFrame"
    statusFrame.Size = UDim2.new(0, 500, 0, 68)
    statusFrame.Position = UDim2.new(0.5, -250, 0, 0)
    statusFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    statusFrame.BackgroundTransparency = 0.30
    statusFrame.BorderColor3 = Color3.fromRGB(255, 170, 0)
    statusFrame.BorderSizePixel = 2
    statusFrame.ZIndex = 50
    statusFrame.Parent = gui
    UI.TopStatusPanel = statusFrame
    UIAddCorner(statusFrame, 5)
    UIAddStroke(statusFrame, Color3.fromRGB(255, 255, 255), 2, 0.15)

    local discordLabel = Instance.new("TextLabel")
    discordLabel.Name = "DiscordLink"
    discordLabel.Size = UDim2.new(0, 210, 0, 14)
    discordLabel.Position = UDim2.new(1, -218, 0, 3)
    discordLabel.BackgroundTransparency = 1
    discordLabel.Text = "discord.gg/7FsYJgR4qT"
    discordLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    discordLabel.Font = Enum.Font.GothamSemibold
    discordLabel.TextSize = 10
    discordLabel.TextXAlignment = Enum.TextXAlignment.Right
    discordLabel.TextYAlignment = Enum.TextYAlignment.Center
    discordLabel.ZIndex = 52
    discordLabel.Parent = statusFrame
    UIAddTextStroke(discordLabel, Color3.fromRGB(0, 0, 0), 0.60)

    UI.TopFarmLabel = Instance.new("TextLabel")
    UI.TopFarmLabel.Name = "FarmLine"
    UI.TopFarmLabel.Size = UDim2.new(1, -16, 0, 25)
    UI.TopFarmLabel.Position = UDim2.new(0, 8, 0, 18)
    UI.TopFarmLabel.BackgroundTransparency = 1
    UI.TopFarmLabel.RichText = true
    UI.TopFarmLabel.Text =
        '<font color="#FFD700"><b>Status Farm :</b></font> '
        .. '<font color="#FFD700"><b>Preparing Farm Level</b></font>'
    UI.TopFarmLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    UI.TopFarmLabel.Font = Enum.Font.GothamSemibold
    UI.TopFarmLabel.TextSize = 12
    UI.TopFarmLabel.TextXAlignment = Enum.TextXAlignment.Center
    UI.TopFarmLabel.TextYAlignment = Enum.TextYAlignment.Center
    UI.TopFarmLabel.ZIndex = 51
    UI.TopFarmLabel.Parent = statusFrame
    UIAddTextStroke(UI.TopFarmLabel, Color3.fromRGB(255, 255, 255), 0.72)

    UI.TopItemLabel = Instance.new("TextLabel")
    UI.TopItemLabel.Name = "ItemLine"
    UI.TopItemLabel.Size = UDim2.new(1, -16, 0, 23)
    UI.TopItemLabel.Position = UDim2.new(0, 8, 0, 42)
    UI.TopItemLabel.BackgroundTransparency = 1
    UI.TopItemLabel.RichText = true
    UI.TopItemLabel.Text =
        '<font color="#FFD700"><b>Status Item :</b></font> '
        .. '<font color="#FFD700"><b>Checking item goal...</b></font>'
    UI.TopItemLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    UI.TopItemLabel.Font = Enum.Font.GothamSemibold
    UI.TopItemLabel.TextSize = 12
    UI.TopItemLabel.TextXAlignment = Enum.TextXAlignment.Center
    UI.TopItemLabel.TextYAlignment = Enum.TextYAlignment.Center
    UI.TopItemLabel.ZIndex = 51
    UI.TopItemLabel.Parent = statusFrame
    UIAddTextStroke(UI.TopItemLabel, Color3.fromRGB(255, 255, 255), 0.72)

    -- =========================================================
    -- KRATOS Stats Checker - supplied main-panel proportions.
    -- =========================================================
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "KratosStatsChecker"
    mainFrame.Size = UDim2.new(0, 500, 0, 340)
    -- Slightly higher default position so the stats panel stays closer to the top.
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -145)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    mainFrame.BackgroundTransparency = 0.30
    mainFrame.BorderColor3 = Color3.fromRGB(255, 170, 0)
    mainFrame.BorderSizePixel = 2
    mainFrame.Active = true
    mainFrame.ZIndex = 20
    mainFrame.Parent = gui
    UI.Panel = mainFrame
    UIAddCorner(mainFrame, 5)
    UIAddStroke(mainFrame, Color3.fromRGB(255, 255, 255), 2, 0.12)

    if statusOnlyMode then
        toggleButton.Visible = false
        powerBubble.Visible = false
        mainFrame.Visible = false
        if UI.BlurEffect and UI.BlurEffect.Parent then
            UI.BlurEffect.Enabled = false
        end
    end

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "KRATOS STATS CHECKER"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.ZIndex = 21
    title.Parent = mainFrame
    UIAddTextStroke(title, Color3.fromRGB(255, 255, 255), 0.72)

    local separatorTitle = Instance.new("Frame")
    separatorTitle.Size = UDim2.new(0.84, 0, 0, 1)
    separatorTitle.Position = UDim2.new(0.08, 0, 0, 40)
    separatorTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    separatorTitle.BorderSizePixel = 0
    separatorTitle.ZIndex = 21
    separatorTitle.Parent = mainFrame

    local statsTitle = Instance.new("TextLabel")
    statsTitle.Size = UDim2.new(1, -40, 0, 30)
    statsTitle.Position = UDim2.new(0, 20, 0, 50)
    statsTitle.BackgroundTransparency = 1
    statsTitle.Text = "Account Stats"
    statsTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    statsTitle.Font = Enum.Font.GothamBold
    statsTitle.TextSize = 14
    statsTitle.TextXAlignment = Enum.TextXAlignment.Left
    statsTitle.ZIndex = 21
    statsTitle.Parent = mainFrame
    UIAddTextStroke(statsTitle, Color3.fromRGB(255, 255, 255), 0.72)

    -- =========================================================
    -- Live Account Stats
    -- Two-column layout: core account info on the left and
    -- currencies on the right. This uses the empty space better.
    -- =========================================================
    local statsHolder = Instance.new("Frame")
    statsHolder.Name = "AccountStats"
    statsHolder.Size = UDim2.new(1, -40, 0, 126)
    statsHolder.Position = UDim2.new(0, 20, 0, 82)
    statsHolder.BackgroundTransparency = 1
    statsHolder.ZIndex = 21
    statsHolder.Parent = mainFrame

    local leftStats = Instance.new("Frame")
    leftStats.Name = "LeftStats"
    leftStats.Size = UDim2.new(0.46, 0, 1, 0)
    leftStats.Position = UDim2.new(0, 0, 0, 0)
    leftStats.BackgroundTransparency = 1
    leftStats.ZIndex = 22
    leftStats.Parent = statsHolder

    local rightStats = Instance.new("Frame")
    rightStats.Name = "RightStats"
    rightStats.Size = UDim2.new(0.42, 0, 1, 0)
    rightStats.Position = UDim2.new(0.58, 0, 0, 0)
    rightStats.BackgroundTransparency = 1
    rightStats.ZIndex = 22
    rightStats.Parent = statsHolder

    local statsDivider = Instance.new("Frame")
    statsDivider.Name = "StatsDivider"
    statsDivider.Size = UDim2.new(0, 1, 0, 102)
    statsDivider.Position = UDim2.new(0.53, 0, 0, 4)
    statsDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    statsDivider.BackgroundTransparency = 0.58
    statsDivider.BorderSizePixel = 0
    statsDivider.ZIndex = 22
    statsDivider.Parent = statsHolder

    local function addColumnLayout(parent)
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 3)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = parent
        return layout
    end

    addColumnLayout(leftStats)
    addColumnLayout(rightStats)

    local function createStatRow(parent, key, labelText, order)
        local row = Instance.new("Frame")
        row.Name = key
        row.Size = UDim2.new(1, 0, 0, 22)
        row.BackgroundTransparency = 1
        row.LayoutOrder = order
        row.ZIndex = 22
        row.Parent = parent

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0, 82, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = labelText .. ":"
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.Font = Enum.Font.GothamSemibold
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.ZIndex = 23
        nameLabel.Parent = row
        UIAddTextStroke(nameLabel, Color3.fromRGB(255, 255, 255), 0.82)

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(1, -86, 1, 0)
        valueLabel.Position = UDim2.new(0, 86, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = "-"
        valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        valueLabel.Font = Enum.Font.GothamSemibold
        valueLabel.TextSize = 12
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
        valueLabel.ZIndex = 23
        valueLabel.Parent = row
        UIAddTextStroke(valueLabel, Color3.fromRGB(255, 255, 255), 0.82)

        UI.StatLabels[key] = valueLabel
    end

    createStatRow(leftStats, "Level", "Level", 1)
    createStatRow(leftStats, "Sea", "Sea", 2)
    createStatRow(leftStats, "Race", "Race", 3)
    createStatRow(rightStats, "Beli", "Beli", 1)
    createStatRow(rightStats, "Fragments", "Frag", 2)

    local separatorItems = Instance.new("Frame")
    separatorItems.Size = UDim2.new(0.90, 0, 0, 1)
    separatorItems.Position = UDim2.new(0.05, 0, 0, 214)
    separatorItems.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    separatorItems.BackgroundTransparency = 0.12
    separatorItems.BorderSizePixel = 0
    separatorItems.ZIndex = 21
    separatorItems.Parent = mainFrame

    local itemsTitle = Instance.new("TextLabel")
    itemsTitle.Size = UDim2.new(1, -40, 0, 28)
    itemsTitle.Position = UDim2.new(0, 20, 0, 220)
    itemsTitle.BackgroundTransparency = 1
    itemsTitle.Text = "Account Items"
    itemsTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    itemsTitle.Font = Enum.Font.GothamBold
    itemsTitle.TextSize = 14
    itemsTitle.TextXAlignment = Enum.TextXAlignment.Left
    itemsTitle.ZIndex = 21
    itemsTitle.Parent = mainFrame
    UIAddTextStroke(itemsTitle, Color3.fromRGB(255, 255, 255), 0.72)

    -- =========================================================
    -- Account Items / future Kaitun progression checklist.
    -- Compact 3-column layout inspired by the supplied Banana checker.
    -- =========================================================
    local itemsHolder = Instance.new("Frame")
    itemsHolder.Name = "AccountItems"
    itemsHolder.Size = UDim2.new(1, -40, 0, 82)
    itemsHolder.Position = UDim2.new(0, 20, 0, 250)
    itemsHolder.BackgroundTransparency = 1
    itemsHolder.ZIndex = 21
    itemsHolder.Parent = mainFrame

    local itemLayout = Instance.new("UIGridLayout")
    itemLayout.CellSize = UDim2.new(0, 145, 0, 22)
    itemLayout.CellPadding = UDim2.new(0, 8, 0, 5)
    itemLayout.FillDirection = Enum.FillDirection.Horizontal
    itemLayout.FillDirectionMaxCells = 3
    itemLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
    itemLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    itemLayout.Parent = itemsHolder

    local function createItemRow(key, labelText, order)
        local row = Instance.new("Frame")
        row.Name = key
        row.Size = UDim2.new(0, 145, 0, 22)
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.LayoutOrder = order
        row.ZIndex = 22
        row.Parent = itemsHolder

        local dot = Instance.new("Frame")
        dot.Name = "Dot"
        dot.Size = UDim2.new(0, 10, 0, 10)
        dot.Position = UDim2.new(0, 2, 0.5, -5)
        dot.BackgroundColor3 = UI_COLORS.Danger
        dot.BorderSizePixel = 0
        dot.ZIndex = 23
        dot.Parent = row
        UIAddCorner(dot, 10)

        local label = Instance.new("TextLabel")
        label.Name = "ItemLabel"
        label.Size = UDim2.new(1, -20, 1, 0)
        label.Position = UDim2.new(0, 18, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(225, 225, 225)
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.ZIndex = 23
        label.Parent = row
        UIAddTextStroke(label, Color3.fromRGB(255, 255, 255), 0.84)

        UI.ItemStatus[key] = {
            Dot = dot,
            Label = label,
        }
    end

    createItemRow("Saber", "Saber", 1)
    createItemRow("Pole", "Pole V1", 2)
    createItemRow("GodHuman", "GodHuman", 3)
    createItemRow("CDK", "Cursed Dual Katana", 4)
    createItemRow("ValkyrieHelm", "Valkyrie Helm", 5)
    createItemRow("SoulGuitar", "Soul Guitar", 6)
    createItemRow("MirrorFractal", "Mirror Fractal", 7)
    createItemRow("PullLever", "Pull Lever", 8)

    -- The old KRATOS/Discord/control footer was intentionally removed.
    -- Do not alias StatusLabel to TopFarmLabel; it would overwrite RichText.
    UI.StatusLabel = nil
    UI.ActivityLabel = nil

    -- =========================================================
    -- Main-panel drag, exactly in the spirit of the supplied base.
    -- =========================================================
    local mainDragging = false
    local mainDragStart = nil
    local mainStartPos = nil

    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            mainDragging = true
            mainDragStart = input.Position
            mainStartPos = mainFrame.Position
        end
    end)

    mainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            mainDragging = false
        end
    end)

    -- =========================================================
    -- Independent floating-bubble drag/click handling.
    -- Each bubble stores its own start position and drag state.
    -- =========================================================
    local dragThreshold = 6

    local function toggleMenu()
        if statusOnlyMode then
            return
        end

        isOpen = not isOpen
        mainFrame.Visible = isOpen

        if UI.BlurEffect and UI.BlurEffect.Parent then
            UI.BlurEffect.Enabled = isOpen
        end
    end

    local function bindIndependentBubble(button, clickCallback)
        local dragging = false
        local dragged = false
        local dragStart = nil
        local startPos = nil
        local trackedInput = nil

        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragged = false
                dragStart = input.Position
                startPos = button.Position
                trackedInput = input
            end
        end)

        button.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                if dragging then
                    dragging = false
                    trackedInput = nil
                    if not dragged and type(clickCallback) == "function" then
                        clickCallback()
                    end
                end
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if not dragging or not dragStart or not startPos then
                return
            end

            if input.UserInputType ~= Enum.UserInputType.MouseMovement
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            -- Mouse movement is global; touch should follow the active finger.
            if trackedInput
                and trackedInput.UserInputType == Enum.UserInputType.Touch
                and input ~= trackedInput then
                return
            end

            local delta = input.Position - dragStart
            if delta.Magnitude > dragThreshold then
                dragged = true
            end

            button.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end)
    end

    bindIndependentBubble(toggleButton, toggleMenu)
    bindIndependentBubble(powerBubble, function()
        UI.SetKaitunEnabled(not UI.KaitunEnabled)
    end)

    UI.RefreshStats()
    UI.RefreshSpecialStatus()
    -- Defer the first world boss-timer scan; a forced workspace-wide scan during
    -- UI construction can cause a visible startup hitch on large servers.
    UI.BossTimerLastScan = tick()
    UI.RenderStatus()
    UI.RefreshPowerButton()
    UI.ApplyRemoteBrandImage()

    task.spawn(function()
        while task.wait(tonumber(Config.UIRefreshInterval) or 0.50) do
            if not UI.ScreenGui or not UI.ScreenGui.Parent then
                break
            end

            UI.RefreshStats()
            UI.RefreshSpecialStatus()
            UI.RenderStatus()
            UI.RefreshPowerButton()
        end
    end)
end

--=====================================================================================
-- [6] UTILS
--=====================================================================================

function Utils.Character()
    return LocalPlayer.Character
end

function Utils.HRP()
    local char = Utils.Character()
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

function Utils.Humanoid()
    local char = Utils.Character()
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

function Utils.Level()
    return UI.GetLevel()
end

function Utils.Normalize(name)
    name = tostring(name or "")
    name = name:gsub("%b[]", "")
    name = name:gsub("^The%s+", "")
    name = name:gsub("^the%s+", "")
    name = name:gsub("%s+", " ")
    name = name:gsub("^%s+", "")
    name = name:gsub("%s+$", "")
    return name:lower()
end

function Utils.GetEquippedWeapon()
    local char = Utils.Character()
    if not char then
        return "None"
    end

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            return tool.Name
        end
    end

    return "None"
end

function Utils.EnsureCombatTool()
    local now = tick()
    if Utils.LastEquipCheck and (now - Utils.LastEquipCheck) < (tonumber(Config.EquipCheckInterval) or 1.25) then
        return Utils.LastEquippedWeapon or "None"
    end

    Utils.LastEquipCheck = now
    if Config.AutoFarm and tostring(Config.FarmWeaponType) == "Melee" then
        local melee = Utils.EnsureMeleeEquipped(true)
        if melee then
            return melee
        end
    end

    local equipped = Utils.GetEquippedWeapon()
    if equipped ~= "None" then
        Utils.LastEquippedWeapon = equipped
        return equipped
    end

    local equippedByType = Utils.EquipByType("Melee")
        or Utils.EquipByType("Blox Fruit")
        or Utils.EquipByType("Sword")
        or Utils.EquipByType("Gun")

    Utils.LastEquippedWeapon = equippedByType or "None"
    return Utils.LastEquippedWeapon
end

function Utils.EnsureMeleeEquipped(force)
    local char = Utils.Character()
    local hum = Utils.Humanoid()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char or not hum then
        return nil
    end

    -- The mastery controller selects the exact style that should receive XP.
    local preferred = MeleeSystem and MeleeSystem.ActiveStyleName or nil
    if preferred then
        local preferredTool = nil

        if MeleeSystem and type(MeleeSystem.GetTool) == "function" then
            preferredTool = MeleeSystem.GetTool(preferred)
        else
            preferredTool = char:FindFirstChild(preferred)
                or (backpack and backpack:FindFirstChild(preferred))
        end

        if preferredTool and preferredTool:IsA("Tool") then
            -- Critical performance/combat fix: do not call EquipTool every attack
            -- tick when the mastery style is already equipped. Re-equipping the
            -- same Tool repeatedly can reset the combat controller and create
            -- visible client stutter while preventing FastAttack from landing.
            if preferredTool.Parent ~= char then
                local now = tick()
                if not Utils.LastMeleeEquipAt
                    or (now - Utils.LastMeleeEquipAt) >= (tonumber(Config.TargetEquipRetry) or 0.20) then
                    Utils.LastMeleeEquipAt = now
                    pcall(function()
                        hum:EquipTool(preferredTool)
                    end)
                end
            end

            Utils.LastEquippedWeapon = preferredTool.Name
            return preferredTool.Name
        end
    end

    -- Fallback: any melee style.
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == "Melee" then
            Utils.LastEquippedWeapon = tool.Name
            Utils.LastMeleeEquipAt = tick()
            return tool.Name
        end
    end

    local now = tick()
    if not force
        and Utils.LastMeleeEquipAt
        and (now - Utils.LastMeleeEquipAt) < (tonumber(Config.TargetEquipRetry) or 0.20) then
        return nil
    end
    Utils.LastMeleeEquipAt = now

    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.ToolTip == "Melee" then
                pcall(function()
                    hum:EquipTool(tool)
                end)

                -- Confirm it actually moved into Character.
                local equipped = char:FindFirstChild(tool.Name)
                if equipped and equipped:IsA("Tool") then
                    Utils.LastEquippedWeapon = tool.Name
                    return tool.Name
                end

                -- Some executors/game states apply EquipTool one frame later.
                task.defer(function()
                    local liveChar = Utils.Character()
                    local liveHum = Utils.Humanoid()
                    local liveBackpack = LocalPlayer:FindFirstChild("Backpack")
                    if liveChar and liveHum and liveBackpack then
                        local retry = liveBackpack:FindFirstChild(tool.Name)
                        if retry and retry:IsA("Tool") then
                            pcall(function()
                                liveHum:EquipTool(retry)
                            end)
                        end
                    end
                end)

                return tool.Name
            end
        end
    end

    return nil
end


function Utils.Equip(name)
    local char = Utils.Character()
    local hum = Utils.Humanoid()
    if not char or not hum then
        return false
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local tool = char:FindFirstChild(name) or (backpack and backpack:FindFirstChild(name))
    if not tool then
        return false
    end

    pcall(function()
        hum:EquipTool(tool)
    end)

    return true
end

function Utils.EquipByType(tooltip)
    local char = Utils.Character()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char then
        return nil
    end

    for _, container in ipairs({char, backpack}) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool.ToolTip == tooltip then
                    Utils.Equip(tool.Name)
                    return tool.Name
                end
            end
        end
    end

    return nil
end

function Utils.SendKey(key)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end)
end

function Utils.SetNoClip(state)
    local char = Utils.Character()
    if not char then
        return
    end

    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.CanCollide = not state
        end
    end
end

-- Fully releases movement created by Kratos. This is intentionally stronger
-- than Teleport.Cancel(): combat/Saber systems can own BodyPosition/BodyGyro
-- objects and some interactions temporarily set WalkSpeed/Jump to zero.
function Utils.RestoreLocalMovement()
    pcall(function()
        if Teleport then
            Teleport.ExclusiveOwner = nil
            if type(Teleport.Cancel) == "function" then
                Teleport.Cancel()
            end
        end
    end)

    pcall(function()
        if Combat and type(Combat.ReleaseHealthRetreat) == "function" then
            Combat.ReleaseHealthRetreat()
        end
        if Combat and type(Combat.ResetAnchor) == "function" then
            Combat.ResetAnchor()
        end
        if Combat then
            Combat.CurrentTarget = nil
        end
    end)

    pcall(function()
        if SaberSystem and type(SaberSystem.ReleaseGroundHold) == "function" then
            SaberSystem.ReleaseGroundHold()
        end
        if SaberSystem and type(SaberSystem.ReleaseCupLift) == "function" then
            SaberSystem.ReleaseCupLift()
        end
        if SaberSystem and type(SaberSystem.ReleaseSaberExpertHover) == "function" then
            SaberSystem.ReleaseSaberExpertHover()
        end
    end)

    local char = Utils.Character()
    local hrp = Utils.HRP()
    local hum = Utils.Humanoid()

    -- Last-resort cleanup for a mover recreated by a tick that was already in
    -- progress at the exact moment OFF was pressed. Only Kratos-owned movers
    -- are removed; native game constraints are left untouched.
    if hrp then
        for _, obj in ipairs(hrp:GetChildren()) do
            local kratosOwned = string.sub(tostring(obj.Name or ""), 1, 6) == "Kratos"
            local isMover = obj:IsA("BodyPosition")
                or obj:IsA("BodyGyro")
                or obj:IsA("BodyVelocity")
                or obj:IsA("BodyAngularVelocity")

            if kratosOwned and isMover then
                pcall(function() obj:Destroy() end)
            end
        end

        pcall(function()
            hrp.Anchored = false
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    if hum then
        pcall(function()
            hum.PlatformStand = false
            hum.Sit = false
            hum.AutoRotate = true

            -- Blox Fruits normally uses positive movement values. Only repair
            -- values that Kratos may have zeroed; do not overwrite buffs.
            if hum.WalkSpeed <= 0 then
                hum.WalkSpeed = 16
            end

            if hum.UseJumpPower then
                if hum.JumpPower <= 0 then
                    hum.JumpPower = 50
                end
            elseif hum.JumpHeight <= 0 then
                hum.JumpHeight = 7.2
            end

            hum.Jump = false
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end
end

function Utils.GetGround(position)
    if typeof(position) ~= "Vector3" then
        return nil
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    local filter = {}
    if LocalPlayer.Character then
        table.insert(filter, LocalPlayer.Character)
    end
    params.FilterDescendantsInstances = filter

    local hit = workspace:Raycast(
        position + Vector3.new(0, 100, 0),
        Vector3.new(0, -200, 0),
        params
    )

    if not hit then
        return nil
    end

    if hit.Material == Enum.Material.Water then
        return nil
    end

    return hit.Position
end

function Utils.IsGround(position)
    return Utils.GetGround(position) ~= nil
end

function Utils.IsAlive()
    local hum = Utils.Humanoid()
    return hum and hum.Parent and hum.Health > 0
end

function Utils.WaitAlive()
    local char = Utils.Character()

    if not char or not char.Parent then
        char = LocalPlayer.CharacterAdded:Wait()
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        hum = char:WaitForChild("Humanoid", 10)
    end

    if not hum then
        return false
    end

    if hum.Health <= 0 then
        local newChar = LocalPlayer.CharacterAdded:Wait()
        if not newChar then
            return false
        end

        hum = newChar:WaitForChild("Humanoid", 10)
        if not hum then
            return false
        end
    end

    return hum.Health > 0
end

function Utils.GetDistance(target)
    local hrp = Utils.HRP()
    if not hrp then
        return math.huge
    end

    local position
    if typeof(target) == "CFrame" then
        position = target.Position
    elseif typeof(target) == "Vector3" then
        position = target
    else
        return math.huge
    end

    return (hrp.Position - position).Magnitude
end

--=====================================================================================
-- [7] SAFETY SYSTEM
--=====================================================================================

SafetySystem.LastRescue = 0
SafetySystem.RescueCooldown = 0.8
SafetySystem.IgnoreUntil = 0
SafetySystem.LastTick = 0

function SafetySystem.GetRescueCFrame()
    local quest = QuestSystem.Current
    if quest and quest.FarmCFrame and quest.FarmCFrame.Position.Y >= 180 then
        return CFrame.new(quest.FarmCFrame.Position + Vector3.new(0, 8, 0))
    end
    if quest and quest.GiverCFrame and quest.GiverCFrame.Position.Y >= 180 then
        return CFrame.new(quest.GiverCFrame.Position + Vector3.new(0, 6, 0))
    end

    local hrp = Utils.HRP()
    if hrp then
        return CFrame.new(hrp.Position + Vector3.new(0, Config.WaterRecoveryHeight, 0))
    end

    return nil
end

function SafetySystem.IsInWaterRisk()
    if not Config.AntiWater then
        return false
    end

    if tick() < (SafetySystem.IgnoreUntil or 0) then
        return false
    end

    -- Never fight against the movement controller while the character is
    -- intentionally flying over water. This was one source of rubber-banding.
    if Teleport and Teleport.IsBusy and Teleport.IsBusy() then
        return false
    end

    local hrp = Utils.HRP()
    local hum = Utils.Humanoid()
    if not hrp or not hum or hum.Health <= 0 then
        return false
    end

    if hrp.Position.Y <= Config.WaterSafetyY and not Utils.IsGround(hrp.Position) then
        return true
    end

    local state = hum:GetState()
    if (state == Enum.HumanoidStateType.Swimming or state == Enum.HumanoidStateType.Freefall)
        and hrp.Position.Y <= (Config.WaterSafetyY + 2) then
        return true
    end

    return false
end

function SafetySystem.RescueFromWater()
    if not Config.AntiWater then
        return false
    end

    if tick() - SafetySystem.LastRescue < SafetySystem.RescueCooldown then
        return false
    end

    local rescueCF = SafetySystem.GetRescueCFrame()
    if not rescueCF then
        return false
    end

    local hrp = Utils.HRP()
    if not hrp then
        return false
    end

    SafetySystem.LastRescue = tick()
    Teleport.Cancel()

    pcall(function()
        hrp.CFrame = rescueCF
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        local hum = Utils.Humanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)

    UI.SetStatus("Anti-Water | rescued to safe ground")
    return true
end

function SafetySystem.Tick()
    if MeleeSystem and MeleeSystem.PurchaseMode then
        return false
    end

    local now = tick()
    local interval = tonumber(Config.SafetyCheckInterval) or 0.25

    if SafetySystem.LastTick and (now - SafetySystem.LastTick) < interval then
        return false
    end

    SafetySystem.LastTick = now

    if SafetySystem.IsInWaterRisk() then
        return SafetySystem.RescueFromWater()
    end

    return false
end

--=====================================================================================
-- [8] TELEPORT SYSTEM
--=====================================================================================

Teleport.Tween = nil
Teleport.Target = nil
Teleport.TravelCollisionState = nil
Teleport.BodyVelocity = nil
Teleport.Owner = nil
Teleport.ExclusiveOwner = nil
Teleport.MoveSerial = 0
Teleport.LastEntranceAt = 0
Teleport.EntrancePendingUntil = 0
Teleport.LastEntranceName = nil
-- Generic requestEntrance routes can occasionally be ignored by the server.
-- Track failures per route so a dead portal request can never freeze AutoFarm.
Teleport.EntranceRouteFailures = {}
Teleport.EntranceRouteDisabledUntil = {}
Teleport.OwnerPriority = {
    MELEE = 200,
    SABER = 180,
    SAFETY = 100,
    FRUIT = 95,
    BARTILO = 93,
    FRAGMENTS = 92,
    QUEST = 90,
    SKIP_FARM_LEVEL = 88,
    CHEST = 85,
    FARM = 80,
    BOSS = 75,
    COMBAT = 70,
    SPECIAL = 60,
    GENERIC = 10,
}

function Teleport.SetTravelCollision(state)
    if not Config.TravelNoClip then
        return
    end

    local char = Utils.Character()
    if not char then
        return
    end

    if state then
        if Teleport.TravelCollisionState then
            return
        end

        Teleport.TravelCollisionState = {}

        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BasePart") then
                Teleport.TravelCollisionState[obj] = obj.CanCollide
                obj.CanCollide = false
            end
        end
    else
        local saved = Teleport.TravelCollisionState
        Teleport.TravelCollisionState = nil

        if saved then
            for part, canCollide in pairs(saved) do
                if part and part.Parent then
                    pcall(function()
                        part.CanCollide = canCollide
                    end)
                end
            end
        end
    end
end

function Teleport.IsBusy()
    if Teleport.StepConnection then
        return true
    end
    local tween = Teleport.Tween
    if not tween then
        return false
    end

    local ok, state = pcall(function()
        return tween.PlaybackState
    end)

    return ok and state == Enum.PlaybackState.Playing
end

function Teleport.CleanupStabilizer()
    local bodyVelocity = Teleport.BodyVelocity
    Teleport.BodyVelocity = nil

    if bodyVelocity and bodyVelocity.Parent then
        pcall(function()
            bodyVelocity:Destroy()
        end)
    end
end

function Teleport.Cancel()
    Teleport.MoveSerial = (Teleport.MoveSerial or 0) + 1
    if Teleport.StepConnection then
        Teleport.StepConnection:Disconnect()
        Teleport.StepConnection = nil
    end

    if Teleport.Tween then
        pcall(function()
            Teleport.Tween:Cancel()
        end)
    end

    Teleport.Tween = nil
    Teleport.Target = nil
    Teleport.Owner = nil
    Teleport.CleanupStabilizer()
    Teleport.SetTravelCollision(false)
end


-- Emergency-only instant relocation (not used for normal island travel).
function Teleport.Snap(target)
    if typeof(target) ~= "CFrame" then
        return false
    end

    local hrp = Utils.HRP()
    local char = Utils.Character()
    if not hrp then
        return false
    end

    Teleport.Cancel()
    local dest = CFrame.new(target.Position + Vector3.new(0, 4, 0), target.Position)

    pcall(function()
        if char and char.PivotTo then
            char:PivotTo(dest)
        else
            hrp.CFrame = dest
        end
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.Anchored = true
    end)

    task.delay(0.40, function()
        local root = Utils.HRP()
        if root then
            pcall(function()
                root.Anchored = false
                root.AssemblyLinearVelocity = Vector3.zero
            end)
        end
    end)

    Teleport.SetTravelCollision(false)
    Teleport.Target = nil
    SafetySystem.IgnoreUntil = tick() + 2.0
    return true
end

function Teleport.GetOwnerPriority(owner)
    return Teleport.OwnerPriority[owner or "GENERIC"] or 0
end

-- Portal locations mirrored from the working reference hubs supplied by the user.
-- IMPORTANT (v18): Fishman Island is handled separately. Instead of repeatedly
-- calling requestEntrance from the middle of another island and blocking movement
-- when the server ignores the request, the Kaitun first travels to the REAL
-- surface portal, then asks Blox Fruits to enter Fishman Island. The reverse path
-- uses the real portal inside Fishman before returning to the surface.
Teleport.EntrancePoints = {
    [1] = {
        {Name = "Upper Skylands", Position = Vector3.new(-7894.62, 5545.4917, -380.2467)},
        {Name = "Skylands", Position = Vector3.new(-4607.8228, 872.5423, -1667.5569)},
    },
    [2] = {
        {Name = "Mansion", Position = Vector3.new(-288.4625, 306.1306, 597.9988)},
        {Name = "Flamingo Room", Position = Vector3.new(2284.912, 15.152, 905.4829)},
        {Name = "Cursed Ship", Position = Vector3.new(923.2125, 126.976, 32852.832)},
        {Name = "Zombie Island", Position = Vector3.new(-6508.558, 89.035, -132.8395)},
    },
    [3] = {
        {Name = "Castle On The Sea", Position = Vector3.new(-5058.775, 314.5155, -3155.8833)},
        {Name = "Hydra", Position = Vector3.new(5756.8374, 610.424, -253.9254)},
        {Name = "Mansion", Position = Vector3.new(-12463.874, 374.9145, -7523.774)},
        {Name = "Temple Of Time", Position = Vector3.new(28282.57, 14896.851, 105.1043)},
    },
}

-- Updated physical portal coordinates supplied from the current game build.
-- SurfacePortal: point the character actually approaches to ENTER Fishman.
-- InsidePortal : point the character approaches to EXIT Fishman.
-- RequestInside is the destination used by current/open-source Blox Fruits hubs
-- with CommF_:InvokeServer("requestEntrance", ...).
Teleport.FishmanPortal = {
    SurfacePortal = Vector3.new(4052.3, -4.0, -1814.5),
    InsidePortal = Vector3.new(61170.6, -4.0, 1954.9),
    RequestInside = Vector3.new(61163.8515625, 11.6796875, 1819.7841796875),
    RequestOutside = Vector3.new(4052.3, -4.0, -1814.5),
    RegionCenter = Vector3.new(61163.8515625, 11.6796875, 1819.7841796875),
    RegionRadius = 5000,
    ApproachDistance = 18,
    RequestCooldown = 0.90,
    SettleTime = 0.85,
}

Teleport.FishmanLastRequestAt = 0
Teleport.FishmanFailures = 0
Teleport.FishmanDirection = nil

function Teleport.GetCurrentSea()
    local id = game.PlaceId
    if id == 2753915549 or id == 85211729168715 then
        return 1
    elseif id == 4442272183 or id == 79091703265657 then
        return 2
    elseif id == 7449423635 or id == 100117331123089 then
        return 3
    end
    return nil
end

function Teleport.IsFishmanPosition(position)
    if typeof(position) ~= "Vector3" then
        return false
    end

    local portal = Teleport.FishmanPortal
    return (position - portal.RegionCenter).Magnitude <= portal.RegionRadius
end

function Teleport.FindUsefulEntrance(targetPosition, currentPosition)
    if not InternalTuning.Portal.Enabled then
        return nil
    end

    local directDistance = (targetPosition - currentPosition).Magnitude
    if directDistance < InternalTuning.Portal.MinDistance then
        return nil
    end

    local points = Teleport.EntrancePoints[Teleport.GetCurrentSea()]
    if type(points) ~= "table" then
        return nil
    end

    local best = nil
    local bestTargetDistance = math.huge

    for _, route in ipairs(points) do
        local targetDistance = (route.Position - targetPosition).Magnitude
        local eligible = true
        if Teleport.GetCurrentSea() == 1 then
            if route.Name == "Upper Skylands" then
                eligible = targetPosition.Y >= 4000
            elseif route.Name == "Skylands" then
                eligible = targetPosition.Y >= 600 and targetPosition.Y < 4000
            end
        end
        if eligible and targetDistance < bestTargetDistance then
            best = route
            bestTargetDistance = targetDistance
        end
    end

    if not best then
        return nil
    end

    local minSavings = InternalTuning.Portal.MinSavings
    if bestTargetDistance + minSavings >= directDistance then
        return nil
    end

    return best
end

function Teleport.IsEntranceArrivalConfirmed(route, position, beforePosition)
    if not route or typeof(position) ~= "Vector3" then
        return false
    end

    -- God's Guard -> Shanda is the important transition here. Upper Skylands
    -- is separated by the cloud/entrance layer, so do not merely trust that
    -- requestEntrance returned without error: verify that we actually arrived
    -- in the high-altitude region before letting AutoFarm continue.
    if route.Name == "Upper Skylands" then
        return position.Y >= InternalTuning.Portal.UpperSkyConfirmY
            or (position - route.Position).Magnitude <= InternalTuning.Portal.UpperSkyConfirmRadius
    end

    -- Lower Skylands also has a large coordinate jump. A meaningful movement
    -- is enough here; the normal local tween finishes the last leg.
    if route.Name == "Skylands" then
        return position.Y >= 600
            or (position - route.Position).Magnitude <= 1400
    end

    return beforePosition ~= nil
        and (position - beforePosition).Magnitude >= InternalTuning.Portal.ConfirmMoveDistance
end

-- Fishman-specific portal state machine.
-- Returning true means this function owns the current travel step and the caller
-- must NOT start the original 60k-coordinate tween yet.
function Teleport.TryFishmanPortal(targetPosition, currentPosition, speed, owner, forceRepath)
    if Teleport.GetCurrentSea() ~= 1 then
        return false
    end

    local targetInside = Teleport.IsFishmanPosition(targetPosition)
    local currentInside = Teleport.IsFishmanPosition(currentPosition)

    -- Already on the correct side of the portal; regular local tween can continue.
    if targetInside == currentInside then
        Teleport.FishmanDirection = nil
        Teleport.FishmanFailures = 0
        return false
    end

    local portal = Teleport.FishmanPortal
    local entering = targetInside and not currentInside
    local physicalPortal = entering and portal.SurfacePortal or portal.InsidePortal
    local requestDestination = entering and portal.RequestInside or portal.RequestOutside
    local physicalDistance = (currentPosition - physicalPortal).Magnitude
    local directionName = entering and "ENTER" or "EXIT"

    if Teleport.FishmanDirection ~= directionName then
        Teleport.FishmanDirection = directionName
        Teleport.FishmanFailures = 0
        Teleport.FishmanLastRequestAt = 0
    end

    -- First go to the actual portal. This is the critical v18 fix: if
    -- requestEntrance is ignored while the player is far away, the Kaitun no
    -- longer remains frozen with "Going To Spawn | Fishman Warrior".
    if physicalDistance > portal.ApproachDistance then
        local label = entering and "Fishman entrance" or "Fishman exit"
        UI.SetStatus(
            "Portal | going to " .. label .. " | "
                .. tostring(math.floor(physicalDistance)) .. " studs"
        )

        Teleport.To(
            CFrame.new(physicalPortal),
            speed or Config.FarmSpeed or Config.TweenSpeed,
            owner or "QUEST",
            forceRepath,
            true
        )
        return true
    end

    -- We are physically at the portal. Cancel the approach tween before asking
    -- the game's own entrance system to move us to the other side.
    local now = tick()
    if now < (Teleport.EntrancePendingUntil or 0) then
        return true
    end

    if now - (Teleport.FishmanLastRequestAt or 0) < portal.RequestCooldown then
        return true
    end

    local remote = CommF_ or GetCommF()
    if not remote then
        return false
    end

    Teleport.Cancel()

    local root = Utils.HRP()
    if root then
        pcall(function()
            -- Put the root exactly on the portal point. This also lets the normal
            -- portal/touch logic fire on executors where requestEntrance requires
            -- the player to actually be at the entrance.
            root.CFrame = CFrame.new(physicalPortal)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    local beforeInside = currentInside
    local ok = pcall(function()
        remote:InvokeServer("requestEntrance", requestDestination)
    end)

    if not ok then
        Teleport.FishmanFailures = (Teleport.FishmanFailures or 0) + 1
        return true
    end

    Teleport.FishmanLastRequestAt = now
    Teleport.EntrancePendingUntil = now + portal.SettleTime
    SafetySystem.IgnoreUntil = math.max(
        SafetySystem.IgnoreUntil or 0,
        Teleport.EntrancePendingUntil + 0.75
    )

    UI.SetStatus(entering and "Portal | entering Fishman Island" or "Portal | leaving Fishman Island")

    -- Do not trust pcall alone: the remote can return without actually moving the
    -- player. Verify the side changed; if not, clear the pending state so the next
    -- farm tick retries while still standing on the real portal.
    task.delay(portal.SettleTime + 0.10, function()
        local liveRoot = Utils.HRP()
        if not liveRoot then
            return
        end

        local afterInside = Teleport.IsFishmanPosition(liveRoot.Position)
        local success = afterInside ~= beforeInside

        if success then
            Teleport.FishmanFailures = 0
            Teleport.FishmanDirection = nil
            Teleport.EntrancePendingUntil = 0
        else
            Teleport.FishmanFailures = (Teleport.FishmanFailures or 0) + 1
            Teleport.EntrancePendingUntil = 0

            -- On repeated failure, nudge across the physical portal point before
            -- trying the remote again. This prevents an endless idle loop caused
            -- by standing a few studs outside the trigger volume.
            if Teleport.FishmanFailures >= 2 then
                local retryRoot = Utils.HRP()
                if retryRoot then
                    pcall(function()
                        retryRoot.CFrame = CFrame.new(physicalPortal + Vector3.new(0, -2, 0))
                        retryRoot.AssemblyLinearVelocity = Vector3.zero
                    end)
                end
                Teleport.FishmanLastRequestAt = 0
            end
        end
    end)

    return true
end

function Teleport.TryEntranceRoute(targetPosition, currentPosition, speed, owner, forceRepath)
    if not InternalTuning.Portal.Enabled then
        return false
    end

    -- Fishman uses the physical entrance/exit state machine above.
    if Teleport.TryFishmanPortal(targetPosition, currentPosition, speed, owner, forceRepath) then
        return true
    end

    local now = tick()

    -- Give requestEntrance a short window to replicate the new position before
    -- any subsystem starts another long-distance tween.
    if now < (Teleport.EntrancePendingUntil or 0) then
        return true
    end

    local route = Teleport.FindUsefulEntrance(targetPosition, currentPosition)
    if not route then
        return false
    end

    local routeKey = tostring(Teleport.GetCurrentSea() or 0) .. ":" .. tostring(route.Name)
    local disabledUntil = (Teleport.EntranceRouteDisabledUntil and Teleport.EntranceRouteDisabledUntil[routeKey]) or 0

    -- If this entrance was just ignored repeatedly, do NOT keep ownership of
    -- movement. Returning false lets Teleport.To perform the normal flight and
    -- guarantees that AutoFarm continues instead of remaining ON/idle.
    if now < disabledUntil then
        return false
    end

    local cooldown = InternalTuning.Portal.Cooldown
    if now - (Teleport.LastEntranceAt or 0) < cooldown then
        return false
    end

    local remote = CommF_ or GetCommF()
    if not remote then
        return false
    end

    Teleport.Cancel()

    local root = Utils.HRP()
    local beforePosition = root and root.Position or currentPosition
    if root then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    local ok = pcall(function()
        remote:InvokeServer("requestEntrance", route.Position)
    end)

    if not ok then
        local failures = ((Teleport.EntranceRouteFailures and Teleport.EntranceRouteFailures[routeKey]) or 0) + 1
        Teleport.EntranceRouteFailures[routeKey] = failures
        Teleport.EntrancePendingUntil = 0
        Teleport.LastEntranceAt = 0

        if failures >= 2 then
            Teleport.EntranceRouteDisabledUntil[routeKey] = tick() + InternalTuning.Portal.FailureBackoff
            UI.SetStatus("Portal failed | fallback travel to " .. tostring(route.Name))
        end

        -- pcall itself failed, so it is safe to fall through to normal movement
        -- immediately rather than consuming this AutoFarm tick.
        return false
    end

    Teleport.LastEntranceAt = now
    Teleport.LastEntranceName = route.Name
    Teleport.EntrancePendingUntil = now + InternalTuning.Portal.SettleTime
    SafetySystem.IgnoreUntil = math.max(
        SafetySystem.IgnoreUntil or 0,
        Teleport.EntrancePendingUntil + 0.75
    )

    UI.SetStatus("Portal | entering " .. tostring(route.Name))

    -- Generic portal requests are also verified now. If the server ignored the
    -- request, release the movement block instead of leaving the farm ON/idle.
    task.delay(InternalTuning.Portal.SettleTime + 0.10, function()
        local liveRoot = Utils.HRP()
        if not liveRoot then
            return
        end

        local confirmed = Teleport.IsEntranceArrivalConfirmed(route, liveRoot.Position, beforePosition)

        if not confirmed then
            Teleport.EntrancePendingUntil = 0
            Teleport.LastEntranceAt = 0

            local failures = ((Teleport.EntranceRouteFailures and Teleport.EntranceRouteFailures[routeKey]) or 0) + 1
            Teleport.EntranceRouteFailures[routeKey] = failures

            -- Never freeze on the cloud/portal transition. If Upper Skylands
            -- ignores the request twice, temporarily release portal ownership
            -- so normal no-clip flight can continue and AutoFarm stays alive.
            if failures >= 2 then
                Teleport.EntranceRouteDisabledUntil[routeKey] = tick() + InternalTuning.Portal.FailureBackoff
                UI.SetStatus("Portal unavailable | fallback route to " .. tostring(route.Name))
            end
        else
            -- Confirmed teleport: clear any old failure/backoff state.
            Teleport.EntranceRouteFailures[routeKey] = 0
            Teleport.EntranceRouteDisabledUntil[routeKey] = nil
            Teleport.EntrancePendingUntil = 0
        end
    end)

    return true
end

-- Fallback motor: bounded steps at the configured speed, independent of
-- TweenService and requestEntrance. Stop/session/priority rules still apply.
function Teleport.StartDirectTravel(target, speed, owner)
    if not AutomationMovementAllowed() or typeof(target) ~= "CFrame" then
        return nil
    end
    owner = tostring(owner or "FARM")
    if Teleport.ExclusiveOwner and Teleport.ExclusiveOwner ~= owner then
        Teleport.LastBlockReason = "owner " .. tostring(Teleport.ExclusiveOwner)
        return nil
    end
    if Teleport.IsBusy() and Teleport.GetOwnerPriority(owner) < Teleport.GetOwnerPriority(Teleport.Owner) then
        Teleport.LastBlockReason = "travel owner " .. tostring(Teleport.Owner)
        return nil
    end
    Teleport.Cancel()
    local root = Utils.HRP()
    if not root then
        Teleport.LastBlockReason = "character/root missing"
        return nil
    end
    Teleport.Owner = owner
    Teleport.Target = target
    Teleport.LastBlockReason = nil
    Teleport.SetTravelCollision(true)
    Combat.StopAboveHead()
    local serial = Teleport.MoveSerial
    local travelSpeed = math.max(1, tonumber(speed) or tonumber(Config.TweenSpeed) or 190)
    Teleport.StepConnection = RunService.Heartbeat:Connect(function(dt)
        if serial ~= Teleport.MoveSerial then
            return
        end
        local live = Utils.HRP()
        if not AutomationMovementAllowed() or not IsCurrentSession() or live ~= root then
            Teleport.Cancel()
            return
        end
        if Teleport.ExclusiveOwner and Teleport.ExclusiveOwner ~= owner then
            Teleport.Cancel()
            return
        end
        local distance = (target.Position - live.Position).Magnitude
        local ok, err = pcall(function()
            live.Anchored = false
            live.AssemblyLinearVelocity = Vector3.zero
            live.AssemblyAngularVelocity = Vector3.zero
            if distance <= 3.5 then
                live.CFrame = target
            else
                live.CFrame = live.CFrame:Lerp(target, math.min(1, travelSpeed * math.min(dt, 0.25) / distance))
            end
        end)
        if not ok then
            Teleport.Cancel()
            Teleport.LastBlockReason = tostring(err)
            UI.SetStatus("Movement error | " .. tostring(err))
        elseif distance <= 3.5 then
            Teleport.Cancel()
        end
    end)
    return Teleport.StepConnection
end

function Teleport.To(target, speed, owner, forceRepath, skipEntranceRoute)
    Teleport.LastBlockReason = nil
    if not AutomationMovementAllowed() then
        Teleport.LastBlockReason = "farm paused"
        return nil
    end

    if not Config.FlightTweenEnabled or typeof(target) ~= "CFrame" then
        Teleport.LastBlockReason = not Config.FlightTweenEnabled and "Flight Tween disabled" or "invalid destination"
        return nil
    end

    local hrp = Utils.HRP()
    local char = Utils.Character()
    if not hrp or not char then
        Teleport.LastBlockReason = "character/root missing"
        return nil
    end

    owner = tostring(owner or "GENERIC")

    if Teleport.ExclusiveOwner and owner ~= Teleport.ExclusiveOwner then
        Teleport.LastBlockReason = "owner " .. tostring(Teleport.ExclusiveOwner)
        return Teleport.Tween
    end

    local targetPosition = target.Position
    local currentPosition = hrp.Position
    local dist = (targetPosition - currentPosition).Magnitude

    if dist <= 3.5 then
        return nil
    end

    -- Before committing to a long flight, ask the game to use the nearest
    -- useful entrance. This is what prevents Fishman Island from becoming a
    -- 3000+ stud ocean flight: requestEntrance places us inside the underwater
    -- area and the regular tween only finishes the short local leg.
    if not skipEntranceRoute and Teleport.TryEntranceRoute(targetPosition, currentPosition, speed, owner, forceRepath) then
        if Teleport.IsBusy() then
            return Teleport.Tween or Teleport.StepConnection
        end
        local remaining = (Teleport.EntrancePendingUntil or 0) - tick()
        if remaining > 0 and remaining <= 3 then
            Teleport.LastBlockReason = "portal replication (" .. tostring(math.ceil(remaining)) .. "s)"
            return nil
        end
        -- A consumed request with no active movement must not leave the farm idle.
        Teleport.EntrancePendingUntil = 0
    end

    -- One movement owner at a time. A low-priority helper (for example
    -- auto-melee) cannot redirect a QUEST flight halfway across the ocean.
    if Teleport.IsBusy() then
        local currentOwner = Teleport.Owner or "GENERIC"

        if Teleport.Target then
            local targetDelta = (Teleport.Target.Position - target.Position).Magnitude
            -- Reuse a live tween owned by the same subsystem when the destination
            -- only moved a little. Previously forceRepath=true restarted the tween
            -- every farm tick, which could leave the avatar visually parked while
            -- the status kept saying it was farming.
            if currentOwner == owner
                and targetDelta <= (tonumber(Config.TravelRepathDistance) or 35) then
                return Teleport.Tween or Teleport.StepConnection
            end
        end

        if Teleport.GetOwnerPriority(owner) < Teleport.GetOwnerPriority(currentOwner) then
            Teleport.LastBlockReason = "travel owner " .. tostring(currentOwner)
            return Teleport.Tween
        end

        Teleport.Cancel()
    end

    Teleport.MoveSerial = (Teleport.MoveSerial or 0) + 1
    local serial = Teleport.MoveSerial
    Teleport.Owner = owner
    Teleport.Target = target

    Teleport.SetTravelCollision(true)

    pcall(function()
        hrp.Anchored = false
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)

    -- Same stabilization principle used by the supplied working base.
    -- It prevents the server/physics controller from pulling the character
    -- back toward the previous island while a long tween is in progress.
    Teleport.CleanupStabilizer()

    local stabilizer = Instance.new("BodyVelocity")
    stabilizer.Name = "KratosFlightStabilizer"
    stabilizer.MaxForce = Vector3.new(4000, 4000, 4000)
    stabilizer.Velocity = Vector3.zero
    stabilizer.Parent = hrp
    Teleport.BodyVelocity = stabilizer

    local tweenSpeed = math.max(
        tonumber(speed) or tonumber(Config.TweenSpeed) or 300,
        1
    )

    local duration = math.max(
        dist / tweenSpeed,
        tonumber(Config.TravelMinDuration) or 0.10
    )

    -- Do not let AntiWater interfere with a valid long-distance flight.
    SafetySystem.IgnoreUntil = math.max(
        SafetySystem.IgnoreUntil or 0,
        tick() + duration + 1.0
    )

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {CFrame = target}
    )

    Teleport.Tween = tween

    tween.Completed:Connect(function(state)
        if serial ~= Teleport.MoveSerial or Teleport.Tween ~= tween then
            return
        end

        Teleport.Tween = nil
        Teleport.Target = nil
        Teleport.Owner = nil
        Teleport.CleanupStabilizer()
        Teleport.SetTravelCollision(false)

        if state == Enum.PlaybackState.Completed then
            local liveRoot = Utils.HRP()
            if liveRoot then
                pcall(function()
                    liveRoot.AssemblyLinearVelocity = Vector3.zero
                    liveRoot.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end
    end)

    tween:Play()
    return tween
end

--=====================================================================================
-- [8.4] MOVEMENT WATCHDOG / STALE OWNER RECOVERY
-- Keeps the farm from staying ON while every movement request is silently blocked.
--=====================================================================================
Watchdog.LastTick = 0
Watchdog.TrackedSerial = nil
Watchdog.LastDistance = math.huge
Watchdog.LastProgressAt = 0
Watchdog.LastRecoveryAt = 0

function Watchdog.IsExclusiveOwnerValid(owner)
    if not owner then
        return true
    end

    if owner == "MELEE" then
        return MeleeSystem and MeleeSystem.PurchaseMode ~= nil
    elseif owner == "SABER" then
        return SaberSystem and SaberSystem.Active == true
    elseif owner == "SEA2" then
        return Sea2System
            and type(Sea2System.IsReadyForSea2) == "function"
            and Sea2System.IsReadyForSea2() == true
    elseif owner == "HP_SAFE" then
        return Combat and Combat.HealthRetreatActive == true
    end

    -- No other subsystem is allowed to hold an exclusive movement lock.
    return false
end

function Watchdog.ReleaseStaleExclusiveOwner()
    local owner = Teleport.ExclusiveOwner
    if not owner or Watchdog.IsExclusiveOwnerValid(owner) then
        return false
    end

    Logger.warn("Movement watchdog released stale owner:", tostring(owner))
    Teleport.Cancel()
    Teleport.ExclusiveOwner = nil

    if Combat and type(Combat.StopAboveHead) == "function" then
        Combat.StopAboveHead()
    end

    QuestSystem.LastMove = 0
    return true
end

function Watchdog.ResetTracking()
    Watchdog.TrackedSerial = nil
    Watchdog.LastDistance = math.huge
    Watchdog.LastProgressAt = 0
end

function Watchdog.Tick()
    local now = tick()
    if now - (Watchdog.LastTick or 0) < 0.35 then
        return false
    end
    Watchdog.LastTick = now

    local recovered = Watchdog.ReleaseStaleExclusiveOwner()

    if not AutomationMovementAllowed() then
        Watchdog.ResetTracking()
        return recovered
    end

    local hrp = Utils.HRP()
    local target = Teleport.Target
    local busy = Teleport.IsBusy()

    if not hrp or not target or not busy then
        Watchdog.ResetTracking()
        return recovered
    end

    local serial = Teleport.MoveSerial
    local distance = (target.Position - hrp.Position).Magnitude
    local epsilon = tonumber(Config.WatchdogMoveEpsilon) or 2.5

    if Watchdog.TrackedSerial ~= serial then
        Watchdog.TrackedSerial = serial
        Watchdog.LastDistance = distance
        Watchdog.LastProgressAt = now
        return recovered
    end

    if distance <= (Watchdog.LastDistance or math.huge) - epsilon then
        Watchdog.LastDistance = distance
        Watchdog.LastProgressAt = now
        return recovered
    end

    -- Do not punish a tween that is already practically at its destination.
    if distance <= 8 then
        Watchdog.LastDistance = distance
        Watchdog.LastProgressAt = now
        return recovered
    end

    local stuckTime = tonumber(Config.WatchdogStuckTime) or 4.5
    if Watchdog.LastProgressAt > 0
        and now - Watchdog.LastProgressAt >= stuckTime
        and now - (Watchdog.LastRecoveryAt or 0) >= 1.0 then

        Watchdog.LastRecoveryAt = now
        Logger.warn(
            "Movement watchdog recovery | owner=",
            tostring(Teleport.Owner),
            "distance=",
            tostring(math.floor(distance + 0.5))
        )

        Teleport.Cancel()
        if Combat and type(Combat.StopAboveHead) == "function" then
            Combat.StopAboveHead()
        end
        QuestSystem.LastMove = 0
        Watchdog.ResetTracking()
        return true
    end

    return recovered
end

--=====================================================================================
-- [8.5] FRUIT COLLECTION SYSTEM
-- Collects only whitelisted fruits, interrupts normal level farm briefly, then returns
-- control to the regular farm engine. Saber/Sea transitions keep higher workflow priority.
--=====================================================================================

FruitSystem.FilterLookup = {}
FruitSystem.Target = nil
FruitSystem.ResolvedNameCache = setmetatable({}, {__mode = "k"})
FruitSystem.VisualSignatureLookup = {}
FruitSystem.VisualIndexBuilt = false
FruitSystem.VisualIndexBuiltAt = 0
FruitSystem.VisualIndexRefreshPending = false
FruitSystem.LastDeepVisualIndexAt = 0

-- Current playable fruit names (Update 30 / Magnet) plus legacy aliases.
FruitSystem.DisplayNames = {
    ["rocket"] = "Rocket",
    ["spin"] = "Spin",
    ["blade"] = "Blade",
    ["spring"] = "Spring",
    ["bomb"] = "Bomb",
    ["smoke"] = "Smoke",
    ["spike"] = "Spike",
    ["flame"] = "Flame",
    ["ice"] = "Ice",
    ["sand"] = "Sand",
    ["dark"] = "Dark",
    ["eagle"] = "Eagle",
    ["diamond"] = "Diamond",
    ["light"] = "Light",
    ["rubber"] = "Rubber",
    ["ghost"] = "Ghost",
    ["magma"] = "Magma",
    ["quake"] = "Quake",
    ["buddha"] = "Buddha",
    ["love"] = "Love",
    ["creation"] = "Creation",
    ["spider"] = "Spider",
    ["sound"] = "Sound",
    ["phoenix"] = "Phoenix",
    ["portal"] = "Portal",
    ["lightning"] = "Lightning",
    ["pain"] = "Pain",
    ["blizzard"] = "Blizzard",
    ["gravity"] = "Gravity",
    ["mammoth"] = "Mammoth",
    ["t rex"] = "T-Rex",
    ["dough"] = "Dough",
    ["shadow"] = "Shadow",
    ["venom"] = "Venom",
    ["gas"] = "Gas",
    ["spirit"] = "Spirit",
    ["tiger"] = "Tiger",
    ["yeti"] = "Yeti",
    ["magnet"] = "Magnet",
    ["control"] = "Control",
    ["kitsune"] = "Kitsune",
    ["dragon"] = "Dragon",
}

FruitSystem.LegacyAliases = {
    ["kilo"] = "rocket",
    ["chop"] = "blade",
    ["falcon"] = "eagle",
    ["revive"] = "ghost",
    ["barrier"] = "creation",
    ["string"] = "spider",
    ["door"] = "portal",
    ["rumble"] = "lightning",
    ["paw"] = "pain",
    ["soul"] = "spirit",
    ["leopard"] = "tiger",
    ["human buddha"] = "buddha",
    ["bird phoenix"] = "phoenix",
    ["east dragon"] = "dragon",
    ["west dragon"] = "dragon",
}

FruitSystem.RarityByName = {
    -- Common
    ["rocket"] = "Comum",
    ["spin"] = "Comum",
    ["blade"] = "Comum",
    ["spring"] = "Comum",
    ["bomb"] = "Comum",
    ["smoke"] = "Comum",
    ["spike"] = "Comum",

    -- Uncommon
    ["flame"] = "Incomum",
    ["ice"] = "Incomum",
    ["sand"] = "Incomum",
    ["dark"] = "Incomum",
    ["eagle"] = "Incomum",
    ["diamond"] = "Incomum",

    -- Rare
    ["light"] = "Rara",
    ["rubber"] = "Rara",
    ["ghost"] = "Rara",
    ["magma"] = "Rara",

    -- Legendary
    ["quake"] = "Lendária",
    ["buddha"] = "Lendária",
    ["love"] = "Lendária",
    ["creation"] = "Lendária",
    ["spider"] = "Lendária",
    ["sound"] = "Lendária",
    ["phoenix"] = "Lendária",
    ["portal"] = "Lendária",
    ["lightning"] = "Lendária",
    ["pain"] = "Lendária",
    ["blizzard"] = "Lendária",

    -- Mythical
    ["gravity"] = "Mítica",
    ["mammoth"] = "Mítica",
    ["t rex"] = "Mítica",
    ["dough"] = "Mítica",
    ["shadow"] = "Mítica",
    ["venom"] = "Mítica",
    ["gas"] = "Mítica",
    ["spirit"] = "Mítica",
    ["tiger"] = "Mítica",
    ["yeti"] = "Mítica",
    ["magnet"] = "Mítica",
    ["control"] = "Mítica",
    ["kitsune"] = "Mítica",
    ["dragon"] = "Mítica",
}

FruitSystem.TargetStartedAt = 0
FruitSystem.TargetDeadline = 0
FruitSystem.TargetLastDistance = math.huge
FruitSystem.TargetLastProgressAt = 0
FruitSystem.LastScanAt = 0
FruitSystem.LastStoreScanAt = 0
FruitSystem.LastRandomAt = 0
FruitSystem.RetryAfter = setmetatable({}, {__mode = "k"})
FruitSystem.StorePending = setmetatable({}, {__mode = "k"})
FruitSystem.StoreRetryAfter = setmetatable({}, {__mode = "k"})
FruitSystem.UnknownSeenAt = setmetatable({}, {__mode = "k"})
FruitSystem.Connections = {}

function FruitSystem.NormalizeFruitName(value)
    local name = string.lower(tostring(value or ""))
    name = name:gsub("blox%s*fruit", " ")
    name = name:gsub("devil%s*fruit", " ")
    name = name:gsub("fruit", " ")
    name = name:gsub("[%[%]%(%){}]", " ")
    name = name:gsub("[%-%_]+", " ")
    name = name:gsub("[^%w%s]", " ")
    name = name:gsub("%s+", " ")
    name = name:match("^%s*(.-)%s*$") or name

    -- Internal IDs are often repeated names such as Flame-Flame.
    local first, second = name:match("^(%S+)%s+(%S+)$")
    if first and second and first == second then
        name = first
    end

    -- Keep current names even when the game/template still exposes a legacy ID.
    name = FruitSystem.LegacyAliases[name] or name

    return name
end

function FruitSystem.IsKnownCanonical(name)
    return type(name) == "string"
        and FruitSystem.DisplayNames[name] ~= nil
end

function FruitSystem.GetVisualSignature(handle)
    if not handle or not handle.Parent then
        return nil
    end

    local values = {}

    local function add(value)
        value = tostring(value or "")
        if value ~= "" then
            table.insert(values, string.lower(value))
        end
    end

    pcall(function()
        if handle:IsA("MeshPart") then
            add(handle.MeshId)
            add(handle.TextureID)
        end
    end)

    for _, child in ipairs(handle:GetDescendants()) do
        pcall(function()
            if child:IsA("SpecialMesh") then
                add(child.MeshId)
                add(child.TextureId)
            elseif child:IsA("Decal") or child:IsA("Texture") then
                add(child.Texture)
            elseif child:IsA("SurfaceAppearance") then
                add(child.ColorMap)
                add(child.NormalMap)
                add(child.MetalnessMap)
                add(child.RoughnessMap)
            end
        end)
    end

    if #values == 0 then
        return nil
    end

    table.sort(values)
    return table.concat(values, "|")
end

function FruitSystem.BuildVisualSignatureIndex(force, deep)
    if FruitSystem.VisualIndexBuilt and not force then
        return
    end

    FruitSystem.VisualIndexBuilt = true
    FruitSystem.VisualIndexBuiltAt = tick()

    if force then
        FruitSystem.VisualSignatureLookup = {}
    end

    local indexed = setmetatable({}, {__mode = "k"})

    local function indexTemplate(template)
        if not template or indexed[template] then
            return
        end
        indexed[template] = true

        if not (template:IsA("Tool") or template:IsA("Model")) then
            return
        end

        local canonical = FruitSystem.NormalizeFruitName(template.Name)
        if not FruitSystem.IsKnownCanonical(canonical) then
            return
        end

        local handle = template:FindFirstChild("Handle")
        if not handle and template:IsA("Model") then
            handle = template.PrimaryPart or template:FindFirstChildWhichIsA("BasePart", true)
        end

        if not handle or not handle:IsA("BasePart") then
            return
        end

        local signature = FruitSystem.GetVisualSignature(handle)
        if signature then
            FruitSystem.VisualSignatureLookup[signature] = canonical
        end
    end

    -- Cheap pass first.
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        indexTemplate(child)

        if child:IsA("Folder")
            and (
                string.find(string.lower(child.Name), "fruit", 1, true)
                or string.find(string.lower(child.Name), "item", 1, true)
                or string.find(string.lower(child.Name), "storage", 1, true)
            ) then

            for _, nested in ipairs(child:GetChildren()) do
                indexTemplate(nested)
            end
        end
    end

    -- Only run this deeper pass when an unresolved fruit actually needs it.
    if deep then
        for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
            indexTemplate(descendant)
        end
    end
end

function FruitSystem.RequestDeepVisualIndexRefresh()
    if FruitSystem.VisualIndexRefreshPending then
        return
    end

    local now = tick()
    local cooldown = tonumber(Config.FruitESPDeepIndexCooldown) or 12.0

    if now - (FruitSystem.LastDeepVisualIndexAt or 0) < cooldown then
        return
    end

    FruitSystem.VisualIndexRefreshPending = true
    FruitSystem.LastDeepVisualIndexAt = now

    task.spawn(function()
        pcall(function()
            FruitSystem.BuildVisualSignatureIndex(true, true)
        end)

        FruitSystem.VisualIndexRefreshPending = false
    end)
end

function FruitSystem.RefreshFilter()
    local lookup = {}

    if type(Config.FruitFilter) == "table" then
        for _, fruitName in ipairs(Config.FruitFilter) do
            local normalized = FruitSystem.NormalizeFruitName(fruitName)
            if normalized ~= "" then
                lookup[normalized] = true
            end
        end
    end

    FruitSystem.FilterLookup = lookup
end

function FruitSystem.GetHandle(object)
    if not object or not object.Parent then
        return nil
    end

    local handle = object:FindFirstChild("Handle")
    if handle and handle:IsA("BasePart") then
        return handle
    end

    if object:IsA("Model") and object.PrimaryPart then
        return object.PrimaryPart
    end

    return nil
end

function FruitSystem.GetCandidateNames(object)
    local names = {}
    local seen = {}

    local function add(value)
        value = tostring(value or "")
        if value ~= "" and not seen[value] then
            seen[value] = true
            table.insert(names, value)
        end
    end

    local function addAttributes(instance)
        if not instance then
            return
        end

        local ok, attributes = pcall(function()
            return instance:GetAttributes()
        end)

        if ok and type(attributes) == "table" then
            for key, value in pairs(attributes) do
                add(key)
                if type(value) == "string" or type(value) == "number" then
                    add(value)
                end
            end
        end
    end

    if object then
        add(object.Name)
        addAttributes(object)

        local handle = FruitSystem.GetHandle(object)
        addAttributes(handle)

        -- Updated world fruit objects may use generic names like "1 Fruit".
        -- Search their small internal hierarchy for an actual fruit identifier.
        for _, descendant in ipairs(object:GetDescendants()) do
            add(descendant.Name)

            if descendant:IsA("StringValue") then
                add(descendant.Value)
            end
        end
    end

    return names
end

function FruitSystem.GetCanonicalName(object)
    if not object then
        return ""
    end

    local cached = FruitSystem.ResolvedNameCache[object]
    if cached and cached ~= "" then
        return cached
    end

    -- Prefer text/attributes that resolve to a known current fruit.
    for _, value in ipairs(FruitSystem.GetCandidateNames(object)) do
        local normalized = FruitSystem.NormalizeFruitName(value)
        if FruitSystem.IsKnownCanonical(normalized) then
            FruitSystem.ResolvedNameCache[object] = normalized
            return normalized
        end
    end

    -- Updated game builds can spawn generic Tool names. Match the physical
    -- fruit's mesh/texture against the replicated fruit template.
    FruitSystem.BuildVisualSignatureIndex(false, false)

    local handle = FruitSystem.GetHandle(object)
    local signature = FruitSystem.GetVisualSignature(handle)
    local visualName = signature and FruitSystem.VisualSignatureLookup[signature]

    if FruitSystem.IsKnownCanonical(visualName) then
        FruitSystem.ResolvedNameCache[object] = visualName
        return visualName
    end

    -- A just-spawned fruit can exist before its final attributes/mesh hierarchy
    -- has fully replicated. Ask for one deeper template refresh and let the
    -- normal ESP loop retry automatically on the next frame/scan.
    FruitSystem.RequestDeepVisualIndexRefresh()

    return ""
end

function FruitSystem.GetDisplayName(object)
    local canonical = FruitSystem.GetCanonicalName(object)
    if canonical == "" then
        return "Fruta desconhecida"
    end

    return FruitSystem.DisplayNames[canonical] or canonical
end

function FruitSystem.IsExcludedPuzzleObject(object)
    if not Config.FruitIgnorePuzzleObjects or not object then
        return false
    end

    -- Update 30 Colosseum "Previous Champions" puzzle. One statue is
    -- fruit-themed and can contain/name descendants with the word Fruit.
    -- Never let scenery/statues enter the unknown-fruit fallback.
    local blockedTokens = {
        "statue",
        "champion",
        "previous champion",
        "former champion",
        "sculpture",
        "monument",
    }

    local function blockedName(value)
        local lower = string.lower(tostring(value or ""))
        if lower == "" then
            return false
        end
        for _, token in ipairs(blockedTokens) do
            if string.find(lower, token, 1, true) then
                return true
            end
        end
        return false
    end

    if blockedName(object.Name) then
        return true
    end

    -- Check a bounded amount of descendants. The new Colosseum statue may be
    -- generically named at the root while a child identifies it as a statue.
    local scanned = 0
    for _, descendant in ipairs(object:GetDescendants()) do
        scanned = scanned + 1
        if scanned > 120 then
            break
        end
        if blockedName(descendant.Name) then
            return true
        end
    end

    -- A real dropped fruit is small. Unknown *models* that are large, static
    -- scenery (like the Colosseum Fruit statue) must never be auto-collected.
    -- Known fruits are resolved before this size guard in IsFruitObject.
    if object:IsA("Model") then
        local maxAllowed = tonumber(Config.FruitUnknownModelMaxSize) or 5.25
        local okSize, size = pcall(function()
            return object:GetExtentsSize()
        end)
        local handle = FruitSystem.GetHandle(object)
        local anchored = false
        if handle then
            pcall(function()
                anchored = handle.Anchored == true
            end)
        end

        if okSize and size then
            local largest = math.max(size.X, size.Y, size.Z)
            if anchored and largest > maxAllowed then
                return true
            end
        end
    end

    return false
end

function FruitSystem.IsFruitObject(object)
    if not object or not object.Parent then
        return false
    end

    if not (object:IsA("Tool") or object:IsA("Model")) then
        return false
    end

    local handle = FruitSystem.GetHandle(object)
    if not handle then
        return false
    end

    -- Strong identifiers win first. A real current fruit with a canonical
    -- name/attribute stays valid even if the model representation changes.
    local canonical = FruitSystem.GetCanonicalName(object)
    if canonical ~= "" then
        return true
    end

    if FruitSystem.IsExcludedPuzzleObject(object) then
        FruitSystem.UnknownSeenAt[object] = nil
        return false
    end

    local lowerName = string.lower(tostring(object.Name or ""))

    -- Generic world fruits are commonly named "Fruit" / "1 Fruit" etc.
    -- Avoid the old broad substring test, which also matched "Fruit Statue".
    if lowerName == "fruit"
        or string.match(lowerName, "^%d+%s+fruit$")
        or string.match(lowerName, "^.+%s+fruit$") then
        return true
    end

    -- Legacy/internal marker, but only after puzzle/scenery exclusion.
    if object:FindFirstChild("Fruit") then
        return true
    end

    local ok, original = pcall(function()
        return object:GetAttribute("OriginalName")
    end)
    return ok and type(original) == "string" and original ~= ""
end

function FruitSystem.IsAllowed(object)
    if not FruitSystem.IsFruitObject(object) then
        return false
    end

    if FruitSystem.IsExcludedPuzzleObject(object) then
        FruitSystem.UnknownSeenAt[object] = nil
        return false
    end

    local lookup = FruitSystem.FilterLookup or {}
    local canonical = FruitSystem.GetCanonicalName(object)

    -- Known fruit: respect the configured whitelist exactly.
    if canonical ~= "" then
        FruitSystem.UnknownSeenAt[object] = nil
        return next(lookup) ~= nil and lookup[canonical] == true
    end

    -- Unknown fruit: give replication/name resolution a few seconds first.
    -- If it still cannot be identified, collect it anyway when enabled.
    if not Config.FruitCollectUnknown then
        return false
    end

    local firstSeen = FruitSystem.UnknownSeenAt[object]
    if not firstSeen then
        firstSeen = tick()
        FruitSystem.UnknownSeenAt[object] = firstSeen
        return false
    end

    local delay = math.max(0, tonumber(Config.FruitUnknownCollectDelay) or 6.0)
    return tick() - firstSeen >= delay
end

function FruitSystem.IsWorldFruit(object)
    return object
        and object.Parent == workspace
        and FruitSystem.IsFruitObject(object)
        and FruitSystem.GetHandle(object) ~= nil
end

function FruitSystem.FindNearestFruit()
    local hrp = Utils.HRP()
    if not hrp then
        return nil
    end

    local nearest = nil
    local nearestDistance = math.huge
    local now = tick()

    -- Current Blox Fruits ground fruits are normally direct Workspace children.
    -- Scanning GetChildren() is intentionally cheap and avoids a hot GetDescendants() loop.
    for _, object in ipairs(workspace:GetChildren()) do
        if FruitSystem.IsAllowed(object) and FruitSystem.IsWorldFruit(object) then
            local retryAt = FruitSystem.RetryAfter[object] or 0
            if now >= retryAt then
                local handle = FruitSystem.GetHandle(object)
                if handle then
                    local distance = (handle.Position - hrp.Position).Magnitude
                    local canonical = FruitSystem.GetCanonicalName(object)
                    local unknownTooFar = canonical == ""
                        and distance > (tonumber(Config.FruitUnknownMaxDistance) or 350)

                    -- Unknown is only a nearby fallback. A real whitelisted fruit
                    -- that resolves to a canonical name may still be chased globally.
                    if not unknownTooFar and distance < nearestDistance then
                        nearestDistance = distance
                        nearest = object
                    end
                end
            end
        end
    end

    return nearest
end

function FruitSystem.TouchFruit(object)
    local handle = FruitSystem.GetHandle(object)
    local hrp = Utils.HRP()
    if not handle or not hrp then
        return false
    end

    local touched = false

    if type(firetouchinterest) == "function" then
        touched = pcall(function()
            firetouchinterest(hrp, handle, 0)
            task.wait(0.03)
            firetouchinterest(hrp, handle, 1)
        end)
    end

    -- Physical contact fallback for executors without firetouchinterest.
    if not touched then
        pcall(function()
            local char = Utils.Character()
            if char and char.PivotTo then
                char:PivotTo(CFrame.new(handle.Position + Vector3.new(0, 1.5, 0)))
            else
                hrp.CFrame = CFrame.new(handle.Position + Vector3.new(0, 1.5, 0))
            end
        end)
    end

    return true
end

function FruitSystem.GetStoreId(tool)
    if not tool then
        return nil
    end

    local ok, original = pcall(function()
        return tool:GetAttribute("OriginalName")
    end)
    if ok and type(original) == "string" and original ~= "" then
        return original
    end

    local canonical = FruitSystem.GetCanonicalName(tool)
    if canonical == "" then
        return nil
    end

    local display = FruitSystem.DisplayNames[canonical] or canonical
    local pretty = tostring(display):gsub("(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. rest
    end)

    -- Compatibility fallback used by Blox Fruits StoreFruit layouts.
    return pretty .. "-" .. pretty
end

function FruitSystem.GetStoreIds(tool)
    local ids = {}
    local seen = {}

    local function add(value)
        value = tostring(value or "")
        if value ~= "" and not seen[value] then
            seen[value] = true
            table.insert(ids, value)
        end
    end

    if not tool then
        return ids
    end

    pcall(function()
        add(tool:GetAttribute("OriginalName"))
    end)

    add(FruitSystem.GetStoreId(tool))

    local canonical = FruitSystem.GetCanonicalName(tool)
    if canonical ~= "" then
        local display = FruitSystem.DisplayNames[canonical] or canonical
        add(display .. "-" .. display)
        add(display)
    end

    -- Last compatibility candidates. These are attempted only if the canonical
    -- StoreFruit id did not remove the Tool from Backpack/Character.
    add(tool.Name)

    return ids
end

function FruitSystem.IsOwnedFruitTool(tool)
    if not tool or not tool.Parent or not tool:IsA("Tool") then
        return false
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = Utils.Character()
    if tool.Parent ~= backpack and tool.Parent ~= character then
        return false
    end

    if FruitSystem.IsExcludedPuzzleObject(tool) then
        return false
    end

    -- Known fruits are always safe to store. This intentionally does NOT use
    -- IsAllowed(): the collection whitelist must not block storage of a fruit
    -- that is already in the player's inventory.
    local canonical = FruitSystem.GetCanonicalName(tool)
    if canonical ~= "" and FruitSystem.IsKnownCanonical(canonical) then
        if Config.FruitStoreAnyOwned == false then
            local lookup = FruitSystem.FilterLookup or {}
            return lookup[canonical] == true
        end
        return true
    end

    local ok, original = pcall(function()
        return tool:GetAttribute("OriginalName")
    end)
    if ok and type(original) == "string" and original ~= "" then
        return true
    end

    -- Generic fruit Tools can replicate their final name a moment late.
    return FruitSystem.IsFruitObject(tool)
end

function FruitSystem.IsStillOwned(tool)
    if not tool or not tool.Parent then
        return false
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = Utils.Character()
    return tool.Parent == backpack or tool.Parent == character
end

function FruitSystem.QueueStore(tool)
    if FruitSystem.RandomActive and FruitSystem.RandomBeforeTools
        and not FruitSystem.RandomBeforeTools[tool]
        and FruitSystem.IsOwnedFruitTool(tool) and FruitSystem.IsStillOwned(tool) then
        FruitSystem.RandomObtainedName = FruitSystem.GetDisplayName(tool)
    end
    if not Config.FruitAutoStore
        or not tool
        or not tool.Parent
        or FruitSystem.StorePending[tool]
        or tick() < (FruitSystem.StoreRetryAfter[tool] or 0) then
        return
    end

    if not FruitSystem.IsOwnedFruitTool(tool) then
        return
    end

    local storeIds = FruitSystem.GetStoreIds(tool)
    if #storeIds == 0 then
        return
    end

    FruitSystem.StorePending[tool] = true

    task.spawn(function()
        local stored = false
        local maxAttempts = math.max(1, math.floor(tonumber(Config.FruitStoreMaxAttempts) or 4))
        local attempt = 0

        while attempt < maxAttempts and FruitSystem.IsStillOwned(tool) do
            attempt = attempt + 1

            local remote = CommF_ or GetCommF()
            if not remote then
                task.wait(0.25)
            else
                -- Re-resolve every pass because OriginalName/canonical metadata
                -- can finish replicating after the fruit first enters Backpack.
                storeIds = FruitSystem.GetStoreIds(tool)

                for _, storeId in ipairs(storeIds) do
                    if not FruitSystem.IsStillOwned(tool) then
                        stored = true
                        break
                    end

                    pcall(function()
                        remote:InvokeServer("StoreFruit", storeId, tool)
                    end)

                    -- Do not trust the remote return value. Some builds return
                    -- nil even when storage succeeds; disappearance from the
                    -- Backpack/Character is the reliable confirmation.
                    local confirmDeadline = tick() + 0.45
                    repeat
                        task.wait(0.06)
                        if not FruitSystem.IsStillOwned(tool) then
                            stored = true
                            break
                        end
                    until tick() >= confirmDeadline

                    if stored then
                        break
                    end
                end
            end

            if not stored and FruitSystem.IsStillOwned(tool) then
                task.wait(0.20)
            end
        end

        if stored or not FruitSystem.IsStillOwned(tool) then
            FruitSystem.StoreRetryAfter[tool] = nil
        elseif tool and tool.Parent then
            FruitSystem.StoreRetryAfter[tool] = tick() + (tonumber(Config.FruitStoreRetryInterval) or 1.25)
        end

        FruitSystem.StorePending[tool] = nil
    end)
end

if __KRATOS_ENV.__KRATOS_RANDOM_OWNER == LocalPlayer.UserId then
    FruitSystem.RandomNextAt = tonumber(__KRATOS_ENV.__KRATOS_RANDOM_NEXT_AT) or 0
end

function FruitSystem.SetRandomStatus(text, seconds)
    FruitSystem.RandomStatus = tostring(text)
    FruitSystem.RandomStatusUntil = tick() + (seconds or 8)
end

function FruitSystem.GetOwnedFruitSet()
    local result = {}
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    for _, container in pairs({backpack, Utils.Character()}) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and FruitSystem.IsOwnedFruitTool(tool) then
                    result[tool] = true
                end
            end
        end
    end
    return result
end

function FruitSystem.EndRandomRoll(status, retryDelay)
    FruitSystem.RandomActive = false
    FruitSystem.RandomBuying = false
    FruitSystem.RandomConfirmUntil = nil
    FruitSystem.RandomNextAt = tick() + (retryDelay or 60)
    FruitSystem.SetRandomStatus(status, 10)
    FruitSystem.LastStoreScanAt = 0
end

function FruitSystem.RandomResponseDelay(response)
    local text = string.lower(tostring(response or ""))
    local h, m, s = text:match("(%d+):(%d%d):(%d%d)")
    if h then
        return math.max(15, math.min(7200, tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)))
    end
    local minutes = text:match("(%d+)%s+minutes?") or text:match("(%d+)%s+minutos?")
    local seconds = text:match("(%d+)%s+seconds?") or text:match("(%d+)%s+segundos?")
    if minutes or seconds then
        return math.max(15, math.min(7200, (tonumber(minutes) or 0) * 60 + (tonumber(seconds) or 0)))
    end
    return 60
end

-- Remote-only random fruit. This function ALWAYS returns false: it never
-- takes movement priority, searches for an NPC, or pauses the farm engine.
function FruitSystem.AutoRandomTick()
    local now = tick()
    if Config.FruitAutoRandom ~= true or not AutomationMovementAllowed() then
        if FruitSystem.RandomActive then
            FruitSystem.EndRandomRoll("disabled", 0)
        end
        return false
    end
    if (tonumber(Utils.Level()) or 1) < 50 then
        return false
    end

    if FruitSystem.RandomConfirmUntil then
        local obtained = nil
        for tool in pairs(FruitSystem.GetOwnedFruitSet()) do
            if not (FruitSystem.RandomBeforeTools or {})[tool] then
                obtained = tool
                break
            end
        end
        if obtained or FruitSystem.RandomObtainedName then
            local name = obtained and FruitSystem.GetDisplayName(obtained) or FruitSystem.RandomObtainedName
            if obtained then FruitSystem.QueueStore(obtained) end
            FruitSystem.EndRandomRoll("obtained " .. tostring(name), 7200)
            __KRATOS_ENV.__KRATOS_RANDOM_OWNER = LocalPlayer.UserId
            __KRATOS_ENV.__KRATOS_RANDOM_NEXT_AT = FruitSystem.RandomNextAt
        elseif now >= FruitSystem.RandomConfirmUntil then
            local result = tostring(FruitSystem.RandomResult or "no fruit received")
            FruitSystem.EndRandomRoll("not confirmed: " .. result:sub(1, 100), FruitSystem.RandomResponseDelay(result))
        end
        return false
    end

    if FruitSystem.RandomPending then
        if FruitSystem.RandomBuying and now - (FruitSystem.RandomBuyStartedAt or now) >= 10 then
            -- Keep the in-flight guard until the remote actually returns.
            -- The farm continues even if the server response is late.
            FruitSystem.EndRandomRoll("server response pending; farm continues", 60)
        end
        return false
    end
    if now < (FruitSystem.RandomNextAt or 0) then
        return false
    end

    FruitSystem.RandomBeforeTools = FruitSystem.GetOwnedFruitSet()
    FruitSystem.RandomObtainedName = nil
    FruitSystem.RandomResult = nil
    FruitSystem.RandomPending = true
    FruitSystem.RandomBuying = true
    FruitSystem.RandomActive = true
    FruitSystem.RandomBuyStartedAt = now
    FruitSystem.SetRandomStatus("rolling remotely; farm continues", 8)

    task.spawn(function()
        local ok, response = pcall(function()
            if not IsCurrentSession() or not AutomationMovementAllowed() or Config.FruitAutoRandom ~= true then
                return "cancelled"
            end
            local remote = CommF_ or WaitForCommF(2)
            if not remote then return "CommF_ missing" end
            return remote:InvokeServer("Cousin", "Buy")
        end)
        FruitSystem.RandomPending = false
        FruitSystem.RandomBuying = false
        if IsCurrentSession() and Config.FruitAutoRandom == true and AutomationMovementAllowed() then
            FruitSystem.RandomActive = true
            FruitSystem.RandomResult = ok and response or ("remote error: " .. tostring(response))
            FruitSystem.RandomConfirmUntil = tick() + 4
            FruitSystem.LastStoreScanAt = 0
        end
    end)
    return false
end

function FruitSystem.StoreOwnedFruits()
    if not Config.FruitAutoStore then
        return
    end

    local now = tick()
    if (now - (FruitSystem.LastStoreScanAt or 0)) < (tonumber(Config.FruitStoreScanInterval) or 0.25) then
        return
    end
    FruitSystem.LastStoreScanAt = now

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = Utils.Character()

    for _, container in ipairs({backpack, character}) do
        if container then
            for _, object in ipairs(container:GetChildren()) do
                if object:IsA("Tool") and FruitSystem.IsOwnedFruitTool(object) then
                    FruitSystem.QueueStore(object)
                end
            end
        end
    end
end

function FruitSystem.BeginTarget(target, now)
    now = tonumber(now) or tick()

    FruitSystem.Target = target
    FruitSystem.TargetStartedAt = now
    FruitSystem.TargetLastProgressAt = now
    FruitSystem.TargetLastDistance = math.huge

    local hrp = Utils.HRP()
    local handle = FruitSystem.GetHandle(target)
    local initialDistance = 0

    if hrp and handle then
        initialDistance = (handle.Position - hrp.Position).Magnitude
        FruitSystem.TargetLastDistance = initialDistance
    end

    local speed = math.max(
        tonumber(Config.FarmSpeed) or tonumber(Config.TweenSpeed) or 190,
        1
    )

    local travelETA = initialDistance / speed
    local minimum = math.max(tonumber(Config.FruitPickupTimeout) or 5.0, 5.0)
    local maximum = math.max(minimum, tonumber(Config.FruitTravelMaxTime) or 90.0)
    local grace = math.max(0, tonumber(Config.FruitTravelGrace) or 10.0)

    FruitSystem.TargetDeadline = now + math.clamp(
        travelETA + grace,
        minimum,
        maximum
    )

    -- Make sure an old farm/quest tween cannot pull against the fruit trip.
    if Teleport.IsBusy() and Teleport.Owner ~= "FRUIT" then
        Teleport.Cancel()
    end

    Combat.CurrentTarget = nil
    Combat.ResetAnchor()
end

function FruitSystem.ResetTarget(cooldown)
    local target = FruitSystem.Target
    if target and cooldown and target.Parent then
        local canonical = FruitSystem.GetCanonicalName(target)
        local retryDelay
        if canonical == "" then
            retryDelay = tonumber(Config.FruitUnknownFailureCooldown) or 45.0
        else
            retryDelay = tonumber(Config.FruitRetryCooldown) or 6.0
        end
        FruitSystem.RetryAfter[target] = tick() + retryDelay
    end

    FruitSystem.Target = nil
    FruitSystem.TargetStartedAt = 0
    FruitSystem.TargetDeadline = 0
    FruitSystem.TargetLastDistance = math.huge
    FruitSystem.TargetLastProgressAt = 0

    if Teleport.Owner == "FRUIT" then
        Teleport.Cancel()
    end
end

function FruitSystem.Tick()
    FruitSystem.StoreOwnedFruits()

    if not Config.AutoFruit then
        FruitSystem.ResetTarget(false)
        return false
    end

    local now = tick()
    local target = FruitSystem.Target

    if target and (not FruitSystem.IsWorldFruit(target) or not FruitSystem.IsAllowed(target)) then
        FruitSystem.ResetTarget(false)
        target = nil
    end

    if not target and (now - (FruitSystem.LastScanAt or 0)) >= (tonumber(Config.FruitScanInterval) or 0.75) then
        FruitSystem.LastScanAt = now
        target = FruitSystem.FindNearestFruit()
        if target then
            FruitSystem.BeginTarget(target, now)
        end
    end

    if not target then
        return false
    end

    local handle = FruitSystem.GetHandle(target)
    local hrp = Utils.HRP()
    if not handle or not hrp then
        FruitSystem.ResetTarget(true)
        return false
    end

    local displayName = FruitSystem.GetDisplayName(target)
    local distance = (handle.Position - hrp.Position).Magnitude
    local pickupDistance = tonumber(Config.FruitPickupDistance) or 5.5

    -- Long fruit flights used to inherit the 5-second pickup timeout. A fruit
    -- 2000+ studs away needs much longer at FarmSpeed=190, so the Kaitun would
    -- cancel FRUIT, resume the level farm, reacquire the fruit, and fly back
    -- again. Keep one target locked until its calculated ETA expires instead.
    local previousDistance = tonumber(FruitSystem.TargetLastDistance) or math.huge
    if distance < previousDistance - 3 then
        FruitSystem.TargetLastDistance = distance
        FruitSystem.TargetLastProgressAt = now
    end

    if (FruitSystem.TargetDeadline or 0) > 0
        and now > FruitSystem.TargetDeadline then

        FruitSystem.ResetTarget(true)
        return false
    end

    local noProgressTimeout = tonumber(Config.FruitNoProgressTimeout) or 7.0
    if distance > pickupDistance
        and FruitSystem.TargetLastProgressAt > 0
        and now - FruitSystem.TargetLastProgressAt > noProgressTimeout then

        FruitSystem.ResetTarget(true)
        return false
    end

    Combat.CurrentTarget = nil
    Combat.ResetAnchor()
    UI.SetStatus(
        "Fruit | collecting " .. displayName
            .. " | " .. tostring(math.floor(distance + 0.5)) .. " studs",
        true
    )

    if distance > pickupDistance then
        local destination = CFrame.new(handle.Position + Vector3.new(0, 2.0, 0))

        -- Stable owner + non-forced repath means the same fruit trip continues
        -- instead of constantly restarting the tween every farm tick.
        local movement = Teleport.To(destination, Config.FarmSpeed, "FRUIT", false)
        if not movement and Teleport.Owner ~= "FRUIT" then
            -- A stale/high-priority movement lock must never let FruitSystem
            -- keep the farm paused while the avatar is not actually traveling.
            FruitSystem.ResetTarget(true)
            return false
        end
        return true
    end

    if Teleport.Owner == "FRUIT" then
        Teleport.Cancel()
    end

    FruitSystem.TouchFruit(target)

    -- If collection succeeded the Tool leaves Workspace and is stored next tick.
    if not FruitSystem.IsWorldFruit(target) then
        FruitSystem.ResetTarget(false)
        return true
    end

    -- Once we're actually beside the fruit, use the short pickup timeout only
    -- for repeated contact attempts; do not send the character back to farming.
    local closeElapsed = now - math.max(
        FruitSystem.TargetLastProgressAt or now,
        FruitSystem.TargetStartedAt or now
    )

    if closeElapsed > (tonumber(Config.FruitPickupTimeout) or 5.0) then
        FruitSystem.ResetTarget(true)
    end

    return true
end

function FruitSystem.Init()
    FruitSystem.RefreshFilter()
    FruitSystem.BuildVisualSignatureIndex()

    -- Lightweight event hint: force the next cheap top-level scan when a fruit appears.
    table.insert(FruitSystem.Connections, workspace.ChildAdded:Connect(function(object)
        if FruitSystem.IsFruitObject(object) then
            FruitSystem.LastScanAt = 0
        end
    end))

    -- Store newly collected fruits immediately instead of waiting for the next
    -- farm scan. A short delay lets OriginalName/name attributes finish replicating.
    local function bindOwnedContainer(container)
        if not container then
            return
        end

        table.insert(FruitSystem.Connections, container.ChildAdded:Connect(function(object)
            if not object:IsA("Tool") then
                return
            end

            task.delay(0.12, function()
                if Config.FruitAutoStore and object and object.Parent then
                    FruitSystem.QueueStore(object)
                end
            end)
        end))
    end

    bindOwnedContainer(LocalPlayer:FindFirstChild("Backpack"))
    bindOwnedContainer(Utils.Character())

    table.insert(FruitSystem.Connections, LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(0.20)
        bindOwnedContainer(character)
        FruitSystem.LastStoreScanAt = 0
    end))
end

--=====================================================================================
-- [8.6] FRUIT ESP SYSTEM
-- Lightweight BillboardGui ESP inspired by common GitHub Blox Fruits ESP patterns.
-- Shows every physical world fruit, independently of the AutoCollect whitelist.
--=====================================================================================

FruitESPSystem.Objects = setmetatable({}, {__mode = "k"})
FruitESPSystem.Connections = {}
FruitESPSystem.Metadata = {}
FruitESPSystem.LastMetadataRefresh = 0
FruitESPSystem.Running = false

function FruitESPSystem.PriceToRarity(price)
    price = tonumber(price) or 0

    -- Fallback only. If GetFruits exposes a rarity field, that value wins.
    if price >= 2500000 then
        return "Mythical"
    elseif price >= 1000000 then
        return "Legendary"
    elseif price >= 600000 then
        return "Rare"
    elseif price >= 250000 then
        return "Uncommon"
    end

    return "Common"
end

function FruitESPSystem.NormalizeRarity(value)
    if value == nil then
        return nil
    end

    if type(value) == "string" or type(value) == "number" then
        local result = tostring(value)
        if result ~= "" then
            return result
        end
    elseif type(value) == "table" then
        for _, key in ipairs({"Name", "DisplayName", "Rarity", "Tier", "name"}) do
            if value[key] ~= nil then
                local result = tostring(value[key])
                if result ~= "" then
                    return result
                end
            end
        end
    end

    return nil
end

function FruitESPSystem.RefreshMetadata(force)
    local now = tick()
    local interval = tonumber(Config.FruitESPMetadataRefresh) or 60

    if not force and now - (FruitESPSystem.LastMetadataRefresh or 0) < interval then
        return
    end

    FruitESPSystem.LastMetadataRefresh = now

    task.spawn(function()
        local remote = CommF_ or GetCommF()
        if not remote then
            return
        end

        local ok, fruits = pcall(function()
            return remote:InvokeServer("GetFruits")
        end)

        if not ok or type(fruits) ~= "table" then
            return
        end

        local metadata = {}

        for _, entry in pairs(fruits) do
            if type(entry) == "table" and entry.Name then
                local normalized = FruitSystem.NormalizeFruitName(entry.Name)

                if normalized ~= "" then
                    local rarity = FruitESPSystem.NormalizeRarity(
                        entry.Rarity or entry.Tier or entry.Quality or entry.RarityName
                    )

                    if not rarity then
                        rarity = FruitESPSystem.PriceToRarity(entry.Price)
                    end

                    metadata[normalized] = {
                        Rarity = rarity,
                        Price = tonumber(entry.Price) or 0,
                    }
                end
            end
        end

        FruitESPSystem.Metadata = metadata
    end)
end

function FruitESPSystem.GetRarity(object)
    local canonical = FruitSystem.GetCanonicalName(object)

    -- Current in-game rarity map is more reliable than guessing by price.
    local current = FruitSystem.RarityByName[canonical]
    if current then
        return current
    end

    local data = FruitESPSystem.Metadata[canonical]
    if data and data.Rarity then
        local raw = string.lower(tostring(data.Rarity))

        local translations = {
            common = "Comum",
            uncommon = "Incomum",
            rare = "Rara",
            legendary = "Lendária",
            mythical = "Mítica",
        }

        return translations[raw] or tostring(data.Rarity)
    end

    return "Desconhecida"
end

function FruitESPSystem.Destroy(object)
    local data = FruitESPSystem.Objects[object]
    FruitESPSystem.Objects[object] = nil

    if data and data.Connections then
        for _, connection in ipairs(data.Connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
    end

    if data and data.Gui then
        pcall(function()
            data.Gui:Destroy()
        end)
    end
end

function FruitESPSystem.Create(object)
    if not Config.FruitESP
        or not FruitSystem.IsWorldFruit(object)
        or FruitSystem.IsExcludedPuzzleObject(object) then
        return nil
    end

    local handle = FruitSystem.GetHandle(object)
    if not handle then
        return nil
    end

    local old = handle:FindFirstChild("VELTRIX_FRUIT_ESP")
    if old then
        pcall(function() old:Destroy() end)
    end

    local gui = Instance.new("BillboardGui")
    gui.Name = "VELTRIX_FRUIT_ESP"
    gui.Adornee = handle
    gui.Size = UDim2.new(0, 230, 0, 58)
    gui.StudsOffset = Vector3.new(0, 3.2, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = tonumber(Config.FruitESPMaxDistance) or 10000
    gui.Parent = handle

    local label = Instance.new("TextLabel")
    label.Name = "Info"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextWrapped = true
    label.TextStrokeTransparency = 0.25
    label.TextColor3 = Color3.fromRGB(255, 220, 80)
    label.Text = "Fruit"
    label.Parent = gui

    local data = {
        Gui = gui,
        Label = label,
        Handle = handle,
        BornAt = tick(),
        Connections = {},
    }

    FruitESPSystem.Objects[object] = data

    local function forceResolve()
        FruitSystem.ResolvedNameCache[object] = nil

        task.defer(function()
            if object and object.Parent and FruitESPSystem.Objects[object] == data then
                FruitESPSystem.UpdateObject(object)
            end
        end)
    end

    -- Current game builds can create the physical Tool first and fill its
    -- final identity/mesh/attributes a fraction of a second later.
    table.insert(data.Connections, object:GetPropertyChangedSignal("Name"):Connect(forceResolve))
    table.insert(data.Connections, object.AttributeChanged:Connect(forceResolve))
    table.insert(data.Connections, object.DescendantAdded:Connect(function()
        forceResolve()
    end))

    return data
end

function FruitESPSystem.UpdateObject(object)
    if not object or not FruitSystem.IsWorldFruit(object) then
        FruitESPSystem.Destroy(object)
        return
    end

    local data = FruitESPSystem.Objects[object]
    if not data or not data.Gui or not data.Gui.Parent then
        data = FruitESPSystem.Create(object)
    end

    if not data or not data.Label or not data.Handle then
        return
    end

    data.Gui.MaxDistance = tonumber(Config.FruitESPMaxDistance) or 10000

    local canonical = FruitSystem.GetCanonicalName(object)
    local unresolved = canonical == ""

    local display
    if unresolved then
        FruitSystem.ResolvedNameCache[object] = nil

        local firstSeen = FruitSystem.UnknownSeenAt[object]
        local delay = math.max(0, tonumber(Config.FruitUnknownCollectDelay) or 6.0)

        if firstSeen and tick() - firstSeen >= delay and Config.FruitCollectUnknown then
            display = "Fruta não identificada • coleta automática"
        else
            display = "Identificando fruta..."
        end
    else
        display = (FruitSystem.DisplayNames[canonical] or canonical) .. " Fruit"
    end

    local lines = {display}

    local hrp = Utils.HRP()
    if Config.FruitESPShowDistance and hrp then
        local distance = math.floor((data.Handle.Position - hrp.Position).Magnitude + 0.5)
        table.insert(lines, "Distância: " .. tostring(distance) .. " studs")
    end

    if Config.FruitESPShowRarity and not unresolved then
        table.insert(lines, "Raridade: " .. FruitESPSystem.GetRarity(object))
    elseif unresolved then
        local age = tick() - (data.BornAt or tick())

        if age >= (tonumber(Config.FruitESPResolveGrace) or 6.0) then
            -- Force another deep template lookup for long-lived unresolved fruits.
            FruitSystem.RequestDeepVisualIndexRefresh()
        end
    end

    data.Label.Text = table.concat(lines, "\n")
end

function FruitESPSystem.Clear()
    local toDestroy = {}

    for object in pairs(FruitESPSystem.Objects) do
        table.insert(toDestroy, object)
    end

    for _, object in ipairs(toDestroy) do
        FruitESPSystem.Destroy(object)
    end
end

function FruitESPSystem.Scan()
    if not Config.FruitESP then
        FruitESPSystem.Clear()
        return
    end

    FruitESPSystem.RefreshMetadata(false)

    local seen = {}

    -- Physical fruits are normally direct Workspace children; this keeps ESP cheap.
    for _, object in ipairs(workspace:GetChildren()) do
        if FruitSystem.IsWorldFruit(object) then
            seen[object] = true
            FruitESPSystem.UpdateObject(object)
        end
    end

    local stale = {}
    for object in pairs(FruitESPSystem.Objects) do
        if not seen[object] or not object.Parent then
            table.insert(stale, object)
        end
    end

    for _, object in ipairs(stale) do
        FruitESPSystem.Destroy(object)
    end
end

function FruitESPSystem.Init()
    if FruitESPSystem.Running then
        return
    end

    FruitESPSystem.Running = true
    FruitESPSystem.RefreshMetadata(true)

    table.insert(FruitESPSystem.Connections, workspace.ChildAdded:Connect(function(object)
        if Config.FruitESP and FruitSystem.IsFruitObject(object) then
            task.defer(function()
                FruitESPSystem.UpdateObject(object)
            end)
        end
    end))

    table.insert(FruitESPSystem.Connections, workspace.ChildRemoved:Connect(function(object)
        if FruitESPSystem.Objects[object] then
            FruitESPSystem.Destroy(object)
        end
    end))

    task.spawn(function()
        while FruitESPSystem.Running and IsCurrentSession() do
            FruitESPSystem.Scan()
            task.wait(math.max(0.15, tonumber(Config.FruitESPRefreshInterval) or 0.30))
        end

        FruitESPSystem.Clear()
    end)
end

function FruitESPSystem.Stop()
    FruitESPSystem.Running = false

    for _, connection in ipairs(FruitESPSystem.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    FruitESPSystem.Connections = {}
    FruitESPSystem.Clear()
end



--=====================================================================================
-- [8.7] PROMO / XP CODE REDEEM SYSTEM
-- Uses ReplicatedStorage.Remotes.Redeem (RemoteFunction) and runs once in background.
--=====================================================================================

CodeSystem.Running = false
CodeSystem.Completed = false
CodeSystem.Remote = nil
CodeSystem.Results = {}
CodeSystem.Attempted = {}

-- Union of codes reported active by current September 2026 lists.
-- If a source is stale or a code was already used, the server simply rejects it.
CodeSystem.Codes = {
    "EASTEREXP",
    "LIGHTNINGABUSE",
    "SUB2CAPTAINMAUI",
    "Enyu_is_Pro",
    "Starcodeheo",
    "Sub2Fer999",
    "Magicbus",
    "JCWK",
    "kittgaming",
    "Bluxxy",
    "SUB2GAMERROBOT_EXP1",
    "Axiore",
    "Sub2Daigrock",
    "Sub2NoobMaster123",
    "StrawHatMaine",
    "TantaiGaming",
    "TheGreatAce",
    "Sub2OfficialNoobie",

    -- Other currently reported rewards / disputed-active codes.
    "KITT_RESET",
    "SUB2GAMERROBOT_RESET1",
    "Sub2UncleKizaru",
    "Bignews",
    "CHANDLER",
    "Fudd10",
    "fudd10_v2",
}

function CodeSystem.ResolveRemote()
    if CodeSystem.Remote and CodeSystem.Remote.Parent then
        return CodeSystem.Remote
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("Redeem")

    if remote and remote:IsA("RemoteFunction") then
        CodeSystem.Remote = remote
        return remote
    end

    -- Future-proof fallback for small naming/layout changes.
    local candidates = {"Redeem", "RedeemCode", "RedeemCodes"}

    for _, name in ipairs(candidates) do
        local found = ReplicatedStorage:FindFirstChild(name, true)
        if found and found:IsA("RemoteFunction") then
            CodeSystem.Remote = found
            return found
        end
    end

    return nil
end

function CodeSystem.Redeem(code)
    code = tostring(code or "")
    if code == "" or CodeSystem.Attempted[code] then
        return false, "skipped"
    end

    local remote = CodeSystem.ResolveRemote()
    if not remote then
        return false, "redeem remote unavailable"
    end

    CodeSystem.Attempted[code] = true

    local ok, response = pcall(function()
        return remote:InvokeServer(code)
    end)

    CodeSystem.Results[code] = {
        Ok = ok,
        Response = response,
    }

    return ok, response
end

function CodeSystem.Run()
    if CodeSystem.Running or CodeSystem.Completed or not Config.AutoRedeemCodes then
        return
    end

    CodeSystem.Running = true

    task.spawn(function()
        task.wait(math.max(0, tonumber(Config.CodeStartDelay) or 2.0))

        local remote = nil
        local deadline = tick() + 10

        repeat
            remote = CodeSystem.ResolveRemote()
            if remote then
                break
            end
            task.wait(0.5)
        until tick() >= deadline or not IsCurrentSession()

        if not remote then
            Logger.warn("CodeSystem: Redeem remote not found")
            CodeSystem.Running = false
            return
        end

        local redeemedCalls = 0

        for _, code in ipairs(CodeSystem.Codes) do
            if not IsCurrentSession() then
                break
            end

            local ok = CodeSystem.Redeem(code)
            if ok then
                redeemedCalls = redeemedCalls + 1
            end

            task.wait(math.max(0.10, tonumber(Config.CodeRedeemDelay) or 0.28))
        end

        CodeSystem.Completed = true
        CodeSystem.Running = false
        Logger.info("CodeSystem: attempted", tostring(#CodeSystem.Codes), "codes; remote calls:", tostring(redeemedCalls))
    end)
end

function CodeSystem.Init()
    if Config.AutoRedeemCodes then
        CodeSystem.Run()
    end
end

--=====================================================================================
-- [9] QUEST DATA SYSTEM
--=====================================================================================

QuestData = {
    StarterIsland = {
        {
            Sea = 1,
            Area = "Starter Island",
            Level = 0,
            Quest = {
                Name = "Bandit",
                QuestGiver = "Bandit Quest Giver",
                QuestIds = {"BanditQuest1"},
                QuestNumber = 1,
                Target = "Bandit",
                Amount = 5,
            },
            NPC = {
                QuestGiver = {"Bandit Quest Giver"},
            },
            Enemy = {
                Names = {"Bandit"},
            },
        },
    },
    Jungle = {
        {
            Sea = 1,
            Area = "Jungle",
            Level = 10,
            Quest = {
                Name = "Monkey",
                QuestGiver = "Adventurer",
                QuestIds = {"JungleQuest"},
                QuestNumber = 1,
                Target = "Monkey",
                Amount = 6,
            },
            NPC = {
                QuestGiver = {"Adventurer"},
            },
            Enemy = {
                Names = {"Monkey"},
            },
        },
        {
            Sea = 1,
            Area = "Jungle",
            Level = 15,
            Quest = {
                Name = "Gorilla",
                QuestGiver = "Adventurer",
                QuestIds = {"JungleQuest"},
                QuestNumber = 2,
                Target = "Gorilla",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"Adventurer"},
            },
            Enemy = {
                Names = {"Gorilla"},
            },
        },
        {
            Sea = 1,
            Area = "Jungle",
            Level = 20,
            Quest = {
                Name = "Gorilla King",
                QuestGiver = "Adventurer",
                QuestIds = {"JungleQuest"},
                QuestNumber = 3,
                Target = "Gorilla King",
                Amount = 1,
            },
            NPC = {
                QuestGiver = {"Adventurer"},
            },
            Boss = {
                Names = {"Gorilla King"},
            },
            Fallbacks = {"Gorilla", "Monkey"},
        },
    },
    PirateVillage = {
        {
            Sea = 1,
            Area = "Pirate Village",
            Level = 30,
            Quest = {
                Name = "Pirate",
                QuestGiver = "Pirate Adventurer",
                QuestIds = {"BuggyQuest1"},
                QuestNumber = 1,
                Target = "Pirate",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"Pirate Adventurer"},
            },
            Enemy = {
                Names = {"Pirate"},
            },
        },
        {
            Sea = 1,
            Area = "Pirate Village",
            Level = 40,
            Quest = {
                Name = "Brute",
                QuestGiver = "Pirate Adventurer",
                QuestIds = {"BuggyQuest1"},
                QuestNumber = 2,
                Target = "Brute",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"Pirate Adventurer"},
            },
            Enemy = {
                Names = {"Brute"},
            },
        },
        {
            Sea = 1,
            Area = "Pirate Village",
            Level = 55,
            Quest = {
                Name = "Chef",
                QuestGiver = "Pirate Adventurer",
                QuestIds = {"BuggyQuest1"},
                QuestNumber = 3,
                Target = "Chef",
                Amount = 1,
                DynamicBoss = true,
            },
            NPC = {
                QuestGiver = {"Pirate Adventurer"},
            },
            Boss = {
                Names = {"Chef"},
            },
        },
    },
    Desert = {
        {
            Sea = 1,
            Area = "Desert",
            Level = 60,
            Quest = {
                Name = "Desert Bandit",
                QuestGiver = "Desert Adventurer",
                QuestIds = {"DesertQuest"},
                QuestNumber = 1,
                Target = "Desert Bandit",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"Desert Adventurer"},
            },
            Enemy = {
                Names = {"Desert Bandit"},
            },
        },
        {
            Sea = 1,
            Area = "Desert",
            Level = 75,
            Quest = {
                Name = "Desert Officer",
                QuestGiver = "Desert Adventurer",
                QuestIds = {"DesertQuest"},
                QuestNumber = 2,
                Target = "Desert Officer",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"Desert Adventurer"},
            },
            Enemy = {
                Names = {"Desert Officer"},
            },
        },
    },
    Snow = {
        {
            Sea = 1,
            Area = "Frozen Village",
            Level = 90,
            Quest = {
                Name = "Snow Bandit",
                QuestGiver = "Villager",
                QuestIds = {"SnowQuest"},
                QuestNumber = 1,
                Target = "Snow Bandit",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"Villager"},
            },
            Enemy = {
                Names = {"Snow Bandit"},
            },
        },
        {
            Sea = 1,
            Area = "Frozen Village",
            Level = 100,
            Quest = {
                Name = "Snowman",
                QuestGiver = "Villager",
                QuestIds = {"SnowQuest"},
                QuestNumber = 2,
                Target = "Snowman",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"Villager"},
            },
            Enemy = {
                Names = {"Snowman"},
            },
        },
        {
            Sea = 1,
            Area = "Frozen Village",
            Level = 105,
            Quest = {
                Name = "Yeti",
                QuestGiver = "Villager",
                QuestIds = {"SnowQuest"},
                QuestNumber = 3,
                Target = "Yeti",
                Amount = 1,
            },
            NPC = {
                QuestGiver = {"Villager"},
            },
            Boss = {
                Names = {"Yeti"},
            },
            Fallbacks = {"Snowman", "Snow Bandit"},
        },
    },
    MarineFortress = {
        {
            Sea = 1,
            Area = "Marine Fortress",
            Level = 120,
            Quest = {
                Name = "Chief Petty Officer",
                QuestGiver = "Marine",
                QuestIds = {"MarineQuest2"},
                QuestNumber = 1,
                Target = "Chief Petty Officer",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"Marine"},
            },
            Enemy = {
                Names = {"Chief Petty Officer"},
            },
        },
        {
            Sea = 1,
            Area = "Marine Fortress",
            Level = 130,
            Quest = {
                Name = "Vice Admiral",
                QuestGiver = "Marine",
                QuestIds = {"MarineQuest2"},
                QuestNumber = 2,
                Target = "Vice Admiral",
                Amount = 1,
            },
            NPC = {
                QuestGiver = {"Marine"},
            },
            Boss = {
                Names = {"Vice Admiral"},
            },
            Fallbacks = {"Chief Petty Officer"},
        },
    },
    Skylands = {
        {
            Sea = 1,
            Area = "Lower Skylands",
            Level = 150,
            Quest = {
                Name = "Sky Bandit",
                QuestGiver = "Sky Adventurer",
                QuestIds = {"SkyQuest", "SkyBanditQuest"},
                QuestNumber = 1,
                Target = "Sky Bandit",
                Amount = 7,
            },
            NPC = {
                QuestGiver = {"Sky Adventurer", "Sky Quest Giver"},
            },
            Enemy = {
                Names = {"Sky Bandit"},
            },
        },
        {
            Sea = 1,
            Area = "Lower Skylands",
            Level = 175,
            Quest = {
                Name = "Dark Master",
                QuestGiver = "Sky Adventurer",
                QuestIds = {"SkyQuest", "DarkMasterQuest"},
                QuestNumber = 2,
                Target = "Dark Master",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"Sky Adventurer", "Sky Quest Giver"},
            },
            Enemy = {
                Names = {"Dark Master"},
            },
        },
    },
    Prison = {
        {
            Sea = 1,
            Area = "Prison",
            Level = 190,
            Quest = {
                Name = "Prisoner",
                QuestGiver = "Jail Keeper",
                QuestIds = {"PrisonerQuest"},
                QuestNumber = 1,
                Target = "Prisoner",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"Jail Keeper"},
            },
            Enemy = {
                Names = {"Prisoner"},
            },
        },
        {
            Sea = 1,
            Area = "Prison",
            Level = 210,
            Quest = {
                Name = "Dangerous Prisoner",
                QuestGiver = "Jail Keeper",
                QuestIds = {"PrisonerQuest"},
                QuestNumber = 2,
                Target = "Dangerous Prisoner",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"Jail Keeper"},
            },
            Enemy = {
                Names = {"Dangerous Prisoner"},
            },
        },
        {
            Sea = 1,
            Area = "Prison",
            Level = 225,
            Quest = {
                Name = "Ruthless Prisoner",
                QuestGiver = "Head Jailer",
                QuestIds = {"PrisonQuest"},
                QuestNumber = 3,
                Target = "Ruthless Prisoner",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"Head Jailer"},
            },
            Enemy = {
                Names = {"Ruthless Prisoner", "Dangerous Prisoner"},
            },
        },
        {
            Sea = 1,
            Area = "Prison",
            Level = 230,
            Quest = {
                Name = "Warden",
                QuestGiver = "Head Jailer",
                QuestIds = {"ImpelQuest"},
                QuestNumber = 1,
                Target = "Warden",
                Amount = 1,
            },
            NPC = {
                QuestGiver = {"Head Jailer"},
            },
            Boss = {
                Names = {"Warden"},
            },
            SideBoss = true,
        },
    },
    Colosseum = {
        {
            Sea = 1,
            Area = "Colosseum",
            Level = 250,
            Quest = {
                Name = "Toga Warrior",
                QuestGiver = "Colosseum Quest Giver",
                QuestIds = {"ColosseumQuest"},
                QuestNumber = 1,
                Target = "Toga Warrior",
                Amount = 7,
            },
            NPC = {
                QuestGiver = {"Colosseum Quest Giver"},
            },
            Enemy = {
                Names = {"Toga Warrior"},
            },
        },
        {
            Sea = 1,
            Area = "Colosseum",
            Level = 275,
            Quest = {
                Name = "Gladiator",
                QuestGiver = "Colosseum Quest Giver",
                QuestIds = {"ColosseumQuest"},
                QuestNumber = 2,
                Target = "Gladiator",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"Colosseum Quest Giver"},
            },
            Enemy = {
                Names = {"Gladiator"},
            },
        },
    },
    MagmaVillage = {
        {
            Sea = 1,
            Area = "Magma Village",
            Level = 300,
            Quest = {
                Name = "Military Soldier",
                QuestGiver = "The Mayor",
                QuestIds = {"MagmaQuest"},
                QuestNumber = 1,
                Target = "Military Soldier",
                Amount = 7,
            },
            NPC = {
                QuestGiver = {"The Mayor"},
            },
            Enemy = {
                Names = {"Military Soldier"},
            },
        },
        {
            Sea = 1,
            Area = "Magma Village",
            Level = 325,
            Quest = {
                Name = "Military Spy",
                QuestGiver = "The Mayor",
                QuestIds = {"MagmaQuest"},
                QuestNumber = 2,
                Target = "Military Spy",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"The Mayor"},
            },
            Enemy = {
                Names = {"Military Spy"},
            },
        },
        {
            Sea = 1,
            Area = "Magma Village",
            Level = 350,
            Quest = {
                Name = "Magma General",
                QuestGiver = "The Mayor",
                QuestIds = {"MagmaQuest"},
                QuestNumber = 3,
                Target = "Magma General",
                Amount = 1,
            },
            NPC = {
                QuestGiver = {"The Mayor"},
            },
            Boss = {
                Names = {"Magma General", "Magma Admiral"},
            },
            Fallbacks = {"Magma General", "Magma Admiral", "Military Spy", "Military Soldier"},
        },
    },
    FishmanIsland = {
        {
            Sea = 1,
            Area = "Fishman Island",
            Level = 375,
            Quest = {
                Name = "Fishman Warrior",
                QuestGiver = "King Neptune",
                QuestIds = {"FishmanQuest"},
                QuestNumber = 1,
                Target = "Fishman Warrior",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"King Neptune"},
            },
            Enemy = {
                Names = {"Fishman Warrior"},
            },
        },
        {
            Sea = 1,
            Area = "Fishman Island",
            Level = 400,
            Quest = {
                Name = "Fishman Commando",
                QuestGiver = "King Neptune",
                QuestIds = {"FishmanQuest"},
                QuestNumber = 2,
                Target = "Fishman Commando",
                Amount = 7,
            },
            NPC = {
                QuestGiver = {"King Neptune"},
            },
            Enemy = {
                Names = {"Fishman Commando"},
            },
        },
        {
            Sea = 1,
            Area = "Fishman Island",
            Level = 425,
            Quest = {
                Name = "Fishman Lord",
                QuestGiver = "King Neptune",
                QuestIds = {"FishmanQuest"},
                QuestNumber = 3,
                Target = "Fishman Lord",
                Amount = 1,
            },
            NPC = {
                QuestGiver = {"King Neptune"},
            },
            Boss = {
                Names = {"Fishman Lord"},
            },
            Fallbacks = {"Fishman Commando", "Fishman Warrior"},
        },
    },
    UpperSkylands = {
        {
            Sea = 1,
            Area = "Upper Skylands",
            Level = 450,
            Quest = {
                Name = "God's Guard",
                QuestGiver = "Mole",
                QuestIds = {"SkyExp1Quest", "GodsGuardQuest"},
                QuestNumber = 1,
                Target = "God's Guard",
                Amount = 7,
            },
            NPC = {
                QuestGiver = {"Mole"},
            },
            Enemy = {
                Names = {"God's Guard", "Gods Guard"},
            },
        },
        {
            Sea = 1,
            Area = "Upper Skylands",
            Level = 475,
            Quest = {
                Name = "Shanda",
                QuestGiver = "Mole",
                QuestIds = {"SkyExp1Quest", "ShandaQuest"},
                QuestNumber = 2,
                Target = "Shanda",
                Amount = 9,
            },
            NPC = {
                QuestGiver = {"Mole"},
            },
            Enemy = {
                Names = {"Shanda"},
            },
        },
        {
            Sea = 1,
            Area = "Upper Skylands",
            Level = 500,
            Quest = {
                Name = "Sky Warlord",
                QuestGiver = "Mole",
                QuestIds = {"SkyExp1Quest", "WysperQuest", "SkyWarlordQuest"},
                QuestNumber = 3,
                Target = "Sky Warlord",
                Amount = 1,
            },
            NPC = {
                QuestGiver = {"Mole"},
            },
            Boss = {
                Names = {"Sky Warlord", "Wysper"},
            },
            Fallbacks = {"Shanda", "God's Guard"},
        },
        {
            Sea = 1,
            Area = "Upper Skylands",
            Level = 525,
            Quest = {
                Name = "Royal Squad",
                QuestGiver = "Sky Quest Giver 2",
                QuestIds = {"SkyExp2Quest", "RoyalSquadQuest"},
                QuestNumber = 1,
                Target = "Royal Squad",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"Sky Quest Giver 2", "Gan Fall Adventurer"},
            },
            Enemy = {
                Names = {"Royal Squad"},
            },
        },
        {
            Sea = 1,
            Area = "Upper Skylands",
            Level = 550,
            Quest = {
                Name = "Royal Soldier",
                QuestGiver = "Sky Quest Giver 2",
                QuestIds = {"SkyExp2Quest", "RoyalSoldierQuest"},
                QuestNumber = 2,
                Target = "Royal Soldier",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"Sky Quest Giver 2", "Gan Fall Adventurer"},
            },
            Enemy = {
                Names = {"Royal Soldier"},
            },
        },
        {
            Sea = 1,
            Area = "Upper Skylands",
            Level = 575,
            Quest = {
                Name = "Lightning God",
                QuestGiver = "Sky Quest Giver 2",
                QuestIds = {"SkyExp2Quest", "ThunderGodQuest", "LightningGodQuest"},
                QuestNumber = 3,
                Target = "Lightning God",
                Amount = 1,
            },
            NPC = {
                QuestGiver = {"Sky Quest Giver 2", "Gan Fall Adventurer"},
            },
            Boss = {
                Names = {"Lightning God", "Thunder God"},
            },
            Fallbacks = {"Lightning God", "Thunder God", "Royal Soldier", "Royal Squad"},
        },
    },
    FountainCity = {
        {
            Sea = 1,
            Area = "Fountain City",
            Level = 625,
            Quest = {
                Name = "Galley Pirate",
                QuestGiver = "Freezeburg Quest Giver",
                QuestIds = {"FountainQuest"},
                QuestNumber = 1,
                Target = "Galley Pirate",
                Amount = 8,
            },
            NPC = {
                QuestGiver = {"Freezeburg Quest Giver"},
            },
            Enemy = {
                Names = {"Galley Pirate"},
            },
        },
        {
            Sea = 1,
            Area = "Fountain City",
            Level = 650,
            Quest = {
                Name = "Galley Captain",
                QuestGiver = "Freezeburg Quest Giver",
                QuestIds = {"FountainQuest"},
                QuestNumber = 2,
                Target = "Galley Captain",
                Amount = 9,
            },
            NPC = {
                QuestGiver = {"Freezeburg Quest Giver"},
            },
            Enemy = {
                Names = {"Galley Captain"},
            },
        },
        {
            Sea = 1,
            Area = "Fountain City",
            Level = 675,
            Quest = {
                Name = "Cyborg",
                QuestGiver = "Freezeburg Quest Giver",
                QuestIds = {"FountainQuest"},
                QuestNumber = 3,
                Target = "Cyborg",
                Amount = 1,
            },
            NPC = {
                QuestGiver = {"Freezeburg Quest Giver"},
            },
            Boss = {
                Names = {"Cyborg"},
            },
            Fallbacks = {"Galley Captain", "Galley Pirate"},
        },
    },

    -- Second Sea progression. These entries are static fallbacks; when the
    -- game's GuideModule/Quests modules are available, the dynamic resolver
    -- remains authoritative.
    KingdomOfRoseArea1 = {
        {
            Sea = 2,
            Area = "Kingdom of Rose - Area 1",
            Level = 700,
            Quest = {Name="Raider", QuestGiver="Area 1 Quest Giver", QuestIds={"Area1Quest"}, QuestNumber=1, Target="Raider", Amount=8},
            NPC = {QuestGiver={"Area 1 Quest Giver"}},
            Enemy = {Names={"Raider"}},
        },
        {
            Sea = 2,
            Area = "Kingdom of Rose - Area 1",
            Level = 725,
            Quest = {Name="Mercenary", QuestGiver="Area 1 Quest Giver", QuestIds={"Area1Quest"}, QuestNumber=2, Target="Mercenary", Amount=8},
            NPC = {QuestGiver={"Area 1 Quest Giver"}},
            Enemy = {Names={"Mercenary"}},
        },
        {
            Sea = 2,
            Area = "Kingdom of Rose - Area 1",
            Level = 750,
            Quest = {Name="Diamond", QuestGiver="Area 1 Quest Giver", QuestIds={"Area1Quest"}, QuestNumber=3, Target="Diamond", Amount=1},
            NPC = {QuestGiver={"Area 1 Quest Giver"}},
            Boss = {Names={"Diamond"}},
            Fallbacks = {"Mercenary", "Raider"},
        },
    },
    KingdomOfRoseArea2 = {
        {
            Sea = 2,
            Area = "Kingdom of Rose - Area 2",
            Level = 775,
            Quest = {Name="Swan Pirate", QuestGiver="Area 2 Quest Giver", QuestIds={"Area2Quest"}, QuestNumber=1, Target="Swan Pirate", Amount=8},
            NPC = {QuestGiver={"Area 2 Quest Giver"}},
            Enemy = {Names={"Swan Pirate"}},
        },
        {
            Sea = 2,
            Area = "Kingdom of Rose - Area 2",
            Level = 800,
            Quest = {Name="Factory Staff", QuestGiver="Area 2 Quest Giver", QuestIds={"Area2Quest"}, QuestNumber=2, Target="Factory Staff", Amount=8},
            NPC = {QuestGiver={"Area 2 Quest Giver"}},
            Enemy = {Names={"Factory Staff"}},
        },
        {
            Sea = 2,
            Area = "Kingdom of Rose - Area 2",
            Level = 850,
            Quest = {Name="Jeremy", QuestGiver="Area 2 Quest Giver", QuestIds={"Area2Quest"}, QuestNumber=3, Target="Jeremy", Amount=1},
            NPC = {QuestGiver={"Area 2 Quest Giver"}},
            Boss = {Names={"Jeremy"}},
            Fallbacks = {"Factory Staff", "Swan Pirate"},
        },
    },
    GreenZone = {
        {
            Sea = 2,
            Area = "Green Zone",
            Level = 875,
            Quest = {Name="Marine Lieutenant", QuestGiver="Marine Quest Giver", QuestIds={"MarineQuest3"}, QuestNumber=1, Target="Marine Lieutenant", Amount=8},
            NPC = {QuestGiver={"Marine Quest Giver"}},
            Enemy = {Names={"Marine Lieutenant"}},
        },
        {
            Sea = 2,
            Area = "Green Zone",
            Level = 900,
            Quest = {Name="Marine Captain", QuestGiver="Marine Quest Giver", QuestIds={"MarineQuest3"}, QuestNumber=2, Target="Marine Captain", Amount=9},
            NPC = {QuestGiver={"Marine Quest Giver"}},
            Enemy = {Names={"Marine Captain"}},
        },
        {
            Sea = 2,
            Area = "Green Zone",
            Level = 925,
            Quest = {Name="Fajita", QuestGiver="Marine Quest Giver", QuestIds={"MarineQuest3"}, QuestNumber=3, Target="Fajita", Amount=1},
            NPC = {QuestGiver={"Marine Quest Giver"}},
            Boss = {Names={"Fajita"}},
            Fallbacks = {"Marine Captain", "Marine Lieutenant"},
        },
    },
    Graveyard = {
        {
            Sea = 2,
            Area = "Graveyard",
            Level = 950,
            Quest = {Name="Zombie", QuestGiver="Graveyard Quest Giver", QuestIds={"ZombieQuest"}, QuestNumber=1, Target="Zombie", Amount=8},
            NPC = {QuestGiver={"Graveyard Quest Giver"}},
            Enemy = {Names={"Zombie"}},
        },
        {
            Sea = 2,
            Area = "Graveyard",
            Level = 975,
            Quest = {Name="Vampire", QuestGiver="Graveyard Quest Giver", QuestIds={"ZombieQuest"}, QuestNumber=2, Target="Vampire", Amount=8},
            NPC = {QuestGiver={"Graveyard Quest Giver"}},
            Enemy = {Names={"Vampire"}},
        },
    },
    SnowMountain = {
        {
            Sea = 2,
            Area = "Snow Mountain",
            Level = 1000,
            Quest = {Name="Snow Trooper", QuestGiver="Snow Quest Giver", QuestIds={"SnowMountainQuest"}, QuestNumber=1, Target="Snow Trooper", Amount=8},
            NPC = {QuestGiver={"Snow Quest Giver"}},
            Enemy = {Names={"Snow Trooper"}},
        },
        {
            Sea = 2,
            Area = "Snow Mountain",
            Level = 1050,
            Quest = {Name="Winter Warrior", QuestGiver="Snow Quest Giver", QuestIds={"SnowMountainQuest"}, QuestNumber=2, Target="Winter Warrior", Amount=9},
            NPC = {QuestGiver={"Snow Quest Giver"}},
            Enemy = {Names={"Winter Warrior"}},
        },
    },
    HotAndColdIce = {
        {
            Sea = 2,
            Area = "Hot and Cold - Ice",
            Level = 1100,
            Quest = {Name="Lab Subordinate", QuestGiver="Ice Quest Giver", QuestIds={"IceSideQuest"}, QuestNumber=1, Target="Lab Subordinate", Amount=8},
            NPC = {QuestGiver={"Ice Quest Giver"}},
            Enemy = {Names={"Lab Subordinate"}},
        },
        {
            Sea = 2,
            Area = "Hot and Cold - Ice",
            Level = 1125,
            Quest = {Name="Horned Warrior", QuestGiver="Ice Quest Giver", QuestIds={"IceSideQuest"}, QuestNumber=2, Target="Horned Warrior", Amount=9},
            NPC = {QuestGiver={"Ice Quest Giver"}},
            Enemy = {Names={"Horned Warrior"}},
        },
        {
            Sea = 2,
            Area = "Hot and Cold - Ice",
            Level = 1150,
            Quest = {Name="Smoke Admiral", QuestGiver="Ice Quest Giver", QuestIds={"IceSideQuest"}, QuestNumber=3, Target="Smoke Admiral", Amount=1},
            NPC = {QuestGiver={"Ice Quest Giver"}},
            Boss = {Names={"Smoke Admiral"}},
            Fallbacks = {"Horned Warrior", "Lab Subordinate"},
        },
    },
    HotAndColdFire = {
        {
            Sea = 2,
            Area = "Hot and Cold - Fire",
            Level = 1175,
            Quest = {Name="Magma Ninja", QuestGiver="Fire Quest Giver", QuestIds={"FireSideQuest"}, QuestNumber=1, Target="Magma Ninja", Amount=8},
            NPC = {QuestGiver={"Fire Quest Giver"}},
            Enemy = {Names={"Magma Ninja"}},
        },
        {
            Sea = 2,
            Area = "Hot and Cold - Fire",
            Level = 1200,
            Quest = {Name="Lava Pirate", QuestGiver="Fire Quest Giver", QuestIds={"FireSideQuest"}, QuestNumber=2, Target="Lava Pirate", Amount=8},
            NPC = {QuestGiver={"Fire Quest Giver"}},
            Enemy = {Names={"Lava Pirate"}},
        },
    },
}

-- Quest data functions
local function FindInstanceByNames(root, names)
    if not root or not names then
        return nil
    end

    for _, name in ipairs(names) do
        local found = root:FindFirstChild(name, true)
        if found then
            return found
        end
    end

    return nil
end


local function GetInstanceCFrameSafe(instance)
    if not instance then
        return nil
    end

    local ok, cf = pcall(function()
        if instance:IsA("BasePart") then
            return instance.CFrame
        elseif instance:IsA("Attachment") then
            return instance.WorldCFrame
        elseif instance:IsA("Model") then
            local root = instance:FindFirstChild("HumanoidRootPart") or instance.PrimaryPart
            if root and root:IsA("BasePart") then
                return root.CFrame
            end
            return instance:GetPivot()
        end
        return nil
    end)

    if ok and typeof(cf) == "CFrame" then
        return cf
    end
    return nil
end

function QuestData.FindQuestGiver(quest)
    if not quest or not quest.NPC then
        return nil
    end
    return FindInstanceByNames(workspace, quest.NPC.QuestGiver)
end

function QuestData.FindEnemy(quest)
    if not quest or not quest.Enemy then
        return nil
    end
    return FindInstanceByNames(workspace, quest.Enemy.Names)
end

function QuestData.FindBoss(quest)
    if not quest or not quest.Boss then
        return nil
    end
    return FindInstanceByNames(workspace, quest.Boss.Names)
end

function QuestData.GetQuestByLevel(level)
    if not level then
        return nil
    end

    local allQuests = {}
    for _, area in pairs(QuestData) do
        if type(area) == "table" and area[1] then
            for _, quest in ipairs(area) do
                table.insert(allQuests, quest)
            end
        end
    end

    local selected = nil
    for i, quest in ipairs(allQuests) do
        if level >= quest.Level then
            selected = quest
        else
            break
        end
    end

    return selected
end

function QuestData.GetByName(name)
    if not name then
        return nil
    end

    for _, area in pairs(QuestData) do
        if type(area) == "table" and area[1] then
            for _, quest in ipairs(area) do
                if quest.Quest.Name == name or quest.Quest.Target == name then
                    return quest
                end
            end
        end
    end

    return nil
end

function QuestData.IsBoss(quest)
    return quest and quest.Boss ~= nil
end

function QuestData.GetQuestPosition(quest)
    local npc = QuestData.FindQuestGiver(quest)
    if npc then
        local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
        if root then
            return root.CFrame
        end
    end
    return nil
end

function QuestData.GetEnemyPosition(quest)
    local enemy = QuestData.FindEnemy(quest)
    if enemy then
        local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
        if root then
            return root.CFrame
        end
    end
    return nil
end

function QuestData.GetBossPosition(quest)
    local boss = QuestData.FindBoss(quest)
    if boss then
        local root = boss:FindFirstChild("HumanoidRootPart") or boss.PrimaryPart
        if root then
            return root.CFrame
        end
    end
    return nil
end

-- Convert to legacy format
function QuestData.ToLegacyFormat()
    local legacy = {}
    
    local staticCFrames = {
        ["Bandit"] = CFrame.new(1059, 17, 1546),
        ["Monkey"] = CFrame.new(-1598, 37, 153),
        ["Gorilla"] = CFrame.new(-1598, 37, 153),
        ["Gorilla King"] = CFrame.new(-1598, 37, 153),
        ["Pirate"] = CFrame.new(-1140, 4, 3829),
        ["Brute"] = CFrame.new(-1140, 4, 3829),
        ["Chef"] = CFrame.new(-1140, 4, 3829),
        ["Desert Bandit"] = CFrame.new(897, 6, 4389),
        ["Desert Officer"] = CFrame.new(897, 6, 4389),
        ["Snow Bandit"] = CFrame.new(1385, 87, -1298),
        ["Snowman"] = CFrame.new(1385, 87, -1298),
        ["Yeti"] = CFrame.new(1385, 87, -1298),
        ["Chief Petty Officer"] = CFrame.new(-5035, 29, 4326),
        ["Vice Admiral"] = CFrame.new(-5035, 29, 4326),
        ["Prisoner"] = CFrame.new(5306, 2, 477),
        ["Dangerous Prisoner"] = CFrame.new(5306, 2, 477),
        ["Ruthless Prisoner"] = CFrame.new(5191, 4, 692),
        ["Warden"] = CFrame.new(5191, 4, 692),
        ["Toga Warrior"] = CFrame.new(-1581, 7, -2982),
        ["Gladiator"] = CFrame.new(-1581, 7, -2982),
        ["Military Soldier"] = CFrame.new(-5319, 12, 8515),
        ["Military Spy"] = CFrame.new(-5319, 12, 8515),
        ["Magma General"] = CFrame.new(-5319, 12, 8515),
        ["Fishman Warrior"] = CFrame.new(61122, 18, 1567),
        ["Fishman Commando"] = CFrame.new(61122, 18, 1567),
        ["Fishman Lord"] = CFrame.new(61122, 18, 1567),
        ["God's Guard"] = CFrame.new(-4720, 846, -1951),
        ["Shanda"] = CFrame.new(-7861, 5545, -381),
        ["Sky Warlord"] = CFrame.new(-7861, 5545, -381),
        ["Royal Squad"] = CFrame.new(-7903, 5636, -1412),
        ["Royal Soldier"] = CFrame.new(-7903, 5636, -1412),
        ["Lightning God"] = CFrame.new(-7903, 5636, -1412),
        ["Galley Pirate"] = CFrame.new(5258, 39, 4052),
        ["Galley Captain"] = CFrame.new(5258, 39, 4052),
        ["Cyborg"] = CFrame.new(5258, 39, 4052),

        -- Second Sea quest givers
        ["Raider"] = CFrame.new(-427, 73, 1835),
        ["Mercenary"] = CFrame.new(-427, 73, 1835),
        ["Diamond"] = CFrame.new(-427, 73, 1835),
        ["Swan Pirate"] = CFrame.new(635, 73, 919),
        ["Factory Staff"] = CFrame.new(635, 73, 919),
        ["Jeremy"] = CFrame.new(635, 73, 919),
        ["Marine Lieutenant"] = CFrame.new(-2441, 73, -3219),
        ["Marine Captain"] = CFrame.new(-2441, 73, -3219),
        ["Fajita"] = CFrame.new(-2441, 73, -3219),
        ["Zombie"] = CFrame.new(-5495, 48, -794),
        ["Vampire"] = CFrame.new(-5495, 48, -794),
        ["Snow Trooper"] = CFrame.new(607, 401, -5371),
        ["Winter Warrior"] = CFrame.new(607, 401, -5371),
        ["Lab Subordinate"] = CFrame.new(-6061, 16, -4904),
        ["Horned Warrior"] = CFrame.new(-6061, 16, -4904),
        ["Smoke Admiral"] = CFrame.new(-6061, 16, -4904),
        ["Magma Ninja"] = CFrame.new(-5430, 16, -5298),
        ["Lava Pirate"] = CFrame.new(-5430, 16, -5298),
    }
    
    for _, area in pairs(QuestData) do
        if type(area) == "table" and area[1] then
            for _, quest in ipairs(area) do
                local entry = {
                    Sea = quest.Sea or 1,
                    Min = quest.Level,
                    Max = quest.Level + 9,
                    Quest = quest.Quest.QuestIds[1],
                    Num = quest.Quest.QuestNumber,
                    Mob = quest.Quest.Target,
                    Required = quest.Quest.Amount,
                    Giver = quest.NPC.QuestGiver,
                    GiverCFrame = staticCFrames[quest.Quest.Target] or nil,
                    FarmCFrame = nil,
                }

                if quest.Boss then
                    entry.Boss = true
                    entry.Fallbacks = quest.Fallbacks
                    -- Preserve the live-name aliases from the modern quest table.
                    -- Example: current servers can expose "Magma Admiral" while
                    -- the static quest target is still named "Magma General".
                    entry.BossNames = quest.Boss.Names
                end

                if quest.SideBoss then
                    entry.SideBoss = true
                end

                if quest.Quest.DynamicBoss then
                    entry.DynamicBoss = true
                end

                table.insert(legacy, entry)
            end
        end
    end
    return legacy
end

--=====================================================================================
-- EXPANDED SYSTEMS FROM KRATOS ORIGINAL
--=====================================================================================

--=====================================================================================
-- [26] MELEE SYSTEM (Black Leg, Fighting Styles)
--=====================================================================================

MeleeSystem.Last = 0
MeleeSystem.Done = {}
MeleeSystem.BlackLegAtVillage = false
MeleeSystem.OwnershipLastCheck = 0
MeleeSystem.OwnershipCheckDelay = 2.5
MeleeSystem.IsBuying = false
MeleeSystem.LastTick = 0
MeleeSystem.LastBuyAttempt = 0
MeleeSystem.ActiveStyleName = nil
MeleeSystem.ActiveStyleMastery = 0
MeleeSystem.PendingStyleName = nil
MeleeSystem.PurchaseInFlight = false
MeleeSystem.LastPurchaseResult = nil
MeleeSystem.AllCurrentStylesDone = false

MeleeSystem.PurchaseMode = nil
MeleeSystem.PurchaseStyle = nil
MeleeSystem.ReturnCFrame = nil
MeleeSystem.PurchaseTripStartedAt = 0
MeleeSystem.PurchaseAttempts = 0

-- Progression adapted from REDZ HUB V2's Auto Mastery Fighting Style logic.
-- The controller never steals movement from Farm Level: it buys through the
-- game's remotes, equips the selected style, and lets the normal level farm
-- provide the mastery XP.
local Melees = {
    -- Sea 1
    {Name="Black Leg",       BuyID="BuyBlackLeg",        MinSea=1, Beli=150000, Teacher="Dark Step Teacher", TeacherCFrame=CFrame.new(-1122.34998, 14.78709, 3855.91992)},
    {Name="Electro",         BuyID="BuyElectro",          MinSea=1, Beli=500000},
    {Name="Fishman Karate",  BuyID="BuyFishmanKarate",    MinSea=2, Beli=750000},

    -- Sea 2+
    {Name="Dragon Claw",     BuyID="DragonClaw",          MinSea=2, Special="DragonClaw"},
    {Name="Superhuman",      BuyID="BuySuperhuman",       MinSea=2},

    -- Advanced styles. Their buy remotes are attempted only after their
    -- prerequisite base style has reached the configured mastery target.
    {Name="Death Step",      BuyID="BuyDeathStep",        MinSea=2, Prereq="Black Leg"},
    {Name="Sharkman Karate", BuyID="BuySharkmanKarate",   MinSea=2, Prereq="Fishman Karate"},
    {Name="Electric Claw",   BuyID="BuyElectricClaw",     MinSea=3, Prereq="Electro"},
    {Name="Dragon Talon",    BuyID="BuyDragonTalon",      MinSea=3, Prereq="Dragon Claw"},

    -- End-game style. The remote itself validates the additional materials.
    {Name="Godhuman",        BuyID="BuyGodhuman",         MinSea=3},
}

function MeleeSystem.GetSea()
    local id = game.PlaceId
    if id == 2753915549 or id == 85211729168715 then
        return 1
    elseif id == 4442272183 or id == 79091703265657 then
        return 2
    elseif id == 7449423635 or id == 100117331123089 then
        return 3
    end
    return 1
end

MeleeSystem.StyleAliases = {
    ["Black Leg"] = {"Black Leg", "Dark Step"},
    ["Dark Step"] = {"Dark Step", "Black Leg"},
}

function MeleeSystem.GetStyleAliases(styleName)
    return MeleeSystem.StyleAliases[styleName] or {styleName}
end

function MeleeSystem.GetTool(styleName)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = Utils.Character()

    for _, alias in ipairs(MeleeSystem.GetStyleAliases(styleName)) do
        if char then
            local tool = char:FindFirstChild(alias)
            if tool and tool:IsA("Tool") then
                return tool
            end
        end

        if backpack then
            local tool = backpack:FindFirstChild(alias)
            if tool and tool:IsA("Tool") then
                return tool
            end
        end
    end
    return nil
end

function MeleeSystem.EquipStyle(styleName)
    local tool = MeleeSystem.GetTool(styleName)
    local hum = Utils.Humanoid()
    if not tool or not hum then
        return false
    end

    pcall(function()
        hum:EquipTool(tool)
    end)

    Utils.LastEquippedWeapon = tool.Name
    Utils.LastMeleeEquipAt = 0
    return true
end

function MeleeSystem.IsOwned(styleName)
    return MeleeSystem.GetTool(styleName) ~= nil
end

function MeleeSystem.GetMastery(styleName)
    local tool = MeleeSystem.GetTool(styleName)
    if not tool then
        return 0
    end

    local level = tool:FindFirstChild("Level")
    if level and tonumber(level.Value) then
        return tonumber(level.Value) or 0
    end

    local mastery = tool:FindFirstChild("Mastery")
    if mastery and tonumber(mastery.Value) then
        return tonumber(mastery.Value) or 0
    end

    local attr = tool:GetAttribute("Level") or tool:GetAttribute("Mastery")
    return tonumber(attr) or 0
end

function MeleeSystem.GetStyleData(styleName)
    for _, style in ipairs(Melees) do
        if style.Name == styleName then
            return style
        end
    end
    return nil
end

function MeleeSystem.PrerequisiteReady(style)
    if not style or not style.Prereq then
        return true
    end

    local target = tonumber(Config.FightingStyleMasteryTarget) or 400
    return MeleeSystem.GetMastery(style.Prereq) >= target
end

function MeleeSystem.BuyRemote(style)
    if not style or not CommF_ then
        return false
    end

    local now = tick()
    if now - (MeleeSystem.LastBuyAttempt or 0) < (tonumber(Config.FightingStyleBuyInterval) or 2.0) then
        return false
    end
    MeleeSystem.LastBuyAttempt = now

    if style.Beli and UI.GetBeli() < style.Beli then
        return false
    end

    local ok = pcall(function()
        if style.Special == "DragonClaw" then
            -- Same two-step pattern used by REDZ.
            CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "1")
            CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "2")
        else
            -- REDZ BuyFightStyle pattern: query first, then purchase.
            pcall(function()
                CommF_:InvokeServer(style.BuyID, true)
            end)
            CommF_:InvokeServer(style.BuyID)
        end
    end)

    if not ok then
        return false
    end

    -- Do not trust a successful pcall as proof of purchase.
    -- The game may reject it for money/fragments/prerequisites.
    task.wait(0.12)
    return MeleeSystem.IsOwned(style.Name)
end

function MeleeSystem.GetTrainingStyle()
    local target = tonumber(Config.FightingStyleMasteryTarget) or 400
    local currentSea = MeleeSystem.GetSea()

    for _, style in ipairs(Melees) do
        if style.MinSea <= currentSea then
            local owned = MeleeSystem.IsOwned(style.Name)
            local mastery = owned and MeleeSystem.GetMastery(style.Name) or 0

            if owned and mastery < target then
                return style, mastery, "train"
            end

            if not owned and MeleeSystem.PrerequisiteReady(style) then
                return style, 0, "buy"
            end
        end
    end

    return nil, target, "done"
end


MeleeSystem.TeacherCache = nil
MeleeSystem.TeacherCacheAt = 0

function MeleeSystem.FindTeacher(style)
    if not style then
        return nil
    end

    local now = tick()
    if MeleeSystem.TeacherCache
        and now - (MeleeSystem.TeacherCacheAt or 0) < 2.0 then
        return MeleeSystem.TeacherCache
    end

    local wanted = {}
    if style.Teacher then
        wanted[string.lower(style.Teacher)] = true
    end
    if style.Name == "Black Leg" then
        wanted["dark step teacher"] = true
        wanted["black leg teacher"] = true
    end

    local function scan(root)
        if not root then
            return nil
        end

        for _, npc in ipairs(root:GetDescendants()) do
            local name = string.lower(tostring(npc.Name or ""))
            if wanted[name]
                or (style.Name == "Black Leg" and string.find(name, "dark step", 1, true)) then
                local cf = GetInstanceCFrameSafe(npc)
                if cf then
                    return cf
                end
            end
        end
        return nil
    end

    local found = scan(workspace:FindFirstChild("NPCs"))
    if not found then
        found = scan(workspace)
    end
    if not found and style.TeacherCFrame and typeof(style.TeacherCFrame) == "CFrame" then
        found = style.TeacherCFrame
    end

    if found then
        MeleeSystem.TeacherCache = found
        MeleeSystem.TeacherCacheAt = now
    end
    return found
end

function MeleeSystem.StartPurchaseTrip(style)
    if not style or MeleeSystem.PurchaseMode then
        return false
    end

    local hrp = Utils.HRP()
    if not hrp then
        return false
    end

    MeleeSystem.PurchaseStyle = style
    MeleeSystem.PendingStyleName = style.Name
    MeleeSystem.ReturnCFrame = hrp.CFrame
    MeleeSystem.PurchaseMode = "TO_TEACHER"
    MeleeSystem.PurchaseTripStartedAt = tick()
    MeleeSystem.PurchaseAttempts = 0
    MeleeSystem.PurchaseBeliBefore = UI.GetBeli()

    Combat.CurrentTarget = nil
    Combat.ResetAnchor()
    Teleport.Cancel()

    Teleport.ExclusiveOwner = "MELEE"
    SafetySystem.IgnoreUntil = tick() + 120
    return true
end

function MeleeSystem.FinishPurchaseTrip(success)
    local style = MeleeSystem.PurchaseStyle

    if success and style then
        MeleeSystem.ActiveStyleName = style.Name
        MeleeSystem.ActiveStyleMastery = MeleeSystem.GetMastery(style.Name)
        MeleeSystem.PendingStyleName = nil
        MeleeSystem.EquipStyle(style.Name)
        Utils.LastMeleeEquipAt = 0
    end

    MeleeSystem.PurchaseMode = nil
    MeleeSystem.PurchaseStyle = nil
    MeleeSystem.ReturnCFrame = nil
    MeleeSystem.PurchaseTripStartedAt = 0
    MeleeSystem.PurchaseAttempts = 0
    MeleeSystem.PurchaseBeliBefore = nil

    Teleport.Cancel()
    Teleport.ExclusiveOwner = nil
    SafetySystem.IgnoreUntil = tick() + 1.0
    QuestSystem.ActiveQuestCheckAt = 0
end

function MeleeSystem.HandlePurchasePriority()
    local mode = MeleeSystem.PurchaseMode
    local style = MeleeSystem.PurchaseStyle

    if not mode or not style then
        return false
    end

    Teleport.ExclusiveOwner = "MELEE"
    SafetySystem.IgnoreUntil = tick() + 3.0
    Combat.CurrentTarget = nil
    Combat.ResetAnchor()

    if MeleeSystem.IsOwned(style.Name) and mode ~= "RETURNING" then
        MeleeSystem.EquipStyle(style.Name)
        MeleeSystem.ActiveStyleName = style.Name
        MeleeSystem.PendingStyleName = nil
        MeleeSystem.PurchaseMode = "RETURNING"
        mode = "RETURNING"
    end

    local teacherCF = MeleeSystem.FindTeacher(style)
    local hrp = Utils.HRP()
    local purchaseDistance = tonumber(Config.BlackLegPurchaseDistance) or 8

    if mode == "TO_TEACHER" then
        if not teacherCF or not hrp then
            UI.SetStatus("Fighting Style | locating Dark Step Teacher", true)
            return true
        end

        local targetCF = teacherCF + Vector3.new(0, tonumber(Config.BlackLegTeacherYOffset) or 3, 0)
        local distance = (hrp.Position - targetCF.Position).Magnitude

        UI.SetStatus(
            "Fighting Style | going to Dark Step Teacher | "
                .. tostring(math.floor(distance)) .. " studs",
            true
        )

        if distance > purchaseDistance then
            Teleport.To(targetCF, Config.TweenSpeed, "MELEE")
            return true
        end

        Teleport.Cancel()
        Teleport.ExclusiveOwner = "MELEE"
        MeleeSystem.PurchaseMode = "BUYING"
        MeleeSystem.LastBuyAttempt = 0
        return true
    end

    if mode == "BUYING" then
        if not teacherCF or not hrp then
            MeleeSystem.PurchaseMode = "TO_TEACHER"
            return true
        end

        local targetCF = teacherCF + Vector3.new(0, tonumber(Config.BlackLegTeacherYOffset) or 3, 0)
        local distance = (hrp.Position - targetCF.Position).Magnitude

        -- Never try to buy from Skylands or another island.
        if distance > (purchaseDistance + 4) then
            UI.SetStatus("Fighting Style | returning to Dark Step Teacher", true)
            MeleeSystem.PurchaseMode = "TO_TEACHER"
            Teleport.Cancel()
            Teleport.ExclusiveOwner = "MELEE"
            Teleport.To(targetCF, Config.TweenSpeed, "MELEE")
            return true
        end

        if MeleeSystem.IsOwned(style.Name) then
            MeleeSystem.EquipStyle(style.Name)
            MeleeSystem.ActiveStyleName = style.Name
            MeleeSystem.PendingStyleName = nil
            MeleeSystem.PurchaseMode = "RETURNING"
            return true
        end

        local beli = UI.GetBeli()
        UI.SetStatus(
            "Fighting Style | buying Dark Step (Black Leg) | $"
                .. tostring(beli)
                .. " | try " .. tostring((MeleeSystem.PurchaseAttempts or 0) + 1),
            true
        )

        if style.Beli and beli < style.Beli then
            UI.SetStatus("Fighting Style | not enough Beli for Dark Step", true)
            return true
        end

        local retry = tonumber(Config.BlackLegRetryInterval) or 1.25
        if tick() - (MeleeSystem.LastBuyAttempt or 0) >= retry then
            MeleeSystem.LastBuyAttempt = tick()
            MeleeSystem.PurchaseAttempts = (MeleeSystem.PurchaseAttempts or 0) + 1

            if not CommF_ then
                CommF_ = WaitForCommF(2)
            end

            if CommF_ then
                pcall(function()
                    pcall(function()
                        CommF_:InvokeServer(style.BuyID, true)
                    end)
                    MeleeSystem.LastPurchaseResult = CommF_:InvokeServer(style.BuyID)
                end)
            end

            task.wait(0.10)

            if MeleeSystem.IsOwned(style.Name) then
                MeleeSystem.EquipStyle(style.Name)
                MeleeSystem.ActiveStyleName = style.Name
                MeleeSystem.PendingStyleName = nil
                MeleeSystem.PurchaseMode = "RETURNING"
                return true
            end
        end

        return true
    end

    if mode == "RETURNING" then
        if not MeleeSystem.IsOwned(style.Name) then
            MeleeSystem.PurchaseMode = "TO_TEACHER"
            UI.SetStatus("Fighting Style | purchase not confirmed | going back", true)
            return true
        end

        MeleeSystem.EquipStyle(style.Name)

        local returnCF = MeleeSystem.ReturnCFrame
        hrp = Utils.HRP()

        if not returnCF or not hrp then
            MeleeSystem.FinishPurchaseTrip(true)
            UI.SetStatus("Fighting Style | Dark Step acquired | resuming farm", true)
            return true
        end

        local distance = (hrp.Position - returnCF.Position).Magnitude
        UI.SetStatus(
            "Fighting Style | Dark Step acquired | returning to farm | "
                .. tostring(math.floor(distance)) .. " studs",
            true
        )

        if distance > (tonumber(Config.BlackLegReturnDistance) or 12) then
            Teleport.To(returnCF, Config.TweenSpeed, "MELEE")
            return true
        end

        MeleeSystem.FinishPurchaseTrip(true)
        UI.SetStatus("Fighting Style | Dark Step equipped | resuming farm", true)
        return true
    end

    return true
end

function MeleeSystem.GetStatus()
    local target = tonumber(Config.FightingStyleMasteryTarget) or 400

    if MeleeSystem.ActiveStyleName then
        local mastery = MeleeSystem.GetMastery(MeleeSystem.ActiveStyleName)
        return tostring(MeleeSystem.ActiveStyleName) .. " " .. tostring(mastery) .. "/" .. tostring(target)
    end

    if MeleeSystem.PendingStyleName then
        return tostring(MeleeSystem.PendingStyleName) .. " | buying"
    end

    if MeleeSystem.AllCurrentStylesDone then
        return "Melee: current styles 400+"
    end

    return "Melee: Combat"
end

function MeleeSystem.TryBuyAsync(style)
    if not style or MeleeSystem.PurchaseInFlight then
        return
    end

    local now = tick()
    if now - (MeleeSystem.LastBuyAttempt or 0) < (tonumber(Config.FightingStyleBuyInterval) or 2.0) then
        return
    end

    if style.Beli and UI.GetBeli() < style.Beli then
        return
    end

    MeleeSystem.LastBuyAttempt = now
    MeleeSystem.PendingStyleName = style.Name
    MeleeSystem.PurchaseInFlight = true

    task.spawn(function()
        local ok = false

        if CommF_ then
            ok = pcall(function()
                if style.Special == "DragonClaw" then
                    CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "1")
                    CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "2")
                else
                    -- REDZ pattern: query then buy.
                    pcall(function()
                        CommF_:InvokeServer(style.BuyID, true)
                    end)
                    CommF_:InvokeServer(style.BuyID)
                end
            end)
        end

        MeleeSystem.LastPurchaseResult = ok
        MeleeSystem.PurchaseInFlight = false

        -- Do not touch UI status here. The farm owns the main status label.
        if MeleeSystem.IsOwned(style.Name) then
            MeleeSystem.PendingStyleName = nil
            MeleeSystem.ActiveStyleName = style.Name
            MeleeSystem.ActiveStyleMastery = MeleeSystem.GetMastery(style.Name)

            if not (SaberSystem and SaberSystem.Active) then
                MeleeSystem.EquipStyle(style.Name)
                Utils.LastMeleeEquipAt = 0
            end
        end
    end)
end

function MeleeSystem.Tick()
    if not Config.AutoMelee or not Config.AutoFightingStyles then
        return
    end

    -- Saber puzzle items must stay equipped. Do not let Black Leg/Dark Step
    -- mastery steal the active Tool while Torch, Cup or Relic is being used.
    if SaberSystem and SaberSystem.Active then
        return
    end

    local now = tick()
    if now - (MeleeSystem.LastTick or 0) < (tonumber(Config.FightingStyleMasteryCheckInterval) or 0.35) then
        return
    end
    MeleeSystem.LastTick = now

    local style, mastery, action = MeleeSystem.GetTrainingStyle()

    if not style then
        MeleeSystem.ActiveStyleName = nil
        MeleeSystem.PendingStyleName = nil
        MeleeSystem.ActiveStyleMastery = tonumber(Config.FightingStyleMasteryTarget) or 400
        MeleeSystem.AllCurrentStylesDone = true
        return
    end

    MeleeSystem.AllCurrentStylesDone = false

    if action == "buy" then
        MeleeSystem.ActiveStyleName = nil
        MeleeSystem.ActiveStyleMastery = 0
        MeleeSystem.PendingStyleName = style.Name

        if style.Name == "Black Leg"
            and UI.GetBeli() >= (style.Beli or Config.BlackLegPrice or 150000) then

            MeleeSystem.StartPurchaseTrip(style)
            return
        end

        MeleeSystem.TryBuyAsync(style)
        return
    end

    MeleeSystem.PendingStyleName = nil
    MeleeSystem.ActiveStyleName = style.Name
    MeleeSystem.ActiveStyleMastery = mastery

    if MeleeSystem.IsOwned(style.Name) then
        MeleeSystem.EquipStyle(style.Name)
        Utils.LastEquippedWeapon = style.Name
    end

    if mastery >= (tonumber(Config.FightingStyleMasteryTarget) or 400) then
        MeleeSystem.Done[style.Name] = true
        MeleeSystem.ActiveStyleName = nil
    end
end

--=====================================================================================
-- SECOND SEA TRANSITION
-- Level 700 alone is not enough: Electro must reach 400 mastery first.
-- Until then the normal First Sea level farm keeps running (Galley Captain/Cyborg
-- fallback at the end of Fountain City). Fishman Karate begins only after Sea 2.
--=====================================================================================
Sea2System.LastAction = 0
Sea2System.LastState = "IDLE"
Sea2System.LastBossSeenAt = 0
Sea2System.TravelAttemptAt = 0

function Sea2System.GetElectroMastery()
    return tonumber(MeleeSystem.GetMastery("Electro")) or 0
end

function Sea2System.IsReadyForSea2()
    if not Config.AutoSea2 then
        return false
    end

    if MeleeSystem.GetSea() ~= 1 then
        return false
    end

    if (tonumber(Utils.Level()) or 0) < (tonumber(Config.Sea2RequiredLevel) or 700) then
        return false
    end

    if Config.Sea2RequireElectroMastery ~= false then
        local required = tonumber(Config.Sea2ElectroMasteryTarget) or 400
        if Sea2System.GetElectroMastery() < required then
            return false
        end
    end

    return true
end

function Sea2System.HasTool(name)
    local char = Utils.Character()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    return (char and char:FindFirstChild(name)) or (backpack and backpack:FindFirstChild(name))
end

function Sea2System.EquipTool(name)
    local tool = Sea2System.HasTool(name)
    local hum = Utils.Humanoid()
    if not tool or not hum then
        return false
    end
    pcall(function()
        hum:EquipTool(tool)
    end)
    return true
end

function Sea2System.GetIceDoor()
    local map = workspace:FindFirstChild("Map")
    local ice = map and map:FindFirstChild("Ice")
    return ice and ice:FindFirstChild("Door") or nil
end

function Sea2System.IsIceDoorClosed()
    local door = Sea2System.GetIceDoor()
    if not door then
        return false
    end
    local closed = false
    pcall(function()
        closed = door.CanCollide == true and door.Transparency < 1
    end)
    return closed
end

function Sea2System.FindIceAdmiral()
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then
        return nil
    end
    for _, enemy in ipairs(enemies:GetChildren()) do
        if enemy.Name == "Ice Admiral" then
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
            if hum and root and hum.Health > 0 then
                return enemy
            end
        end
    end
    return nil
end

function Sea2System.TryRemote(...)
    if not CommF_ then
        CommF_ = WaitForCommF(2)
    end
    if not CommF_ then
        return false
    end

    local now = tick()
    if now - (Sea2System.LastAction or 0) < (tonumber(Config.Sea2TransitionActionCooldown) or 0.85) then
        return false
    end
    Sea2System.LastAction = now

    local args = table.pack(...)
    task.spawn(function()
        pcall(function()
            CommF_:InvokeServer(table.unpack(args, 1, args.n))
        end)
    end)
    return true
end

function Sea2System.Tick()
    if not Config.AutoSea2 then
        return false
    end

    -- Once teleported, release ownership immediately and let normal Sea 2 farm run.
    if MeleeSystem.GetSea() >= 2 then
        Sea2System.LastState = "DONE"
        return false
    end

    local level = tonumber(Utils.Level()) or 0
    local requiredLevel = tonumber(Config.Sea2RequiredLevel) or 700
    if level < requiredLevel then
        return false
    end

    local requiredMastery = tonumber(Config.Sea2ElectroMasteryTarget) or 400
    local electroMastery = Sea2System.GetElectroMastery()

    if Config.Sea2RequireElectroMastery ~= false and electroMastery < requiredMastery then
        -- IMPORTANT: do not own movement here. Normal level farm continues on the
        -- final First Sea quests while Electro gains mastery.
        Sea2System.LastState = "TRAIN_ELECTRO"
        return false
    end

    Combat.ResetAnchor()
    Teleport.ExclusiveOwner = "SEA2"

    local hrp = Utils.HRP()
    if not hrp then
        return true
    end

    local doorClosed = Sea2System.IsIceDoorClosed()
    local key = Sea2System.HasTool("Key")

    if doorClosed and not key then
        Sea2System.LastState = "GET_KEY"
        local detectiveCF = CFrame.new(4852, 6, 719)
        local distance = (hrp.Position - detectiveCF.Position).Magnitude

        UI.SetStatus("Sea 2 | getting Detective key")
        if distance > (tonumber(Config.Sea2TransitionInteractDistance) or 7) then
            Teleport.To(detectiveCF, Config.TweenSpeed, "SEA2", true)
        else
            Teleport.Cancel()
            Teleport.ExclusiveOwner = "SEA2"
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
            Sea2System.TryRemote("DressrosaQuestProgress", "Detective")
        end
        return true
    end

    if doorClosed and key then
        Sea2System.LastState = "OPEN_DOOR"
        Sea2System.EquipTool("Key")
        local doorCF = CFrame.new(1346, 37, -1329)
        local distance = (hrp.Position - doorCF.Position).Magnitude

        UI.SetStatus("Sea 2 | opening Ice Admiral door")
        if distance > 4.5 then
            Teleport.To(doorCF, Config.TweenSpeed, "SEA2", true)
        else
            Teleport.Cancel()
            Teleport.ExclusiveOwner = "SEA2"
            pcall(function()
                hrp.CFrame = doorCF
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
        end
        return true
    end

    local iceAdmiral = Sea2System.FindIceAdmiral()
    if iceAdmiral then
        Sea2System.LastState = "ICE_ADMIRAL"
        Sea2System.LastBossSeenAt = tick()
        Teleport.ExclusiveOwner = nil
        UI.SetStatus("Sea 2 | defeating Ice Admiral")
        Utils.EnsureMeleeEquipped(true)
        HakiSystem.ActivateBuso()
        Combat.EngageTarget(iceAdmiral)
        return true
    end

    -- Door is open and the Ice Admiral is gone: travel to Second Sea.
    Sea2System.LastState = "TRAVEL"
    local captainCF = CFrame.new(1280, 27, -1380)
    local distance = (hrp.Position - captainCF.Position).Magnitude
    UI.SetStatus("Sea 2 | traveling to Second Sea")

    if distance > 8 then
        Teleport.To(captainCF, Config.TweenSpeed, "SEA2", true)
    else
        Teleport.Cancel()
        Teleport.ExclusiveOwner = "SEA2"
        Sea2System.TryRemote("TravelDressrosa")
    end

    return true
end


SaberSystem.Active = false
SaberSystem.LastCheck = 0
SaberSystem.LastAction = 0
SaberSystem.ReturnCFrame = nil
SaberSystem.CurrentStep = "WAITING"
SaberSystem.BossTarget = nil
SaberSystem.LastBossAttack = 0
SaberSystem.PlatesCache = nil

SaberSystem.Cache = {
    Action = "Waiting",
    Detail = "-",
    PlatesActive = 0,
    PlatesTotal = 5,
    NextPlate = "-",
    PlateAttempts = 0,
    Distance = 0,
    RichSon = 0,
    SickMan = 0,
    Torch = false,
    Cup = false,
    Relic = false,
    Target = "-",
}
SaberSystem.CurrentPlateIndex = nil
SaberSystem.LastPlateTouchAt = 0
SaberSystem.LastProgressAt = 0
SaberSystem.CachedRichSon = 0
SaberSystem.CachedSickMan = 0
-- Raw server answers are kept separately because some Saber implementations
-- use 0/1 differently. A non-nil RichSon answer is the reliable evidence that
-- the Sick Man / Cup stage has already been passed.
SaberSystem.RawRichSon = nil
SaberSystem.RawSickMan = nil
SaberSystem.ProgressProbeComplete = false
SaberSystem.ProgressProbeAttempts = 0

SaberSystem.ActiveQuestItem = nil
SaberSystem.BurnAttempts = 0
SaberSystem.BurnHoldStartedAt = 0
SaberSystem.LastBurnTouchAt = 0
SaberSystem.BurnSideIndex = nil

-- Stable puzzle interaction state.
SaberSystem.GroundHoldKey = nil
SaberSystem.GroundHoldPosition = nil
SaberSystem.GroundHoldBodyPosition = nil
SaberSystem.GroundHoldBodyGyro = nil
SaberSystem.GroundHoldHumanoid = nil
SaberSystem.GroundHoldSaved = nil

-- Boss availability / temporary server-hop state.
SaberSystem.BossWaitName = nil
SaberSystem.BossMissingSince = 0
SaberSystem.LastBossHopAt = 0
SaberSystem.BossHopRequested = false
SaberSystem.BossLastSeenName = nil
SaberSystem.BossLastSeenAt = 0
SaberSystem.BossLastHealth = nil
SaberSystem.BossDeathSeenAt = 0

local __SABER_PROGRESS = __KRATOS_ENV.__KRATOS_SABER_PROGRESS

if type(__SABER_PROGRESS) ~= "table" then
    __SABER_PROGRESS = {
        PlatesDone = false,
        TorchCollected = false,
        BurnDone = false,
        CupCollected = false,
        CupFilled = false,
        SickManDone = false,
        MobLeaderDone = false,
        RelicObtained = false,
    }

    __KRATOS_ENV.__KRATOS_SABER_PROGRESS = __SABER_PROGRESS
end

SaberSystem.ProgressFlags = __SABER_PROGRESS

SaberSystem.TorchCheckStartedAt = 0
SaberSystem.TorchCheckPosition = nil
SaberSystem.TorchCheckDone = false

SaberSystem.CupCheckStartedAt = 0
SaberSystem.CupCheckPosition = nil
SaberSystem.CupPickupLastContactAt = 0
SaberSystem.CupPickupContactAttempt = 0
SaberSystem.CupPickupBusy = false

SaberSystem.CupWaterIndex = 1
SaberSystem.CupWaterTryStartedAt = 0
SaberSystem.CupWaterAttempts = 0
SaberSystem.CupLiftActive = false
SaberSystem.CupLiftStartedAt = 0
SaberSystem.CupLastLiftAt = 0
SaberSystem.CupLiftBodyPosition = nil
SaberSystem.CupDashDoneForAttempt = false
SaberSystem.CupDashAt = 0

-- Saber story progression state. These are runtime helpers; persistent puzzle
-- evidence continues to live in ProgressFlags.
SaberSystem.RichSonContacted = false
SaberSystem.MobLeaderEngaged = false
SaberSystem.MobLeaderKilledAt = 0
SaberSystem.MobLeaderKilledJobId = nil
SaberSystem.ServerConfirmedRichState = nil
SaberSystem.LastSickManInteractAt = 0
SaberSystem.LastRichManInteractAt = 0
SaberSystem.LastRelicPlaceAt = 0

-- Non-blocking Saber NPC interaction state.  ProQuestProgress is a yielding
-- RemoteFunction; never call it directly from the main farm tick.
SaberSystem.SickManInteractPending = false
SaberSystem.SickManInteractStartedAt = 0
SaberSystem.SickManInteractAttempts = 0
SaberSystem.RichManInteractPending = false
SaberSystem.RichManInteractMode = nil
SaberSystem.RichManInteractStartedAt = 0

function SaberSystem.GetTool(toolName)
    local char = Utils.Character()
    local backpack = LocalPlayer:FindFirstChild("Backpack")

    if char then
        local tool = char:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then
            return tool
        end
    end

    if backpack then
        local tool = backpack:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then
            return tool
        end
    end

    return nil
end

function SaberSystem.HasTool(toolName)
    return SaberSystem.GetTool(toolName) ~= nil
end

function SaberSystem.GetEquippedTool(toolName)
    local char = Utils.Character()

    if not char then
        return nil
    end

    local tool = char:FindFirstChild(toolName)

    if tool and tool:IsA("Tool") then
        return tool
    end

    return nil
end

function SaberSystem.EquipTool(toolName)
    local tool = SaberSystem.GetTool(toolName)
    local hum = Utils.Humanoid()
    local char = Utils.Character()

    if not tool or not hum or not char then
        return false
    end

    -- Puzzle tools must have exclusive equipment ownership.
    if toolName == "Torch" or toolName == "Cup" or toolName == "Relic" then
        SaberSystem.ActiveQuestItem = toolName

        pcall(function()
            hum:UnequipTools()
        end)
    end

    pcall(function()
        hum:EquipTool(tool)
    end)

    local equipped = SaberSystem.GetEquippedTool(toolName)
    return equipped ~= nil
end

function SaberSystem.MarkOwned()
    SaberSystem.Has = true
    SaberSystem.ProgressFlags.Completed = true
    __KRATOS_ENV.__KRATOS_SABER_PROGRESS = SaberSystem.ProgressFlags
    __KRATOS_ENV.__KRATOS_SABER_OWNER = LocalPlayer.UserId

    -- A stale Relic can remain equipped after an old Saber quest state.
    -- Once Saber is confirmed owned, immediately release puzzle-item equipment.
    local char = Utils.Character()
    local hum = Utils.Humanoid()
    if char and hum and char:FindFirstChild("Relic") then
        pcall(function()
            hum:UnequipTools()
        end)
    end

    SaberSystem.ActiveQuestItem = nil
    return true
end

function SaberSystem.Check(force)
    local now = tick()

    if SaberSystem.HasTool("Saber") then
        return SaberSystem.MarkOwned()
    end

    -- Reuse a confirmed completion only for the same Roblox account.
    if SaberSystem.ProgressFlags.Completed == true
        and __KRATOS_ENV.__KRATOS_SABER_OWNER == LocalPlayer.UserId then
        return SaberSystem.MarkOwned()
    end

    local cachedInventory = AbilitySystem and AbilitySystem.Inventory or nil
    if InventoryHasItem(cachedInventory, "Saber") then
        return SaberSystem.MarkOwned()
    end

    local interval = tonumber(Config.SaberInventoryCheckInterval) or 3.0
    if not force and now - (SaberSystem.LastCheck or 0) < interval then
        return SaberSystem.Has == true
    end

    SaberSystem.LastCheck = now

    -- Never let the Saber quest take control until this ownership check finishes.
    if not rawget(SaberSystem, "InventoryCheckPending") then
        SaberDynamicSet("InventoryCheckPending", true)

        task.spawn(function()
            local inventory = FetchPlayerInventory()
            local hasSaber = InventoryHasItem(inventory, "Saber")

            if not hasSaber then
                local weaponInventory = FetchStoredWeaponInventory()
                hasSaber = InventoryHasItem(weaponInventory, "Saber")
            end

            if hasSaber then
                SaberSystem.MarkOwned()
            end

            SaberDynamicSet("InventoryCheckPending", false)
        end)
    end

    return SaberSystem.Has == true
end

function SaberSystem.Begin()
    if SaberSystem.Active then
        return
    end

    local hrp = Utils.HRP()

    SaberSystem.Active = true
    SaberSystem.ReturnCFrame = hrp and hrp.CFrame or nil
    SaberSystem.CurrentStep = "STARTING"

    Combat.CurrentTarget = nil
    Combat.ResetAnchor()
    Teleport.Cancel()

    Teleport.ExclusiveOwner = "SABER"
    SafetySystem.IgnoreUntil = tick() + 120
end

function SaberSystem.Finish()
    SaberSystem.Active = false
    SaberSystem.CurrentStep = "COMPLETED"
    SaberSystem.BossTarget = nil
    SaberSystem.ActiveQuestItem = nil
    SaberSystem.BurnAttempts = 0
    SaberSystem.BurnHoldStartedAt = 0
    SaberSystem.BurnSideIndex = nil
    SaberSystem.ReleaseGroundHold()

    SaberSystem.BossWaitName = nil
    SaberSystem.BossMissingSince = 0
    SaberSystem.BossHopRequested = false

    Combat.CurrentTarget = nil
    Combat.ResetAnchor()
    Teleport.Cancel()

    if Teleport.ExclusiveOwner == "SABER" then
        Teleport.ExclusiveOwner = nil
    end

    SafetySystem.IgnoreUntil = tick() + 1
    QuestSystem.ActiveQuestCheckAt = 0
end


function SaberSystem.MarkProgress(flagName)
    if SaberSystem.ProgressFlags[flagName] ~= true then
        SaberSystem.ProgressFlags[flagName] = true
        __KRATOS_ENV.__KRATOS_SABER_PROGRESS = SaberSystem.ProgressFlags
    end
end

function SaberSystem.IsBurnPartOpen(burnPart, burnContainer)
    if SaberSystem.ProgressFlags.BurnDone then
        return true
    end

    if burnContainer and not burnPart then
        return true
    end

    if not burnPart then
        return false
    end

    local open = false

    pcall(function()
        if burnPart.CanCollide == false then
            open = true
        end

        if tonumber(burnPart.Transparency)
            and burnPart.Transparency >= 0.90 then
            open = true
        end

        if tonumber(burnPart.LocalTransparencyModifier)
            and burnPart.LocalTransparencyModifier >= 0.90 then
            open = true
        end

        if burnPart:GetAttribute("Open") == true
            or burnPart:GetAttribute("Opened") == true
            or burnPart:GetAttribute("Burned") == true then
            open = true
        end
    end)

    if open then
        SaberSystem.MarkProgress("BurnDone")
    end

    return open
end

function SaberSystem.GetMapObjects(force)
    local now = tick()
    local interval = tonumber(Config.SaberMapCacheInterval) or 0.75
    local cached = rawget(SaberSystem, "MapObjectCache")

    if not force
        and cached
        and cached.Map
        and cached.Map.Parent
        and (now - (rawget(SaberSystem, "MapObjectCacheAt") or 0)) < interval then
        return cached
    end

    local map = workspace:FindFirstChild("Map")

    if not map then
        local empty = {
            Map = nil,
            Jungle = nil,
            Desert = nil,
            Plates = nil,
            FinalPart = nil,
            BurnPart = nil,
            Torch = nil,
            Cup = nil,
        }
        SaberDynamicSet("MapObjectCache", empty)
        SaberDynamicSet("MapObjectCacheAt", now)
        return empty
    end

    -- Recursive lookups are relatively expensive on the Blox Fruits map.
    -- Cache their result briefly instead of repeating them every farm tick.
    local jungle = map:FindFirstChild("Jungle") or map:FindFirstChild("Jungle", true)
    local desert = map:FindFirstChild("Desert") or map:FindFirstChild("Desert", true)

    local plates = jungle and jungle:FindFirstChild("QuestPlates", true) or nil
    local final = jungle and jungle:FindFirstChild("Final", true) or nil
    local finalPart = final and final:FindFirstChild("Part", true) or nil

    local burn = desert and desert:FindFirstChild("Burn", true) or nil
    local burnPart = burn and burn:FindFirstChild("Part", true) or nil

    local result = {
        Map = map,
        Jungle = jungle,
        Desert = desert,
        Plates = plates,
        FinalPart = finalPart,
        BurnPart = burnPart,
        BurnOpen = SaberSystem.IsBurnPartOpen(burnPart, burn),
        Torch = jungle and jungle:FindFirstChild("Torch", true) or nil,
        Cup = desert and desert:FindFirstChild("Cup", true) or nil,
    }

    SaberDynamicSet("MapObjectCache", result)
    SaberDynamicSet("MapObjectCacheAt", now)
    return result
end

function SaberSystem.SetCache(action, detail)
    SaberSystem.Cache.Action = tostring(action or SaberSystem.Cache.Action or "Waiting")
    SaberSystem.Cache.Detail = tostring(detail or "-")
end

function SaberSystem.RefreshItemCache()
    SaberSystem.Cache.Torch = SaberSystem.HasTool("Torch")
    SaberSystem.Cache.Cup = SaberSystem.HasTool("Cup")
    SaberSystem.Cache.Relic = SaberSystem.HasTool("Relic")

    if SaberSystem.ActiveQuestItem then
        SaberSystem.Cache.Detail = "Equipped: " .. tostring(SaberSystem.ActiveQuestItem)
    end

    if SaberSystem.BossTarget and SaberSystem.BossTarget.Parent then
        SaberSystem.Cache.Target = SaberSystem.BossTarget.Name
    else
        SaberSystem.Cache.Target = "-"
    end
end

function SaberSystem.GetCacheStatusText()
    local cache = SaberSystem.Cache or {}
    local step = tostring(SaberSystem.CurrentStep or "WAITING")

    local line1 = "SABER QUEST | Step: " .. step
        .. " | Plates: " .. tostring(cache.PlatesActive or 0)
        .. "/" .. tostring(cache.PlatesTotal or 5)

    local line2 = "Action: " .. tostring(cache.Action or "-")

    if (cache.Distance or 0) > 0 then
        line2 = line2 .. " | " .. tostring(math.floor(cache.Distance)) .. " studs"
    end

    if (cache.NextPlate or "-") ~= "-" then
        line2 = line2
            .. " | Next: " .. tostring(cache.NextPlate)
            .. " | Try: " .. tostring(cache.PlateAttempts or 0)
    end

    local flags = SaberSystem.ProgressFlags or {}

    local torchState = flags.TorchCollected and "DONE" or "..."
    if SaberSystem.TorchCheckDone and not SaberSystem.HasTool("Torch") then
        torchState = "DONE/CHECK"
    end

    local line3 = "Progress: Plates:"
        .. (flags.PlatesDone and "DONE" or "...")
        .. " Torch:" .. torchState
        .. " Burn:" .. (flags.BurnDone and "DONE" or "...")
        .. " Cup:" .. (flags.CupCollected and "DONE" or "...")

    local progressExtra = " | Rich:" .. tostring(cache.RichSon or 0)
        .. " Sick:" .. tostring(cache.SickMan or 0)

    local line4 = "Target: " .. tostring(cache.Target or "-")
        .. " | Style: " .. tostring(MeleeSystem.GetStatus())

    return line1
        .. "\n" .. line2
        .. "\n" .. line3 .. progressExtra
        .. "\n" .. line4
end

function SaberSystem.GetProgress(force)
    local now = tick()
    local interval = tonumber(Config.SaberProgressCheckInterval) or 1.50

    if not force and now - (SaberSystem.LastProgressAt or 0) < interval then
        return SaberSystem.CachedRichSon or 0, SaberSystem.CachedSickMan or 0
    end

    SaberSystem.LastProgressAt = now

    -- Never yield the main farm loop on ProQuestProgress. Keep both the raw
    -- server result and a numeric display cache. The raw RichSon result is
    -- important: public Saber implementations disagree about whether SickMan
    -- returns 0 or 1 after completion, but they only advance to RichSon after
    -- the filled Cup has already been delivered.
    if not rawget(SaberSystem, "ProgressCheckPending") then
        SaberDynamicSet("ProgressCheckPending", true)
        SaberSystem.ProgressProbeAttempts = (SaberSystem.ProgressProbeAttempts or 0) + 1

        task.spawn(function()
            local rich = SaberSystem.CachedRichSon or 0
            local sick = SaberSystem.CachedSickMan or 0
            local rawRich = nil
            local rawSick = nil

            if not CommF_ then
                CommF_ = WaitForCommF(2)
            end

            if CommF_ then
                pcall(function()
                    rawRich = CommF_:InvokeServer("ProQuestProgress", "RichSon")
                    if rawRich ~= nil then
                        rich = tonumber(rawRich) or rich
                    end
                end)

                pcall(function()
                    rawSick = CommF_:InvokeServer("ProQuestProgress", "SickMan")
                    if rawSick ~= nil then
                        sick = tonumber(rawSick) or sick
                    end
                end)
            end

            SaberSystem.RawRichSon = rawRich
            SaberSystem.RawSickMan = rawSick
            SaberSystem.CachedRichSon = rich
            SaberSystem.CachedSickMan = sick
            SaberSystem.Cache.RichSon = rich
            SaberSystem.Cache.SickMan = sick
            SaberSystem.ProgressProbeComplete = true

            -- RichSon has three useful states in public Auto Saber implementations:
            -- nil = Rich Man conversation has not been accepted yet,
            --   0 = Rich Man accepted -> defeat Mob Leader,
            --   1 = Mob Leader complete -> return for the Relic.
            -- Only numeric answers are progression evidence. A nil response often
            -- means the dialogue UI is open and the player still needs to choose Talk.
            local richState = tonumber(rawRich)
            if richState ~= nil then
                SaberSystem.ServerConfirmedRichState = richState
                SaberSystem.MarkProgress("SickManDone")
                SaberSystem.MarkProgress("CupFilled")
                SaberSystem.MarkProgress("CupCollected")
                SaberSystem.RichSonContacted = true

                if richState >= 1 then
                    SaberSystem.MarkProgress("MobLeaderDone")
                elseif richState == 0 then
                    -- Server says the Rich Man quest is active but Mob Leader
                    -- is NOT complete for the current quest state. Never trust
                    -- a stale completion flag from a previous server here.
                    SaberSystem.ProgressFlags.MobLeaderDone = false
                    SaberSystem.ProgressFlags.RelicObtained = false
                    SaberSystem.MobLeaderKilledAt = 0
                    SaberSystem.MobLeaderKilledJobId = nil
                end
            else
                SaberSystem.ServerConfirmedRichState = nil
            end

            SaberDynamicSet("ProgressCheckPending", false)
        end)
    end

    return SaberSystem.CachedRichSon or 0, SaberSystem.CachedSickMan or 0
end

function SaberSystem.IsSickManDone()
    if SaberSystem.ProgressFlags.SickManDone then
        return true
    end

    if SaberSystem.HasTool("Relic") then
        return true
    end

    -- A numeric RichSon state (0/1) is server-side proof that the Cup/Sick Man
    -- stage is already behind this account. nil merely means the Rich Man
    -- dialogue has not been accepted yet.
    if tonumber(SaberSystem.RawRichSon) ~= nil then
        return true
    end

    return false
end

function SaberSystem.IsMobLeaderDoneForCurrentServer()
    if SaberSystem.HasTool("Relic") then
        return true
    end

    local richState = tonumber(SaberSystem.RawRichSon)
    if richState ~= nil then
        return richState >= 1
    end

    -- A locally observed kill is valid only in the SAME Roblox server.
    -- If the player changes server before claiming the Relic, we intentionally
    -- re-check/re-do the Mob Leader step instead of trusting stale memory.
    return SaberSystem.ProgressFlags.MobLeaderDone == true
        and SaberSystem.MobLeaderKilledJobId == game.JobId
        and (SaberSystem.MobLeaderKilledAt or 0) > 0
end

function SaberSystem.ResetMobLeaderCompletion(reason)
    SaberSystem.ProgressFlags.MobLeaderDone = false
    SaberSystem.ProgressFlags.RelicObtained = false
    SaberSystem.MobLeaderEngaged = false
    SaberSystem.MobLeaderKilledAt = 0
    SaberSystem.MobLeaderKilledJobId = nil
    SaberSystem.ServerConfirmedRichState = tonumber(SaberSystem.RawRichSon)
    SaberSystem.SetCache("Mob Leader needs recheck", reason or "Current server has no confirmed reward state")
end

function SaberSystem.FindEnemy(enemyName)
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then
        return nil
    end

    for _, enemy in ipairs(enemies:GetChildren()) do
        if enemy.Name == enemyName then
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart

            if hum and root and hum.Health > 0 then
                return enemy
            end
        end
    end

    return nil
end


function SaberSystem.ReleaseGroundHold()
    local hum = SaberSystem.GroundHoldHumanoid
    local saved = SaberSystem.GroundHoldSaved

    if SaberSystem.GroundHoldBodyPosition
        and SaberSystem.GroundHoldBodyPosition.Parent then
        pcall(function()
            SaberSystem.GroundHoldBodyPosition:Destroy()
        end)
    end

    if SaberSystem.GroundHoldBodyGyro
        and SaberSystem.GroundHoldBodyGyro.Parent then
        pcall(function()
            SaberSystem.GroundHoldBodyGyro:Destroy()
        end)
    end

    if hum and hum.Parent and saved then
        pcall(function()
            hum.WalkSpeed = saved.WalkSpeed
            hum.AutoRotate = saved.AutoRotate

            if hum.UseJumpPower then
                hum.JumpPower = saved.JumpPower
            else
                hum.JumpHeight = saved.JumpHeight
            end

            hum.Jump = false
        end)
    end

    SaberSystem.GroundHoldKey = nil
    SaberSystem.GroundHoldPosition = nil
    SaberSystem.GroundHoldBodyPosition = nil
    SaberSystem.GroundHoldBodyGyro = nil
    SaberSystem.GroundHoldHumanoid = nil
    SaberSystem.GroundHoldSaved = nil
end

function SaberSystem.GetGroundedCFrame(targetCF)
    local char = Utils.Character()
    local hrp = Utils.HRP()
    local hum = Utils.Humanoid()

    if not char or not hrp or not hum or typeof(targetCF) ~= "CFrame" then
        return targetCF
    end

    local rayHeight = tonumber(Config.SaberGroundRayHeight) or 16
    local rayDepth = tonumber(Config.SaberGroundRayDepth) or 80
    local origin = targetCF.Position + Vector3.new(0, rayHeight, 0)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}
    params.IgnoreWater = false

    local result = workspace:Raycast(
        origin,
        Vector3.new(0, -(rayHeight + rayDepth), 0),
        params
    )

    local y = targetCF.Position.Y

    if result then
        local rootHalf = hrp.Size.Y * 0.5
        y = result.Position.Y + hum.HipHeight + rootHalf + 0.05
    end

    local position = Vector3.new(targetCF.Position.X, y, targetCF.Position.Z)

    local look = targetCF.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)

    if flatLook.Magnitude < 0.01 then
        flatLook = Vector3.new(0, 0, -1)
    else
        flatLook = flatLook.Unit
    end

    return CFrame.new(position, position + flatLook)
end

function SaberSystem.HoldGround(key, targetCF)
    if not AutomationMovementAllowed() then
        SaberSystem.ReleaseGroundHold()
        return false
    end

    local hrp = Utils.HRP()
    local hum = Utils.Humanoid()

    if not hrp or not hum or typeof(targetCF) ~= "CFrame" then
        return false
    end

    local groundedCF = SaberSystem.GetGroundedCFrame(targetCF)

    if SaberSystem.GroundHoldKey ~= key
        or not SaberSystem.GroundHoldBodyPosition
        or not SaberSystem.GroundHoldBodyPosition.Parent then

        SaberSystem.ReleaseGroundHold()

        Teleport.Cancel()
        Teleport.ExclusiveOwner = "SABER"

        SaberSystem.GroundHoldKey = key
        SaberSystem.GroundHoldPosition = groundedCF.Position
        SaberSystem.GroundHoldHumanoid = hum
        SaberSystem.GroundHoldSaved = {
            WalkSpeed = hum.WalkSpeed,
            AutoRotate = hum.AutoRotate,
            JumpPower = hum.JumpPower,
            JumpHeight = hum.JumpHeight,
        }

        -- One snap only. After this, constraints keep the character still;
        -- no per-tick CFrame corrections that cause the up/down bouncing.
        pcall(function()
            hrp.CFrame = groundedCF
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hum.WalkSpeed = 0
            hum.AutoRotate = false
            hum.Jump = false

            if hum.UseJumpPower then
                hum.JumpPower = 0
            else
                hum.JumpHeight = 0
            end
        end)

        local bodyPosition = Instance.new("BodyPosition")
        bodyPosition.Name = "KratosSaberGroundHold"
        bodyPosition.P = tonumber(Config.SaberGroundHoldP) or 22000
        bodyPosition.D = tonumber(Config.SaberGroundHoldD) or 1800
        bodyPosition.MaxForce = Vector3.new(
            tonumber(Config.SaberGroundHoldMaxForce) or 1000000000,
            tonumber(Config.SaberGroundHoldMaxForce) or 1000000000,
            tonumber(Config.SaberGroundHoldMaxForce) or 1000000000
        )
        bodyPosition.Position = groundedCF.Position
        bodyPosition.Parent = hrp

        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "KratosSaberGroundFacing"
        bodyGyro.P = 12000
        bodyGyro.D = 1000
        bodyGyro.MaxTorque = Vector3.new(0, 1000000000, 0)
        bodyGyro.CFrame = groundedCF
        bodyGyro.Parent = hrp

        SaberSystem.GroundHoldBodyPosition = bodyPosition
        SaberSystem.GroundHoldBodyGyro = bodyGyro
    else
        -- Keep velocity dead without teleporting the HumanoidRootPart every tick.
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hum.Jump = false
        end)
    end

    return true
end

function SaberSystem.MoveTo(targetCF, statusText)
    SaberSystem.ReleaseGroundHold()

    local hrp = Utils.HRP()

    if not hrp or typeof(targetCF) ~= "CFrame" then
        SaberSystem.SetCache(statusText or "Moving", "Waiting for character/target")
        return false
    end

    Teleport.ExclusiveOwner = "SABER"
    SafetySystem.IgnoreUntil = tick() + 3

    local distance = (hrp.Position - targetCF.Position).Magnitude
    SaberSystem.Cache.Distance = distance
    SaberSystem.SetCache(statusText or "Moving", SaberSystem.CurrentStep)

    UI.SetStatus("Saber Quest | " .. tostring(statusText), true)

    if distance > 5 then
        Teleport.To(targetCF, Config.TweenSpeed, "SABER", true)
        return false
    end

    if Teleport.IsBusy() and Teleport.Owner == "SABER" then
        Teleport.Cancel()
        Teleport.ExclusiveOwner = "SABER"
    end

    SaberSystem.Cache.Distance = 0
    return true
end

function SaberSystem.ReleaseSaberExpertHover()
    local hold = rawget(SaberSystem, "SaberExpertHoverBodyPosition")
    if hold and hold.Parent then
        pcall(function() hold:Destroy() end)
    end

    local gyro = rawget(SaberSystem, "SaberExpertHoverBodyGyro")
    if gyro and gyro.Parent then
        pcall(function() gyro:Destroy() end)
    end

    SaberDynamicSet("SaberExpertHoverBodyPosition", nil)
    SaberDynamicSet("SaberExpertHoverBodyGyro", nil)
end

function SaberSystem.UpdateSaberExpertHover(root)
    if not AutomationMovementAllowed() then
        SaberSystem.ReleaseSaberExpertHover()
        return false
    end

    local hrp = Utils.HRP()
    if not hrp or not root then
        return false
    end

    local height = tonumber(Config.SaberExpertHoverHeight) or 20
    local desiredPosition = root.Position + Vector3.new(0, height, 0)

    local hold = rawget(SaberSystem, "SaberExpertHoverBodyPosition")
    if not hold or not hold.Parent then
        hold = Instance.new("BodyPosition")
        hold.Name = "KratosSaberExpertHover"
        hold.P = tonumber(Config.SaberExpertHoldP) or 32000
        hold.D = tonumber(Config.SaberExpertHoldD) or 2200
        local maxForce = tonumber(Config.SaberExpertHoldMaxForce) or 1000000000
        hold.MaxForce = Vector3.new(maxForce, maxForce, maxForce)
        hold.Position = desiredPosition
        hold.Parent = hrp
        SaberDynamicSet("SaberExpertHoverBodyPosition", hold)
    else
        hold.Position = desiredPosition
    end

    local gyro = rawget(SaberSystem, "SaberExpertHoverBodyGyro")
    if not gyro or not gyro.Parent then
        gyro = Instance.new("BodyGyro")
        gyro.Name = "KratosSaberExpertFaceBoss"
        gyro.P = 18000
        gyro.D = 900
        gyro.MaxTorque = Vector3.new(0, 1000000000, 0)
        gyro.Parent = hrp
        SaberDynamicSet("SaberExpertHoverBodyGyro", gyro)
    end

    local flatTarget = Vector3.new(root.Position.X, hrp.Position.Y, root.Position.Z)
    if (flatTarget - hrp.Position).Magnitude > 0.1 then
        gyro.CFrame = CFrame.new(hrp.Position, flatTarget)
    end

    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)

    return true, desiredPosition
end


function SaberSystem.GetMobLeaderCombatCFrame(root)
    local hrp = Utils.HRP()
    if not root or not hrp then
        return nil
    end

    local radius = tonumber(Config.SaberMobLeaderCombatRadius) or 8
    local height = tonumber(Config.SaberMobLeaderCombatHeight) or 3
    local origin = root.Position + Vector3.new(0, 2.5, 0)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    local ignore = {}
    local character = Utils.Character()
    if character then
        table.insert(ignore, character)
    end
    if root.Parent then
        table.insert(ignore, root.Parent)
    end
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = true

    local candidates = {}

    -- Prefer the side that is already closest to the player, then try a full ring.
    local playerDelta = Vector3.new(
        hrp.Position.X - root.Position.X,
        0,
        hrp.Position.Z - root.Position.Z
    )

    if playerDelta.Magnitude > 0.1 then
        table.insert(candidates, playerDelta.Unit)
    end

    for i = 0, 7 do
        local angle = math.rad(i * 45)
        table.insert(candidates, Vector3.new(math.cos(angle), 0, math.sin(angle)))
    end

    local bestCF = nil
    local bestDistance = math.huge

    for _, direction in ipairs(candidates) do
        local position = root.Position + direction * radius + Vector3.new(0, height, 0)
        local travel = position - origin

        -- Reject a candidate if the boss-to-player path runs into cliff/wall geometry.
        local blocked = workspace:Raycast(origin, travel, params)

        if not blocked then
            -- Also require a little headroom at the candidate so we do not snap into
            -- a low ceiling/rock overhang.
            local headroom = workspace:Raycast(
                position,
                Vector3.new(0, 6, 0),
                params
            )

            if not headroom then
                local distance = (hrp.Position - position).Magnitude

                if distance < bestDistance then
                    bestDistance = distance
                    bestCF = CFrame.lookAt(
                        position,
                        Vector3.new(root.Position.X, position.Y, root.Position.Z)
                    )
                end
            end
        end
    end

    -- Conservative fallback: stay on the player's current side of the boss.
    if not bestCF then
        local direction = playerDelta.Magnitude > 0.1
            and playerDelta.Unit
            or Vector3.new(0, 0, 1)

        local position = root.Position + direction * radius + Vector3.new(0, height, 0)
        bestCF = CFrame.lookAt(
            position,
            Vector3.new(root.Position.X, position.Y, root.Position.Z)
        )
    end

    return bestCF
end

function SaberSystem.FightEnemy(enemyName, fallbackCF)
    local previousTarget = SaberSystem.BossTarget
    local enemy = SaberSystem.FindEnemy(enemyName)

    if not enemy then
        local now = tick()
        local previousHum = previousTarget and previousTarget:FindFirstChildOfClass("Humanoid")
        local previousHealth = previousHum and previousHum.Health or SaberSystem.BossLastHealth
        local previousVanished = previousTarget ~= nil and previousTarget.Parent == nil

        -- Mob Leader completion is only accepted when it actually died.
        if enemyName == "Mob Leader" and SaberSystem.MobLeaderEngaged then
            local defeated = previousTarget ~= nil and (
                (previousHum and previousHum.Health <= 0)
                or (previousVanished and tonumber(previousHealth) and tonumber(previousHealth) <= 0)
            )

            if defeated then
                SaberSystem.MarkProgress("MobLeaderDone")
                SaberSystem.MobLeaderKilledAt = now
                SaberSystem.MobLeaderKilledJobId = game.JobId
                SaberSystem.ServerConfirmedRichState = nil
                SaberSystem.BossTarget = nil
                SaberSystem.BossWaitName = nil
                SaberSystem.BossMissingSince = 0
                SaberSystem.BossHopRequested = false
                SaberSystem.SetCache("Mob Leader defeated", "Returning to Rich Man")
                return false
            end
        end

        -- Saber Expert can disappear mid-fight. If it vanished while still alive,
        -- do not sit at the spawn for a long time: start the temporary hop timer
        -- almost immediately. If it died, give the Saber reward a short grace.
        local quickHop = false
        if enemyName == "Saber Expert" and previousTarget then
            if SaberSystem.HasTool("Saber") then
                return false
            end

            if tonumber(previousHealth) and tonumber(previousHealth) <= 0 then
                if (SaberSystem.BossDeathSeenAt or 0) == 0 then
                    SaberSystem.BossDeathSeenAt = now
                end

                local rewardGrace = tonumber(Config.SaberBossDeathRewardGrace) or 1.25
                if now - SaberSystem.BossDeathSeenAt < rewardGrace then
                    SaberSystem.SetCache("Saber Expert defeated", "Waiting for Saber reward")
                    return true
                end
                quickHop = true
            elseif previousVanished then
                local vanishGrace = tonumber(Config.SaberBossDisappearGrace) or 0.75
                if now - (SaberSystem.BossLastSeenAt or now) >= vanishGrace then
                    quickHop = true
                end
            end
        end

        SaberSystem.BossTarget = nil
        if enemyName == "Saber Expert" then
            SaberSystem.ReleaseSaberExpertHover()
        end
        SaberSystem.Cache.Target = enemyName

        if SaberSystem.BossWaitName ~= enemyName then
            SaberSystem.BossWaitName = enemyName
            SaberSystem.BossMissingSince = now
            SaberSystem.BossHopRequested = false
        end

        -- Mob Leader special rule:
        -- do NOT let the missing-boss timer run while travelling across the map.
        -- First reach Jean-Luc Island / Mob Leader spawn. Only after we're
        -- physically near that CFrame may the temporary server-hop countdown start.
        if enemyName == "Mob Leader" and typeof(fallbackCF) == "CFrame" then
            local hrp = Utils.HRP()
            local confirmDistance = tonumber(Config.SaberMobLeaderHopConfirmDistance) or 85
            local distanceToSpawn = hrp
                and (hrp.Position - fallbackCF.Position).Magnitude
                or math.huge

            SaberSystem.Cache.Distance = distanceToSpawn

            if distanceToSpawn > confirmDistance then
                -- Reset every tick while travelling so elapsed travel time can
                -- never accidentally satisfy SaberBossWaitBeforeHop.
                SaberSystem.BossMissingSince = now
                SaberSystem.BossHopRequested = false

                SaberSystem.SetCache(
                    "Going to Mob Leader spawn",
                    string.format("%.0f studs away | hop disabled while travelling", distanceToSpawn)
                )

                SaberSystem.MoveTo(fallbackCF, "going to Mob Leader spawn")
                return true
            end
        end

        local hopAfter = tonumber(Config.SaberBossWaitBeforeHop) or 3
        if quickHop then
            SaberSystem.BossMissingSince = math.min(
                SaberSystem.BossMissingSince or now,
                now - hopAfter
            )
        end

        local waited = now - (SaberSystem.BossMissingSince or now)

        if enemyName == "Mob Leader" then
            SaberSystem.SetCache(
                "Mob Leader spawn checked",
                string.format("Boss absent here | %.1f/%.1fs before server hop", waited, hopAfter)
            )
        else
            SaberSystem.SetCache(
                "Waiting for " .. enemyName,
                string.format("%.1f/%.1fs before temporary hop", waited, hopAfter)
            )
        end

        -- Only travel to the spawn while normally waiting. After a mid-fight
        -- despawn we stay still and hop as fast as possible.
        if not quickHop then
            SaberSystem.MoveTo(fallbackCF, "waiting for " .. enemyName)
        else
            Teleport.Cancel()
            local hrp = Utils.HRP()
            if hrp then
                pcall(function()
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end

        if Config.SaberBossServerHop
            and waited >= hopAfter
            and not SaberSystem.BossHopRequested
            and now - (SaberSystem.LastBossHopAt or 0)
                >= (tonumber(Config.SaberBossHopCooldown) or 4) then

            SaberSystem.BossHopRequested = true
            SaberSystem.LastBossHopAt = now

            SaberSystem.ReleaseGroundHold()
            Teleport.Cancel()
            Teleport.ExclusiveOwner = "SABER"

            SaberSystem.SetCache(
                "Server Hop for " .. enemyName,
                enemyName == "Mob Leader"
                    and "Spawn confirmed empty at Jean-Luc Island"
                    or "Fast temporary Saber boss search"
            )

            task.spawn(function()
                if ServerSystem and type(ServerSystem.ServerHop) == "function" then
                    ServerSystem.ServerHop(
                        Config.ServerHopRegion,
                        tonumber(Config.SaberBossHopMaxPlayers) or 11,
                        true
                    )
                end

                -- If teleport failed, unlock quickly and retry after cooldown.
                task.wait(1.5)
                SaberSystem.BossHopRequested = false
            end)
        end

        return true
    end

    local bossTargetChanged = SaberSystem.BossTarget ~= enemy
    SaberSystem.BossTarget = enemy
    SaberSystem.Cache.Target = enemyName

    if bossTargetChanged then
        SaberSystem.LastBossAttack = 0
        pcall(Attack.RefreshRemotes)
        pcall(Attack.PrimeHitToken)
    end
    SaberSystem.BossLastSeenName = enemyName
    SaberSystem.BossLastSeenAt = tick()
    SaberSystem.BossDeathSeenAt = 0

    if enemyName == "Mob Leader" then
        SaberSystem.MobLeaderEngaged = true
    end
    SaberSystem.BossWaitName = nil
    SaberSystem.BossMissingSince = 0
    SaberSystem.BossHopRequested = false
    SaberSystem.ReleaseGroundHold()

    local hum = enemy:FindFirstChildOfClass("Humanoid")
    local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
    local hrp = Utils.HRP()

    if not hum or not root or not hrp or hum.Health <= 0 then
        if hum then
            SaberSystem.BossLastHealth = hum.Health
        end
        return true
    end

    SaberSystem.BossLastHealth = hum.Health

    local desired

    if enemyName == "Saber Expert" and Config.SaberExpertHoverCombat ~= false then
        -- Follow the boss dynamically from exactly above it.
        -- IMPORTANT: only the local player's BodyPosition/BodyGyro are changed.
        -- The Saber Expert's CFrame, velocity, collision and humanoid are untouched.
        local hoverHeight = tonumber(Config.SaberExpertHoverHeight) or 20
        desired = CFrame.new(
            root.Position + Vector3.new(0, hoverHeight, 0),
            root.Position
        )
    elseif enemyName == "Mob Leader" then
        -- Mob Leader sits next to cliff/ceiling geometry. Fight from a clear SIDE
        -- position instead of directly above, otherwise the player can get stuck
        -- inside the rock and never reach a valid FastAttack range.
        SaberSystem.ReleaseSaberExpertHover()
        desired = SaberSystem.GetMobLeaderCombatCFrame(root)
            or CFrame.new(root.Position + Vector3.new(0, 3, 8), root.Position)
    else
        SaberSystem.ReleaseSaberExpertHover()
        desired = CFrame.new(
            root.Position + Vector3.new(0, tonumber(Config.FarmAboveHeight) or 7.5, 0)
        )
    end

    local distance = (hrp.Position - desired.Position).Magnitude

    SaberSystem.Cache.Distance = distance
    SaberSystem.SetCache("Fighting " .. enemyName, "HP " .. tostring(math.floor(hum.Health)))
    UI.SetStatus("Saber Quest | fighting " .. enemyName, true)

    local approach
    if enemyName == "Saber Expert" then
        approach = tonumber(Config.SaberExpertApproachDistance) or 7
    elseif enemyName == "Mob Leader" then
        approach = tonumber(Config.SaberMobLeaderAttackRange) or 18
    else
        approach = 10
    end

    if enemyName == "Saber Expert" and Config.SaberExpertHoverCombat ~= false then
        if distance > 45 then
            SaberSystem.ReleaseSaberExpertHover()
            Teleport.To(desired, Config.FarmSpeed or Config.TweenSpeed, "SABER", true)
            return true
        end

        if Teleport.IsBusy() and Teleport.Owner == "SABER" then
            Teleport.Cancel()
            Teleport.ExclusiveOwner = "SABER"
        end

        -- From here the player is held 25 studs above the CURRENT boss position.
        -- Updating the BodyPosition every tick makes the character follow the boss
        -- without ever moving or freezing the boss itself.
        SaberSystem.UpdateSaberExpertHover(root)
    else
        local realBossDistance = (hrp.Position - root.Position).Magnitude
        local canAttackNow = enemyName == "Mob Leader"
            and realBossDistance <= (tonumber(Config.SaberMobLeaderAttackRange) or 18)

        -- For Mob Leader, once the REAL boss is already in hit range, stop chasing
        -- an exact CFrame. This prevents the character from repeatedly climbing
        -- into the cliff while FastAttack is waiting.
        if distance > approach and not canAttackNow then
            Teleport.To(desired, Config.FarmSpeed or Config.TweenSpeed, "SABER", true)
            return true
        end

        if Teleport.IsBusy() and Teleport.Owner == "SABER" then
            Teleport.Cancel()
            Teleport.ExclusiveOwner = "SABER"
        end

        pcall(function()
            if enemyName == "Mob Leader" then
                -- Keep the character beside the boss and upright.
                hrp.CFrame = desired
            else
                hrp.CFrame = desired
            end
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    Utils.EnsureMeleeEquipped(true)
    HakiSystem.ActivateBuso()

    local now = tick()
    local cooldown = math.max(0.06, tonumber(Config.SaberBossAttackSpeed) or 0.08)

    if bossTargetChanged or now - (SaberSystem.LastBossAttack or 0) >= cooldown then
        SaberSystem.LastBossAttack = now

        if enemyName == "Saber Expert" then
            -- Use the full FastAttack routine here. Some current Blox Fruits builds
            -- do not register the old RigController-only path reliably for melee.
            -- This still does not modify the boss physics; it only sends attack hits.
            Attack.ExecuteAttack(enemy)
        else
            Attack.ExecuteAttack(enemy)
        end
    end

    return true
end

function SaberSystem.GetPlateButtons(plates)
    local result = {}

    if not plates then
        return result
    end

    for i = 1, 5 do
        local plateName = "Plate" .. tostring(i)
        local plate = plates:FindFirstChild(plateName)
            or plates:FindFirstChild(plateName, true)

        if plate then
            local button = plate:FindFirstChild("Button")
                or plate:FindFirstChild("Button", true)

            if not button then
                button = plate:FindFirstChildWhichIsA("BasePart", true)
            end

            if button and button:IsA("BasePart") then
                result[i] = button
            end
        end
    end

    return result
end

function SaberSystem.IsPlateActive(button)
    if not button or not button:IsA("BasePart") then
        return false
    end

    if button.BrickColor == BrickColor.new("Camo") then
        return true
    end

    if button:GetAttribute("Active") == true then
        return true
    end

    return false
end

function SaberSystem.GetPlateProgress(plates)
    local buttons = SaberSystem.GetPlateButtons(plates)
    local active = 0
    local visibleTotal = 0

    for i = 1, 5 do
        local button = buttons[i]

        if button then
            visibleTotal = visibleTotal + 1

            if SaberSystem.IsPlateActive(button) then
                active = active + 1
            end
        end
    end

    SaberSystem.Cache.PlatesActive = active
    SaberSystem.Cache.PlatesTotal = 5

    return active, visibleTotal, buttons
end

function SaberSystem.GetNextPlate(plates)
    local active, total, buttons = SaberSystem.GetPlateProgress(plates)

    if SaberSystem.CurrentPlateIndex then
        local currentButton = buttons[SaberSystem.CurrentPlateIndex]

        if currentButton and not SaberSystem.IsPlateActive(currentButton) then
            return currentButton, SaberSystem.CurrentPlateIndex, active, total
        end

        SaberSystem.CurrentPlateIndex = nil
        SaberSystem.Cache.PlateAttempts = 0
    end

    for i = 1, 5 do
        local button = buttons[i]

        if button and not SaberSystem.IsPlateActive(button) then
            SaberSystem.CurrentPlateIndex = i
            SaberSystem.Cache.PlateAttempts = 0
            return button, i, active, total
        end
    end

    return nil, nil, active, total
end

function SaberSystem.ActivatePlate(plates)
    local hrp = Utils.HRP()

    if not hrp then
        return true
    end

    local button, index, active = SaberSystem.GetNextPlate(plates)

    if not button or not index then
        SaberSystem.Cache.NextPlate = "-"
        SaberSystem.SetCache(
            "All visible Jungle plates activated",
            tostring(active) .. "/5 confirmed"
        )
        return true
    end

    SaberSystem.Cache.NextPlate = "Plate" .. tostring(index)

    local arrived = SaberSystem.MoveTo(
        button.CFrame + Vector3.new(0, 2.2, 0),
        "activating Plate " .. tostring(index)
            .. " (" .. tostring(active) .. "/5)"
    )

    if not arrived then
        return true
    end

    local now = tick()

    if now - (SaberSystem.LastPlateTouchAt or 0) < 0.35 then
        return true
    end

    SaberSystem.LastPlateTouchAt = now
    SaberSystem.Cache.PlateAttempts = (SaberSystem.Cache.PlateAttempts or 0) + 1

    -- Stop exactly on the current button. Do not advance until it is confirmed.
    Teleport.Cancel()
    Teleport.ExclusiveOwner = "SABER"

    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = button.CFrame + Vector3.new(0, 1.2, 0)
    end)

    if type(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(hrp, button, 0)
            task.wait(0.10)
            firetouchinterest(hrp, button, 1)
        end)
    else
        task.wait(0.12)
    end

    -- Second contact if the first touch was missed by streaming/network ownership.
    if not SaberSystem.IsPlateActive(button) then
        pcall(function()
            hrp.CFrame = button.CFrame
        end)

        task.wait(0.12)

        if type(firetouchinterest) == "function" then
            pcall(function()
                firetouchinterest(hrp, button, 0)
                task.wait(0.08)
                firetouchinterest(hrp, button, 1)
            end)
        end
    end

    local newActive = SaberSystem.GetPlateProgress(plates)

    if SaberSystem.IsPlateActive(button) then
        if newActive >= 5 then
            SaberSystem.MarkProgress("PlatesDone")
        end

        SaberSystem.SetCache(
            "Plate " .. tostring(index) .. " activated",
            tostring(newActive) .. "/5 plates"
        )
        SaberSystem.CurrentPlateIndex = nil
        SaberSystem.Cache.PlateAttempts = 0
        SaberSystem.Cache.NextPlate = "-"
    else
        SaberSystem.SetCache(
            "Retrying Plate " .. tostring(index),
            "Touch not confirmed"
        )
    end

    return true
end


function SaberSystem.GetBurnApproachCFrame(burnPart)
    local hrp = Utils.HRP()

    if not burnPart or not burnPart:IsA("BasePart") or not hrp then
        return nil
    end

    local margin = tonumber(Config.SaberTorchSideMargin) or 1.35
    local halfX = (burnPart.Size.X * 0.5) + margin
    local halfZ = (burnPart.Size.Z * 0.5) + margin

    -- Stand low enough for the held Torch to touch the curtain rather than
    -- targeting the curtain's geometric center.
    local localY = -(burnPart.Size.Y * 0.5) + 2.6

    local offsets = {
        Vector3.new( halfX, localY, 0),
        Vector3.new(-halfX, localY, 0),
        Vector3.new(0, localY,  halfZ),
        Vector3.new(0, localY, -halfZ),
    }

    local candidates = {}

    for i, offset in ipairs(offsets) do
        local worldPos = burnPart.CFrame:PointToWorldSpace(offset)

        table.insert(candidates, {
            Index = i,
            Position = worldPos,
            Distance = (hrp.Position - worldPos).Magnitude,
        })
    end

    table.sort(candidates, function(a, b)
        return a.Distance < b.Distance
    end)

    -- Start from the closest side. If repeated attempts fail, cycle around
    -- the curtain so changed map geometry does not trap the Kaitun outside.
    local retryOffset = math.floor((SaberSystem.BurnAttempts or 0) / 3)
    local selectedIndex = ((retryOffset) % #candidates) + 1
    local selected = candidates[selectedIndex]

    SaberSystem.BurnSideIndex = selected.Index

    return CFrame.new(selected.Position, burnPart.Position)
end

function SaberSystem.BurnDesertCurtain(objects)
    local hrp = Utils.HRP()
    local char = Utils.Character()

    if not hrp or not char then
        return true
    end

    if objects and objects.BurnOpen then
        SaberSystem.MarkProgress("TorchCollected")
        SaberSystem.MarkProgress("BurnDone")
        SaberSystem.BurnAttempts = 0
        SaberSystem.BurnHoldStartedAt = 0
        SaberSystem.ReleaseGroundHold()
        SaberSystem.SetCache("Curtain burned", "Opening Cup room")
        return false
    end

    local burnPart = objects and objects.BurnPart or nil

    -- If the Desert is not fully streamed yet, go to the old area only as a
    -- streaming fallback. Once Burn.Part exists, all movement uses the live part.
    if not burnPart then
        SaberSystem.SetCache("Loading Desert curtain", "Burn.Part not streamed")
        SaberSystem.MoveTo(CFrame.new(1113, 8, 4352), "loading Desert curtain")
        return true
    end

    local torch = SaberSystem.GetEquippedTool("Torch")

    if not torch then
        SaberSystem.SetCache("Equipping Torch", "Locking Saber quest item")
        SaberSystem.EquipTool("Torch")
        return true
    end

    SaberSystem.ActiveQuestItem = "Torch"

    local targetCF = SaberSystem.GetBurnApproachCFrame(burnPart)

    if not targetCF then
        SaberSystem.SetCache("Locating curtain", "No valid Burn.Part approach")
        return true
    end

    local distance = (hrp.Position - targetCF.Position).Magnitude
    SaberSystem.Cache.Distance = distance
    SaberSystem.SetCache(
        "Burning Desert curtain",
        "Side " .. tostring(SaberSystem.BurnSideIndex or "?")
            .. " | Try " .. tostring((SaberSystem.BurnAttempts or 0) + 1)
    )

    if distance > (tonumber(Config.SaberTorchDistance) or 4.0) then
        SaberSystem.ReleaseGroundHold()
        SaberSystem.BurnHoldStartedAt = 0
        Teleport.To(targetCF, Config.TweenSpeed, "SABER", true)
        return true
    end

    if Teleport.IsBusy() and Teleport.Owner == "SABER" then
        Teleport.Cancel()
        Teleport.ExclusiveOwner = "SABER"
    end

    -- Once close enough, stand still on the ground. No repeated CFrame snap.
    SaberSystem.HoldGround("TORCH_BURN", targetCF)

    -- If Roblox unequipped the Torch while travelling, restore it before the hold.
    if not SaberSystem.GetEquippedTool("Torch") then
        SaberSystem.EquipTool("Torch")
        SaberSystem.BurnHoldStartedAt = 0
        return true
    end

    local now = tick()

    if (SaberSystem.BurnHoldStartedAt or 0) == 0 then
        SaberSystem.BurnHoldStartedAt = now
    end

    local torchHandle = torch:FindFirstChild("Handle")

    -- Fire a real touch pair when the executor exposes it. Physical standing
    -- remains the fallback, matching the game's normal puzzle interaction.
    if torchHandle
        and type(firetouchinterest) == "function"
        and now - (SaberSystem.LastBurnTouchAt or 0) >= 0.25 then

        SaberSystem.LastBurnTouchAt = now

        pcall(function()
            firetouchinterest(torchHandle, burnPart, 0)
            task.wait(0.06)
            firetouchinterest(torchHandle, burnPart, 1)
        end)
    end

    local holdTime = tonumber(Config.SaberTorchHoldTime) or 0.75

    if now - SaberSystem.BurnHoldStartedAt < holdTime then
        SaberSystem.SetCache(
            "Holding Torch at curtain",
            string.format("%.1f/%.1fs", now - SaberSystem.BurnHoldStartedAt, holdTime)
        )
        return true
    end

    -- Re-check the live part after standing still.
    if not burnPart.Parent or burnPart.CanCollide == false then
        SaberSystem.MarkProgress("TorchCollected")
        SaberSystem.MarkProgress("BurnDone")
        SaberSystem.BurnAttempts = 0
        SaberSystem.BurnHoldStartedAt = 0
        SaberSystem.ReleaseGroundHold()
        SaberSystem.SetCache("Curtain burned", "Cup room unlocked")
        return false
    end

    local retryInterval = tonumber(Config.SaberTorchRetryInterval) or 0.65

    if now - SaberSystem.BurnHoldStartedAt >= (holdTime + retryInterval) then
        SaberSystem.BurnAttempts = (SaberSystem.BurnAttempts or 0) + 1
        SaberSystem.BurnHoldStartedAt = 0

        SaberSystem.SetCache(
            "Retrying Desert curtain",
            "Switching contact position | Try "
                .. tostring(SaberSystem.BurnAttempts + 1)
        )
    end

    return true
end


function SaberSystem.GetCupWaterCFrame()
    return Config.SaberCupWaterPosition1
end

function SaberSystem.SwitchCupWaterPoint()
    -- Only one droplet position is used now. Reset and retry the same spot.
    SaberSystem.ReleaseGroundHold()
    SaberSystem.ReleaseCupLift()

    SaberSystem.CupWaterIndex = 1
    SaberSystem.CupWaterTryStartedAt = 0
    SaberSystem.CupWaterAttempts = (SaberSystem.CupWaterAttempts or 0) + 1
    SaberSystem.CupLiftActive = false
    SaberSystem.CupLiftStartedAt = 0
    SaberSystem.CupLastLiftAt = 0
    SaberSystem.CupDashDoneForAttempt = false
    SaberSystem.CupDashAt = 0
end

function SaberSystem.ReleaseCupLift()
    if SaberSystem.CupLiftBodyPosition
        and SaberSystem.CupLiftBodyPosition.Parent then
        pcall(function()
            SaberSystem.CupLiftBodyPosition:Destroy()
        end)
    end

    SaberSystem.CupLiftBodyPosition = nil
    SaberSystem.CupLiftActive = false
    SaberSystem.CupLiftStartedAt = 0
end

function SaberSystem.LiftCupIntoWater(sourceCF)
    if not AutomationMovementAllowed() then
        SaberSystem.ReleaseCupLift()
        return false
    end

    local hrp = Utils.HRP()
    local hum = Utils.Humanoid()
    local cup = SaberSystem.GetEquippedTool("Cup")

    if not hrp or not hum or not cup then
        return false
    end

    local handle = cup:FindFirstChild("Handle")

    SaberSystem.ReleaseGroundHold()
    SaberSystem.ReleaseCupLift()
    Teleport.Cancel()
    Teleport.ExclusiveOwner = "SABER"

    local exactPosition = sourceCF.Position
    local lookVector = sourceCF.LookVector

    if lookVector.Magnitude < 0.01 then
        lookVector = Vector3.new(0, 0, -1)
    end

    local desiredHRPPosition = exactPosition

    if Config.SaberCupHandleAlign ~= false and handle then
        local currentOffset = hrp.Position - handle.Position
        local manualOffset = Config.SaberCupHandleOffset or Vector3.zero
        desiredHRPPosition = exactPosition + currentOffset + manualOffset
    end

    pcall(function()
        hrp.CFrame = CFrame.new(
            desiredHRPPosition,
            desiredHRPPosition + lookVector
        )
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hum.WalkSpeed = 0
        hum.AutoRotate = false
        hum.Jump = false
    end)

    local hold = Instance.new("BodyPosition")
    hold.Name = "KratosCupExactWaterHold"
    hold.P = 28000
    hold.D = 2000
    hold.MaxForce = Vector3.new(
        1000000000,
        1000000000,
        1000000000
    )
    hold.Position = desiredHRPPosition
    hold.Parent = hrp

    SaberSystem.CupLiftBodyPosition = hold
    SaberSystem.CupLiftActive = true
    SaberSystem.CupLiftStartedAt = tick()
    SaberSystem.CupLastLiftAt = tick()

    return true
end

function SaberSystem.FillCup()
    local hrp = Utils.HRP()
    local cup = SaberSystem.GetEquippedTool("Cup")

    if not hrp then
        return true
    end

    if not cup then
        SaberSystem.SetCache("Equipping Cup", "Holding cup for water drop")
        SaberSystem.ReleaseCupLift()
        SaberSystem.EquipTool("Cup")
        return true
    end

    SaberSystem.ActiveQuestItem = "Cup"

    local sourceCF = SaberSystem.GetCupWaterCFrame()
    local exactPosition = sourceCF.Position
    local distance = (hrp.Position - exactPosition).Magnitude

    SaberSystem.Cache.Distance = distance

    if distance > (tonumber(Config.SaberCupInteractDistance) or 5.5) then
        SaberSystem.ReleaseGroundHold()
        SaberSystem.ReleaseCupLift()

        SaberSystem.SetCache(
            "Moving to water drop",
            string.format("%.1f studs away", distance)
        )

        SaberSystem.MoveTo(
            sourceCF,
            "moving to water drop"
        )

        SaberSystem.CupWaterTryStartedAt = 0
        return true
    end

    if Teleport.IsBusy() and Teleport.Owner == "SABER" then
        Teleport.Cancel()
        Teleport.ExclusiveOwner = "SABER"
    end

    local handle = cup:FindFirstChild("Handle")

    -- Cup filled successfully.
    if handle and not handle:FindFirstChild("TouchInterest") then
        SaberSystem.MarkProgress("CupCollected")
        SaberSystem.MarkProgress("CupFilled")
        SaberSystem.ReleaseCupLift()
        SaberSystem.ReleaseGroundHold()

        SaberSystem.SetCache(
            "Cup filled",
            "Water drop activated"
        )

        SaberSystem.CupWaterTryStartedAt = 0
        SaberSystem.CupWaterAttempts = 0
        return false
    end

    local now = tick()

    if (SaberSystem.CupWaterTryStartedAt or 0) == 0 then
        SaberSystem.CupWaterTryStartedAt = now
        SaberSystem.CupDashDoneForAttempt = false
        SaberSystem.CupDashAt = 0
    end

    -- The tested interaction sometimes registers when the Cup crosses the drop
    -- during a short forward dash. Do it exactly once per water attempt.
    if Config.SaberCupDashOnFill ~= false and not SaberSystem.CupDashDoneForAttempt then
        SaberSystem.CupDashDoneForAttempt = true
        SaberSystem.CupDashAt = now
        SaberSystem.ReleaseCupLift()
        SaberSystem.ReleaseGroundHold()
        Teleport.Cancel()
        Teleport.ExclusiveOwner = "SABER"

        SaberSystem.SetCache("Filling cup", "Dashing through water drop")
        Utils.SendKey(Enum.KeyCode.Q)
        return true
    end

    local dashDelay = tonumber(Config.SaberCupDashDelay) or 0.22
    if (SaberSystem.CupDashAt or 0) > 0
        and (now - SaberSystem.CupDashAt) < dashDelay then
        return true
    end

    -- After the dash, check whether the Cup filled before doing precise alignment.
    handle = cup:FindFirstChild("Handle")
    if handle and not handle:FindFirstChild("TouchInterest") then
        SaberSystem.MarkProgress("CupCollected")
        SaberSystem.MarkProgress("CupFilled")
        SaberSystem.ReleaseCupLift()
        SaberSystem.ReleaseGroundHold()
        SaberSystem.SetCache("Cup filled", "Dash activated water drop")
        SaberSystem.CupWaterTryStartedAt = 0
        SaberSystem.CupWaterAttempts = 0
        SaberSystem.CupDashDoneForAttempt = false
        SaberSystem.CupDashAt = 0
        return false
    end

    local elapsed = now - SaberSystem.CupWaterTryStartedAt
    local tryTime = tonumber(Config.SaberCupWaterTryTime) or 3.0
    local holdTime = tonumber(Config.SaberCupLiftHoldTime) or 0.85
    local reliftDelay = tonumber(Config.SaberCupReliftDelay) or 0.45

    if not SaberSystem.CupLiftActive then
        SaberSystem.SetCache(
            "Filling cup",
            "Positioning cup at the water drop"
        )

        SaberSystem.LiftCupIntoWater(sourceCF)
        return true
    end

    local liftElapsed = now - (SaberSystem.CupLiftStartedAt or now)

    -- Keep the character completely still while the Cup touches the drop.
    if SaberSystem.CupLiftBodyPosition
        and SaberSystem.CupLiftBodyPosition.Parent then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    SaberSystem.SetCache(
        "Trying to fill cup",
        string.format(
            "Holding cup in water %.1f/%.1fs",
            math.min(liftElapsed, holdTime),
            holdTime
        )
    )

    if liftElapsed >= holdTime then
        SaberSystem.ReleaseCupLift()

        -- Re-check after the vertical contact.
        handle = cup:FindFirstChild("Handle")

        if handle and not handle:FindFirstChild("TouchInterest") then
            SaberSystem.MarkProgress("CupCollected")
            SaberSystem.MarkProgress("CupFilled")
            SaberSystem.ReleaseGroundHold()

            SaberSystem.SetCache(
                "Cup filled",
                "Exact water position confirmed"
            )

            SaberSystem.CupWaterTryStartedAt = 0
            SaberSystem.CupWaterAttempts = 0
            return false
        end

        if now - (SaberSystem.CupLastLiftAt or 0) < reliftDelay then
            return true
        end
    end

    -- If the current water point still does not work after the full attempt,
    -- use the backup point already present in the Kaitun.
    if elapsed >= tryTime then
        SaberSystem.ReleaseCupLift()
        SaberSystem.SwitchCupWaterPoint()

        SaberSystem.SetCache(
            "Water drop did not trigger",
            "Retrying the same water drop"
        )
    end

    return true
end

function SaberSystem.RefreshProgressEvidence(objects, richProgress, sickProgress)
    local flags = SaberSystem.ProgressFlags
    local hrp = Utils.HRP()

    local plates = objects and objects.Plates or nil
    local activePlates = 0

    if plates then
        activePlates = SaberSystem.GetPlateProgress(plates)

        if activePlates >= 5 then
            SaberSystem.MarkProgress("PlatesDone")
        end
    end

    if SaberSystem.HasTool("Torch") then
        SaberSystem.MarkProgress("TorchCollected")
    end

    if objects and objects.BurnOpen then
        SaberSystem.MarkProgress("BurnDone")
    end

    if SaberSystem.TorchCheckDone and not SaberSystem.HasTool("Torch") then
        SaberSystem.MarkProgress("TorchCollected")
        SaberSystem.MarkProgress("BurnDone")
    end

    if SaberSystem.HasTool("Cup") then
        SaberSystem.MarkProgress("CupCollected")

        local cup = SaberSystem.GetTool("Cup")
        local handle = cup and cup:FindFirstChild("Handle")

        if handle and not handle:FindFirstChild("TouchInterest") then
            SaberSystem.MarkProgress("CupFilled")
        end
    end

    if SaberSystem.IsSickManDone() then
        SaberSystem.MarkProgress("SickManDone")
    end

    if SaberSystem.HasTool("Relic") then
        SaberSystem.MarkProgress("RelicObtained")
    end

    -- Recovery after a successful burn: Torch can disappear immediately.
    if flags.TorchCollected
        and not flags.BurnDone
        and flags.PlatesDone
        and objects
        and objects.Desert
        and objects.Cup
        and not SaberSystem.HasTool("Torch")
        and hrp then

        local cupCF = GetInstanceCFrameSafe(objects.Cup)

        if cupCF then
            local distanceToCup = (hrp.Position - cupCF.Position).Magnitude

            if distanceToCup <= 120 then
                SaberSystem.MarkProgress("BurnDone")
            end
        end
    end

    if flags.BurnDone then
        SaberSystem.MarkProgress("TorchCollected")
    end

    if flags.CupCollected then
        SaberSystem.MarkProgress("BurnDone")
        SaberSystem.MarkProgress("TorchCollected")
    end

    if flags.CupFilled then
        SaberSystem.MarkProgress("CupCollected")
    end

    if flags.SickManDone then
        SaberSystem.MarkProgress("CupFilled")
        SaberSystem.MarkProgress("CupCollected")
    end

    return activePlates
end

function SaberSystem.TouchWorldObject(instance, radius)
    local hrp = Utils.HRP()

    if not hrp or not instance then
        return false
    end

    local cf = GetInstanceCFrameSafe(instance)

    if not cf then
        return false
    end

    local maxDistance = tonumber(radius) or 8
    local distance = (hrp.Position - cf.Position).Magnitude

    if distance > maxDistance then
        SaberSystem.MoveTo(cf + Vector3.new(0, 2.5, 0), "approaching quest item")
        return false
    end

    if Teleport.IsBusy() and Teleport.Owner == "SABER" then
        Teleport.Cancel()
        Teleport.ExclusiveOwner = "SABER"
    end

    local touchPart = nil

    if instance:IsA("BasePart") then
        touchPart = instance
    elseif instance:IsA("Tool") then
        touchPart = instance:FindFirstChild("Handle")
    elseif instance:IsA("Model") then
        touchPart = instance.PrimaryPart
            or instance:FindFirstChildWhichIsA("BasePart", true)
    else
        touchPart = instance:FindFirstChildWhichIsA("BasePart", true)
    end

    if touchPart and type(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(hrp, touchPart, 0)
            task.wait(0.08)
            firetouchinterest(hrp, touchPart, 1)
        end)
    end

    return true
end

function SaberSystem.HandleTorchPickupCheck(objects)
    if SaberSystem.ProgressFlags.TorchCollected
        or SaberSystem.ProgressFlags.BurnDone then
        return false
    end

    local hrp = Utils.HRP()

    if not hrp then
        return true
    end

    local torch = objects and objects.Torch or nil
    local torchCF = torch and GetInstanceCFrameSafe(torch) or nil

    -- First go to the live Torch object when it exists.
    if torchCF then
        local distance = (hrp.Position - torchCF.Position).Magnitude
        SaberSystem.Cache.Distance = distance

        if distance > (tonumber(Config.SaberTorchPickupRadius) or 8) then
            SaberSystem.CurrentStep = "GET_TORCH"
            SaberSystem.SetCache("Going to Torch", "One-time Torch verification")
            SaberSystem.MoveTo(torchCF + Vector3.new(0, 2.5, 0), "going to Torch")
            SaberSystem.TorchCheckStartedAt = 0
            return true
        end

        SaberSystem.TouchWorldObject(
            torch,
            tonumber(Config.SaberTorchPickupRadius) or 8
        )
    else
        -- Same Jungle Torch room fallback. Only used to verify the stage once.
        local fallbackCF = CFrame.new(-1610, 12, 165)
        local distance = (hrp.Position - fallbackCF.Position).Magnitude

        if distance > (tonumber(Config.SaberTorchPickupRadius) or 8) then
            SaberSystem.CurrentStep = "GET_TORCH"
            SaberSystem.SetCache("Checking Torch room", "Torch object not visible")
            SaberSystem.MoveTo(fallbackCF, "checking Torch")
            SaberSystem.TorchCheckStartedAt = 0
            return true
        end
    end

    -- If the Torch appears, use it normally.
    if SaberSystem.HasTool("Torch") then
        SaberSystem.MarkProgress("TorchCollected")
        SaberSystem.TorchCheckDone = true
        SaberSystem.TorchCheckStartedAt = 0

        SaberSystem.CurrentStep = "EQUIP_TORCH"
        SaberSystem.SetCache("Torch obtained", "Continuing to Desert curtain")
        SaberSystem.EquipTool("Torch")
        return true
    end

    -- User-requested rule:
    -- We reached the Torch pickup point and still have no Torch.
    -- After a short verification window, assume the Torch/Burn stage was
    -- already completed and advance permanently to the Cup.
    local now = tick()

    if (SaberSystem.TorchCheckStartedAt or 0) == 0 then
        SaberSystem.TorchCheckStartedAt = now
    end

    local elapsed = now - SaberSystem.TorchCheckStartedAt
    local checkTime = tonumber(Config.SaberTorchPickupCheckTime) or 2.0

    SaberSystem.CurrentStep = "CHECK_TORCH"
    SaberSystem.SetCache(
        "Checking Torch inventory",
        string.format("%.1f/%.1fs", elapsed, checkTime)
    )

    if elapsed < checkTime then
        return true
    end

    SaberSystem.MarkProgress("TorchCollected")
    SaberSystem.MarkProgress("BurnDone")
    SaberSystem.TorchCheckDone = true
    SaberSystem.TorchCheckStartedAt = 0

    SaberSystem.CurrentStep = "GET_CUP"
    SaberSystem.SetCache(
        "Torch not found - stage already done",
        "Skipping permanently to Cup"
    )

    return false
end

function SaberSystem.GetCupPickupPart(instance)
    if not instance then
        return nil
    end

    -- The Saber cup uses a touch transmitter. If the Cup is a model/container,
    -- always prefer the exact BasePart that owns TouchInterest instead of an
    -- arbitrary PrimaryPart/pedestal part.
    local function hasTouchTransmitter(part)
        if not part or not part:IsA("BasePart") then
            return false
        end

        if part:FindFirstChild("TouchInterest") then
            return true
        end

        local ok, transmitter = pcall(function()
            return part:FindFirstChildWhichIsA("TouchTransmitter")
        end)

        return ok and transmitter ~= nil
    end

    if instance:IsA("BasePart") and hasTouchTransmitter(instance) then
        return instance
    end

    if instance:IsA("Tool") then
        local handle = instance:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            return handle
        end
    end

    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("BasePart") and hasTouchTransmitter(descendant) then
            return descendant
        end
    end

    if instance:IsA("BasePart") then
        return instance
    end

    if instance:IsA("Model") then
        return instance.PrimaryPart
            or instance:FindFirstChildWhichIsA("BasePart", true)
    end

    return instance:FindFirstChildWhichIsA("BasePart", true)
end

function SaberSystem.GetLiveDesertCup()
    local map = workspace:FindFirstChild("Map")
    local desert = map and map:FindFirstChild("Desert")
    if not desert then
        return nil
    end

    -- REDZ and the live map both expose this exact object as Map.Desert.Cup.
    -- Prefer the direct child first so a recursive search cannot select an
    -- unrelated decorative object named Cup.
    return desert:FindFirstChild("Cup") or desert:FindFirstChild("Cup", true)
end

function SaberSystem.ForceCupPickupContact(cup)
    if SaberSystem.CupPickupBusy then
        return true
    end

    local char = Utils.Character()
    local hrp = Utils.HRP()
    local hum = Utils.Humanoid()
    local liveCup = SaberSystem.GetLiveDesertCup() or cup
    local touchPart = SaberSystem.GetCupPickupPart(liveCup)

    if not char or not hrp or not hum or not touchPart then
        return false
    end

    local now = tick()
    local interval = tonumber(Config.SaberCupPickupContactInterval) or 0.35

    if now - (SaberSystem.CupPickupLastContactAt or 0) < interval then
        return true
    end

    SaberSystem.CupPickupLastContactAt = now
    SaberSystem.CupPickupContactAttempt = (SaberSystem.CupPickupContactAttempt or 0) + 1
    SaberSystem.CupPickupBusy = true

    SaberSystem.ReleaseGroundHold()

    if Teleport.IsBusy() and Teleport.Owner == "SABER" then
        Teleport.Cancel()
    end

    Teleport.ExclusiveOwner = "SABER"
    SafetySystem.IgnoreUntil = now + 2

    local yOffset = tonumber(Config.SaberCupPickupSnapYOffset) or 0
    local radius = tonumber(Config.SaberCupPickupSweepRadius) or 1.15
    local holdTime = tonumber(Config.SaberCupPickupAttemptHold) or 0.10
    local targetCF = touchPart.CFrame + Vector3.new(0, yOffset, 0)

    task.spawn(function()
        local oldCollide = {}

        local function finishAttempt()
            for part, value in pairs(oldCollide) do
                if part and part.Parent then
                    pcall(function()
                        part.CanCollide = value
                    end)
                end
            end
            SaberSystem.CupPickupBusy = false
        end

        -- Prevent the pedestal/wall from pushing the avatar away from the
        -- actual cup while we sweep through its touch part.
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                oldCollide[part] = part.CanCollide
                pcall(function()
                    part.CanCollide = false
                end)
            end
        end

        local offsets = {
            Vector3.new(0, 0, 0),
            Vector3.new(radius, 0, 0),
            Vector3.new(-radius, 0, 0),
            Vector3.new(0, 0, radius),
            Vector3.new(0, 0, -radius),
            Vector3.new(0, -0.65, 0),
            Vector3.new(0, 0.65, 0),
        }

        for _, offset in ipairs(offsets) do
            if SaberSystem.HasTool("Cup") then
                break
            end

            if not hrp.Parent or not touchPart.Parent then
                break
            end

            pcall(function()
                hrp.CFrame = targetCF + offset
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hum.Jump = false
            end)

            -- Prefer the actual touch transmitter part. Fire every character
            -- BasePart against it because some executors/rigs ignore HRP-only
            -- touch simulation.
            if type(firetouchinterest) == "function" then
                pcall(function()
                    for _, bodyPart in ipairs(char:GetDescendants()) do
                        if bodyPart:IsA("BasePart") then
                            firetouchinterest(bodyPart, touchPart, 0)
                            task.wait()
                            firetouchinterest(bodyPart, touchPart, 1)
                        end
                    end
                end)
            end

            task.wait(holdTime)
        end

        finishAttempt()
    end)

    return true
end

function SaberSystem.HandleCupPickup(objects)
    if SaberSystem.HasTool("Cup") then
        SaberSystem.MarkProgress("CupCollected")
        SaberSystem.CupCheckStartedAt = 0
        SaberSystem.CupPickupContactAttempt = 0
        SaberSystem.CupPickupLastContactAt = 0
        SaberSystem.CupPickupBusy = false
        return false
    end

    local hrp = Utils.HRP()

    if not hrp then
        return true
    end

    local cup = SaberSystem.GetLiveDesertCup() or (objects and objects.Cup or nil)
    local touchPart = SaberSystem.GetCupPickupPart(cup)
    local cupCF = touchPart and touchPart.CFrame or (cup and GetInstanceCFrameSafe(cup) or nil)

    if cupCF then
        local distance = (hrp.Position - cupCF.Position).Magnitude
        SaberSystem.Cache.Distance = distance

        SaberSystem.CurrentStep = "GET_CUP"
        SaberSystem.SetCache("Getting Cup", "Touching the Cup directly")

        -- Do not stop above the item.  The old +2.5 Y offset is why the avatar
        -- could stand on the pedestal forever without actually touching Cup.
        if distance > 4.5 then
            SaberSystem.MoveTo(cupCF, "going to Cup")
            SaberSystem.CupCheckStartedAt = 0
            return true
        end

        SaberSystem.ForceCupPickupContact(cup)
    else
        -- Stay by the opened Desert room until the live Cup streams in.
        local cupRoomCF = CFrame.new(1113, 8, 4352)
        local desert = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Desert")
        if desert then
            local burn = desert:FindFirstChild("Burn", true)
            local burnPart = burn and burn:FindFirstChild("Part", true)
            if burnPart then
                cupRoomCF = burnPart.CFrame
            end
        end
        local distance = (hrp.Position - cupRoomCF.Position).Magnitude

        SaberSystem.CurrentStep = "GET_CUP"
        SaberSystem.SetCache("Loading Cup", "Waiting for Cup object")

        if distance > 12 then
            SaberSystem.MoveTo(cupRoomCF, "going to Cup room")
        end

        return true
    end

    if SaberSystem.HasTool("Cup") then
        SaberSystem.MarkProgress("CupCollected")
        SaberSystem.CupCheckStartedAt = 0
        SaberSystem.CupPickupContactAttempt = 0
        SaberSystem.CupPickupLastContactAt = 0
        SaberSystem.CupPickupBusy = false

        SaberSystem.CurrentStep = "EQUIP_CUP"
        SaberSystem.SetCache("Cup obtained", "Preparing to fill Cup")
        SaberSystem.EquipTool("Cup")
        return false
    end

    local now = tick()

    if (SaberSystem.CupCheckStartedAt or 0) == 0 then
        SaberSystem.CupCheckStartedAt = now
    end

    local elapsed = now - SaberSystem.CupCheckStartedAt
    local waitTime = tonumber(Config.SaberCupPickupCheckTime) or 2.0

    SaberSystem.SetCache(
        "Picking up Cup",
        "Contact attempt " .. tostring(SaberSystem.CupPickupContactAttempt or 0)
    )

    if elapsed >= waitTime then
        SaberSystem.CupCheckStartedAt = 0
        SaberSystem.SetCache("Retrying Cup pickup", "Cup not in inventory yet")
    end

    return true
end

function SaberSystem.IsNearSaberPoint(cf, radius)
    local hrp = Utils.HRP()
    if not hrp or not cf then
        return false, math.huge
    end

    local distance = (hrp.Position - cf.Position).Magnitude
    return distance <= (tonumber(radius) or 7.5), distance
end

function SaberSystem.MoveToSaberNPC(cf, action, detail)
    local near, distance = SaberSystem.IsNearSaberPoint(
        cf,
        tonumber(Config.SaberNPCInteractDistance) or 7.5
    )

    SaberSystem.Cache.Distance = distance
    SaberSystem.SetCache(action, detail)

    if not near then
        SaberSystem.MoveTo(cf, action)
        return false
    end

    if Teleport.IsBusy() and Teleport.Owner == "SABER" then
        Teleport.Cancel()
        Teleport.ExclusiveOwner = "SABER"
    end

    -- NPC stages must stay completely still. The side-to-side contact sweep is
    -- reserved exclusively for HandleCupPickup() and is never used for NPCs.
    SaberSystem.HoldGround("NPC_" .. tostring(action or "INTERACT"), cf)

    return true
end

function SaberSystem.DeliverFilledCupToSickMan()
    local sickCF = Config.SaberSickManCFrame

    SaberSystem.CurrentStep = "SICK_MAN"
    UI.SetStatus("Saber Quest | taking filled Cup to Sick Man", true)

    if not SaberSystem.MoveToSaberNPC(
        sickCF,
        "Delivering filled Cup",
        "Sick Man - Frozen Village"
    ) then
        return true
    end

    -- If the server already consumed the Cup, the delivery succeeded even if
    -- a previous progress request is still finishing in the background.
    if not SaberSystem.HasTool("Cup") then
        SaberSystem.MarkProgress("SickManDone")
        SaberSystem.CachedSickMan = 1
        SaberSystem.Cache.SickMan = 1
        SaberSystem.SetCache("Sick Man complete", "Going to Rich Man")
        SaberSystem.SickManInteractPending = false
        return false
    end

    local now = tick()
    local cooldown = tonumber(Config.SaberNPCInteractCooldown) or 0.85

    if SaberSystem.SickManInteractPending then
        SaberSystem.SetCache(
            "Giving water to Sick Man",
            "Synchronizing filled Cup with quest"
        )

        -- Do not freeze forever if one executor leaves an InvokeServer thread
        -- waiting. The old task is harmless; a later tick can retry.
        if now - (SaberSystem.SickManInteractStartedAt or now) > 4.0 then
            SaberSystem.SickManInteractPending = false
        end

        return true
    end

    if now - (SaberSystem.LastSickManInteractAt or 0) < cooldown then
        return true
    end

    SaberSystem.LastSickManInteractAt = now
    SaberSystem.SickManInteractPending = true
    SaberSystem.SickManInteractStartedAt = now
    SaberSystem.SickManInteractAttempts = (SaberSystem.SickManInteractAttempts or 0) + 1

    -- Public Saber implementations explicitly sync FillCup before SickMan.
    -- Our visual TouchInterest check can show a full cup before the server-side
    -- puzzle flag is committed, which was the reason the routine could sit in
    -- the Sick Man hut indefinitely.
    task.spawn(function()
        local fillWorked = false
        local sickWorked = false
        local cup = SaberSystem.GetTool("Cup")

        if not CommF_ then
            CommF_ = WaitForCommF(2)
        end

        if CommF_ then
            if cup then
                pcall(function()
                    CommF_:InvokeServer("ProQuestProgress", "FillCup", cup)
                    fillWorked = true
                end)
            end

            task.wait(0.12)

            local firstResult = nil
            pcall(function()
                firstResult = CommF_:InvokeServer("ProQuestProgress", "SickMan")
                sickWorked = true
            end)

            -- Several public Kaituns call SickMan twice when the first response
            -- indicates the interaction still needs to advance. One extra call
            -- is cheap here and makes this work across both observed states.
            if SaberSystem.HasTool("Cup") then
                task.wait(0.12)
                pcall(function()
                    local secondResult = CommF_:InvokeServer("ProQuestProgress", "SickMan")
                    if secondResult ~= nil then
                        firstResult = secondResult
                    end
                    sickWorked = true
                end)
            end
        end

        task.wait(0.10)

        if sickWorked or not SaberSystem.HasTool("Cup") then
            SaberSystem.MarkProgress("SickManDone")
            SaberSystem.CachedSickMan = 1
            SaberSystem.Cache.SickMan = 1
            SaberSystem.SetCache("Sick Man complete", "Going to Rich Man")
            SaberSystem.CupDashDoneForAttempt = false
        end

        SaberSystem.SickManInteractPending = false
    end)

    return true
end

function SaberSystem.GetRichManCFrame()
    -- Prefer the live NPC position when the NPC is replicated. The exact
    -- coordinate below remains the fallback for servers where NPC models
    -- are streamed out or renamed.
    local npcs = workspace:FindFirstChild("NPCs")

    if npcs then
        local candidates = {"Rich Man", "RichMan", "Rich Son", "RichSon"}

        for _, npcName in ipairs(candidates) do
            local npc = npcs:FindFirstChild(npcName, true)

            if npc then
                if npc:IsA("Model") then
                    local root = npc:FindFirstChild("HumanoidRootPart")
                        or npc:FindFirstChild("Head")
                        or npc.PrimaryPart

                    if root and root:IsA("BasePart") then
                        return root.CFrame * CFrame.new(0, 0, 3)
                    end
                elseif npc:IsA("BasePart") then
                    return npc.CFrame * CFrame.new(0, 0, 3)
                end
            end
        end
    end

    return Config.SaberRichManCFrame
        or CFrame.new(-943.8, 27.6, 4115.5)
end

function SaberSystem.InteractRichMan(mode)
    local richCF = SaberSystem.GetRichManCFrame()
    local rewardMode = mode == "reward"

    SaberSystem.CurrentStep = rewardMode and "GET_RELIC" or "RICH_MAN"
    UI.SetStatus(
        rewardMode
            and "Saber Quest | returning to Rich Man for Relic"
            or "Saber Quest | talking to Rich Man",
        true
    )

    if not SaberSystem.MoveToSaberNPC(
        richCF,
        rewardMode and "Getting Ancient Relic" or "Talking to Rich Man",
        "Pirate Village"
    ) then
        return true
    end

    -- We are at the NPC now. Keep the character fixed while the conversation
    -- is open and let the dialogue helper choose only the positive Talk option
    -- ("Conversar" / "Talk"). It never chooses "Esquece" / "Forget".
    if DialogueSuppressor and DialogueSuppressor.Enabled then
        DialogueSuppressor.ActiveUntil = tick() + 3.0
        DialogueSuppressor.ScanVisible(true)
    end

    if SaberSystem.HasTool("Relic") then
        SaberSystem.MarkProgress("RelicObtained")
        SaberSystem.MarkProgress("MobLeaderDone")
        SaberSystem.SetCache("Ancient Relic received", "Returning to Jungle")
        SaberSystem.RichManInteractPending = false
        SaberSystem.ReleaseGroundHold()
        return false
    end

    local now = tick()
    local cooldown = tonumber(Config.SaberNPCInteractCooldown) or 0.85

    if SaberSystem.RichManInteractPending then
        SaberSystem.SetCache(
            rewardMode and "Getting Ancient Relic" or "Talking to Rich Man",
            "Waiting for Rich Man dialogue/progress"
        )

        -- While the remote is pending, still allow the visible positive dialogue
        -- choice to be pressed. This is what fixes the localized "Conversar" UI.
        if DialogueSuppressor and DialogueSuppressor.Enabled then
            DialogueSuppressor.ScanVisible(true)
        end

        if now - (SaberSystem.RichManInteractStartedAt or now) > 4.0 then
            SaberSystem.RichManInteractPending = false
        end

        return true
    end

    if now - (SaberSystem.LastRichManInteractAt or 0) < cooldown then
        if DialogueSuppressor and DialogueSuppressor.Enabled then
            DialogueSuppressor.ScanVisible(true)
        end
        return true
    end

    SaberSystem.LastRichManInteractAt = now
    SaberSystem.RichManInteractPending = true
    SaberSystem.RichManInteractMode = mode
    SaberSystem.RichManInteractStartedAt = now

    task.spawn(function()
        if not CommF_ then
            CommF_ = WaitForCommF(2)
        end

        local result = nil
        if CommF_ then
            pcall(function()
                result = CommF_:InvokeServer("ProQuestProgress", "RichSon")
            end)
        end

        local richState = tonumber(result)
        SaberSystem.RawRichSon = result

        if richState ~= nil then
            SaberSystem.ServerConfirmedRichState = richState
            SaberSystem.CachedRichSon = richState
            SaberSystem.Cache.RichSon = richState
            SaberSystem.RichSonContacted = true
            SaberSystem.MarkProgress("SickManDone")
            SaberSystem.MarkProgress("CupFilled")
            SaberSystem.MarkProgress("CupCollected")

            if richState >= 1 then
                SaberSystem.MarkProgress("MobLeaderDone")
            elseif richState == 0 then
                -- In this server the boss step is still active. If we arrived
                -- here carrying a stale GET_RELIC state from another server,
                -- discard it and fight Mob Leader again.
                SaberSystem.ResetMobLeaderCompletion("Rich Man says Mob Leader is still required")
                SaberSystem.RichSonContacted = true
            end
        else
            SaberSystem.ServerConfirmedRichState = nil
        end

        -- nil means the Rich Man dialogue is open but the positive choice has
        -- not been accepted yet. Do NOT pretend the quest was accepted. The
        -- dialogue helper will press "Conversar"/"Talk", and the next farm tick
        -- probes RichSon again until it becomes 0 or 1.
        if richState == nil then
            SaberSystem.RichSonContacted = false
            SaberSystem.SetCache(
                "Rich Man dialogue",
                rewardMode and "Choose Talk to receive Relic" or "Choose Talk to accept Mob Leader quest"
            )

            task.defer(function()
                if DialogueSuppressor and DialogueSuppressor.Enabled then
                    DialogueSuppressor.ActiveUntil = tick() + 3.0
                    DialogueSuppressor.ScanVisible(true)
                end
            end)

        elseif rewardMode then
            if richState == 0 then
                -- Critical recovery: a server hop before claiming the Relic can
                -- leave our local memory at GET_RELIC while the current server
                -- still expects Mob Leader. Go fight him again instead of
                -- standing forever at Rich Man.
                SaberSystem.ResetMobLeaderCompletion("Server changed before Relic was claimed")
                SaberSystem.CurrentStep = "MOB_LEADER"
                SaberSystem.SetCache("Mob Leader must be defeated again", "Current server reward state is 0")
                SaberSystem.ReleaseGroundHold()
            elseif richState >= 1 then
                -- State 1 means Mob Leader is complete. Calling RichSon again
                -- while at Rich Man awards the Ancient Relic.
                if not SaberSystem.HasTool("Relic") and CommF_ then
                    task.wait(0.18)
                    pcall(function()
                        result = CommF_:InvokeServer("ProQuestProgress", "RichSon")
                    end)
                    task.wait(0.12)
                end

                if SaberSystem.HasTool("Relic") then
                    SaberSystem.MarkProgress("RelicObtained")
                    SaberSystem.MarkProgress("MobLeaderDone")
                    SaberSystem.SetCache("Ancient Relic received", "Returning to Jungle")
                else
                    SaberSystem.SetCache("Waiting for Ancient Relic", "Retrying Rich Man conversation")
                    task.defer(function()
                        if DialogueSuppressor and DialogueSuppressor.Enabled then
                            DialogueSuppressor.ActiveUntil = tick() + 3.0
                            DialogueSuppressor.ScanVisible(true)
                        end
                    end)
                end
            end
        else
            if richState == 0 then
                SaberSystem.SetCache("Rich Man quest accepted", "Going to Mob Leader")
            elseif richState >= 1 then
                -- Account/server already has Mob Leader completion. Skip directly
                -- to the reward conversation on the next tick.
                SaberSystem.SetCache("Mob Leader already complete", "Returning for Ancient Relic")
            end
        end

        -- Force a fresh server probe after every dialogue attempt.
        SaberSystem.LastProgressAt = 0
        SaberSystem.RichManInteractPending = false
    end)

    return true
end

function SaberSystem.PlaceRelicAtJungle(objects)
    local relicCF = Config.SaberRelicSlotCFrame
    local radius = tonumber(Config.SaberRelicInteractDistance) or 7.0

    SaberSystem.CurrentStep = "PLACE_RELIC"
    SaberSystem.SetCache("Placing Ancient Relic", "Jungle Saber door")
    UI.SetStatus("Saber Quest | placing Ancient Relic", true)
    SaberSystem.EquipTool("Relic")

    local near, distance = SaberSystem.IsNearSaberPoint(relicCF, radius)
    SaberSystem.Cache.Distance = distance

    if not near then
        SaberSystem.MoveTo(relicCF, "placing Ancient Relic")
        return true
    end

    if Teleport.IsBusy() and Teleport.Owner == "SABER" then
        Teleport.Cancel()
        Teleport.ExclusiveOwner = "SABER"
    end

    local hrp = Utils.HRP()
    if hrp then
        pcall(function()
            hrp.CFrame = relicCF
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    local now = tick()
    if now - (SaberSystem.LastRelicPlaceAt or 0) >= 0.85 then
        SaberSystem.LastRelicPlaceAt = now

        -- Most versions trigger by physically holding the Relic at the slot.
        -- This remote is a fallback used by several Saber automations.
        pcall(function()
            CommF_:InvokeServer("ProQuestProgress", "PlaceRelic")
        end)
    end

    if objects and objects.FinalPart and objects.FinalPart.CanCollide == false then
        SaberSystem.SetCache("Relic placed", "Saber Expert room opened")
        return false
    end

    return true
end


function SaberSystem.HandlePriority()
    if not Config.AutoSaber then
        if SaberSystem.Active then
            SaberSystem.Finish()
        end
        return false
    end

    if Utils.Level() < 200 then
        return false
    end

    if SaberSystem.Check(false) then
        if SaberSystem.Active then
            SaberSystem.Finish()
        end
        return false
    end

    -- On first startup, wait for the stored-weapon inventory response before
    -- deciding the account still needs the Saber quest. Normal level farm keeps
    -- running during this short check instead of grabbing an old Relic.
    if not SaberSystem.Active and rawget(SaberSystem, "InventoryCheckPending") then
        return false
    end

    if not SaberSystem.Active then
        SaberSystem.Begin()
    end

    Teleport.ExclusiveOwner = "SABER"
    SafetySystem.IgnoreUntil = tick() + 3

    local objects = SaberSystem.GetMapObjects()

    if not objects or not objects.Map then
        SaberSystem.CurrentStep = "WAIT_MAP"
        SaberSystem.SetCache("Loading First Sea map", "Moving near Jungle")
        SaberSystem.MoveTo(CFrame.new(-1612, 36, 149), "loading Jungle map")
        return true
    end

    local char = Utils.Character()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local hrp = Utils.HRP()

    if not char or not backpack or not hrp then
        return true
    end

    local richProgress, sickProgress = SaberSystem.GetProgress()
    SaberSystem.RefreshItemCache()
    SaberSystem.Cache.RichSon = richProgress
    SaberSystem.Cache.SickMan = sickProgress

    local activePlates = SaberSystem.RefreshProgressEvidence(
        objects,
        richProgress,
        sickProgress
    )

    -- Saber story state machine: Cup -> Sick Man -> Rich Man -> Mob Leader
    -- -> Rich Man/Relic -> Jungle slot -> Saber Expert.

    -- Final door open -> Saber Expert.
    if objects.FinalPart and objects.FinalPart.CanCollide == false then
        SaberSystem.CurrentStep = "SABER_EXPERT"
        SaberSystem.SetCache("Defeating Saber Expert", "Final Jungle door open")

        SaberSystem.FightEnemy(
            "Saber Expert",
            CFrame.new(-1461, 30, -51)
        )

        if SaberSystem.Check(true) then
            UI.SetStatus("Saber Quest | Saber acquired | resuming Farm Level", true)
            SaberSystem.Finish()
            return false
        end

        return true
    end

    -- Relic obtained -> physically use it at the Jungle slot.
    if SaberSystem.HasTool("Relic") then
        SaberSystem.MarkProgress("RelicObtained")
        SaberSystem.PlaceRelicAtJungle(objects)
        return true
    end

    local sickDone = SaberSystem.IsSickManDone()

    if sickDone then
        SaberSystem.MarkProgress("SickManDone")

        local richState = tonumber(SaberSystem.RawRichSon)

        -- Only CURRENT-SERVER evidence may send us to GET_RELIC. A stale
        -- MobLeaderDone flag from another server is deliberately ignored.
        if SaberSystem.IsMobLeaderDoneForCurrentServer() then
            SaberSystem.MarkProgress("MobLeaderDone")
            SaberSystem.InteractRichMan("reward")
            return true
        end

        -- nil: Rich Man has not accepted the Mob Leader quest in this server.
        if richState == nil or not SaberSystem.RichSonContacted then
            SaberSystem.InteractRichMan("start")
            return true
        end

        -- 0: quest accepted, Mob Leader must be defeated (again if necessary).
        SaberSystem.CurrentStep = "MOB_LEADER"
        SaberSystem.SetCache("Defeating Mob Leader", "Jean-Luc Island")

        local fighting = SaberSystem.FightEnemy(
            "Mob Leader",
            Config.SaberMobLeaderCFrame or CFrame.new(-2848, 7, 5354)
        )

        if fighting == false then
            SaberSystem.MarkProgress("MobLeaderDone")
            SaberSystem.MobLeaderKilledJobId = game.JobId
            SaberSystem.InteractRichMan("reward")
        end

        return true
    end

    -- Cup equipped: fill it, then physically take it to Sick Man.
    local equippedCup = char:FindFirstChild("Cup")
    if equippedCup then
        SaberSystem.MarkProgress("CupCollected")
        local handle = equippedCup:FindFirstChild("Handle")

        if handle and not handle:FindFirstChild("TouchInterest") then
            SaberSystem.MarkProgress("CupFilled")
            SaberSystem.DeliverFilledCupToSickMan()
            return true
        end

        SaberSystem.CurrentStep = "FILL_CUP"
        SaberSystem.SetCache("Filling Cup", "Frozen Village water")

        local stillFilling = SaberSystem.FillCup()

        if not stillFilling then
            SaberSystem.MarkProgress("CupFilled")
            SaberSystem.CurrentStep = "SICK_MAN"
        end

        return true
    end

    if backpack:FindFirstChild("Cup") then
        SaberSystem.MarkProgress("CupCollected")
        SaberSystem.CurrentStep = "EQUIP_CUP"
        SaberSystem.SetCache("Equipping Cup", "Cup in Backpack")
        UI.SetStatus("Saber Quest | equipping Cup", true)
        SaberSystem.EquipTool("Cup")
        return true
    end

    -- After Torch/Burn is completed, verify the story state before trying to
    -- pick up another Cup. Old accounts may already have delivered the water;
    -- in that case the world Cup cannot be collected anymore by design.
    if SaberSystem.ProgressFlags.BurnDone or objects.BurnOpen then
        SaberSystem.MarkProgress("BurnDone")
        SaberSystem.MarkProgress("TorchCollected")

        if not SaberSystem.ProgressProbeComplete then
            SaberSystem.CurrentStep = "CHECK_SICK_MAN"
            SaberSystem.SetCache(
                "Checking Saber progress",
                "Verifying Sick Man / Rich Man before Cup"
            )
            UI.SetStatus("Saber Quest | checking saved progress", true)
            SaberSystem.GetProgress(true)
            return true
        end

        -- The progress probe may have discovered that this account already
        -- completed the Cup delivery. Route forward instead of retrying GET_CUP.
        if SaberSystem.IsSickManDone() then
            SaberSystem.MarkProgress("SickManDone")
            SaberSystem.MarkProgress("CupFilled")
            SaberSystem.MarkProgress("CupCollected")

            local richState = tonumber(SaberSystem.RawRichSon)

            if SaberSystem.IsMobLeaderDoneForCurrentServer() then
                SaberSystem.MarkProgress("MobLeaderDone")
                SaberSystem.InteractRichMan("reward")
            elseif richState == nil then
                -- New server / unfinished Rich Man dialogue: accept the boss
                -- task first. Do not jump straight to GET_RELIC.
                SaberSystem.RichSonContacted = false
                SaberSystem.InteractRichMan("start")
            else
                -- richState == 0: kill Mob Leader in this server.
                SaberSystem.RichSonContacted = true
                SaberSystem.ResetMobLeaderCompletion("Rich Man boss step is active in this server")
                SaberSystem.CurrentStep = "MOB_LEADER"
                SaberSystem.SetCache(
                    "Sick Man already complete",
                    "Defeating Mob Leader before Relic"
                )
                SaberSystem.FightEnemy(
                    "Mob Leader",
                    Config.SaberMobLeaderCFrame or CFrame.new(-2848, 7, 5354)
                )
            end
            return true
        end

        local gettingCup = SaberSystem.HandleCupPickup(objects)

        if gettingCup then
            return true
        end

        -- Cup was confirmed in inventory. Next tick will equip/fill it.
    end

    -- Torch phase. Keep the quest item equipped and use the live Burn.Part
    -- instead of relying on a stale hard-coded point inside the Desert house.
    if char:FindFirstChild("Torch") then
        SaberSystem.MarkProgress("TorchCollected")
        SaberSystem.CurrentStep = "BURN_DOOR"

        local stillBurning = SaberSystem.BurnDesertCurtain(objects)

        if not stillBurning then
            SaberSystem.CurrentStep = "GET_CUP"
        end

        return true
    end

    if backpack:FindFirstChild("Torch") then
        SaberSystem.MarkProgress("TorchCollected")
        SaberSystem.CurrentStep = "EQUIP_TORCH"
        SaberSystem.SetCache("Equipping Torch", "Preventing Melee from replacing it")

        SaberSystem.EquipTool("Torch")
        return true
    end

    -- Jungle plates.
    local plates = objects.Plates
    local door = plates and (
        plates:FindFirstChild("Door")
        or plates:FindFirstChild("Door", true)
    ) or nil

    if plates then
        local activePlates = SaberSystem.GetPlateProgress(plates)

        if (door and door.CanCollide) or activePlates < 5 then
            SaberSystem.CurrentStep = "PLATES"
            SaberSystem.ActivatePlate(plates)
            return true
        end
    end

    -- 5/5 plates is enough to advance even if Door has not streamed yet.
    activePlates = activePlates or 0

    if plates and activePlates <= 0 then
        activePlates = SaberSystem.GetPlateProgress(plates)
    end

    if (door and door.CanCollide == false) or activePlates >= 5 then
        SaberSystem.MarkProgress("PlatesDone")

        if not SaberSystem.ProgressFlags.TorchCollected then
            local checkingTorch = SaberSystem.HandleTorchPickupCheck(objects)

            if checkingTorch then
                return true
            end

            -- No Torch after verification: user-requested rule marks this
            -- stage complete and falls forward to Cup.
        end

        if SaberSystem.ProgressFlags.BurnDone then
            local gettingCup = SaberSystem.HandleCupPickup(objects)

            if gettingCup then
                return true
            end

            return true
        end

        -- Torch exists in inventory, so burn the Desert curtain normally.
        SaberSystem.CurrentStep = "BURN_DOOR"
        SaberSystem.SetCache(
            "Torch confirmed",
            "Going to Desert curtain before Cup"
        )
        SaberSystem.MoveTo(CFrame.new(1113, 8, 4352), "going to Desert curtain")
        return true
    end

    if not plates then
        SaberSystem.CurrentStep = "LOAD_PLATES"
        SaberSystem.SetCache("Loading Jungle plates", "QuestPlates not streamed")
        SaberSystem.MoveTo(CFrame.new(-1612, 36, 149), "loading Jungle plates")
        return true
    end

    SaberSystem.CurrentStep = "WAITING_STATE"
    SaberSystem.SetCache("Resolving Saber state", "No matching step yet")
    return true
end

function SaberSystem.RefreshProgress()
    return SaberSystem.HandlePriority()
end

function SaberSystem.Farm()
    return SaberSystem.HandlePriority()
end

--=====================================================================================
-- [28] STATS SYSTEM
--=====================================================================================

StatsSystem.LastUpdate = 0

function StatsSystem.Tick()
    if not Config.AutoStats then
        return
    end

    if tick() - StatsSystem.LastUpdate < 5 then
        return
    end

    StatsSystem.LastUpdate = tick()

    local points = tonumber(UI.GetPoints()) or 0
    if points <= 0 or not CommF_ then
        return
    end

    local selectedStats = {}

    if Config.AutoStatsMelee then
        table.insert(selectedStats, "Melee")
    end
    if Config.AutoStatsDefense then
        table.insert(selectedStats, "Defense")
    end
    if Config.AutoStatsSword then
        table.insert(selectedStats, "Sword")
    end
    if Config.AutoStatsGun then
        table.insert(selectedStats, "Gun")
    end
    if Config.AutoStatsBloxFruit then
        table.insert(selectedStats, "Demon Fruit")
    end

    if #selectedStats == 0 then
        return
    end

    local requested = math.max(1, math.floor(tonumber(Config.StatPointsPerTick) or 1))

    -- Distribute in the selected order. Defaults are Melee -> Defense -> Sword,
    -- which preserves the current Kaitun behavior unless the loader changes it.
    for _, stat in ipairs(selectedStats) do
        if points <= 0 then
            break
        end

        local amount = math.min(requested, points)
        local ok = pcall(function()
            CommF_:InvokeServer("AddPoint", stat, amount)
        end)

        if ok then
            points = math.max(0, points - amount)
        end

        task.wait(0.10)
    end
end

--=====================================================================================
-- [29] QUEST ACQUISITION SYSTEM (From Speed Hub X)
--=====================================================================================

-- Initialize EnemySpawns system (from Speed Hub X)
local function InitializeEnemySpawns()
    -- The old implementation cloned large portions of Workspace/ReplicatedStorage
    -- into new folders. That was one of the biggest sources of memory spikes and
    -- frame drops. Keep only references to existing spawn containers and scan
    -- them lazily when a quest needs a spawn.
    EnemySpawns = workspace:FindFirstChild("EnemySpawns")

    local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
    local originSpawns = worldOrigin and worldOrigin:FindFirstChild("EnemySpawns")
    if not EnemySpawns then
        EnemySpawns = originSpawns
    end

    EnemyCDKSpawns = workspace:FindFirstChild("EnemyCDKSpawns")
        or (worldOrigin and worldOrigin:FindFirstChild("EnemyCDKSpawns"))

    return EnemySpawns
end

QuestSystem.SpawnCycleIndex = QuestSystem.SpawnCycleIndex or 1

local function NormalizeFarmEnemyName(name)
    local value = tostring(name or "")
    value = value:gsub("%b[]", "")
    value = value:gsub("%([Ll][Vv]%.?%s*%d+%s*%)", "")
    value = value:gsub("Lv%.", "")
    value = value:gsub("[%[%]%d]", "")
    value = value:gsub("%s+", "")
    return string.lower(value)
end

function QuestSystem.FindSpawnPosition(enemyNames)
    local wanted = {}
    for _, name in ipairs(enemyNames or {}) do
        wanted[NormalizeFarmEnemyName(name)] = true
    end

    local hrp = Utils.HRP()
    local giverCF = QuestSystem.GetQuestGiverCFrame and QuestSystem.GetQuestGiverCFrame() or nil
    local referencePos = (giverCF and giverCF.Position) or (hrp and hrp.Position)

    local matches = {}

    local function addCandidate(instance, priority)
        if not instance then
            return
        end

        local cf = GetInstanceCFrameSafe(instance)
        if not cf then
            return
        end

        local normalized = NormalizeFarmEnemyName(instance.Name)
        if not wanted[normalized] then
            return
        end

        local distance = referencePos and (cf.Position - referencePos).Magnitude or 0
        table.insert(matches, {
            CFrame = cf,
            Priority = priority or 10,
            Distance = distance,
        })
    end

    -- 1) Exact Speed Hub source: active replicated spawn positions.
    local fortBuilder = ReplicatedStorage:FindFirstChild("FortBuilderReplicatedSpawnPositionsFolder")
    if fortBuilder then
        for _, child in ipairs(fortBuilder:GetDescendants()) do
            if child:IsA("BasePart")
                and child:GetAttribute("Active") == true then
                addCandidate(child, 1)
            end
        end
    end

    -- 2) WorldOrigin EnemySpawns / generated EnemySpawns.
    local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
    local originSpawns = worldOrigin and worldOrigin:FindFirstChild("EnemySpawns")
    if originSpawns then
        for _, child in ipairs(originSpawns:GetDescendants()) do
            addCandidate(child, 2)
        end
    end

    local localSpawns = workspace:FindFirstChild("EnemySpawns")
    if localSpawns then
        for _, child in ipairs(localSpawns:GetDescendants()) do
            addCandidate(child, 3)
        end
    end

    -- 3) Replicated enemy templates can still reveal the right area when
    -- the live mobs have not streamed in yet.
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        if child:IsA("Model") or child:IsA("BasePart") then
            addCandidate(child, 4)
        end
    end

    -- 4) Last resort: accept matching FortBuilder positions even when the
    -- current game build omitted/changed the Active attribute.
    if fortBuilder then
        for _, child in ipairs(fortBuilder:GetDescendants()) do
            if child:IsA("BasePart") then
                addCandidate(child, 5)
            end
        end
    end

    if #matches == 0 then
        return nil
    end

    table.sort(matches, function(a, b)
        if a.Priority ~= b.Priority then
            return a.Priority < b.Priority
        end
        return a.Distance < b.Distance
    end)

    return matches[1].CFrame
end


-- Fast spawn navigation modeled after the supplied Speed Hub X Auto Farm Level.
-- It prefers active replicated spawn points and cycles them instead of camping one spot.
function QuestSystem.NavigateToSpawn(enemyNames)
    local now = tick()
    local hrp = Utils.HRP()
    local quest = QuestSystem.Current
    if not hrp or not quest then
        return false
    end

    -- Keep one destination across farm ticks. A spawn is rotated only after
    -- reaching it and allowing time for its enemy to respawn/stream in.
    if QuestSystem.SpawnTravelQuest ~= quest then
        QuestSystem.SpawnTravelQuest = quest
        QuestSystem.SpawnTravelTarget = nil
        QuestSystem.SpawnTravelIndex = 1
        QuestSystem.SpawnTravelFailures = 0
        QuestSystem.SpawnTravelArrivedAt = nil
    end

    local targetCF = QuestSystem.SpawnTravelTarget
    if not targetCF then
        local wanted = {}
        for _, name in ipairs(enemyNames or {}) do
            wanted[NormalizeFarmEnemyName(name)] = true
        end

        local spawns = {}
        local fortBuilder = ReplicatedStorage:FindFirstChild("FortBuilderReplicatedSpawnPositionsFolder")
        if fortBuilder then
            for _, child in ipairs(fortBuilder:GetDescendants()) do
                if child:IsA("BasePart") and child:GetAttribute("Active") == true
                    and wanted[NormalizeFarmEnemyName(child.Name)] then
                    table.insert(spawns, child:GetPivot())
                end
            end
        end

        if #spawns == 0 then
            local fallback = QuestSystem.FindSpawnPosition(enemyNames)
            if fallback then
                table.insert(spawns, fallback)
            end
        end
        if #spawns == 0 then
            return false
        end

        -- Stable order: hierarchy iteration order can change after streaming.
        table.sort(spawns, function(a, b)
            if a.Position.X ~= b.Position.X then
                return a.Position.X < b.Position.X
            elseif a.Position.Z ~= b.Position.Z then
                return a.Position.Z < b.Position.Z
            end
            return a.Position.Y < b.Position.Y
        end)

        local index = tonumber(QuestSystem.SpawnTravelIndex) or 1
        index = ((index - 1) % #spawns) + 1
        QuestSystem.SpawnTravelIndex = index
        QuestSystem.SpawnTravelCount = #spawns
        -- A fixed low offset prevents the old 65 -> 30 stud destination jump.
        targetCF = spawns[index] * CFrame.new(0, 12, 5)
        QuestSystem.SpawnTravelTarget = targetCF
        QuestSystem.SpawnTravelLastDistance = math.huge
        QuestSystem.SpawnTravelProgressAt = now
        QuestSystem.SpawnTravelArrivedAt = nil
    end

    local distance = (targetCF.Position - hrp.Position).Magnitude
    local mobName = tostring(quest.Mob or "mob")
    if distance <= 12 then
        if Teleport.Owner == "FARM" then
            Teleport.Cancel()
        end
        QuestSystem.SpawnTravelArrivedAt = QuestSystem.SpawnTravelArrivedAt or now
        UI.SetStatus("Waiting spawn | " .. mobName)
        if now - QuestSystem.SpawnTravelArrivedAt >= 3.0 then
            QuestSystem.SpawnTravelIndex = (QuestSystem.SpawnTravelIndex % QuestSystem.SpawnTravelCount) + 1
            QuestSystem.SpawnTravelTarget = nil
            QuestSystem.SpawnTravelArrivedAt = nil
            QuestSystem.SpawnTravelFailures = 0
        end
        return true
    end
    QuestSystem.SpawnTravelArrivedAt = nil

    if distance < (QuestSystem.SpawnTravelLastDistance or math.huge) - 2 then
        QuestSystem.SpawnTravelLastDistance = distance
        QuestSystem.SpawnTravelProgressAt = now
        QuestSystem.SpawnTravelFailures = 0
    elseif now - (QuestSystem.SpawnTravelProgressAt or now) >= 6.0 then
        -- This timer survives tween restarts, unlike the movement watchdog's
        -- serial-based timer. Recover only FARM movement, preserving priorities.
        QuestSystem.SpawnTravelProgressAt = now
        QuestSystem.SpawnTravelFailures = (QuestSystem.SpawnTravelFailures or 0) + 1
        if Teleport.Owner == "FARM" then
            Teleport.Cancel()
            Combat.StopAboveHead()
            if QuestSystem.SpawnTravelFailures == 1 then
                Teleport.StartDirectTravel(targetCF, Config.FarmSpeed or Config.TweenSpeed, "FARM")
            end
        end
        if QuestSystem.SpawnTravelFailures >= 2 then
            QuestSystem.SpawnTravelIndex = (QuestSystem.SpawnTravelIndex % QuestSystem.SpawnTravelCount) + 1
            QuestSystem.SpawnTravelTarget = nil
            QuestSystem.SpawnTravelFailures = 0
        end
        UI.SetStatus("Farm Level | retrying spawn movement | " .. mobName)
        return true
    end

    -- Within an island use the actual motor directly, without portal ownership.
    local needsPortal = Teleport.IsFishmanPosition(targetCF.Position) ~= Teleport.IsFishmanPosition(hrp.Position)
        or math.abs(targetCF.Position.Y - hrp.Position.Y) > 500
    local movement = Teleport.To(targetCF, Config.FarmSpeed or Config.TweenSpeed, "FARM", false, not needsPortal)
    if not movement and not Teleport.LastBlockReason and not needsPortal then
        movement = Teleport.StartDirectTravel(targetCF, Config.FarmSpeed or Config.TweenSpeed, "FARM")
    end
    if Teleport.LastBlockReason then
        UI.SetStatus("Farm movement blocked | " .. Teleport.LastBlockReason)
    elseif movement or (targetCF.Position - hrp.Position).Magnitude <= 12 then
        UI.SetStatus("Going to spawn | " .. mobName .. " | " .. tostring(math.floor(distance)) .. " studs")
    else
        UI.SetStatus("Farm Level | waiting movement controller | " .. mobName)
    end
    return true
end

function QuestSystem.IsRuthlessPrisonQuest(quest)
    quest = quest or QuestSystem.Current
    if not quest then
        return false
    end

    return Utils.Normalize(quest.Mob) == "ruthless prisoner"
        or Utils.Normalize(quest.Giver and quest.Giver[1]) == "head jailer"
            and tonumber(quest.Min or 0) == 225
end

function QuestSystem.IsPrisonQuest(quest)
    quest = quest or QuestSystem.Current
    if not quest then
        return false
    end

    local giver = Utils.Normalize(quest.Giver and quest.Giver[1])
    local mob = Utils.Normalize(quest.Mob)

    if giver == "jail keeper" or giver == "head jailer" then
        return true
    end

    return mob == "prisoner"
        or mob == "dangerous prisoner"
        or mob == "ruthless prisoner"
        or mob == "warden"
end

function QuestSystem.FindLiveQuestGiver(names)
    if type(names) ~= "table" then
        return nil
    end

    local wanted = {}
    for _, name in ipairs(names) do
        wanted[Utils.Normalize(name)] = true
    end

    local roots = {
        workspace:FindFirstChild("NPCs"),
        workspace:FindFirstChild("_WorldOrigin"),
        workspace,
    }

    for _, rootFolder in ipairs(roots) do
        if rootFolder then
            for _, obj in ipairs(rootFolder:GetDescendants()) do
                if (obj:IsA("Model") or obj:IsA("BasePart"))
                    and wanted[Utils.Normalize(obj.Name)] then

                    local cf = GetInstanceCFrameSafe(obj)
                    if cf then
                        return obj, cf
                    end
                end
            end
        end
    end

    return nil, nil
end

function QuestSystem.GetSafeGiverApproachCFrame(quest, giverCF)
    if not quest or typeof(giverCF) ~= "CFrame" then
        return giverCF
    end

    local key = tostring(quest.Quest)
        .. ":" .. tostring(quest.Num)
        .. ":" .. tostring(quest.Giver and quest.Giver[1] or "")

    local cached = QuestSystem.GiverApproachCache[key]
    if cached and typeof(cached) == "CFrame" then
        return cached
    end

    local radius = tonumber(Config.QuestGiverSafeRadius) or 4.0
    local height = tonumber(Config.QuestGiverSafeHeight) or 3.5
    local giverPos = giverCF.Position

    local character = Utils.Character()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true

    local ignore = {}
    if character then
        table.insert(ignore, character)
    end

    local liveNPC = nil
    if quest.Giver then
        liveNPC = QuestSystem.FindLiveQuestGiver(quest.Giver)
    end
    if liveNPC then
        table.insert(ignore, liveNPC)
    end

    params.FilterDescendantsInstances = ignore

    local directions = {
        Vector3.new(1, 0, 0),
        Vector3.new(-1, 0, 0),
        Vector3.new(0, 0, 1),
        Vector3.new(0, 0, -1),
    }

    local hrp = Utils.HRP()
    local best = nil
    local bestDistance = math.huge

    for _, dir in ipairs(directions) do
        local candidatePos = giverPos + dir * radius + Vector3.new(0, height, 0)

        -- Reject a side if a wall blocks the short path from the NPC.
        local horizontalStart = giverPos + Vector3.new(0, 2.5, 0)
        local horizontalTravel = candidatePos - horizontalStart
        local blocked = workspace:Raycast(horizontalStart, horizontalTravel, params)

        -- Make sure the avatar has some room above the chosen point.
        local headroom = workspace:Raycast(
            candidatePos,
            Vector3.new(0, 5.5, 0),
            params
        )

        if not blocked and not headroom then
            local distance = hrp
                and (hrp.Position - candidatePos).Magnitude
                or 0

            if distance < bestDistance then
                bestDistance = distance
                best = CFrame.lookAt(
                    candidatePos,
                    Vector3.new(giverPos.X, candidatePos.Y, giverPos.Z)
                )
            end
        end
    end

    if not best then
        -- Stable fallback: never target the NPC's exact floor CFrame.
        local candidatePos = giverPos + Vector3.new(0, height, radius)
        best = CFrame.lookAt(
            candidatePos,
            Vector3.new(giverPos.X, candidatePos.Y, giverPos.Z)
        )
    end

    QuestSystem.GiverApproachCache[key] = best
    return best
end

function QuestSystem.GetQuestEnemyNames(quest)
    quest = quest or QuestSystem.Current
    if not quest then
        return {}
    end

    if QuestSystem.IsRuthlessPrisonQuest(quest) then
        -- Update 30 currently has a naming bug where Lv.220 Ruthless Prisoners
        -- may appear in-game as Dangerous Prisoner.
        return {"Ruthless Prisoner", "Dangerous Prisoner"}
    end

    return {tostring(quest.Mob or "")}
end

function QuestSystem.GetQuestGiverCFrame()
    local quest = QuestSystem.Current
    if not quest then
        return nil
    end

    QuestSystem.GiverCache = QuestSystem.GiverCache or {}

    -- Prison Update 30: resolve the live Head Jailer first. This avoids using a
    -- GuideModule pivot that can sit too close to/inside the rebuilt floor.
    if Config.PrisonSafeQuestMovement
        and quest.Giver
        and Utils.Normalize(quest.Giver[1]) == "head jailer" then

        local _, liveCF = QuestSystem.FindLiveQuestGiver(quest.Giver)
        if liveCF then
            return liveCF
        end
    end
    local key = tostring(quest.Quest) .. ":" .. tostring(quest.Num)
    local now = tick()
    local cached = QuestSystem.GiverCache[key]

    if cached and (now - cached.Time) < 1.5 and cached.CFrame then
        return cached.CFrame
    end

    -- Base behavior: GuideModule's actual quest-giver CFrame is authoritative.
    if quest.GiverCFrame and typeof(quest.GiverCFrame) == "CFrame" then
        QuestSystem.GiverCache[key] = {CFrame = quest.GiverCFrame, Time = now}
        return quest.GiverCFrame
    end

    -- Fallback only: search the live NPC tree.
    local giverNames = quest.Giver
    if giverNames then
        local npcRoots = {
            workspace:FindFirstChild("NPCs"),
            workspace,
        }

        for _, rootFolder in ipairs(npcRoots) do
            if rootFolder then
                local npc = FindInstanceByNames(rootFolder, giverNames)
                local cf = GetInstanceCFrameSafe(npc)
                if cf then
                    QuestSystem.GiverCache[key] = {CFrame = cf, Time = now}
                    return cf
                end
            end
        end
    end

    QuestSystem.GiverCache[key] = {CFrame = nil, Time = now}
    return nil
end

function QuestSystem.FindNearestQuestPrompt(root, targetPosition)
    local nearest = nil
    local nearestDistance = math.huge

    local function considerPrompt(prompt)
        if not prompt or not prompt:IsA("ProximityPrompt") then
            return
        end

        local parent = prompt.Parent
        local basePart = nil

        if parent then
            if parent:IsA("BasePart") then
                basePart = parent
            elseif parent:IsA("Attachment") and parent.Parent and parent.Parent:IsA("BasePart") then
                basePart = parent.Parent
            end
        end

        if not basePart then
            return
        end

        if targetPosition then
            local dist = (basePart.Position - targetPosition).Magnitude
            if dist > 16 then
                return
            end

            if dist < nearestDistance then
                nearest = prompt
                nearestDistance = dist
            end
        elseif not nearest then
            nearest = prompt
            nearestDistance = 0
        end
    end

    if root then
        for _, obj in ipairs(root:GetDescendants()) do
            considerPrompt(obj)
        end
    end

    if nearest then
        return nearest
    end

    if targetPosition then
        local scanned = 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            scanned = scanned + 1
            if scanned > 1200 then
                break
            end
            considerPrompt(obj)
        end
    end

    return nearest
end

function QuestSystem.TryHeadJailerInteract(quest, giverCF)
    if not QuestSystem.IsPrisonQuest(quest) then
        return false
    end

    local now = tick()
    if now - (QuestSystem.LastPrisonInteractAt or 0) < (tonumber(Config.PrisonPromptRetryInterval) or 0.65) then
        return false
    end
    QuestSystem.LastPrisonInteractAt = now

    local giverModel = nil
    if quest and quest.Giver then
        giverModel = select(1, QuestSystem.FindLiveQuestGiver(quest.Giver))
    end

    local giverPos = giverCF and giverCF.Position or (giverModel and giverModel:GetPivot().Position) or nil
    local prompt = QuestSystem.FindNearestQuestPrompt(giverModel, giverPos)
    local interacted = false

    if prompt then
        if type(fireproximityprompt) == "function" then
            interacted = pcall(function()
                fireproximityprompt(prompt)
            end)
            if not interacted then
                interacted = pcall(function()
                    fireproximityprompt(prompt, prompt.HoldDuration or 0)
                end)
            end
        end

        if not interacted then
            interacted = pcall(function()
                prompt:InputHoldBegin()
                task.wait(math.max(0.10, (tonumber(prompt.HoldDuration) or 0) + 0.05))
                prompt:InputHoldEnd()
            end)
        end
    end

    Utils.SendKey(Enum.KeyCode.E)

    if interacted then
        UI.SetStatus("Prison | interacting with Head Jailer")
    else
        UI.SetStatus("Prison | sending interact key")
    end

    return true
end

function QuestSystem.Acquire()
    local quest = QuestSystem.Current

    if not Config.AutoQuest or not quest then
        UI.SetStatus("Quest | no quest for Lv " .. tostring(Utils.Level()))
        return false
    end

    local remote = WaitForCommF(8)
    if remote then
        CommF_ = remote
    end

    if not CommF_ then
        UI.SetStatus("Quest | CommF_ not ready")
        return false
    end

    if QuestSystem.HasActiveQuest() then
        UI.SetStatus("Quest Active | " .. tostring(quest.Mob))
        return QuestSystem.GoToFarmAfterAcquire()
    end

    if tick() - (QuestSystem.LastQuestAction or 0) < 0.8 then
        return false
    end

    local giverCF = QuestSystem.GetQuestGiverCFrame()
    if not giverCF then
        UI.SetStatus("Quest | giver not found: " .. tostring(quest.Giver and quest.Giver[1] or "unknown"))
        return false
    end

    local hrp = Utils.HRP()
    if not hrp then
        return false
    end

    local interactDistance = Config.FarmLevelBaseMode and (tonumber(Config.FarmQuestDistance) or 5) or (tonumber(Config.QuestInteractDistance) or 12)
    local distance = (giverCF.Position - hrp.Position).Magnitude
    local isHeadJailer = quest.Giver
        and Utils.Normalize(quest.Giver[1]) == "head jailer"

    if isHeadJailer then
        interactDistance = math.max(
            interactDistance,
            tonumber(Config.QuestGiverInteractDistance) or 8.0
        )
    end

    if distance > interactDistance then
        UI.SetStatus("Going To NPC | " .. QuestSystem.GetGiverDisplayName(quest))
        QuestSystem.LastMove = tick()

        local approachCF = isHeadJailer
            and QuestSystem.GetSafeGiverApproachCFrame(quest, giverCF)
            or CFrame.new(giverCF.Position + Vector3.new(0, 3, 0), giverCF.Position)

        local tween = Teleport.To(
            approachCF,
            Config.TweenSpeed,
            "QUEST"
        )

        if not tween and distance > (interactDistance + 5) then
            UI.SetStatus("Quest travel | retrying route")
        end
        return false
    end

    UI.SetStatus("Accepting Quest | " .. tostring(quest.Mob))

    if isHeadJailer then
        QuestSystem.TryHeadJailerInteract(quest, giverCF)
    end

    local ok, result = pcall(function()
        return CommF_:InvokeServer("StartQuest", quest.Quest, quest.Num)
    end)

    QuestSystem.LastQuestAction = tick()

    if not ok or result == false then
        Logger.warn("StartQuest failed:", result)
        QuestSystem.Active = false
        QuestSystem.ActiveQuestCache = false
        if isHeadJailer then
            QuestSystem.TryHeadJailerInteract(quest, giverCF)
            UI.SetStatus("Prison | StartQuest retry")
        else
            UI.SetStatus("Quest | StartQuest failed")
        end
        return false
    end

    QuestSystem.Active = false
    QuestSystem.ActiveQuestCache = false
    QuestSystem.ActiveQuestCheckAt = 0
    QuestSystem.LocalKills = 0
    QuestSystem.FallbackMode = false

    -- Prison is intentionally strict: do not leave the quest NPC merely because
    -- InvokeServer did not throw. Wait until the real quest tracker appears.
    -- This prevents NPC <-> farm ping-pong when StartQuest is rejected/late.
    if QuestSystem.IsPrisonQuest(quest) then
        QuestSystem.LastAcceptedQuestKey = nil
        QuestSystem.AcceptedGraceUntil = 0
        Teleport.Cancel()

        QuestSystem.ActiveQuestCheckAt = 0
        if QuestSystem.HasActiveQuest() then
            QuestSystem.PrisonWaitingSince = 0
            UI.SetStatus("Prison quest confirmed | going to " .. tostring(quest.Mob))
            QuestSystem.GoToFarmAfterAcquire()
            return true
        end

        QuestSystem.PrisonWaitingSince = QuestSystem.PrisonWaitingSince == 0 and tick() or QuestSystem.PrisonWaitingSince
        QuestSystem.TryHeadJailerInteract(quest, giverCF)
        if tick() - (QuestSystem.PrisonWaitingSince or 0) >= (tonumber(Config.PrisonQuestConfirmTimeout) or 2.0) then
            QuestSystem.LastQuestAction = 0
        end

        UI.SetStatus("Prison | waiting quest confirmation")
        return false
    end

    -- Other islands keep the short replication grace behavior.
    QuestSystem.LastAcceptedQuestKey = tostring(quest.Quest) .. ":" .. tostring(quest.Num)
    QuestSystem.AcceptedGraceUntil = tick() + 12.0

    -- Release the previous QUEST movement owner before FARM takes over.
    Teleport.Cancel()

    UI.SetStatus("Quest started | going to " .. tostring(quest.Mob))
    QuestSystem.GoToFarmAfterAcquire()
    return true
end

function QuestSystem.GoToFarmAfterAcquire()
    local quest = QuestSystem.Current
    if not quest then
        return false
    end

    local hrp = Utils.HRP()
    if not hrp then
        return false
    end

    -- Same Farm Level order as the supplied base:
    -- existing enemy -> engage it; otherwise -> active spawn position.
    local target = Combat.FindQuestMob()
    if target then
        Combat.EngageTarget(target)
        return true
    end

    -- Update 30 naming quirk: Ruthless Prisoners may replicate as
    -- "Dangerous Prisoner". Use the dedicated Ruthless area first so generic
    -- spawn cycling cannot bounce between the Lv.210 and Lv.220 groups.
    if QuestSystem.IsRuthlessPrisonQuest(quest) then
        local target = Combat.FindQuestMob and Combat.FindQuestMob() or nil
        if target then
            return true
        end

        local rushCF = Config.RuthlessPrisonFarmCFrame
        if typeof(rushCF) == "CFrame" then
            local distance = (rushCF.Position - hrp.Position).Magnitude
            if distance > 35 then
                UI.SetStatus("Going to Ruthless Prisoner area")
                Teleport.To(
                    rushCF,
                    Config.FarmSpeed or Config.TweenSpeed,
                    "FARM",
                    false
                )
            else
                UI.SetStatus("Waiting Ruthless Prisoner spawn")
            end
            return true
        end
    end

    -- Speed Hub X behavior: when the mob is absent, rotate through its
    -- active replicated spawn points instead of waiting at the quest giver.
    if QuestSystem.NavigateToSpawn(QuestSystem.GetQuestEnemyNames(quest)) then
        return true
    end

    local giverCF = QuestSystem.GetQuestGiverCFrame()

    -- Final scouting fallback only when no replicated spawn information exists.
    if giverCF then
        if QuestSystem.ScoutQuest ~= quest then
            QuestSystem.ScoutQuest = quest
            QuestSystem.ScoutTarget = nil
            QuestSystem.ScoutIndex = 0
        end
        local scoutOffsets = {
            Vector3.new(0, 35, -120),
            Vector3.new(90, 35, -90),
            Vector3.new(-90, 35, -90),
            Vector3.new(130, 45, 20),
            Vector3.new(-130, 45, 20),
            Vector3.new(0, 55, 150),
        }

        if not QuestSystem.ScoutTarget
            or (QuestSystem.ScoutTarget.Position - hrp.Position).Magnitude <= 15 then
            QuestSystem.ScoutIndex = ((QuestSystem.ScoutIndex or 0) % #scoutOffsets) + 1
            QuestSystem.ScoutTarget = CFrame.new(giverCF.Position + scoutOffsets[QuestSystem.ScoutIndex])
        end
        local scoutPos = QuestSystem.ScoutTarget.Position

        UI.SetStatus("Scouting " .. tostring(quest.Mob) .. " area")
        Teleport.To(
            CFrame.new(scoutPos, giverCF.Position),
            Config.TweenSpeed,
            "FARM"
        )
        return true
    end

    UI.SetStatus("Searching spawn | " .. tostring(quest.Mob))
    return false
end

--=====================================================================================
-- [30] FPS BOOST SYSTEM
--=====================================================================================

FPSBoostSystem.Enabled = false
FPSBoostSystem.Active = false
FPSBoostSystem.Originals = setmetatable({}, {__mode = "k"})
FPSBoostSystem.Connections = {}
FPSBoostSystem.Generation = 0

function FPSBoostSystem.Set(instance, property, value)
    if not instance then
        return
    end

    local ok, old = pcall(function()
        return instance[property]
    end)

    if not ok or old == value then
        return
    end

    local data = FPSBoostSystem.Originals[instance]
    if not data then
        data = {}
        FPSBoostSystem.Originals[instance] = data
    end

    if data[property] == nil then
        data[property] = old
    end

    pcall(function()
        instance[property] = value
    end)
end

function FPSBoostSystem.IsProtected(instance)
    if not instance then
        return true
    end

    local char = LocalPlayer.Character
    if char and instance:IsDescendantOf(char) then
        return true
    end

    -- Keep live enemies visible so the level farm can still be watched/debugged.
    if Config.FPSBoostKeepEnemies then
        local enemies = workspace:FindFirstChild("Enemies")
        if enemies and instance:IsDescendantOf(enemies) then
            return true
        end
    end

    -- Keep quest givers / NPCs visible.
    if Config.FPSBoostKeepNPCs then
        local npcs = workspace:FindFirstChild("NPCs")
        if npcs and instance:IsDescendantOf(npcs) then
            return true
        end
    end

    if not Config.FPSBoostHideOtherPlayers then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer
                and player.Character
                and instance:IsDescendantOf(player.Character) then
                return true
            end
        end
    end

    return false
end

function FPSBoostSystem.Optimize(instance)
    if not FPSBoostSystem.Active or not instance or FPSBoostSystem.IsProtected(instance) then
        return
    end

    if instance:IsA("BasePart") then
        FPSBoostSystem.Set(instance, "Material", Enum.Material.SmoothPlastic)
        FPSBoostSystem.Set(instance, "Reflectance", 0)
        FPSBoostSystem.Set(instance, "CastShadow", false)

        if Config.FPSBoostHideMap then
            FPSBoostSystem.Set(instance, "LocalTransparencyModifier", 1)
        end

    elseif instance:IsA("Decal") or instance:IsA("Texture") then
        FPSBoostSystem.Set(instance, "Transparency", 1)

    elseif instance:IsA("ParticleEmitter")
        or instance:IsA("Trail")
        or instance:IsA("Beam")
        or instance:IsA("Fire")
        or instance:IsA("Smoke")
        or instance:IsA("Sparkles") then

        FPSBoostSystem.Set(instance, "Enabled", false)

    elseif instance:IsA("PointLight")
        or instance:IsA("SpotLight")
        or instance:IsA("SurfaceLight") then

        FPSBoostSystem.Set(instance, "Enabled", false)

    elseif instance:IsA("PostEffect") then
        FPSBoostSystem.Set(instance, "Enabled", false)
    end
end

function FPSBoostSystem.DisconnectAll()
    for _, connection in ipairs(FPSBoostSystem.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(FPSBoostSystem.Connections)
end

function FPSBoostSystem.Enable()
    if not Config.FPSBoost or FPSBoostSystem.Enabled then
        return
    end

    -- If an older Kratos FPS controller is still active from a previous
    -- execution, restore/disconnect it before installing this one.
    local env = (getgenv and getgenv()) or _G
    local oldController = env.KratosFPSBoost
    if oldController
        and oldController ~= FPSBoostSystem
        and type(oldController.disable) == "function" then

        pcall(oldController.disable)
    end

    FPSBoostSystem.Generation = FPSBoostSystem.Generation + 1
    local generation = FPSBoostSystem.Generation

    FPSBoostSystem.Enabled = true
    FPSBoostSystem.Active = true

    local terrain = workspace:FindFirstChildOfClass("Terrain")

    FPSBoostSystem.Set(Lighting, "GlobalShadows", false)
    FPSBoostSystem.Set(Lighting, "FogEnd", 100000)

    if terrain then
        FPSBoostSystem.Set(terrain, "WaterWaveSize", 0)
        FPSBoostSystem.Set(terrain, "WaterWaveSpeed", 0)
        FPSBoostSystem.Set(terrain, "WaterReflectance", 0)
        FPSBoostSystem.Set(terrain, "WaterTransparency", 1)
    end

    -- Initial scan is batched so enabling FPS Boost does not freeze the game.
    task.spawn(function()
        local descendants = workspace:GetDescendants()
        local batch = math.max(50, tonumber(Config.FPSBoostBatchSize) or 400)

        for i, instance in ipairs(descendants) do
            if not FPSBoostSystem.Active
                or generation ~= FPSBoostSystem.Generation then
                return
            end

            FPSBoostSystem.Optimize(instance)

            if i % batch == 0 then
                task.wait()
            end
        end

        for i, instance in ipairs(Lighting:GetDescendants()) do
            if not FPSBoostSystem.Active
                or generation ~= FPSBoostSystem.Generation then
                return
            end

            FPSBoostSystem.Optimize(instance)

            if i % batch == 0 then
                task.wait()
            end
        end
    end)

    table.insert(FPSBoostSystem.Connections, workspace.DescendantAdded:Connect(function(instance)
        task.defer(function()
            if FPSBoostSystem.Active and generation == FPSBoostSystem.Generation then
                FPSBoostSystem.Optimize(instance)
            end
        end)
    end))

    table.insert(FPSBoostSystem.Connections, Lighting.DescendantAdded:Connect(function(instance)
        task.defer(function()
            if FPSBoostSystem.Active and generation == FPSBoostSystem.Generation then
                FPSBoostSystem.Optimize(instance)
            end
        end)
    end))

    env.KratosFPSBoost = FPSBoostSystem
    FPSBoostSystem.disable = FPSBoostSystem.Disable

    Logger.info("FPS Boost Extremo enabled")
end

function FPSBoostSystem.Disable()
    if not FPSBoostSystem.Enabled and not FPSBoostSystem.Active then
        return
    end

    FPSBoostSystem.Generation = FPSBoostSystem.Generation + 1
    FPSBoostSystem.Active = false
    FPSBoostSystem.Enabled = false

    FPSBoostSystem.DisconnectAll()

    for instance, properties in pairs(FPSBoostSystem.Originals) do
        if instance and instance.Parent then
            for property, value in pairs(properties) do
                pcall(function()
                    instance[property] = value
                end)
            end
        end
    end

    FPSBoostSystem.Originals = setmetatable({}, {__mode = "k"})

    local env = (getgenv and getgenv()) or _G
    if env.KratosFPSBoost == FPSBoostSystem then
        env.KratosFPSBoost = nil
    end

    Logger.info("FPS Boost Extremo disabled")
end

function FPSBoostSystem.Sync()
    if Config.FPSBoost then
        if not FPSBoostSystem.Enabled then
            FPSBoostSystem.Enable()
        end
    elseif FPSBoostSystem.Enabled or FPSBoostSystem.Active then
        FPSBoostSystem.Disable()
    end
end

--=====================================================================================
-- [31] COMBAT EXPANSION
--=====================================================================================

function Combat.FindQuestMob()
    local quest = QuestSystem.Current
    if not quest then
        Combat.CurrentTarget = nil
        return nil
    end

    local wanted = NormalizeFarmEnemyName(quest.Mob)
    local ruthlessQuest = QuestSystem.IsRuthlessPrisonQuest(quest)

    local function targetRank(enemy)
        local normalized = NormalizeFarmEnemyName(enemy and enemy.Name)

        if normalized == wanted then
            return 0
        end

        if ruthlessQuest and normalized == NormalizeFarmEnemyName("Dangerous Prisoner") then
            local rawName = string.lower(tostring(enemy.Name or ""))

            -- Current Update 30 builds can expose Ruthless Prisoners under the
            -- Dangerous Prisoner display name. Lv.220 is the strong signal.
            if string.find(rawName, "220", 1, true) then
                return 0
            end

            -- Unknown/no-level model name: allow only as a fallback.
            return 1
        end

        return nil
    end

    -- ONE MOB AT A TIME: never switch targets while the current one is alive.
    local locked = Combat.CurrentTarget
    if Config.FarmOneMobAtATime and locked and locked.Parent then
        local hum = locked:FindFirstChildOfClass("Humanoid")
        local root = locked:FindFirstChild("HumanoidRootPart") or locked.PrimaryPart
        if hum and root and hum.Health > 0
            and targetRank(locked) ~= nil then
            return locked
        end

        Combat.CurrentTarget = nil
        Combat.ResetAnchor()
    end

    local enemies = workspace:FindFirstChild("Enemies")
    local hrp = Utils.HRP()
    if not enemies or not hrp then
        return nil
    end

    local nearest = nil
    local nearestRank = math.huge
    local nearestSq = math.huge
    local maxRange = tonumber(Config.SearchRadius) or 8000
    local maxRangeSq = maxRange * maxRange

    for _, enemy in ipairs(enemies:GetChildren()) do
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart

        local rank = hum and root and hum.Health > 0
            and targetRank(enemy)
            or nil

        if rank ~= nil then
            local delta = root.Position - hrp.Position
            local distSq = delta:Dot(delta)

            if distSq <= maxRangeSq
                and (
                    rank < nearestRank
                    or (rank == nearestRank and distSq < nearestSq)
                ) then

                nearestRank = rank
                nearestSq = distSq
                nearest = enemy
            end
        end
    end

    if nearest then
        Combat.CurrentTarget = nearest
    end

    Combat.TargetCache = nearest
    return nearest
end

function Combat.FindFallbackMob()
    local quest = QuestSystem.Current
    if not quest or not quest.Fallbacks then
        return nil
    end

    local now = tick()
    if Combat.LastFallbackQuest == quest and (now - (Combat.LastFallbackScan or 0)) < (tonumber(Config.CombatScanInterval) or 0.30) then
        local cached = Combat.FallbackCache
        if cached and cached.Parent then
            local hum = cached:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                return cached
            end
        end
        return nil
    end

    local hrp = Utils.HRP()
    if not hrp then
        return nil
    end

    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then
        return nil
    end

    Combat.LastFallbackScan = now
    Combat.LastFallbackQuest = quest
    Combat.FallbackCache = nil

    local searchRadius = tonumber(Config.SearchRadius) or 8000
    for _, fallbackName in ipairs(quest.Fallbacks) do
        local fallbackNorm = Utils.Normalize(fallbackName)
        for _, enemy in ipairs(enemies:GetChildren()) do
            local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
            local enemyHum = enemy:FindFirstChildOfClass("Humanoid")
            if enemyHRP and enemyHum and enemyHum.Health > 0 then
                local enemyName = Utils.Normalize(enemy.Name)
                if enemyName:find(fallbackNorm, 1, true) then
                    local delta = enemyHRP.Position - hrp.Position
                    if delta:Dot(delta) <= searchRadius * searchRadius then
                        Combat.FallbackCache = enemy
                        return enemy
                    end
                end
            end
        end
    end

    return nil
end

--=====================================================================================
-- [32] BOSS PATROL SYSTEM (From Speed Hub X)
--=====================================================================================

BossSystem = {
    PatrolPoints = {},
    CurrentPatrolIndex = 1,
    IsPatrolling = false,
    BossCooldown = 0,
    RaidOverrideActive = false,
    RaidOverrideName = nil,
    CachedRaidBoss = nil,
    RaidBossWatchersReady = false,
    RaidBossConnections = {},
}

-- Boss patrol routes (from Speed Hub X)
local BossPatrolRoutes = {
    ["Chef"] = {
        CFrame.new(-1141, 4, 3831),
        CFrame.new(-1200, 4, 3900),
        CFrame.new(-1100, 4, 3800),
    },
    ["Vice Admiral"] = {
        CFrame.new(-4784, 14, 4241),
        CFrame.new(-4700, 14, 4300),
        CFrame.new(-4850, 14, 4200),
    },
    ["Warden"] = {
        CFrame.new(5282, 2, 470),
        CFrame.new(5300, 2, 500),
        CFrame.new(5250, 2, 450),
    },
    ["Magma General"] = {
        CFrame.new(-5316, 12, 8515),
        CFrame.new(-5400, 25, 8490),
        CFrame.new(-5250, 25, 8550),
    },
    ["Fishman Lord"] = {
        CFrame.new(61122, 18, 1568),
        CFrame.new(61000, 18, 1600),
        CFrame.new(61250, 18, 1530),
    },
    ["Sky Warlord"] = {
        CFrame.new(-5100, 800, -800),
        CFrame.new(-4900, 820, -750),
        CFrame.new(-5200, 810, -850),
    },
    ["Yeti"] = {
        CFrame.new(1387, 95, -1297),
        CFrame.new(1100, 95, -1300),
        CFrame.new(1200, 95, -1450),
        CFrame.new(1450, 95, -1350),
        CFrame.new(1300, 95, -1200),
    },
    ["Lightning God"] = {
        CFrame.new(-5400, 410, -700),
        CFrame.new(-4800, 420, -600),
        CFrame.new(-5200, 430, -800),
        CFrame.new(-5000, 440, -650),
    },
    ["Cyborg"] = {
        CFrame.new(5259, 38, 4050),
        CFrame.new(5500, 40, 4200),
        CFrame.new(5000, 40, 3900),
        CFrame.new(5300, 40, 4100),
    },
}

local KnownRaidBossNames = {
    ["greybeard"] = true,
    ["darkbeard"] = true,
    ["order"] = true,
    ["cursed captain"] = true,
}

function BossSystem.IsRaidBossModel(mob)
    if not mob or not mob.Parent then
        return false
    end

    local hum = mob:FindFirstChildOfClass("Humanoid")
    local root = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
    if not hum or hum.Health <= 0 or not root then
        return false
    end

    local rawName = string.lower(tostring(mob.Name or ""))

    -- Primary path: current raid bosses normally expose [Raid Boss] in their model name.
    if string.find(rawName, "[raid boss]", 1, true) then
        return true
    end

    -- Fallback for builds/executors that expose a cleaned model name.
    local normalized = Utils.Normalize(mob.Name)
    if KnownRaidBossNames[normalized] then
        return true
    end

    local okAttr, attr = pcall(function()
        return mob:GetAttribute("IsRaidBoss")
    end)
    return okAttr and attr == true
end

function BossSystem.PreArmRaidBoss(mob)
    if not BossSystem.IsRaidBossModel(mob) then
        return
    end

    BossSystem.CachedRaidBoss = mob
    Combat.AttackCooldown = 0

    pcall(Attack.RefreshRemotes)
    pcall(Attack.PrimeHitToken)
    pcall(HakiSystem.ActivateBuso)
    pcall(function()
        Utils.EnsureMeleeEquipped(true)
    end)
end

function BossSystem.WatchRaidBossFolder(folder)
    if not folder then
        return
    end

    for _, mob in ipairs(folder:GetChildren()) do
        BossSystem.PreArmRaidBoss(mob)
    end

    table.insert(BossSystem.RaidBossConnections, folder.ChildAdded:Connect(function(mob)
        task.defer(function()
            BossSystem.PreArmRaidBoss(mob)
        end)
    end))

    table.insert(BossSystem.RaidBossConnections, folder.ChildRemoved:Connect(function(mob)
        if BossSystem.CachedRaidBoss == mob then
            BossSystem.CachedRaidBoss = nil
        end
    end))
end

function BossSystem.SetupRaidBossWatchers()
    if BossSystem.RaidBossWatchersReady then
        return
    end
    BossSystem.RaidBossWatchersReady = true

    for _, folderName in ipairs({"Enemies", "Bosses"}) do
        BossSystem.WatchRaidBossFolder(workspace:FindFirstChild(folderName))
    end

    table.insert(BossSystem.RaidBossConnections, workspace.ChildAdded:Connect(function(child)
        if child.Name == "Enemies" or child.Name == "Bosses" then
            BossSystem.WatchRaidBossFolder(child)
        end
    end))
end

BossSystem.SetupRaidBossWatchers()

function BossSystem.IsBossSpawned(bossName)
    local wanted = Utils.Normalize(bossName)

    for _, folderName in ipairs({"Enemies", "Bosses"}) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, mob in ipairs(folder:GetChildren()) do
                if Utils.Normalize(mob.Name) == wanted then
                    local hum = mob:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        return true, mob
                    end
                end
            end
        end
    end

    return false, nil
end

function BossSystem.FindRaidBoss()
    if not Config.AutoRaidBosses then
        return nil
    end

    local sea = MeleeSystem.GetSea()
    if sea ~= 1 and sea ~= 2 then
        return nil
    end

    local cached = BossSystem.CachedRaidBoss
    if cached and BossSystem.IsRaidBossModel(cached) then
        return cached
    end

    local hrp = Utils.HRP()
    local nearest = nil
    local nearestSq = math.huge

    for _, folderName in ipairs({"Enemies", "Bosses"}) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, mob in ipairs(folder:GetChildren()) do
                if BossSystem.IsRaidBossModel(mob) then
                    local root = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart

                    if root then
                        local distSq = 0
                        if hrp then
                            local delta = root.Position - hrp.Position
                            distSq = delta:Dot(delta)
                        end

                        if not nearest or distSq < nearestSq then
                            nearest = mob
                            nearestSq = distSq
                        end
                    end
                end
            end
        end
    end

    BossSystem.CachedRaidBoss = nearest
    return nearest
end

function BossSystem.HandleRaidBossPriority()
    local boss = BossSystem.FindRaidBoss()

    if not boss then
        if BossSystem.RaidOverrideActive then
            BossSystem.RaidOverrideActive = false
            BossSystem.RaidOverrideName = nil
            Combat.CurrentTarget = nil
            Combat.ResetAnchor()
            QuestSystem.ActiveQuestCheckAt = 0
            QuestSystem.LastUpdate = 0
            UI.SetStatus("Raid Boss defeated/gone | resuming Farm Level", true)
        end
        return false
    end

    local hum = boss:FindFirstChildOfClass("Humanoid")
    local root = boss:FindFirstChild("HumanoidRootPart") or boss.PrimaryPart
    if not hum or hum.Health <= 0 or not root then
        return false
    end

    local bossName = Utils.Normalize(boss.Name)
    bossName = bossName:gsub("(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. rest
    end)

    local entering = not BossSystem.RaidOverrideActive
        or BossSystem.RaidOverrideName ~= bossName

    if entering then
        BossSystem.RaidOverrideActive = true
        BossSystem.RaidOverrideName = bossName

        -- Raid Bosses override the current level quest and do not wait on this remote.
        task.spawn(function()
            pcall(function()
                if CommF_ then
                    CommF_:InvokeServer("AbandonQuest")
                end
            end)
        end)

        Combat.AttackCooldown = 0
        pcall(Attack.RefreshRemotes)
        pcall(Attack.PrimeHitToken)
        pcall(HakiSystem.ActivateBuso)
        pcall(function()
            Utils.EnsureMeleeEquipped(true)
        end)

        QuestSystem.Active = false
        QuestSystem.ActiveQuestCache = false
        QuestSystem.ActiveQuestCheckAt = 0
        QuestSystem.AcceptedGraceUntil = 0
        QuestSystem.LastAcceptedQuestKey = nil

        Combat.CurrentTarget = nil
        Combat.ResetAnchor()
        Teleport.Cancel()
    end

    Combat.CurrentTarget = boss
    FarmEngine.Activity = "Raid Boss | " .. bossName
    UI.SetStatus("Raid Boss | " .. bossName .. " | attacking", true)
    Combat.EngageTarget(boss)
    return true
end

function BossSystem.PatrolForBoss(bossName)
    local route = BossPatrolRoutes[bossName]
    if not route then
        return false
    end

    -- Check if boss is already spawned
    local spawned, bossMob = BossSystem.IsBossSpawned(bossName)
    if spawned and bossMob then
        local root = bossMob:FindFirstChild("HumanoidRootPart")
        if root then
            UI.SetStatus(bossName .. " spawned - going to fight")
            Teleport.To(CFrame.new(root.Position + Vector3.new(0, Config.PatrolHeight, 0), root.Position), Config.TweenSpeed, "BOSS")
            return true
        end
    end

    -- Patrol the area
    BossSystem.CurrentPatrolIndex = (BossSystem.CurrentPatrolIndex % #route) + 1
    local patrolPoint = route[BossSystem.CurrentPatrolIndex]
    
    UI.SetStatus("Patrolling for " .. bossName .. " " .. BossSystem.CurrentPatrolIndex .. "/" .. #route)
    
    local hrp = Utils.HRP()
    if hrp then
        -- Force instant teleport for high-altitude areas
        Teleport.To(
            CFrame.new(patrolPoint.Position + Vector3.new(0, Config.PatrolHeight, 0)),
            Config.TweenSpeed,
            "BOSS"
        )
    end
    
    return true
end


--==============================================================================
-- GLOBAL COMBAT HEALTH SAFETY
-- One synchronized retreat state for normal NPCs, bosses and special fights.
--==============================================================================
Combat.HealthRetreatActive = false
Combat.HealthRetreatBodyPosition = nil
Combat.HealthRetreatTarget = nil
Combat.HealthRetreatPosition = nil
Combat.HealthRetreatStartedAt = 0

function Combat.GetHealthRatio()
    local hum = Utils.Humanoid()

    if not hum or hum.MaxHealth <= 0 then
        return 1
    end

    return math.clamp(hum.Health / hum.MaxHealth, 0, 1)
end

function Combat.ReleaseHealthRetreat()
    local mover = Combat.HealthRetreatBodyPosition
    Combat.HealthRetreatBodyPosition = nil

    if mover and mover.Parent then
        pcall(function()
            mover:Destroy()
        end)
    end

    Combat.HealthRetreatActive = false
    Combat.HealthRetreatTarget = nil
    Combat.HealthRetreatPosition = nil
    Combat.HealthRetreatStartedAt = 0

    if type(Combat.StopAboveHead) == "function" then
        Combat.StopAboveHead()
    end
end

function Combat.GetRetreatBasePosition()
    local target = Combat.CurrentTarget

    if target and target.Parent then
        local hum = target:FindFirstChildOfClass("Humanoid")
        local root = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart

        if hum and hum.Health > 0 and root then
            return root.Position
        end
    end

    local hrp = Utils.HRP()
    if hrp then
        return hrp.Position
    end

    return Vector3.new(0, 100, 0)
end

function Combat.BeginHealthRetreat()
    if not AutomationMovementAllowed() then
        Combat.ReleaseHealthRetreat()
        return false
    end

    local hrp = Utils.HRP()
    local hum = Utils.Humanoid()

    if not hrp or not hum then
        return false
    end

    if type(Combat.StopAboveHead) == "function" then
        Combat.StopAboveHead()
    end

    Teleport.Cancel()
    Teleport.ExclusiveOwner = "HP_SAFE"

    local base = Combat.GetRetreatBasePosition()
    local safeHeight = tonumber(Config.CombatSafeHeight) or 65
    local safeY = math.max(hrp.Position.Y, base.Y) + safeHeight
    local safePosition = Vector3.new(base.X, safeY, base.Z)

    local oldMover = Combat.HealthRetreatBodyPosition
    if oldMover and oldMover.Parent then
        pcall(function()
            oldMover:Destroy()
        end)
    end

    local mover = Instance.new("BodyPosition")
    mover.Name = "KratosCombatHPSafe"
    mover.P = tonumber(Config.CombatSafeHoldP) or 32000
    mover.D = tonumber(Config.CombatSafeHoldD) or 500
    local maxForce = tonumber(Config.CombatSafeMaxForce) or 1000000000
    mover.MaxForce = Vector3.new(maxForce, maxForce, maxForce)
    mover.Position = safePosition
    mover.Parent = hrp

    Combat.HealthRetreatBodyPosition = mover
    Combat.HealthRetreatActive = true
    Combat.HealthRetreatTarget = Combat.CurrentTarget
    Combat.HealthRetreatPosition = safePosition
    Combat.HealthRetreatStartedAt = tick()

    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)

    return true
end

function Combat.HealthSafetyTick()
    if not Config.CombatHPSafety then
        if Combat.HealthRetreatActive then
            Combat.ReleaseHealthRetreat()
        end
        return false
    end

    local hum = Utils.Humanoid()
    local hrp = Utils.HRP()

    if not hum or not hrp or hum.Health <= 0 then
        Combat.ReleaseHealthRetreat()
        return false
    end

    local ratio = Combat.GetHealthRatio()
    local retreatAt = tonumber(Config.CombatRetreatHealth) or 0.40
    local resumeAt = tonumber(Config.CombatResumeHealth) or 0.85

    if Combat.HealthRetreatActive then
        if ratio >= resumeAt then
            Combat.ReleaseHealthRetreat()
            Teleport.ExclusiveOwner = nil

            if type(Combat.ResetAnchor) == "function" then
                Combat.ResetAnchor()
            end

            FarmEngine.Activity = string.format(
                "HP recovered %d%% | resuming farm",
                math.floor(ratio * 100 + 0.5)
            )
            UI.SetStatus(FarmEngine.Activity, true)
            return false
        end

        local safePosition = Combat.HealthRetreatPosition
        if not safePosition then
            Combat.BeginHealthRetreat()
            safePosition = Combat.HealthRetreatPosition
        end

        if safePosition then
            local mover = Combat.HealthRetreatBodyPosition
            if not mover or not mover.Parent then
                Combat.BeginHealthRetreat()
                mover = Combat.HealthRetreatBodyPosition
            end

            if mover and mover.Parent then
                mover.Position = safePosition
            end

            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
        end

        FarmEngine.Activity = string.format(
            "Recovering HP %d%% / %d%%",
            math.floor(ratio * 100 + 0.5),
            math.floor(resumeAt * 100 + 0.5)
        )
        UI.SetStatus(FarmEngine.Activity, true)
        return true
    end

    if ratio <= retreatAt then
        Combat.BeginHealthRetreat()
        FarmEngine.Activity = string.format(
            "Recovering HP %d%% / %d%%",
            math.floor(ratio * 100 + 0.5),
            math.floor(resumeAt * 100 + 0.5)
        )
        UI.SetStatus(FarmEngine.Activity, true)
        return true
    end

    return false
end

function BossSystem.HandleBossQuest(quest)
    if not quest or not quest.Boss then
        return false
    end

    local bossName = quest.Mob

    if quest.SideBoss then
        bossName = tostring(quest.Mob or "Warden")
    end

    local level = Utils.Level()
    if level < quest.Min or level > quest.Max then
        return false
    end

    local spawned, bossMob = BossSystem.IsBossSpawned(bossName)
    if not spawned or not bossMob then
        return false
    end

    local bossHum = bossMob:FindFirstChildOfClass("Humanoid")
    local bossRoot = bossMob:FindFirstChild("HumanoidRootPart") or bossMob.PrimaryPart

    if not bossHum or bossHum.Health <= 0 or not bossRoot then
        return false
    end

    -- Bosses now use the SAME synchronized combat path as normal NPCs.
    -- The old branch only moved above the boss and returned before FastAttack.
    Combat.CurrentTarget = bossMob
    FarmEngine.Activity = "Farming 1 mob | " .. tostring(bossName) .. " | Boss"
    UI.SetStatus(FarmEngine.Activity, true)
    Combat.EngageTarget(bossMob)
    return true
end


--=====================================================================================
-- [32.7] NEARBY CHEST COLLECTION
--=====================================================================================

ChestSystem.Active = false
ChestSystem.Queue = {}
ChestSystem.ReturnCFrame = nil
ChestSystem.ScanOrigin = nil
ChestSystem.LastScanAt = 0
ChestSystem.LastPickupAt = 0
ChestSystem.Current = nil
ChestSystem.CurrentStartedAt = 0
ChestSystem.CheckedAgain = false
ChestSystem.Attempted = setmetatable({}, {__mode = "k"})

function ChestSystem.GetChestCFrame(chest)
    if not chest or not chest.Parent then
        return nil
    end

    if chest:IsA("BasePart") then
        return chest.CFrame
    end

    if chest:IsA("Model") then
        local ok, pivot = pcall(function()
            return chest:GetPivot()
        end)
        if ok and typeof(pivot) == "CFrame" then
            return pivot
        end
    end

    local part = chest:FindFirstChildWhichIsA("BasePart", true)
    return part and part.CFrame or nil
end

function ChestSystem.GetTouchPart(chest)
    if not chest or not chest.Parent then
        return nil
    end

    if chest:IsA("BasePart") then
        return chest
    end

    if chest:IsA("Model") and chest.PrimaryPart then
        return chest.PrimaryPart
    end

    local named = chest:FindFirstChild("Chest", true)
    if named and named:IsA("BasePart") then
        return named
    end

    return chest:FindFirstChildWhichIsA("BasePart", true)
end

function ChestSystem.IsAvailable(chest)
    if not chest or not chest.Parent then
        return false
    end

    local disabled = false
    pcall(function()
        disabled = chest:GetAttribute("IsDisabled") == true
    end)

    if disabled then
        return false
    end

    local lastAttempt = ChestSystem.Attempted[chest]
    if lastAttempt
        and tick() - lastAttempt < (tonumber(Config.ChestRetryCooldown) or 6.0) then
        return false
    end

    return ChestSystem.GetChestCFrame(chest) ~= nil
end

function ChestSystem.GetNearbyChests(originPosition)
    local hrp = Utils.HRP()
    if not hrp then
        return {}
    end

    originPosition = originPosition or hrp.Position
    local radius = tonumber(Config.ChestCollectRadius) or 350
    local found = {}

    for _, chest in ipairs(CollectionService:GetTagged("_ChestTagged")) do
        if ChestSystem.IsAvailable(chest) then
            local chestCF = ChestSystem.GetChestCFrame(chest)

            if chestCF then
                local distance = (chestCF.Position - originPosition).Magnitude

                if distance <= radius then
                    table.insert(found, {
                        Chest = chest,
                        Distance = distance,
                    })
                end
            end
        end
    end

    table.sort(found, function(a, b)
        return a.Distance < b.Distance
    end)

    local queue = {}
    for _, data in ipairs(found) do
        table.insert(queue, data.Chest)
    end

    return queue
end

function ChestSystem.Reset()
    ChestSystem.Active = false
    ChestSystem.Queue = {}
    ChestSystem.ReturnCFrame = nil
    ChestSystem.ScanOrigin = nil
    ChestSystem.Current = nil
    ChestSystem.CurrentStartedAt = 0
    ChestSystem.CheckedAgain = false

    if Teleport.Owner == "CHEST" then
        Teleport.Cancel()
    end

    -- Chest detours can finish immediately after a boss dies. Force the quest
    -- resolver to run again before any stale boss quest can be re-accepted.
    if Config.BossRefreshAfterChest ~= false then
        QuestSystem.LastUpdate = 0
        QuestSystem.ActiveQuestCheckAt = 0
        QuestSystem.DynamicQuestCacheAt = 0
    end
end

function ChestSystem.Begin(queue)
    local hrp = Utils.HRP()
    if not hrp or type(queue) ~= "table" or #queue == 0 then
        return false
    end

    ChestSystem.Active = true
    ChestSystem.Queue = queue
    ChestSystem.ReturnCFrame = hrp.CFrame
    ChestSystem.ScanOrigin = hrp.Position
    ChestSystem.Current = nil
    ChestSystem.CurrentStartedAt = 0
    ChestSystem.CheckedAgain = false

    Combat.CurrentTarget = nil
    Combat.ResetAnchor()

    if Teleport.IsBusy()
        and Teleport.GetOwnerPriority(Teleport.Owner or "GENERIC")
            <= Teleport.GetOwnerPriority("CHEST") then
        Teleport.Cancel()
    end

    UI.SetStatus("Chest Farm | " .. tostring(#queue) .. " nearby chest(s)")
    return true
end

function ChestSystem.TryTouch(chest)
    local hrp = Utils.HRP()
    local part = ChestSystem.GetTouchPart(chest)

    if not hrp or not part then
        return false
    end

    local touched = false

    if firetouchinterest then
        touched = pcall(function()
            firetouchinterest(part, hrp, 0)
            firetouchinterest(part, hrp, 1)
        end)
    end

    -- Physical fallback for executors without firetouchinterest.
    pcall(function()
        hrp.CFrame = CFrame.new(
            part.Position + Vector3.new(0, 1.25, 0),
            part.Position
        )
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)

    return touched
end

function ChestSystem.StepCurrentChest()
    local chest = ChestSystem.Current

    if not chest or not ChestSystem.IsAvailable(chest) then
        ChestSystem.Current = nil
        ChestSystem.CurrentStartedAt = 0
        return true
    end

    local hrp = Utils.HRP()
    local chestCF = ChestSystem.GetChestCFrame(chest)
    if not hrp or not chestCF then
        ChestSystem.Current = nil
        ChestSystem.CurrentStartedAt = 0
        return true
    end

    local distance = (hrp.Position - chestCF.Position).Magnitude
    local pickupDistance = tonumber(Config.ChestPickupDistance) or 5.5
    local timeout = tonumber(Config.ChestPickupTimeout) or 2.0

    UI.SetStatus(
        "Chest Farm | collecting | "
            .. tostring(math.floor(distance + 0.5))
            .. " studs"
    )

    if distance > pickupDistance then
        Teleport.To(
            chestCF * CFrame.new(0, 1.5, 0),
            Config.FarmSpeed or Config.TweenSpeed,
            "CHEST",
            true
        )

        if tick() - (ChestSystem.CurrentStartedAt or tick()) > timeout then
            ChestSystem.Attempted[chest] = tick()
            ChestSystem.Current = nil
            ChestSystem.CurrentStartedAt = 0
        end

        return true
    end

    if Teleport.Owner == "CHEST" then
        Teleport.Cancel()
    end

    ChestSystem.TryTouch(chest)
    ChestSystem.Attempted[chest] = tick()
    ChestSystem.LastPickupAt = tick()
    ChestSystem.Current = nil
    ChestSystem.CurrentStartedAt = 0
    return true
end

function ChestSystem.Tick()
    if not Config.AutoCollectNearbyChests or not Config.AutoFarm then
        if ChestSystem.Active then
            ChestSystem.Reset()
        end
        return false
    end

    local hrp = Utils.HRP()
    if not hrp then
        return false
    end

    -- Do not start a chest detour while a more important movement owner is active.
    if not ChestSystem.Active and Teleport.IsBusy() then
        local ownerPriority = Teleport.GetOwnerPriority(Teleport.Owner or "GENERIC")
        if ownerPriority > Teleport.GetOwnerPriority("CHEST") then
            return false
        end
    end

    if not ChestSystem.Active then
        local now = tick()
        local interval = tonumber(Config.ChestScanInterval) or 0.75

        if now - (ChestSystem.LastScanAt or 0) < interval then
            return false
        end

        ChestSystem.LastScanAt = now
        local nearby = ChestSystem.GetNearbyChests(hrp.Position)

        if #nearby == 0 then
            return false
        end

        return ChestSystem.Begin(nearby)
    end

    if ChestSystem.Current then
        return ChestSystem.StepCurrentChest()
    end

    while #ChestSystem.Queue > 0 do
        local chest = table.remove(ChestSystem.Queue, 1)

        if ChestSystem.IsAvailable(chest) then
            ChestSystem.Current = chest
            ChestSystem.CurrentStartedAt = tick()
            return ChestSystem.StepCurrentChest()
        end
    end

    -- One quick re-scan catches chests that spawned while the first batch was collected.
    if not ChestSystem.CheckedAgain then
        ChestSystem.CheckedAgain = true

        local origin = ChestSystem.ScanOrigin or hrp.Position
        local more = ChestSystem.GetNearbyChests(origin)

        if #more > 0 then
            ChestSystem.Queue = more
            UI.SetStatus("Chest Farm | +" .. tostring(#more) .. " chest(s)")
            return true
        end
    end

    if Config.ChestReturnToFarm and ChestSystem.ReturnCFrame then
        local distanceBack = (hrp.Position - ChestSystem.ReturnCFrame.Position).Magnitude

        if distanceBack > 10 then
            UI.SetStatus("Chest Farm | returning to farm")
            Teleport.To(
                ChestSystem.ReturnCFrame,
                Config.FarmSpeed or Config.TweenSpeed,
                "CHEST",
                true
            )
            return true
        end
    end

    ChestSystem.Reset()
    UI.SetStatus("Chest Farm complete | resuming level farm")
    return false
end

--=====================================================================================
-- [32.75] GLOBAL AUTO CHECKPOINT
--=====================================================================================

CheckpointSystem.LastKey = nil
CheckpointSystem.LastAt = 0
CheckpointSystem.LastCharacter = nil
CheckpointSystem.Pending = false

function CheckpointSystem.ResetForCharacter(character)
    if CheckpointSystem.LastCharacter ~= character then
        CheckpointSystem.LastCharacter = character
        CheckpointSystem.LastKey = nil
        CheckpointSystem.LastAt = 0
        CheckpointSystem.Pending = false
    end
end

function CheckpointSystem.GetAreaKey(targetRoot)
    local sea = tonumber(MeleeSystem.GetSea()) or 1
    local quest = QuestSystem.Current

    if sea == 1 and targetRoot and targetRoot.Position.X > 50000 then
        return "1:UNDERWATER_CITY"
    end

    if quest and quest.Area then
        return tostring(sea) .. ":" .. tostring(quest.Area)
    end

    if targetRoot then
        -- Fallback for special/boss farms that do not expose Quest.Area.
        -- A coarse grid is enough to distinguish islands without changing key
        -- every time the NPC moves a few studs.
        local p = targetRoot.Position
        local gx = math.floor((p.X / 1800) + 0.5)
        local gz = math.floor((p.Z / 1800) + 0.5)
        return string.format("%d:GRID:%d:%d", sea, gx, gz)
    end

    return tostring(sea) .. ":UNKNOWN"
end

function CheckpointSystem.IsFishmanArea(hrp, targetRoot)
    if tonumber(MeleeSystem.GetSea()) ~= 1 then
        return false
    end

    if hrp and hrp.Position.X > 50000 then
        return true
    end

    return targetRoot and targetRoot.Position.X > 50000 or false
end

function CheckpointSystem.Try(target)
    if Config.AutoCheckpoint == false
        or Config.AutoFarm == false
        or not FarmEngine.Running
        or CheckpointSystem.Pending then
        return false
    end

    local character = Utils.Character()
    local hrp = Utils.HRP()
    local targetRoot = target and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart)

    if not character or not hrp or not targetRoot then
        return false
    end

    CheckpointSystem.ResetForCharacter(character)

    local maxDistance = InternalTuning.Checkpoint.TargetDistance
    if (hrp.Position - targetRoot.Position).Magnitude > maxDistance then
        return false
    end

    local key = CheckpointSystem.GetAreaKey(targetRoot)
    if CheckpointSystem.LastKey == key then
        return true
    end

    CheckpointSystem.LastKey = key
    CheckpointSystem.LastAt = tick()
    CheckpointSystem.Pending = true

    local fishman = CheckpointSystem.IsFishmanArea(hrp, targetRoot)
    local retries = fishman
        and InternalTuning.Checkpoint.FishmanRetries
        or InternalTuning.Checkpoint.Retries
    local retryDelay = InternalTuning.Checkpoint.RetryDelay

    task.spawn(function()
        local remote = CommF_
        if not remote then
            remote = WaitForCommF(2)
            CommF_ = remote
        end

        if remote then
            -- Fishman/Underwater City gets extra attempts because the entrance
            -- uses a separate portal space and spawn replication can lag behind.
            for _ = 1, math.max(1, retries) do
                pcall(function()
                    remote:InvokeServer("SetSpawnPoint")
                end)
                task.wait(retryDelay)
            end
        end

        CheckpointSystem.Pending = false
    end)

    return true
end

--=====================================================================================
-- [32.8] SKIP FARM LEVEL
--=====================================================================================

SkipFarmLevelSystem.Active = false
SkipFarmLevelSystem.LastEntranceAt = 0
SkipFarmLevelSystem.LastAbandonAt = 0
SkipFarmLevelSystem.LastTargetScanAt = 0
SkipFarmLevelSystem.TargetCache = nil
SkipFarmLevelSystem.TargetCacheStage = nil
SkipFarmLevelSystem.LastCheckpointAt = 0
SkipFarmLevelSystem.LastCheckpointStage = nil

function SkipFarmLevelSystem.GetLevel()
    local data = LocalPlayer and LocalPlayer:FindFirstChild("Data")
    local level = data and data:FindFirstChild("Level")
    return level and tonumber(level.Value) or 0
end

function SkipFarmLevelSystem.GetStage()
    local level = SkipFarmLevelSystem.GetLevel()
    local darkMasterCap = InternalTuning.SkipFarm.DarkMasterMaxLevel
    local royalSquadCap = InternalTuning.SkipFarm.RoyalSquadMaxLevel

    if level > 0 and level < darkMasterCap then
        return {
            Key = "DARK_MASTER",
            Name = "Dark Master",
            Targets = {"Dark Master"},
            Cap = darkMasterCap,
            Entrance = InternalTuning.SkipFarm.LowerSkyEntrance,
            UpperSky = false,
        }
    end

    if level >= darkMasterCap and level < royalSquadCap then
        return {
            Key = "ROYAL_SQUAD",
            Name = "Royal Squad",
            Targets = {"Royal Squad"},
            Cap = royalSquadCap,
            Entrance = InternalTuning.SkipFarm.UpperSkyEntrance,
            FarmCFrame = InternalTuning.SkipFarm.UpperSkyFarmCFrame,
            UpperSky = true,
        }
    end

    return nil
end

function SkipFarmLevelSystem.ShouldRun()
    if not Config.SkipFarmLevel or not Config.AutoFarm then
        return false
    end

    if MeleeSystem.GetSea() ~= 1 then
        return false
    end

    return SkipFarmLevelSystem.GetStage() ~= nil
end

function SkipFarmLevelSystem.Reset()
    SkipFarmLevelSystem.Active = false
    SkipFarmLevelSystem.TargetCache = nil
    SkipFarmLevelSystem.TargetCacheStage = nil
    SkipFarmLevelSystem.LastTargetScanAt = 0
    SkipFarmLevelSystem.LastCheckpointStage = nil

    if Combat.CurrentTarget then
        Combat.CurrentTarget = nil
    end

    Combat.ResetAnchor()
end

function SkipFarmLevelSystem.Enter()
    if SkipFarmLevelSystem.Active then
        return
    end

    SkipFarmLevelSystem.Active = true
    SkipFarmLevelSystem.TargetCache = nil
    SkipFarmLevelSystem.TargetCacheStage = nil
    SkipFarmLevelSystem.LastTargetScanAt = 0

    -- SkipFarmLevel intentionally farms without normal quests.
    -- Drop any old quest once so the UI/quest sync cannot fight this mode.
    task.spawn(function()
        pcall(function()
            if CommF_ then
                CommF_:InvokeServer("AbandonQuest")
            end
        end)
    end)

    QuestSystem.Active = false
    QuestSystem.ActiveQuestCache = false
    QuestSystem.ActiveQuestCheckAt = 0
    QuestSystem.AnyQuestCache = false
    QuestSystem.AnyQuestCheckAt = 0
    QuestSystem.AcceptedGraceUntil = 0
    QuestSystem.LastAcceptedQuestKey = nil

    Combat.CurrentTarget = nil
    Combat.ResetAnchor()
    Teleport.Cancel()
end

function SkipFarmLevelSystem.FindTarget(stage)
    local now = tick()
    if not stage then
        return nil
    end

    if SkipFarmLevelSystem.TargetCacheStage ~= stage.Key then
        SkipFarmLevelSystem.TargetCache = nil
        SkipFarmLevelSystem.TargetCacheStage = stage.Key
    end

    if SkipFarmLevelSystem.TargetCache and SkipFarmLevelSystem.TargetCache.Parent then
        local hum = SkipFarmLevelSystem.TargetCache:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            return SkipFarmLevelSystem.TargetCache
        end
    end

    if now - (SkipFarmLevelSystem.LastTargetScanAt or 0) < 0.12 then
        return nil
    end

    SkipFarmLevelSystem.LastTargetScanAt = now

    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then
        return nil
    end

    local wanted = {}
    for index, name in ipairs(stage.Targets or {}) do
        wanted[NormalizeFarmEnemyName(name)] = index
    end

    local hrp = Utils.HRP()
    local best = nil
    local bestPriority = math.huge
    local bestDistance = math.huge

    for _, mob in ipairs(enemies:GetChildren()) do
        local hum = mob:FindFirstChildOfClass("Humanoid")
        local root = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
        local priority = wanted[NormalizeFarmEnemyName(mob.Name)]

        if priority and hum and hum.Health > 0 and root then
            local distance = hrp and (root.Position - hrp.Position).Magnitude or 0

            if priority < bestPriority
                or (priority == bestPriority and distance < bestDistance) then
                best = mob
                bestPriority = priority
                bestDistance = distance
            end
        end
    end

    SkipFarmLevelSystem.TargetCache = best
    return best
end

function SkipFarmLevelSystem.TryCheckpoint(stage, target)
    -- Kept for compatibility with the SkipFarmLevel flow, but checkpointing is
    -- now global and works on every Auto Farm island.
    if Config.AutoCheckpoint == false then
        return
    end
    CheckpointSystem.Try(target)
end

function SkipFarmLevelSystem.GoToStage(stage)
    local hrp = Utils.HRP()
    if not hrp or not stage then
        return true
    end

    local now = tick()
    local cooldown = InternalTuning.SkipFarm.EntranceCooldown

    -- Upper Skylands has a very large coordinate jump. Use the real game
    -- entrance first instead of flying thousands of studs.
    if stage.UpperSky and typeof(stage.FarmCFrame) == "CFrame" then
        local distance = (hrp.Position - stage.FarmCFrame.Position).Magnitude
        local arrivalDistance = InternalTuning.SkipFarm.ArrivalDistance

        if distance > 2500
            and now - (SkipFarmLevelSystem.LastEntranceAt or 0) >= cooldown then

            SkipFarmLevelSystem.LastEntranceAt = now

            task.spawn(function()
                pcall(function()
                    if CommF_ then
                        CommF_:InvokeServer("requestEntrance", stage.Entrance)
                    end
                end)
            end)

            UI.SetStatus(
                "Skip Farm Level | entering Upper Skylands | "
                    .. tostring(stage.Name)
            )
            return true
        end

        if distance > arrivalDistance then
            UI.SetStatus(
                "Skip Farm Level | going to " .. tostring(stage.Name)
                    .. " | " .. tostring(math.floor(distance)) .. " studs"
            )

            Teleport.To(
                stage.FarmCFrame * CFrame.new(0, 25, 0),
                Config.FarmSpeed or Config.TweenSpeed,
                "SKIP_FARM_LEVEL",
                false
            )
            return true
        end
    end

    -- Dark Master and final local positioning use the replicated spawn resolver.
    UI.SetStatus(
        "Skip Farm Level | going to spawn | " .. tostring(stage.Name)
    )

    local navigated = QuestSystem.NavigateToSpawn(stage.Targets)
    if navigated then
        return true
    end

    -- Last-resort entrance fallback if the spawn resolver has not replicated yet.
    if typeof(stage.Entrance) == "Vector3"
        and now - (SkipFarmLevelSystem.LastEntranceAt or 0) >= cooldown then

        SkipFarmLevelSystem.LastEntranceAt = now
        task.spawn(function()
            pcall(function()
                if CommF_ then
                    CommF_:InvokeServer("requestEntrance", stage.Entrance)
                end
            end)
        end)
    end

    return true
end

function SkipFarmLevelSystem.Tick()
    if not SkipFarmLevelSystem.ShouldRun() then
        if SkipFarmLevelSystem.Active then
            SkipFarmLevelSystem.Reset()

            QuestSystem.LastUpdate = 0
            QuestSystem.ActiveQuestCheckAt = 0
            QuestSystem.AnyQuestCheckAt = 0

            UI.SetStatus(
                "Skip Farm Level complete | returning to normal Farm Level",
                true
            )
        end

        return false
    end

    SkipFarmLevelSystem.Enter()

    local level = SkipFarmLevelSystem.GetLevel()
    local stage = SkipFarmLevelSystem.GetStage()
    if not stage then
        return false
    end

    local target = SkipFarmLevelSystem.FindTarget(stage)

    if target then
        SkipFarmLevelSystem.TryCheckpoint(stage, target)

        local displayName = NormalizeFarmEnemyName(target.Name)

        FarmEngine.Activity = "Skip Farm Level | " .. tostring(displayName)
        UI.SetStatus(
            "Skip Farm Level | Killing " .. tostring(displayName)
                .. " | Lv " .. tostring(level)
                .. "/" .. tostring(stage.Cap)
        )

        Combat.EngageTarget(target)
        return true
    end

    Combat.CurrentTarget = nil
    Combat.ResetAnchor()
    return SkipFarmLevelSystem.GoToStage(stage)
end

--=====================================================================================
-- [32.9] BARTILO QUEST - SECOND SEA
--=====================================================================================

BartiloSystem.LastProgressAt = 0
BartiloSystem.Progress = nil
BartiloSystem.LastQuestActionAt = 0
BartiloSystem.LastAbandonAt = 0
BartiloSystem.LastNPCScanAt = 0
BartiloSystem.CachedNPC = nil
BartiloSystem.LastPlateTouchAt = 0
BartiloSystem.LastObjectiveCheckAt = 0
BartiloSystem.Objective50Cache = false

function BartiloSystem.GetLevel()
    local data = LocalPlayer and LocalPlayer:FindFirstChild("Data")
    local level = data and data:FindFirstChild("Level")
    return level and tonumber(level.Value) or 0
end

function BartiloSystem.GetProgress(force)
    local now = tick()

    if not force
        and BartiloSystem.Progress ~= nil
        and now - (BartiloSystem.LastProgressAt or 0) < 0.55 then
        return BartiloSystem.Progress
    end

    BartiloSystem.LastProgressAt = now

    local result = nil
    pcall(function()
        if not CommF_ then
            CommF_ = WaitForCommF(2)
        end
        if CommF_ then
            result = CommF_:InvokeServer("BartiloQuestProgress", "Bartilo")
        end
    end)

    local numeric = tonumber(result)
    if numeric ~= nil then
        BartiloSystem.Progress = numeric
    end

    return BartiloSystem.Progress
end

function BartiloSystem.ShouldRun()
    if Config.AutoBartiloQuest == false or not Config.AutoFarm then
        return false
    end

    if MeleeSystem.GetSea() ~= 2 then
        return false
    end

    if BartiloSystem.GetLevel() < 850 then
        return false
    end

    local progress = BartiloSystem.GetProgress(false)
    return progress ~= nil and progress >= 0 and progress < 3
end

function BartiloSystem.FindEnemy(name)
    local enemies = workspace:FindFirstChild("Enemies")
    local hrp = Utils.HRP()
    if not enemies then
        return nil
    end

    local wanted = NormalizeFarmEnemyName(name)
    local best = nil
    local bestDistance = math.huge

    for _, mob in ipairs(enemies:GetChildren()) do
        if NormalizeFarmEnemyName(mob.Name) == wanted then
            local hum = mob:FindFirstChildOfClass("Humanoid")
            local root = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart

            if hum and hum.Health > 0 and root then
                local distance = hrp and (root.Position - hrp.Position).Magnitude or 0
                if distance < bestDistance then
                    best = mob
                    bestDistance = distance
                end
            end
        end
    end

    return best
end

function BartiloSystem.HasObjectiveAmount(required)
    local now = tick()
    if required == 50
        and now - (BartiloSystem.LastObjectiveCheckAt or 0) < 0.28 then
        return BartiloSystem.Objective50Cache == true
    end

    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        if required == 50 then
            BartiloSystem.LastObjectiveCheckAt = now
            BartiloSystem.Objective50Cache = false
        end
        return false
    end

    local matched = false
    local scanned = 0
    for _, obj in ipairs(playerGui:GetDescendants()) do
        scanned = scanned + 1
        if scanned > 650 then
            break
        end

        if (obj:IsA("TextLabel") or obj:IsA("TextButton"))
            and IsGuiActuallyVisible(obj) then

            local raw = tostring(obj.Text or "")
            local current, total = raw:match("(%d+)%s*/%s*(%d+)")
            current, total = tonumber(current), tonumber(total)

            if total == required and current and current >= 0 and current <= total then
                matched = true
                break
            end
        end
    end

    if required == 50 then
        BartiloSystem.LastObjectiveCheckAt = now
        BartiloSystem.Objective50Cache = matched
    end

    return matched
end

function BartiloSystem.FindBartiloNPC()
    local now = tick()
    if BartiloSystem.CachedNPC and BartiloSystem.CachedNPC.Parent then
        local cf = GetInstanceCFrameSafe(BartiloSystem.CachedNPC)
        if cf then
            return BartiloSystem.CachedNPC, cf
        end
    end

    if now - (BartiloSystem.LastNPCScanAt or 0) < 1.0 then
        return nil, nil
    end
    BartiloSystem.LastNPCScanAt = now

    local roots = {
        workspace:FindFirstChild("NPCs"),
        workspace:FindFirstChild("_WorldOrigin"),
        workspace,
    }

    for _, root in ipairs(roots) do
        if root then
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("Model") or obj:IsA("BasePart") then
                    local name = Utils.Normalize(obj.Name)
                    if string.find(name, "bartilo", 1, true) then
                        local cf = GetInstanceCFrameSafe(obj)
                        if cf then
                            BartiloSystem.CachedNPC = obj
                            return obj, cf
                        end
                    end
                end
            end
        end
    end

    return nil, nil
end

function BartiloSystem.StartSwanQuest()
    local now = tick()

    if QuestSystem.HasAnyActiveQuest(true) then
        if BartiloSystem.HasObjectiveAmount(50) then
            return true
        end

        if now - (BartiloSystem.LastAbandonAt or 0) >= 0.45 then
            BartiloSystem.LastAbandonAt = now
            pcall(function()
                if CommF_ then
                    CommF_:InvokeServer("AbandonQuest")
                end
            end)

            QuestSystem.AnyQuestCheckAt = 0
            QuestSystem.ActiveQuestCheckAt = 0
        end

        UI.SetStatus("Bartilo Quest | clearing wrong quest")
        return false
    end

    if BartiloSystem.HasObjectiveAmount(50) then
        return true
    end

    if now - (BartiloSystem.LastQuestActionAt or 0) >= 0.75 then
        BartiloSystem.LastQuestActionAt = now

        task.spawn(function()
            pcall(function()
                if not CommF_ then
                    CommF_ = WaitForCommF(2)
                end
                if CommF_ then
                    CommF_:InvokeServer("StartQuest", "BartiloQuest", 1)
                end
            end)
        end)
    end

    -- If the server does not accept the remote from far away, walk to Bartilo
    -- and let the next pass retry from the actual quest giver.
    local npc, npcCF = BartiloSystem.FindBartiloNPC()
    local hrp = Utils.HRP()

    if npcCF and hrp and (hrp.Position - npcCF.Position).Magnitude > 8 then
        UI.SetStatus("Bartilo Quest | going to Bartilo")
        Teleport.To(
            npcCF * CFrame.new(0, 3, 4),
            Config.FarmSpeed or Config.TweenSpeed,
            "BARTILO",
            true
        )
    else
        UI.SetStatus("Bartilo Quest | starting 50 Swan Pirates")
    end

    return false
end

function BartiloSystem.HandleSwanPirates()
    if not BartiloSystem.StartSwanQuest() then
        return true
    end

    local target = BartiloSystem.FindEnemy("Swan Pirate")
    if target then
        FarmEngine.Activity = "Bartilo Quest | Swan Pirate"
        UI.SetStatus("Bartilo Quest | Killing Swan Pirates | 50 required")
        Combat.EngageTarget(target)
        return true
    end

    Combat.CurrentTarget = nil
    Combat.ResetAnchor()
    UI.SetStatus("Bartilo Quest | going to Swan Pirate spawn")
    QuestSystem.NavigateToSpawn({"Swan Pirate"})
    return true
end

function BartiloSystem.HandleJeremy()
    local target = BartiloSystem.FindEnemy("Jeremy")

    if target then
        FarmEngine.Activity = "Bartilo Quest | Jeremy"
        UI.SetStatus("Bartilo Quest | Killing Jeremy")
        Combat.EngageTarget(target)
        return true
    end

    Combat.CurrentTarget = nil
    Combat.ResetAnchor()
    UI.SetStatus("Bartilo Quest | going to Jeremy spawn")

    if not QuestSystem.NavigateToSpawn({"Jeremy"}) then
        Teleport.To(
            CFrame.new(2316, 449, 787),
            Config.FarmSpeed or Config.TweenSpeed,
            "BARTILO",
            false
        )
    end

    return true
end

function BartiloSystem.HandlePuzzle()
    Combat.CurrentTarget = nil
    Combat.ResetAnchor()

    local map = workspace:FindFirstChild("Map")
    local dressrosa = map and map:FindFirstChild("Dressrosa")
    local plates = dressrosa and dressrosa:FindFirstChild("BartiloPlates")

    if not plates then
        UI.SetStatus("Bartilo Quest | waiting for puzzle plates")
        return true
    end

    for index = 1, 8 do
        local plate = plates:FindFirstChild("Plate" .. tostring(index))
        if plate and plate:IsA("BasePart") and plate.Color.G < 0.95 then
            local hrp = Utils.HRP()
            local distance = hrp and (hrp.Position - plate.Position).Magnitude or math.huge

            UI.SetStatus("Bartilo Quest | Puzzle Plate " .. tostring(index) .. "/8")

            if distance > 3.5 then
                Teleport.To(
                    plate.CFrame * CFrame.new(0, 2.5, 0),
                    Config.FarmSpeed or Config.TweenSpeed,
                    "BARTILO",
                    true
                )
            elseif tick() - (BartiloSystem.LastPlateTouchAt or 0) >= 0.35 then
                BartiloSystem.LastPlateTouchAt = tick()
                pcall(function()
                    hrp.CFrame = plate.CFrame * CFrame.new(0, 2.0, 0)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                end)
            end

            return true
        end
    end

    -- All plates look complete; refresh server progress immediately.
    BartiloSystem.GetProgress(true)
    UI.SetStatus("Bartilo Quest | puzzle complete, verifying")
    return true
end

function BartiloSystem.Tick()
    if not BartiloSystem.ShouldRun() then
        return false
    end

    local progress = BartiloSystem.GetProgress(false)

    if progress == 0 then
        return BartiloSystem.HandleSwanPirates()
    elseif progress == 1 then
        return BartiloSystem.HandleJeremy()
    elseif progress == 2 then
        return BartiloSystem.HandlePuzzle()
    end

    return false
end

--=====================================================================================
-- [33] FARM ENGINE EXPANSION
--=====================================================================================

function FarmEngine.SafeCall(label, callback)
    local ok, result = pcall(callback)
    if not ok then
        FarmEngine.LastError = tostring(label) .. ": " .. tostring(result)
        FarmEngine.ErrorCount = (FarmEngine.ErrorCount or 0) + 1
        Logger.error(FarmEngine.LastError)
        return false, nil
    end
    return true, result
end

--=====================================================================================
-- [37] AUTO CHAT / FARM FRAGMENTS / OPTIMIZE FIX LAG
--=====================================================================================

AutoChatSystem.Running = false

function AutoChatSystem.Send(message)
    local text = tostring(message or "")
    if text == "" then
        return false
    end

    -- Modern Roblox chat path. TextChannel:SendAsync is the supported API for
    -- TextChatService experiences. Fall back to the legacy remote when required.
    local ok = pcall(function()
        local channels = TextChatService and TextChatService:FindFirstChild("TextChannels")
        local general = channels and channels:FindFirstChild("RBXGeneral")

        if not general and channels then
            for _, child in ipairs(channels:GetChildren()) do
                if child:IsA("TextChannel") then
                    general = child
                    break
                end
            end
        end

        if general then
            general:SendAsync(text)
            return
        end

        error("TextChat channel unavailable")
    end)

    if ok then
        return true
    end

    local legacy = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    local say = legacy and legacy:FindFirstChild("SayMessageRequest")
    if say and say:IsA("RemoteEvent") then
        local legacyOK = pcall(function()
            say:FireServer(text, "All")
        end)
        return legacyOK
    end

    return false
end

function AutoChatSystem.Start()
    if AutoChatSystem.Running or not Config.AutoChatEnabled then
        return
    end

    local text = tostring(Config.AutoChatText or "")
    if text == "" then
        return
    end

    AutoChatSystem.Running = true
    task.spawn(function()
        local delaySeconds = math.max(5, tonumber(Config.AutoChatDelay) or 20)
        local nextSendAt = tick() + delaySeconds

        while AutoChatSystem.Running and IsCurrentSession() do
            if not Config.AutoChatEnabled then
                break
            end

            if tick() >= nextSendAt then
                AutoChatSystem.Send(Config.AutoChatText)
                nextSendAt = tick() + math.max(5, tonumber(Config.AutoChatDelay) or delaySeconds)
            end

            task.wait(0.5)
        end

        AutoChatSystem.Running = false
    end)
end

function AutoChatSystem.Stop()
    AutoChatSystem.Running = false
end

OptimizeFixLagSystem.ScreenGui = nil
OptimizeFixLagSystem.RenderingDisabled = false
OptimizeFixLagSystem.FpsCapApplied = false

function OptimizeFixLagSystem.ApplyScreenMode()
    local white = Config.OptimizeWhiteScreen == true
    local black = Config.OptimizeBlackScreen == true

    if white or black then
        pcall(function()
            RunService:Set3dRenderingEnabled(false)
            OptimizeFixLagSystem.RenderingDisabled = true
        end)

        if not OptimizeFixLagSystem.ScreenGui or not OptimizeFixLagSystem.ScreenGui.Parent then
            local gui = Instance.new("ScreenGui")
            gui.Name = "KratosOptimizeScreen"
            gui.IgnoreGuiInset = true
            gui.ResetOnSpawn = false
            gui.DisplayOrder = -100000

            local frame = Instance.new("Frame")
            frame.Name = "Background"
            frame.Size = UDim2.fromScale(1, 1)
            frame.BorderSizePixel = 0
            frame.Parent = gui

            local parent = nil
            pcall(function()
                if type(gethui) == "function" then
                    parent = gethui()
                end
            end)
            gui.Parent = parent or CoreGui
            OptimizeFixLagSystem.ScreenGui = gui
        end

        local frame = OptimizeFixLagSystem.ScreenGui:FindFirstChild("Background")
        if frame then
            -- Black wins if both were accidentally enabled.
            frame.BackgroundColor3 = black and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
        end
    else
        if OptimizeFixLagSystem.RenderingDisabled then
            pcall(function()
                RunService:Set3dRenderingEnabled(true)
            end)
            OptimizeFixLagSystem.RenderingDisabled = false
        end

        if OptimizeFixLagSystem.ScreenGui then
            pcall(function()
                OptimizeFixLagSystem.ScreenGui:Destroy()
            end)
            OptimizeFixLagSystem.ScreenGui = nil
        end
    end
end

function OptimizeFixLagSystem.ApplyFpsCap()
    if not Config.OptimizeLockFpsEnabled then
        return
    end

    local capFunction = nil
    pcall(function()
        local env = getgenv()
        capFunction = env and env.setfpscap or nil
    end)
    capFunction = capFunction or rawget(_G, "setfpscap")

    if type(capFunction) == "function" then
        local fps = math.clamp(math.floor(tonumber(Config.OptimizeLockFps) or 20), 10, 360)
        pcall(capFunction, fps)
        OptimizeFixLagSystem.FpsCapApplied = true
    end
end

function OptimizeFixLagSystem.Sync()
    OptimizeFixLagSystem.ApplyScreenMode()
    OptimizeFixLagSystem.ApplyFpsCap()
end

function OptimizeFixLagSystem.Stop()
    if OptimizeFixLagSystem.RenderingDisabled then
        pcall(function()
            RunService:Set3dRenderingEnabled(true)
        end)
        OptimizeFixLagSystem.RenderingDisabled = false
    end

    if OptimizeFixLagSystem.ScreenGui then
        pcall(function()
            OptimizeFixLagSystem.ScreenGui:Destroy()
        end)
        OptimizeFixLagSystem.ScreenGui = nil
    end
end

FragmentFarmSystem.Active = false
FragmentFarmSystem.WasInRaid = false
FragmentFarmSystem.LastChipAttempt = 0
FragmentFarmSystem.LastChipFallback = 0
FragmentFarmSystem.LastStartAttempt = 0
FragmentFarmSystem.ChipTaskRunning = false
FragmentFarmSystem.LastIslandIndex = 0

function FragmentFarmSystem.GetLevel()
    local data = LocalPlayer:FindFirstChild("Data")
    local level = data and data:FindFirstChild("Level")
    return level and tonumber(level.Value) or 0
end

function FragmentFarmSystem.GetFragments()
    local data = LocalPlayer:FindFirstChild("Data")
    local fragments = data and data:FindFirstChild("Fragments")
    return fragments and tonumber(fragments.Value) or 0
end

function FragmentFarmSystem.HasTool(name)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    return (backpack and backpack:FindFirstChild(name))
        or (char and char:FindFirstChild(name))
end

function FragmentFarmSystem.FindPhysicalFruit()
    local function scan(container)
        if not container then
            return nil
        end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Tool") and tostring(child.ToolTip) == "Blox Fruit" then
                return child
            end
        end
        return nil
    end

    return scan(LocalPlayer:FindFirstChild("Backpack")) or scan(LocalPlayer.Character)
end

function FragmentFarmSystem.IsCheapFruitName(name)
    local wanted = tostring(name or ""):lower():gsub("%s*fruit$", "")
    for _, key in ipairs(InternalTuning.Fragments.CheapFruitKeys) do
        local normalized = tostring(key):lower():gsub("%-", " "):gsub("%s+", " ")
        normalized = normalized:gsub(" fruit$", "")
        local keyShort = normalized:match("^([^ ]+)") or normalized
        if wanted:find(keyShort, 1, true) then
            return true
        end
    end
    return false
end

function FragmentFarmSystem.LoadCheapStoredFruit()
    if not CommF_ then
        CommF_ = WaitForCommF(2)
    end
    if not CommF_ then
        return false
    end

    local existing = FragmentFarmSystem.FindPhysicalFruit()
    if existing then
        return FragmentFarmSystem.IsCheapFruitName(existing.Name)
    end

    for _, fruitKey in ipairs(InternalTuning.Fragments.CheapFruitKeys) do
        local ok = pcall(function()
            CommF_:InvokeServer("LoadFruit", fruitKey)
        end)
        if ok then
            task.wait(0.08)
            local fruitTool = FragmentFarmSystem.FindPhysicalFruit()
            if fruitTool then
                return FragmentFarmSystem.IsCheapFruitName(fruitTool.Name)
            end
        end
    end

    return false
end

function FragmentFarmSystem.IsRaidActive()
    local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
    local locations = worldOrigin and worldOrigin:FindFirstChild("Locations")
    if locations and locations:FindFirstChild("Island 1") then
        return true
    end

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local main = playerGui and playerGui:FindFirstChild("Main")
    if main then
        local top = main:FindFirstChild("TopHUDList")
        local raidTimer = top and top:FindFirstChild("RaidTimer")
        if raidTimer and raidTimer:IsA("GuiObject") and raidTimer.Visible then
            return true
        end

        local timer = main:FindFirstChild("Timer")
        if timer and timer:IsA("GuiObject") and timer.Visible then
            return true
        end
    end

    return false
end

function FragmentFarmSystem.GetHighestRaidIsland()
    local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
    local locations = worldOrigin and worldOrigin:FindFirstChild("Locations")
    if not locations then
        return nil, 0
    end

    local best, bestIndex = nil, 0
    for _, child in ipairs(locations:GetChildren()) do
        local index = tonumber(tostring(child.Name):match("^Island (%d+)$"))
        if index and index > bestIndex then
            best = child
            bestIndex = index
        end
    end

    return best, bestIndex
end

function FragmentFarmSystem.GetObjectPosition(object)
    if not object then
        return nil
    end
    if object:IsA("BasePart") then
        return object.Position
    end
    if object:IsA("Model") then
        local ok, cf = pcall(function()
            return object:GetPivot()
        end)
        if ok and cf then
            return cf.Position
        end
    end
    return nil
end

function FragmentFarmSystem.FindNearestRaidEnemy(centerPosition)
    local enemies = workspace:FindFirstChild("Enemies")
    local hrp = Utils.HRP()
    if not enemies or not hrp then
        return nil
    end

    local best, bestDistance = nil, math.huge
    local searchRadius = tonumber(InternalTuning.Fragments.EnemySearchRadius) or 1800

    for _, enemy in ipairs(enemies:GetChildren()) do
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
        if hum and root and hum.Health > 0 then
            local nearIsland = true
            if centerPosition then
                nearIsland = (root.Position - centerPosition).Magnitude <= searchRadius
            end

            if nearIsland then
                local distance = (root.Position - hrp.Position).Magnitude
                if distance < bestDistance then
                    best = enemy
                    bestDistance = distance
                end
            end
        end
    end

    return best
end

function FragmentFarmSystem.GetRaidStartDetector()
    local sea = MeleeSystem.GetSea()
    local map = workspace:FindFirstChild("Map")
    if not map then
        return nil
    end

    local container = nil
    if sea == 2 then
        local circle = map:FindFirstChild("CircleIsland")
        container = circle and (circle:FindFirstChild("RaidSummon2") or circle:FindFirstChild("RaidSummon"))
    elseif sea == 3 then
        local castle = map:FindFirstChild("Boat Castle")
        container = castle and (castle:FindFirstChild("RaidSummon2") or castle:FindFirstChild("RaidSummon"))
    end

    if not container then
        return nil
    end

    return container:FindFirstChildWhichIsA("ClickDetector", true)
        or container:FindFirstChildWhichIsA("ProximityPrompt", true)
end

function FragmentFarmSystem.TryStartRaid()
    local now = tick()
    if now - (FragmentFarmSystem.LastStartAttempt or 0) < (tonumber(InternalTuning.Fragments.StartRetry) or 3) then
        return false
    end
    FragmentFarmSystem.LastStartAttempt = now

    local detector = FragmentFarmSystem.GetRaidStartDetector()
    if not detector then
        UI.SetStatus("Farm Fragments | raid start button not found")
        return false
    end

    if detector:IsA("ClickDetector") and type(fireclickdetector) == "function" then
        return pcall(function()
            fireclickdetector(detector)
        end)
    elseif detector:IsA("ProximityPrompt") and type(fireproximityprompt) == "function" then
        return pcall(function()
            fireproximityprompt(detector, 1)
        end)
    end

    UI.SetStatus("Farm Fragments | executor cannot press raid button")
    return false
end

function FragmentFarmSystem.TryGetChip()
    if FragmentFarmSystem.ChipTaskRunning then
        return true
    end

    local now = tick()
    local retry = tonumber(InternalTuning.Fragments.ChipRetry) or 4
    if now - (FragmentFarmSystem.LastChipAttempt or 0) < retry then
        return true
    end

    FragmentFarmSystem.LastChipAttempt = now
    FragmentFarmSystem.ChipTaskRunning = true

    task.spawn(function()
        local function finish()
            FragmentFarmSystem.ChipTaskRunning = false
        end

        if not CommF_ then
            CommF_ = WaitForCommF(2)
        end
        if not CommF_ then
            finish()
            return
        end

        -- First attempt the normal 100k/free-cooldown purchase.
        pcall(function()
            CommF_:InvokeServer("RaidsNpc", "Select", InternalTuning.Fragments.RaidType)
        end)
        task.wait(0.35)

        if FragmentFarmSystem.HasTool("Special Microchip") then
            finish()
            return
        end

        -- During the scientist cooldown, use only a cheap/common stored fruit.
        local fallbackRetry = tonumber(InternalTuning.Fragments.ChipFallbackRetry) or 18
        if tick() - (FragmentFarmSystem.LastChipFallback or 0) >= fallbackRetry then
            FragmentFarmSystem.LastChipFallback = tick()
            if FragmentFarmSystem.LoadCheapStoredFruit() then
                pcall(function()
                    CommF_:InvokeServer("RaidsNpc", "Select", InternalTuning.Fragments.RaidType)
                end)
                task.wait(0.20)
            end
        end

        finish()
    end)

    return true
end

function FragmentFarmSystem.ShouldRun()
    if not Config.FarmFragmentsEnabled or not Config.AutoFarm then
        return false
    end

    local sea = MeleeSystem.GetSea()
    if sea ~= 2 and sea ~= 3 then
        return false
    end

    if FragmentFarmSystem.GetLevel() < (tonumber(InternalTuning.Fragments.MinHostLevel) or 1100) then
        return false
    end

    return FragmentFarmSystem.GetFragments() < (tonumber(Config.FarmFragmentsTarget) or 50000)
end

function FragmentFarmSystem.Stop()
    FragmentFarmSystem.Active = false
    FragmentFarmSystem.WasInRaid = false
    FragmentFarmSystem.LastIslandIndex = 0
    FragmentFarmSystem.ChipTaskRunning = false

    if Teleport.Owner == "FRAGMENTS" then
        Teleport.Cancel()
    end
end

function FragmentFarmSystem.Tick()
    if not FragmentFarmSystem.ShouldRun() then
        if FragmentFarmSystem.Active then
            FragmentFarmSystem.Stop()
        end
        return false
    end

    FragmentFarmSystem.Active = true
    local currentFragments = FragmentFarmSystem.GetFragments()
    local targetFragments = tonumber(Config.FarmFragmentsTarget) or 50000
    local raidActive = FragmentFarmSystem.IsRaidActive()

    if raidActive then
        FragmentFarmSystem.WasInRaid = true
        local island, islandIndex = FragmentFarmSystem.GetHighestRaidIsland()
        local islandPosition = FragmentFarmSystem.GetObjectPosition(island)
        FragmentFarmSystem.LastIslandIndex = math.max(FragmentFarmSystem.LastIslandIndex or 0, islandIndex or 0)

        local target = FragmentFarmSystem.FindNearestRaidEnemy(islandPosition)
        if target then
            UI.SetStatus(
                "Farm Fragments | Raid Island " .. tostring(math.max(1, islandIndex or 1))
                    .. " | " .. tostring(currentFragments) .. "/" .. tostring(targetFragments)
            )
            Utils.EnsureMeleeEquipped(true)
            Combat.EngageTarget(target)
            return true
        end

        if islandPosition then
            local hrp = Utils.HRP()
            local moveDistance = tonumber(InternalTuning.Fragments.IslandMoveDistance) or 220
            if hrp and (hrp.Position - islandPosition).Magnitude > moveDistance then
                UI.SetStatus("Farm Fragments | moving to Raid Island " .. tostring(islandIndex))
                Teleport.To(
                    CFrame.new(islandPosition + Vector3.new(0, InternalTuning.Fragments.IslandYOffset or 35, 0)),
                    Config.TweenSpeed,
                    "FRAGMENTS",
                    true
                )
            else
                UI.SetStatus("Farm Fragments | waiting next raid wave")
            end
        else
            UI.SetStatus("Farm Fragments | waiting raid island")
        end

        return true
    end

    -- The raid just ended; release combat lock before buying the next chip.
    if FragmentFarmSystem.WasInRaid then
        FragmentFarmSystem.WasInRaid = false
        Combat.CurrentTarget = nil
        Combat.ResetAnchor()
        if Teleport.Owner == "FRAGMENTS" then
            Teleport.Cancel()
        end
        FragmentFarmSystem.LastStartAttempt = 0
        FragmentFarmSystem.LastChipAttempt = 0
    end

    if FragmentFarmSystem.HasTool("Special Microchip") then
        UI.SetStatus(
            "Farm Fragments | starting Flame raid | "
                .. tostring(currentFragments) .. "/" .. tostring(targetFragments)
        )
        FragmentFarmSystem.TryStartRaid()
        return true
    end

    UI.SetStatus(
        "Farm Fragments | getting raid chip | "
            .. tostring(currentFragments) .. "/" .. tostring(targetFragments)
    )
    FragmentFarmSystem.TryGetChip()
    return true
end

function FarmEngine.Tick()
    if not FarmEngine.Running then
        return
    end

    if not Utils.IsAlive() then
        Combat.ReleaseHealthRetreat()
        Combat.ResetAnchor()
        Watchdog.ResetTracking()
        UI.SetStatus("Waiting for character...")
        return
    end

    -- Self-heal stale movement ownership/tweens before any farm priority runs.
    FarmEngine.SafeCall("MovementWatchdog", Watchdog.Tick)

    -- Global HP safety owns movement before Farm/Saber/Boss systems.
    local hpOK, hpRetreating = FarmEngine.SafeCall(
        "CombatHPSafety",
        Combat.HealthSafetyTick
    )

    if hpOK and hpRetreating then
        FarmEngine.SafeCall("FPSBoost", FPSBoostSystem.Sync)
        FarmEngine.SafeCall("DialogueSuppressor", DialogueSuppressor.Sync)
        return
    end

    -- Purchase has priority after health safety.
    FarmEngine.SafeCall("FightingStyles", MeleeSystem.Tick)

    local rushLevelNow = SkipFarmLevelSystem.GetLevel()
    local rushBlocksPurchase = Config.SkipFarmLevel == true
        and MeleeSystem.GetSea() == 1
        and rushLevelNow > 0
        and rushLevelNow < InternalTuning.SkipFarm.RoyalSquadMaxLevel

    local purchaseOK, purchaseActive = true, false
    if not rushBlocksPurchase then
        purchaseOK, purchaseActive = FarmEngine.SafeCall(
            "FightingStylePurchase",
            MeleeSystem.HandlePurchasePriority
        )
    end

    if purchaseOK and purchaseActive then
        FarmEngine.SafeCall("FPSBoost", FPSBoostSystem.Sync)
        return
    end

    -- Lv 50+ Saber quest pauses Farm Level until Saber is actually owned.
    local saberOK, saberActive = FarmEngine.SafeCall(
        "SaberPriority",
        SaberSystem.HandlePriority
    )

    if saberOK and saberActive then
        FarmEngine.SafeCall("FPSBoost", FPSBoostSystem.Sync)
        FarmEngine.SafeCall("DialogueSuppressor", DialogueSuppressor.Sync)
        return
    end

    -- Sea 2 is locked until level 700 AND Electro mastery 400.
    -- While Electro is below 400 this returns false, so normal First Sea
    -- level farming continues and supplies the mastery XP.
    local sea2OK, sea2Active = FarmEngine.SafeCall("Sea2Transition", Sea2System.Tick)
    if sea2OK and sea2Active then
        FarmEngine.SafeCall("FPSBoost", FPSBoostSystem.Sync)
        return
    end

    FarmEngine.SafeCall("Safety", SafetySystem.Tick)

    if Config.AutoTeam and Config.ForceTeamSet then
        local currentTeam = tostring(LocalPlayer.Team)
        if currentTeam ~= Config.Team then
            UI.SetStatus("Team | correcting selection")
            FarmEngine.SafeCall("Team", SetupTeam)
            return
        end
    end

    -- Random fruit is housekeeping only; it never owns movement or pauses farming.
    FarmEngine.SafeCall("RandomFruitRemote", FruitSystem.AutoRandomTick)

    -- A filtered world fruit may briefly interrupt normal level farm, but never
    -- pull the character out of an active/targeted Fragment Raid.
    -- Saber and Sea transitions were already checked above, so they remain authoritative.
    local fragmentWantsControl = FragmentFarmSystem.ShouldRun()
    if not fragmentWantsControl then
        local fruitOK, fruitActive = FarmEngine.SafeCall("FruitPriority", FruitSystem.Tick)
        if fruitOK and fruitActive then
            FarmEngine.SafeCall("FPSBoost", FPSBoostSystem.Sync)
            return
        end
    end

    -- Non-movement housekeeping only.
    FarmEngine.SafeCall("Stats", StatsSystem.Tick)
    FarmEngine.SafeCall("FPSBoost", FPSBoostSystem.Sync)
    FarmEngine.SafeCall("DialogueSuppressor", DialogueSuppressor.Sync)

    if not Config.AutoFarm then
        Combat.ResetAnchor()

        -- Fighting-style progression already runs above and does not own movement.

        UI.SetStatus("Auto Farm disabled")
        return
    end

    -- Bartilo is a one-time Second Sea story progression:
    -- 50 Swan Pirates -> Jeremy -> 8-plate puzzle. Keep story progression ahead
    -- of optional fragment raids if an old account somehow reaches Lv1100 first.
    local bartiloOK, bartiloActive = FarmEngine.SafeCall(
        "BartiloQuest",
        BartiloSystem.Tick
    )
    if bartiloOK and bartiloActive then
        return
    end

    -- Optional target-based fragment farming. At Lv1100+ in Sea 2/3 it owns
    -- movement/combat until the requested fragment amount is reached.
    local fragmentOK, fragmentActive = FarmEngine.SafeCall(
        "FarmFragments",
        FragmentFarmSystem.Tick
    )
    if fragmentOK and fragmentActive then
        FarmEngine.SafeCall("FPSBoost", FPSBoostSystem.Sync)
        return
    end

    -- First/Second Sea Raid Boss override. Any live [Raid Boss] model takes
    -- priority over normal level farming, but not over an explicitly enabled
    -- fragment raid target.
    local raidOK, raidActive = FarmEngine.SafeCall(
        "RaidBossPriority",
        BossSystem.HandleRaidBossPriority
    )
    if raidOK and raidActive then
        return
    end

    -- Nearby chests are a short level-farm detour. Collect the whole local batch
    -- and return to the saved farm position before normal farming resumes.
    local chestOK, chestActive = FarmEngine.SafeCall(
        "NearbyChests",
        ChestSystem.Tick
    )
    if chestOK and chestActive then
        FarmEngine.SafeCall("FPSBoost", FPSBoostSystem.Sync)
        return
    end

    -- SkipFarmLevel overrides weak early quests:
    -- Lv 1-24 Dark Master, Lv 25-59 Royal Squad, then normal quest farming.
    local rushOK, rushActive = FarmEngine.SafeCall(
        "SkipFarmLevel",
        SkipFarmLevelSystem.Tick
    )
    if rushOK and rushActive then
        return
    end

    -- FARM LEVEL HAS PRIORITY FROM THIS POINT ON.
    local questOK, quest = FarmEngine.SafeCall("QuestUpdate", QuestSystem.Update)
    if not questOK or not quest then
        Combat.ResetAnchor()
        UI.SetStatus("Farm Level | resolving quest")
        return
    end

    -- STRICT QUEST SYNC: never attack a normal mob while a different mission
    -- is still active. This fixes boss -> normal fallback transitions such as
    -- Magma Admiral (0/1) remaining active while Current already became
    -- Military Spy (0/8). The check is locale-safe because the quest objective
    -- amount is used in addition to the mob name.
    if Config.StrictQuestSync ~= false then
        -- Read one throttled GUI snapshot. Do not invalidate the cache here;
        -- doing so every farm tick forced multiple full PlayerGui scans per cycle.
        local anyActive = QuestSystem.HasAnyActiveQuest()
        local currentMatches = QuestSystem.HasActiveQuest()

        if QuestSystem.RequireQuestClear then
            if anyActive then
                local nowSync = tick()
                if nowSync - (QuestSystem.LastMismatchAbandonAt or 0) >= (tonumber(Config.QuestMismatchAbandonInterval) or 0.35) then
                    QuestSystem.LastMismatchAbandonAt = nowSync
                    pcall(function()
                        CommF_:InvokeServer("AbandonQuest")
                    end)
                end

                QuestSystem.AcceptedGraceUntil = 0
                QuestSystem.LastAcceptedQuestKey = nil
                QuestSystem.ActiveQuestCheckAt = 0
                QuestSystem.AnyQuestCheckAt = 0
                Combat.CurrentTarget = nil
                Combat.ResetAnchor()
                Teleport.Cancel()
                UI.SetStatus(
                    "Quest Sync | clearing " .. tostring(QuestSystem.QuestSwitchFrom or "old quest")
                        .. " -> " .. tostring(QuestSystem.QuestSwitchTo or quest.Mob)
                )
                return
            end

            QuestSystem.RequireQuestClear = false
            QuestSystem.QuestSwitchFrom = nil
            QuestSystem.QuestSwitchTo = nil
            QuestSystem.LastMismatchAbandonAt = 0
            QuestSystem.ActiveQuestCache = false
            QuestSystem.ActiveQuestCheckAt = 0
        elseif anyActive and not currentMatches then
            local nowSync = tick()
            if nowSync - (QuestSystem.LastMismatchAbandonAt or 0) >= (tonumber(Config.QuestMismatchAbandonInterval) or 0.35) then
                QuestSystem.LastMismatchAbandonAt = nowSync
                pcall(function()
                    CommF_:InvokeServer("AbandonQuest")
                end)
            end

            QuestSystem.AcceptedGraceUntil = 0
            QuestSystem.LastAcceptedQuestKey = nil
            QuestSystem.ActiveQuestCache = false
            QuestSystem.ActiveQuestCheckAt = 0
            QuestSystem.AnyQuestCheckAt = 0
            QuestSystem.AnyQuestCache = false
            Combat.CurrentTarget = nil
            Combat.ResetAnchor()
            Teleport.Cancel()
            UI.SetStatus("Quest Sync | removing wrong quest before " .. tostring(quest.Mob))
            return
        end
    end

    local activeOK, questActive = FarmEngine.SafeCall("QuestTracker", QuestSystem.HasFarmQuest)
    if not activeOK then
        UI.SetStatus("Farm Level | checking quest")
        return
    end

    if questActive then
        -- If the grace window ended, the real tracker must confirm the quest.
        if tick() >= (QuestSystem.AcceptedGraceUntil or 0) then
            QuestSystem.ActiveQuestCheckAt = 0
            if not QuestSystem.HasActiveQuest() then
                QuestSystem.LastAcceptedQuestKey = nil
                QuestSystem.AcceptedGraceUntil = 0
                questActive = false
            end
        end
    end

    if questActive then
        QuestSystem.FastQuestAttempts = 0
        QuestSystem.FastQuestFallbackUntil = 0

        -- Never stay parked at the quest giver after the mission is active.
        local giverCF = QuestSystem.GetQuestGiverCFrame()
        local hrp = Utils.HRP()
        if giverCF and hrp then
            local giverDistance = (giverCF.Position - hrp.Position).Magnitude
            if giverDistance <= 18 then
                -- Release NPC approach once; let an existing FARM trip continue.
                if Teleport.Owner == "QUEST" then
                    Teleport.Cancel()
                end
                UI.SetStatus("Quest active | leaving NPC for " .. tostring(quest.Mob))
                QuestSystem.GoToFarmAfterAcquire()
                return
            end
        end

        if quest.Boss then
            local bossOK, handled = FarmEngine.SafeCall("Boss", function()
                return BossSystem.HandleBossQuest(quest)
            end)
            if bossOK and handled then
                return
            end
        end

        local target = Combat.FindQuestMob()
        if target then
            local melee = Utils.EnsureMeleeEquipped(true)
            if tostring(Config.FarmWeaponType) == "Melee" and not melee then
                UI.SetStatus("Equipping combat style...")
                return
            end

            UI.SetStatus("Farming 1 mob | " .. tostring(quest.Mob) .. " | " .. MeleeSystem.GetStatus())
            Combat.EngageTarget(target)
        else
            Combat.CurrentTarget = nil
            Combat.ResetAnchor()
            QuestSystem.GoToFarmAfterAcquire()
        end

        return
    end

    -- No active quest.
    Combat.CurrentTarget = nil
    Combat.ResetAnchor()

    local questKey = tostring(quest.Quest) .. ":" .. tostring(quest.Num)
    if QuestSystem.FastQuestLastKey ~= questKey then
        QuestSystem.FastQuestLastKey = questKey
        QuestSystem.FastQuestAttempts = 0
        QuestSystem.FastQuestLastAttempt = 0
        QuestSystem.FastQuestFallbackUntil = 0
    end

    local now = tick()
    local useFastQuest = Config.FastQuestMode == true
        and not QuestSystem.IsPrisonQuest(quest)
        and now >= (QuestSystem.FastQuestFallbackUntil or 0)

    -- Same idea as Speed Hub X "Auto Take Quest": call StartQuest immediately,
    -- without spending time walking to the NPC. Re-check the real quest tracker
    -- on subsequent farm ticks.
    if useFastQuest
        and (QuestSystem.FastQuestAttempts or 0) < (tonumber(Config.FastQuestMaxRemoteAttempts) or 4)
        and now - (QuestSystem.FastQuestLastAttempt or 0) >= (tonumber(Config.FastQuestRetryInterval) or 0.22) then

        QuestSystem.FastQuestLastAttempt = now
        QuestSystem.FastQuestAttempts = (QuestSystem.FastQuestAttempts or 0) + 1
        QuestSystem.LastQuestAction = now

        UI.SetStatus(
            "Fast Quest | " .. tostring(quest.Mob)
                .. " | try " .. tostring(QuestSystem.FastQuestAttempts)
        )

        local ok = pcall(function()
            CommF_:InvokeServer("StartQuest", quest.Quest, quest.Num)
        end)

        QuestSystem.ActiveQuestCheckAt = 0

        if ok and QuestSystem.HasActiveQuest(true) then
            Teleport.Cancel()
            QuestSystem.GoToFarmAfterAcquire()
        else
            UI.SetStatus("Farm Level | confirming quest | " .. tostring(quest.Mob))
        end
        return
    end

    -- If remote quest acquisition is rejected by this server/executor, fall
    -- back to the normal proximity method instead of getting stuck.
    if useFastQuest
        and (QuestSystem.FastQuestAttempts or 0) >= (tonumber(Config.FastQuestMaxRemoteAttempts) or 4) then
        QuestSystem.FastQuestFallbackUntil = now + (tonumber(Config.FastQuestFallbackReset) or 3.0)
    end

    local giverCF = QuestSystem.GetQuestGiverCFrame()
    local hrp = Utils.HRP()

    if not giverCF or not hrp then
        UI.SetStatus("Farm Level | finding quest giver")
        return
    end

    local distance = (giverCF.Position - hrp.Position).Magnitude
    local questDistance = tonumber(Config.FarmQuestDistance) or 5
    local isHeadJailer = Config.PrisonSafeQuestMovement
        and quest.Giver
        and Utils.Normalize(quest.Giver[1]) == "head jailer"

    if isHeadJailer then
        questDistance = math.max(
            questDistance,
            tonumber(Config.QuestGiverInteractDistance) or 8.0
        )
    end

    if distance <= questDistance then
        if Teleport.Owner == "QUEST" then
            Teleport.Cancel()
        end

        UI.SetStatus("Accepting Quest | " .. tostring(quest.Mob))

        if isHeadJailer then
            QuestSystem.TryHeadJailerInteract(quest, giverCF)
        end

        if now - (QuestSystem.LastQuestAction or 0) >= 0.35 then
            QuestSystem.LastQuestAction = now

            local ok, result = pcall(function()
                return CommF_:InvokeServer("StartQuest", quest.Quest, quest.Num)
            end)

            if ok and result ~= false then
                QuestSystem.ActiveQuestCheckAt = 0
                QuestSystem.FastQuestAttempts = 0
                QuestSystem.FastQuestFallbackUntil = 0
                QuestSystem.GiverApproachCache = {}

                if QuestSystem.IsPrisonQuest(quest) then
                    -- Stay beside the Prison quest NPC until the real tracker
                    -- confirms the mission. Never bounce back to the farm on a
                    -- merely successful remote call.
                    QuestSystem.LastAcceptedQuestKey = nil
                    QuestSystem.AcceptedGraceUntil = 0
                    Teleport.Cancel()

                    QuestSystem.ActiveQuestCheckAt = 0
                    if QuestSystem.HasActiveQuest() then
                        QuestSystem.PrisonWaitingSince = 0
                        UI.SetStatus("Prison quest confirmed | going to " .. tostring(quest.Mob))
                        QuestSystem.GoToFarmAfterAcquire()
                    else
                        QuestSystem.PrisonWaitingSince = QuestSystem.PrisonWaitingSince == 0 and tick() or QuestSystem.PrisonWaitingSince
                        QuestSystem.TryHeadJailerInteract(quest, giverCF)
                        if tick() - (QuestSystem.PrisonWaitingSince or 0) >= (tonumber(Config.PrisonQuestConfirmTimeout) or 2.0) then
                            QuestSystem.LastQuestAction = 0
                        end
                        UI.SetStatus("Prison | waiting quest confirmation")
                    end
                    return
                end

                Teleport.Cancel()
                if QuestSystem.HasActiveQuest(true) then
                    UI.SetStatus("Quest confirmed | going to " .. tostring(quest.Mob))
                    QuestSystem.GoToFarmAfterAcquire()
                else
                    UI.SetStatus("Farm Level | waiting quest confirmation | " .. tostring(quest.Mob))
                end
                return
            end
        end
    else
        -- The special side/height approach is only needed for Head Jailer.
        -- Ordinary NPCs use a small vertical offset so FarmQuestDistance=5
        -- can actually be reached (4 horizontal + 3.5 vertical was > 5).
        local approachCF = isHeadJailer
            and QuestSystem.GetSafeGiverApproachCFrame(quest, giverCF)
            or CFrame.new(giverCF.Position + Vector3.new(0, 3, 0), giverCF.Position)

        UI.SetStatus("Going Quest NPC | " .. QuestSystem.GetGiverDisplayName(quest))
        Teleport.To(
            approachCF or giverCF,
            Config.TweenSpeed,
            "QUEST",
            false
        )
    end
end

--=====================================================================================
-- [UI CLEANUP] NPC DIALOGUE AUTO DISMISS
-- Automatically clicks intrusive NPC dialogue, then clicks the response button
-- (for example "Not this time!") so the farm can continue without UI blocking.
--=====================================================================================

DialogueSuppressor.Enabled = false
DialogueSuppressor.PlayerGui = nil
DialogueSuppressor.Connections = {}
DialogueSuppressor.ObservedText = setmetatable({}, {__mode = "k"})
DialogueSuppressor.AllText = setmetatable({}, {__mode = "k"})
DialogueSuppressor.PrisonerActiveUntil = 0
DialogueSuppressor.PrisonerLastActionAt = 0
DialogueSuppressor.PrisonerActionCooldown = 0.16
DialogueSuppressor.LastClickAt = 0
DialogueSuppressor.LastScanAt = 0
DialogueSuppressor.ClickCooldown = 0.18
DialogueSuppressor.ScanInterval = 0.60
DialogueSuppressor.Pending = setmetatable({}, {__mode = "k"})
DialogueSuppressor.ActiveUntil = 0
DialogueSuppressor.DialogueWindow = 2.5

DialogueSuppressor.BlockedPhrases = {
    "escaped prisoner",
    "not this time!",
    "hey! you gonna help me get through, or",
    "you gonna help me get through, or",
    "you gonna grab a hammer and help",
    "confront the prisoner before attacking!",
    "just gotta patch up these last planks and she'll float",
    "just gotta patch up these last planks",
    "she'll float",
    "help me dig",
    "grab a hammer",
}

DialogueSuppressor.ResponsePhrases = {
    "not this time!",
    "not this time",
}

DialogueSuppressor.PrisonerDismissPhrases = {
    "nevermind",
    "never mind",
    "leave",
    "cancel",
}

-- Positive story choices are intentionally separate from generic responses.
-- They are clicked ONLY while the Saber state machine is interacting with a
-- story NPC, preventing the random screen clicks that older builds caused.
DialogueSuppressor.StoryResponsePhrases = {
    "conversar",
    "talk",
    "continuar",
    "continue",
    "sim",
    "yes",
}

DialogueSuppressor.NegativeStoryPhrases = {
    "esquece",
    "forget",
    "leave",
    "cancel",
}

local function NormalizeDialogueText(value)
    local textValue = string.lower(tostring(value or ""))
    textValue = textValue:gsub("%s+", " ")
    textValue = textValue:gsub("^%s+", "")
    textValue = textValue:gsub("%s+$", "")
    return textValue
end

function DialogueSuppressor.IsBlockedText(value)
    local normalized = NormalizeDialogueText(value)
    if normalized == "" then
        return false
    end

    for _, phrase in ipairs(DialogueSuppressor.BlockedPhrases) do
        if string.find(normalized, phrase, 1, true) then
            return true
        end
    end

    return false
end

function DialogueSuppressor.IsResponseText(value)
    local normalized = NormalizeDialogueText(value)
    if normalized == "" then
        return false
    end

    for _, phrase in ipairs(DialogueSuppressor.ResponsePhrases) do
        if string.find(normalized, phrase, 1, true) then
            return true
        end
    end

    return false
end

function DialogueSuppressor.IsPrisonerDismissText(value)
    local normalized = NormalizeDialogueText(value)
    if normalized == "" then
        return false
    end

    for _, phrase in ipairs(DialogueSuppressor.PrisonerDismissPhrases) do
        if normalized == phrase or string.find(normalized, phrase, 1, true) then
            return true
        end
    end

    return false
end


function DialogueSuppressor.IsStoryResponseText(value)
    local normalized = NormalizeDialogueText(value)
    if normalized == "" then
        return false
    end

    for _, phrase in ipairs(DialogueSuppressor.NegativeStoryPhrases) do
        if normalized == phrase then
            return false
        end
    end

    -- Exact match on purpose: short words such as "sim"/"yes" must never
    -- match arbitrary HUD text that merely contains those letters.
    for _, phrase in ipairs(DialogueSuppressor.StoryResponsePhrases) do
        if normalized == phrase then
            return true
        end
    end

    return false
end

function DialogueSuppressor.IsSaberStoryStep()
    local step = SaberSystem and tostring(SaberSystem.CurrentStep or "") or ""
    return step == "RICH_MAN"
        or step == "GET_RELIC"
        or step == "SICK_MAN"
end

function DialogueSuppressor.IsProtectedUI(obj)
    local current = obj

    for _ = 1, 10 do
        if not current then
            break
        end

        local name = string.lower(tostring(current.Name or ""))

        if string.find(name, "kratos", 1, true) then
            return true
        end

        if name == "quest"
            or string.find(name, "trackedquest", 1, true)
            or string.find(name, "questframe", 1, true)
            or string.find(name, "questcontainer", 1, true) then
            return true
        end

        current = current.Parent
    end

    return false
end

function DialogueSuppressor.IsActuallyVisible(gui)
    if not gui or not gui:IsA("GuiObject") or not gui.Parent then
        return false
    end

    local current = gui
    for _ = 1, 10 do
        if current:IsA("GuiObject") and current.Visible == false then
            return false
        end
        current = current.Parent
        if not current then
            break
        end
    end

    local size = gui.AbsoluteSize
    return size.X > 2 and size.Y > 2
end

function DialogueSuppressor.HasRealDialogueContainer(obj)
    local current = obj

    for _ = 1, 10 do
        if not current or current == DialogueSuppressor.PlayerGui then
            break
        end

        local lowerName = string.lower(tostring(current.Name or ""))

        if string.find(lowerName, "dialog", 1, true)
            or string.find(lowerName, "choice", 1, true)
            or string.find(lowerName, "speech", 1, true)
            or string.find(lowerName, "answer", 1, true)
            or string.find(lowerName, "talk", 1, true)
            or string.find(lowerName, "prompt", 1, true) then
            return true
        end

        local marked = false
        pcall(function()
            marked = current:GetAttribute("Dialogue") == true
                or current:GetAttribute("IsDialogue") == true
                or current:GetAttribute("NPCDialogue") == true
        end)

        if marked then
            return true
        end

        current = current.Parent
    end

    return false
end

function DialogueSuppressor.FindClickableAncestor(obj)
    local playerGui = DialogueSuppressor.PlayerGui
    local current = obj
    local fallback = nil

    for _ = 1, 8 do
        if not current or current == playerGui then
            break
        end

        if DialogueSuppressor.IsProtectedUI(current) then
            return nil
        end

        if current:IsA("TextButton") or current:IsA("ImageButton") then
            return current
        end

        if current:IsA("GuiObject") then
            local lowerName = string.lower(tostring(current.Name or ""))

            if string.find(lowerName, "dialog", 1, true)
                or string.find(lowerName, "choice", 1, true)
                or string.find(lowerName, "answer", 1, true)
                or string.find(lowerName, "prompt", 1, true)
                or string.find(lowerName, "speech", 1, true)
                or string.find(lowerName, "talk", 1, true) then
                fallback = current
            end
        end

        current = current.Parent
    end

    return fallback
end

function DialogueSuppressor.ClickGui(gui, force)
    if not DialogueSuppressor.Enabled or not gui or not gui.Parent then
        return false
    end

    if DialogueSuppressor.IsProtectedUI(gui) or not DialogueSuppressor.IsActuallyVisible(gui) then
        return false
    end

    local now = tick()
    local cooldown = tonumber(DialogueSuppressor.ClickCooldown) or 0.18
    if not force and (now - (DialogueSuppressor.LastClickAt or 0)) < cooldown then
        return false
    end

    if DialogueSuppressor.Pending[gui] then
        return false
    end
    DialogueSuppressor.Pending[gui] = true
    DialogueSuppressor.LastClickAt = now

    task.spawn(function()
        task.wait(0.03)
        if not DialogueSuppressor.Enabled or not gui or not gui.Parent then
            DialogueSuppressor.Pending[gui] = nil
            return
        end

        local pos = gui.AbsolutePosition
        local size = gui.AbsoluteSize
        local x = math.floor(pos.X + math.max(2, size.X * 0.5))
        local y = math.floor(pos.Y + math.max(2, size.Y * 0.5))

        pcall(function()
            VirtualInputManager:SendMouseMoveEvent(x, y, game)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.025)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)

        task.wait(0.08)
        DialogueSuppressor.Pending[gui] = nil
    end)

    return true
end

function DialogueSuppressor.LooksLikeNPCDialogue(obj)
    if not obj or DialogueSuppressor.IsProtectedUI(obj) then
        return false
    end

    if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
        return false
    end

    local normalized = NormalizeDialogueText(obj.Text)
    if normalized == "" then
        return false
    end

    -- Explicitly known blocking dialogue is always safe to advance.
    if DialogueSuppressor.IsBlockedText(normalized) then
        return true
    end

    -- Never infer dialogue just because a long sentence happens to be on screen.
    -- This prevents accidental clicks during Saber travel/combat.
    if Config.DialogueRequireRealContainer ~= false
        and not DialogueSuppressor.HasRealDialogueContainer(obj) then
        return false
    end

    -- A real dialogue container still needs sentence-like text.
    if #normalized < 10 then
        return false
    end

    return string.find(normalized, " ", 1, true) ~= nil
end


function DialogueSuppressor.IsEscapedPrisonerDialogue(value)
    local normalized = NormalizeDialogueText(value)

    return string.find(normalized, "escaped prisoner", 1, true) ~= nil
        or string.find(normalized, "you gonna help me get through", 1, true) ~= nil
        or string.find(normalized, "just gotta patch up these last planks", 1, true) ~= nil
        or string.find(normalized, "she'll float", 1, true) ~= nil
        or string.find(normalized, "grab a hammer", 1, true) ~= nil
        or string.find(normalized, "help me dig", 1, true) ~= nil
end

function DialogueSuppressor.ClickScreenNormalized(xScale, yScale)
    if not DialogueSuppressor.Enabled then
        return false
    end

    local now = tick()
    local cooldown = tonumber(DialogueSuppressor.PrisonerActionCooldown) or 0.16

    if now - (DialogueSuppressor.PrisonerLastActionAt or 0) < cooldown then
        return false
    end

    DialogueSuppressor.PrisonerLastActionAt = now

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local x = math.floor(viewport.X * (tonumber(xScale) or 0.50))
    local y = math.floor(viewport.Y * (tonumber(yScale) or 0.76))

    task.spawn(function()
        pcall(function()
            VirtualInputManager:SendMouseMoveEvent(x, y, game)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.025)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)
    end)

    return true
end

function DialogueSuppressor.ScanEscapedPrisoner()
    if not DialogueSuppressor.Enabled or not DialogueSuppressor.PlayerGui then
        return false
    end

    local prisonerDialogue = nil
    local dismissResponse = nil
    local confrontResponse = nil

    -- Cheap loop over cached text objects. No GetDescendants() on every farm tick.
    for obj in pairs(DialogueSuppressor.AllText) do
        if obj and obj.Parent
            and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox"))
            and not DialogueSuppressor.IsProtectedUI(obj)
            and DialogueSuppressor.IsActuallyVisible(obj) then

            local raw = tostring(obj.Text or "")

            if not dismissResponse and DialogueSuppressor.IsPrisonerDismissText(raw) then
                dismissResponse = obj
            elseif not confrontResponse and DialogueSuppressor.IsResponseText(raw) then
                confrontResponse = obj
            end

            if not prisonerDialogue
                and DialogueSuppressor.IsEscapedPrisonerDialogue(raw) then
                prisonerDialogue = obj
            end
        end
    end

    if prisonerDialogue then
        DialogueSuppressor.PrisonerActiveUntil = tick() + 3.5
        DialogueSuppressor.ActiveUntil = tick() + 3.5
    end

    local prisonerWindow = tick() <= (DialogueSuppressor.PrisonerActiveUntil or 0)

    -- If the game offers a real back-out option, prefer it so regular level
    -- farming ignores the Prison Island Secret completely.
    if prisonerWindow and Config.IgnoreEscapedPrisoners and dismissResponse then
        local target = DialogueSuppressor.FindClickableAncestor(dismissResponse) or dismissResponse

        if DialogueSuppressor.ClickGui(target, true) then
            DialogueSuppressor.PrisonerActiveUntil = tick() + 0.8
            return true
        end
    end

    -- Never deliberately start the Prison Island Secret while normal level
    -- farming is configured to ignore it. The response used by this dialogue
    -- can begin the escaped-prisoner confrontation, so leave it untouched.
    if prisonerWindow and confrontResponse and Config.IgnorePrisonSecretQuest ~= true then
        local target = DialogueSuppressor.FindClickableAncestor(confrontResponse) or confrontResponse

        if DialogueSuppressor.ClickGui(target, true) then
            DialogueSuppressor.PrisonerActiveUntil = tick() + 1.0
            return true
        end
    end

    -- First dialogue page sometimes needs one click before the response appears.
    if prisonerDialogue then
        local target = DialogueSuppressor.FindClickableAncestor(prisonerDialogue)

        if target and DialogueSuppressor.ClickGui(target, true) then
            return true
        end

        -- Last-resort targeted click: lower-middle of the dialogue panel.
        -- This only fires while "Escaped Prisoner" text is visibly on screen.
        return DialogueSuppressor.ClickScreenNormalized(0.50, 0.76)
    end

    return false
end

function DialogueSuppressor.ProcessTextObject(obj)
    if not DialogueSuppressor.Enabled or not obj or not obj.Parent then
        return false
    end

    if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
        return false
    end

    if DialogueSuppressor.IsProtectedUI(obj)
        or not DialogueSuppressor.IsActuallyVisible(obj) then
        return false
    end

    local rawText = tostring(obj.Text or "")
    local isResponse = DialogueSuppressor.IsResponseText(rawText)
    local isStoryResponse = DialogueSuppressor.IsStoryResponseText(rawText)
    local isKnownDialogue = DialogueSuppressor.IsBlockedText(rawText)
    local hasContainer = DialogueSuppressor.HasRealDialogueContainer(obj)

    if isStoryResponse then
        if not DialogueSuppressor.IsSaberStoryStep() then
            return false
        end
        -- Story buttons must belong to a real dialogue UI. This keeps
        -- "Conversar" from becoming a generic click-anywhere trigger.
        if not hasContainer then
            return false
        end
        isResponse = true
    end

    if isResponse then
        local inDialogueWindow = tick() <= (DialogueSuppressor.ActiveUntil or 0)
        if not inDialogueWindow and not hasContainer then
            return false
        end
    elseif not DialogueSuppressor.LooksLikeNPCDialogue(obj) then
        return false
    end

    local target = DialogueSuppressor.FindClickableAncestor(obj)

    -- For a known full-screen NPC sentence, clicking the text itself is valid.
    if not target and isKnownDialogue then
        target = obj
    end

    if not target then
        return false
    end

    if not isResponse then
        DialogueSuppressor.ActiveUntil = tick() + (tonumber(DialogueSuppressor.DialogueWindow) or 2.5)
    end

    return DialogueSuppressor.ClickGui(target, isResponse)
end

function DialogueSuppressor.ScanVisible(force)
    if not DialogueSuppressor.Enabled or not DialogueSuppressor.PlayerGui then
        return
    end

    local now = tick()
    local interval = tonumber(DialogueSuppressor.ScanInterval) or 0.60
    if not force and (now - (DialogueSuppressor.LastScanAt or 0)) < interval then
        return
    end
    DialogueSuppressor.LastScanAt = now

    local responseCandidate = nil
    local dialogueCandidate = nil

    -- Only scan the small set of objects that are actually dialogue candidates.
    -- The old version rebuilt PlayerGui:GetDescendants() every 0.10s.
    for obj in pairs(DialogueSuppressor.ObservedText) do
        if obj and obj.Parent
            and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox"))
            and not DialogueSuppressor.IsProtectedUI(obj)
            and DialogueSuppressor.IsActuallyVisible(obj) then

            if DialogueSuppressor.IsResponseText(obj.Text)
                or (DialogueSuppressor.IsSaberStoryStep()
                    and DialogueSuppressor.IsStoryResponseText(obj.Text)) then
                responseCandidate = obj
                break
            elseif not dialogueCandidate and DialogueSuppressor.LooksLikeNPCDialogue(obj) then
                dialogueCandidate = obj
            end
        end
    end

    if responseCandidate then
        DialogueSuppressor.ProcessTextObject(responseCandidate)
    elseif dialogueCandidate then
        DialogueSuppressor.ProcessTextObject(dialogueCandidate)
    end
end

function DialogueSuppressor.ObserveTextObject(obj)
    if not obj then
        return
    end

    if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
        return
    end

    -- Keep a weak cache of all text objects so dialogues whose Text is filled
    -- after GUI creation (notably Escaped Prisoner) are still detected cheaply.
    DialogueSuppressor.AllText[obj] = true

    if DialogueSuppressor.ObservedText[obj] then
        return
    end

    -- Observe only known dialogue text or text living inside a real dialogue UI.
    -- This avoids thousands of event connections on HUD/stat/menu labels.
    local isCandidate = DialogueSuppressor.HasRealDialogueContainer(obj)
        or DialogueSuppressor.IsBlockedText(obj.Text)
        or DialogueSuppressor.IsResponseText(obj.Text)
        or DialogueSuppressor.IsStoryResponseText(obj.Text)

    if not isCandidate then
        return
    end

    DialogueSuppressor.ObservedText[obj] = true

    local textConnection = obj:GetPropertyChangedSignal("Text"):Connect(function()
        task.defer(function()
            DialogueSuppressor.ProcessTextObject(obj)
        end)
    end)
    table.insert(DialogueSuppressor.Connections, textConnection)

    local visibleConnection = obj:GetPropertyChangedSignal("Visible"):Connect(function()
        if obj.Visible then
            task.defer(function()
                DialogueSuppressor.ProcessTextObject(obj)
            end)
        end
    end)
    table.insert(DialogueSuppressor.Connections, visibleConnection)

    task.defer(function()
        DialogueSuppressor.ProcessTextObject(obj)
    end)
end

function DialogueSuppressor.Enable()
    if DialogueSuppressor.Enabled then
        return
    end

    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        or LocalPlayer:WaitForChild("PlayerGui", 10)
    if not playerGui then
        return
    end

    DialogueSuppressor.Enabled = true
    DialogueSuppressor.PlayerGui = playerGui
    DialogueSuppressor.LastClickAt = 0
    DialogueSuppressor.LastScanAt = 0
    DialogueSuppressor.ActiveUntil = 0
    DialogueSuppressor.PrisonerActiveUntil = 0
    DialogueSuppressor.PrisonerLastActionAt = 0

    for _, obj in ipairs(playerGui:GetDescendants()) do
        DialogueSuppressor.ObserveTextObject(obj)
    end

    table.insert(DialogueSuppressor.Connections, playerGui.DescendantAdded:Connect(function(obj)
        task.defer(function()
            if DialogueSuppressor.Enabled then
                DialogueSuppressor.ObserveTextObject(obj)
            end
        end)
    end))

    DialogueSuppressor.ScanVisible(true)
end

function DialogueSuppressor.Disable()
    if not DialogueSuppressor.Enabled then
        return
    end

    DialogueSuppressor.Enabled = false

    for _, connection in ipairs(DialogueSuppressor.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(DialogueSuppressor.Connections)

    DialogueSuppressor.ObservedText = setmetatable({}, {__mode = "k"})
    DialogueSuppressor.AllText = setmetatable({}, {__mode = "k"})
    DialogueSuppressor.Pending = setmetatable({}, {__mode = "k"})
    DialogueSuppressor.ActiveUntil = 0
    DialogueSuppressor.PrisonerActiveUntil = 0
    DialogueSuppressor.PrisonerLastActionAt = 0
    DialogueSuppressor.PlayerGui = nil
end

function DialogueSuppressor.Sync()
    if Config.HideNPCDialogues then
        if not DialogueSuppressor.Enabled then
            DialogueSuppressor.Enable()
        end

        -- Prison dialogue is special: first advance the NPC sentence, then
        -- immediately choose "Not this time!" so combat is unblocked.
        DialogueSuppressor.ScanEscapedPrisoner()
        DialogueSuppressor.ScanVisible(false)
    elseif DialogueSuppressor.Enabled then
        DialogueSuppressor.Disable()
    end
end

--=====================================================================================
-- [UI CLEANUP] BLOX FRUITS GAME NOTIFICATIONS
-- Hides the game's toast/notification layer (money, rewards, obtained items, etc.)
-- while preserving the quest tracker and all Kratos UI.
--=====================================================================================

GameNotificationSuppressor.Enabled = false
GameNotificationSuppressor.PlayerGui = nil
GameNotificationSuppressor.Connections = {}
GameNotificationSuppressor.HiddenState = setmetatable({}, {__mode = "k"})

local function NotificationNameLooksLikeContainer(name)
    local n = string.lower(tostring(name or ""))
    return n == "notifications"
        or n == "notification"
        or n == "notify"
        or n == "alerts"
        or n == "alert"
        or n:find("notification", 1, true) ~= nil
end

function GameNotificationSuppressor.HideContainer(obj)
    if not obj then
        return false
    end

    local current = obj
    local depth = 0
    while current and current ~= GameNotificationSuppressor.PlayerGui and depth < 8 do
        if NotificationNameLooksLikeContainer(current.Name) then
            pcall(function()
                if current:IsA("ScreenGui") then
                    if GameNotificationSuppressor.HiddenState[current] == nil then
                        GameNotificationSuppressor.HiddenState[current] = {Kind = "Enabled", Value = current.Enabled}
                    end
                    current.Enabled = false
                elseif current:IsA("GuiObject") then
                    if GameNotificationSuppressor.HiddenState[current] == nil then
                        GameNotificationSuppressor.HiddenState[current] = {Kind = "Visible", Value = current.Visible}
                    end
                    current.Visible = false
                end
            end)
            return true
        end
        current = current.Parent
        depth = depth + 1
    end

    return false
end

function GameNotificationSuppressor.Scan()
    if not GameNotificationSuppressor.Enabled or not GameNotificationSuppressor.PlayerGui then
        return
    end

    local scanned = 0
    for _, obj in ipairs(GameNotificationSuppressor.PlayerGui:GetDescendants()) do
        scanned = scanned + 1
        if scanned > 1600 then
            break
        end
        if NotificationNameLooksLikeContainer(obj.Name) then
            GameNotificationSuppressor.HideContainer(obj)
        end
    end
end

function GameNotificationSuppressor.Disable()
    GameNotificationSuppressor.Enabled = false
    for _, connection in ipairs(GameNotificationSuppressor.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    GameNotificationSuppressor.Connections = {}

    for obj, state in pairs(GameNotificationSuppressor.HiddenState) do
        if obj and obj.Parent and state then
            pcall(function()
                if state.Kind == "Enabled" and obj:IsA("ScreenGui") then
                    obj.Enabled = state.Value
                elseif state.Kind == "Visible" and obj:IsA("GuiObject") then
                    obj.Visible = state.Value
                end
            end)
        end
    end
    GameNotificationSuppressor.HiddenState = setmetatable({}, {__mode = "k"})
    GameNotificationSuppressor.PlayerGui = nil
end

function GameNotificationSuppressor.Sync()
    if Config.HideBloxNotifications ~= true then
        if GameNotificationSuppressor.Enabled then
            GameNotificationSuppressor.Disable()
        end
        return
    end

    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        or LocalPlayer:WaitForChild("PlayerGui", 10)
    if not playerGui then
        return
    end

    if GameNotificationSuppressor.Enabled and GameNotificationSuppressor.PlayerGui == playerGui then
        GameNotificationSuppressor.Scan()
        return
    end

    GameNotificationSuppressor.Disable()
    GameNotificationSuppressor.Enabled = true
    GameNotificationSuppressor.PlayerGui = playerGui

    table.insert(GameNotificationSuppressor.Connections, playerGui.DescendantAdded:Connect(function(obj)
        if not GameNotificationSuppressor.Enabled then
            return
        end
        task.defer(function()
            if obj and obj.Parent then
                GameNotificationSuppressor.HideContainer(obj)
            end
        end)
    end))

    GameNotificationSuppressor.Scan()
end

--=====================================================================================
--=====================================================================================
-- Updated Initialization
--=====================================================================================

function Initialize()
    Logger.info("Initializing Kratos Ultimate Hub v2.0 V29...")

    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    -- Setup team FIRST
    task.wait(0.5)
    SetupTeam()

    -- Wait for the current character (do not wait forever for a future respawn).
    local currentCharacter = LocalPlayer.Character
    if not currentCharacter or not currentCharacter.Parent then
        currentCharacter = LocalPlayer.CharacterAdded:Wait()
    end
    pcall(function()
        currentCharacter:WaitForChild("HumanoidRootPart", 10)
        currentCharacter:WaitForChild("Humanoid", 10)
    end)
    task.wait(1)

    -- A previous Kratos build may have been stopped while a hover/body mover
    -- was still attached. Clean those leftovers before the new farm starts.
    Utils.RestoreLocalMovement()

    -- Initialize systems
    Attack.Init()
    FruitSystem.Init()
    FruitESPSystem.Init()
    QuestSystem.LastUpdate = 0
    QuestSystem.Update()
    UI.Build()

    -- Utility systems configured by Settings Loader V14+.
    OptimizeFixLagSystem.Sync()
    AutoChatSystem.Start()

    CodeSystem.Init()
    AbilitySystem.Init()

    -- Hide intrusive NPC dialogue/choice boxes locally when requested.
    FarmEngine.SafeCall("DialogueSuppressorInit", DialogueSuppressor.Sync)
    FarmEngine.SafeCall("GameNotificationSuppressorInit", GameNotificationSuppressor.Sync)

    -- FPS Boost follows Config.FPSBoost independently of AutoFarm.
    FarmEngine.SafeCall("FPSBoostInit", FPSBoostSystem.Sync)

    SkillSystem.MonitorSkills()
    
    -- Initialize Speed Hub X systems
    InitializeEnemySpawns()

    -- Verify team again
    if Config.ForceTeamSet and Config.AutoTeam then
        task.wait(0.3)
        local currentTeam = tostring(LocalPlayer.Team)
        if currentTeam ~= Config.Team then
            Logger.warn("Team mismatch, retrying...")
            SetupTeam()
        end
    end

    -- Start farming
    if Config.AutoFarm then
        FarmEngine.Start()
    end

    Logger.info("Kratos Ultimate Hub v2.0 V29 initialized!")
    Logger.info("Team:", tostring(LocalPlayer.Team))
    Logger.info("Systems: Quest, Combat, Melee, Saber, Abilities/Ken, Stats, FPS Boost, Auto Chat, Farm Fragments, Optimize Fix Lag, Fruit ESP, Promo Codes, Raid Boss Priority, EnemySpawns")
    UI.SetStatus(Config.AutoFarm and "Farm loop active | checking quest" or "Ready - Ultimate Hub Active")
end

-- Initialize basic quest system
local FirstSeaQuests = QuestData.ToLegacyFormat()
table.sort(FirstSeaQuests, function(a, b)
    return (tonumber(a.Min) or 0) < (tonumber(b.Min) or 0)
end)
for i, quest in ipairs(FirstSeaQuests) do
    local nextQuest = FirstSeaQuests[i + 1]
    quest.Max = nextQuest and ((tonumber(nextQuest.Min) or quest.Min) - 1) or (tonumber(quest.Max) or (tonumber(quest.Min) or 0) + 50)
end

local GENERIC_GIVER_PART_NAMES = {
    ["humanoidrootpart"] = true,
    ["head"] = true,
    ["torso"] = true,
    ["uppertorso"] = true,
    ["lowertorso"] = true,
    ["rootpart"] = true,
    ["primarypart"] = true,
    ["part"] = true,
    ["meshpart"] = true,
}

local function IsGenericGiverName(name)
    local normalized = string.lower(tostring(name or ""))
    normalized = normalized:gsub("%s+", "")
    return normalized == "" or GENERIC_GIVER_PART_NAMES[normalized] == true
end

local function GetLegacyGiverNameForMob(mobName, level)
    local wanted = Utils.Normalize(mobName)
    local best = nil
    local currentSea = MeleeSystem.GetSea()

    for _, legacyQuest in ipairs(FirstSeaQuests) do
        local legacyMob = Utils.Normalize(legacyQuest.Mob)
        local minLevel = tonumber(legacyQuest.Min) or 0
        local questSea = tonumber(legacyQuest.Sea) or 1

        if questSea == currentSea and legacyMob == wanted and level >= minLevel then
            if not best or minLevel > (tonumber(best.Min) or 0) then
                best = legacyQuest
            end
        end
    end

    if best and best.Giver and best.Giver[1] then
        return tostring(best.Giver[1])
    end

    return nil
end


local function GetLegacyQuestForMob(mobName, level)
    local wanted = Utils.Normalize(mobName)
    local best = nil
    local currentSea = MeleeSystem.GetSea()

    for _, legacyQuest in ipairs(FirstSeaQuests) do
        local legacyMob = Utils.Normalize(legacyQuest.Mob)
        local minLevel = tonumber(legacyQuest.Min) or 0
        local questSea = tonumber(legacyQuest.Sea) or 1

        if questSea == currentSea
            and legacyMob == wanted
            and (not level or level >= minLevel) then

            if not best or minLevel > (tonumber(best.Min) or 0) then
                best = legacyQuest
            end
        end
    end

    return best
end

local function GetLegacyBossQuestForMob(mobName, level)
    local wanted = Utils.Normalize(mobName)
    local currentSea = MeleeSystem.GetSea()
    local best = nil

    for _, legacyQuest in ipairs(FirstSeaQuests) do
        local minLevel = tonumber(legacyQuest.Min) or 0
        local questSea = tonumber(legacyQuest.Sea) or 1

        if legacyQuest.Boss
            and questSea == currentSea
            and (not level or level >= minLevel) then

            local matches = Utils.Normalize(legacyQuest.Mob) == wanted

            if not matches and type(legacyQuest.BossNames) == "table" then
                for _, alias in ipairs(legacyQuest.BossNames) do
                    if Utils.Normalize(alias) == wanted then
                        matches = true
                        break
                    end
                end
            end

            if matches and (not best or minLevel > (tonumber(best.Min) or 0)) then
                best = legacyQuest
            end
        end
    end

    return best
end

local function AttachLegacyBossMetadata(quest, level)
    if not quest or not quest.Mob then
        return quest
    end

    local legacy = GetLegacyQuestForMob(quest.Mob, level)

    -- Dynamic GuideModule names do not always match the static quest target.
    -- Resolve against the boss alias list as well (Magma Admiral/Magma General,
    -- and any future alias preserved by QuestData.ToLegacyFormat).
    if not (legacy and legacy.Boss) then
        legacy = GetLegacyBossQuestForMob(quest.Mob, level)
    end

    if legacy and legacy.Boss then
        quest.Boss = true
        quest.Fallbacks = quest.Fallbacks or legacy.Fallbacks
        quest.SideBoss = quest.SideBoss or legacy.SideBoss
        quest.BossNames = quest.BossNames or legacy.BossNames
        quest.CanonicalBossMob = quest.CanonicalBossMob or legacy.Mob
    end

    return quest
end

function QuestSystem.GetFallbackNonBossQuest(level, bossQuest)
    level = tonumber(level) or tonumber(Utils.Level()) or 1

    -- Prefer the boss's explicit local fallback list. This keeps the player
    -- on the same island; Yeti -> Snowman, Chef -> local Pirate/Brute, etc.
    if bossQuest and type(bossQuest.Fallbacks) == "table" then
        for _, fallbackName in ipairs(bossQuest.Fallbacks) do
            local fallback = GetLegacyQuestForMob(fallbackName, level)

            if fallback and not fallback.Boss then
                return fallback
            end
        end
    end

    -- Generic fallback for every island/level: highest normal quest the
    -- player's level can legitimately farm.
    local best = nil

    local currentSea = MeleeSystem.GetSea()

    for _, quest in ipairs(FirstSeaQuests) do
        local minLevel = tonumber(quest.Min) or 0
        local questSea = tonumber(quest.Sea) or 1

        if questSea == currentSea and level >= minLevel and not quest.Boss then
            if not best or minLevel > (tonumber(best.Min) or 0) then
                best = quest
            end
        end
    end

    return best
end

function QuestSystem.ResolveBossFarmQuest(candidate)
    if not candidate then
        QuestSystem.PendingBossName = nil
        QuestSystem.PendingBossTimer = nil
        QuestSystem.PendingBossSeconds = nil
        QuestSystem.PendingBossQuest = nil
        QuestSystem.BossFallbackActive = false
        return nil
    end

    local level = tonumber(Utils.Level()) or 1
    candidate = AttachLegacyBossMetadata(candidate, level)

    if not candidate.Boss then
        QuestSystem.PendingBossName = nil
        QuestSystem.PendingBossTimer = nil
        QuestSystem.PendingBossSeconds = nil
        QuestSystem.PendingBossQuest = nil
        QuestSystem.BossFallbackActive = false
        return candidate
    end

    local bossName = tostring(candidate.Mob or "")
    local spawned = false

    if BossSystem and type(BossSystem.IsBossSpawned) == "function" then
        local ok, value = pcall(function()
            local isSpawned = BossSystem.IsBossSpawned(bossName)
            return isSpawned
        end)

        if ok then
            spawned = value == true
        end
    end

    local timer, seconds = UI.FindBossTimerForName(bossName, false)
    local respawning = Config.BossAvoidQuestWhileRespawning ~= false
        and tonumber(seconds) ~= nil
        and tonumber(seconds) > 0

    QuestSystem.PendingBossName = bossName
    QuestSystem.PendingBossTimer = timer
    QuestSystem.PendingBossSeconds = seconds
    QuestSystem.PendingBossQuest = candidate

    -- A visible respawn timer is authoritative: never accept/re-accept the
    -- boss mission while the boss is counting down. This also protects against
    -- a dead/stale model lingering for a few frames after the kill.
    if respawning then
        spawned = false
    end

    -- Never wait/patrol an empty spawn. When the boss really exists, switch to
    -- the boss quest; otherwise keep leveling normally.
    if spawned or not Config.BossFallbackToNormalFarm then
        QuestSystem.BossFallbackActive = false
        return candidate
    end

    local fallback = QuestSystem.GetFallbackNonBossQuest(level, candidate)

    if fallback then
        QuestSystem.BossFallbackActive = true
        QuestSystem.FallbackMode = true
        QuestSystem.FallbackMob = fallback.Mob
        return fallback
    end

    -- No normal quest was found. Do not force patrol movement; keep candidate
    -- only as a last-resort quest definition.
    QuestSystem.BossFallbackActive = false
    return candidate
end

local function ResolveDynamicGiverName(instance, mobName, level)
    -- GuideModule may use HumanoidRootPart as the NPCList key.
    -- Walk upward until we reach a meaningful NPC/model name.
    local current = instance
    for _ = 1, 6 do
        if not current then
            break
        end

        local name = nil
        pcall(function()
            name = current.Name
        end)

        if name
            and not IsGenericGiverName(name)
            and name ~= "NPCs"
            and name ~= "Workspace"
            and name ~= "workspace" then
            return tostring(name)
        end

        current = current.Parent
    end

    -- Reliable fallback from the Kaitun's own level quest data.
    local legacyName = GetLegacyGiverNameForMob(mobName, level)
    if legacyName and not IsGenericGiverName(legacyName) then
        return legacyName
    end

    return "Quest Giver"
end

QuestSystem.Current = nil
QuestSystem.LastUpdate = 0
QuestSystem.LastQuestAction = 0
QuestSystem.LastMove = 0
QuestSystem.Active = false
QuestSystem.LocalKills = 0
QuestSystem.FallbackMode = false
QuestSystem.FallbackMob = nil

QuestSystem.PendingBossName = nil
QuestSystem.PendingBossTimer = nil
QuestSystem.PendingBossSeconds = nil
QuestSystem.PendingBossQuest = nil
QuestSystem.BossFallbackActive = false

QuestSystem.DynamicGuide = nil
QuestSystem.DynamicQuests = nil
QuestSystem.DynamicQuestCache = nil
QuestSystem.DynamicQuestCacheAt = 0
QuestSystem.DynamicQuestCacheLevel = nil
QuestSystem.DynamicModuleRetryAt = 0
QuestSystem.AcceptedGraceUntil = 0
QuestSystem.LastAcceptedQuestKey = nil

-- Speed Hub X style fast quest state.
QuestSystem.FastQuestAttempts = 0
QuestSystem.FastQuestLastAttempt = 0
QuestSystem.FastQuestFallbackUntil = 0
QuestSystem.FastQuestLastKey = nil
QuestSystem.SpawnCycleIndex = QuestSystem.SpawnCycleIndex or 1
QuestSystem.LastSpawnCycleAt = 0
QuestSystem.GiverApproachCache = {}

local function GetPivotCFrame(instance)
    return GetInstanceCFrameSafe(instance)
end

local RuntimeRequire = require

function QuestSystem.LoadDynamicQuestModules()
    if QuestSystem.DynamicGuide and QuestSystem.DynamicQuests then
        return true
    end

    local now = tick()
    if now < (QuestSystem.DynamicModuleRetryAt or 0) then
        return false
    end

    local okGuide, guide = pcall(function()
        local module = ReplicatedStorage:FindFirstChild("GuideModule")
        if not module then
            return nil
        end
        return RuntimeRequire(module)
    end)

    local okQuests, quests = pcall(function()
        local module = ReplicatedStorage:FindFirstChild("Quests")
        if not module then
            return nil
        end
        return RuntimeRequire(module)
    end)

    if okGuide and type(guide) == "table" then
        QuestSystem.DynamicGuide = guide
    end
    if okQuests and type(quests) == "table" then
        QuestSystem.DynamicQuests = quests
    end

    local loaded = QuestSystem.DynamicGuide ~= nil and QuestSystem.DynamicQuests ~= nil
    if not loaded then
        QuestSystem.DynamicModuleRetryAt = now + 10
    end
    return loaded
end

function QuestSystem.GetDynamicCurrent()
    local level = tonumber(Utils.Level()) or 1
    local now = tick()

    if QuestSystem.DynamicQuestCache
        and QuestSystem.DynamicQuestCacheLevel == level
        and (now - (QuestSystem.DynamicQuestCacheAt or 0)) < 1.0 then
        return QuestSystem.DynamicQuestCache
    end

    if not QuestSystem.LoadDynamicQuestModules() then
        return nil
    end

    local npcList = QuestSystem.DynamicGuide.Data
        and QuestSystem.DynamicGuide.Data.NPCList

    if type(npcList) ~= "table" then
        return nil
    end

    local selectedLevel = 0
    local selectedIndex = 1
    local selectedGiver = nil
    local selectedGiverCFrame = nil

    -- Same selection model used by the supplied working base:
    -- choose the highest GuideModule level that does not exceed the player level.
    for npc, npcData in pairs(npcList) do
        local levels = type(npcData) == "table" and npcData.Levels
        if type(levels) == "table" then
            for i = 1, #levels do
                local requirement = tonumber(levels[i])
                if requirement and level >= requirement and requirement > selectedLevel then
                    selectedLevel = requirement
                    selectedIndex = (#levels == 3 and i == 3) and 2 or i
                    selectedGiver = npc

                    -- GuideModule can index NPCList by a BasePart such as
                    -- HumanoidRootPart. Prefer the parent model for position/name.
                    local giverObject = npc
                    pcall(function()
                        if npc:IsA("BasePart") and npc.Parent then
                            giverObject = npc.Parent
                        end
                    end)

                    selectedGiverCFrame = GetPivotCFrame(giverObject) or GetPivotCFrame(npc)
                end
            end
        end
    end

    if selectedLevel <= 0 then
        return nil
    end

    local selectedQuestName = nil
    local selectedQuestNum = selectedIndex
    local selectedMob = nil
    local selectedAmount = 1

    for questName, questList in pairs(QuestSystem.DynamicQuests) do
        if questName ~= "CitizenQuest" and type(questList) == "table" then
            for questNum, questData in pairs(questList) do
                if type(questData) == "table" and tonumber(questData.LevelReq) == selectedLevel then
                    selectedQuestName = questName
                    selectedQuestNum = tonumber(questNum) or selectedQuestNum

                    if type(questData.Task) == "table" then
                        for taskName, amount in pairs(questData.Task) do
                            selectedMob = tostring(taskName)
                            selectedAmount = tonumber(amount) or 1
                            break
                        end
                    end

                    if selectedMob then
                        break
                    end
                end
            end
        end

        if selectedQuestName and selectedMob then
            break
        end
    end

    if not selectedQuestName or not selectedMob then
        return nil
    end

    local mob = selectedMob:gsub("%s*%[Lv%.%s*[%d,]+%].*$", "")
    mob = mob:gsub("%s+$", "")

    local giverName = ResolveDynamicGiverName(selectedGiver, mob, level)

    -- Never expose internal Roblox part names in the UI/status.
    if IsGenericGiverName(giverName) then
        giverName = GetLegacyGiverNameForMob(mob, level) or "Quest Giver"
    end

    local result = {
        Min = selectedLevel,
        Max = selectedLevel + 49,
        Quest = selectedQuestName,
        Num = selectedQuestNum,
        Mob = mob,
        Required = selectedAmount,
        Giver = { giverName },
        GiverCFrame = selectedGiverCFrame,
        FarmCFrame = nil,
    }

    -- Dynamic quest tasks often use the real boss name without the word
    -- "boss" (Yeti, Warden, Vice Admiral...). Attach metadata from the
    -- Kaitun's quest database so boss fallback works on every supported island.
    result = AttachLegacyBossMetadata(result, level)

    if string.find(string.lower(mob), "boss", 1, true) then
        result.Boss = true
    end

    QuestSystem.DynamicQuestCache = result
    QuestSystem.DynamicQuestCacheAt = now
    QuestSystem.DynamicQuestCacheLevel = level
    return result
end

function QuestSystem.GetGiverDisplayName(quest)
    if not quest then
        return "Quest Giver"
    end

    local name = quest.Giver and quest.Giver[1] or nil

    if name and not IsGenericGiverName(name) then
        return tostring(name)
    end

    local fallback = GetLegacyGiverNameForMob(quest.Mob, tonumber(Utils.Level()) or 1)
    if fallback and not IsGenericGiverName(fallback) then
        return fallback
    end

    return "Quest Giver"
end

function QuestSystem.GetPrePrisonFallback(level, currentSea)
    if Config.IgnorePrisonSecretQuest ~= true then
        return nil
    end

    if tonumber(currentSea) ~= 1 then
        return nil
    end

    local entryLevel = tonumber(Config.PrisonEntryLevel) or 190
    local fallbackMin = tonumber(Config.PrePrisonFallbackMinLevel) or 175

    if level < fallbackMin or level >= entryLevel then
        return nil
    end

    local wantedMob = Utils.Normalize(Config.PrePrisonFallbackMob or "Dark Master")
    local selected = nil

    for _, quest in ipairs(FirstSeaQuests) do
        local questSea = tonumber(quest.Sea) or 1
        local minLevel = tonumber(quest.Min) or 0

        if questSea == 1
            and minLevel <= level
            and Utils.Normalize(quest.Mob) == wantedMob then
            selected = quest
            break
        end
    end

    return selected
end

function QuestSystem.IsPrematurePrisonQuest(quest, level, currentSea)
    if Config.IgnorePrisonSecretQuest ~= true or not quest then
        return false
    end

    if tonumber(currentSea) ~= 1 then
        return false
    end

    if level >= (tonumber(Config.PrisonEntryLevel) or 190) then
        return false
    end

    local giver = Utils.Normalize(quest.Giver and quest.Giver[1])
    local mob = Utils.Normalize(quest.Mob)

    return giver == "jail keeper"
        or giver == "head jailer"
        or mob == "prisoner"
        or mob == "dangerous prisoner"
        or mob == "ruthless prisoner"
        or mob == "warden"
end

function QuestSystem.GetCurrent()
    local level = tonumber(Utils.Level()) or 1
    local currentSea = MeleeSystem.GetSea()

    -- Hard progression gate for Update 30: from Lv.175 through Lv.189,
    -- remain on Dark Master instead of ever approaching Prison. This avoids
    -- the Jail Keeper/Prison Island Secret dialogue before PrisonerQuest unlocks.
    local prePrison = QuestSystem.GetPrePrisonFallback(level, currentSea)
    if prePrison then
        return QuestSystem.ResolveBossFarmQuest(prePrison)
    end

    local dynamic = QuestSystem.GetDynamicCurrent()

    if dynamic and not QuestSystem.IsPrematurePrisonQuest(dynamic, level, currentSea) then
        return QuestSystem.ResolveBossFarmQuest(dynamic)
    end

    local selected = nil

    for _, quest in ipairs(FirstSeaQuests) do
        local minLevel = tonumber(quest.Min) or 0
        local questSea = tonumber(quest.Sea) or 1

        if questSea == currentSea and level >= minLevel then
            if not selected or minLevel > (tonumber(selected.Min) or 0) then
                selected = quest
            end
        end
    end

    return QuestSystem.ResolveBossFarmQuest(selected)
end

IsGuiActuallyVisible = function(gui)
    if not gui or not gui:IsA("GuiObject") then
        return false
    end

    local current = gui
    while current and current ~= LocalPlayer:FindFirstChildOfClass("PlayerGui") do
        if current:IsA("GuiObject") and current.Visible == false then
            return false
        end
        current = current.Parent
    end

    return true
end

local function QuestGuiMatchesCurrent(root)
    local quest = QuestSystem.Current
    if not quest or not root then
        return false
    end

    local names = {}
    local seenNames = {}

    local function addName(value)
        local normalized = Utils.Normalize(value):gsub("[^%w]", "")
        if normalized ~= "" and not seenNames[normalized] then
            seenNames[normalized] = true
            table.insert(names, normalized)
        end
    end

    addName(quest.Mob)
    addName(quest.CanonicalBossMob)

    if type(quest.BossNames) == "table" then
        for _, alias in ipairs(quest.BossNames) do
            addName(alias)
        end
    end

    local required = tonumber(quest.Required) or 0
    local amountMatched = false
    local scanned = 0

    for _, obj in ipairs(root:GetDescendants()) do
        scanned = scanned + 1
        if scanned > 650 then
            break
        end

        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and IsGuiActuallyVisible(obj) then
            local raw = tostring(obj.Text or "")
            local txt = string.lower(raw)
            local normalizedText = Utils.Normalize(txt):gsub("[^%w]", "")

            -- Name match is useful when the client UI is in English.
            for _, normalizedName in ipairs(names) do
                if normalizedName ~= "" and string.find(normalizedText, normalizedName, 1, true) then
                    return true
                end
            end

            -- The objective amount is language-independent. This is especially
            -- important on localized clients: e.g. Military Spy is 0/8 while
            -- Magma Admiral is 0/1, even though both names are translated.
            local a, b = raw:match("(%d+)%s*/%s*(%d+)")
            a, b = tonumber(a), tonumber(b)
            if required > 0 and a and b and b == required and a >= 0 and a <= b then
                amountMatched = true
            end
        end
    end

    return amountMatched
end

function QuestSystem.HasAnyActiveQuest(force)
    local now = tick()
    local interval = tonumber(Config.QuestGuiCheckInterval) or 0.24

    if not force
        and (now - (QuestSystem.AnyQuestCheckAt or 0)) < interval then
        return QuestSystem.AnyQuestCache == true
    end

    QuestSystem.AnyQuestCheckAt = now

    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        QuestSystem.AnyQuestCache = false
        return false
    end

    local active = false
    local tracked = playerGui:FindFirstChild("TrackedQuestFrame", true)
    if tracked then
        if tracked:IsA("GuiObject") and IsGuiActuallyVisible(tracked) then
            active = true
        else
            local frame = tracked:FindFirstChild("Frame", true)
            if frame and frame:IsA("GuiObject") and IsGuiActuallyVisible(frame) then
                active = true
            end
        end
    end

    if not active then
        local main = playerGui:FindFirstChild("Main", true)
        local questGui = main and main:FindFirstChild("Quest", true)
        if questGui and questGui:IsA("GuiObject") and IsGuiActuallyVisible(questGui) then
            active = true
        end
    end

    -- Last-resort objective scan is throttled. Previously this could walk up to
    -- 900 PlayerGui descendants every 0.08s and was one of the main camera hitch
    -- sources while Auto Farm Level was enabled.
    if not active then
        local scanned = 0
        for _, obj in ipairs(playerGui:GetDescendants()) do
            scanned = scanned + 1
            if scanned > 650 then
                break
            end

            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and IsGuiActuallyVisible(obj) then
                if tostring(obj.Text or ""):match("%d+%s*/%s*%d+") then
                    active = true
                    break
                end
            end
        end
    end

    QuestSystem.AnyQuestCache = active
    return active
end

function QuestSystem.HasActiveQuest(force)
    local now = tick()
    local interval = tonumber(Config.QuestGuiCheckInterval) or 0.24
    if not force and (now - (QuestSystem.ActiveQuestCheckAt or 0)) < interval then
        return QuestSystem.ActiveQuestCache == true
    end

    QuestSystem.ActiveQuestCheckAt = now

    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local active = false

    if playerGui then
        -- Speed Hub path, but recursively because newer UI builds can nest it.
        local tracked = playerGui:FindFirstChild("TrackedQuestFrame", true)
        if tracked then
            if tracked:IsA("GuiObject") and IsGuiActuallyVisible(tracked) then
                active = QuestGuiMatchesCurrent(tracked)
            else
                local frame = tracked:FindFirstChild("Frame", true)
                if frame and frame:IsA("GuiObject") and IsGuiActuallyVisible(frame) then
                    active = QuestGuiMatchesCurrent(frame)
                end
            end
        end

        -- New/alternate Blox Fruits UI layouts.
        if not active then
            local main = playerGui:FindFirstChild("Main", true)
            local questGui = main and main:FindFirstChild("Quest", true)
            if questGui and questGui:IsA("GuiObject") and IsGuiActuallyVisible(questGui) then
                active = QuestGuiMatchesCurrent(questGui)
            end
        end

        -- Final UI fallback: visible quest text/objective anywhere in PlayerGui.
        if not active then
            active = QuestGuiMatchesCurrent(playerGui)
        end
    end

    QuestSystem.ActiveQuestCache = active
    QuestSystem.Active = active
    return active
end

function QuestSystem.HasFarmQuest()
    if QuestSystem.HasActiveQuest() then
        return true
    end

    local now = tick()
    local quest = QuestSystem.Current
    local key = quest and (tostring(quest.Quest) .. ":" .. tostring(quest.Num)) or nil

    if key
        and QuestSystem.LastAcceptedQuestKey == key
        and now < (QuestSystem.AcceptedGraceUntil or 0) then
        return true
    end

    return false
end

function QuestSystem.Update(force)
    local now = tick()
    if not force and (now - (QuestSystem.LastUpdate or 0)) < (tonumber(Config.QuestRefresh) or 0.6) then
        return QuestSystem.Current
    end

    QuestSystem.LastUpdate = now
    local previous = QuestSystem.Current
    local current = QuestSystem.GetCurrent()

    if previous and current and previous.Quest == current.Quest and previous.Num == current.Num then
        return previous
    end

    -- Boss appeared/disappeared or the level changed. The old mission must be
    -- fully cleared before the new target is allowed to attack. A single
    -- AbandonQuest call is not enough because the tracker can replicate late.
    if previous and current then
        if Config.StrictQuestSync ~= false then
            QuestSystem.RequireQuestClear = true
            QuestSystem.QuestSwitchFrom = tostring(previous.Mob or previous.Quest or "old quest")
            QuestSystem.QuestSwitchTo = tostring(current.Mob or current.Quest or "new quest")
            QuestSystem.LastMismatchAbandonAt = 0
        end

        pcall(function()
            CommF_:InvokeServer("AbandonQuest")
        end)
    end

    QuestSystem.Current = current
    if previous ~= current then
        QuestSystem.Active = false
        QuestSystem.ActiveQuestCache = false
        QuestSystem.ActiveQuestCheckAt = 0
    else
        QuestSystem.Active = QuestSystem.Active and current ~= nil
    end

    if previous ~= current then
        QuestSystem.LocalKills = 0
        QuestSystem.Active = false
        QuestSystem.ActiveQuestCache = false
        QuestSystem.ActiveQuestCheckAt = 0
        QuestSystem.GiverCache = {}
        QuestSystem.GiverApproachCache = {}
        QuestSystem.SpawnCache = {}
        QuestSystem.AcceptedGraceUntil = 0
        QuestSystem.LastAcceptedQuestKey = nil
        QuestSystem.PrisonWaitingSince = 0
        QuestSystem.LastPrisonInteractAt = 0
        QuestSystem.ScoutIndex = 0
        QuestSystem.FastQuestAttempts = 0
        QuestSystem.FastQuestLastAttempt = 0
        QuestSystem.FastQuestFallbackUntil = 0
        QuestSystem.FastQuestLastKey = nil
        QuestSystem.SpawnCycleIndex = 1
        QuestSystem.LastSpawnCycleAt = 0
        Combat.CurrentTarget = nil
        Combat.TargetCache = nil
        Combat.LastScanQuest = nil
    end

    return QuestSystem.Current
end

QuestSystem.ProgressCacheAt = QuestSystem.ProgressCacheAt or 0
QuestSystem.ProgressCacheCurrent = QuestSystem.ProgressCacheCurrent or 0
QuestSystem.ProgressCacheRequired = QuestSystem.ProgressCacheRequired or 0

function QuestSystem.GetQuestProgress()
    local quest = QuestSystem.Current
    if not quest then
        return 0, 0
    end

    local required = tonumber(quest.Required) or 0
    local now = tick()

    if now - (QuestSystem.ProgressCacheAt or 0) < 0.20
        and QuestSystem.ProgressCacheRequired == required then
        return QuestSystem.ProgressCacheCurrent or 0, required
    end

    QuestSystem.ProgressCacheAt = now
    QuestSystem.ProgressCacheRequired = required

    local current = math.min(tonumber(QuestSystem.LocalKills) or 0, required)
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")

    if playerGui and required > 0 then
        local scanned = 0

        for _, obj in ipairs(playerGui:GetDescendants()) do
            scanned = scanned + 1
            if scanned > 900 then
                break
            end

            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                local visible = true
                pcall(function()
                    visible = obj.Visible
                end)

                if visible then
                    local a, b = tostring(obj.Text or ""):match("(%d+)%s*/%s*(%d+)")
                    a, b = tonumber(a), tonumber(b)

                    if a and b and b == required and a >= 0 and a <= b then
                        current = a
                        break
                    end
                end
            end
        end
    end

    QuestSystem.LocalKills = current
    QuestSystem.ProgressCacheCurrent = current
    return current, required
end

function QuestSystem.HasValidQuest()
    return QuestSystem.Current ~= nil
end

function QuestSystem.IsQuestCompleted()
    local quest = QuestSystem.Current
    if not quest then
        return false
    end
    return QuestSystem.LocalKills >= quest.Required
end

-- Farm Engine
FarmEngine.State = "INITIALIZING"
FarmEngine.Activity = "Starting"
FarmEngine.Running = false
FarmEngine.LastError = nil
FarmEngine.ErrorCount = 0

function FarmEngine.Start()
    if FarmEngine.Running then
        return
    end

    FarmEngine.Running = true
    FarmEngine.State = "RUNNING"
    UI.KaitunEnabled = true
    UI.SetStatus("Farm Engine Started")

    if type(UI.RefreshPowerButton) == "function" then
        UI.RefreshPowerButton()
    end

    task.spawn(function()
        local baseWait = math.max(0.08, tonumber(Config.FarmTickInterval) or 0.12)
        local adaptiveWait = baseWait

        while FarmEngine.Running and IsCurrentSession() do
            local started = tick()
            local ok, err = pcall(FarmEngine.Tick)
            local elapsed = tick() - started

            if not ok then
                FarmEngine.State = "RECOVERING"
                FarmEngine.LastError = tostring(err)
                Logger.error("Farm tick failed:", err)
                UI.SetStatus("Farm Engine | unexpected recovery")
                adaptiveWait = math.min(0.40, math.max(baseWait, 0.20))
                task.wait(adaptiveWait)
                FarmEngine.State = "RUNNING"
            else
                -- Adaptive backoff: if one cycle becomes expensive, slow the next
                -- cycle instead of immediately piling more work onto the scheduler.
                if elapsed > baseWait then
                    adaptiveWait = math.min(0.30, math.max(baseWait, elapsed * 1.25))
                else
                    adaptiveWait = baseWait
                end
                task.wait(adaptiveWait)
            end
        end
    end)
end

function FarmEngine.Stop()
    FarmEngine.Running = false
    FarmEngine.State = "STOPPED"
    FarmEngine.StopSerial = (FarmEngine.StopSerial or 0) + 1
    local stopSerial = FarmEngine.StopSerial

    UI.KaitunEnabled = false
    Attack.WorkerTarget = nil
    Attack.WorkerLastHealth = nil
    Attack.WorkerLastDamageAt = 0

    -- Invalidate any optimistic quest grace from before the pause. On resume,
    -- the real quest GUI is checked again instead of pulling the player away.
    QuestSystem.AcceptedGraceUntil = 0
    QuestSystem.LastAcceptedQuestKey = nil
    QuestSystem.ActiveQuestCheckAt = 0
    QuestSystem.RequireQuestClear = false
    QuestSystem.QuestSwitchFrom = nil
    QuestSystem.QuestSwitchTo = nil
    QuestSystem.LastMismatchAbandonAt = 0
    QuestSystem.GiverApproachCache = {}
    QuestSystem.GiverCache = {}

    UI.SetStatus("Farm Engine Stopped")
    Utils.RestoreLocalMovement()

    -- One farm tick can already be on the call stack when OFF is clicked. Run
    -- two guarded cleanup passes to catch a mover created by that stale tick.
    for _, delayTime in ipairs({0.12, 0.35}) do
        task.delay(delayTime, function()
            if FarmEngine.StopSerial == stopSerial
                and FarmEngine.Running == false
                and UI.KaitunEnabled == false then
                Utils.RestoreLocalMovement()
            end
        end)
    end

    if type(UI.RefreshPowerButton) == "function" then
        UI.RefreshPowerButton()
    end
end

-- Attack System
Attack.RegisterAttack = nil
Attack.RegisterHit = nil
Attack.LastFrameworkRefresh = 0
Attack.FrameworkController = nil
Attack.RigLib = nil
Attack.HitToken = tostring(LocalPlayer.UserId):sub(2, 4) .. "078da"
Attack.HitTokenPrimed = false
Attack.SendHitsThread = nil
Attack.LastSendHitsThreadRefresh = 0
Attack.WorkerRunning = false
Attack.WorkerGeneration = 0
Attack.WorkerLastAttack = 0
Attack.WorkerTarget = nil
Attack.WorkerLastHealth = nil
Attack.WorkerLastDamageAt = 0
Attack.LastFallbackClick = 0

function Attack.GetSendHitsThread(force)
    local now = tick()
    if not force
        and Attack.SendHitsThread
        and coroutine.status(Attack.SendHitsThread) ~= "dead"
        and now - (Attack.LastSendHitsThreadRefresh or 0) < 3.0 then
        return Attack.SendHitsThread
    end

    Attack.LastSendHitsThreadRefresh = now
    Attack.SendHitsThread = nil

    pcall(function()
        local globalModule = ReplicatedStorage:FindFirstChild("Global")
        if not globalModule then
            return
        end

        local global = require(globalModule)
        local sendHits = type(global) == "table" and global.SendHitsToServer or nil
        if type(sendHits) ~= "function" then
            return
        end

        local getter = getupvalues or (debug and debug.getupvalues)
        if type(getter) ~= "function" then
            return
        end

        for _, value in pairs(getter(sendHits)) do
            if type(value) == "thread" and coroutine.status(value) ~= "dead" then
                Attack.SendHitsThread = value
                break
            end
        end
    end)

    return Attack.SendHitsThread
end

function Attack.LocalM1Fallback()
    local now = tick()
    if now - (Attack.LastFallbackClick or 0) < (tonumber(Config.AttackFallbackClickInterval) or 0.22) then
        return false
    end

    Attack.LastFallbackClick = now
    return pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(math.huge, math.huge))
    end)
end

function Attack.RefreshFramework()
    local now = tick()
    if Attack.FrameworkController
        and Attack.RigLib
        and (now - (Attack.LastFrameworkRefresh or 0)) < 2.0 then
        return true
    end

    Attack.LastFrameworkRefresh = now

    local ok = pcall(function()
        local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
        local combatModule = scripts and scripts:FindFirstChild("CombatFramework")
        local frameworkFolder = ReplicatedStorage:FindFirstChild("CombatFramework")
        local rigModule = frameworkFolder and frameworkFolder:FindFirstChild("RigLib")

        if not combatModule or not rigModule then
            return
        end

        local framework = require(combatModule)
        local upvalues = debug.getupvalues(framework)
        local lib = upvalues and upvalues[2]

        if lib and lib.activeController then
            Attack.FrameworkController = lib.activeController
        end

        Attack.RigLib = require(rigModule)
    end)

    return ok and Attack.FrameworkController ~= nil and Attack.RigLib ~= nil
end

function Attack.RefreshRemotes()
    if not Net then
        return false
    end

    local oldAttack = Attack.RegisterAttack
    local oldHit = Attack.RegisterHit

    Attack.RegisterAttack = Net:FindFirstChild("RE/RegisterAttack", true)
        or Net:FindFirstChild("RegisterAttack", true)
    Attack.RegisterHit = Net:FindFirstChild("RE/RegisterHit", true)
        or Net:FindFirstChild("RegisterHit", true)

    if oldAttack ~= Attack.RegisterAttack or oldHit ~= Attack.RegisterHit then
        Attack.HitTokenPrimed = false
    end

    return Attack.RegisterAttack ~= nil and Attack.RegisterHit ~= nil
end

function Attack.Init()
    pcall(Attack.RefreshRemotes)
    pcall(Attack.RefreshFramework)
    pcall(Attack.GetSendHitsThread, true)

    Attack.WorkerGeneration = (Attack.WorkerGeneration or 0) + 1
    local generation = Attack.WorkerGeneration
    Attack.WorkerRunning = true

    task.spawn(function()
        while Attack.WorkerRunning and generation == Attack.WorkerGeneration and IsCurrentSession() do
            local target = Combat and Combat.CurrentTarget or nil
            local hrp = Utils.HRP()
            local hum = target and target:FindFirstChildOfClass("Humanoid")
            local root = target and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart)

            if FarmEngine.Running
                and Config.AutoFarm
                and Config.FastAttack
                and target and target.Parent
                and hum and hum.Health > 0
                and hrp and root
                and (root.Position - hrp.Position).Magnitude <= 55 then

                local now = tick()

                if Attack.WorkerTarget ~= target then
                    Attack.WorkerTarget = target
                    Attack.WorkerLastHealth = hum.Health
                    Attack.WorkerLastDamageAt = now
                    Attack.WorkerLastAttack = 0
                    -- One real local M1 helps satisfy builds that require the NPC
                    -- to be confronted before server-side fast hits are accepted.
                    Attack.LocalM1Fallback()
                elseif Attack.WorkerLastHealth == nil or hum.Health < Attack.WorkerLastHealth - 0.01 then
                    Attack.WorkerLastHealth = hum.Health
                    Attack.WorkerLastDamageAt = now
                else
                    Attack.WorkerLastHealth = hum.Health
                end

                local cooldown = math.max(0.05, tonumber(Config.AttackSpeed) or 0.07)
                if now - (Attack.WorkerLastAttack or 0) >= cooldown then
                    Attack.WorkerLastAttack = now
                    pcall(HakiSystem.ActivateBuso)
                    pcall(Attack.ExecuteAttack, target)
                end

                if now - (Attack.WorkerLastDamageAt or now) >= (tonumber(Config.AttackNoDamageFallback) or 0.70) then
                    Attack.WorkerLastDamageAt = now
                    pcall(Attack.RefreshRemotes)
                    pcall(Attack.GetSendHitsThread, true)
                    Attack.LocalM1Fallback()
                end
            else
                Attack.WorkerTarget = nil
                Attack.WorkerLastHealth = nil
                Attack.WorkerLastDamageAt = 0
            end

            task.wait(tonumber(Config.AttackWorkerInterval) or 0.03)
        end
    end)
end

function Attack.GetEquippedMeleeTool()
    local char = Utils.Character()
    if not char then
        return nil
    end

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == "Melee" then
            return tool
        end
    end

    return char:FindFirstChildOfClass("Tool")
end

function Attack.RedzStyleHit(target)
    if not target or not target.Parent then
        return false
    end

    if not Attack.RefreshFramework() then
        return false
    end

    local char = Utils.Character()
    local controller = Attack.FrameworkController
    local rigLib = Attack.RigLib

    if not char or not controller or not rigLib then
        return false
    end

    local targetRoot = target:FindFirstChild("HumanoidRootPart")
        or target:FindFirstChild("Head")
        or target.PrimaryPart

    if not targetRoot then
        return false
    end

    return pcall(function()
        -- Keep the controller in the same fast-attack state used by the base.
        controller.increment = 3
        controller.timeToNextAttack = 0
        controller.timeToNextBlock = 0
        controller.focusStart = 0
        controller.attacking = false
        controller.hitboxMagnitude = 100

        -- FastAttack via CombatFramework itself when exposed by this build.
        if type(controller.attack) == "function" then
            pcall(function()
                controller:attack()
            end)
        end

        local weapon = controller.blades and controller.blades[1]
        if weapon then
            while weapon.Parent and weapon.Parent ~= char do
                weapon = weapon.Parent
            end
        end

        local rigControllerEvent = ReplicatedStorage:FindFirstChild("RigControllerEvent")
        if rigControllerEvent and weapon then
            rigControllerEvent:FireServer("weaponChange", tostring(weapon))
            rigControllerEvent:FireServer("hit", {targetRoot}, 1, "")
        end
    end)
end

function Attack.PrimeHitToken()
    if Attack.HitTokenPrimed then
        return true
    end

    if not Attack.RegisterHit then
        return false
    end

    local ok = pcall(function()
        Attack.RegisterHit:FireServer(Attack.HitToken)
    end)

    if ok then
        Attack.HitTokenPrimed = true
    end

    return ok
end

function Attack.GetTargetHits(target, range)
    local results = {}
    local char = Utils.Character()
    local hrp = Utils.HRP()

    if not target or not hrp then
        return results
    end

    local wanted = Utils.Normalize(target.Name)
    local maxRange = tonumber(range) or 60
    local maxCount = Config.BringMobs
        and math.max(1, math.floor(tonumber(Config.BringMobCount) or 2))
        or 1

    local function addMob(mob)
        if #results >= maxCount or not mob or mob == char then
            return
        end

        local hum = mob:FindFirstChildOfClass("Humanoid")
        local root = mob:FindFirstChild("HumanoidRootPart")
            or mob:FindFirstChild("Head")
            or mob.PrimaryPart

        if not hum or hum.Health <= 0 or not root then
            return
        end

        if Utils.Normalize(mob.Name) ~= wanted then
            return
        end

        if (root.Position - hrp.Position).Magnitude > maxRange then
            return
        end

        local hitPart = mob:FindFirstChild("Head") or root
        table.insert(results, {mob, hitPart})
    end

    -- Current target must always be first.
    addMob(target)

    local enemies = workspace:FindFirstChild("Enemies")
    if enemies and #results < maxCount then
        for _, mob in ipairs(enemies:GetChildren()) do
            if mob ~= target then
                addMob(mob)
                if #results >= maxCount then
                    break
                end
            end
        end
    end

    return results
end

function Attack.ExecuteAttack(target)
    if not Config.FastAttack or not target or not target.Parent then
        return false
    end

    local hum = target:FindFirstChildOfClass("Humanoid")
    local hitPart = target:FindFirstChild("HumanoidRootPart")
        or target:FindFirstChild("Head")
        or target.PrimaryPart

    if not hum or hum.Health <= 0 or not hitPart then
        return false
    end

    local equippedMelee = Utils.EnsureMeleeEquipped(true)

    if tostring(Config.FarmWeaponType) == "Melee" and not equippedMelee then
        return false
    end

    if not Attack.RegisterAttack or not Attack.RegisterHit then
        pcall(Attack.RefreshRemotes)
    end

    local remoteWorked = false

    -- Current Speed Hub X-style FastAttack protocol:
    -- RegisterAttack(0), then feed firstPart + remaining hits into the game's
    -- SendHitsToServer coroutine when available. Direct RegisterHit is the fallback.
    if Attack.RegisterAttack and Attack.RegisterHit then
        local hits = Attack.GetTargetHits(target, 60)

        if #hits > 0 then
            local first = table.remove(hits, 1)
            local firstPart = first and first[2] or hitPart
            local sendThread = Attack.GetSendHitsThread(false)

            local attackOK = pcall(function()
                Attack.RegisterAttack:FireServer(0)
            end)

            if sendThread and coroutine.status(sendThread) ~= "dead" then
                local resumed = coroutine.resume(sendThread, firstPart, hits)
                remoteWorked = attackOK and resumed == true
            else
                Attack.PrimeHitToken()
                remoteWorked = pcall(function()
                    Attack.RegisterHit:FireServer(
                        firstPart,
                        hits,
                        nil,
                        Attack.HitToken
                    )
                end) and attackOK
            end
        end
    end

    -- Framework path stays as a compatibility fallback.
    local frameworkOK = Attack.RedzStyleHit(target)

    -- Last-resort compatibility for executors/builds where the token protocol
    -- is unavailable but the simpler RegisterHit form still works.
    if not remoteWorked and Attack.RegisterAttack and Attack.RegisterHit then
        pcall(function()
            Attack.RegisterAttack:FireServer(0)
            Attack.RegisterHit:FireServer(hitPart, {})
        end)
    end

    return remoteWorked or frameworkOK
end

-- Haki System
function HakiSystem.ActivateBuso()
    if not Config.AutoHaki then
        return
    end

    local now = tick()
    if HakiSystem.LastBuso and (now - HakiSystem.LastBuso) < (tonumber(Config.HakiInterval) or 5.0) then
        return
    end

    local char = Utils.Character()
    if char and char:FindFirstChild("HasBuso") then
        return
    end

    if not CommF_ then
        CommF_ = WaitForCommF(2)
    end

    if CommF_ then
        HakiSystem.LastBuso = now
        pcall(function()
            CommF_:InvokeServer("Buso")
        end)
    end
end

function HakiSystem.ActivateKen()
    if not Config.AutoActiveKen then
        return false
    end

    local now = tick()
    if now - (HakiSystem.LastKen or 0) < (tonumber(Config.KenActivateInterval) or 1.0) then
        return false
    end

    if not CommF_ then
        CommF_ = WaitForCommF(2)
    end
    if not CommF_ then
        return false
    end

    HakiSystem.LastKen = now
    local ok = pcall(function()
        -- Current activation call used by Speed Hub X.
        CommF_:InvokeServer("Ken", true)
    end)
    return ok
end

--=====================================================================================
-- Ability / shop auto-buy
--=====================================================================================
AbilitySystem.Prices = {
    AirJump = 10000,
    Aura = 25000,
    FlashStep = 100000,
    InstinctV1 = 750000,
}
AbilitySystem.Done = {}
AbilitySystem.LastPurchaseTick = 0
AbilitySystem.ItemLastAttempt = {}
AbilitySystem.Inventory = {}
AbilitySystem.LastInventoryRefresh = 0
AbilitySystem.Running = false

function AbilitySystem.GetBeli()
    local data = LocalPlayer:FindFirstChild("Data")
    local beli = data and data:FindFirstChild("Beli")
    return beli and tonumber(beli.Value) or 0
end

function AbilitySystem.RefreshInventory(force)
    local now = tick()
    if not force
        and now - (AbilitySystem.LastInventoryRefresh or 0) < (tonumber(Config.ShopInventoryRefreshInterval) or 5.0) then
        return AbilitySystem.Inventory
    end

    AbilitySystem.LastInventoryRefresh = now
    if not CommF_ then
        CommF_ = WaitForCommF(2)
    end
    if not CommF_ then
        return AbilitySystem.Inventory
    end

    local inventory = FetchPlayerInventory()

    if type(inventory) == "table" then
        local set = {}
        local seen = {}

        local function collect(value, depth)
            if depth > 5 or type(value) ~= "table" or seen[value] then
                return
            end
            seen[value] = true

            local name = value.Name or value.name or value.StorageKey or value.DisplayName or value.ItemName
            if type(name) == "string" and name ~= "" then
                set[tostring(name)] = true
            end

            for key, child in pairs(value) do
                if type(key) == "string" and (child == true or child == 1) then
                    set[key] = true
                end
                if type(child) == "table" then
                    collect(child, depth + 1)
                end
            end
        end

        collect(inventory, 0)
        AbilitySystem.Inventory = set
    end

    return AbilitySystem.Inventory
end

function AbilitySystem.TryBuySimple(key, enabled, price, ...)
    if not enabled or AbilitySystem.Done[key] then
        return false
    end
    if AbilitySystem.GetBeli() < (tonumber(price) or 0) then
        return false
    end
    if not CommF_ then
        CommF_ = WaitForCommF(2)
    end
    if not CommF_ then
        return false
    end

    local args = {...}
    local ok, result = pcall(function()
        return CommF_:InvokeServer(unpack(args))
    end)

    if ok and result ~= false then
        -- Geppo/Buso/Soru have no extra prerequisites beyond Beli. Once the
        -- server accepts the call, do not spam the purchase remote this session.
        AbilitySystem.Done[key] = true
        Logger.info("Ability purchase checked:", key, tostring(result))
        return true
    end

    return false
end

function AbilitySystem.TryBuyInstinctV1()
    if not Config.AutoBuyInstinctV1 or AbilitySystem.Done.InstinctV1 then
        return false
    end

    local level = tonumber(Utils.Level()) or 1
    if level < 300 then
        return false
    end

    -- Instinct V1 requires the Saber puzzle/boss to be completed.
    if SaberSystem and type(SaberSystem.Check) == "function" then
        pcall(function()
            SaberSystem.Check(false)
        end)
    end
    if not (SaberSystem and SaberSystem.Has == true) then
        return false
    end

    if AbilitySystem.GetBeli() < (AbilitySystem.Prices.InstinctV1 or 750000) then
        return false
    end

    if not CommF_ then
        CommF_ = WaitForCommF(2)
    end
    if not CommF_ then
        return false
    end

    local beforeBeli = AbilitySystem.GetBeli()
    local ok, result = pcall(function()
        -- Purchase call from the Speed Hub X Ability Teacher table.
        return CommF_:InvokeServer("KenTalk", "Buy")
    end)

    if not ok or result == false then
        return false
    end

    -- The remote is idempotent if Instinct is already owned. Mark this session
    -- as checked after an accepted call, then immediately use the activation
    -- remote so AutoActiveKen starts working without waiting for another system tick.
    AbilitySystem.Done.InstinctV1 = true
    task.delay(0.20, function()
        local afterBeli = AbilitySystem.GetBeli()
        if afterBeli < beforeBeli then
            Logger.info("Instinct V1 purchased. Beli spent:", beforeBeli - afterBeli)
        else
            Logger.info("Instinct V1 purchase checked/already owned")
        end
        HakiSystem.LastKen = 0
        HakiSystem.ActivateKen()
    end)

    return true
end

function AbilitySystem.TryBuyConfiguredItems()
    if type(Config.AutoBuyShopItems) ~= "table" then
        return
    end

    local inventory = AbilitySystem.RefreshInventory(false)
    local now = tick()
    local retry = tonumber(Config.ShopItemRetryInterval) or 15.0

    for itemName, enabled in pairs(Config.AutoBuyShopItems) do
        if enabled == true and not inventory[itemName] then
            local last = AbilitySystem.ItemLastAttempt[itemName] or 0
            if now - last >= retry then
                AbilitySystem.ItemLastAttempt[itemName] = now

                if not CommF_ then
                    CommF_ = WaitForCommF(2)
                end

                if CommF_ then
                    pcall(function()
                        -- Same generic item shop call used by Redz/Speed Hub X.
                        CommF_:InvokeServer("BuyItem", itemName)
                    end)
                    -- Force a fresh inventory read on the next cycle to verify it.
                    AbilitySystem.LastInventoryRefresh = 0
                end
            end
        end
    end
end

function AbilitySystem.Tick()
    local now = tick()
    if now - (AbilitySystem.LastPurchaseTick or 0) >= (tonumber(Config.AbilityBuyInterval) or 2.0) then
        AbilitySystem.LastPurchaseTick = now

        AbilitySystem.TryBuySimple(
            "AirJump",
            Config.AutoBuyAirJump,
            AbilitySystem.Prices.AirJump,
            "BuyHaki", "Geppo"
        )
        AbilitySystem.TryBuySimple(
            "Aura",
            Config.AutoBuyAura,
            AbilitySystem.Prices.Aura,
            "BuyHaki", "Buso"
        )
        AbilitySystem.TryBuySimple(
            "FlashStep",
            Config.AutoBuyFlashStep,
            AbilitySystem.Prices.FlashStep,
            "BuyHaki", "Soru"
        )
        AbilitySystem.TryBuyInstinctV1()
        AbilitySystem.TryBuyConfiguredItems()
    end

    -- Activation is independent from purchasing and remains controlled by AutoActiveKen.
    HakiSystem.ActivateKen()
end

function AbilitySystem.Init()
    if AbilitySystem.Running then
        return
    end
    AbilitySystem.Running = true

    task.spawn(function()
        while AbilitySystem.Running and IsCurrentSession() do
            pcall(AbilitySystem.Tick)
            task.wait(0.35)
        end
    end)
end

function AbilitySystem.Stop()
    AbilitySystem.Running = false
end

-- Combat System
Combat.CurrentTarget = nil
Combat.AttackCooldown = 0
Combat.LastMoveAt = 0
Combat.LastScan = 0
Combat.LastScanQuest = nil
Combat.TargetCache = nil
Combat.LastFallbackScan = 0
Combat.LastFallbackQuest = nil
Combat.FallbackCache = nil
Combat.LastBringAt = 0
Combat.LastBringTarget = nil
Combat.SimulationConfigured = false
Combat.OrbitAngle = 0
Combat.LastOrbitUpdate = 0
Combat.HoverBodyPosition = nil
Combat.HoverBodyGyro = nil
Combat.HoverTarget = nil

function Combat.FindNearestEnemy()
    local hrp = Utils.HRP()
    if not hrp then
        return nil
    end

    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then
        return nil
    end

    local nearest = nil
    local nearestDist = math.huge

    for _, enemy in ipairs(enemies:GetChildren()) do
        local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
        local enemyHum = enemy:FindFirstChildOfClass("Humanoid")

        if enemyHRP and enemyHum and enemyHum.Health > 0 then
            local dist = (enemyHRP.Position - hrp.Position).Magnitude
            if dist < nearestDist and dist <= Config.SearchRadius then
                nearestDist = dist
                nearest = enemy
            end
        end
    end

    return nearest
end

Combat.TargetAnchor = nil
Combat.AnchorTarget = nil
Combat.OrbitAngle = 0

function Combat.StopAboveHead()
    local mover = Combat.HoverBodyPosition
    local gyro = Combat.HoverBodyGyro

    Combat.HoverBodyPosition = nil
    Combat.HoverBodyGyro = nil
    Combat.HoverTarget = nil

    if mover and mover.Parent then
        pcall(function()
            mover:Destroy()
        end)
    end

    if gyro and gyro.Parent then
        pcall(function()
            gyro:Destroy()
        end)
    end

    local character = LocalPlayer and LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function()
            humanoid.AutoRotate = true
        end)
    end
end

function Combat.ResetAnchor()
    Combat.StopAboveHead()
    Combat.TargetAnchor = nil
    Combat.AnchorTarget = nil
    Combat.OrbitAngle = 0
    Combat.LastOrbitUpdate = 0
    Combat.LastTargetLockTarget = nil
    Combat.LastTargetLockAt = 0
end

function Combat.GetAnchor(enemy, enemyRoot)
    if Combat.AnchorTarget ~= enemy
        or not Combat.TargetAnchor
        or not enemyRoot
        or not enemyRoot.Parent then

        Combat.AnchorTarget = enemy
        Combat.TargetAnchor = enemyRoot and enemyRoot.CFrame or nil
        Combat.OrbitAngle = 0
    end

    return Combat.TargetAnchor
end

function Combat.LockTargetAtSpawn(enemy, anchorCF)
    if not Config.LockTargetAtSpawn
        or not enemy
        or typeof(anchorCF) ~= "CFrame" then
        return
    end

    local now = tick()
    if Combat.LastTargetLockTarget == enemy
        and now - (Combat.LastTargetLockAt or 0) < (tonumber(Config.TargetLockInterval) or 0.12) then
        return
    end
    Combat.LastTargetLockTarget = enemy
    Combat.LastTargetLockAt = now

    local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
    local hum = enemy:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then
        return
    end

    local tolerance = tonumber(Config.TargetLockTolerance) or 1.5
    local delta = root.Position - anchorCF.Position

    pcall(function()
        -- Only this selected NPC is constrained at the place where the fight began.
        root.CanCollide = false
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        hum.AutoRotate = false
        hum.WalkSpeed = 0

        if delta.Magnitude > tolerance then
            root.CFrame = anchorCF
        end
    end)
end

function Combat.BringEnemyToAnchor(enemy, anchorCF)
    Combat.LockTargetAtSpawn(enemy, anchorCF)
end

function Combat.BringNearbyMobs(anchorEnemy, anchorCF)
    if not Config.BringMobs
        or not anchorEnemy
        or typeof(anchorCF) ~= "CFrame" then
        return 0
    end

    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then
        return 0
    end

    local wanted = Utils.Normalize(anchorEnemy.Name)
    local radius = tonumber(Config.BringMobRadius) or 500
    local maxCount = math.max(1, math.floor(tonumber(Config.BringMobCount) or 2))
    local additionalLimit = math.max(0, maxCount - 1) -- anchor target counts as one
    local brought = 0

    if additionalLimit <= 0 then
        return 0
    end

    for _, mob in ipairs(enemies:GetChildren()) do
        if brought >= additionalLimit then
            break
        end

        if mob ~= anchorEnemy and Utils.Normalize(mob.Name) == wanted then
            local root = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
            local hum = mob:FindFirstChildOfClass("Humanoid")

            if root and hum and hum.Health > 0
                and (root.Position - anchorCF.Position).Magnitude <= radius then

                brought = brought + 1

                pcall(function()
                    root.CanCollide = false
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    hum.AutoRotate = false
                    hum.WalkSpeed = 0

                    -- Small deterministic offset prevents every root from occupying
                    -- the exact same point while still keeping the group in range.
                    local angle = (brought / math.max(1, additionalLimit)) * math.pi * 2
                    local offset = Vector3.new(math.cos(angle) * 2.25, 0, math.sin(angle) * 2.25)
                    root.CFrame = anchorCF + offset
                end)
            end
        end
    end

    return brought
end

function Combat.StayAboveTarget(enemy, anchorCF)
    if not AutomationMovementAllowed() then
        Combat.StopAboveHead()
        return false
    end

    local hrp = Utils.HRP()
    if not hrp or not enemy or typeof(anchorCF) ~= "CFrame" then
        return false
    end

    local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
    local head = enemy:FindFirstChild("Head")

    local basePosition
    if enemyRoot then
        -- Follow the live NPC position while orbiting.
        basePosition = enemyRoot.Position
    elseif head then
        basePosition = head.Position
    else
        basePosition = anchorCF.Position
    end

    -- Speed Hub X style orbit:
    -- FarmOrbitRadius is horizontal distance; FarmDistance is vertical height.
    local radius = math.max(0, tonumber(Config.FarmOrbitRadius) or 24)
    local height = tonumber(Config.FarmDistance) or 12
    local orbitSpeed = tonumber(Config.FarmOrbitSpeed) or 380

    local now = tick()
    local last = tonumber(Combat.LastOrbitUpdate) or 0
    local dt = last > 0 and math.clamp(now - last, 0, 0.20) or 0.016
    Combat.LastOrbitUpdate = now
    Combat.OrbitAngle = ((tonumber(Combat.OrbitAngle) or 0) + orbitSpeed * dt) % 360

    local angle = math.rad(Combat.OrbitAngle)
    local desiredPosition = basePosition + Vector3.new(
        math.sin(angle) * radius,
        height,
        math.cos(angle) * radius
    )

    local distance = (hrp.Position - desiredPosition).Magnitude
    local approachDistance = math.max(
        radius + 20,
        tonumber(Config.FarmAboveApproachDistance) or 55
    )

    if distance > approachDistance then
        Combat.StopAboveHead()
        Teleport.To(
            CFrame.new(desiredPosition, basePosition),
            tonumber(Config.FarmSpeed) or Config.TweenSpeed,
            "COMBAT",
            false
        )
        return false
    end

    if Teleport.IsBusy() and Teleport.Owner == "COMBAT" then
        Teleport.Cancel()
    end

    local mover = Combat.HoverBodyPosition
    local gyro = Combat.HoverBodyGyro

    if not mover or not mover.Parent or Combat.HoverTarget ~= enemy then
        Combat.StopAboveHead()

        mover = Instance.new("BodyPosition")
        mover.Name = "KratosSpeedHubOrbit"
        mover.MaxForce = Vector3.new(
            tonumber(Config.CombatHoverMaxForce) or 1000000000,
            tonumber(Config.CombatHoverMaxForce) or 1000000000,
            tonumber(Config.CombatHoverMaxForce) or 1000000000
        )
        mover.P = math.max(30000, tonumber(Config.CombatHoverP) or 18000)
        mover.D = math.max(1800, tonumber(Config.CombatHoverD) or 1200)
        mover.Position = desiredPosition
        mover.Parent = hrp

        -- Stabilize only the horizontal facing direction.
        -- Y-only torque keeps the avatar upright and prevents the waist from
        -- pitching forward/back while the NPC is below the player.
        gyro = Instance.new("BodyGyro")
        gyro.Name = "KratosStableOrbitGyro"
        gyro.MaxTorque = Vector3.new(0, 1000000000, 0)
        gyro.P = 28000
        gyro.D = 1200
        gyro.Parent = hrp

        local humanoid = hrp.Parent and hrp.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.AutoRotate = false
        end

        Combat.HoverBodyPosition = mover
        Combat.HoverBodyGyro = gyro
        Combat.HoverTarget = enemy
    else
        mover.Position = desiredPosition
    end

    -- Look at the NPC only on the horizontal plane.
    -- Same Y = no up/down tilt, so the body remains visually upright.
    local flatTarget = Vector3.new(basePosition.X, hrp.Position.Y, basePosition.Z)
    if gyro and gyro.Parent and (flatTarget - hrp.Position).Magnitude > 0.05 then
        gyro.CFrame = CFrame.lookAt(hrp.Position, flatTarget)
    end

    pcall(function()
        -- Do not zero linear velocity here; BodyPosition handles orbit motion.
        -- Only kill unwanted spin/tilt.
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)

    return (hrp.Position - desiredPosition).Magnitude <= 14
end

function Combat.EngageTarget(enemy)
    if not enemy then
        Combat.CurrentTarget = nil
        Combat.ResetAnchor()
        return
    end

    -- Close the gap between FarmEngine ticks when a boss skill lands hard.
    if Combat.HealthSafetyTick() then
        return
    end

    local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
    local enemyHum = enemy:FindFirstChildOfClass("Humanoid")

    if not enemyRoot or not enemyHum or enemyHum.Health <= 0 then
        if Combat.CurrentTarget == enemy then
            Combat.CurrentTarget = nil
        end
        Combat.ResetAnchor()
        return
    end

    -- ONE MOB AT A TIME.
    if Config.FarmOneMobAtATime
        and Combat.CurrentTarget
        and Combat.CurrentTarget ~= enemy then

        local currentHum = Combat.CurrentTarget:FindFirstChildOfClass("Humanoid")
        if currentHum and currentHum.Health > 0 and Combat.CurrentTarget.Parent then
            return
        end
    end

    local targetChanged = Combat.CurrentTarget ~= enemy
    Combat.CurrentTarget = enemy

    if targetChanged then
        -- First hit should not inherit the previous NPC's cooldown/state.
        Combat.AttackCooldown = 0

        -- Warm the attack path while we're still approaching the target.
        pcall(Attack.RefreshRemotes)
        pcall(Attack.PrimeHitToken)
        pcall(HakiSystem.ActivateBuso)
        pcall(function()
            Utils.EnsureMeleeEquipped(true)
        end)
    end

    -- Fighting-style purchases run in the background and never replace the
    -- farm status. Equip whichever melee style is currently available.
    FarmEngine.SafeCall("FightingStyles", MeleeSystem.Tick)

    if MeleeSystem.PurchaseMode then
        Combat.CurrentTarget = nil
        Combat.ResetAnchor()
        return
    end

    local melee = Utils.EnsureMeleeEquipped(true)
    if tostring(Config.FarmWeaponType) == "Melee" and not melee then
        UI.SetStatus("Farming 1 mob | " .. tostring(enemy.Name) .. " | equipping Melee")
        return
    end

    local anchorCF = Combat.GetAnchor(enemy, enemyRoot)
    if not anchorCF then
        return
    end

    -- Optional group farming. Disabled by default.
    if Config.BringMobs then
        Combat.BringNearbyMobs(enemy, anchorCF)
    end

    -- The selected NPC remains at the exact place where this fight started.
    Combat.LockTargetAtSpawn(enemy, anchorCF)

    -- Speed Hub X style: player circles the NPC while continuing FastAttack.
    local inPosition = Combat.StayAboveTarget(enemy, anchorCF)

    -- The orbit destination moves every frame. Requiring the avatar to be
    -- within 14 studs of that moving point can starve FastAttack forever.
    -- Attack as soon as the actual enemy is inside the same 60-stud hit range
    -- used as a close-engagement gate so the server recognizes the confrontation.
    local hrp = Utils.HRP()
    local enemyDistance = hrp and (enemyRoot.Position - hrp.Position).Magnitude or math.huge

    -- Global checkpoint is tied to actually reaching the combat area, not merely
    -- selecting a quest. This prevents saving a spawn while still travelling.
    if not FragmentFarmSystem.Active
        and enemyDistance <= InternalTuning.Checkpoint.TargetDistance then
        CheckpointSystem.Try(enemy)
    end

    local canAttackWhileOrbiting = enemyDistance <= 32

    if not inPosition and not canAttackWhileOrbiting then
        UI.SetStatus("Farming 1 mob | approaching " .. tostring(enemy.Name) .. " | " .. MeleeSystem.GetStatus())
        return
    end

    -- FastAttack is handled by Attack's independent lightweight worker. Keeping
    -- it out of the main FarmEngine tick prevents attack/equip/GUI work from
    -- stacking in the same frame and makes camera input noticeably smoother.
    if not Attack.WorkerRunning then
        local now = tick()
        local attackCooldown = math.max(0.05, tonumber(Config.AttackSpeed) or 0.07)
        if targetChanged or now - (Combat.AttackCooldown or 0) >= attackCooldown then
            Combat.AttackCooldown = now
            HakiSystem.ActivateBuso()
            Attack.ExecuteAttack(enemy)
        end
    end
end

function Combat.Tick()
    if not Config.AutoFarm then
        return
    end

    if not Utils.IsAlive() then
        Combat.CurrentTarget = nil
        return
    end

    HakiSystem.ActivateBuso()
    Utils.EnsureCombatTool()

    local target = Combat.CurrentTarget
    if target and target.Parent then
        local hum = target:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            Combat.EngageTarget(target)
            return
        end
    end

    -- Previous mob is dead/gone. Only now may we choose the next one.
    Combat.CurrentTarget = nil
    Combat.ResetAnchor()
    target = Combat.FindQuestMob()
    if not target then
        target = Combat.FindFallbackMob()
        if target then
            QuestSystem.FallbackMode = true
        end
    end

    if target then
        Combat.EngageTarget(target)
        return
    end

    local quest = QuestSystem.Current
    local mobName = quest and quest.Mob or "enemies"
    if quest and tick() - (QuestSystem.LastMove or 0) >= 2.0 then
        QuestSystem.LastMove = tick()
        UI.SetStatus("No " .. tostring(mobName) .. " nearby | repositioning")
        QuestSystem.GoToFarmAfterAcquire()
    else
        UI.SetStatus("Searching for " .. tostring(mobName) .. "...")
    end
end

function SkillSystem.MonitorSkills()
    local char = Utils.Character()
    if not char then
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        return
    end

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        return
    end

    animator.AnimationPlayed:Connect(function(animTrack)
        if not animTrack or not animTrack.Animation then
            return
        end

        local animId = animTrack.Animation.AnimationId
        if SkillSystem.Animations[animId] then
            return
        end

        if false and Config.AutoDodgeSkill then
            local duration = animTrack.TimePosition or 1.5
            duration = math.max(duration, 1.5)

            if not _G.DodgeTime or _G.DodgeTime < tick() then
                _G.DodgeTime = tick() + math.floor(duration)
            else
                _G.DodgeTime = _G.DodgeTime + math.floor(duration)
            end
        end
    end)
end

-- Server System
ServerSystem.HopInProgress = false

function ServerSystem.ServerHop(region, maxPlayers, force)
    -- Normal server hop obeys Config.ServerHopEnabled.
    -- force=true is reserved for temporary Saber boss searches.
    if not Config.ServerHopEnabled and not force then
        return false
    end

    if ServerSystem.HopInProgress then
        return false
    end

    ServerSystem.HopInProgress = true

    region = region or Config.ServerHopRegion
    maxPlayers = maxPlayers or Config.MaxPlayersPerServer

    if force then
        maxPlayers = tonumber(Config.SaberBossHopMaxPlayers) or tonumber(maxPlayers) or 11
    end

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local response = ReplicatedStorage:FindFirstChild("__ServerBrowser")

    if not playerGui or not response then
        ServerSystem.HopInProgress = false
        return false
    end

    if force and SaberSystem and SaberSystem.Active then
        SaberSystem.SetCache(
            "Temporary Server Hop",
            "Searching required Saber boss"
        )
    end

    local maxPages = force and (tonumber(Config.SaberBossHopPages) or 8) or 100
    local pageDelay = force and 0.02 or 0.10

    for i = 1, maxPages do
        pcall(function()
            local serverBrowser = playerGui:FindFirstChild("ServerBrowser")

            if serverBrowser then
                local frame = serverBrowser:FindFirstChild("Frame")
                local filters = frame and frame:FindFirstChild("Filters")
                local searchRegion = filters and filters:FindFirstChild("SearchRegion")
                local textBox = searchRegion and searchRegion:FindFirstChild("TextBox")

                if textBox then
                    textBox.Text = region
                end
            end
        end)

        local ok, servers = pcall(function()
            return response:InvokeServer(i)
        end)

        if ok and servers then
            for jobId, serverData in pairs(servers) do
                if jobId ~= game.JobId
                    and serverData.Count <= maxPlayers
                    and not string.find(tostring(serverData.Private), "true") then

                    local teleported = pcall(function()
                        response:InvokeServer("teleport", jobId)
                    end)

                    if teleported then
                        -- If teleport succeeds, this script instance disappears.
                        -- If it fails, unlock after a short grace period.
                        task.delay(5, function()
                            ServerSystem.HopInProgress = false
                        end)

                        return true
                    end
                end
            end
        end

        task.wait(pageDelay)
    end

    -- Fast fallback for a required Saber boss: if the in-game browser did not
    -- produce an eligible server quickly, ask Roblox for a fresh public server.
    if force then
        local fallbackOK = pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)

        if fallbackOK then
            task.delay(3, function()
                ServerSystem.HopInProgress = false
            end)
            return true
        end
    end

    ServerSystem.HopInProgress = false
    return false
end

--=====================================================================================
-- STARTUP
--=====================================================================================

-- All systems are now declared and defined before execution.
task.spawn(function()
    local ok, err = pcall(Initialize)
    if not ok then
        Logger.error("Initialization failed:", err)
    end
end)

-- Client-side cleanup. BindToClose is server-only and must not be called here.
local function CleanupKratos()
    pcall(function()
        if AntiAFK then
            AntiAFK.Enabled = false

            if AntiAFK.Connection then
                AntiAFK.Connection:Disconnect()
                AntiAFK.Connection = nil
            end
        end
    end)
    pcall(function()
        if UI and UI.BlurEffect and UI.BlurEffect.Parent then
            UI.BlurEffect:Destroy()
            UI.BlurEffect = nil
        end
    end)
    pcall(function()
        if UI and UI.ScreenGui and UI.ScreenGui.Parent then
            UI.ScreenGui:Destroy()
            UI.ScreenGui = nil
        end
    end)
    pcall(function()
        if FarmEngine and type(FarmEngine.Stop) == "function" then
            FarmEngine.Stop()
        end
    end)
    pcall(function()
        if FPSBoostSystem and type(FPSBoostSystem.Disable) == "function" then
            FPSBoostSystem.Disable()
        end
    end)
    pcall(function()
        if AutoChatSystem and type(AutoChatSystem.Stop) == "function" then
            AutoChatSystem.Stop()
        end
        if FragmentFarmSystem and type(FragmentFarmSystem.Stop) == "function" then
            FragmentFarmSystem.Stop()
        end
        if OptimizeFixLagSystem and type(OptimizeFixLagSystem.Stop) == "function" then
            OptimizeFixLagSystem.Stop()
        end
    end)
    pcall(function()
        if DialogueSuppressor and type(DialogueSuppressor.Disable) == "function" then
            DialogueSuppressor.Disable()
        end
        if GameNotificationSuppressor and type(GameNotificationSuppressor.Disable) == "function" then
            GameNotificationSuppressor.Disable()
        end
        if UI and UI.WorldTimerGuiConnection then
            pcall(function()
                UI.WorldTimerGuiConnection:Disconnect()
            end)
            UI.WorldTimerGuiConnection = nil
            UI.WorldTimerGuiCacheReady = false
        end
    end)
    pcall(function()
        if AbilitySystem and type(AbilitySystem.Stop) == "function" then
            AbilitySystem.Stop()
        end
    end)
    pcall(function()
        if FruitESPSystem and type(FruitESPSystem.Stop) == "function" then
            FruitESPSystem.Stop()
        end
    end)
    pcall(function()
        if BossSystem and BossSystem.RaidBossConnections then
            for _, connection in ipairs(BossSystem.RaidBossConnections) do
                pcall(function() connection:Disconnect() end)
            end
            BossSystem.RaidBossConnections = {}
        end
    end)
    pcall(function()
        if FruitSystem and FruitSystem.Connections then
            for _, connection in ipairs(FruitSystem.Connections) do
                pcall(function() connection:Disconnect() end)
            end
            FruitSystem.Connections = {}
        end
    end)
    pcall(function()
        Teleport.Cancel()
    end)
end

-- Expose cleanup without using server-only APIs.
getgenv().__KRATOS_CLEANUP = CleanupKratos
