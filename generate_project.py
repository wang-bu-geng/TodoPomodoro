#!/usr/bin/env python3
"""Generate Xcode project.pbxproj for TodoPomodoro iOS app with Live Activity widget extension"""
import uuid, os, json

ROOT = os.path.dirname(os.path.abspath(__file__))

def pbxid(seed):
    return uuid.uuid5(uuid.NAMESPACE_DNS, str(seed)).hex[:24].upper()

def q(s):
    return json.dumps(s, ensure_ascii=False)

# ==============================
# 1. File lists
# ==============================
MAIN_SRCDIR = os.path.join(ROOT, "TodoPomodoro")

app_files = [
    "TodoPomodoroApp.swift",
    "ContentView.swift",
    "Models/TodoItem.swift",
    "ViewModels/TodoViewModel.swift",
    "ViewModels/PomodoroViewModel.swift",
    "ViewModels/SettingsViewModel.swift",
    "Views/Pomodoro/PomodoroView.swift",
    "Views/Settings/SettingsView.swift",
    "Views/Todo/TodoListView.swift",
    "Views/Todo/AddTodoView.swift",
    "Views/Todo/TodoDetailView.swift",
    "PomodoroWidget/PomodoroActivityAttributes.swift",
]

widget_files = [
    "PomodoroWidget/PomodoroActivityAttributes.swift",
    "PomodoroWidget/PomodoroLiveActivity.swift",
    "PomodoroWidget/PomodoroWidgetBundle.swift",
]

widget_infoplist_path = "TodoPomodoro/PomodoroWidget/Info.plist"

# ==============================
# 2. ID generation
# ==============================
# App target IDs
PROJECT_PBXID = pbxid("project")
MAIN_GROUP = pbxid("main_group")
SOURCES_GROUP = pbxid("sources_group")
PRODUCTS_GROUP = pbxid("products_group")
APP_PRODUCT_REF = pbxid("product_app")
APP_TARGET = pbxid("target_app")
APP_BUILD_CFG_DEBUG = pbxid("app_build_debug")
APP_BUILD_CFG_RELEASE = pbxid("app_build_release")
APP_BUILD_LIST = pbxid("app_build_list")
SOURCES_PHASE = pbxid("sources_phase")
FRAMEWORKS_PHASE = pbxid("frameworks_phase")
RESOURCES_PHASE = pbxid("resources_phase")

# Widget target IDs
WIDGET_PRODUCT_REF = pbxid("product_widget")
WIDGET_TARGET = pbxid("target_widget")
WIDGET_BUILD_CFG_DEBUG = pbxid("widget_build_debug")
WIDGET_BUILD_CFG_RELEASE = pbxid("widget_build_release")
WIDGET_BUILD_LIST = pbxid("widget_build_list")
WIDGET_SOURCES_PHASE = pbxid("widget_sources_phase")
WIDGET_FRAMEWORKS_PHASE = pbxid("widget_frameworks_phase")
WIDGET_RESOURCES_PHASE = pbxid("widget_resources_phase")
WIDGET_GROUP = pbxid("widget_group")

# Dependency IDs
TARGET_DEP = pbxid("target_dep_widget")
CONTAINER_PROXY = pbxid("container_proxy")

# Info.plist
APP_INFO_REF = pbxid("infoplist")
WIDGET_INFO_REF = pbxid("widget_infoplist")

lines = []
def emit(s=""):
    lines.append(s)
def t(n, s=""):
    lines.append("    " * n + s)

# ==============================
# 3. Header
# ==============================
emit("// !$*UTF8*$!")
emit("{")
t(1, "archiveVersion = 1;")
t(1, "classes = {};")
t(1, "objectVersion = 56;")
t(1, "objects = {")

# ==============================
# 4. PBXBuildFile (main app)
# ==============================
for f in app_files:
    t(2, f"{pbxid('bf_' + f)} = {{isa = PBXBuildFile; fileRef = {pbxid('fr_' + f)}; }};")

