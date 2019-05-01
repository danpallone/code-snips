#!/bin/bash

# Requirements:
# ************
# aws cli must be installed.
# export MFAARN="<your mfa arn>"
#  ./assume_role.sh demo <us-east-1>


set -e

if [ -z "$2" ]; then
  if [ -z "$MFAARN" ]
  then
    printf "Please set your MFAARN or pass in your username.\n"
    exit 1
  fi
  MFAARN="$MFAARN"
else
  MFAARN="arn:aws:iam::516172020428:mfa/$2"
fi

if [ -z "$3" ]; then
  REGION="us-east-1"
else
  REGION="$3"
fi
DURATION=3600

if [ $1 == "demo" ]; then
  PROFILE=demo
  ROLEARN="arn:aws:iam::659111566604954:role/demo"
elif [ $1 == "eng" ]; then
  PROFILE="engineering"
  ROLEARN="arn:aws:iam::0722221093231757:role/EngAdmin"
else
  printf "Enter Valid Profile Name.\n"
  exit 1
fi

NAME="$PROFILE-session"
#echo "$MFAARN,$MFACODE,$SOURCE_PROFILE,$REGION"
# KST=access*K*ey, *S*ecretkey, session*T*oken
export AWS_PROFILE="$SOURCE_PROFILE"
KST=(`aws sts assume-role --role-arn "$ROLEARN" \
                          --region "$REGION" \
                          --profile "$SOURCE_PROFILE" \
                          --role-session-name "$NAME" \
                          --serial-number "$MFAARN" \
                          --token-code $MFACODE  \
                           --duration-seconds $DURATION \
                          --query "[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken]" \
                          --output text`)

aws_access_key_id="${KST[0]}"
aws_secret_access_key="${KST[1]}"
aws_session_token="${KST[2]}"


`aws configure set profile.$PROFILE.region $REGION`
`aws configure set profile.$PROFILE.aws_access_key_id $aws_access_key_id`
`aws configure set profile.$PROFILE.aws_secret_access_key $aws_secret_access_key`
`aws configure set profile.$PROFILE.aws_session_token $aws_session_token`


#echo "ACCESS KEY $aws_access_key_id"
#echo "SECRET KEY $aws_secret_access_key"
#echo "SESSION TOKEN $aws_session_token"
echo ""
echo "$PROFILE profile updated with temporary credentials"
