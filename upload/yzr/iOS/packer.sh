buildValue=1

target=iOS
echo ${target}

gitPath=client
configPath=yzr3CN

sGameHubAccount=uploader
sGameHubPasswd="RM1k-ys["
localBackupPath=~/jenkinsBuild/backup/${configPath}/Library/${target}
rsyncLibraryPath=/volume1/web/packer/${configPath}/Library/${target}

mkdir -p $localBackupPath/Library

startTime=$(date +%s)

buildPath=~/jenkinsBuild/${directory}

rm -rf "$buildPath"
mkdir -p "$buildPath"

cd "$buildPath" || exit

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

unity_path=/Applications/Unity/Unity.app/Contents/MacOS/Unity
keystore_name="${gitPath}/Client/Build/com.sgame.ex.keystore"
keystore_pass="123456"
keyAliasName=`basename $keystore_name`
keyAliasPasswd="123456"

rm -rf $gitPath

git clone -b "$git_tag" http://oauth2:glpat-V87fyuuGqxxnsgjTwcqZ@git.pbex.s-game.cn/pbex/Yzr3CN.git $gitPath --depth 1 > git.log
cp -af ${localBackupPath}/Library ${gitPath}/Client/
sshpass -p "$sGameHubPasswd" rsync -arPzO --delete -e "ssh -p 22" --chmod=ugo=rwx $sGameHubAccount@192.168.0.200:$rsyncLibraryPath/Library $gitPath/Client/ > rsync_local.log

log_file=$(pwd)/pack.log
gen_path="${gitPath}/Client/Assets/Xlua/Gen"

rm -rf $gen_path
rm -f "$log_file"

# replace /Assets/Resources/ServerTag.txt
rm -f "$gitPath/Client/Assets/Resources/serverTag.txt"
echo "${server_tag}" >> "$gitPath/Client/Assets/Resources/serverTag.txt"
cat "$gitPath/Client/Assets/Resources/serverTag.txt"

#build_assets
method_name="AssetBuild.AssetBuildTools.BuildAssetBundleSh"
custom_args="buildVersion=${res_version}"
$unity_path -batchmode -nographics -quit -logFile "$log_file" -projectPath $gitPath/Client -executeMethod $method_name -CustomArgs $custom_args -buildTarget $target

#build xcode
method_name="Model.BuildGames.BuildiOS"
xcode_path=$(pwd)/xcode
xcode_name="Unity-iPhone"

build_options="BuildOptions.None"
custom_args="productPath=$xcode_path#productName=$xcode_name#keystoreName=$keystore_name#keystorePass=$keystore_pass#keyaliasName=$keyAliasName#keyaliasPass=$keyAliasPasswd#buildOptions=$build_options#versionCode=$buildValue#buildVersion=$res_version"
"$unity_path" -batchmode -nographics -quit -logFile "$log_file" -projectPath "$gitPath/Client" -executeMethod $method_name -CustomArgs "$custom_args" -buildTarget ${target}

wget https://nasload.s-game.cn/packer/yzr3CN/pbxproj

chmod +x pbxproj && ./pbxproj

# build archive
xcode_log_file=$(pwd)/xcode_pack.log

scheme_name=Unity-iPhone
project_name=${xcode_path}/${xcode_name}
build_configuration=Release
export_archive_path=$(pwd)/${scheme_name}.xcarchive

xcodebuild clean -workspace "${project_name}/${scheme_name}.xcworkspace" -scheme ${scheme_name} -configuration ${build_configuration}

security unlock-keychain -p "123456"
xcodebuild archive -workspace "${project_name}/${scheme_name}.xcworkspace" -scheme ${scheme_name} -configuration ${build_configuration} -archivePath ${export_archive_path} -destination 'generic/platform=iOS' >> "${xcode_log_file}"
