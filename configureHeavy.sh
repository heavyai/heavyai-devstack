#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0


# Reading .env file or setting defaults
if [ -f ./.env ]; then
    echo "Reading .env file"
    source ./.env
else
    echo ".env file does not exist. Using defaults"
fi
# Default value for INSTALL_TYPE
INSTALL_TYPE="simple"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -soa)
            INSTALL_TYPE="soa"
            shift # Remove -soa from processing
            ;;
        -jupyter)
            INSTALL_TYPE="jupyter"
            shift # Remove -jupyter from processing
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Output the chosen INSTALL_TYPE
echo "INSTALL_TYPE is set to $INSTALL_TYPE"

HEAVYDB_CONF_FILENAME="heavydb.conf"
HEAVYIQ_CONF_FILENAME="iq.conf"
IMMERSE_CONF_FILENAME="immerse.conf"
TEMPLATE_FOLDER="./templates"
IMMERSE_SERVERS_JSON_TEMPLATE="$TEMPLATE_FOLDER/servers.json"
HEAVYDB_SERVICE_NAME="heavydb"
IMMERSE_SERVICE_NAME="immerse"
IQ_SERVICE_NAME="iq"
CONFIG_STAGING_LOCATION="./staging"
: ${CONTAINER:="heavyai/heavyai-ee-cuda:latest "}

: ${IMMERSE_PORT:="6273"}
: ${HEAVYDB_PORT:="6274"}
: ${HEAVYIQ_PORT:="6275"}
: ${HEAVYDB_BACKEND_PORT:="6278"}
: ${HEAVYDB_CALCITE_PORT:="6279"}

HEAVY_CONF_TEMPLATE="$TEMPLATE_FOLDER/$HEAVYDB_CONF_FILENAME.template"
HEAVYIQ_CONF_TEMPLATE="$TEMPLATE_FOLDER/$HEAVYIQ_CONF_FILENAME.template"
IMMERSE_CONF_TEMPLATE="$TEMPLATE_FOLDER/$IMMERSE_CONF_FILENAME.template"

: ${HEAVY_CONFIG_BASE:="/var/lib/heavyai"} #typically /var/lib/heavyai
: ${HEAVYDB_CONFIG_FILE="${HEAVY_CONFIG_BASE}/heavy.conf"}  # assuming actual path for the config
: ${HEAVY_IQ_LOCATION:="${HEAVY_CONFIG_BASE}/iq"}
: ${HEAVY_IQ_CONFIG_FILE:="${HEAVY_IQ_LOCATION}/iq.conf"}
: ${HEAVY_IMMERSE_LOCATION:="${HEAVY_CONFIG_BASE}/immerse"}
: ${HEAVY_IMMERSE_CONFIG_FILE:="${HEAVY_IMMERSE_LOCATION}/immerse.conf"}
: ${HEAVY_STORAGE_DIR:="${HEAVY_CONFIG_BASE}/storage"}
: ${HEAVYDB_IMPORT_PATH:="${HEAVY_CONFIG_BASE}/import"}
: ${HEAVYDB_EXPORT_PATH:="${HEAVY_CONFIG_BASE}/export"}
: ${IMMERSE_SERVERS_JSON:="${HEAVY_IMMERSE_LOCATION}/servers.json"}
: ${HEAVYDB_BACKEND_URL:="http://$HEAVYDB_SERVICE_NAME:$HEAVYDB_BACKEND_PORT"}
if [ "$INSTALL_TYPE" == "soa" ]; then 
    : ${IQ_URL:="http://$IQ_SERVICE_NAME:$HEAVYIQ_PORT"}
    DOCKER_FILE_TEMPLATE="$TEMPLATE_FOLDER/docker-compose-soa.yml"

elif [ "$INSTALL_TYPE" == "jupyter" ]; then 
    : ${IQ_URL:="http://$HEAVYDB_SERVICE_NAME:$HEAVYIQ_PORT"}
    DOCKER_FILE_TEMPLATE="$TEMPLATE_FOLDER/docker-compose-jupyter.yml"
else 
    : ${IQ_URL:="http://$HEAVYDB_SERVICE_NAME:$HEAVYIQ_PORT"}
    DOCKER_FILE_TEMPLATE="$TEMPLATE_FOLDER/docker-compose-simple.yml"

fi

