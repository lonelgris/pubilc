target=iOS
echo ${target}

gitPath=pbex-client
configPath=yzr3Ex

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

git clone -b "$git_tag" http://oauth2:glpat-V87fyuuGqxxnsgjTwcqZ@git.pbex.s-game.cn/pbex/pbex-client.git $gitPath --depth 1
cp -af ${localBackupPath}/Library $gitPath/Client/
sshpass -p "$sGameHubPasswd" rsync -arPzO --delete -e 'ssh -p 22' --chmod=ugo=rwx $sGameHubAccount@192.168.0.200:$rsyncLibraryPath/Library $gitPath/Client/ >>rsync_local.log

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

unity_path=/Applications/Unity/Unity.app/Contents/MacOS/Unity
client_path=$(pwd)/pbex-client/Client

xcode_path=$(pwd)/xcode
build_options="BuildOptions.None"
playerSetting_companyName="S-Game"
playerSetting_productName="Phantom Blade EX"
playerSetting_version=$Version
cur_channel="AppleStore"
build_value=$Build
is_vietnam=false
is_jp=false
final_product_name="${server_tag}_${cur_channel}_${playerSetting_version//./-}"

log_file=$(pwd)/pack.log
echo $log_file

target=iOS
echo ${target}

#rm -rf pbex-client
#cp -R ~/Unity/origin/pbex-client-0429 pbex-client
#cp -R ~/Unity/origin/Library-ex-${target} pbex-client/Client/Library

gen_path=$client_path"/Assets/Xlua/Gen"

rm -rf $gen_path
rm -f $log_file

custom_args="resVersion="$res_version


# copy m1 xlua.bundle
rm -rf ${client_path}/Assets/Plugins/xlua.bundle
rm -f ${client_path}/Assets/Plugins/xlua.bundle.meta
cp -R $(pwd)/pbex-client/Bundle/xluadll/ ${client_path}/Assets/Plugins/

# replace /Assets/Resources/ServerTag.txt
rm -f $client_path"/Assets/Resources/serverTag.txt"
echo "${server_tag}" >> $client_path"/Assets/Resources/serverTag.txt"
cat $client_path"/Assets/Resources/serverTag.txt"

# pack addressable data
method_name="Model.BuildGames.OnHybridCLRGenerateAll"
"$unity_path" -batchmode -quit -logFile "$log_file" -projectPath "$client_path" -executeMethod "$method_name" -CustomArgs "$custom_args" -buildTarget ${target}

# build xcode
method_name="Model.BuildGames.BuildiOS"
custom_args="productPath=${xcode_path}#productName=${final_product_name}#buildOptions=${build_options}#CompanyName=$playerSetting_companyName#ProductName=$playerSetting_productName#Version=$playerSetting_version#channelType=${cur_channel}#buildValue=${build_value}#isVietnam=$is_vietnam#isJP=$is_jp#resVersion=$res_version"
"$unity_path" -batchmode -quit -logFile "$log_file" -projectPath "$client_path" -executeMethod "$method_name" -CustomArgs "$custom_args" -buildTarget ${target}

# build archive
scheme_name=Unity-iPhone
project_name=${xcode_path}/${final_product_name}
build_configuration=Release
export_archive_path=$(pwd)/${scheme_name}.xcarchive
export_ipa_path=$(pwd)

xcodebuild clean -workspace ${project_name}/${scheme_name}.xcworkspace -scheme ${scheme_name} -configuration ${build_configuration}

security unlock-keychain -p "123456"
xcodebuild archive -workspace ${project_name}/${scheme_name}.xcworkspace -scheme ${scheme_name} -configuration ${build_configuration} -archivePath ${export_archive_path} -destination 'generic/platform=iOS' >> xcworkspace.log

# build ipa

rm -f ExportOptions.plist
cat > ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>compileBitcode</key>
	<false/>
	<key>destination</key>
	<string>export</string>
	<key>method</key>
	<string>debugging</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>stripSwiftSymbols</key>
	<true/>
	<key>teamID</key>
	<string>AB98Z5W66M</string>
	<key>thinning</key>
	<string>&lt;none&gt;</string>
</dict>
</plist>
EOF

