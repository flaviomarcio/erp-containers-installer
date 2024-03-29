#!/bin/bash

clear

export COLOR_DEFAULT="\e[0m"
export COLOR_RED="\e[31m"
export COLOR_GREEN="\e[32m"
export COLOR_YELLOW="\e[33m"
export COLOR_BLUE="\e[34m"
export COLOR_MAGENTA="\e[35m"
export COLOR_CIANO="\e[36m"

#auth server
#  curl -i -X POST -H 'Content-Type:application/json' http://localhost:8080/api/users/register -d '{"username":"admin","password":"admin"}'
#  curl -i -X GET http://localhost:8080/api/users/user?id=ee11cbb1-9052-340b-87aa-c0ca060c23ee
#  curl -i -X POST -H 'Content-Type:application/json'  http://localhost:8080/api/oauth/login -d '{"username":"user2","password":"teste"}'
#  curl -s --location 'http://localhost:8080/api/oauth/grant-code' --header 'Content-Type: application/json' --data '{"clientId": "c4ca4238-a0b9-2382-0dcc-509a6f75849b"}'

#sensedia steps
CMD_FILE=/tmp/req.sh

function loadCredential()
{
  export AUTH_HOST=${STACK_ENVIRONMENT}-${STACK_TARGET}-srv-auth
  export AUTH_CONTEXT_PATH=
  export AUTH_URI="http://${AUTH_HOST}${AUTH_CONTEXT_PATH}/api"
  if [[ ${CLIENT_ID} == "" ]]; then
    export CLIENT_ID=${STACK_SERVICE_DEFAULT_USER}
    export CLIENT_SECRET=${STACK_SERVICE_DEFAULT_PASS}
  fi
  export GRANT_TYPE=urn:ietf:params:oauth:grant-type:jwt-bearer
}

function authByGrantCode()
{
  unset REQUEST_GRANT_DATA
  # shellcheck disable=SC2089
  echo "curl -s --location '${AUTH_URI}/oauth/grant-code' \\">${CMD_FILE}
  echo "                        --header 'Content-Type: application/json'  \\">>${CMD_FILE}
  echo "                        --data '{\"clientId\": \"${CLIENT_ID}\"}'">>${CMD_FILE}
  chmod +x ${CMD_FILE};
  echo -e "${COLOR_MAGENTA}Request grant-code${COLOR_DEFAULT}"
  echo -e "  - ${COLOR_CIANO}CLIENT_ID        :${COLOR_GREEN} ${CLIENT_ID}"
  echo -e "  - ${COLOR_CIANO}CLIENT_SECRET    :${COLOR_GREEN} ${CLIENT_SECRET}"
  echo -e "  - ${COLOR_CIANO}GRANT_TYPE       :${COLOR_GREEN} urn:ietf:params:oauth:grant-type:jwt-bearer"
  echo -e "  - ${COLOR_CIANO}Request          :${COLOR_YELLOW}$(cat ${CMD_FILE})${COLOR_DEFAULT}"
  echo ""
  local GRANT_CODE=$(echo $(/tmp/req.sh) | jq '.code' | sed 's/\"//g');
  echo -e "  - ${COLOR_CIANO}grant-code: ${COLOR_GREEN}${GRANT_CODE}${COLOR_DEFAULT}"
  #make basic autorization
  local BASIC_AUTH=$(echo -n "${CLIENT_ID}:${CLIENT_SECRET}" | base64 -w 0);

  #request token
  echo "curl -s --location \"${AUTH_URI}/oauth/access-token\" \\" >${CMD_FILE}
  echo "                      --header \"Content-Type: application/x-www-form-urlencoded\" \\" >>${CMD_FILE}
  echo "                      --header \"Authorization: Basic ${BASIC_AUTH}\" \\" >>${CMD_FILE}
  echo "                      --data-urlencode \"code=${GRANT_CODE}\" \\" >>${CMD_FILE}
  echo "                      --data-urlencode \"grant_type=${GRANT_TYPE}\"" >>${CMD_FILE}
  chmod +x /tmp/req.sh;
  echo ""
  echo -e "${COLOR_MAGENTA}Request access-token${COLOR_DEFAULT}"
  echo -e "  - ${COLOR_CIANO}Authorization  : ${COLOR_RED}Basic ${COLOR_GREEN}${BASIC_AUTH}${COLOR_DEFAULT}"
  echo -e "  - ${COLOR_CIANO}Request        :${COLOR_DEFAULT} ${COLOR_YELLOW}$(cat ${CMD_FILE})${COLOR_DEFAULT}"
  echo -e "  - ${COLOR_CIANO}Response       :${COLOR_DEFAULT}"
  local JSON=$(/tmp/req.sh);
  local ACCESS_TOKEN=$(echo ${JSON} | jq '.token.accessToken' | sed 's/\"//g')
  local ACCESS_TOKEN_MD5=$(echo ${JSON} | jq '.token.accessTokenMd5' | sed 's/\"//g')
  local REFRESH_TOKEN=$(echo ${JSON} | jq '.token.refreshToken' | sed 's/\"//g')
  local REFRESH_TOKEN_MD5=$(echo ${JSON} | jq '.token.refreshTokenMd5' | sed 's/\"//g')
  echo -e "    - ${COLOR_CIANO}access-token : ${COLOR_RED}Bearer ${COLOR_GREEN}${ACCESS_TOKEN}${COLOR_DEFAULT}"
  echo ""
  echo -e "    - ${COLOR_CIANO}access-token : ${COLOR_RED}Bearer ${COLOR_GREEN}${REFRESH_TOKEN}${COLOR_DEFAULT}"
}

