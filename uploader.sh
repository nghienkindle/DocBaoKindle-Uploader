#!/bin/bash

# -----------------------------------------------------
# KindleEar uploader
# Source: bookfere.com
# -----------------------------------------------------

r_color="\033[1;91m"
g_color="\033[1;92m"
y_color="\033[0;93m"
c_color="\033[0;36m"
w_color="\033[0;37m"
b_color="\033[1;90m"
e_color="\033[0m"

divid_1="${b_color}==============================================${e_color}"
divid_2="${b_color}----------------------------------------------${e_color}"

source_url="https://github.com/cdhigh/KindleEar.git"
if [[ $1 ]]; then
    http_code=$(curl -o /dev/null -s -w "%{http_code}" $1)
    if [ $http_code == '000' ]; then
        echo -e $divid_1
        echo -e "${r_color}指定连接有问题，请检查"
        echo -e $divid_1
        exit 0
    fi
    source_url=$1;
fi

source_path=./$(echo $source_url | sed 's/.*\/\(.*\)/\1/;s/\.git//')
config_py=$source_path/config.py
app_yaml=$source_path/app.yaml
module_worker_yaml=$source_path/module-worker.yaml
parameters=(
    "COLOR_TO_GRAY"
    "GENERATE_TOC_THUMBNAIL"
    "GENERATE_TOC_DESC"
    "GENERATE_HTML_TOC"
    "PINYIN_FILENAME"
    # more...
)
descriptions=(
    "Do_you_want_to_convert_the picture_to_grayscale?"
    "Do_you_want_to_generate_thumbnails_for_the_catalog?"
    "Do_you_want_to_add_a_summary_for_the_catalog?"
    "Do_you_want_to_to generate_an_HTML_format_catalog?"
    "Should_the_Chinese_name_be_converted_to_Pinyin?"
    # more...
)
interrupt() {
    echo -e $1$divid_2
    echo -e "${r_color}Upload aborted"
    echo -e $divid_1
    exit 0
}


cd ~ && clear
trap "interrupt \"\n\"" SIGINT
echo -e $divid_1
echo "Ready to upload KindleEar source code"
echo -e $divid_1
echo -e "${w_color}Source: $source_url${e_color}"
echo -e $divid_2

get_version() {
    version='unknown'
    version_file=$source_path/apps/__init__.py
    if [ -f $version_file ]; then
        version=$(sed -n "s/^__Version__\ =\ '\(.*\)'/\1/p" $version_file)
    fi
    echo $version
}

clone_code() {
    echo -e "${c_color}Start pulling KindleEar source code"
    rm -rf $source_path && git clone $source_url
    if [ ! -d $source_path -o ! -f $config_py -o ! $app_yaml -o ! $module_worker_yaml ]; then
        echo -e $divid_2
        echo -e "${r_color}There was a problem with the upload process, please try again."
        echo -e $divid_1
        exit 0
    fi
    echo "The source code is pulled, version number: $(get_version)"
}

if [ ! -d $source_path -o ! -f $config_py -o ! $app_yaml -o ! $module_worker_yaml ]; then
    clone_code
else
    response="y"
    echo -n -e ${y_color}"$(get_version) version already exists, pull again?[y/N]${e_color} "
    read -r response
    if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
        bak_email=$(sed -n "s/^SRC_EMAIL\ =\ \"\(.*\)\".*#.*/\1/p" $config_py)
        bak_appid=$(sed -n "s/^DOMAIN\ =\ \"http\(\|s\):\/\/\(.*\)\.appspot\.com\/\".*#.*/\2/p" $config_py)
        for parameter in ${parameters[@]}; do
            eval $parameter=$(sed -n "s/^$parameter\ =\ \(.*\)/\1/p" $config_py)
        done

        echo -e $divid_2
        clone_code

        sed -i "s/^SRC_EMAIL\ =\ \".*\"/SRC_EMAIL\ =\ \"$bak_email\"/g" $config_py
        sed -i "s/^DOMAIN\ =\ \"http\(\|s\):\/\/.*\.appspot\.com\/\"/DOMAIN\ =\ \"http:\/\/$bak_appid\.appspot\.com\/\"/g" $config_py
        for parameter in ${parameters[@]}; do
            eval sed -i "s/^$parameter\ =\ .*/$parameter\ =\ \$$parameter/g" $config_py
        done
    fi
fi

sed -i "s/^application:.*//g;s/^version:.*//g" $app_yaml $module_worker_yaml
sed -i "s/^module: worker/service: worker/g" $module_worker_yaml

email=$(sed -n "s/^SRC_EMAIL\ =\ \"\(.*\)\".*#.*/\1/p" $config_py)
appid=$(sed -n "s/^DOMAIN\ =\ \"http\(\|s\):\/\/\(.*\)\.appspot\.com\/\".*#.*/\2/p" $config_py)

echo -e ${e_color}$divid_1
if [ $email = "nghienkindle@gmail.com" -o $appid = "baokindle" ]; then
    echo -e "${y_color}Please follow the prompts to modify the APP configuration${e_color}"
    echo -e $divid_2
fi
echo -e "Gmail: "${g_color}$email${e_color}
echo -e "APPID: "${g_color}$appid${e_color}

response="y"
if [ ! $email = "akindleear@gmail.com" -o ! $appid = "kindleear" ]; then
    echo -e $divid_2
    echo -n -e "${y_color}
    
    you want to re-modify the configuration of the APP?[y/N]${e_color} "
    read -r response
fi

if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e $divid_2
    while true; do
        read -r -p "Please enter Gmail address: " email
        if [ -n "$email" ]; then
            break
        fi
        echo -e $divid_2
        echo -e "${r_color}Gmail cannot be empty, please re-enter${e_color}"
        echo -e $divid_2
    done
    while true; do
        read -r -p "Please enter your APP ID: " appid
        if [ -n "$appid" ]; then
            break
        fi
        echo -e $divid_2
        echo -e "${r_color}APP ID cannot be empty, please re-enter${e_color}"
        echo -e $divid_2
    done
    sed -i "s/^SRC_EMAIL\ =\ \".*\"/SRC_EMAIL\ =\ \"$email\"/g" $config_py
    pattern="^DOMAIN\ =\ \"http\(\|s\):\/\/.*\.appspot\.com\/\""
    replace="DOMAIN\ =\ \"http:\/\/$appid\.appspot\.com\/\""
    sed -i "s/$pattern/$replace/g" $config_py
fi
echo -e $divid_1


response="N"
echo -n -e "${y_color}Do you want to modify other configuration?[y/N]${e_color} "
read -r response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e $divid_2
    index=0
    for parameter in ${parameters[@]}; do
        old_value=$(sed -n "s/^$parameter\ =\ \(.*\)/\1/p" $config_py)
        notice="no"; if [[ $old_value = "True" ]]; then notice="yes"; fi
        response="N"
        read -r -p ${descriptions[index]}"current（${notice}）[y/N] " response
        if [[ $response ]]; then
            new_value="False"
            if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then new_value="True"; fi
            sed -i "s/^$parameter\ =\ $old_value/$parameter\ =\ $new_value/g" $config_py
        fi
        let index+=1
    done
fi
echo -e $divid_1


echo -n -e "${y_color}Preparation is completed, confirm upload [y/N]${e_color} "
read -r response
echo -e $divid_2
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
    trap interrupt SIGINT
    echo -e "${c_color}Uploading, please wait..."
    gcloud app deploy $source_path/*.yaml --version=1 --quiet
    echo -e $divid_2
    echo -e "Application access address: https://$appid.appspot.com"
else
    echo "Upload abandoned"
fi
echo -e $divid_1
