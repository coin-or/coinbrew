#!/usr/bin/env bash

# Author: Ted Ralphs (ted@lehigh.edu)
# Copyright 2016-2019, Ted Ralphs
# Released Under the Eclipse Public License 
#
# TODO
# - fix dependency-tracking or remove it from configure
# - consider using pushd/popd instead of cd somewhere/cd ..
# - look at TODO and FIXME below

# script debugging
#set -x
#PS4='${LINENO}:${PWD}: '

function help {
    echo "Usage: coinbrew <command1> <command2> <name|URL:branch> --option option_par ..."
    echo "       Run without arguments for interactive mode"
    echo
    echo "Commands:"
    echo
    echo "  fetch: Checkout source code for project and dependencies"
    echo "    options: --svn (check out SVN projects with SVN)"
    echo "             --git (check out all projects from git)"
    echo "             --ssh (checkout git projects using ssh"
    echo "             --skip='proj1 proj2' skip listed projects"
    echo "             --no-third-party don't download third party source (getter-scripts)"
    echo "             --skip-update Skip updating projects that are already checked out (useful if you have local changes)"
    echo "             --skip-dependencies don't fetch dependencies"
    echo
    echo "  build: Configure, build, test (optional), and pre-install all projects"
    echo "    options: --configure-help (print help on build configuration"
    echo "             --xxx=yyy (will be passed through to configure)"
    echo "             --parallel-jobs=n build in parallel with maximum 'n' jobs"
    echo "             --build-dir=/dir/to/build/in where to build (default: $PWD/build)"
    echo "             --test run unit test of main project before install"
    echo "             --test-all run unit tests of all projects before install"
    echo "             --verbosity=i set verbosity level (1-4)"
    echo "             --reconfigure re-run configure"
    echo "             --prefix=/dir/to/install (where to install, default: $PWD/dist)"
    echo "             --skip-dependencies don't build dependencies"
    echo
    echo "  install: Install all projects in location specified by prefix (after build and test)"
    echo
    echo "  uninstall: Uninstall all projects"
    echo
    echo "General options:"
    echo "  --debug: Turn on debugging output"
    echo "  --no-prompt: Turn on non-interactive mode"
    echo "  --help: Print help"
    echo 
}

function print_action {
    echo
    echo "##################################################"
    echo "### $1 "
    echo "##################################################"
    echo
}

function get_cached_options {
    local lclFile="$1"
    echo "Reading cached options from $lclFile"
    # read options from file, one option per line, and store into array copts
    readarray -t copts < "$lclFile"
    # move options from copts[0], copts[1], ... into
    # configure_options, where they are stored as the keys
    # skip options that are empty (happens when reading empty .config file)
    for c in ${!copts[*]} ; do
        [ -z "${copts[$c]}" ] && continue
        configure_options["${copts[$c]}"]=""
    done
    # print configuration options, one per line
    # (TODO might need verbosity level check)
    printf "%s\n" "${!configure_options[@]}"
}

function invoke_make {
    v=$1
    shift
    if [ $v = 1 ]; then
        set +e
        $sudo $MAKE -j $jobs $@ > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            $sudo $MAKE -j $jobs $@ > /dev/null
            echo
            echo "Build failed, see error output above"
            echo
            exit 1
        fi
        set -e
    elif [ $v = 2 ]; then
        $sudo $MAKE -j $jobs $@ > /dev/null
    else
        $sudo $MAKE -j $jobs $@
    fi
}

function get_project {
    TMP_IFS=$IFS
    unset IFS
    for i in $coin_skip_projects
    do
        if [ $1 = $i ]; then
            IFS=$TMP_IFS
            return 1
        fi
    done
    if [ `echo $dir | cut -d '/' -f 1` = ThirdParty ]; then
        if ([ -e $dir ] && [ ! -e $dir/.build ]) ||
           [ $get_third_party = false ]; then
            IFS=$TMP_IFS
            return 1
        fi
    fi
    IFS=$TMP_IFS
    return 0
}