function authByLogin()
{
  __authByLogin_shw=${1}
  if [[ ${__authByLogin_shw} == "" ]]; then
    __authByLogin_shw=true
  fi
  loadCredential
  unset ACCESS_TOKEN
  unset ACCESS_TOKEN_MD5
  unset REFRESH_TOKEN
  unset REFRESH_TOKEN_MD5
  unset REQUEST_GRANT_DATA
  # shellcheck disable=SC2089
  echo "curl -s --location '${AUTH_URI}/oauth/login' \\">${CMD_FILE}
  echo "                        --header 'Content-Type: application/json'  \\">>${CMD_FILE}
  echo "                        --data '{\"clientId\": \"${CLIENT_ID}\", \"secret\": \"${CLIENT_SECRET}\"}'">>${CMD_FILE}
  chmod +x /tmp/req.sh;
  if [[ ${__authByLogin_shw} == true ]]; then
    echo ""
    echo -e "${COLOR_MAGENTA}Request access-token${COLOR_DEFAULT}"
    echo -e "  - ${COLOR_CIANO}Authorization  : ${COLOR_RED}Basic ${COLOR_GREEN}${BASIC_AUTH}${COLOR_DEFAULT}"
    echo -e "  - ${COLOR_CIANO}Request        :${COLOR_DEFAULT} ${COLOR_YELLOW}$(cat ${CMD_FILE})${COLOR_DEFAULT}"
    echo -e "  - ${COLOR_CIANO}Response       :${COLOR_DEFAULT}"
  fi
  export JSON=$(/tmp/req.sh);
  export ACCESS_TOKEN=$(echo ${JSON} | jq '.token.accessToken' | sed 's/\"//g')
  export ACCESS_TOKEN_MD5=$(echo ${JSON} | jq '.token.accessTokenMd5' | sed 's/\"//g')
  export REFRESH_TOKEN=$(echo ${JSON} | jq '.token.refreshToken' | sed 's/\"//g')
  export REFRESH_TOKEN_MD5=$(echo ${JSON} | jq '.token.refreshTokenMd5' | sed 's/\"//g')
  if [[ ${__authByLogin_shw} == true ]]; then
    echo -e "    - ${COLOR_CIANO}access-token : ${COLOR_RED}Bearer ${COLOR_GREEN}${ACCESS_TOKEN}${COLOR_DEFAULT}"
    echo ""
    echo -e "    - ${COLOR_CIANO}access-token : ${COLOR_RED}Bearer ${COLOR_GREEN}${REFRESH_TOKEN}${COLOR_DEFAULT}"  
  fi
}

