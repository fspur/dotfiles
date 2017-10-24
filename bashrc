# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=
#powerline-daemon -q
#POWERLINE_BASH_CONTINUATION=1
#POWERLINE_BASH_SELECT=1
#. /home/sram21/.local/lib/python2.7/site-packages/powerline/bindings/bash/powerline.sh
HISTCONTROL=ignoreboth

# User specific aliases and functions
source /cust/tools/bin/b2c.sh
export PS1=$'\n\[\e[0;93m\]\u@nutanix\e[22m\] [\D{%T}]:\w\n\[\e[1;32m\]$(parse_git_branch)\[\e[92m\]\xe2\x86\x92\[\e[0m\] '
export LD_LIBRARY_PATH=/usr/lib/oracle/12.1/client64/lib/
export A_AUTH=			#akamai creds
export SVN_AUTH=	#svn creds
export SSHPASS=`cat $HOME/.pw`
export HTTP_AUTH=   	#rappctrl creds
export ME=mail@example.com
export PATH=$PATH:/opt/scripts_bin
export DEF2KEYS_DATA_DIR=$HOME/envdef
alias connect="ssh 2>/dev/null"
alias sshpass="sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null 2>/dev/null"
alias nokeyconnect="ssh -o 'PubKeyAuthentication no' 2>/dev/null"
alias ll="ls -ltrh --color=auto"
alias vi='vim'
alias vipk='vi ~/packages'
alias svnlog='svn log -r HEAD:BASE -l '
alias clrall="clear && printf '\033[3J'" #clear kiTTY scrollback
alias svndiff='svn diff -rPREV'
alias cgrep='grep --color=always'
alias tml="tmux list-sessions"
alias tma="tmux attach-session"
alias tmc="clear && tmux clear-history"
alias tmk="tmux kill-session"
alias ls='ls --color=auto'
alias pawx='psql -d awx -U awx -h tower.va2.b2c.blah.com'

parse_git_branch() {
 git branch 2> /dev/null | sed '/^[^*]/d;s/* \(.*\)/git:(branch:\1)/'
}

plussql() {
	if [[ $1 != "*prdv*" ]]
	then
		rlwrap sqlplus64 `envclient $1:datasource.$2.user`/`envclient $1:datasource.$2.password`@`envclient $1:datasource.$2.host`/`envclient $1:datasource.$2.instance.name` $3 #@$HOME/sqlplus/startup/format.sql
	fi
}
export -f plussql

sshhost() {
	sshpass `envclient $1:"sin."$2".host"`
}
export -f sshhost

chkecr() {
	url="dbtool-p-1.va2.b2c.blah.com:8989/env_report_4/get_env_creds?p_env="
	echo -e "curl -s $url=$1 | grep $2\n"
	curl -s dbtool-p-1.va2.b2c.blah.com:8989/env_report_4/get_env_creds?p_env=$1 | grep  $2
}
export -f chkecr

rdeploy()
{
	 echo
         read -r -p "proceed with the deployment? [y/N] " response
	 echo
         response=${response,,}
         if [[ $response =~ ^(yes|y)$ ]]
	 then
		 command rdeploy "$@"
 	 fi
}
export -f rdeploy

rappctrl()
{
         echo
         read -r -p "proceed with the control? [y/N] " response
         echo
         case $response in
             [yY][eE][sS]|[yY])
		 command rappctrl "$@"
                 ;;
             *)
                 return 1
                 ;;
         esac
}

#deploy with pfactor, strips out spaces from packages before deploying
#usage: $ rpdeploy packages <ecn>
rpdeploy ()
{
        echo
	read -r -p "proceed with the deployment to $2, [y/N]? " response
        echo
	case $response in
	    [yY][eE][sS]|[yY]) 
		cp $1 ~/packages.tmp
		tr -d ' ' < ~/packages.tmp > ~/packages
		rm ~/packages.tmp
		command rdeploy --env $2 --path $1 --pfactor 1
	        ;;
	    *)
		return 1
	        ;;
	esac
}
export -f rpdeploy

#envclient with single/multiple ecns
#usage: $ ekeys <env1>,<env2>.. <first part of key> <second part of key>
ekeys ()
{
	IFS=', ' read -a envs <<< $1

    if [ "$3" == "" ]; then
		for env in "${envs[@]}"
			do
				result=`envclient $env:/$2/`
				echo -e "\n\$ envclient $env:/$2/"
				echo -e "\n$result"
				echo -e "\ntotal records: "`echo "$result" | sed '/^\s*$/d' | wc -l`
				echo -e "______________________"
			done
    else
		for env in "${envs[@]}"
			do
				result=`envclient $env:/$2.*$3/`
				echo -e "\n\$ envclient $env:/$2.*$3/"
				echo -e "\n$result"
				echo -e "\ntotal records: "`echo "$result" | sed '/^\s*$/d' | wc -l`
				echo -e "______________________"
			done
    fi
}
export -f ekeys

#check if packages are installed
#usage: chkpkg <file with packagenames> <env>
chkpkg ()
{
	echo "// Packages that are not deployed to $2 //"
	cat $1 | while read line; do v=`find-pkg --env $2 --pkg $line | wc -l`; [ $v -eq 0 ] && echo $line; done
}
export -f chkpkg

#check if packages are in repo
#usage: chkpkgrepo <repo name> <file with packagenames>
chkpkgrepo ()
{
	echo "// Packages that are not in the repo //"
	cat $2 | while read line; do v=`curl -I -s http://pkgs.blah.com/pkgs/$1/$line | head -n1 | grep 404 | wc -l`; [ $v -eq 1 ] && echo $line; done
}
export -f chkpkgrepo

gtssldates()
{
    echo | openssl s_client -connect $1:$2 2>/dev/null | openssl x509 -noout -dates
}
export -f gtssldates

gthosts ()
{
    if [ "$2" == "" ]; then
    	envclient $1:/sin.[0-9]*.host/ | awk -F= '{print $NF}'
    else
    	envclient $1:/$2.*.deploy.host/ | awk -F= '{print $NF}'
    fi
}
export -f gthosts

crchkr()
{
    for CR in "$@";do ls change_requests/$CR.yml 2>/dev/null;done
}
export -f crchkr

xecinvm()
{
    for VM in `gthosts $1 $2`; do sshpass $VM /cust/tools/bin/$3 "| sed -e 's/^/$VM\t/'"; done
}
export -f xecinvm

upcommdef()
{
	curl -X POST -d @$2 http://admin:admin@$1:7072/repository-web/registry/upload
}
export -f upcommdef