# Parse arguments
function parse_args {
    while (( "$#" ))
    do
        arg=$1
        shift
        legacy_format=false
        case $arg in
            *=*)
                option=${arg%%=*}
                option_arg=${arg#*=}
                legacy_format=true
                ;;
            -*)
                option=$arg
                if [ "$#" = 0 ]; then
                    option_arg=
                else
                    if [[ "$1" == -* ]]; then
                        option_arg=
                    else
                        option_arg=$1
                    fi
                fi
                ;;
            *)
                option=$arg
                option_arg=
                ;;
        esac
        case $option in
            -p|--prefix)
                if [ x"$option_arg" != x ]; then
                    case $option_arg in
                        [\\/$]* | ?:[\\/]* | NONE | '' )
                            prefix=$option_arg
                            ;;
                        *)  
                            echo "Prefix path must be absolute."
                            exit 3
                            ;;
                    esac
                else
                    echo "No path provided for --prefix"
                    exit 3
                fi
                if [ $legacy_format = false ]; then
                    shift
                fi
                ;;
            -b|--build-dir)
                if [ x"$option_arg" != x ]; then
                    case $option_arg in
                        [\\/$]* | ?:[\\/]* | NONE | '' )
                            build_dir=$option_arg
                            ;;
                        *)
                            build_dir=$PWD/$option_arg
                            ;;
                    esac
                else
                    echo "No path provided for --build-dir"
                    exit 3
                fi
                if [ $legacy_format = false ]; then
                    shift
                fi
                ;;
            -j|--parallel-jobs)
                if [ x"$option_arg" != x ]; then
                    jobs=$option_arg
                else
                    echo "No number specified for --parallel-jobs"
                    exit 3
                fi
                if [ $legacy_format = false ]; then
                    shift
                fi
                ;;
            --threads)
                echo "The 'threads' argument has been re-named 'parallel-jobs'."
                echo "Please re-run with correct argument name"
                exit 3
                ;;
            -v|--verbosity)
                if [ x"$option_arg" != x ]; then
                    verbosity=$option_arg
                else
                    echo "No verbosity specified for --verbosity"
                    exit 3
                fi
                if [ $legacy_format = false ]; then
                    shift
                fi
                ;;
            --main-proj)
                if [ x"$option_arg" != x ]; then
                    main_proj=$option_arg
                else
                    echo "No main project specified for --main-proj."
                    exit 3
                fi
                if [ $legacy_format = false ]; then
                    shift
                fi
                ;;
            --main-proj-version)
                if [ x"$option_arg" != x ]; then
                    main_proj_version=$option_arg
                else
                    echo "No main project version specified for --main-proj-version."
                    exit 3
                fi
                if [ $legacy_format = false ]; then
                    shift
                fi
                ;;
            --main-proj-sha)
                if [ x"$option_arg" != x ]; then
                    main_proj_sha=$option_arg
                else
                    echo "No main project specified for --main-proj-sha."
                    exit 3
                fi
                if [ $legacy_format = false ]; then
                    shift
                fi
                ;;                
            -s|--skip)
                if [ x"$option_arg" != x ]; then
                    coin_skip_projects=$option_arg
                else
                    echo "No projects specified with --skip."
                    exit 3
                fi
                if [ $legacy_format = false ]; then
                    shift
                fi
                ;;
            --time)
                if [ x"$option_arg" != x ]; then
                    checkout_time=$option_arg
                else
                    echo "No checkout time specified with --time."
                    exit 3
                fi
                if [ $legacy_format = false ]; then
                    shift
                fi
                ;;
            --enable-msvc)
                configure_options["$arg"]=""
                disable_uninstalled=false
                ;;
            --disable-pkg-config)
                configure_options["$arg"]=""
                disable_uninstalled=false
                ;;
            --enable-debug)
                configure_options["$arg"]=""
                enable_debug=true
                ;;
            -h|--help)
                help
                exit 0
                ;;
            -c|--configure-help)
                configure_help=true
                no_prompt=true
                ;;
            --skip-dependencies)
                skip_dependencies=true
                ;;
            --sparse)
                sparse=true
                ;;
            --svn)
                VCS=svn
                ;;
            --git)
                VCS=git
                ;;
            --ssh)
                ssh_checkout=true
                ;;
            -d|--debug)
                set -x
                ;;
            --rebuild)
                rebuild=true
                ;;
            --reconfigure)
                reconfigure=true
                ;;
            -t|--test)
                run_test=true
                ;;
            --test-all)
                run_all_tests=true
                ;;
            --no-third-party)
                get_third_party=false
                ;;
            -n|--no-prompt)
                no_prompt=true
                ;;
            --skip-update)
                skip_update=true
                ;;
            --latest-release)
                get_latest_release=true
                ;;
            fetch)
                num_actions+=1
                fetch=true
                ;;
            build)
                num_actions+=1
                build=true
                ;;
            install)
                num_actions+=1
                install=true
                ;;
            uninstall)
                num_actions+=1
                uninstall=true
                ;;
            *)
                if [[ "$arg" == *=* ]] || [[ "$arg" == --* ]]; then
                    configure_options["$arg"]=""
                elif [[ $arg == *:* ]]; then
                    if [ `echo $arg | cut -d ':' -f 1` = https ] ||
                       [ `echo $arg | cut -d '@' -f 1` = git ]; then
                        main_proj=`echo $arg | cut -d ':' -f 1-2`
                        main_proj_version=`echo $arg | cut -d ':' -f 3`
                    else
                        main_proj=${arg%%:*}
                        main_proj_version=${arg#*:}
                    fi
                else
                    main_proj=$arg
                fi
                ;;
        esac
    done
}

