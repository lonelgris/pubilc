directory=yzr3 #运行目录
git_tag=cn-0606 #git tag
server_tag=cn-release315 #服务器tag
#bundle_res_path="/e/ResourceBundle/YZR3V2HD" #上传资源文件夹路径
#SVNUp=true
#ServerTag=cn-release315
BuildVersion=0.0.513 #资源版本号
#BundleVersionCode=1 #包版本号 PlayerSetting->Bundle Version Code
#IsXianFeng=false
#BuildPkg=true #是否出包
#MtpPkg=false #是否出mtp包
#UploadRes=false #是否上传资源
#UploadEnRes=false #是否上传英文资源

target=Android
echo ${target}

gitPath=client
configPath=yzr3CN

sGameHubAccount=uploader
sGameHubPasswd="RM1k-ys["
localBackupPath=~/jenkinsBuild/backup/${configPath}/Library/${target}
rsyncLibraryPath=/volume1/web/packer/${configPath}/Library/${target}

mkdir -p $localBackupPath

startTime=$(date +%s)

buildPath=~/jenkinsBuild/${directory}

rm -rf "$buildPath"
mkdir -p "$buildPath"

cd "$buildPath" || exit

#打包脚本

unity_path=/Applications/Unity/Unity.app/Contents/MacOS/Unity

rm -rf $gitPath

git clone -b "$git_tag" http://oauth2:glpat-V87fyuuGqxxnsgjTwcqZ@git.pbex.s-game.cn/pbex/Yzr3CN.git $gitPath --depth 1

cp -af ${localBackupPath}/Library ${gitPath}/Client/

sshpass -p "$sGameHubPasswd" rsync -arPzO --delete -e "ssh -p 22" --chmod=ugo=rwx $sGameHubAccount@192.168.0.200:$rsyncLibraryPath/Library $gitPath/Client/ >>rsync_local.log

##清空xlua目录，解决脚本编译错误问题
log_file=$(pwd)/pack.log
gen_path="${gitPath}/Client/Assets/Xlua/Gen"

rm -rf $gen_path
rm -f "$log_file"

#build_assets
method_name="AssetBuild.AssetBuildTools.BuildAssetBundleSh"
custom_args="buildVersion=${BuildVersion}"
$unity_path -batchmode -nographics -quit -logFile "$log_file" -projectPath $gitPath/Client -executeMethod $method_name -CustomArgs $custom_args -buildTarget $target

endTime=$(date +%s)
take=$(( endTime - startTime ))
echo Time taken to execute commands is ${take} seconds.