#!/bin/bash
# Cryptovik "See All Your Stake" Script version 3.0
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

declare -A data

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
    	
	local STAKE_AUTH_NAMES=(MAR_NATIVE_1 MAR_NATIVE_2 )
	local STAKE_AUTHORITY=("stWirqFCf2Uts1JBL1Jsd3r6VBWhgnpdPxCTe1MFjrq" "ex9CfkBZZd6Nv9XdnoDmmB45ymbu4arXVk7g5pWnt3N")
	
	local STAKE_NAMES=(SELF_STAKE FOUNDATION SFDP_TESTNET SECRET_STAKE MARINADE MARINADE2 SOCEAN_POOL JPOOL_POOL EVERSOL_STAKE BLAZESTAKE LIDO_POOL DAO_POOL JITO_POOL LAINE_POOL UNKNOWN_POOL ?ALAMEDA2 ?ALAMEDA3 ?ALAMEDA4 ?ALAMEDA5 ?ALAMEDA6 ?ALAMEDA7 ?ALAMEDA8 ?ALAMEDA9 ?ALAMEDA10 ?ALAMEDA11 ?ALAMEDA12 ?ALAMEDA13 ?ALAMEDA14 ?ALAMEDA15 MARINADE_N EDGEVANA ZIPPY_STAKE VAULT_POOL SHINOBI_POOL FOUNDATION_2 ?FIREDANCER AERO_POOL JAG_POOL DYNO_POOL DEFIN_POOL MARGINFI BOND)
	local STAKE_WTHDR=($NODE_WITHDRAW_AUTHORITY "4ZJhPQAgUseCsWhKvJLTmmRRUV74fdoTpQLNfKoekbPY" "mvines9iiHiQTysrwkJjGf2gb9Ex9jXJX8ns3qwf2kN" "EhYXq3ANp5nAerUpbSgd7VK2RRcxK1zNuSQ755G5Mtxx" "9eG63CdHjsfhHmobHgLtESGC8GabbmRcaSpHAZrtmhco" "4bZ6o3eUUNXhKuqjdCnCoPAoLgWiuLYixKaxoa8PpiKk" "AzZRvyyMHBm8EHEksWxq4ozFL7JxLMydCDMGhqM6BVck" "HbJTxftxnXgpePCshA8FubsRj9MW4kfPscfuUfn44fnt" "C4NeuptywfXuyWB9A7H7g5jHVDE8L6Nj2hS53tA71KPn" "6WecYymEARvjG5ZyqkrVQ6YkhPfujNzWpSPwNKXHCbV2" "W1ZQRwUfSkDKy2oefRBUWph82Vr2zg9txWMA8RQazN5" "BbyX1GwUNsfbcoWwnkZDo8sqGmwNDzs2765RpjyQ1pQb" "6iQKfEyhr3bZMotVkW6beNZz5CPAkiwvgV2CTje9pVSS" "AAbVVaokj2VSZCmSU5Uzmxi6mxrG1n6StW9mnaWwN6cv" "HXdYQ5gixrY2H6Y9gqsD8kPM2JQKSaRiohDQtLbZkRWE" "e6keeZrGmHMiQaFM3TAYvFz8HE3qtTFUSHsyqq5FEw7" "DYG1ooTxkLS5iHDkte2XK4QBrpHziDR6EEZg5VsqNpVo" "EcH12jxhrbhF6qHqRzWpZ8rZU3TjG3sX6F67zP61oDJG" "HKd8LdhjUyhp2z4kYgpJxc4pzKCCKR4yC14EFSLNENtw" "8g3YB8KxpWEAAvcjom5vSqxJAZczZBgB4pEgsssts86K" "2YcwVbKx9L25Jpaj2vfWSXD5UKugZumWjzEe6suBUJi2" "DU5XJS2Cm8ftMmi5eZZJg8nkgx1hnZ3nT5sPU3GzV1fo" "7VMTVroogF6GhVunnUWF9hX8JiXqPHiZoG3VKAe64Ckt" "GunPZHAJc5DH8qARPz8x6UXAsoR3NDadFYs3bxtMZsvg" "7hbKGnBZEFF3Bwd9HFetDkLDHXycjvCATFUnj1nEzV85" "7dPqBYywCgLmjuHmexrEJLTCuoFpEUEf31Mjkjhz15wv" "5LJ93G4SQh9GiewTQJNAu6X9sQ1VVyrpCAgbQsRSgn22" "21uFTR9S5LptdR2tBxVeG1KAsKXB7tESqQVT8KRU7Vnj" "F5U6ac2vLzv3pYsxPVPYhhvxZY7u2WJMQEk81E3keMhX" "CyAH9f9awBcfuZqHzwwEs4uJBLEG33S743jxnQX1KcZ6" "FZEaZMmrRC3PDPFMzqooKLS2JjoyVkKNd2MkHjr7Xvyq" "F15nfVkJFAa3H4BaHEb6hQBnmiJZwPYioDiE1yxbc5y4" "GdNXJobf8fbTR5JSE7adxa6niaygjx4EEbnnRaDCHMMW" "EpH4ZKSeViL5qAHA9QANYVHxdmuzbUH2T79f32DmSCaM" "BVPWEKqzHD4H2pAX34wbtn33eNpzx6KxHxuaJW7uKZei" "8fxe1qGoDVLtqe9PAFyV4kR6zryTDyGQYb9AZQVUCvpM" "AKJt3m2xJ6ANda9adBGqb5BMrheKJSwxyCfYkLuZNmjn" "Hodkwm8xf43JzRuKNYPGnYJ7V9cXZ7LJGNy96TWQiSGN" "BqPJdYKKpReEfXHv8kgdmRcBfLToBSHpt1qThtb52GSs" "5ugu8RogBq5ZdfGt4hKxKotRBkndiV1ndsqWCf7PBmST" "3b7XQeZ8nSMyjcQGTFJS5kBw4pXS2SqtB9ooHCnF2xV9" "7cgg6KhPd1G8oaoB48RyPDWu7uZs51jUpDYB3eq4VebH")
	
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

