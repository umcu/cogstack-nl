#!/usr/bin/env bash

set -e

NIFI_TOOLKIT_VERSION="1.18.0"

if [[ -z "${NIFI_TOOLKIT_VERSION}" ]]; then
    NIFI_TOOLKIT_VERSION=$NIFI_TOOLKIT_VERSION
    echo "NIFI_TOOLKIT_VERSION not set, getting default version, NIFI_TOOLKIT_VERSION=$NIFI_TOOLKIT_VERSION"
else
    NIFI_TOOLKIT_VERSION=${NIFI_TOOLKIT_VERSION}
fi

if [ ! -d "./nifi_toolkit" ] 
then
    if [ ! -f ./nifi-toolkit-$NIFI_TOOLKIT_VERSION-bin.zip ]; then
        wget https://archive.apache.org/dist/nifi/$NIFI_TOOLKIT_VERSION/nifi-toolkit-$NIFI_TOOLKIT_VERSION-bin.zip
    fi
    unzip nifi-toolkit-$NIFI_TOOLKIT_VERSION-bin.zip
    mv nifi-toolkit-$NIFI_TOOLKIT_VERSION nifi_toolkit
    rm nifi-toolkit-$NIFI_TOOLKIT_VERSION-bin.zip
fi

# MORE INFO ON THE TOOLKIT : https://nifi.apache.org/docs/nifi-docs/components/nifi-docs/html/toolkit-guide.html#tls_toolkit
# The default value is 730 days.

if [[ -z "${NIFI_CERTIFICATE_TIME_VAILIDITY_IN_DAYS}" ]]; then
    NIFI_CERTIFICATE_TIME_VAILIDITY_IN_DAYS=730
    echo "NIFI_CERTIFICATE_TIME_VAILIDITY_IN_DAYS not set, defaulting to NIFI_CERTIFICATE_TIME_VAILIDITY_IN_DAYS=730"
else
    NIFI_CERTIFICATE_TIME_VAILIDITY_IN_DAYS=${NIFI_CERTIFICATE_TIME_VAILIDITY_IN_DAYS}
fi

# IMPORTANT: ENSURES THAT ONLY THE PASSWORD/KEYSTORE PROPERTIES ARE UPDATED, it takes the original nifi.props and overwrites the password/trustkeystore props with the new ones generated by the tool.
PATH_TO_NIFI_PROPERTIES_FILE="./../nifi/conf/nifi.properties"

# -k, --keySize <arg> Number of bits for generated keys (default: 2048)
KEY_SIZE=4096

# -n, --hostnames <arg> Comma separated list of hostnames i.e "server1,server2,localhost" etc.
HOSTNAMES="localhost"

OUTPUT_DIRECTORY="./nifi_certificates"

# -C,--clientCertDn <arg> Generate client certificate suitable for use in browser with specified DN (Can be specified multiple times)
# this should respect whatever is used to generate the other certificate with regards CN=nifi, this needs to match the HOSTNAME of the nifi container(s)
if [[ -z "${NIFI_SUBJ_LINE_CERTIFICATE_CN}" ]]; then
    NIFI_SUBJ_LINE_CERTIFICATE_CN="C=UK/ST=UK/L=UK/O=cogstack/OU=cogstack/CN=cogstack"
    echo "NIFI_SUBJ_LINE_CERTIFICATE_CN not set, defaulting to NIFI_SUBJ_LINE_CERTIFICATE_CN=C=UK/ST=UK/L=UK/O=cogstack/OU=cogstack/CN=cogstack"
else
    NIFI_SUBJ_LINE_CERTIFICATE_CN=${NIFI_SUBJ_LINE_CERTIFICATE_CN}
fi


# IMPRTANT: this is used in StandardSSLContextService controllers on the NiFi side, trusted keystore password field.
if [[ -z "${NIFI_KEY_PASSWORD}" ]]; then
    NIFI_KEY_PASSWORD="cogstackNifi"
    echo "NIFI_KEY_PASSWORD not set, defaulting to NIFI_KEY_PASSWORD=cogstackNifi"
fi

# Overwite existing files use the "-O" flag.
bash nifi_toolkit/bin/tls-toolkit.sh standalone -k $KEY_SIZE -n $HOSTNAMES -o $OUTPUT_DIRECTORY -O -f $PATH_TO_NIFI_PROPERTIES_FILE -d $NIFI_CERTIFICATE_TIME_VAILIDITY_IN_DAYS -C $NIFI_SUBJ_LINE_CERTIFICATE_CN -K $NIFI_KEY_PASSWORD

# move the new nifi properties files with the updated security configs to the nifi directory
mv ./$OUTPUT_DIRECTORY/$HOSTNAMES/nifi.properties ../nifi/conf/
