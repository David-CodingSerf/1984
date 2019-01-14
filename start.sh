#!/bin/bash

# 日志信息类型
function echoInfo(){
  tips="[INFO] "
  if [ "$2" = "0" ]; then
    tips=""
  fi
  echo "\033[36m$tips$1\033[0m"
}
function echoSuccess(){
  tips="[SUCCESS] "
  if [ "$2" = "0" ]; then
    tips=""
  fi
  echo "\033[32m$tips$1\033[0m"
}
function echoError(){
  tips="[ERROR] "
  if [ "$2" = "0" ]; then
    tips=""
  fi
  echo "\033[31m$tips$1\033[0m"
}
function echoWarning(){
  tips="[WARNING] "
  if [ "$2" = "0" ]; then
    tips=""
  fi
  echo "\033[33m$tips$1\033[0m"
}
function echoInput(){
  tips="[INPUT] "
  if [ "$2" = "0" ]; then
    tips=""
  fi
  echo "\033[35m$tips$1\033[0m"
}
function echoLine() {
  echo "---------------------------------------------------------"
}

# 检查安装是否成功
function checkFail() {
  if [ $? -eq 0 ] ; then
    echoSuccess "$1 安装成功！"
    echo
  else
    echoError "$1 安装失败！"
    echoError "退出！" 0
    exit 1
  fi
}
# 获取用户输入
function readInput() {
	if read -t 10 -p "$1" yn
	then
		if [[ $yn == [Yy] ]]; then
		$2
		elif [[ $yn == [Nn] ]]; then
		exit 1
		else [[ $yn != [YyNn] ]]
		exit 1
		fi
	else
		echo "输入超时..."
		exit 1
	fi
}
# cmd 命令是否存在
function existCmdByType() {
  type "$1" &> /dev/null ;
}
function existCmdByEval() {
  eval $1 &> /dev/null ;
}
# app 是否存在
function existApp() {
  ls "/Applications/${1}.app" &>/dev/null
}
## insall 用法：install <cmd> <show name> <install command>
# $1 是否已安装的检测命令
# $2 工具名
# $3 安装命令
function installCmd() {
  if existCmdByType "$1" || existCmdByEval "$1" 
  then
    echoSuccess "【跳过】检测到 ${2} 已经安装"
  else
    echoInfo "${2} 尚未安装，现在开始安装，请稍候..."
    # 安装命令
    eval $3
    checkFail $2 
  fi
}
## insall 用法：install <show name> <cask name>
# $1 app名
# $2 cask名
function installCask() {
  if existApp "$1"
  then
    echoSuccess "【跳过】检测到 ${1} 已经安装"
  else
    echoWarning "${1} 尚未安装，现在开始安装，请稍候..."
    # 安装命令
    brew reinstall caskroom/cask/$2
    checkFail $1
  fi
}
## insall 用法：install <show name> <download url>
# $1 app名
# $2 cask名
function installDmg() {
  if existApp "$1"
  then
    echoSuccess "【跳过】检测到 ${1} 已经安装"
  else
    echoWarning "${1} 尚未安装，现在开始安装，请稍候..."
    # 下载
    local dmgDownloadFile="${TMPDIR}1984_dmg_download.dmg"
    rm -rf ${dmgDownloadFile} &> /dev/null
    curl -s $2 > ${dmgDownloadFile} 
    # 安装命令
    local dmgMountDir="${TMPDIR}1984_dmg_mount_volume"
    hdiutil detach -force ${dmgMountDir} &> /dev/null
    hdiutil attach -nobrowse -mountpoint $dmgMountDir $dmgDownloadFile &> /dev/null
    cp -rf ${dmgMountDir}/$1.app /Applications &> /dev/null
    # 善后
    hdiutil detach -force ${dmgMountDir} &> /dev/null
    rm -rf ${dmgDownloadFile} &> /dev/null
    # 检测
    checkFail $1
  fi
}

