#!/bin/bash
# Cryptovik "See All Your Stake" Script version 3.1
# Stand with Ukraine!
# If you want - Donate to script author


# colors
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
DARKGRAY='\033[1;30m'
YELLOW='\033[1;33m'
LIGHTPURPLE='\033[1;35m'
UNDERLINE='\033[4m'
NOCOLOR='\033[0m'

# Function to safely parse CSV with proper handling of quoted fields
function parse_csv_to_json() {
    local csv_file="$1"
    # Skip header line and parse CSV properly handling quoted fields
    tail -n +2 "$csv_file" | jq -R -s '
        split("\n") |
        map(select(length > 0)) |
        map(select(test("^#") | not)) |
        map(
            # Split by comma but respect quoted fields
            . as $line |
            # Use regex to properly split CSV respecting quotes
            [match("(?:^|,)(\"(?:[^\"]|\"\")*\"|[^,]*)"; "g").captures[0].string] |
            map(
                # Remove surrounding quotes and unescape double quotes
                if test("^\".*\"$") then
                    .[1:-1] | gsub("\"\""; "\"")
                else
                    .
                end |
                # Trim whitespace
                gsub("^\\s+|\\s+$"; "")
            ) |
            {
                short_name: .[0],
                type: .[1],
                group: .[2],
                category: .[3],
                public_key: .[4],
                long_name: .[5],
                description: .[6],
                url: .[7],
                image: .[8]
            }
        )
    '
}

declare -A data

# stakepools_list.csv from GitHub
STAKEPOOL_URL="https://raw.githubusercontent.com/SOFZP/Solana-Stake-Pools-Research/main/stakepools_list.csv"
STAKEPOOL_CACHE="${HOME}/.cache/stakepools_list.csv"
STAKEPOOL_TMP="/tmp/stakepools_list_tmp.csv"
mkdir -p "$(dirname "$STAKEPOOL_CACHE")"

download_needed=true

if [[ -f "$STAKEPOOL_CACHE" ]]; then
  curl -sf "$STAKEPOOL_URL" -o "$STAKEPOOL_TMP" || {
    echo -e "${YELLOW}⚠️  Cannot fetch latest stakepools_list.csv. Using local cache.${NOCOLOR}"
    download_needed=false
  }

  if [[ "$download_needed" == true ]]; then
    old_hash=$(sha256sum "$STAKEPOOL_CACHE" | awk '{print $1}')
    new_hash=$(sha256sum "$STAKEPOOL_TMP" | awk '{print $1}')
    
    if [[ "$old_hash" == "$new_hash" ]]; then
      # echo -e "${DARKGRAY}ℹ️  stakepools_list.csv is already up-to-date.${NOCOLOR}"
      rm -f "$STAKEPOOL_TMP"
      download_needed=false
    else
      mv "$STAKEPOOL_TMP" "$STAKEPOOL_CACHE"
      # echo -e "${GREEN}✅ stakepools_list.csv updated from GitHub${NOCOLOR}"
    fi
  fi
else
  curl -sf "$STAKEPOOL_URL" -o "$STAKEPOOL_CACHE" || {
    echo -e "${RED}❌ Failed to fetch stakepools_list.csv and no local copy exists.${NOCOLOR}"
    exit 1
  }
  echo -e "${GREEN}✅ stakepools_list.csv downloaded from GitHub${NOCOLOR}"
fi



STAKEPOOL_CONF="$STAKEPOOL_CACHE"



retry_command() {
    local command_str="$1"
    local max_attempts="${2:-5}"
    local default_value="${3:-"N/A"}"
    local show_errors="${4:-"yes"}"
    local attempt=1
    local output=""

    while (( attempt <= max_attempts )); do
        output=$(eval "$command_str" 2>/dev/null)
        if [[ -n "$output" ]]; then
            echo "$output"
            return 0
        else
            sleep 3
        fi
        ((attempt++))
    done

	[[ "$show_errors" =~ ^(yes|true)$ ]] && \
    	echo -e "${RED}Failed to execute command after $max_attempts attempts.\nCommand: $command_str${NOCOLOR}" >&2
	
    echo "$default_value"; return 1
}