function user_prompts {

    if [ $no_prompt = false ]; then
        echo "Entering interactive mode (suppress with --no-prompt)..."
        echo 
    fi

    # Prompt user for what actions to perform
    if [ $num_actions = 0 ]; then
        if [ $no_prompt = "false" ]; then
            echo "Please choose an action by typing 1-4."
            echo " 1. Fetch source code of a project and its dependencies."
            echo " 2. Build a project and its dependencies."
            echo " 3. Install a project and its dependencies."
            echo " 4. Help"
            echo -n "=> "
            read choice
            case $choice in
                1)
                    fetch=true
                    ;;
                2)
                    build=true
                    echo "Please specify a build directory (can be relative or absolute)."
                    echo -n "=> "
                    read user_build_dir
                    case $user_build_dir in
                        [\\/$]* | ?:[\\/]* | NONE | '' )
                            build_dir=$user_build_dir
                            ;;
                        *)
                            build_dir=$PWD/$user_build_dir
                            ;;
                    esac
                    ;;
                3) 
                    install=true
                    echo "Please specify an install directory (can be relative or absolute)."
                    echo -n "=> "
                    read prefix
                    ;;
                4)
                    help
                    exit 0
                    ;;
            esac
        else
            if [ $configure_help = false ]; then
                help
                exit 0
            fi
        fi
    fi

    if [ x"$prefix" != x ] && [ build = "false" ]; then
        echo "Prefix should only be specified with the build command"
        exit 3
    fi

    # If main project is not set, prompt user to pick one or return error
    if [ x$main_proj = x ]; then
        if [ $no_prompt = false ]; then
            echo
            echo "Please choose a main project to fetch/build by typing 1-18"
            echo "or simply type the repository name of another project not" 
            echo "listed here (it must be a project with a 'Dependencies' file)."
            echo " 1. Osi"
            echo " 2. Clp"
            echo " 3. Cbc"
            echo " 4. DyLP"
            echo " 5. FlopC++"
            echo " 6. Vol"
            echo " 7. SYMPHONY"
            echo " 8. Smi"
            echo " 9. CoinMP"
            echo " 10. Bcp"
            echo " 11. Ipopt"
            echo " 12. Alps"
            echo " 13. BiCePS"
            echo " 14. Blis"
            echo " 15. Dip"
            echo " 16. Bonmin"
            echo " 17. Couenne"
            echo " 18. Optimization Services"
            echo " 19. MibS"
            echo " 20. DisCO"
            echo " 21. All"
            echo " 22. Let me enter another project"
            echo -n "=> "
            read choice
            echo
            case $choice in
                1)  main_proj=Osi;;
                2)  main_proj=Clp;;
                3)  main_proj=Cbc;;
                4)  main_proj=DyLP;;
                5)
                    if [ $VCS = git ]; then
                        main_proj=FlopCpp
                    else
                        main_proj=FlopC++
                    fi
                    ;;
                6)  main_proj=Vol;;
                7)  main_proj=SYMPHONY;;
                8)  main_proj=Smi;;
                9)  main_proj=CoinMP;;
                10)  main_proj=Bcp;;
                11)  main_proj=Ipopt;;
                12)
                    if [ $VCS = git ]; then
                        main_proj=CHiPPS-ALPS
                    else
                        main_proj=CHiPPS/Alps
                    fi
                    ;;
                13) 
                    if [ $VCS = git ]; then
                        main_proj=CHiPPS-BiCePS
                    else
                        main_proj=CHiPPS/Bcps
                    fi
                    ;;
                14) 
                    if [ $VCS = git ]; then
                        main_proj=CHiPPS-BLIS
                    else
                        main_proj=CHiPPS/Blis
                    fi
                    ;;
                15)  main_proj=Dip;;
                16)  main_proj=Bonmin;;
                17)  main_proj=Couenne;;
                18)  main_proj=OS;;
                19)  main_proj=MibS;;
                20)  main_proj=DisCO;;
                21)  main_proj=COIN-OR-OptimizationSuite;;
                22)
                    echo "Enter the name or URL of the project"
                    echo -n "=> "
                    read choice2
                    main_proj=$choice2
                    ;;
                *)  main_proj=$choice;;
            esac
        else
            if [ $configure_help = "true" ]; then
                echo "For help with problem configuration, please specify a project"
                echo "For example 'coinbrew Xyz --configure-help'"
            else
                echo "In non-interactive mode, main project must be specified."
            fi
            exit 20
        fi
    fi

    ### Main Project should now be set ###
    
    # Figure out project URL. First guess at correct values,
    # change later if project is already checked out 
    if [ `echo $main_proj | cut -d ':' -f 1` = https ] ||
           [ `echo $main_proj | cut -d '@' -f 1` = git ]; then
        #We assume this is a fork of a git project
        main_proj_url=$main_proj
        if [ `echo $main_proj | cut -d ':' -f 1` = https ]; then
            main_proj=`echo $main_proj_url | cut -d '/' -f 5 | cut -d '.' -f 1`
        else
            main_proj=`echo $main_proj | cut -d '/' -f 2 | cut -d '.' -f 1`
        fi
    elif [ $VCS = "git" ]; then
        if [ $ssh_checkout = "false" ]; then
            main_proj_url="https://github.com/coin-or/$main_proj"
        else
            main_proj_url="git@github.com:coin-or/$main_proj"
        fi
    else
        main_proj_url="https://projects.coin-or.org/svn/$main_proj/$main_proj_version/$main_proj"
    fi

    # Figure out main project version and directory
    if [ x$main_proj_version = x ]; then
        if [ `echo $main_proj_url | cut -d ':' -f 1` = "git@github.com" ] ||
               [ `echo $main_proj_url | cut -d '/' -f 3` = "github.com" ]; then
            main_proj_version=master
        else
            main_proj_version=trunk
        fi
    fi
    if [ x`echo $main_proj | cut -d '-' -f 1` = x"CHiPPS" ]; then
        case `echo $main_proj | cut -d '-' -f 2` in
            ALPS)
                main_proj_dir=Alps
                ;;
            BiCePS)
                main_proj_dir=Bcps
                ;;
            BLIS)
                main_proj_dir=Blis
                ;;
        esac
    else
        main_proj_dir=$main_proj
    fi
    
    # Check whether project is already checked out 
    if [ -d $main_proj_dir ]; then
        cd $main_proj_dir
        # Possibly switch url and version for existing projects
        if [ -d .git ]; then
            if [ $main_proj_version = "trunk" ]; then
                main_proj_version=master
            fi
            main_proj_url=`git remote -v |  fgrep origin | fgrep fetch | tr '\t' ' ' | tr -s ' '| cut -d ' ' -f 2`
            if [ $fetch = "false" ]; then
                current_rev=`git rev-parse HEAD` 
                if [ `git show-ref --tags | fgrep $current_rev | fgrep releases | cut -d '/' -f 3-` ]; then
		    current_version=`git show-ref --tags | fgrep $current_rev | fgrep releases | cut -d '/' -f 4`
                elif [ `git show-ref --heads | fgrep $current_rev | fgrep stable | cut -d '/' -f 3-` ]; then
		    current_version=`git show-ref --heads | fgrep $current_rev | fgrep stable | cut -d '/' -f 4`
                elif [ `git show-ref --heads | fgrep $current_rev | cut -d '/' -f 3-` ]; then
		    current_version=`git show-ref --heads | fgrep $current_rev | cut -d '/' -f 3`
		else
                    current_version=$current_rev
		fi
                main_proj_version=$current_version
            fi
        else
            if [ $main_proj_version = "master" ]; then
                main_proj_version=trunk
            fi
            main_proj_url="https://projects.coin-or.org/svn/$main_proj/$main_proj_version/$main_proj"
            if [ $fetch = "false" ]; then
                if [ `svn info | fgrep "URL" | cut -d '/' -f 6` = trunk ]; then
                    current_version=trunk
                else
                    current_version=`echo $url | cut -d '/' -f 6-7`
                fi
                main_proj_version=$current_version
            fi
        fi    
        if [ $fetch = "false" ] && [ $build = "true" ]; then
            echo "################################################"
            echo "### Building version $current_version"
            echo "### with existing versions of dependencies."
            echo "### Run 'fetch' first to switch versions" 
            echo "### or to ensure correct dependencies"
            echo "################################################"
            echo 
            if [ $no_prompt = false ]; then
                echo "Fetch now? y/n"
                got_choice=false
                while [ $got_choice = "false" ]; do
                    echo -n "=> "
                    read choice
                    case $choice in
                        y|n) got_choice=true;;
                        *) ;;
                    esac
                done
                case $choice in
                    y)
                        fetch="true"
                        ;;
                    n)
                        ;;
                esac
            fi
        fi
        cd $root_dir
    elif [ $fetch = "false" ]; then
        # Project is not checked out and fetching is not requested
        echo "It appears that project has not been fetched yet."
        if [ $configure_help = "false" ]; then
            echo "Fetching automatically..."
            fetch=true
        else
            echo "Please fetch before asking for help on configuration."
            exit 30
        fi
    fi

    # Figure out if the user really wants a release (for git main projects only)
    if [ `echo $main_proj_url | cut -d ':' -f 1` = "git@github.com" ] ||
           [ `echo $main_proj_url | cut -d '/' -f 3` = "github.com" ]; then
        latest_release=`git ls-remote --tags $main_proj_url`
	if echo "$latest_release" | fgrep releases &> /dev/null ; then
	  latest_release=`echo "$latest_release" | fgrep releases | \
	  	cut -d '/' -f 4 | sort -nr -t. -k1,1 -k2,2 -k3,3 | head -1`
	fi
        if [ $get_latest_release = "true" ] ; then
	  if [ -n "$latest_release" ] ; then
            echo 
            if [ x$main_proj_version != x ]; then
                echo "Fetching latest release $latest_release rather than specified version $main_proj_version."
            else
                echo "Fetching latest release $latest_release"
            fi
            echo
            main_proj_version="releases/$latest_release"
	  else
	    echo
	    echo "It appears that $main_proj has no releases. You'll need to specify a branch as ${main_proj}:branch."
	    exit 31
	  fi
        fi
        if [ $main_proj_version = "master" ] && \
	   ([ $fetch = "true" ] || [ $install = "true" ]) && \
	   [ -n "$latest_release" ] ; then
            echo "NOTE: You are working with the development version."
            echo "      You might consider the latest release version,"
            echo "      which appears to be releases/$latest_release"
            echo "      To fetch this release, execute coinbrew as"
            echo 
            echo "      coinbrew fetch $main_proj:releases/$latest_release"
            echo
        fi
    
        if [ x$main_proj != x ] && [ x$main_proj_version = x ] && [ $fetch = true ] &&
               [ $no_prompt = false ]; then
            echo
            echo "It appears that the last 10 releases of $main_proj are"
            git ls-remote --tags $main_proj_url | fgrep releases | cut -d '/' -f 4 | sort -nr -t. -k1,1 -k2,2 -k3,3 | head -10
            echo "Do you want to work with the latest release? (y/n)"
            got_choice=false
            while [ $got_choice = "false" ]; do
                echo -n "=> "
                read choice
                case $choice in
                    y|n) got_choice=true;;
                    *) ;;
                esac
            done
            case $choice in
                y) main_proj_version=releases/`git ls-remote --tags $main_proj_url | fgrep releases | cut -d '/' -f 4 | sort -nr -t. -k1,1 -k2,2 -k3,3 | head -1`
                   ;;
                n) echo "Please enter another version name in the form of"
                   if [ $VCS = "svn" ]; then
                       echo 'trunk', 'releases/x.y.z', or 'stable/x.y'
                   else
                       echo 'master', 'releases/x.y.z', or 'stable/x.y'
                   fi
                   echo -n "=> "
                   read choice
                   main_proj_version=$choice
                   ;;
            esac
            echo
        fi
    fi

    # Figure out if this is a re-build and the user specified new options
    if [ -e $build_dir/.config/$main_proj-$main_proj_version ] &&
           [ $build = "true" ] && [ $reconfigure = false ]; then
        echo "###"
        echo "### Cached configuration options from previous build found."
        echo "###"
        if [ x"${#configure_options[*]}" != x0 ]; then
            echo
            echo "You are trying to run the build again and have specified"
            echo "configuration options on the command line."
            echo
            if [ $no_prompt = false ]; then
                echo "Please choose one of the following options."
                echo " The indicated action will be performed for you AUTOMATICALLY"
                echo "1. Run the build again with the previously specified options."
                echo "   This can also be accomplished invoking the build"
                echo "   command without any arguments."
                echo "2. Configure in a new build directory (whose name you will be"
                echo "   prmpted to specify) with new options."
                echo "3. Re-configure in the same build directory with the new"
                echo "   options. This option is not recommended unless you know"
                echo "   what you're doing!."
                echo "4. Quit"
                echo
                got_choice=false
                while [ $got_choice = "false" ]; do
                    echo "Please type 1, 2, 3, or 4"
                    echo -n "=> "
                    read choice
                    case $choice in
                        1|2|3|4) got_choice=true;;
                        *) ;;
                    esac
                done
                case $choice in
                    1)  ;;
                    2)
                        echo "Please enter a new build directory:"
                        echo -n "=> "
                        read dir
                        if [ x"$dir" != x ]; then
                            case $dir in
                                [\\/$]* | ?:[\\/]* | NONE | '' )
                                    build_dir=$dir
                                    ;;
                                *)
                                    build_dir=$PWD/$dir
                                    ;;
                            esac
                        fi
                        ;;
                    3)
                        rm $build_dir/.config/$main_proj-$main_proj_version
                        reconfigure=true
                        ;;
                    4)
                        exit 0
                esac
            else
                echo "Please re-run the build and force reconfiguration with --reconfigure."
                echo "Exiting..."
                exit 10
            fi
        fi
    fi

    # Return error is configuration options were specified, but no build command
    if [ x"${#configure_options[*]}" != x0 ] && [ $build = "false" ]; then
        echo "Configuration options should be specified only with build command"
        exit 3
    fi    
}