EPOCH_INFO=$(retry_command "solana ${SOLANA_CLUSTER} epoch-info 2> /dev/null" 5 "" false)
THIS_EPOCH=`echo -e "${EPOCH_INFO}" | grep 'Epoch: ' | sed 's/Epoch: //g' | awk '{print $1}'`


NODE_WITHDRAW_AUTHORITY=$(retry_command "solana ${SOLANA_CLUSTER} vote-account ${YOUR_VOTE_ACCOUNT} | grep 'Withdraw' | awk '{print \$NF}'" 5 "" false)


ALL_MY_STAKES=$(retry_command "solana ${SOLANA_CLUSTER} stakes ${YOUR_VOTE_ACCOUNT}" 10 "" false)

# ALL_STAKERS_KEYS_PAIRS=`echo "$ALL_MY_STAKES" | grep -E -B1 "Withdraw" | grep -oP "(?<=Stake Authority: ).*|(?<=Withdraw Authority: ).*" | paste -d '+' - - | sort | uniq`
mapfile -t ALL_STAKERS_KEYS_PAIRS < <(
  echo "$ALL_MY_STAKES" | grep -E -B1 "Withdraw" |
  grep -oP "(?<=Stake Authority: ).*|(?<=Withdraw Authority: ).*" |
  paste -d '+' - - | sort -u
)

echo -e "${DARKGRAY}All Stakers of $YOUR_VOTE_ACCOUNT | Epoch ${THIS_EPOCH} ${CLUSTER_NAME}${NOCOLOR}"