function check_key_pair () {
    local DONE_STAKES_REF=($1)
    local KEYS_PAIR="$2"

    local KEY_S_TO_CHECK="${KEYS_PAIR%%+*}"
    local KEY_W_TO_CHECK="${KEYS_PAIR##*+}"
    	
    # Швидка перевірка дублікатів
    for key in "${DONE_STAKES_REF[@]}"; do
        [[ "$KEY_S_TO_CHECK" == "$key" || "$KEY_W_TO_CHECK" == "$key" ]] && return 1
    done
    	
    local RETURN_INFO=""
    local FOUND_S="W"
    local KEY_RESULT="\t"
    
    # Check if it's stake authority
    for j in "${!STAKE_AUTHORITY[@]}"; do
        if [[ "$KEY_S_TO_CHECK" == "${STAKE_AUTHORITY[$j]}" ]]; then
            RETURN_INFO="${STAKE_AUTH_NAMES[$j]}"
            FOUND_S="S"
            KEY_RESULT="$KEY_S_TO_CHECK"
            break
        fi
    done

    # Check if it's withdraw authority
    if [[ "$FOUND_S" == "W" ]]; then
        for k in "${!STAKE_WTHDR[@]}"; do
            if [[ "$KEY_W_TO_CHECK" == "${STAKE_WTHDR[$k]}" ]]; then
                RETURN_INFO="${STAKE_NAMES[$k]}"
                KEY_RESULT="$KEY_W_TO_CHECK"
                break
            fi
        done
    fi

    local RETURN_KEY_TYPE_NAME=""
    if [[ -z "$RETURN_INFO" ]]; then
        RETURN_KEY_TYPE_NAME="$KEY_W_TO_CHECK W \t"
    else
        RETURN_KEY_TYPE_NAME="$KEY_RESULT $FOUND_S $RETURN_INFO"
    fi

    echo "${RETURN_KEY_TYPE_NAME}^${KEY_RESULT} ${DONE_STAKES_REF[*]}"
}

function sort_data() {
    local sortable_data=()
    local sorted_data
    local sort_args=()

    for key in "${!data[@]}"; do
        sortable_data+=("$key:${data[$key]}")
    done

    for criterion in "$@"; do
        IFS=':' read -r column order <<< "$criterion"
        [[ "$order" == "DESC" ]] && order_flag="r" || order_flag=""
        sort_args+=("-k${column},${column}${order_flag}n")
    done

    sorted_data=$(printf "%s\n" "${sortable_data[@]}" | sort -t':' "${sort_args[@]}")

    while IFS=':' read -r key count info active deactivating activating; do
        # Порожнє info замінити на "-" або пробіл
        [[ -z "$info" || "$info" == "\\t" ]] && info=""
        
        # Уникнення експоненційної нотації та обрізка .000
		[[ "$active" =~ ^0(\.0+)?$ ]] && active="0" || active=$(printf "%.3f" "$active")
		[[ "$deactivating" =~ ^0(\.0+)?$ ]] && deactivating="0" || deactivating=$(printf "%.3f" "$deactivating")
		[[ "$activating" =~ ^0(\.0+)?$ ]] && activating="0" || activating=$(printf "%.3f" "$activating")

        printf "%-47s %-7d ${LIGHTPURPLE}%-15s${NOCOLOR} ${CYAN}%-15s${NOCOLOR} ${RED}%-15s${NOCOLOR} ${GREEN}%-15s${NOCOLOR}\n" \
          "$key" "$count" "$info" "$active" "$deactivating" "$activating"
    done <<< "$sorted_data"
}


# Defaults
DEFAULT_CLUSTER='-ul'
DEFAULT_SOLANA_ADRESS=$(solana address)
THIS_CONFIG_RPC=$(solana config get | awk -F': ' '/RPC URL:/ {print $2}')

THIS_SOLANA_ADRESS=${1:-$DEFAULT_SOLANA_ADRESS}
SOLANA_CLUSTER=${2:-$DEFAULT_CLUSTER}
shift 2
SORTING_CRITERIAS=("$@")


# Автовибір кластера, якщо -ul
if [[ "$SOLANA_CLUSTER" == "-ul" ]]; then
  case "$THIS_CONFIG_RPC" in
    *testnet*) SOLANA_CLUSTER="-ut" ;;
    *mainnet*) SOLANA_CLUSTER="-um" ;;
  esac
fi

# Ім’я кластера для виводу
case "$SOLANA_CLUSTER" in
  -ut) CLUSTER_NAME="(TESTNET)" ;;
  -um) CLUSTER_NAME="(Mainnet)" ;;
  -ul) CLUSTER_NAME="(Taken from Local)" ;;
  *)   CLUSTER_NAME="" ;;
esac

# Отримання voteAccount
YOUR_VOTE_ACCOUNT=""
for ((i=1; i<=5; i++)); do
  THIS_VALIDATOR_JSON=$(retry_command "solana ${SOLANA_CLUSTER} validators --output json-compact" 5 "" false | jq --arg ID "$THIS_SOLANA_ADRESS" '.validators[] | select(.identityPubkey==$ID)')
  YOUR_VOTE_ACCOUNT=$(echo "$THIS_VALIDATOR_JSON" | jq -r '.voteAccountPubkey' 2>/dev/null)
  [[ -n "$YOUR_VOTE_ACCOUNT" && "$YOUR_VOTE_ACCOUNT" != "null" ]] && break
  sleep 3
