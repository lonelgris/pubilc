package main

import (
	"bufio"
	"bytes"
	"context"
	"flag"
	"fmt"
	"github.com/disgoorg/snowflake/v2"
	"github.com/pkg/errors"
	"github.com/skip2/go-qrcode"
	"io"
	"math/rand"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/disgoorg/disgo/discord"
	"github.com/disgoorg/disgo/webhook"
)

// 上报discord 参数
var discordUrl = flag.String("discordUrl",
	"https://discord.com/api/webhooks/1075323981193826354/rCJrCgDxYIV3E-gpuhh6F8zh8smCnev9Tguil9flnMaI2fVMNTwbp2fYEh0yAwcWsDIX", "discord url")

var RobotThread = flag.String("RobotThread", "1075322890276319232", "RobotThread")

var uploadIpa = flag.String("uploadIpa", "PhantomBladeEX.ipa", "上传ipa文件")

// 日志参数
var gitPath = flag.String("gitPath", "", "gitPath")
var tag = flag.String("tag", "", "tag")
var execTime = flag.String("execTime", "", "execTime") //执行时间
var userName = flag.String("userName", "", "userName")

var sGameHubUser = flag.String("sGameHubUser", "", "sGameHubUser")
var sGameHubPassword = flag.String("sGameHubPassword", "", "sGameHubPassword")
var packerPath = flag.String("packerPath", "/packer/yzr3Ex/ipa", "packerPath")                                 //ipa上传路径
var plistTemplatePath = flag.String("plistTemplatePath", "/packer/yzr3Ex/template.plist", "plistTemplatePath") //plist模板路径

const (
	sGameHubUrl = "https://nasload.s-game.cn" //sGame hub ipa https下载地址

	plistMachineIp = "192.168.0.46"                                //plist 上传机器ip
	plistHttpsUrl  = "https://test46.sgameuser.com:7903/download/" //plist https下载地址

	uploadFolder = "rsyncIpa/"
)

func main() {
	generate()
}

func generate() {

	//检测打包shell是否执行成功

	flag.Parse()

	if *uploadIpa == "" {
		execExit("上传ipa文件不能为空")
	}

	if *userName == "" {
		execExit("userName不能为空")
	}

	if *sGameHubUser == "" || *sGameHubPassword == "" {
		execExit("sGameHubUser或sGameHubPassword不能为空")
	}

	if _, err := os.Stat(*uploadIpa); err != nil {
		execExit(fmt.Sprintf("上传ipa文件不存在:%s", *uploadIpa))
	}

	//删除上传目录
	_ = os.RemoveAll(uploadFolder)

	if err := os.MkdirAll(uploadFolder, os.ModePerm); err != nil {
		execExit(fmt.Sprintf("创建上传目录失败:%v", err))
	}

	//下载plist 模板文件
	plistTemplateUrl := sGameHubUrl + *plistTemplatePath

	res, err := http.Get(plistTemplateUrl)
	if err != nil {
		execExit(fmt.Sprintf("下载plist模板文件失败:%v", err))
	}

	timeUnixStr := fmt.Sprintf("%d", time.Now().Unix())

	plistNewName := fmt.Sprintf("ipa_%s.plist", timeUnixStr)

	f, err := os.Create(uploadFolder + plistNewName)
	if err != nil {
		execExit(fmt.Sprintf("创建plist文件失败:%v", err))
	}

	if _, err = io.Copy(f, res.Body); err != nil {
		execExit(fmt.Sprintf("复制plist文件失败:%v", err))
	}

	ipaNewName := fmt.Sprintf("ipa_%s.ipa", timeUnixStr)

	fmt.Println("处理plist文件中...")

	if err = ReplaceFileContentField(uploadFolder+plistNewName, "__REPLACE_URL__",
		sGameHubUrl+*packerPath+"/"+ipaNewName); err != nil {
		execExit(fmt.Sprintf("替换plist文件内容失败:%v", err))
	}

	fmt.Printf("生成plist文件成功\n")

	if err = RunCommand("cp", *uploadIpa, uploadFolder+ipaNewName); err != nil {
		execExit(fmt.Sprintf("复制ipa文件失败:%v", err))
	}

	fmt.Printf("上传文件中plist文件中...\n")

	if err = RunCommand("sshpass", "-p", "123456", "rsync", "-a", "--append", "--delete", "-m", "-P", "-r",
		"-e", "ssh -p 22", "--chmod=ugo=rwx", uploadFolder+plistNewName, "root@"+plistMachineIp+":/home/jubin/ipa/download/"); err != nil {
		execExit(fmt.Sprintf("上传plist文件失败:%v", err))
	}

	fmt.Printf("上传文件ipa文件中...\n")

	if err = RunCommand("sshpass", "-p", *sGameHubPassword, "rsync", "-a", "--append", "--delete", "-m", "-P", "-r",
		"-e", "ssh -p 22", "--chmod=ugo=rwx", uploadFolder+ipaNewName, *sGameHubUser+"@192.168.0.200:/volume1/web/"+*packerPath); err != nil {
		execExit(fmt.Sprintf("上传ipa文件失败:%v", err))
	}

	fmt.Printf("上传ipa文件成功\n")

	fmt.Println("生成二维码中...")

	downloadUrl := "itms-services:///?action=download-manifest&url=" + plistHttpsUrl + plistNewName

	fmt.Println("downloadUrl:", downloadUrl)

	pngName := fmt.Sprintf(uploadFolder+"qrcode_%s.png", timeUnixStr)

	err = qrcode.WriteFile(downloadUrl, qrcode.Medium, 256, pngName)

	if err != nil {
		execExit(fmt.Sprintf("生成二维码失败: %s, err: %s", pngName, err))
	}

	fmt.Printf("生成二维码成功\n")

	if err = sendDiscordMessage("ipa文件上传成功", *tag, pngName); err != nil {
		execExit(fmt.Sprintf("发送消息失败: %s", err))
	}

	execExit("")
}