configureApp() {
    template_file=$1
    config_file=$2

    # Ensure the template exists
    if [ ! -f "$template_file" ]; then
        echo "Template file $template_file does not exist."
        return 1
    fi

    cp "$template_file" "$config_file"
    
    # Using alternative delimiters for sed to handle paths with slashes
    sed -i "s|{{IMMERSE_PORT}}|$IMMERSE_PORT|g" $config_file
    sed -i "s|{{HEAVY_CONFIG_BASE}}|$HEAVY_CONFIG_BASE|g" $config_file
    sed -i "s|{{HEAVYDB_CALCITE_PORT}}|$HEAVYDB_CALCITE_PORT|g" $config_file
    sed -i "s|{{HEAVYIQ_PORT}}|$HEAVYIQ_PORT|g" $config_file
    sed -i "s|{{HEAVYDB_PORT}}|$HEAVYDB_PORT|g" $config_file
    sed -i "s|{{HEAVYDB_BACKEND_PORT}}|$HEAVYDB_BACKEND_PORT|g" $config_file
    sed -i "s|{{HEAVY_STORAGE_DIR}}|$HEAVY_STORAGE_DIR|g" "$config_file"
    sed -i "s|{{HEAVYDB_IMPORT_PATH}}|$HEAVYDB_IMPORT_PATH|g" $config_file
    sed -i "s|{{HEAVYDB_EXPORT_PATH}}|$HEAVYDB_EXPORT_PATH|g" $config_file   
    sed -i "s|{{HEAVY_IQ_CONFIG}}|$HEAVY_IQ_CONFIG|g" $config_file
    sed -i "s|{{HEAVY_IMMERSE_CONFIG}}|$HEAVY_IMMERSE_CONFIG|g" $config_file
    sed -i "s|{{HEAVYDB_CONFIG_LOCATION}}|$HEAVYDB_CONFIG_LOCATION|g" $config_file
    sed -i "s|{{IMMERSE_SERVERS_JSON}}|$IMMERSE_SERVERS_JSON|g" $config_file
    sed -i "s|{{HEAVYDB_BACKEND_URL}}|$HEAVYDB_BACKEND_URL|g" $config_file
    sed -i "s|{{IQ_URL}}|$IQ_URL|g" $config_file
    sed -i "s|{{HEAVYDB_SERVICE_NAME}}|$HEAVYDB_SERVICE_NAME|g" $config_file
    sed -i "s|{{IMMERSE_SERVICE_NAME}}|$IMMERSE_SERVICE_NAME|g" $config_file
    sed -i "s|{{IQ_SERVICE_NAME}}|$IQ_SERVICE_NAME|g" $config_file
    sed -i "s|{{CONTAINER}}|$CONTAINER|g" $config_file
    sed -i "s|{{HEAVYDB_CONFIG_FILE}}|$HEAVYDB_CONFIG_FILE|g" $config_file
    sed -i "s|{{HEAVY_IQ_CONFIG_FILE}}|$HEAVY_IQ_CONFIG_FILE|g" $config_file
    sed -i "s|{{HEAVY_IMMERSE_CONFIG_FILE}}|$HEAVY_IMMERSE_CONFIG_FILE|g" $config_file
    sed -i "s|{{HEAVY_IQ_LOCATION}}|$HEAVY_IQ_LOCATION|g" $config_file
    sed -i "s|{{HEAVY_IMMERSE_LOCATION}}|$HEAVY_IMMERSE_LOCATION|g" $config_file

}

setupInstall(){
    echo "Setting up the installation"
    sudo mkdir -p $HEAVY_CONFIG_BASE #typically /var/lib/heavyai
    sudo chown $USER:$USER $HEAVY_CONFIG_BASE
    mkdir -p $CONFIG_STAGING_LOCATION
    mkdir -p $HEAVYDB_IMPORT_PATH
    mkdir -p $HEAVYDB_EXPORT_PATH
    if [ "$INSTALL_TYPE" == "soa" ]; then
        mkdir -p $HEAVY_IQ_LOCATION
        mkdir -p $HEAVY_IQ_LOCATION/log #this folder does not get created by the initial startup script.
        mkdir -p $HEAVY_IMMERSE_LOCATION
    fi

}

moveConfig(){
    echo "Moving the configuration files to the correct location"

    cp "$CONFIG_STAGING_LOCATION/$HEAVYDB_CONF_FILENAME" "$HEAVYDB_CONFIG_FILE"
    cp "$CONFIG_STAGING_LOCATION/docker-compose.yml" "../docker-compose.yml"
    


    if [ "$INSTALL_TYPE" == "soa" ]; then
        cp "$CONFIG_STAGING_LOCATION/$HEAVYIQ_CONF_FILENAME" "$HEAVY_IQ_CONFIG_FILE"
        cp "$CONFIG_STAGING_LOCATION/$IMMERSE_CONF_FILENAME" "$HEAVY_IMMERSE_CONFIG_FILE"
        cp "$CONFIG_STAGING_LOCATION/servers.json" "$IMMERSE_SERVERS_JSON"
    else
            cp "$CONFIG_STAGING_LOCATION/servers.json" "$HEAVY_CONFIG_BASE/servers.json"

    fi
    
}





setupInstall

configureApp "$HEAVY_CONF_TEMPLATE" "$CONFIG_STAGING_LOCATION/$HEAVYDB_CONF_FILENAME"
configureApp "$DOCKER_FILE_TEMPLATE" "$CONFIG_STAGING_LOCATION/docker-compose.yml"
configureApp "$IMMERSE_SERVERS_JSON_TEMPLATE" "$CONFIG_STAGING_LOCATION/servers.json"

if [ "$INSTALL_TYPE" == "soa" ]; then
    configureApp "$IMMERSE_CONF_TEMPLATE" "$CONFIG_STAGING_LOCATION/$IMMERSE_CONF_FILENAME"
    configureApp "$HEAVYIQ_CONF_TEMPLATE" "$CONFIG_STAGING_LOCATION/$HEAVYIQ_CONF_FILENAME"
fi

moveConfig