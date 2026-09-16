#!/usr/bin/env python3
"""Generate the small, dependency-free Xcode project from the checked-in sources."""
from pathlib import Path
import hashlib
import json
import plistlib

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / 'CrocoCross.xcodeproj'
PROJECT.mkdir(exist_ok=True)
objects = {}

def key(label):
    return hashlib.sha1(label.encode()).hexdigest()[:24].upper()

def add(label, isa, **fields):
    ident = key(label)
    objects[ident] = dict(isa=isa, **fields)
    return ident

def ref(path, kind):
    return add('ref:' + path, 'PBXFileReference', lastKnownFileType=kind, path=path, sourceTree='SOURCE_ROOT')

def built(path, ident):
    return add('build:' + path, 'PBXBuildFile', fileRef=ident)

def configurations(label, values):
    configs = []
    for name in ('Debug', 'Release'):
        settings = dict(values)
        settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone' if name == 'Debug' else '-O'
        settings['ONLY_ACTIVE_ARCH'] = 'YES' if name == 'Debug' else 'NO'
        if name == 'Debug': settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG'
        configs.append(add(label + ':' + name, 'XCBuildConfiguration', name=name, buildSettings=settings))
    return add(label + ':list', 'XCConfigurationList', buildConfigurations=configs, defaultConfigurationIsVisible=0, defaultConfigurationName='Release')

source_refs, source_builds = [], []
for path in sorted((ROOT / 'App').rglob('*.swift')):
    rel = str(path.relative_to(ROOT))
    ident = ref(rel, 'sourcecode.swift'); source_refs.append(ident); source_builds.append(built(rel, ident))

resource_refs, resource_builds = [], []
for path, kind in [('App/Resources/GameAssets', 'folder'), ('App/Resources/Assets.xcassets', 'folder.assetcatalog'), ('App/Resources/box2d-license.txt', 'text'), ('App/PrivacyInfo.xcprivacy', 'text.xml')]:
    ident = ref(path, kind); resource_refs.append(ident); resource_builds.append(built(path, ident))

core_ref = add('core:package', 'XCLocalSwiftPackageReference', relativePath='.')
core_product = add('core:product', 'XCSwiftPackageProductDependency', productName='CrocoCrossCore')
core_build = add('core:link', 'PBXBuildFile', productRef=core_product)
app_product = add('app:product', 'PBXFileReference', explicitFileType='wrapper.application', path='CrocoCross.app', sourceTree='BUILT_PRODUCTS_DIR')
test_product = add('test:product', 'PBXFileReference', explicitFileType='wrapper.cfbundle', path='CrocoCrossUITests.xctest', sourceTree='BUILT_PRODUCTS_DIR')

common = {
    'IPHONEOS_DEPLOYMENT_TARGET': '18.0', 'SDKROOT': 'iphoneos', 'SWIFT_VERSION': '6.0',
    'CLANG_ENABLE_MODULES': 'YES', 'CLANG_ENABLE_OBJC_ARC': 'YES', 'ENABLE_STRICT_OBJC_MSGSEND': 'YES',
    'GCC_WARN_UNDECLARED_SELECTOR': 'YES', 'GCC_WARN_UNINITIALIZED_AUTOS': 'YES_AGGRESSIVE',
    'CLANG_WARN_DOCUMENTATION_COMMENTS': 'YES', 'CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER': 'YES',
    'SWIFT_STRICT_CONCURRENCY': 'complete', 'DEBUG_INFORMATION_FORMAT': 'dwarf-with-dsym',
    'ENABLE_TESTABILITY': 'YES',
}
app_settings = {
    'PRODUCT_BUNDLE_IDENTIFIER': 'com.daviddemri.crococross', 'PRODUCT_NAME': '$(TARGET_NAME)',
    'CODE_SIGN_STYLE': 'Automatic', 'DEVELOPMENT_TEAM': '57XAAX65VC',
    'CODE_SIGN_ENTITLEMENTS': 'App/CrocoCross.entitlements', 'INFOPLIST_FILE': 'App/Info.plist',
    'TARGETED_DEVICE_FAMILY': '1,2', 'SUPPORTED_PLATFORMS': 'iphoneos iphonesimulator',
    'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon', 'MARKETING_VERSION': '1.0.0',
    'CURRENT_PROJECT_VERSION': '9', 'LD_RUNPATH_SEARCH_PATHS': '$(inherited) @executable_path/Frameworks',
    'SUPPORTS_MACCATALYST': 'NO', 'SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD': 'NO',
    'SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD': 'NO', 'GENERATE_INFOPLIST_FILE': 'NO',
}
app_target = add('app:target', 'PBXNativeTarget', name='CrocoCross', productName='CrocoCross',
    productReference=app_product, productType='com.apple.product-type.application',
    buildConfigurationList=configurations('app:config', app_settings),
    buildPhases=[add('app:sources','PBXSourcesBuildPhase',buildActionMask=2147483647,files=source_builds,runOnlyForDeploymentPostprocessing=0),
                 add('app:frameworks','PBXFrameworksBuildPhase',buildActionMask=2147483647,files=[core_build],runOnlyForDeploymentPostprocessing=0),
                 add('app:resources','PBXResourcesBuildPhase',buildActionMask=2147483647,files=resource_builds,runOnlyForDeploymentPostprocessing=0)],
    buildRules=[], dependencies=[], packageProductDependencies=[core_product])