function fetch_proj {
    current_rev=
    if [ -d $dir ]; then
        cd $dir
        if [ -d .svn ]; then
            # Get current version and revision
            current_url=`svn info | fgrep "URL: https" | cut -d " " -f 2`
            current_rev=`svn info | fgrep "Revision:" | cut -d " " -f 2`
            if [ $proj = "BuildTools" ] &&
                   [ `echo $url | cut -d '/' -f 6` = 'ThirdParty' ]; then
                if [ `echo $current_url | cut -d '/' -f 8` = trunk ]; then
                    current_version=trunk
                else
                    current_version=`echo $url | cut -d '/' -f 8-9`
                fi
            elif [ $proj = "CHiPPS" ]; then
                if [ `echo $current_url | cut -d '/' -f 7` = trunk ]; then
                    current_version=trunk
                else
                    current_version=`echo $url | cut -d '/' -f 7-8`
                fi
            elif [ $proj = "Data" ]; then
                if [ `echo $current_url | cut -d '/' -f 7` = trunk ]; then
                    current_version=trunk
                else
                    current_version=`echo $url | cut -d '/' -f 7-8`
                fi
            else
                if [ `echo $current_url | cut -d '/' -f 6` = trunk ]; then
                    current_version=trunk
                else
                    current_version=`echo $url | cut -d '/' -f 6-7`
                fi
            fi
            if [ $skip_update = "false" ]; then
                if [ $current_version != $version ]; then
                    print_action "Switching $dir to $version"
                    svn --non-interactive --trust-server-cert --ignore-externals switch $url
                    if [ $dir = $main_proj_dir ]; then
                        rm -f Dependencies
                        svn cat --non-interactive --trust-server-cert https://projects.coin-or.org/svn/$proj/$version/Dependencies > Dependencies
                    fi
                else
                    print_action "Updating $dir"
                    svn --non-interactive --trust-server-cert --ignore-externals update
                    if [ $dir = $main_proj_dir ]; then
                        rm -f Dependencies
                        svn cat --non-interactive --trust-server-cert https://projects.coin-or.org/svn/$proj/$version/Dependencies > Dependencies
                    fi
                fi
            else
                print_action "Skipping update of $dir"
            fi
            new_rev=`svn info | fgrep "Revision:" | cut -d " " -f 2`
        else
            if [ $version = "trunk" ] ; then
                version=master
            elif [ `echo $version | cut -d '/' -f 1` = "branches" ]; then
                version=`echo $version | cut -d '/' -f 2`
            fi
            current_version=`git branch | grep \* | cut -d ' ' -f 2`
            if [ $current_version = "(HEAD" ]; then
                current_version=`git branch | grep \* | cut -d ' ' -f 5 | cut -d ')' -f 1`
            fi
            current_rev=`git rev-parse HEAD`
            if [ $skip_update = "false" ]; then
                if [ $current_version != $version ] ||
                       ([ x$sha != x ] && [[ $current_rev != $sha* ]]) ||
                       [ x$checkout_time != x ]; then
                    git fetch --tags
                    if [ x$sha != x ]; then
                        print_action "Switching $dir to SHA $sha"
                        git checkout $sha
                    elif [ x"$checkout_time" != x ]; then
                        print_action "Checking out $dir version $version as of $checkout_time"
                        git checkout `git rev-list -n 1 --first-parent --before="$checkout_time" $version`
                    else
                        print_action "Switching $dir to $version"
                        git checkout $version
                    fi
                    if [ `git branch | grep \* | cut -d ' ' -f 2` != "(HEAD" ]; then
                        git pull
                    fi
                else
                    print_action "Updating $dir"
                    if [ `git branch | grep \* | cut -d ' ' -f 2` != "(HEAD" ]; then
                        git pull
                    fi
                fi
            else
                print_action "Skipping update of $dir"
            fi
            new_rev=`git rev-parse HEAD`
        fi
    elif [ x`echo $url | cut -d '/' -f 3` = x"projects.coin-or.org" ]; then
        print_action "Fetching $dir $version"
        svn co --non-interactive --trust-server-cert --ignore-externals $url $dir
        cd $dir
        if [ $dir = $main_proj_dir ]; then
            rm -f Dependencies
            svn cat --non-interactive --trust-server-cert https://projects.coin-or.org/svn/$proj/$version/Dependencies > Dependencies
        fi
        new_rev=`svn info | fgrep "Revision:" | cut -d ' ' -f 2`
    else
        if [ $version = "trunk" ] ; then
            version=master
        fi
        if [ $sparse = "true" ]; then
            print_action "Fetching $dir $version"
            mkdir $dir
            cd $dir
            git init
            git remote add origin $url
            git config core.sparsecheckout true
            echo $proj/ >> .git/info/sparse-checkout
            git fetch --tags
            git checkout $version
            cd -
        else
            if [ x$sha = x ]; then
                print_action "Fetching $dir $version"
                git clone --branch=$version $url $dir
            else
                print_action "Fetching $dir SHA $sha"
                git clone $url $dir
                cd $dir
                git checkout $sha
                cd -
            fi
            cd $dir
        fi     
        new_rev=`git rev-parse HEAD`
    fi
    cd $root_dir

    # If this is a third party project, fetch the source if desired
    if [ $get_third_party = "true" ] &&
           ([ x$current_rev != x$new_rev ] ||
                [ $current_version != $version ]) &&
           [ `echo $dir | cut -d '/' -f 1` = ThirdParty ]; then
        tp_proj=`echo $dir | cut -d '/' -f 2`
        if [ -e $dir/get.$tp_proj ]; then
            cd $dir
            ./get.$tp_proj
            touch .build
            cd -
        else
            echo "Not downloading source for $tp_proj..."
        fi
    fi  
}
        
