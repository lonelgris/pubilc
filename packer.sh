target=iOS
echo ${target}

rsyncAccount=jubin
rsyncPasswd=LINGdi1535
rsyncLibraryPath=/volume1/web/packer/yzr3Ex/Library/${target}

startTime=$(date +%s)

buildPath=~/jenkinsBuild/${directory}

rm -rf "$buildPath"

mkdir -p "$buildPath"
cd "$buildPath" || exit

git clone -b "$git_tag" http://oauth2:glpat-V87fyuuGqxxnsgjTwcqZ@git.pbex.s-game.cn/pbex/pbex-client.git --depth 1

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

unity_path=/Applications/Unity/Unity.app/Contents/MacOS/Unity
client_path=$(pwd)/pbex-client/Client
echo "$client_path"

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
echo "$log_file"

rm -rf pbex-client/Client/Library

sshpass -p $rsyncPasswd \
rsync -a \
      --append \
      --delete \
      -m \
      -r \
      -e "ssh -p 22" \
      --chmod=ugo=rwx \
      $rsyncAccount@192.168.0.200:$rsyncLibraryPath/Library pbex-client/Client/

gen_path=$client_path"/Assets/Xlua/Gen"

rm -rf "$gen_path"
rm -f "$log_file"

custom_args="resVersion=$res_version"


# copy m1 xlua.bundle
rm -rf "${client_path}"/Assets/Plugins/xlua.bundle
rm -f "${client_path}"/Assets/Plugins/xlua.bundle.meta
cp -R "$(pwd)"/pbex-client/Bundle/xluadll/ "${client_path}"/Assets/Plugins/

# replace /Assets/Resources/ServerTag.txt
rm -f "$client_path/Assets/Resources/serverTag.txt"
echo "${server_tag}" >> "$client_path/Assets/Resources/serverTag.txt"
cat "$client_path/Assets/Resources/serverTag.txt"

# pack addressable data
method_name="Model.BuildGames.OnHybridCLRGenerateAll"
"$unity_path" -batchmode -quit -logFile "$log_file" -projectPath "$client_path" -executeMethod "$method_name" -CustomArgs "$custom_args" -buildTarget ${target}

# build xcode
method_name="Model.BuildGames.BuildiOS"
custom_args="productPath=${xcode_path}#productName=${final_product_name}#buildOptions=${build_options}#CompanyName=$playerSetting_companyName#ProductName=$playerSetting_productName#Version=$playerSetting_version#channelType=${cur_channel}#buildValue=${build_value}#isVietnam=$is_vietnam#isJP=$is_jp#resVersion=$res_version"
"$unity_path" -batchmode -quit -logFile "$log_file" -projectPath "$client_path" -executeMethod "$method_name" -CustomArgs "$custom_args" -buildTarget ${target}

# build archive
xcode_log_file=$(pwd)/xcode_pack.log

scheme_name=Unity-iPhone
project_name=${xcode_path}/${final_product_name}
build_configuration=Release
export_archive_path=$(pwd)/${scheme_name}.xcarchive
export_ipa_path=$(pwd)

xcodebuild clean -workspace "${project_name}"/${scheme_name}.xcworkspace -scheme ${scheme_name} -configuration ${build_configuration}

security unlock-keychain -p "123456"
xcodebuild archive -workspace "${project_name}"/${scheme_name}.xcworkspace -scheme ${scheme_name} -configuration ${build_configuration} -archivePath "${export_archive_path}" -destination 'generic/platform=iOS' >> "${xcode_log_file}"

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
xcodebuild -exportArchive -archivePath "${export_archive_path}" -exportPath "${export_ipa_path}" -exportOptionsPlist "${ExportOptionsPlistPath}" -allowProvisioningUpdates

endTime=$(date +%s)
take=$(( endTime - startTime ))
echo Time taken to execute commands is ${take} seconds.

upload=upload-${target}

wget https://nasload.s-game.cn/packer/yzr3Ex/$upload

chmod +x $upload
./$upload --tag="$server_tag" --execTime="${take} seconds" --sGameHubUser=$rsyncAccount --sGameHubPassword=$rsyncPasswd --gitPath=pbex-client --userName="${directory}"

sshpass -p $rsyncPasswd \
rsync -a \
      --append \
      --delete \
      -m \
      -r \
      -e "ssh -p 22" \
      --chmod=ugo=rwx \
      pbex-client/Client/Library $rsyncAccount@192.168.0.200:$rsyncLibraryPath/

sshpass -p $rsyncPasswd \
rsync -a \
      --append \
      --delete \
      -m \
      -r \
      -e "ssh -p 22" \
      --chmod=ugo=rwx \
      pbex-client/Client/Library $rsyncAccount@192.168.0.200:$rsyncLibraryPath/

tarName=$git_tag.tar.gz

tar -czf "$tarName" Unity-iPhone.xcarchive

ncftpput -u uploader -p "RM1k-ys[" 192.168.0.200 web/packer/yzr3Ex/xcarchive/ "$tarName"

if [ "$isClean" == "true" ];
then
    rm -rf "$buildPath"
fi