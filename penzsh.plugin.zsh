## Exports
export PENZSH_CMD_DIR="${0:h:a}/cmds"

## Hook function definitions
function chpwd_update_penzsh_vars() {
	update_current_penzsh_vars
}

function prompt_penzsh() {
	if ( $PENZSH ) ; then
		local pzsh_icon=""

		case $PENZSH_OS in
		windows) pzsh_icon="WINDOWS_ICON";;
		linux) pzsh_icon="LINUX_ICON";;
		bsd) pzsh_icon="FREEBSD_ICON";;
		*) pzsh_icon="VCS_UNTRACKED_ICON";;
		esac
		
		p10k segment -r -i ${pzsh_icon} -b red -t "$PENZSH_TARGET" 2>/dev/null
	fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd chpwd_update_penzsh_vars

## Aliases
alias pz=penzsh

## Function Definitions
function update_current_penzsh_vars() {
	# Are we in a penzsh project?
	PENZSH=false
	fc -P
	local x=`pwd`
	while [ "$x" != "/" ] ; do
		if [ `find "$x" -maxdepth 1 -name .penzsh -type d 2>/dev/null` ] ; then
			PENZSH=true
			PENZSH_DIR=$x
			PENZSH_TARGET=$(cat $x/.penzsh/target)
			PENZSH_OS=$(cat $x/.penzsh/os)
			fc -p $x/.penzsh/history
			break
		fi
		x=`dirname "$x"`
	done
}
update_current_penzsh_vars

function penzsh_echo() {
	echo "PENZSH >>> ${@}"
}

function penzsh() {
	local CMD=${1:-help}

	if ( $PENZSH ) ; then
		case $CMD in
		create)
			penzsh_echo "Currently in a penzsh project for $PENZSH_TARGET!"
			penzsh_echo "penzsh does not support sub-projects!"
			;;
		flag)
			case $2 in
			win*)
				echo windows > $PENZSH_DIR/.penzsh/os
				penzsh_echo "Now treating target as a Windows machine."
				;;
			lin*)
				echo linux > $PENZSH_DIR/.penzsh/os
				penzsh_echo "Now treating target as a Linux machine."
				;;
			freebsd|bsd)
				echo bsd > $PENZSH_DIR/.pensh/os
				penzsh_echo "Now treating target as a FreeBSD machine."
				;;
			*)
				penzsh_echo "Error: Unknown flag!"
				;;
			esac
			update_current_penzsh_vars
			;;
		note)
			echo "$(date -u +\[%Y-%b-%d\ %T\ UTC\]) > ${@:2}" >> $PENZSH_DIR/.penzsh/notes
			;;
		notes)
			less $PENZSH_DIR/.penzsh/notes
			;;
		todo)
			echo "${@:2}" >> $PENZSH_DIR/.penzsh/todo
			;;
		todos)
			cat -n $PENZSH_DIR/.penzsh/todo
			;;
		todone)
			local TODO_N=$(($2+0))
			local TODO_TASK=`sed -n "${TODO_N}p;" $PENZSH_DIR/.penzsh/todo 2>/dev/null`
			if [ -z "$TODO_TASK" ] ; then
				penzsh_echo "There aren't that many tasks!"
			else
				penzsh_echo "Really complete ${TODO_TASK}?"
				read -q "REPLY?(y/n): "
				echo ""
				if [ $REPLY = "y" ] ; then
					sed -i "${TODO_N}d;" $PENZSH_DIR/.penzsh/todo
					penzsh_echo "Todo removed!"
				else
					penzsh_echo "Aborting todo completion!"
				fi
			fi
			;;
		cmds)
			ls $PENZSH_CMD_DIR
			;;
		*)
			if [ -f $PENZSH_CMD_DIR/$1 ]; then
				source $PENZSH_CMD_DIR/$1 ${a:2}
			else
				echo "Following commands currently supported:"
				echo -e "\tcmds   - List vailable custom/tool commands"
				echo -e "\tcreate - Make the current direction a penzsh project"
				echo -e "\tflag"
				echo -e "\t\tfreebsd - Flag the target as a FreeBSD machine."
				echo -e "\t\tlinux   - Flag the target as a Linux machine."
				echo -e "\t\twindows - Flag the target as a Windows machine."
				echo -e "\tnote   - Save a note for later"
				echo -e "\tnotes  - Read your notes for this target"
				echo -e "\ttodo   - Remind yourself of something"
				echo -e "\ttodos  - See what you need to do for this target"
			fi
			;;
		esac
	else
		case $CMD in
		create)
			mkdir -p .penzsh
			PENZSH_DIR=`pwd`
			if [ $2 ] ; then
				echo $2 > .penzsh/target
			else
				read "target?Target: "
				echo $target > $PENZSH_DIR/.penzsh/target
			fi
			touch $PENZSH_DIR/.penzsh/notes
			touch $PENZSH_DIR/.penzsh/todo
			touch $PENZSH_DIR/.penzsh/os
			mkdir -p $PENZSH_DIR/enum
			mkdir -p $PENZSH_DIR/loot
			mkdir -p $PENZSH_DIR/exploits

			update_current_penzsh_vars
			;;
		*)
			penzsh_echo "This is not a penzsh project. Please run 'penzsh create' to make this the root directory of a penzsh project."
		esac
	fi

	
}
