#!/bin/bash
#
# Copyright (c) 2026, the Equitable Society of Bit Plumbers, LLC.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
set -e

if [[ $1 == "" ]]; then
    echo "usage: ${0} <AWS_ACCOUNT_NAME> <AWS_REGION> [BASTION_ID]"
    exit 64
fi

if [[ $2 == "" ]]; then
    echo "usage: ${0} <AWS_ACCOUNT_NAME> <AWS_REGION> [BASTION_ID]"
    exit 64
fi

if [[ ! $2 =~ ^(us|eu|ap|sa|ca|me|af|il)-(north|south|east|west|central){1,2}-[[:digit:]]$ ]]; then
    echo "AWS_REGION parameter must be a region, got '$2'"
    exit 1
fi

export ACCOUNT_NAME=$1
export AWS_REGION=$2
export BASTION_NAME=${3:-bastion}

ACCOUNT_ID=$(
    aws organizations list-accounts \
    --query "(Accounts[?Name=='${ACCOUNT_NAME}'].Id)[0]" \
    --output text
)

echo "$ACCOUNT_NAME => $ACCOUNT_ID / $AWS_REGION"


CREDENTIALS=$(
    aws sts assume-role \
    --role-arn "arn:aws:iam::$ACCOUNT_ID:role/OrganizationAccountAccessRole" \
    --role-session-name connect-bastion \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text
)

read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< "$CREDENTIALS"

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN

BASTION_ID=$(
    aws ssm get-parameter \
    --name "/bastion/${BASTION_NAME}/instance-id" \
    --query "Parameter.Value" \
    --output text
) || echo "${BASTION_NAME} is not registered in SSM"

if [ -z "$BASTION_ID" ]; then
    echo "Error: Could not find bastion instance ID in SSM Parameter Store"
    exit 1
fi

aws ssm start-session \
    --target "$BASTION_ID" \
    --document-name AWS-StartInteractiveCommand \
    --parameters command="/usr/local/bin/ssm-bash"