function build_proj {
    mkdir -p $build_dir/$dir/$version_num
    echo -n $dir/$version_num" " >> $build_dir/coin_subdirs.txt
    cd $build_dir/$dir/$version_num
    
    if [ ! -e config.status ] || [ $reconfigure = "true" ]; then
        if [ $reconfigure = "true" ]; then
            print_action "Reconfiguring $dir $version_num"
        else
            print_action "Configuring $dir $version_num"
        fi
        if [ -e $root_dir/$dir/$dir/configure ]; then
            config_script="$root_dir/$dir/$dir/configure"
        else
            config_script="$root_dir/$dir/configure"
        fi
        if [ $verbosity -ge 3 ] || ( [ $verbosity -ge 2 ] &&
                                         [ x$main_proj != x ] &&
                                         [ $main_proj_dir = $dir ]); then
            "$config_script" --disable-dependency-tracking --prefix=$prefix "${!configure_options[@]}"
        else
            set +e
            "$config_script" --disable-dependency-tracking --prefix=$prefix "${!configure_options[@]}" > /dev/null
            if [ $? -ne 0 ]; then
                echo
                echo "Configuration failed, re-running with output enabled"
                echo
                "$config_script" --disable-dependency-tracking --prefix=$prefix "${!configure_options[@]}" 
                exit 1
            fi
            set -e
        fi
    fi
    if [ $rebuild = "true" ]; then
        print_action "Cleaning $dir"
        if [ $verbosity = 4 ]; then
            $MAKE clean
        else
            set +e
            $MAKE clean > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                $sudo $MAKE clean > /dev/null
                echo
                echo "Build failed, see error output above"
                echo
                exit 1
            fi
            set -e
        fi
    fi
    print_action "Building $dir $version_num"
    if [ $verbosity -ge 2 ]; then
        if [ x$main_proj != x ] && [ $main_proj_dir = $dir ]; then
            invoke_make $verbosity ""
        else
            invoke_make $(($verbosity-1)) ""
        fi
    else
        invoke_make 1 ""
    fi
    if [ $run_all_tests = "true" ]; then
        print_action "Running $dir unit test"
        invoke_make "false" test
    elif [ $run_test = "true" ] && [ x$main_proj != x ]; then
        if [ $main_proj_dir = $dir ]; then
            print_action "Running $proj unit test"
            invoke_make "false" test
        fi
    fi
    cd $root_dir
}

