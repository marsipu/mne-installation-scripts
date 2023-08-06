#!/bin/bash
# This batch file creates a mne-environment
# It has to be run with bash -i to source .bashrc
echo "Creating MNE-Dev-Environment"
wsl_path="/mnt/c/users/marti/PycharmProjects"
lab_linux_path="/home/martins/PycharmProjects"
# Activate mne-python development-version
if [[ -d $wsl_path ]]
then
    pycharm_path=$wsl_path
elif [[ -d $lab_linux_path ]]
then
    pycharm_path=$lab_linux_path
else
    echo "No matching path found!"
    exit
fi

echo "setting PyCharm-Path to: $pycharm_path" 

# Use mamba or conda?
read -p "Do you want to use mamba? [y/n]:" _solver
if [ $_solver = y ]
then
    solver=mamba
else
    solver=conda
fi

# Install mamba
if [ $solver = mamba ]
then
    echo "Installing mamba"
    conda install --yes --channel=conda-forge --name=base mamba
fi

# Remove existing environment
echo "Removing existing environment"
conda env remove -n mnedev

echo "Installing mne"
curl --remote-name https://raw.githubusercontent.com/mne-tools/mne-python/master/environment.yml
$solver env create -n mnedev -f environment.yml
conda activate mnedev
mne sys_info

rm ./environment.yml

# Install dev-version of mne-python
echo "Installing mne dependencies"
cd "$pycharm_path/mne-python"
python -m pip uninstall -y mne
pip install -e . --config-settings editable_mode=strict
pip install -r requirements_doc.txt
pip install -r requirements_testing.txt
pip install -r requirements_testing_extra.txt
$solver install -y graphviz
$solver install -c conda-forge -y sphinx-autobuild doc8
pre-commit install

# Install dev-version of mne-qt-browser
cd "$pycharm_path/mne-qt-browser"
python -m pip uninstall -y mne_qt_browser
pip install -e . --config-settings editable_mode=strict
pip install -r requirements_testing.txt

# Install dev-version of mne-pipeline-hd
cd "$pycharm_path/mne-pipeline-hd"
pip install -e . --config-settings editable_mode=strict
pip install -r requirements_dev.txt