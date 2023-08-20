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
#  curl -i -X POST -H 'Content-Type:application/json'  http://localhost:8080/api/api/oauth/login -d '{"username":"user2","password":"teste"}'
#  curl -s --location 'http://localhost:8080/api/api/oauth/grant-code' --header 'Content-Type: application/json' --data '{"clientId": "c4ca4238-a0b9-2382-0dcc-509a6f75849b"}'

#sensedia steps
export CMD_FILE=/tmp/req.sh

function loadCredential()
{
  export AUTH_HOST=${STACK_ENVIRONMENT}-${STACK_TARGET}-srv-auth
  export AUTH_CONTEXT_PATH=
  export AUTH_URI=${AUTH_HOST}${AUTH_CONTEXT_PATH}
  export CLIENT_ID=${STACK_SERVICE_DEFAULT_USER}
  export CLIENT_SECRET=${STACK_SERVICE_DEFAULT_PASS}
  export GRANT_TYPE=urn:ietf:params:oauth:grant-type:jwt-bearer
  export ACCESS_TOKEN=
}

function authByGrantCode()
{
  export REQUEST_GRANT_DATA=""
  # shellcheck disable=SC2089
  echo "curl -s --location 'http://${AUTH_URI}/api/oauth/grant-code' \\">${CMD_FILE}
  echo "                        --header 'Content-Type: application/json'  \\">>${CMD_FILE}
  echo "                        --data '{\"clientId\": \"${CLIENT_ID}\"}'">>${CMD_FILE}
  chmod +x ${CMD_FILE};
  echo -e "${COLOR_MAGENTA}Request grant-code${COLOR_DEFAULT}"
  echo -e "  - ${COLOR_CIANO}CLIENT_ID        :${COLOR_GREEN} ${CLIENT_ID}"
  echo -e "  - ${COLOR_CIANO}CLIENT_SECRET    :${COLOR_GREEN} ${CLIENT_SECRET}"
  echo -e "  - ${COLOR_CIANO}GRANT_TYPE       :${COLOR_GREEN} urn:ietf:params:oauth:grant-type:jwt-bearer"
  echo -e "  - ${COLOR_CIANO}Request          :${COLOR_YELLOW}$(cat ${CMD_FILE})${COLOR_DEFAULT}"
  echo ""
  export GRANT_CODE=$(echo $(/tmp/req.sh) | jq '.code' | sed 's/\"//g');
  echo -e "  - ${COLOR_CIANO}grant-code: ${COLOR_GREEN}${GRANT_CODE}${COLOR_DEFAULT}"
  #make basic autorization
  export BASIC_AUTH=$(echo -n "${CLIENT_ID}:${CLIENT_SECRET}" | base64 -w 0);

  #request token
  echo "curl -s --location \"http://${AUTH_URI}/api/oauth/access-token\" \\" >${CMD_FILE}
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
  export JSON=$(/tmp/req.sh);
  export ACCESS_TOKEN=$(echo ${JSON} | jq '.token.accessToken' | sed 's/\"//g')
  export ACCESS_TOKEN_MD5=$(echo ${JSON} | jq '.token.accessTokenMd5' | sed 's/\"//g')
  export REFRESH_TOKEN=$(echo ${JSON} | jq '.token.refreshToken' | sed 's/\"//g')
  export REFRESH_TOKEN_MD5=$(echo ${JSON} | jq '.token.refreshTokenMd5' | sed 's/\"//g')
  echo -e "    - ${COLOR_CIANO}access-token : ${COLOR_RED}Bearer ${COLOR_GREEN}${ACCESS_TOKEN}${COLOR_DEFAULT}"
  echo ""
  echo -e "    - ${COLOR_CIANO}access-token : ${COLOR_RED}Bearer ${COLOR_GREEN}${REFRESH_TOKEN}${COLOR_DEFAULT}"
}

