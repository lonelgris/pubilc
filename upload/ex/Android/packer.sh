target=Android
echo ${target}

sGameHubAccount=uploader
sGameHubPasswd="RM1k-ys["
localBackupPath=~/jenkinsBuild/backup/yzr3Ex/Library/${target}
rsyncLibraryPath=/volume1/web/packer/yzr3Ex/Library/${target}

mkdir -p localBackupPath

startTime=$(date +%s)

buildPath=~/jenkinsBuild/${directory}

rm -rf "$buildPath"
mkdir -p "$buildPath"

cd "$buildPath" || exit

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

unity_path=/Applications/Unity/Unity.app/Contents/MacOS/Unity
client_path=$(pwd)/pbex-client/Client
echo $client_path

apk_final_Name="PhantomBladeEX"
save_apk_path=$(pwd)
keystore_name=${client_path}"/Build/PBEX.keystore"
keystore_pass="pbex2022217!"
keyalias_name="pbexkey"
keyalias_pass="yzr2022."
build_options="BuildOptions.None"
playerSetting_companyName="S-Game"
playerSetting_productName=""
playerSetting_version=$Version
playerSetting_identifier=""
build_value=$Build
is_vietnam=false
is_jp=false
B_versionCode=$BundleVersionCode

log_file=$(pwd)/pack.log
echo $log_file

rm -rf pbex-client
#cp -R ~/Unity/origin/pbex-client-0429 pbex-client
#cp -R ~/Unity/origin/Library-ex-${target} pbex-client/Client/Library

git clone -b "$git_tag" http://oauth2:glpat-V87fyuuGqxxnsgjTwcqZ@git.pbex.s-game.cn/pbex/pbex-client.git --depth 1

cp -af ${localBackupPath}/Library pbex-client/Client/

sshpass -p $sGameHubPasswd rsync -arPzO --delete -e "ssh -p 22" --chmod=ugo=rwx $sGameHubAccount@192.168.0.200:$rsyncLibraryPath/Library pbex-client/Client/ >>rsync_local.log

gen_path=$client_path"/Assets/Xlua/Gen"

rm -rf $gen_path
rm -f $log_file

# replace /Assets/Resources/ServerTag.txt
rm -f $client_path"/Assets/Resources/serverTag.txt"
echo "${server_tag}" >> $client_path"/Assets/Resources/serverTag.txt"
cat $client_path"/Assets/Resources/serverTag.txt"

# add firebase definesymbols
custom_args="channelType="$channel_type
method_name="Model.BuildGames.SetFirebaseDefineSymbols"
echo $method_name
echo $custom_args
"$unity_path" -batchmode -quit -logFile "$log_file" -projectPath "$client_path" -executeMethod "$method_name" -CustomArgs "$custom_args" -buildTarget ${target}

# pack addressable data
custom_args="resVersion="$res_version
method_name="Model.BuildGames.OnHybridCLRGenerateAll"
echo $method_name
echo $custom_args
"$unity_path" -batchmode -quit -logFile "$log_file" -projectPath "$client_path" -executeMethod "$method_name" -CustomArgs "$custom_args" -buildTarget ${target}

buildAab=false
if [ "$channel_type" = "GooglePlay" ];then
	buildAab=true
fi
echo "buildAab = $buildAab"

# build apk
method_name="Model.BuildGames.BuildEx"
custom_args="productPath=$save_apk_path#productName=$apk_final_Name#keystoreName=$keystore_name#keystorePass=$keystore_pass#keyaliasName=$keyalias_name#keyaliasPass=$keyalias_pass#buildOptions=$build_options#CompanyName=$playerSetting_companyName#ProductName=$playerSetting_productName#Version=$playerSetting_version#Identifier=$playerSetting_identifier#B_buildAab=$buildAab#versionCode=$B_versionCode#channelType=$channel_type#isVietnam=$is_vietnam#isJP=$is_jp#resVersion=$res_version"

echo $method_name
echo $custom_args
"$unity_path" -batchmode -quit -logFile "$log_file" -projectPath "$client_path" -executeMethod "$method_name" -CustomArgs "$custom_args" -buildTarget ${target}

endTime=$(date +%s)
take=$(( endTime - startTime ))
echo Time taken to execute commands is ${take} seconds.


#上传脚本
time=$(date "+%Y%m%d-%H%M%S")

discordUrl=https://discord.com/api/webhooks/1075323981193826354/rCJrCgDxYIV3E-gpuhh6F8zh8smCnev9Tguil9flnMaI2fVMNTwbp2fYEh0yAwcWsDIX
robotThread=1075322890276319232
discordUserName=${directory}_packer_$time #discord 显示用
gitPath=pbex-client
#git_tag 对应本次执行tag
#execTime 执行时间
#sGameHubAccount 上传hub 账号
#sGameHubPasswd 上传hub 密码
localPath=upload #本地上传用文件夹 一般不需要改
uploadFile=${apk_final_Name}.apk
fileHubPath=packer/yzr3Ex/apk
uploadFileNewName=ipa_${directory}_${time}.apk

if [ "$channel_type" = "GooglePlay" ];then
uploadFile=${apk_final_Name}.aab
fileHubPath=packer/yzr3Ex/aab
uploadFileNewName=ipa_${directory}_${time}.aab
fi

if [ -f $uploadFile ];then
	echo "开始文件上传"
else
	echo "文件不存在"
	exit
fi

rm -rf $localPath
mkdir $localPath

cp $uploadFile $localPath/"$uploadFileNewName"
sshpass -p $sGameHubPasswd rsync -a --append --delete -m -P -r -e "ssh -p 22" --chmod=ugo=rwx $localPath/"$uploadFileNewName" \
$sGameHubAccount@192.168.0.200:/volume1/web/$fileHubPath

downloadUrl==https://nasload.s-game.cn/"$fileHubPath"/"$uploadFileNewName"
wget https://nasload.s-game.cn/packer/qrCode
qrPath=$localPath/qr_$time.png
chmod +x qrCode && ./qrCode --url="$downloadUrl" --path="$qrPath"

wget https://nasload.s-game.cn/packer/discordSender
chmod +x discordSender && ./discordSender --discordUrl=$discordUrl --robotThread="$robotThread" --userName="$discordUserName" --execTime="$take second" \
--gitTag="$git_tag" --gitPath=$gitPath --pngPath="$qrPath"

sshpass -p "$sGameHubPasswd" rsync -arPzO --delete -e "ssh -p 22" --chmod=ugo=rwx pbex-client/Client/Library \
$sGameHubAccount@192.168.0.200:$rsyncLibraryPath/ >> rsync_remote.log

cp -af pbex-client/Client/Library ${localBackupPath}/


if [ "$isClean" == "true" ];
then
    rm -rf "$buildPath"
fi