function install_proj {
    print_action "Installing $dir $version_num"
    cd $build_dir/$dir/$version_num
    sudo=""
    if [ ! -w $prefix ]; then
        if [ ! $(id -u) = 0 ]; then
            echo "Prefix is not writable."
            echo "Install step needs to be run with sudo"
            sudo=sudo
        fi
    fi
    if [ $verbosity -ge 3 ]; then
        invoke_make $(($verbosity-1)) install
    else
        invoke_make 1 install
    fi
    cd $root_dir
}

function uninstall_proj {
    print_action "Uninstalling $dir"
    cd $build_dir/$dir/$version_num
    sudo=""
    if [ ! -w $prefix ]; then
        if [ ! $(id -u) = 0 ]; then
            echo "Prefix is not writable."
            echo "Uninstall step needs to be run with sudo"
            sudo=sudo
        fi
    fi
    if [ $verbosity -ge 3 ]; then
        invoke_make $(($verbosity-1)) uninstall
    else
        invoke_make 1 uninstall
    fi
    cd $root_dir
}

# This is some old code that I don't think is necessary
function uninstall_all {
    # We have to uninstall in reverse order
    # subdirs must be defined for this to work
    for ((dir=${#subdirs[@]}-1; i>=0; i--))
    do
        if [ $build_dir != $PWD ]; then
            proj_dir=`echo $dir | cut -d '/' -f 1`
            if [ $proj_dir = "Data" ] || [ $proj_dir = "ThirdParty" ]; then
                proj_dir=$dir
            fi
            cd $build_dir/$proj_dir
        else
            cd $dir
        fi
        print_action "Uninstalling $proj_dir"
        invoke_make $verbosity uninstall
        cd $root_dir
    done
    if [ -e $main_proj ]; then
        if [ $build_dir != $PWD ]; then
            mkdir -p $build_dir/$main_proj_dir
            cd $build_dir/$main_proj_dir
        else
            cd $main_proj_dir
        fi
    fi
    print_action "Uninstalling $main_proj"
    invoke_make $verbosity uninstall
    cd $root_dir
}
    
# Exit when command fails
set -e
#Attempt to use undefined variable outputs error message, and forces an exit
set -u
#Causes a pipeline to return the exit status of the last command in the pipe
#that returned a non-zero return value.
set -o pipefail

# Set defaults
root_dir=$PWD
declare -i num_actions
num_actions=0
sparse=false
prefix=
coin_skip_projects=
svn=true
fetch=false
build=false
install=false
uninstall=false
run_test=false
run_all_tests=false
declare -A configure_options
configure_options=()
jobs=1
build_dir=
rebuild=false
reconfigure=false
get_third_party=true
verbosity=1
main_proj=
main_proj_version=
main_proj_sha=
main_proj_dir=
MAKE=make
VCS=git
no_prompt=false
skip_update=false
ssh_checkout=false
configure_help=false
sudo=""
checkout_time=
disable_uninstalled=true
enable_debug=false
skip_dependencies=false
get_latest_release=false

echo "Welcome to the COIN-OR fetch and build utility"
echo 
echo "For help, run script with --help."
echo 

parse_args "$@"

#Set the default build directory
if [ x$build_dir = x ] ; then
    if [ $enable_debug = "false" ]; then
       build_dir=$root_dir/build
    else
       build_dir=$root_dir/build-debug
    fi
fi

#Try to create the build directory if it doesn't exist
if [ ! -d $build_dir ]; then
    set +e
    mkdir -p $build_dir 2> /dev/null
    set -e
fi

#Check whether build directory creation was successful
if [ -d $build_dir ]; then
    echo "Package will be built in $build_dir"
    echo
else
    echo "Build directory cannot be created."
    echo "Please create it and make it writable."
    echo "Then re-run script"
    exit 4
fi

user_prompts

# This changes the default separator used in for loops to carriage return.
# We need this later.
TMP_IFS=$IFS
IFS=$'\n'

# Set the install directory. Clean up the version in case we're doing an
# implied fetch on a build request. Only important if the user has deleted
# the code but left the build directory (with configuration options) intact.

if [ $build = "true" ] || [ $install = "true" ] || [ $uninstall = "true" ]; then
    version_num=`echo $main_proj_version | cut -d '/' -f 2`
    if [ -e $build_dir/.config/$main_proj-$version_num ]; then
        for i in `cat $build_dir/.config/$main_proj-$version_num`
        do
            if [[ "$i" == --with-coin-instdir* ]]; then
                prefix=`echo $i | cut -d '=' -f 2`
            fi
        done
    fi
    if [ $build = "true" ]; then
        if [ x$prefix = x ]; then
            prefix=$root_dir/dist
            mkdir -p $root_dir/dist
            install=true
        elif [ ! -d $prefix ]; then
            set +e
            mkdir -p $prefix 2> /dev/null
            set -e
        fi
        if [ -d $prefix ] && [ $install = "false" ]; then
            echo
            echo "Installation directory is writable."
            echo "Install will be done automatically."
            echo
            install=true
        fi
    fi
    if [ $install = "true" ]; then
        configure_options["--with-coin-instdir=$prefix"]=""
        echo "Package will be installed to $root_dir/dist/ "
        echo
        if [ ! -w $prefix ]; then
            echo "Installation directory is not writable."
            echo "Sudo authentication required for installation."
            echo "NOTE: Only installation will be done using sudo."
            echo "      Builds are done as normal user."
            sudo mkdir -p $prefix
        fi
    fi
fi

# Cache configuration options. Clean up the version number as per above, in
# case we're doing an implied fetch.

if [ $build = "true" ]; then
    version_num=`echo $main_proj_version | cut -d '/' -f 2`
    if [ ! -e $build_dir/.config/$main_proj-$version_num ] ||
           [ $reconfigure = "true" ]; then
        echo "Caching configuration options..."
        mkdir -p $build_dir/.config
        printf "%s\n" "${!configure_options[@]}" > \
	  $build_dir/.config/$main_proj-$version_num
        printf "%s\n" "${!configure_options[@]}"
    else
        get_cached_options $build_dir/.config/$main_proj-$version_num
    fi
fi

#Find out if we're supposed to skip any projects
for c in ${!configure_options[@]} ; do
    if [[ $c == --without-* ]]; then
        found_project=true
        proj_name=`echo "$c" | cut -d '-' -f 4`
        proj_name=${proj_name,,}
        case $proj_name in
            asl)
                proj_dir="ThirdParty/ASL"
                ;;
            blas)
                proj_dir="ThirdParty/Blas"
                ;;
            filtersqp)
                proj_dir="ThirdParty/FilterSQP"
                ;;
            glpk)
                proj_dir="ThirdParty/Glpk"
                ;;
            hsl)
                proj_dir="ThirdParty/HSL"
                ;;
            lapack)
                proj_dir="ThirdParty/Lapack"
                ;;
            metic)
                proj_dir="ThirdParty/Metis"
                ;;
            mumps)
                proj_dir="ThirdParty/Mumps"
                ;;
            scip)
                proj_dir="ThirdParty/SCIP"
                ;;
            alps)
                proj_dir="Alps"
                ;;
            bcp)
                proj_dir="Bcp"
                ;;
            bcps)
                proj_dir="Bcps"
                ;;
            blis)
                proj_dir="Blis"
                ;;
            bonmin)
                proj_dir="Bonmin"
                ;;
            cbc)
                proj_dir="Cbc"
                ;;
            cgl)
                proj_dir="Cgl"
                ;;
            clp)
                proj_dir="Clp"
                ;;
            coinmp)
                proj_dir="CoinMP"
                ;;
            coinutils)
                proj_dir="CoinUtils"
                ;;
            couenne)
                proj_dir="Couenne"
                ;;
            dip)
                proj_dir="Dip"
                ;;
            disco)
                proj_dir="DisCO"
                ;;
            dylp)
                proj_dir="DyLP"
                ;;
            flopcpp)
                proj_dir="FlopCpp"
                ;;
            ipopt)
                proj_dir="Ipopt"
                ;;
            mibs)
                proj_dir="MibS"
                ;;
            os)
                proj_dir="OS"
                ;;
            osi)
                proj_dir="Osi"
                ;;
            symphony)
                proj_dir="SYMPHONY"
                ;;
            smi)
                proj_dir="Smi"
                ;;
            vol)
                proj_dir="Vol"
                ;;
            cppad)
                proj_dir="cppad"
                ;;
            *)
                echo "Warning: Unknow project $proj_name"
                found_project=false
        esac
        if [ $found_project = "true" ]; then
            if [ x"$coin_skip_projects" != x ]; then
                coin_skip_projects=$proj_dir
            else
                coin_skip_projects="${coin_skip_projects} $proj_dir"
            fi
        fi
    fi
