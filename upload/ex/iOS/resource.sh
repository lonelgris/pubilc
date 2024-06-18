target=iOS
echo ${target}

sGameHubAccount=uploader
sGameHubPasswd="RM1k-ys["
localBackupPath=~/jenkinsBuild/backup/yzr3Ex/Library/${target}
rsyncLibraryPath=/volume1/web/packer/yzr3Ex/Library/${target}

buildPath=~/jenkinsBuild/${directory}

startTime=$(date +%s)

rm -rf "$buildPath"

mkdir -p "$buildPath"
cd "$buildPath" || exit

unity_path=/Applications/Unity/Unity.app/Contents/MacOS/Unity
client_path=$(pwd)/pbex-client/Client
echo $client_path
log_file=$(pwd)/pack.log
echo $log_file

rm -rf pbex-client
#cp -R ~/Unity/origin/pbex-client-0429 pbex-client
git clone -b "$git_tag" http://oauth2:glpat-V87fyuuGqxxnsgjTwcqZ@git.pbex.s-game.cn/pbex/pbex-client.git --depth 1

#cp -R ~/Unity/origin/Library-ex-${target} pbex-client/Client/Library
cp -af ${localBackupPath}/Library pbex-client/Client/

sshpass -p $sGameHubPasswd rsync -arPz --delete -e "ssh -p 22" --chmod=ugo=rwx $sGameHubAccount@192.168.0.200:$rsyncLibraryPath/Library pbex-client/Client/ >>rsync_local.log

gen_path=$client_path"/Assets/Xlua/Gen"

rm -rf $gen_path
rm -f $log_file

method_name="Model.BuildGames.OnHybridCLRGenerateAll"

custom_args="resVersion="$res_version

"$unity_path" -batchmode -quit -logFile "$log_file" -projectPath "$client_path" -executeMethod "$method_name" -CustomArgs "$custom_args" -buildTarget ${target}

endTime=$(date +%s)
take=$(( endTime - startTime ))
echo Time taken to execute commands is ${take} seconds.

time=$(date "+%Y%m%d-%H%M%S")

discordUrl=https://discord.com/api/webhooks/1075323981193826354/rCJrCgDxYIV3E-gpuhh6F8zh8smCnev9Tguil9flnMaI2fVMNTwbp2fYEh0yAwcWsDIX
robotThread=1075322890276319232
discordUserName=${directory}_res_$time #discord 显示用
gitPath=pbex-client
resourcePath=pbex-client/Bundle/Addressables/${target}
resourceHubPath=web/packer/yzr3Ex/resource/${target}

ncftpput -R -u $sGameHubAccount -p "$sGameHubPasswd" 192.168.0.200 $resourceHubPath $resourcePath/* >>ncftpput.log

wget https://nasload.s-game.cn/packer/discordSender

chmod +x discordSender && ./discordSender --discordUrl=$discordUrl --robotThread="$robotThread" --userName="$discordUserName" --execTime="$take second" \
--gitTag="$git_tag" --gitPath=$gitPath --discordContent="\n**resource version**\n$res_version"

rm -rf "$buildPath"