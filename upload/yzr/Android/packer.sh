target=Android
configPath=yzr3CN
directory=yzr3CN-Packer
gitPath=client
git_tag=cn-0613
server_tag=cn-AndroidHubTest
res_version=1.2004.125
apkName=yzr3CN
apk_path=$(pwd)
isXianF=false
BundleVersionCode=627

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
keyAliasName=$(basename $keystore_name)
keyAliasPasswd="123456"

log_file=$(pwd)/pack.log

rm -rf $gitPath
#cp -R ~/Unity/origin/pbex-client-0429 pbex-client
#cp -R ~/Unity/origin/Library-ex-${target} pbex-client/Client/Library

git clone -b "$git_tag" http://oauth2:glpat-V87fyuuGqxxnsgjTwcqZ@git.pbex.s-game.cn/pbex/Yzr3CN.git $gitPath --depth 1 > git.log

cp -af ${localBackupPath}/Library ${gitPath}/Client/

sshpass -p "$sGameHubPasswd" rsync -arPzO --delete -e "ssh -p 22" --chmod=ugo=rwx $sGameHubAccount@192.168.0.200:$rsyncLibraryPath/Library $gitPath/Client/ > rsync_local.log

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

#build apk
method_name="Model.BuildGames.BuildHero"
build_options="BuildOptions.None"
custom_args="productPath=$apk_path#productName=$apkName#keystoreName=$keystore_name#keystorePass=$keystore_pass#keyaliasName=$keyAliasName#keyaliasPass=$keyAliasPasswd#buildOptions=$build_options#versionCode=$BundleVersionCode#xianfeng=$isXianF#buildVersion=$res_version"
"$unity_path" -batchmode -nographics -quit -logFile "$log_file" -projectPath "$gitPath/Client" -executeMethod $method_name -CustomArgs "$custom_args"

endTime=$(date +%s)
take=$(( endTime - startTime ))
echo Time taken to execute commands is ${take} seconds.