done

# Fetch main project first
if [ x$main_proj != x ]; then
    url=$main_proj_url
    dir=$main_proj_dir
    proj=$main_proj
    version=$main_proj_version

# Clean up the version number. Trickery! For something like releases/1.5.4,
# this will return just 1.5.4.  But if there's no '/', you get the whole
# thing back, hence arbitrary branch names like trunk or autotools-update
# come through just fine.

    version_num=`echo $version | cut -d '/' -f 2`
    sha=$main_proj_sha
    if [ $fetch = true ]; then
        fetch_proj
    fi
    if [ $configure_help = true ]; then
        echo "Here is the help output for the main configure script."
        echo
        if [ -e $dir/$dir/configure ]; then
            $dir/$dir/configure --help
        elif [ -e $dir/configure ]; then
            $dir/configure --help
        else
            echo "Can't find configure file for main project!"
        fi
        exit 0
    fi
fi

# Build list of dependencies
if [ $skip_dependencies = "false" ]; then
    if [ -e Dependencies ] && [ x$main_proj = x ]; then
        deps=`cat Dependencies | tr '\t' ' ' | tr -s ' '`
    elif [ -e .coin-or/Dependencies ] && [ x$main_proj = x ]; then
        deps=`cat .coin-or/Dependencies | tr '\t' ' ' | tr -s ' '`
    elif [ x$main_proj != x ] && [ -e $main_proj_dir/Dependencies ]; then
        deps=`cat $main_proj_dir/Dependencies | tr '\t' ' ' | tr -s ' '`
    elif [ x$main_proj != x ] && [ -e $main_proj_dir/.coin-or/Dependencies ]; then
        deps=`cat $main_proj_dir/.coin-or/Dependencies | tr '\t' ' ' | tr -s ' '`
    elif [ x$main_proj != x ] && [ -e $main_proj_dir/$main_proj_dir/Dependencies ]; then
        deps=`cat $main_proj_dir/$main_proj_dir/Dependencies | tr '\t' ' ' | tr -s ' '`
    else
        echo "Can't find dependencies file...exiting"
        echo
        exit 3
    fi
else
    deps=
fi

# Add main project to list (if one is specified)
if [ x$main_proj != x ]; then
    if [ x"$deps" != x ]; then
        deps+=$'\n'
    fi
    if [ `echo $main_proj_url | cut -d ':' -f 1` = "git@github.com" ] ||
           [ `echo $main_proj_url | cut -d '/' -f 3` = "github.com" ]; then    
        deps+="$main_proj_dir $main_proj_url $main_proj_version"
    else
        deps+="$main_proj_dir $main_proj_url"
    fi
