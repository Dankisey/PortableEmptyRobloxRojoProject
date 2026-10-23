local UtilsTypes = require(script.Parent.UtilsTypes)
local Types = {}

--[[========================================================================================]]

export type ButtonsInteractionsConnector = {
	new: () -> ButtonsInteractionsConnector;

	ConnectButton: (ButtonsInteractionsConnector, button: GuiButton, callback: (any) -> (), any) -> nil;

	-- onPress on press, onRelease at the end of the same input wherever the finger is
	ConnectHoldButton: (ButtonsInteractionsConnector, button: GuiButton, onPress: () -> (), onRelease: () -> ()) -> ();
	DisconnectButton: (ButtonsInteractionsConnector, button: GuiButton) -> nil;

	_connectedButtons: {[GuiButton]: {
		IsActive: boolean;
		HoveringTask: thread;
		Connection: RBXScriptConnection;
		ReleaseConnection: RBXScriptConnection?;
	}};
	_buttonsParent: {[GuiButton]: ScreenGui};
	_tweeningButtons: {[GuiButton]: boolean};
	_isMobile: boolean;
} & ControllerTemplate

export type CharacterMovementController = {
	new: () -> CharacterMovementController;

	EnableMovement: (CharacterMovementController) -> nil;
	DisableMovement: (CharacterMovementController) -> nil;
	RefreshSpeed: (CharacterMovementController) -> nil;
} & ControllerTemplate

export type ClientMessagesSender = {
	new: () -> ClientMessagesSender;

	SendMessage: (ClientMessagesSender, messageType: "Default"|"Success"|"Error", baseMessage: string, playerNames: {string}?) -> nil;
	MessageSent: UtilsTypes.Event;
} & ControllerTemplate

export type BackgroundMusicController = {
	new: () -> BackgroundMusicController;

	Skip: (BackgroundMusicController) -> nil;
} & ControllerTemplate

--[[ ResetCamera is required: the other methods cannot be undone without it ]]
export type CameraController = {
	new: () -> CameraController;

	TweenTo: (CameraController, target: CFrame, time: number, start: CFrame?) -> RBXScriptSignal;
	ShakeWithoutPivoting: (CameraController, humanoid: Humanoid, shakeIntensity: number, duration: number, frequency: number) -> nil;
	PivotCamera: (CameraController, character: Model, offsetCframe: CFrame) -> nil;
	FreezeCamera: (CameraController, character: Model) -> nil;
	FixThirdPerson: (CameraController, character: Model) -> nil;
	ResetCamera: (CameraController) -> nil;
} & ControllerTemplate

export type ChatController = {
	new: () -> ChatController;
} & ControllerTemplate

export type GuideBeamController = {
	new: () -> GuideBeamController;

	CreateOrRedirectGuideBeam: (GuideBeamController, category: string, targetPosition: Vector3, reachDistance: number?) -> nil;
	TryDestroyBeam: (GuideBeamController, category: string, isSavingTarget: boolean?) -> boolean;
} & ControllerTemplate

export type InputController = {
	new: () -> InputController;

	GetControlType: (InputController) -> "Console"|"Mobile"|"Desktop";
} & ControllerTemplate

export type SoundPlayer = {
	new: () -> SoundPlayer;

	PlaySound: (SoundPlayer, soundName: string, onPart: (BasePart | Attachment)?) -> Sound?;
} & ControllerTemplate

export type ToolsController = {
	new: () -> ToolsController;

	-- onRelease is needed only by tools that hold
	RegisterAction: (ToolsController, toolType: string, onUse: (Tool) -> (), onRelease: ((Tool) -> ())?) -> ();

	-- the only entry point for the use button and its keys
	UseEquippedTool: (ToolsController) -> ();
	ReleaseEquippedTool: (ToolsController) -> ();
	ActivateTool: (ToolsController, tool: Tool) -> ();

	GetEquippedTool: (ToolsController) -> Tool?;
	GetEquippedToolType: (ToolsController) -> string?;

	-- the tool stays in hand but ignores presses
	SetToolsBlocked: (ToolsController, isBlocked: boolean) -> ();
	AreToolsBlocked: (ToolsController) -> boolean;

	ToolUnequipped: UtilsTypes.Event;
	ToolEquipped: UtilsTypes.Event;
} & ControllerTemplate