function authByLoginCheck()
{
  clear
  unset CLIENT_ID
  unset CLIENT_SECRET
  echo -e "${COLOR_MAGENTA}New user${COLOR_DEFAULT}"
  echo -e "   ${COLOR_GREEN}Set a username: ${COLOR_DEFAULT}"
  read CLIENT_ID
  echo -e "   ${COLOR_GREEN}Set a password: ${COLOR_DEFAULT}"
  read CLIENT_SECRET

  authByLogin
}

function sessionCheck()
{
  clear
  authByLogin
  clear
  _c_usr=${CLIENT_ID}
  echo "curl -s --location '${AUTH_URI}/oauth/check' \\">${CMD_FILE}
  echo "                        --header 'Content-Type: application/json'  \\">>${CMD_FILE}
  echo "                        --header 'Authorization: Bearer ${ACCESS_TOKEN}'">>${CMD_FILE}
  cat /tmp/req.sh
  chmod +x /tmp/req.sh;
  /tmp/req.sh | jq
}

function userFind()
{
  clear
  authByLogin
  clear
  _c_usr=${CLIENT_ID}
  echo "curl -s --location '${AUTH_URI}/users/find?userKey=${_c_usr}' \\">${CMD_FILE}
  echo "                        --header 'Content-Type: application/json'  \\">>${CMD_FILE}
  echo "                        --header 'Authorization: Bearer ${ACCESS_TOKEN}'">>${CMD_FILE}
  cat /tmp/req.sh
  chmod +x /tmp/req.sh;
  /tmp/req.sh | jq
}

function userCreateRecord()
{
  local _c_shw="${1}"
  local _c_usr="${2}"
  local _c_pwd="${3}"
  local _c_nam="${4}"
  local _c_doc="${5}"
  local _c_ema="${6}"
  local _c_phn="${7}"

  if [[ ${_c_usr} == "" ]]; then
    echo -e "   ${COLOR_RED}    Invalid username ${COLOR_DEFAULT}"
    return 0
  fi

  if [[ ${_c_pwd} == "" ]]; then
    local _c_pwd="${_c_usr}@1234"
  fi

  if [[ ${_c_ema} == "" ]]; then
    #fake mail
    local _c_ema="${_c_usr}@${STACK_DOMAIN}" 
  fi

  if [[ ${_c_doc} == "" ]]; then
    #fake document
    local _c_doc="$RANDOM$RANDOM$RANDOM"
    local _c_doc=$(expr substr "$_c_doc" 1 11) 
  fi

  if [[ ${_c_phn} == "" ]]; then
    #fake phone
    local _c_phn="55$RANDOM$RANDOM$RANDOM"
    local _c_phn=$(expr substr "$_c_phn" 1 14)
  fi

  if [[ ${ACCESS_TOKEN} == "" ]]; then
    authByLogin ${_c_shw}
  fi

  if [[ ${ACCESS_TOKEN} == "" ]]; then
    return 0
  fi

  echo "curl -s --location '${AUTH_URI}/users/register' \\">${CMD_FILE}
  echo "                        --header 'Content-Type: application/json'  \\">>${CMD_FILE}
  echo "                        --header 'Authorization: Bearer ${ACCESS_TOKEN}'  \\">>${CMD_FILE}
  echo "                        --data '{\"username\": \"${_c_usr}\", \"password\": \"${_c_pwd}\", \"name\": \"${_c_nam}\", \"document\": \"${_c_doc}\", \"email\": \"${_c_ema}\", \"phoneNumber\": \"${_c_phn}\"}'">>${CMD_FILE}
  chmod +x /tmp/req.sh;
  if [[ ${_c_shw} == true ]]; then
    cat /tmp/req.sh
  fi
  export JSON=$(/tmp/req.sh)
  if [[ ${_c_shw} == true ]]; then
    echo ${JSON} | jq
  fi
}