test_refs, test_builds = [], []
for path in sorted((ROOT / 'UITests').glob('*.swift')):
    rel = str(path.relative_to(ROOT)); ident = ref(rel,'sourcecode.swift'); test_refs.append(ident); test_builds.append(built(rel,ident))
proxy = add('test:proxy','PBXContainerItemProxy',containerPortal=key('project'),proxyType=1,remoteGlobalIDString=app_target,remoteInfo='CrocoCross')
dependency = add('test:dependency','PBXTargetDependency',target=app_target,targetProxy=proxy)
test_target = add('test:target','PBXNativeTarget',name='CrocoCrossUITests',productName='CrocoCrossUITests',productReference=test_product,
    productType='com.apple.product-type.bundle.ui-testing',buildConfigurationList=configurations('test:config',{
        'PRODUCT_BUNDLE_IDENTIFIER':'com.daviddemri.crococross.uitests','PRODUCT_NAME':'$(TARGET_NAME)',
        'GENERATE_INFOPLIST_FILE':'YES','TEST_TARGET_NAME':'CrocoCross','TARGETED_DEVICE_FAMILY':'1,2',
        'CODE_SIGN_STYLE':'Automatic','DEVELOPMENT_TEAM':'57XAAX65VC',
    }),buildPhases=[add('test:sources','PBXSourcesBuildPhase',buildActionMask=2147483647,files=test_builds,runOnlyForDeploymentPostprocessing=0),
        add('test:frameworks','PBXFrameworksBuildPhase',buildActionMask=2147483647,files=[],runOnlyForDeploymentPostprocessing=0)],
    buildRules=[],dependencies=[dependency])
products = add('products','PBXGroup',children=[app_product,test_product],name='Products',sourceTree='<group>')
main_group = add('main','PBXGroup',children=[
    add('sources','PBXGroup',children=source_refs,name='App',sourceTree='<group>'),
    add('resources','PBXGroup',children=resource_refs,name='Resources',sourceTree='<group>'),
    add('tests','PBXGroup',children=test_refs,name='UI Tests',sourceTree='<group>'),products],sourceTree='<group>')
project = add('project','PBXProject',attributes={'BuildIndependentTargetsInParallel':'YES','LastUpgradeCheck':'2600'},
    buildConfigurationList=configurations('project:config',common),compatibilityVersion='Xcode 15.0',
    developmentRegion='en',hasScannedForEncodings=0,knownRegions=['en','Base'],mainGroup=main_group,
    packageReferences=[core_ref],productRefGroup=products,projectDirPath='',projectRoot='',targets=[app_target,test_target])

def pbx(value, level=0):
    if isinstance(value, dict):
        return '{\n' + ''.join('\t'*(level+1)+json.dumps(k)+' = '+pbx(v,level+1)+';\n' for k,v in value.items()) + '\t'*level+'}'
    if isinstance(value,list): return '(' + ', '.join(pbx(v,level) for v in value) + ')'
    if isinstance(value,int): return str(value)
    return json.dumps(value)

document = dict(archiveVersion=1,classes={},objectVersion=60,objects=objects,rootObject=project)
(PROJECT/'project.pbxproj').write_text('// !$*UTF8*$!\n'+pbx(document)+'\n')
schemes=PROJECT/'xcshareddata/xcschemes'; schemes.mkdir(parents=True,exist_ok=True)
def buildable(target, name, product):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="{product}" BlueprintName="{name}" ReferencedContainer="container:CrocoCross.xcodeproj"/>'
app=buildable(app_target,'CrocoCross','CrocoCross.app'); test=buildable(test_target,'CrocoCrossUITests','CrocoCrossUITests.xctest')
(schemes/'CrocoCross.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
  <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{app}</BuildActionEntry>
 </BuildActionEntries></BuildAction>
 <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB"><Testables><TestableReference skipped="NO">{test}</TestableReference></Testables></TestAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app}</BuildableProductRunnable></LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app}</BuildableProductRunnable></ProfileAction>
 <AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print(f'Generated {PROJECT.name}: {len(source_refs)} Swift files, {len(test_refs)} UI test files')