func ReplaceFileContentField(filePath string, replaceField string, insteadFile string) error {

	in, err := os.OpenFile(filePath, os.O_RDWR|os.O_CREATE, 0766)
	if err != nil {
		return err
	}

	out, err := os.OpenFile(filePath+".mdf", os.O_RDWR|os.O_CREATE, 0766)
	if err != nil {
		fmt.Println("Open write file fail:", err)
		os.Exit(-1)
	}
	defer func(out *os.File) {
		_ = out.Close()
	}(out)

	br := bufio.NewReader(in)
	index := 1
	for {
		line, prefix, errRead := br.ReadLine()

		if errRead == io.EOF {
			break
		}

		if errRead != nil {
			return errRead
		}

		if prefix {
			return fmt.Errorf("line too long")
		}

		newLine := strings.Replace(string(line), replaceField, insteadFile, -1)
		_, err = out.WriteString(newLine + "\n")
		if err != nil {
			return err
		}

		index++
	}

	_ = in.Close()

	_ = out.Close()

	//删除原文件
	if err = os.Remove(filePath); err != nil {
		return err
	}

	//重命名新文件
	if err = os.Rename(filePath+".mdf", filePath); err != nil {
		return err
	}

	return nil
}

func RunCommand(name string, arg ...string) error {

	cmd := exec.Command(name, arg...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout // 标准输出
	cmd.Stderr = &stderr // 标准错误
	err := cmd.Run()

	if err != nil {
		return errors.Wrapf(err, "执行命令失败，name: %s, arg: %v, stdout: %s, stderr: %s", name, arg, stdout.String(), stderr.String())
	}

	outStr, errStr := string(stdout.Bytes()), string(stderr.Bytes())

	if len(outStr) > 0 {
		fmt.Println(outStr)
	}

	if len(errStr) > 0 {
		return errors.Errorf(errStr)
	}

	return nil
}

//warning: setlocale: LC_MESSAGES: cannot change locale (en_USexport): No such file or directory
//sudo vim /etc/ssh/ssh_config
//注释掉   SendEnv LANG LC_*

func sendDiscordMessage(title string, tag string, pngPath string) error {
	client, err := webhook.NewWithURL(*discordUrl)
	if err != nil {
		return errors.Wrapf(err, "create discord client failed")
	}
	defer client.Close(context.Background())

	b := discord.NewWebhookMessageCreateBuilder()
	b.SetUsername(fmt.Sprintf(*userName+"_%s", time.Now().Format("2006-01-02 15:04:05")))

	discordContent := ""

	if tag != "" {
		discordContent += fmt.Sprintf("\n**执行tag**\n%s", tag)

		if tagCommit, err := GetTagCommit(*gitPath, tag); err != nil {
			fmt.Println(err)
		} else {
			discordContent += fmt.Sprintf("\n\n**tagCommit**\n%s", tagCommit)
		}
	}

	if *execTime != "" {
		discordContent += fmt.Sprintf("\n\n**execTime**\n%s", *execTime)
	}

	b.SetContent(discordContent)

	var f *os.File
	f, err = os.Open(pngPath)

	if err != nil {
		return errors.Wrapf(err, "open png file failed")
	}

	b.AddFile(title+".png", pngPath, f)

	threadID, _ := snowflake.Parse(*RobotThread)
	_, err = client.CreateMessageInThread(b.Build(), threadID)

	if err != nil {
		return errors.Wrapf(err, "send discord message failed")
	}

	return nil
}

func senDiscordErrMsg(errMsg string) error {
	fmt.Println(errMsg)

	client, err := webhook.NewWithURL(*discordUrl)
	if err != nil {
		execExit(fmt.Sprintf("create discord client failed, err: %s", err))
	}
	defer client.Close(context.Background())

	eb := discord.NewEmbedBuilder()
	eb.SetTitle(errMsg)
	eb.SetColor(rand.Intn(0xffffff + 1))
	eb.SetTimestamp(time.Now())

	b := discord.NewWebhookMessageCreateBuilder()
	b.SetUsername(*userName)
	b.AddEmbeds(eb.Build())

	threadID, _ := snowflake.Parse(*RobotThread)
	_, err = client.CreateMessageInThread(b.Build(), threadID)

	if err != nil {
		return errors.Wrapf(err, "send discord message failed")
	}

	return nil
}

func execExit(errMsg string) {
	if errMsg != "" {
		fmt.Println(errMsg)
		_ = senDiscordErrMsg(errMsg)
	}

	_ = os.RemoveAll(uploadFolder)

	os.Exit(0)
}

func GetTagCommit(gitPath string, tag string) (string, error) {
	//获取tag之间的commit
	gitCmd := fmt.Sprintf("git log %s --pretty=format:\"%%s\"", tag)

	if gitPath != "" {
		gitCmd = fmt.Sprintf("cd %s && %s", gitPath, gitCmd)
	}

	output, err := RunCommandGetOutPut(gitCmd)

	if err != nil {
		return "", errors.Errorf("get tag commit failed: %s, err: %s", tag, err)
	}

	//美化下返回值，每行中间加一行空白行
	returnStr := "*" + string(output)

	if gitPath != "" {
		_, _ = RunCommandGetOutPut("cd -")
	}

	return strings.ReplaceAll(returnStr, "\n", "\n\n*"), nil
}

func RunCommandGetOutPut(cmd string) ([]byte, error) {

	fmt.Println(cmd)

	pwdCmd := exec.Command("sh", "-c", cmd)
	return pwdCmd.CombinedOutput()
}
