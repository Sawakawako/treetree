extends GdUnitTestSuite

const ACTION_NODE_NAMES: Array[String] = [
    "ReturnTitleButton", "GatherButton", "LeafButton", "BranchButton",
    "ChloroplastButton", "XylemButton", "SunflowerButton", "NautilusButton",
    "RootEffButton", "RootExploreButton", "SeedlingButton", "DeepDreamButton",
    "WindVeilButton", "StoryButton", "StreamStoryButton", "TotemInterpretButton",
    "InteractHumanButton", "InteractForestButton", "InteractStoneButton", "InteractWildButton",
    "PlunderHumanButton", "PlunderForestButton", "PlunderStoneButton", "PlunderWildButton",
    "IntimateHumanButton", "IntimateForestButton", "IntimateStoneButton", "IntimateWildButton",
    "ReviveHumanButton", "ReviveForestButton", "ReviveStoneButton", "ReviveWildButton",
    "PlunderSoulHumanButton", "PlunderSoulForestButton", "PlunderSoulStoneButton", "PlunderSoulWildButton",
    "FirepitButton", "RingButton", "ForgeButton", "TotemPoleButton",
    "FaithConvertButton", "MemoryConvertButton", "LifeUpgradeButton", "MemoryLinguaButton",
    "FaithEngineButton", "MemoryEngineButton", "RootEchoButton", "RootResonanceButton",
    "EarthSenseButton", "DeepRootButton", "TreeCanopyButton", "RingMemoryButton",
    "CloudCrownButton", "WoodHeartButton", "SkyLightButton", "SongResonanceButton",
    "VillageHeartButton", "GraceButton", "AltarButton",
    "AsgardButton", "VanaheimButton", "AlfheimButton", "JotunheimButton",
    "MidgardButton", "NidavellirButton", "NiflheimButton", "HelheimButton", "MuspelheimButton",
    "WorldTraceButton", "RainNameButton", "RiverHearingButton", "SkyLadderButton",
    "WorldShapingButton", "WorldBreathButton", "OasisButton", "RainButton",
    "BanishShadowButton", "CallSoulButton", "ShapeButton",
    "MiracleHumanButton", "MiracleForestButton", "MiracleStoneButton", "MiracleWildButton",
    "WorldAxisButton",
]

const EVENT_NODE_NAMES: Array[String] = [
    "ChoicePanel", "ChoiceOptionAButton", "ChoiceOptionBButton",
    "ChoiceOptionCButton", "ChoiceOptionDButton", "ReturnPanel",
    "ReturnAdvanceButton", "EndingPanel", "EndingActionButton",
]

func test_every_existing_action_and_blocking_control_has_a_migration_target() -> void:
    var scene := load("res://features/ui/main.tscn") as PackedScene
    var root := scene.instantiate()
    for node_name: String in ACTION_NODE_NAMES + EVENT_NODE_NAMES:
        assert_that(root.find_child(node_name, true, false)).is_not_null()
    root.free()