done

if [[ -z "$YOUR_VOTE_ACCOUNT" || "$YOUR_VOTE_ACCOUNT" == "null" ]]; then
  echo -e "${RED}❌ $THIS_SOLANA_ADRESS — can't find vote account!${NOCOLOR}"
  echo -e "${YELLOW}Possible reasons: --no-voting key active, RPC error, or validator wasn't vote ever or does not exist.${NOCOLOR}"
  exit 1
fi

# Отримуємо список всіх імен валідаторів одним запитом
VALIDATOR_NAMES_JSON=$(retry_command "solana ${SOLANA_CLUSTER} validator-info get --output json" 5 "null" false)
declare -A VALIDATOR_NAMES
while IFS=$'\t' read -r identity name; do
    if [[ -z "$name" ]]; then
        name="NO NAME"
    fi
    name=$(echo "$name" | sed 's/ /\\u00A0/g')
    VALIDATOR_NAMES["$identity"]="$name"
done < <(echo "$VALIDATOR_NAMES_JSON" | jq -r '.[] | "\(.identityPubkey)\t\(.info.name // "NO NAME")"')


NODE_NAME="${VALIDATOR_NAMES[$THIS_SOLANA_ADRESS]:-NO\\u00A0NAME}"


EPOCH_INFO=$(retry_command "solana ${SOLANA_CLUSTER} epoch-info 2> /dev/null" 5 "" false)
THIS_EPOCH=`echo -e "${EPOCH_INFO}" | grep 'Epoch: ' | sed 's/Epoch: //g' | awk '{print $1}'`

NODE_WITHDRAW_AUTHORITY=$(retry_command "solana ${SOLANA_CLUSTER} vote-account ${YOUR_VOTE_ACCOUNT} | grep 'Withdraw' | awk '{print \$NF}'" 5 "" false)

# Load data
STAKE_AUTHORITY=()
STAKE_AUTH_NAMES=()
STAKE_WTHDR=()
STAKE_NAMES=()

# Parse CSV once and store in variable
PARSED_CSV_JSON=$(parse_csv_to_json "$STAKEPOOL_CACHE")

# Process parsed data for stake authorities and withdrawers
while IFS=$'\t' read -r short_name type public_key; do
  [[ -z "$public_key" ]] && continue

  # 🔁 Підстановка плейсхолдерів (без змін у файлі)
  resolved_pubkey="${public_key//YOUR_NODE_WITHDRAW_AUTHORITY/$NODE_WITHDRAW_AUTHORITY}"
  resolved_pubkey="${resolved_pubkey//YOUR_NODE_IDENTITY/$THIS_SOLANA_ADRESS}"

  if [[ "$type" == "S" ]]; then
    STAKE_AUTHORITY+=("$resolved_pubkey")
    STAKE_AUTH_NAMES+=("$short_name")
  elif [[ "$type" == "W" ]]; then
    STAKE_WTHDR+=("$resolved_pubkey")
    STAKE_NAMES+=("$short_name")
  fi
done < <(echo "$PARSED_CSV_JSON" | jq -r '.[] | [.short_name, .type, .public_key] | @tsv')



ALL_MY_STAKES_JSON=$(retry_command "solana ${SOLANA_CLUSTER} stakes ${YOUR_VOTE_ACCOUNT} --output json-compact" 10 "" false)

mapfile -t ALL_STAKERS_KEYS_PAIRS < <(
  echo "$ALL_MY_STAKES_JSON" | jq -r '
    .[] | "\(.staker)+\(.withdrawer)"' | sort -u
)

echo -e "${DARKGRAY}All Stakers of $NODE_NAME | $YOUR_VOTE_ACCOUNT | Epoch ${THIS_EPOCH} ${CLUSTER_NAME}${NOCOLOR}"

