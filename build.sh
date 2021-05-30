red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
echo "[ABOUT] This bash script constructs necessary storage arrangements and ensures that the local environment is suitable to run the program."

# Ask the user if they are building the environment for the client or server side. Client side does not need all of the same packages or storage directories as server side.
echo "[PROMPT] Are you building the environment for the client or server side?"
while true;
do
  read -p "[PROMPT] Enter \"client\" or \"server\": " choice
  if [ $choice == "client" ] || [ $choice == "Client" ]; then
    deploy="CLIENT"
    break
  elif [ $choice == "server" ] || [ $choice == "Server" ]; then
    deploy="SERVER"
    # Build the environment folders and files needed for storing data (Server side only).
    echo "[${deploy} BUILD] Constructing data storage directories, setting data values, and creating essential storage files."

    directories=("data" "data/recordings" "data/stream_frames")

    for directory in ${directories[@]}
    do
      DIR="${directory}"
      if [ ! -d "$DIR" ]; then
        echo "[${deploy} BUILD] Creating directory: ${directory}"
        mkdir "${directory}"
      fi
    done

    ENV_FILE=.env
    if test -f "$ENV_FILE"; then
      max=$(grep MAX_CLIENTS .env | cut -d '=' -f2)
    else
      max=5
      echo "[${deploy} BUILD] .env file not found.\n[${deploy} BUILD] Construcing new .env file with a default MAX_CLIENTS of 5."
      echo "MAX_CLIENTS=${max}\nGMAIL_USER=\nGMAIL_APP_PASSWORD=" > .env
    fi

    for i in `seq 1 $max`
    do
      if [ ! -d "${directories[2]}/${i}" ]; then
        echo "[${deploy} BUILD] Creating storage directory: data/stream_frames/${i}"
        mkdir data/stream_frames/$i
      fi
    done

    touch data/whitelist.txt
    touch data/blacklist.txt
    echo "on" > data/alarm_status.txt
    echo "0" > data/clients.txt
    break
  fi
done


echo "[${deploy} BUILD] Checking Python version"
{
  pvs="$(python3 --version)"
} || {
  echo "${red}[BUILD FAILURE]${reset} Python3 could not be detected on your machine. View step 3 on the README.md to learn how to install a recent version of Python."
  exit
}
IFS='.' read -r -a version <<< "${pvs:7:20}" # convert Python version string to array (i.e., "3.8.5" to 3 8 5)

# Check that machine is using Python 3.8.5 or later
valid=false
if [ $((${version[0]} + 0)) == 3 ]; then
  if [ $((${version[1]} + 0)) == 8 ] && [ $((${version[2]} + 0)) -ge 5 ]; then
      valid=true
  elif [ $((${version[1]} + 0)) -gt 8 ]; then
    valid=true
  fi
elif [[ $((${version[0]} + 0)) -gt 3 ]]; then
  valid=true
fi

if [ "$valid" = true ]; then
  echo "[${deploy} BUILD] Your Python version (${pvs:7:10}) is sufficient."
else
  echo "[${deploy} BUILD] ${red}WARNING${reset}: Your Python version (${pvs:7:10}) is older than the recommended version, Python 3.8.5. Consider updating before running the program."
fi

# Install python module dependencies.
echo "[${deploy} BUILD] Installing Python modules using pip. ${WARNING}"

# Install pip commands using pip3 or pip. If neither commands work, alert the user.
{
  pip3 install --upgrade pip
  pip3 install opencv-python-headless
  pip3 install python-decouple
  if [ $deploy == "SERVER" ]; then
    pip3 install flask
    pip3 install waitress
  fi
} || {
  pip install --upgrade pip
  pip install opencv-python-headless
  pip install python-decouple
  if [ $deploy == "SERVER" ]; then
    pip install flask
    pip install waitress
  fi
} || {
  python -m pip install --upgrade pip
  python -m pip install opencv-python-headless
  python -m pip install python-decouple
  if [ $deploy == "SERVER" ]; then
    python -m pip install flask
    python -m pip install waitress
  fi
} || {
  python3 -m pip install --upgrade pip
  python3 -m pip install opencv-python-headless
  python3 -m pip install python-decouple
  if [ $deploy == "SERVER" ]; then
    python3 -m pip install flask
    python3 -m pip install waitress
  fi
} || {
  echo "${red}[BUILD FAILURE]${reset} Could not install Python modules using pip. View step 3 on README.md for more information on installing Pip or view step 4 on README.md to manually install the required Python packages."
  exit
}
echo "${green}[BUILD SUCCESS]${reset} Your environment appears to be sufficient for this program. View step 4 on README.md for information on how to run the program."