fi

#If we are going to build against installed packages, we need to disable
#the uninstalled .pc files. Otherwise, they are preferred.
if ([ $install = "true" ] || [[ $prefix == $root_dir/* ]]) &&
       [ $disable_uninstalled = "true" ]; then
    export PKG_CONFIG_DISABLE_UNINSTALLED=TRUE
    echo "Disabling uninstalled packages"
fi

# Go through each project in order and fetch, build, install (as instructed).
# Skip comments (lines starting with '#').
for entry in $deps
do
    if expr "$entry" : '^#' > /dev/null 2>&1; then continue ; fi
    dir=`echo $entry | tr '\t' ' ' | tr -s ' '| cut -d ' ' -f 1`
    url=`echo $entry | tr '\t' ' ' | tr -s ' '| cut -d ' ' -f 2`
    proj=`echo $url | cut -d '/' -f 5`
    sha=
    # Set the URL of the project, the version, and the build dir
    if [ `echo $url | cut -d ':' -f 1` = "git@github.com" ] ||
       [ `echo $url | cut -d '/' -f 3` = "github.com" ]; then
        #The URL is for a git project
        version=`echo $entry | tr '\t' ' ' | tr -s ' '| cut -d ' ' -f 3`
        if [ $version != "master" ]; then
            version_num=`echo $version | cut -d '/' -f 2`
        else
            version_num=master
        fi
    else
        #The URL is for an SVN project
        if [ $proj = "BuildTools" ] &&
               [ `echo $url | cut -d '/' -f 6` = 'ThirdParty' ]; then
            if [ `echo $url | cut -d '/' -f 8` = trunk ]; then
                version=master
            else
                version=`echo $url | cut -d '/' -f 8-9`
            fi
        elif [ $proj = "CHiPPS" ]; then
            if [ `echo $url | cut -d '/' -f 7` = trunk ]; then
                version=master
            else
                version=`echo $url | cut -d '/' -f 7-8`
            fi
        elif [ $proj = "Data" ]; then
            if [ `echo $url | cut -d '/' -f 7` = trunk ]; then
                version=master
            else
                version=`echo $url | cut -d '/' -f 7-8`
            fi
        else
            if [ `echo $url | cut -d '/' -f 6` = trunk ]; then
                version=master
            else
                version=`echo $url | cut -d '/' -f 6-7`
            fi
        fi
        if [ $version != "master" ]; then
            version_num=`echo $version | cut -d '/' -f 2`
        else
            version_num=master
        fi
        
        if [ ! -d $dir ] && [ $VCS = "git" ]; then
            if [ $proj = "BuildTools" ] || [ $proj = "Data" ]; then
                if [ $ssh_checkout = "false" ]; then
                    url="https://github.com/coin-or-tools/"
                else
                    url="git@github.com:coin-or-tools/"
                fi
            else
                if [ $ssh_checkout = "false" ]; then
                    url="https://github.com/coin-or/"
                else
                    url="git@github.com:coin-or/"
                fi
            fi
            # Convert SVN URL to a Github one and check out with git
            if [ `echo $version | cut -d '/' -f 1` = "branches" ]; then
                version=`echo $version | cut -d '/' -f 2`
            fi
            svn_repo=`echo $url | cut -d '/' -f 5`
            if [ `echo $dir | cut -d "/" -f 1` = "ThirdParty" ]; then
                url+=`echo $dir | sed s"|/|-|"`
            elif [ $proj = "Data" ]; then
                url+=`echo $dir | sed s"|/|-|"`
            elif [ $proj = "CHiPPS" ]; then
                url+="CHiPPS-"$dir
            elif [ $proj = "FlopC++" ]; then
                url+="FlopCpp"
            else
                url+=$proj
            fi
        fi
    fi

    # Get the source (if requested)
    if [ $fetch = "true" ]; then
        if get_project $dir; then
            if [ x$main_proj_dir = x ] ||  [ $dir != $main_proj_dir ]; then
                fetch_proj
            fi
        else
            print_action "Skipping $dir"
        fi
    fi
    
    # Build the project (if requested)
    if [ $build = "true" ] && [ $dir != "BuildTools" ]; then
        if [ ! -d $dir ] && get_project $dir; then
            print_action "Warning: project $dir is missing"
            fetch_proj
        fi
        if get_project $dir; then
            build_proj
        else
            print_action "Skipping $dir"
        fi
    fi

    # Install the project (if requested)
    if ([ $install = "true" ] ||
            ([ $build = "true" ] && [ -w $prefix ])) &&
           [ $dir != "BuildTools" ] && get_project $dir; then
        install_proj
    fi

    # Uninstall the project (if requested)
    if [ $uninstall = "true" ] && [ -e $build_dir/$dir ]; then
        uninstall_proj
    fi
done

if [ x$prefix != x ] && [ $uninstall = "true" ]; then
    sudo=""
    if [ ! -w $prefix ]; then
        if [ ! $(id -u) = 0 ]; then
            sudo=sudo
        fi
    fi
    echo
    echo "Removing $prefix/include/coin and $prefix/share/coin"
    echo
    $sudo rm -rf $prefix/include/coin $prefix/share/coin
fi

if [ $install = "true" ]; then
    if command -v ld >/dev/null 2>&1; then
        if [[ `ld --verbose | grep SEARCH_DIR` =~ $prefix/lib ]]; then
            if command -v /sbin/ldconfig >/dev/null 2>&1; then
                echo
                echo "Running ldconfig to update library cache"
                echo
                if command -v sudo >/dev/null 2>&1; then
                    sudo /sbin/ldconfig
                else
                    /sbin/ldconfig
                fi
            fi
        fi
    fi
fi

if [ $install = "true" ]; then
    echo
    echo "Install completed. If executing any of the installed"
    echo "binaries results in an error that shared libraries cannot"
    echo "be found, you may need to"
    echo "  - add 'export LD_LIBRARY_PATH=$prefix/lib' to your ~/.bashrc (Linux)"
    echo "  - add 'export DYLD_LIBRARY_PATH=$prefix/lib' to ~/.bashrc (OS X)"
    echo
fi


IFS=$TMP_IFS

