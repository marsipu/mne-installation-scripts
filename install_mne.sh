#!/bin/bash
# This batch file creates a mne-environment
# It has to be run with bash -i to source .bashrc
echo "Creating MNE-Dev-Environment"

# Read version
source ./version.txt
echo Running mne-python installation script $version for MacOs/Linux...

# Read paths from paths.ini
source ./paths.ini

# :: Check if all paths exist
paths=($root $conda_root $script_root)
for path in ${paths[@]};
do
    if [ ! -d $path ]
    then
        echo "Path $path does not exist"
        exit 1
    fi
done

# Use mamba or conda?
read -p "Do you want to use mamba? [y/n]: " _solver
if [ $_solver = y ]
then
    solver=mamba
else
    solver=conda
fi

# Install mamba
if [ $solver = mamba ]
then
    echo Installing mamba
    conda install --yes --channel=conda-forge --name=base mamba
fi

read -p "Do you want to install a development environment? (y/n): " _inst_type

if [ $_inst_type == n ]; then
  # Get environment name
  read -p "Please enter environment-name: " _env_name

  # Install simple mne-environment
  read -p "Do you want to install only core dependencies? (y/n): " _core

  if [[ $_core == y ]]; then
    echo Creating environment "$_env_name" and installing mne-python with core dependencies...
    $solver create --yes --strict-channel-priority --channel=conda-forge --name=$_env_name mne-base
  else
    echo Creating environment "$_env_name" and installing mne-python with all dependencies...
    $solver create --yes --override-channels --channel=conda-forge --name=$_env_name mne
  fi

  conda activate $_env_name

else
  # Remove existing environment
  echo "Removing existing environment"
  conda env remove -n mnedev
  rm -rf "$conda_root/envs/mnedev"

  echo "Installing development version of mne-python"
  curl --remote-name --ssl-no-revoke https://raw.githubusercontent.com/mne-tools/mne-python/main/environment.yml
  $solver env create -n mnedev -f environment.yml
  conda activate mnedev

  # Delete environment.yml
  rm "environment.yml"

  echo "Installing mne-python development dependencies..."
  # Install dev-version of mne-python
  cd "$script_root/mne-python" || exit
  python -m pip uninstall -y mne
  pip install -e .
  pip install -r requirements_doc.txt
  pip install -r requirements_testing.txt
  pip install -r requirements_testing_extra.txt
  $solver install -c conda-forge -y sphinx-autobuild doc8 graphviz
  pre-commit install

  # Install dev-version of mne-qt-browser
  echo "Installing developement version of mne-qt-browser"
  cd "$script_root/mne-qt-browser" || exit
  python -m pip uninstall -y mne_qt_browser
  pip install -e .[opengl,tests]

  # Install dev-version of mne-pipeline-hd
  echo "Installing"
  cd "$script_root/mne-pipeline-hd" || exit
  pip install -e .[tests]
fi

# Printing System-Info
mne sys_info

exit 0








# Remove existing environment
echo "Removing existing environment"
conda env remove -n mnedev

echo "Installing mne"
curl --remote-name --ssl-no-revoke https://raw.githubusercontent.com/mne-tools/mne-python/main/environment.yml
$solver env create -n mnedev -f environment.yml
conda activate mnedev
mne sys_info

rm ./environment.yml

# Install dev-version of mne-python
echo "Installing mne dependencies"
cd "$script_root/mne-python"
python -m pip uninstall -y mne
pip install -e . --config-settings editable_mode=strict
pip install -r requirements_doc.txt
pip install -r requirements_testing.txt
pip install -r requirements_testing_extra.txt
$solver install -y graphviz
$solver install -c conda-forge -y sphinx-autobuild doc8
pre-commit install

# Install dev-version of mne-qt-browser
cd "$script_root/mne-qt-browser"
python -m pip uninstall -y mne_qt_browser
pip install -e .[opengl,tests] --config-settings editable_mode=strict

# Install dev-version of mne-pipeline-hd
cd "$script_root/mne-pipeline-hd"
pip install -e .[tests] --config-settings editable_mode=stric