# ==============================
# 4b. PBXBuildFile (widget)
# ==============================
for f in widget_files:
    t(2, f"{pbxid('bf_' + f)} = {{isa = PBXBuildFile; fileRef = {pbxid('fr_' + f)}; }};")

# ==============================
# 5. PBXBuildFile (frameworks - app)
# ==============================
# No explicit framework refs needed for SwiftUI/Foundation - auto-linked

# ==============================
# 6. PBXFileReference (app sources)
# ==============================
for f in app_files:
    t(2, f"{pbxid('fr_' + f)} = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {q('TodoPomodoro/' + f)}; sourceTree = SOURCE_ROOT; }};")

# App Info.plist
t(2, f"{APP_INFO_REF} = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = TodoPomodoro/Info.plist; sourceTree = SOURCE_ROOT; }};")

# ==============================
# 7. PBXFileReference (widget)
# ==============================
for f in widget_files:
    t(2, f"{pbxid('fr_' + f)} = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {q('TodoPomodoro/' + f)}; sourceTree = SOURCE_ROOT; }};")

t(2, f"{WIDGET_INFO_REF} = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = TodoPomodoro/PomodoroWidget/Info.plist; sourceTree = SOURCE_ROOT; }};")

# ==============================
# 8. PBXFileReference (products)
# ==============================
t(2, f"{APP_PRODUCT_REF} = {{isa = PBXFileReference; explicitFileType = \"wrapper.application\"; includeInIndex = 0; path = TodoPomodoro.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
t(2, f"{WIDGET_PRODUCT_REF} = {{isa = PBXFileReference; explicitFileType = \"wrapper.app-extension\"; includeInIndex = 0; path = PomodoroWidget.appex; sourceTree = BUILT_PRODUCTS_DIR; }};")

# ==============================
# 9. PBXFrameworksBuildPhase (app)
# ==============================
t(2, f"{FRAMEWORKS_PHASE} = {{")
t(3, "isa = PBXFrameworksBuildPhase;")
t(3, "buildActionMask = 2147483647;")
t(3, "files = ();")
t(3, "runOnlyForDeploymentPostprocessing = 0;")
t(2, "};")

# ==============================
# 10. PBXFrameworksBuildPhase (widget)
# ==============================
t(2, f"{WIDGET_FRAMEWORKS_PHASE} = {{")
t(3, "isa = PBXFrameworksBuildPhase;")
t(3, "buildActionMask = 2147483647;")
t(3, "files = ();")
t(3, "runOnlyForDeploymentPostprocessing = 0;")
t(2, "};")

# ==============================
# 11. PBXGroup - Main
# ==============================
t(2, f"{MAIN_GROUP} = {{")
t(3, "isa = PBXGroup;")
t(3, "children = (")
t(4, f"{SOURCES_GROUP},")
t(4, f"{WIDGET_GROUP},")
t(4, f"{PRODUCTS_GROUP},")
t(3, ");")
t(3, "sourceTree = SOURCE_ROOT;")
t(2, "};")

# ==============================
# 12. PBXGroup - Sources
# ==============================
children = []
for f in app_files:
    children.append(pbxid('fr_' + f))
children.append(APP_INFO_REF)

t(2, f"{SOURCES_GROUP} = {{")
t(3, "isa = PBXGroup;")
t(3, "children = (")
for c in children:
    t(4, f"{c},")
t(3, ");")
t(3, "path = TodoPomodoro;")
t(3, "sourceTree = SOURCE_ROOT;")
t(2, "};")

# ==============================
# 13. PBXGroup - Widget
# ==============================
widget_children = []
for f in widget_files:
    widget_children.append(pbxid('fr_' + f))
widget_children.append(WIDGET_INFO_REF)

t(2, f"{WIDGET_GROUP} = {{")
t(3, "isa = PBXGroup;")
t(3, "children = (")
for c in widget_children:
    t(4, f"{c},")
t(3, ");")
t(3, "path = TodoPomodoro/PomodoroWidget;")
t(3, "sourceTree = SOURCE_ROOT;")
t(2, "};")

# ==============================
# 14. PBXGroup - Products
# ==============================
t(2, f"{PRODUCTS_GROUP} = {{")
t(3, "isa = PBXGroup;")
t(3, "children = (")
t(4, f"{APP_PRODUCT_REF},")
t(4, f"{WIDGET_PRODUCT_REF},")
t(3, ");")
t(3, "name = Products;")
t(3, "sourceTree = SOURCE_ROOT;")
t(2, "};")

# ==============================
# 15. PBXNativeTarget - App
# ==============================
t(2, f"{APP_TARGET} = {{")
t(3, "isa = PBXNativeTarget;")
t(3, "buildConfigurationList = {APP_BUILD_LIST};")
t(3, "buildPhases = (")
t(4, f"{SOURCES_PHASE},")
t(4, f"{FRAMEWORKS_PHASE},")
t(4, f"{RESOURCES_PHASE},")
t(3, ");")
t(3, "buildRules = ();")
t(3, "dependencies = (")
t(4, f"{TARGET_DEP},")
t(3, ");")
t(3, "name = TodoPomodoro;")
t(3, "productName = TodoPomodoro;")
t(3, "productReference = {APP_PRODUCT_REF};")
t(3, "productType = \"com.apple.product-type.application\";")
t(2, "};")

# ==============================
# 16. PBXNativeTarget - Widget Extension
# ==============================
t(2, f"{WIDGET_TARGET} = {{")
t(3, "isa = PBXNativeTarget;")
t(3, "buildConfigurationList = {WIDGET_BUILD_LIST};")
t(3, "buildPhases = (")
t(4, f"{WIDGET_SOURCES_PHASE},")
t(4, f"{WIDGET_FRAMEWORKS_PHASE},")
t(4, f"{WIDGET_RESOURCES_PHASE},")
t(3, ");")
t(3, "buildRules = ();")
t(3, "dependencies = ();")
t(3, "name = PomodoroWidget;")
t(3, "productName = PomodoroWidget;")
t(3, "productReference = {WIDGET_PRODUCT_REF};")
t(3, "productType = \"com.apple.product-type.app-extension\";")
t(2, "};")

# ==============================
# 17. PBXProject
# ==============================
t(2, f"{PROJECT_PBXID} = {{")
t(3, "isa = PBXProject;")
t(3, "buildConfigurationList = {APP_BUILD_LIST};")
t(3, "compatibilityVersion = \"Xcode 3.2\";")
t(3, "developmentRegion = zh-Hans;")
t(3, "hasScannedForEncodings = 0;")
t(3, "knownRegions = (")
t(4, "en, zh-Hans, Base")
t(3, ");")
t(3, "mainGroup = {MAIN_GROUP};")
t(3, "productRefGroup = {PRODUCTS_GROUP};")
t(3, "projectDirPath = \"\";")
t(3, "projectRoot = \"\";")
t(3, "targets = (")
t(4, f"{APP_TARGET},")
t(4, f"{WIDGET_TARGET},")
t(3, ");")
t(2, "};")

# ==============================
# 18. PBXResourcesBuildPhase (app)
# ==============================
t(2, f"{RESOURCES_PHASE} = {{")
t(3, "isa = PBXResourcesBuildPhase;")
t(3, "buildActionMask = 2147483647;")
t(3, "files = ();")
t(3, "runOnlyForDeploymentPostprocessing = 0;")
t(2, "};")

# ==============================
# 19. PBXResourcesBuildPhase (widget)
# ==============================
t(2, f"{WIDGET_RESOURCES_PHASE} = {{")
t(3, "isa = PBXResourcesBuildPhase;")
t(3, "buildActionMask = 2147483647;")
t(3, "files = ();")
t(3, "runOnlyForDeploymentPostprocessing = 0;")
t(2, "};")

# ==============================
# 20. PBXSourcesBuildPhase (app)
# ==============================
t(2, f"{SOURCES_PHASE} = {{")
t(3, "isa = PBXSourcesBuildPhase;")
t(3, "buildActionMask = 2147483647;")
t(3, "files = (")
for f in app_files:
    t(4, f"{pbxid('bf_' + f)},")
t(3, ");")
t(3, "runOnlyForDeploymentPostprocessing = 0;")
t(2, "};")

# ==============================
# 21. PBXSourcesBuildPhase (widget)
# ==============================
t(2, f"{WIDGET_SOURCES_PHASE} = {{")
t(3, "isa = PBXSourcesBuildPhase;")
t(3, "buildActionMask = 2147483647;")
t(3, "files = (")
for f in widget_files:
    t(4, f"{pbxid('bf_' + f)},")
t(3, ");")
t(3, "runOnlyForDeploymentPostprocessing = 0;")
t(2, "};")

# ==============================
# 22. XCBuildConfiguration - App Debug
# ==============================
t(2, f"{APP_BUILD_CFG_DEBUG} = {{")
t(3, "isa = XCBuildConfiguration;")
t(3, "buildSettings = {")
t(4, "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;")
t(4, "CLANG_ENABLE_MODULES = YES;")
t(4, "CLANG_ENABLE_OBJC_ARC = YES;")
t(4, "CODE_SIGN_STYLE = Automatic;")
t(4, "CURRENT_PROJECT_VERSION = 1;")
t(4, "ENABLE_PREVIEWS = YES;")
t(4, "GENERATE_INFOPLIST_FILE = NO;")
t(4, "INFOPLIST_FILE = TodoPomodoro/Info.plist;")
t(4, "INFOPLIST_KEY_CFBundleDisplayName = \"王不更 · 番茄Todo\";")
t(4, "INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;")
t(4, "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;")
t(4, "INFOPLIST_KEY_UILaunchScreen_Generation = YES;")
t(4, "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = \"UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortraitUpsideDown\";")
t(4, "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = \"UIInterfaceOrientationPortrait\";")
t(4, "IPHONEOS_DEPLOYMENT_TARGET = 17.0;")
t(4, "LD_RUNPATH_SEARCH_PATHS = (")
t(5, "\"$(inherited)\",")
t(5, "\"@executable_path/Frameworks\",")
t(4, ");")
t(4, "MARKETING_VERSION = 1.0;")
t(4, "PRODUCT_BUNDLE_IDENTIFIER = com.todopomodoro.app;")
t(4, "PRODUCT_NAME = TodoPomodoro;")
t(4, "SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\";")
t(4, "SWIFT_EMIT_LOC_STRINGS = YES;")
t(4, "SWIFT_VERSION = 5.0;")
t(4, "TARGETED_DEVICE_FAMILY = \"1,2\";")
t(3, "};")
t(3, "name = Debug;")
t(2, "};")

# ==============================
# 23. XCBuildConfiguration - App Release
# ==============================
t(2, f"{APP_BUILD_CFG_RELEASE} = {{")
t(3, "isa = XCBuildConfiguration;")
t(3, "buildSettings = {")
t(4, "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;")
t(4, "CLANG_ENABLE_MODULES = YES;")
t(4, "CLANG_ENABLE_OBJC_ARC = YES;")
t(4, "CODE_SIGN_STYLE = Automatic;")
t(4, "CURRENT_PROJECT_VERSION = 1;")
t(4, "ENABLE_PREVIEWS = YES;")
t(4, "GENERATE_INFOPLIST_FILE = NO;")
t(4, "INFOPLIST_FILE = TodoPomodoro/Info.plist;")
t(4, "INFOPLIST_KEY_CFBundleDisplayName = \"王不更 · 番茄Todo\";")
t(4, "INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;")
t(4, "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;")
t(4, "INFOPLIST_KEY_UILaunchScreen_Generation = YES;")
t(4, "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = \"UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortraitUpsideDown\";")
t(4, "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = \"UIInterfaceOrientationPortrait\";")
t(4, "IPHONEOS_DEPLOYMENT_TARGET = 17.0;")
t(4, "LD_RUNPATH_SEARCH_PATHS = (")
t(5, "\"$(inherited)\",")
t(5, "\"@executable_path/Frameworks\",")
t(4, ");")
t(4, "MARKETING_VERSION = 1.0;")
t(4, "PRODUCT_BUNDLE_IDENTIFIER = com.todopomodoro.app;")
t(4, "PRODUCT_NAME = TodoPomodoro;")
t(4, "SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\";")
t(4, "SWIFT_EMIT_LOC_STRINGS = YES;")
t(4, "SWIFT_VERSION = 5.0;")
t(4, "TARGETED_DEVICE_FAMILY = \"1,2\";")
t(3, "};")
t(3, "name = Release;")
t(2, "};")

# ==============================
# 24. XCBuildConfiguration - Widget Debug
# ==============================
t(2, f"{WIDGET_BUILD_CFG_DEBUG} = {{")
t(3, "isa = XCBuildConfiguration;")
t(3, "buildSettings = {")
t(4, "APPLICATION_EXTENSION_API_ONLY = YES;")
t(4, "CLANG_ENABLE_MODULES = YES;")
t(4, "CLANG_ENABLE_OBJC_ARC = YES;")
t(4, "CODE_SIGN_STYLE = Automatic;")
t(4, "CURRENT_PROJECT_VERSION = 1;")
t(4, "GENERATE_INFOPLIST_FILE = NO;")
t(4, "INFOPLIST_FILE = TodoPomodoro/PomodoroWidget/Info.plist;")
t(4, "IPHONEOS_DEPLOYMENT_TARGET = 17.0;")
t(4, "LD_RUNPATH_SEARCH_PATHS = (")
t(5, "\"$(inherited)\",")
t(5, "\"@executable_path/Frameworks\",")
t(5, "\"@executable_path/../../Frameworks\",")
t(4, ");")
t(4, "MARKETING_VERSION = 1.0;")
t(4, "PRODUCT_BUNDLE_IDENTIFIER = com.todopomodoro.app.PomodoroWidget;")
t(4, "PRODUCT_NAME = PomodoroWidget;")
t(4, "SKIP_INSTALL = YES;")
t(4, "SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\";")
t(4, "SWIFT_EMIT_LOC_STRINGS = YES;")
t(4, "SWIFT_VERSION = 5.0;")
t(4, "TARGETED_DEVICE_FAMILY = \"1,2\";")
t(3, "};")
t(3, "name = Debug;")
t(2, "};")

# ==============================
# 25. XCBuildConfiguration - Widget Release
# ==============================
t(2, f"{WIDGET_BUILD_CFG_RELEASE} = {{")
t(3, "isa = XCBuildConfiguration;")
t(3, "buildSettings = {")
t(4, "APPLICATION_EXTENSION_API_ONLY = YES;")
t(4, "CLANG_ENABLE_MODULES = YES;")
t(4, "CLANG_ENABLE_OBJC_ARC = YES;")
t(4, "CODE_SIGN_STYLE = Automatic;")
t(4, "CURRENT_PROJECT_VERSION = 1;")
t(4, "GENERATE_INFOPLIST_FILE = NO;")
t(4, "INFOPLIST_FILE = TodoPomodoro/PomodoroWidget/Info.plist;")
t(4, "IPHONEOS_DEPLOYMENT_TARGET = 17.0;")
t(4, "LD_RUNPATH_SEARCH_PATHS = (")
t(5, "\"$(inherited)\",")
t(5, "\"@executable_path/Frameworks\",")
t(5, "\"@executable_path/../../Frameworks\",")
t(4, ");")
t(4, "MARKETING_VERSION = 1.0;")
t(4, "PRODUCT_BUNDLE_IDENTIFIER = com.todopomodoro.app.PomodoroWidget;")
t(4, "PRODUCT_NAME = PomodoroWidget;")
t(4, "SKIP_INSTALL = YES;")
t(4, "SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\";")
t(4, "SWIFT_EMIT_LOC_STRINGS = YES;")
t(4, "SWIFT_VERSION = 5.0;")
t(4, "TARGETED_DEVICE_FAMILY = \"1,2\";")
t(3, "};")
t(3, "name = Release;")
t(2, "};")

# ==============================
# 26. XCConfigurationList - App
# ==============================
t(2, f"{APP_BUILD_LIST} = {{")
t(3, "isa = XCConfigurationList;")
t(3, "buildConfigurations = (")
t(4, f"{APP_BUILD_CFG_DEBUG},")
t(4, f"{APP_BUILD_CFG_RELEASE},")
t(3, ");")
t(3, "defaultConfigurationIsVisible = 0;")
t(3, "defaultConfigurationName = Release;")
t(2, "};")

# ==============================
# 27. XCConfigurationList - Widget
# ==============================
t(2, f"{WIDGET_BUILD_LIST} = {{")
t(3, "isa = XCConfigurationList;")
t(3, "buildConfigurations = (")
t(4, f"{WIDGET_BUILD_CFG_DEBUG},")
t(4, f"{WIDGET_BUILD_CFG_RELEASE},")
t(3, ");")
t(3, "defaultConfigurationIsVisible = 0;")
t(3, "defaultConfigurationName = Release;")
t(2, "};")

# ==============================
# 28. PBXTargetDependency
# ==============================
t(2, f"{TARGET_DEP} = {{")
t(3, "isa = PBXTargetDependency;")
t(3, "target = {WIDGET_TARGET};")
t(3, "targetProxy = {CONTAINER_PROXY};")
t(2, "};")

# ==============================
# 29. PBXContainerItemProxy
# ==============================
t(2, f"{CONTAINER_PROXY} = {{")
t(3, "isa = PBXContainerItemProxy;")
t(3, "containerPortal = {PROJECT_PBXID};")
t(3, "proxyType = 1;")
t(3, "remoteGlobalIDString = {WIDGET_TARGET};")
t(3, "remoteInfo = PomodoroWidget;")
t(2, "};")

# ==============================
# 30. Close
# ==============================
t(2, "};")  # close objects
t(1, f"rootObject = {PROJECT_PBXID};")
emit("}")

# Replace {PLACEHOLDER}s with actual IDs
content = "\n".join(lines)
for key, val in {
    '{APP_BUILD_LIST}': APP_BUILD_LIST,
    '{APP_PRODUCT_REF}': APP_PRODUCT_REF,
    '{WIDGET_BUILD_LIST}': WIDGET_BUILD_LIST,
    '{WIDGET_PRODUCT_REF}': WIDGET_PRODUCT_REF,
    '{CONTAINER_PROXY}': CONTAINER_PROXY,
    '{MAIN_GROUP}': MAIN_GROUP,
    '{PRODUCTS_GROUP}': PRODUCTS_GROUP,
    '{PROJECT_PBXID}': PROJECT_PBXID,
    '{WIDGET_TARGET}': WIDGET_TARGET,
}.items():
    content = content.replace(key, val)

# Write
out_path = os.path.join(ROOT, "TodoPomodoro.xcodeproj", "project.pbxproj")
os.makedirs(os.path.dirname(out_path), exist_ok=True)
with open(out_path, "w") as f:
    f.write(content)

size = len(content.encode('utf-8'))
lines_count = len(content.splitlines())
print(f"✅ Generated: {size} bytes, {lines_count} lines")

# Write .xcscheme
scheme_dir = os.path.join(ROOT, "TodoPomodoro.xcodeproj", "xcshareddata", "xcschemes")
os.makedirs(scheme_dir, exist_ok=True)
scheme_content = '''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1610"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "''' + APP_TARGET + '''"
               BuildableName = "TodoPomodoro.app"
               BlueprintName = "TodoPomodoro"
               ReferencedContainer = "container:TodoPomodoro.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "''' + APP_TARGET + '''"
            BuildableName = "TodoPomodoro.app"
            BlueprintName = "TodoPomodoro"
            ReferencedContainer = "container:TodoPomodoro.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "''' + APP_TARGET + '''"
            BuildableName = "TodoPomodoro.app"
            BlueprintName = "TodoPomodoro"
            ReferencedContainer = "container:TodoPomodoro.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>'''
scheme_path = os.path.join(scheme_dir, "TodoPomodoro.xcscheme")
with open(scheme_path, "w") as f:
    f.write(scheme_content)
print(f"✅ Scheme: {scheme_path}")