function start1984() {
  echo
  echoInfo "                    前端工作环境初始化                  " 0
  echoLine
  echoInfo "该脚本将带领你安装和配置开发环境所需要的工具和软件"
  # 检查 Xcode 开发者工具是否有安装 
  # if [ ! -d /Library/Developer/CommandLineTools ]; then
  #   echoInfo "开始前请确保先手动安装好 Xcode 开发者工具"
  #   echoInput "Xcode 开发者工具安装好后，请按 回车 继续"
  #   echoLine
  #   xcode-select --install &> /dev/null
  # else
  #   echoInput "请按 回车 继续"
  # fi
  echoInput "请按 回车 继续"

  read -s -n 1 input_enter
  if [ ! -z "$input_enter" ]; then
    echoError "退出！" 0
    exit 0
  else
    echoInfo "开始安装和配置，请按提示操作！"
    sleep 1.5
  fi 
}

function clearInput() {
  while read -e -t 1; do : ; done
}

function initGitConfig() {
  echoLine
  clearInput
  # 输入名字和Email地址，后续配置git使用
  echoInput "请输入你的域账号（作为 git 的全局用户名）"
  read git_name
  echoInput "请输入你的Email（作为 git 的全局邮箱）"
  read git_email

  # 配置git的全局名字和Email
  git config --global user.name ${git_name}
  git config --global user.email ${git_email}
}

# command line tools
function installCmdLineTools() {
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
  local PROD=$(softwareupdate -l |
    grep "\*.*Command Line" |
    head -n 1 | awk -F"*" '{print $2}' |
    sed -e 's/^ *//' |
    tr -d '\n')
  softwareupdate -i "$PROD" --verbose;
}
# homebrew
# raw 太慢了，用 git clone 本地来搞
# installCmd "brew" "homebrew" "/usr/bin/ruby -e \"$(curl -SL https://raw.githubusercontent.com/Homebrew/install/master/install)\""
function installHomebrew() {
  hbdir="git_homebrew_install"
  rm -rf ${TMPDIR}${hbdir} &> /dev/null
  git clone https://github.com/Homebrew/install.git ${TMPDIR}${hbdir} &> /dev/null
  ruby ${TMPDIR}${hbdir}/install
  rm -rf ${TMPDIR}${hbdir} &> /dev/null
}

# oh-my-zsh
# 自动安装会触发 shell 替换导致脚本中止
function installOhMyZsh() {
  git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
  cp ~/.zshrc ~/.zshrc.old
  cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
}

function installEverything() {
  echoLine
  # command line tools
  installCmd "ls /Library/Developer/CommandLineTools" "Xcode 开发者工具" "installCmdLineTools"
  # homebrew
  installCmd "brew" "homebrew" "installHomebrew"

  # node
  installCmd "node" "Node.js" "brew install node"

  # hpm
  installCmd "anyproxy" "AnyProxy 代理服务器" "npm i -g anyproxy"

  # zsh
  installCmd "zsh" "zsh" "brew install zsh"

  # oh-my-zsh
  installCmd "ls ~/.oh-my-zsh" "oh-my-zsh" "installOhMyZsh"

  # vscode
  installCask "Visual Studio Code" "visual-studio-code"

  # iTerm
  installCask "iTerm" "iterm2"

  # Google Chrome
  installCask "Google Chrome" "google-chrome"

  # MacDown
  installCask "MacDown" "macdown"

  # Alfred 3
  installCask "Alfred 3" "alfred"

  # Sketch
  # installCask "Sketch" "sketch"
}


# 启动脚本
start1984

# 安装工具
echoLine
echoInfo "STEP 1. 安装工具和软件"
installEverything
# 配置 git
echoLine
echoInfo "STEP 2. 配置 Git"
initGitConfig
# 更换shell为zsh
echoLine
echoInfo "STEP 3. 更换 shell 为 zsh"
echoLine
chsh -s /bin/zsh
# 全部完成
echoLine
echoSuccess "全部完成"