DONE_STAKES=""
for i in "${ALL_STAKERS_KEYS_PAIRS[@]}"; do
    RES=$(check_key_pair "$DONE_STAKES" "$i")
    [[ -z "$RES" ]] && continue

    KEY_TYPE_NAME=$(echo "$RES" | cut -d'^' -f1)
    DONE_STAKES=$(echo "$RES" | cut -d'^' -f2)

    KEY=$(echo "$KEY_TYPE_NAME" | cut -d' ' -f1)
    TYPE=$(echo "$KEY_TYPE_NAME" | cut -d' ' -f2)
    NAME=$(echo "$KEY_TYPE_NAME" | cut -d' ' -f3)

    # Фільтруємо акаунти цього ключа
    stake_entries=$(echo "$ALL_MY_STAKES_JSON" | jq -c --arg key "$KEY" '
      .[] | select(.staker == $key or .withdrawer == $key)
    ')

    count=0
    active_total=0
    deactivating_total=0
    activating_total=0

    while IFS= read -r stake; do
        active=$(echo "$stake" | jq '.activeStake // 0')
        activating=$(echo "$stake" | jq '.activatingStake // 0')
        deactivating=$(echo "$stake" | jq '.deactivatingStake // 0')

        [[ "$active" != "0" ]] && ((count++))
        active_total=$((active_total + active))
        activating_total=$((activating_total + activating))
        deactivating_total=$((deactivating_total + deactivating))
    done <<< "$stake_entries"

    # Запис у data[], формат такий самий як раніше
    data["$KEY"]="$count:$NAME:$(
        awk -v n="$active_total" 'BEGIN{printf "%.3f", n/1e9}' | sed -r 's/^(.{12}).*$/\1/'
    ):$(
        awk -v n="$deactivating_total" 'BEGIN{printf "%.3f", n/1e9}' | sed -r 's/^(.{12}).*$/\1/'
    ):$(
        awk -v n="$activating_total" 'BEGIN{printf "%.3f", n/1e9}' | sed -r 's/^(.{12}).*$/\1/'
    )"
done



echo -e "—————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————"

echo -e "${UNDERLINE}Key Authority\t\t\t\t\tCount\t${LIGHTPURPLE}${UNDERLINE}Info\t\t${CYAN}${UNDERLINE}Active Stake\t${RED}${UNDERLINE}Deactivating\t${GREEN}${UNDERLINE}Activating${NOCOLOR}"

# Виклик функції для сортування за вибраним стовпчиком (наприклад, за Active Stake)

sort_data "${SORTING_CRITERIAS[@]}"

#sort_data 4:DESC 6:DESC
#sort_data 6:DESC 4:DESC 1:DESC 3:ASC



TOTAL_ACTIVE_STAKE=$(echo "$ALL_MY_STAKES_JSON" | jq '[.[].activeStake // 0] | add / 1e9' | awk '{printf "%.3f\n", $1}')
TOTAL_STAKE_COUNT=$(echo "$ALL_MY_STAKES_JSON" | jq '[.[] | select(.activeStake // 0 > 0)] | length')

ACTIVATING_STAKE=$(echo "$ALL_MY_STAKES_JSON" | jq '[.[].activatingStake // 0] | add / 1e9' | awk '{printf "%.3f\n", $1}')
ACTIVATING_STAKE_COUNT=$(echo "$ALL_MY_STAKES_JSON" | jq '[.[] | select(.activatingStake // 0 > 0)] | length')

DEACTIVATING_STAKE=$(echo "$ALL_MY_STAKES_JSON" | jq '[.[].deactivatingStake // 0] | add / 1e9' | awk '{printf "%.3f\n", $1}')
DEACTIVATING_STAKE_COUNT=$(echo "$ALL_MY_STAKES_JSON" | jq '[.[] | select(.deactivatingStake // 0 > 0)] | length')

TOTAL_ACTIVE_STAKE_COUNT=$((TOTAL_STAKE_COUNT - ACTIVATING_STAKE_COUNT))

echo -e "—————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————"

# Уникнення експоненційної нотації та обрізка .000
[[ "$TOTAL_ACTIVE_STAKE" =~ ^0(\.0+)?$ ]] && TOTAL_ACTIVE_STAKE="0" || TOTAL_ACTIVE_STAKE=$(printf "%.3f" "$TOTAL_ACTIVE_STAKE")
[[ "$ACTIVATING_STAKE" =~ ^0(\.0+)?$ ]] && ACTIVATING_STAKE="0" || ACTIVATING_STAKE=$(printf "%.3f" "$ACTIVATING_STAKE")
[[ "$DEACTIVATING_STAKE" =~ ^0(\.0+)?$ ]] && DEACTIVATING_STAKE="0" || DEACTIVATING_STAKE=$(printf "%.3f" "$DEACTIVATING_STAKE")

printf "%-47s %-7d %-15s ${CYAN}%-15s${NOCOLOR} ${RED}%-15s${NOCOLOR} ${GREEN}%-15s${NOCOLOR}\n" \
  "TOTAL:" "$TOTAL_ACTIVE_STAKE_COUNT" "" "$TOTAL_ACTIVE_STAKE" "$DEACTIVATING_STAKE" "$ACTIVATING_STAKE"


echo -e "${NOCOLOR}"