ExportOptionsPlistPath=$(pwd)/ExportOptions.plist
xcodebuild -exportArchive -archivePath ${export_archive_path} -exportPath ${export_ipa_path} -exportOptionsPlist ${ExportOptionsPlistPath} -allowProvisioningUpdates

endTime=$(date +%s)
take=$(( endTime - startTime ))
echo Time taken to execute commands is ${take} seconds.

time=$(date "+%Y%m%d-%H%M%S")

discordUrl=https://discord.com/api/webhooks/1075323981193826354/rCJrCgDxYIV3E-gpuhh6F8zh8smCnev9Tguil9flnMaI2fVMNTwbp2fYEh0yAwcWsDIX
robotThread=1075322890276319232
discordUserName=${directory}_packer_$time #discord 显示用
localPath=upload #本地上传用文件夹 一般不需要改
uploadFile=PhantomBladeEX.ipa
fileHubPath=packer/yzr3Ex/ipa
plistHttpsUrl=https://test46.sgameuser.com:7903/download
uploadFileNewName=ipa_${directory}_${time}.ipa

if [ -f $uploadFile ];then
	echo "开始文件上传"
else
	echo "文件不存在"
	exit
fi

rm -rf $localPath
mkdir $localPath

cp $uploadFile $localPath/"$uploadFileNewName"
sshpass -p "$sGameHubPasswd" rsync -a --append --delete -m -P -r -e "ssh -p 22" --chmod=ugo=rwx $localPath/"$uploadFileNewName" \
$sGameHubAccount@192.168.0.200:/volume1/web/$fileHubPath

plistName=plist_${directory}_${time}.plist

cat > $localPath/$plistName <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>items</key>
<array>
<dict>
<key>assets</key>
<array>
<dict>
<key>kind</key>
<string>software-package</string>
<key>url</key>
<string>__REPLACE_URL__</string>
</dict>
<dict>
<key>kind</key>
<string>full-size-image</string>
<key>needs-shine</key>
<true/>
<key>url</key>
<string>https://sbase.s-game.cn:7908/download?name=icon.png</string>
</dict>
</array>
<key>metadata</key>
<dict>
<key>bundle-identifier</key>
<string>com.sgame.phantomblade</string>
<key>bundle-version</key>
<string>1.0</string>
<key>kind</key>
<string>software</string>
<key>title</key>
<string>Phantom Blade EX</string>
</dict>
</dict>
</array>
</dict>
</plist>
EOF

downloadUrl=https://nasload.s-game.cn/"$fileHubPath"/"$uploadFileNewName"

sed -i '' s#__REPLACE_URL__#"$downloadUrl"#g $localPath/"$plistName"
sshpass -p 123456 rsync -a --append --delete -m -P -r -e 'ssh -p 22' --chmod=ugo=rwx $localPath/"$plistName" \
root@192.168.0.46:/home/jubin/ipa/download/

plistDownloadUrl=$plistHttpsUrl/$plistName

wget https://nasload.s-game.cn/packer/qrCode
qrPath=$localPath/qr_$time.png
chmod +x qrCode && ./qrCode --url="itms-services://?action=download-manifest&url=$plistDownloadUrl" --path="$qrPath"

wget https://nasload.s-game.cn/packer/discordSender
chmod +x discordSender && ./discordSender --discordUrl=$discordUrl --robotThread="$robotThread" --userName="$discordUserName" --execTime="$take second" \
--gitTag="$git_tag" --gitPath=$gitPath --pngPath="$qrPath" --discordContent="**pack name**\n${uploadFileNewName}"

sshpass -p "$sGameHubPasswd" rsync -arPzO --delete -e "ssh -p 22" --chmod=ugo=rwx $gitPath/Client/Library \
$sGameHubAccount@192.168.0.200:$rsyncLibraryPath/ >> rsync_remote.log

cp -af $gitPath/Client/Library ${localBackupPath}/

curTime=$(date "+%Y%m%d-%H%M%S")
tarName=ex-"${curTime}".tar.gz
tar -czf "$tarName" ${scheme_name}.xcarchive

ncftpput -u uploader -p 'RM1k-ys[' 192.168.0.200 web/packer/yzr3Ex/xcarchive/ "$tarName"

if [ "$isClean" == "true" ];
then
    rm -rf "$buildPath"
fi