export type TooltipsController = {
	new: () -> TooltipsController;

	RegisterDefaultTooltip: (TooltipsController, activationObject: GuiObject, tooltipText: string) -> nil;
	RegisterTooltip: (TooltipsController, activationObject: GuiObject, info: {Type: string}) -> nil;

	DefaultTooltipActivated: UtilsTypes.Event;
	DefaultTooltipDisabled: UtilsTypes.Event;
} & ControllerTemplate

export type RagdollController = {
	new: () -> RagdollController;

	SetRagdoll: (RagdollController, character: Model, enabled: boolean) -> nil;
	ApplyImpulse: (RagdollController, character: Model, velocity: Vector3) -> nil;
	-- pose, tool blocking and camera together: the shared entry point for scenes
	ApplyState: (RagdollController, target: Player, isRagdolled: boolean, impulse: Vector3?) -> nil;

	-- read from outside, so a field and not a method
	IsRagdolled: boolean;
} & ControllerTemplate

export type CustomPromptsController = {
	new: () -> CustomPromptsController;

	CustomPrompts: {[string]: any};
} & ControllerTemplate

--[[========================================================================================]]

export type InfoPin = {
	new: (frame: Frame) -> InfoPin;

	IsEnabled: (InfoPin) -> boolean;
	TurnOff: (InfoPin) -> nil;
	TurnOn: (InfoPin) -> nil;
}

export type FadingGui = {
	new: () -> FadingGui;

	FadeOut: (FadingGui) -> RBXScriptSignal?;
	FadeIn: (FadingGui) -> RBXScriptSignal?;
} & GuiTemplate

export type MainGui = {
	new: () -> MainGui;
} & GuiTemplate

export type PopupsGui = {
	new: () -> PopupsGui;

	FirePopup: (PopupsGui, statName: string, data: any) -> nil;
} & GuiTemplate

export type GuiController = {
	new: () -> GuiController;

	TryAddToEnablingQueue: (GuiController, gui: ScreenGui) -> nil;
	ForceEnabling: (GuiController, gui: ScreenGui) -> nil;

	FadingGui: FadingGui;
	MainGui: MainGui;
	PopupsGui: PopupsGui;
	[string]: GuiTemplate;
}

--[[========================================================================================]]

--[[ a controller missing here makes the types go stale silently ]]
export type Controllers = {
	BackgroundMusicController: BackgroundMusicController;
	ButtonsInteractionsConnector: ButtonsInteractionsConnector;
	CameraController: CameraController;
	CharacterMovementController: CharacterMovementController;
	ChatController: ChatController;
	ClientMessagesSender: ClientMessagesSender;
	CustomPromptsController: CustomPromptsController;
	GuiController: GuiController;
	GuideBeamController: GuideBeamController;
	InputController: InputController;
	RagdollController: RagdollController;
	SoundPlayer: SoundPlayer;
	ToolsController: ToolsController;
	TooltipsController: TooltipsController;
}

--[[========================================================================================]]
export type AnimatedGuiTemplate = {
	CancelAnimations: (AnimatedGuiTemplate) -> nil;
	RemoveTween: (AnimatedGuiTemplate, tween: Tween) -> nil;

	InitialSize: UDim2;
	MainFrame: Frame;

	_animationTweens: {Tween};
} & GuiTemplate

export type GuiTemplate = {
	Enable: (GuiTemplate, isForced: boolean) -> nil;
	Disable: (GuiTemplate) -> nil;
	CreateChildren: (GuiTemplate, guiName: string, modules: {ModuleScript}) -> nil;

	InjectControllers: (GuiTemplate, controllers: Controllers) -> nil;
	InjectUtils: (GuiTemplate, utils: UtilsTypes.Utils) -> nil;
	InjectConfigs: (GuiTemplate, configs: {[string]: any}) -> nil;

	Disabled: UtilsTypes.Event;

	Gui: ScreenGui;
	Name: string;
	_controllers: Controllers;
	_utils: UtilsTypes.Utils;
	_configs: {[string]: any};
}

export type ControllerTemplate = {
	InjectControllers: (ControllerTemplate, controllers: Controllers) -> nil;
	InjectUtils: (ControllerTemplate, utils: UtilsTypes.Utils) -> nil;
	InjectConfigs: (ControllerTemplate, configs: {[string]: any}) -> nil;

	_controllers: Controllers;
	_utils: UtilsTypes.Utils;
	_configs: {[string]: any};
}

return Types