function userCreateTest()
{
  clear
  local _c_usr="u${RANDOM}"
  local _c_pwd="p${RANDOM}"
  local _c_nam="u${RANDOM}"
  local _c_doc="${RANDOM}"
  local _c_ema="${_c_usr}@admin.com"
  local _c_phn="5511${RANDOM}${RANDOM}"

  userCreateRecord true, "${_c_usr}" "${_c_pwd}" "${_c_nam}" "${_c_doc}" "${_c_ema}" "${_c_phn}"
}

function userCreateNew()
{
  clear
  echo -e "${COLOR_MAGENTA}New user${COLOR_DEFAULT}"
  echo -e "   ${COLOR_GREEN}Set a name: ${COLOR_DEFAULT}"
  read _c_usr
  echo -e "   ${COLOR_GREEN}Set a password: ${COLOR_DEFAULT}"
  read _c_pwd
  echo -e "   ${COLOR_GREEN}Set a e-mail: ${COLOR_DEFAULT}"
  read _c_ema
  echo -e "   ${COLOR_GREEN}Set a document: ${COLOR_DEFAULT}"
  read _c_doc
  echo -e "   ${COLOR_GREEN}Set a phone number: ${COLOR_DEFAULT}"
  read _c_phn
  echo -e "${COLOR_MAGENTA}User detail ${COLOR_DEFAULT}"

  userCreateRecord true, "${_c_usr}" "${_c_pwd}" "${_c_nam}" "${_c_doc}" "${_c_ema}" "${_c_phn}"
  echo -e "   ${COLOR_BLUE_B} username......: ${_c_usr} ${COLOR_DEFAULT}"
  echo -e "   ${COLOR_BLUE_B} password......: ${_c_pwd} ${COLOR_DEFAULT}"
  echo -e "   ${COLOR_BLUE_B} name..........: ${_c_nam} ${COLOR_DEFAULT}"
  echo -e "   ${COLOR_BLUE_B} document......: ${_c_doc} ${COLOR_DEFAULT}"
  echo -e "   ${COLOR_BLUE_B} e-mail........: ${_c_ema} ${COLOR_DEFAULT}"
  echo -e "   ${COLOR_BLUE_B} phone.number..: ${_c_phn} ${COLOR_DEFAULT}"
}

function userCreateDelete()
{
  authByLogin
  return 1
}

function userManagmentMenu()
{
  while :
  do
    clear;
    loadCredential
    local options=(Exit Login GrantCode SessionCheck UserFind UserCreateNew UserFind UserDelete UserCreateTest)
    echo -e "${COLOR_MAGENTA}Select auth mode${COLOR_DEFAULT}"
    PS3=$'\n'"Choose option: "
    select opt in "${options[@]}"
    do
      if [[ ${opt} == "Exit" ]]; then
        exit 0
      elif [[ ${opt} == "Login" ]]; then
        authByLoginCheck
      elif [[ ${opt} == "GrantCode" ]]; then
        authByLoginCheck
      elif [[ ${opt} == "SessionCheck" ]]; then
        sessionCheck
      elif [[ ${opt} == "UserCreateNew" ]]; then
        userCreateNew
      elif [[ ${opt} == "UserCreateDelete" ]]; then
        userCreateDelete
      elif [[ ${opt} == "UserFind" ]]; then
        userFind
      elif [[ ${opt} == "UserDelete" ]]; then
        userDelete
      elif [[ ${opt} == "UserCreateTest" ]]; then
        userCreateTest
      fi
      echo ""
      echo ""
      echo -e "${COLOR_GREEN}[ENTER] to continue${COLOR_DEFAULT}"
      echo ""
      read
      break
    done
  done
}