function authByLogin()
{
  export REQUEST_GRANT_DATA=""
  # shellcheck disable=SC2089
  echo "curl -s --location 'http://${AUTH_URI}/api/oauth/login' \\">${CMD_FILE}
  echo "                        --header 'Content-Type: application/json'  \\">>${CMD_FILE}
  echo "                        --data '{\"clientId\": \"${CLIENT_ID}\", \"secret\": \"${CLIENT_SECRET}\"}'">>${CMD_FILE}
  chmod +x /tmp/req.sh;
  echo ""
  echo -e "${COLOR_MAGENTA}Request access-token${COLOR_DEFAULT}"
  echo -e "  - ${COLOR_CIANO}Authorization  : ${COLOR_RED}Basic ${COLOR_GREEN}${BASIC_AUTH}${COLOR_DEFAULT}"
  echo -e "  - ${COLOR_CIANO}Request        :${COLOR_DEFAULT} ${COLOR_YELLOW}$(cat ${CMD_FILE})${COLOR_DEFAULT}"
  echo -e "  - ${COLOR_CIANO}Response       :${COLOR_DEFAULT}"
  export JSON=$(/tmp/req.sh);
  export ACCESS_TOKEN=$(echo ${JSON} | jq '.token.accessToken' | sed 's/\"//g')
  export ACCESS_TOKEN_MD5=$(echo ${JSON} | jq '.token.accessTokenMd5' | sed 's/\"//g')
  export REFRESH_TOKEN=$(echo ${JSON} | jq '.token.refreshToken' | sed 's/\"//g')
  export REFRESH_TOKEN_MD5=$(echo ${JSON} | jq '.token.refreshTokenMd5' | sed 's/\"//g')
  echo -e "    - ${COLOR_CIANO}access-token : ${COLOR_RED}Bearer ${COLOR_GREEN}${ACCESS_TOKEN}${COLOR_DEFAULT}"
  echo ""
  echo -e "    - ${COLOR_CIANO}access-token : ${COLOR_RED}Bearer ${COLOR_GREEN}${REFRESH_TOKEN}${COLOR_DEFAULT}"  
}

function sessionCheck()
{
  clear
  authByLogin
  clear
  _c_usr=${CLIENT_ID}
  echo "curl -s --location 'http://${AUTH_URI}/api/oauth/check' \\">${CMD_FILE}
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
  echo "curl -s --location 'http://${AUTH_URI}/users/find?userKey=${_c_usr}' \\">${CMD_FILE}
  echo "                        --header 'Content-Type: application/json'  \\">>${CMD_FILE}
  echo "                        --header 'Authorization: Bearer ${ACCESS_TOKEN}'">>${CMD_FILE}
  cat /tmp/req.sh
  chmod +x /tmp/req.sh;
  /tmp/req.sh | jq
}

function userCreateRecord()
{
  export _c_usr="${1}"
  export _c_pwd="${2}"
  export _c_doc="${3}"
  export _c_ema="${4}"
  export _c_phn="${5}"
  echo "curl -s --location 'http://${AUTH_URI}/users/register' \\">${CMD_FILE}
  echo "                        --header 'Content-Type: application/json'  \\">>${CMD_FILE}
  echo "                        --data '{\"username\": \"${_c_usr}\", \"password\": \"${_c_pwd}\", \"document\": \"${_c_doc}\", \"email\": \"${_c_ema}\", \"phoneNumber\": \"${_c_phn}\"}'">>${CMD_FILE}
  chmod +x /tmp/req.sh;
  export JSON=$(/tmp/req.sh)
  echo ${JSON} | jq
}

function userCreateTest()
{
  clear
  authByLogin
  clear
  export _c_usr="u${RANDOM}"
  export _c_pwd="p${RANDOM}"
  export _c_doc="${RANDOM}"
  export _c_ema="${_c_usr}@admin.com"
  export _c_phn="5511${RANDOM}${RANDOM}"
  userCreateRecord "${_c_usr}" "${_c_pwd}" "${_c_doc}" "${XXXX}" "${_c_ema}" "${_c_phn}"
}

function userCreateNew()
{
  clear
  authByLogin
  clear
  export _c_usr="u${RANDOM}"
  export _c_pwd="p${RANDOM}"
  export _c_doc="${RANDOM}"
  export _c_ema="${_c_usr}@admin.com"
  export _c_phn="5511${RANDOM}${RANDOM}"
  userCreateRecord "${_c_usr}" "${_c_pwd}" "${_c_doc}" "${XXXX}" "${_c_ema}" "${_c_phn}"
}

function userManagmentMenu()
{
  loadCredential

  while :
  do
    clear;
    options=(Exit Login GrantCode SessionCheck UserFind UserCreate UserDelete)
    echo -e "${COLOR_MAGENTA}Select auth mode${COLOR_DEFAULT}"
    PS3=$'\n'"Choose option: "
    select opt in "${options[@]}"
    do
      if [[ ${opt} == "Exit" ]]; then
        exit 0
      elif [[ ${opt} == "Login" ]]; then
        authByLogin
      elif [[ ${opt} == "GrantCode" ]]; then
        authByLogin
      elif [[ ${opt} == "SessionCheck" ]]; then
        sessionCheck
      elif [[ ${opt} == "userCreateNew" ]]; then
        userCreateNew
      elif [[ ${opt} == "userCreateList" ]]; then
        userCreateList
      elif [[ ${opt} == "UserFind" ]]; then
        userFind
      elif [[ ${opt} == "UserDelete" ]]; then
        userDelete
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

