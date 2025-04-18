:: This batch file creates a mne-environment
:: You need to specify the path to your conda-root and the path to the script-root, where you store the folders 
:: of your development version of mne-python, mne-qt-browser, mne-pipeline-hd etc. in a paths.ini file, like this:
:: conda_root=C:\Users\user\Anaconda3
:: script_root=C:\Users\user\Documents\GitHub\mne-python

:: This disables printing every command from the script
@echo off
:: This is necessary to allow setting variables inside if-blocks
:: https://superuser.com/questions/78496/variables-in-batch-file-not-being-set-when-inside-if
setlocal enabledelayedexpansion

:: Read version
for /f "tokens=1,2 delims==" %%a in (./version.txt) do (
    if %%a==version set version=%%b
)
echo Running mne-python installation script %version% for Windows...

:: Read paths from paths.inis
for /f "tokens=1,2 delims==" %%a in (./paths.ini) do (
    if %%a==conda_root set conda_root=%%b
    if %%a==script_root set script_root=%%b
)
echo Conda-Root: %conda_root%
echo Script-Root: %script_root%

:: Check if all paths exist
for %%a in (%conda_root% %script_root%) do (
    if not exist %%a (
        echo Path %%a does not exist, exiting...
        Pause
        exit 1
    )
)

:: Activate Anaconda
call %conda_root%/Scripts/activate.bat %conda_root%

:: Configure package solver
where mamba >nul 2>nul
if %errorlevel%==0 (
    set mamba_installed=true
) else (
    set mamba_installed=false
)

if %mamba_installed%==true (
    set /P use_mamba="Do you want to use mamba? (y/n): "
) else (
    set use_mamba=n
)

if %use_mamba%==y (
    set solver=mamba
    echo "Using mamba as solver..."
) else (
    set solver=conda
    echo "Using conda as solver..."
)

set /P _inst_type="Do you want to install a development environment? (y/n): "

if %_inst_type%==n (
    :: Get version
    set /P _mne_version="Do you want to install a specific version of mne-python? (<version>/n): "

    if !_mne_version!==n (
        set _mne_core=mne-base
        set _mne_full=mne
    ) else (
        set _mne_core=mne-base^=^=!_mne_version!
        set _mne_full=mne^=^=!_mne_version!
    )

    :: Install simple mne-environment
    set /P _core="Do you want to install only core dependencies? (y/n): "

    :: Get environment name
    set /P _env_name="Please enter environment-name: "

    if !_core!==y (
        echo Creating environment "!_env_name!" and installing mne-python with core dependencies...
        call %solver% create --yes --strict-channel-priority --channel=conda-forge --name=!_env_name! !_mne_core!
    ) else (
        echo Creating environment "!_env_name!" and installing mne-python with all dependencies...
        call %solver% create --yes --override-channels --channel=conda-forge --name=!_env_name! !_mne_full!
    )
    
    call %solver% activate !_env_name!

) else (
    :: Remove existing environment
    echo Creating development environment "mnedev"...
    echo Removing existing environment
    call %solver% env remove -n mnedev -y

    echo Installing development version of mne-python
    call curl --remote-name --ssl-no-revoke https://raw.githubusercontent.com/mne-tools/mne-python/main/environment.yml
    call %solver% env create -n mnedev -f environment.yml
    call %solver% activate mnedev

    :: Delete environment.yml
    call del "environment.yml"

    echo Installing mne-python development dependencies...
    :: Install dev-version of mne-python
    cd /d %script_root%/mne-python
    call python -m pip uninstall -y mne
    call pip install -e .[full,test,test_extra,doc]
    call %solver% install -c conda-forge -y sphinx-autobuild doc8 graphviz
    call pre-commit install

    :: Install dev-version of mne-qt-browser
    echo Installing developement version of mne-qt-browser
    cd /d %script_root%/mne-qt-browser
    call python -m pip uninstall -y mne_qt_browser
    call pip install -e .[opengl,tests]

    :: Install dev-version of mne-pipeline-hd
    echo Installing developement version of mne-pipeline-hd
    cd /d %script_root%/mne-pipeline-hd
    call pip install -e .[dev,docs]
)

:: Printing System-Info
call mne sys_info

Pause
exit 0