DONE_STAKES=""
for i in "${ALL_STAKERS_KEYS_PAIRS[@]}"; do
    RES=$(check_key_pair "$DONE_STAKES" "$i")
	if [[ "$RES" == "" ]]; then
        continue
    fi
	
	KEY_TYPE_NAME=$(echo $RES | cut -d'^' -f1)
	DONE_STAKES=$(echo $RES | cut -d'^' -f2)
	
	KEY=$(echo $KEY_TYPE_NAME | cut -d' ' -f1)
	TYPE=$(echo $KEY_TYPE_NAME | cut -d' ' -f2)
	NAME=$(echo $KEY_TYPE_NAME | cut -d' ' -f3)
	
	# Визначення значення count
    count=$(echo "$ALL_MY_STAKES" | grep -B7 -E $KEY | grep 'Active Stake' | sed 's/Active Stake: //g' | sed 's/ SOL//g' | wc -l)

	# Заповнення асоціативного масиву з даними
    data["$KEY"]=$count:$NAME:$(
        echo "$ALL_MY_STAKES" | grep -B7 -E $KEY | grep 'Active Stake' | sed 's/Active Stake: //g' | sed 's/ SOL//g' | bc | awk '{n+=0+$1+0}; END{print 0+n+0}' | sed -r 's/^(.{7}).+$/\1/'
    ):$(
        echo "$ALL_MY_STAKES" | grep -B7 -E $KEY | grep -B1 -i 'deactivates' | grep 'Active Stake' | sed 's/Active Stake: //g' | sed 's/ SOL//g' | bc | awk '{n+=0+$1+0}; END{print 0+n+0}' | sed -r 's/^(.{7}).+$/\1/'
    ):$(
        echo "$ALL_MY_STAKES" | grep -B7 -E $KEY | grep 'Activating Stake' | sed 's/Activating Stake: //g' | sed 's/ SOL//g' | bc | awk '{n+=0+$1+0}; END{print 0+n+0}' | sed -r 's/^(.{7}).+$/\1/'
    )
done



echo -e "—————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————"

echo -e "${UNDERLINE}Key Authority\t\t\t\t\tCount\t${LIGHTPURPLE}${UNDERLINE}Info\t\t${CYAN}${UNDERLINE}Active Stake\t${RED}${UNDERLINE}Deactivating\t${GREEN}${UNDERLINE}Activating${NOCOLOR}"

# Виклик функції для сортування за вибраним стовпчиком (наприклад, за Active Stake)

sort_data "${SORTING_CRITERIAS[@]}"

#sort_data 4:DESC 6:DESC
#sort_data 6:DESC 4:DESC 1:DESC 3:ASC



TOTAL_ACTIVE_STAKE=$(echo "$ALL_MY_STAKES" | awk '/Active Stake:/ {gsub("Active Stake: ", "", $0); gsub(" SOL", "", $0); sum += $1} END {printf "%.2f\n", sum}')
TOTAL_STAKE_COUNT=`echo -e "${ALL_MY_STAKES}" | grep 'Active Stake' | sed 's/Active Stake: //g' | sed 's/ SOL//g' | bc | wc -l`

ACTIVATING_STAKE=$(echo "$ALL_MY_STAKES" | awk '/Activating Stake:/ {gsub("Activating Stake: ", "", $0); gsub(" SOL", "", $0); sum += $1} END {printf "%.2f\n", sum}')
ACTIVATING_STAKE_COUNT=`echo -e "${ALL_MY_STAKES}" | grep 'Activating Stake: ' | sed 's/Activating Stake: //g' | sed 's/ SOL//g' | bc | wc -l`

DEACTIVATING_STAKE=$(echo "$ALL_MY_STAKES" | awk '
{
  if (tolower($0) ~ /deactivates/) {
    if (prev ~ /Active Stake:/) {
      gsub("Active Stake: ", "", prev)
      gsub(" SOL", "", prev)
      sum += prev
    }
  }
  prev = $0
}
END {
  printf "%.2f\n", sum
}')
DEACTIVATING_STAKE_COUNT=`echo -e "${ALL_MY_STAKES}" | grep -B1 -i 'deactivates' | grep 'Active Stake' | sed 's/Active Stake: //g' | sed 's/ SOL//g' | bc | wc -l`

TOTAL_ACTIVE_STAKE_COUNT=`echo "${TOTAL_STAKE_COUNT:-0} ${ACTIVATING_STAKE_COUNT:-0}" | awk '{print $1 - $2}' | bc`

echo -e "—————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————"

printf "%-47s %-7d %-15s ${CYAN}%-15s${NOCOLOR} ${RED}%-15s${NOCOLOR} ${GREEN}%-15s${NOCOLOR}\n" \
  "TOTAL:" "$TOTAL_ACTIVE_STAKE_COUNT" "" "$TOTAL_ACTIVE_STAKE" "$DEACTIVATING_STAKE" "$ACTIVATING_STAKE"


echo -e "${NOCOLOR}"
