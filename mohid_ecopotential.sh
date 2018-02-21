#!/bin/bash

########################################################
#                                                      #
# Developed by Ana Isabel Oliveira for Ecopotential    #
# project.                                             #
# Objective: Became Mohid capable of doing the         #
# continuous calculation automatically taking into     #
# account the LAI values given by a time serie.        #
#                                                      #
# Date: 31/01/2018                                     #
#                                                      #
# MARETEC, IST, Lisbon.                                #
#                                                      #
########################################################

#--------------- USER'S DEFINITION -----------------#
export TERM=xterm
echo $LD_LIBRARY_PATH
LD_LIBRARY_PATH=/root/apps/zlib-1.2.11/lib:/root/apps/hdf5-1.8.15/lib:/root/apps/netcdf-4.4.1.1/lib:/opt/intel/compilers_and_libraries_2018.1.163/linux/compiler/lib/intel64_lin/
echo $LD_LIBRARY_PATH
export LD_LIBRARY_PATH
export project_path='/root/mohidtestdocker'

#---------------------- DATES ----------------------
begin_date="2010-10-01"                       #Y-M-D
end_date="2010-10-19"                         #Y-M-D
####################################################

#---------------------- OTHER INFO ----------------------
export join_timeserie_folder=/SavedResults
export config_file_temp_joinTimeSerie=/home/aoliveira/projects/Ecopotential/joinTimeSerie/joinTimeSeries_template.dat
export config_file_joinTimeSerie=/home/aoliveira/projects/Ecopotential/joinTimeSerie/joinTimeSeries.dat
export joinTimeSerie_script_folder=/home/aoliveira/projects/Ecopotential/joinTimeSerie
#########################################################

#---------------------- LAI FILE PATH ----------------------
export lai_file=${project_path}/GeneralData/BoundaryConditions/LAI.dat
################################################################

#---------------------- MOHID FOLDERS PATHS ----------------------
export mohid_data_folder=${project_path}/data/
export mohid_res_folder=${project_path}/res/
##################################################################

#---------------------- BACKUP RESULTS FOLDERS PATHS ----------------------
export results_timeseries_folder=SavedResults/
############################################################################

#---------------------- DAT FILES PATHS&NAMES ----------------------
export model_file=${project_path}/data/Model_1.dat
export model_file_template=${project_path}/data/Model.dat
export nomfich_file=${project_path}/data/Nomfich_1.dat
#####################################################################

#---------------------- EXECUTABLE PATHS ----------------------
export mohid_exe=${project_path}/exe/
###############################################################


number_threads=3


#---------------------------------------------------#
#####################################################
#---------------------------------------------------#
clear
CONTINUOUS=0
export run_off_is_active=0
export drainage_net_is_active=0
export porous_media_is_active=0
export vegetation_is_active=0
export reservoirs_is_active=0
export run_off_prop_is_active=0
export porous_media_prop_is_active=0

#------------------------- FUNCTIONS --------------------------
VERIFY_ACTIVE_MODULES(){
    while read line; do
        if [[ $line == *":"* ]] && ! [[ $line =~ ^! ]]; then
            IFS=':' read -r -a line_splitted <<< "$line"
            if [[ "${line_splitted[0]}" == *"RUN_OFF"* ]] && [[ ${line_splitted[1]} == *"1"* ]]; then
                export run_off_is_active=1
            elif [[ "${line_splitted[0]}" = *"DRAINAGE_NET"* ]] && [[ ${line_splitted[1]} == *"1"* ]]; then
                export drainage_net_is_active=1
            elif [[ "${line_splitted[0]}" = *"POROUS_MEDIA"* ]] && [[ ${line_splitted[1]} == *"1"* ]]; then
                export porous_media_is_active=1
            elif [[ "${line_splitted[0]}" = *"VEGETATION"* ]] && [[ ${line_splitted[1]} == *"1"* ]]; then
                export vegetation_is_active=1
            elif [[ "${line_splitted[0]}" = *"RESERVOIRS"* ]] && [[ ${line_splitted[1]} == *"1"* ]]; then
                export reservoirs_is_active=1
            elif [[ "${line_splitted[0]}" = *"RUN_OFF_PROPERTIES"* ]] && [[ ${line_splitted[1]} == *"1"* ]]; then
                export run_off_prop_is_active=1
            elif [[ "${line_splitted[0]}" = *"POROUS_MEDIA_PROPERTIES"* ]] && [[ ${line_splitted[1]} == *"1"* ]]; then
                export porous_media_prop_is_active=1
            fi
        fi
    done < ${mohid_data_folder}/Basin_1.dat
    }

CHANGE_CONTINUOUS(){

    if [ $1 == 1 ]; then
        mohid_filename="RunOff_1.dat"
        if [ $8 == 0 ]; then
            perl -pe "s?CONTINUOUS                : 0?CONTINUOUS                : 1?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
        else
            perl -pe "s?CONTINUOUS                : 1?CONTINUOUS                : 0?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
        fi
        rm "${mohid_data_folder}${mohid_filename}"
        mv "${mohid_data_folder}${mohid_filename}".tmp "${mohid_data_folder}${mohid_filename}"
    
    fi
    
    if [ $2 == 1 ]; then
        mohid_filename="DrainageNetwork_1.dat"
        if [ $8 == 0 ]; then
            perl -pe "s?CONTINUOUS                : 0?CONTINUOUS                : 1?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
        else
            perl -pe "s?CONTINUOUS                : 1?CONTINUOUS                : 0?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
        fi
        rm "${mohid_data_folder}${mohid_filename}"
        mv "${mohid_data_folder}${mohid_filename}".tmp "${mohid_data_folder}${mohid_filename}"
    
    fi
    
    if [ $3 == 1 ]; then
        mohid_filename="PorousMedia_1.dat"
        if [ $8 == 0 ]; then
            perl -pe "s?CONTINUOUS                : 0?CONTINUOUS                : 1?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
        else
            perl -pe "s?CONTINUOUS                : 1?CONTINUOUS                : 0?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
        fi
        rm "${mohid_data_folder}${mohid_filename}"
        mv "${mohid_data_folder}${mohid_filename}".tmp "${mohid_data_folder}${mohid_filename}"
    
    fi
    
    if [ $4 == 1 ]; then
        mohid_filename="Vegetation_1.dat"
        if [ $8 == 0 ]; then
            perl -pe "s?CONTINUOUS                : 0?CONTINUOUS                : 1?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
        else
            perl -pe "s?CONTINUOUS                : 1?CONTINUOUS                : 0?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
        fi
        rm "${mohid_data_folder}${mohid_filename}"
        mv "${mohid_data_folder}${mohid_filename}".tmp "${mohid_data_folder}${mohid_filename}"
        if [ $8 == 0 ]; then
            perl -pe "s?OLD                       : 0?OLD                       : 1?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
        else
            perl -pe "s?OLD                       : 1?OLD                       : 0?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
        fi
        rm "${mohid_data_folder}${mohid_filename}"
        mv "${mohid_data_folder}${mohid_filename}".tmp "${mohid_data_folder}${mohid_filename}"
    
    fi
    
    if [ $5 == 1 ]; then
        mohid_filename="Reservoirs_1.dat"
        if [ $8 == 0 ]; then
            perl -pe "s?CONTINUOUS                : 0?CONTINUOUS                : 1?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
        else
            perl -pe "s?CONTINUOUS                : 1?CONTINUOUS                : 0?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
        fi
        rm "${mohid_data_folder}${mohid_filename}"
        mv "${mohid_data_folder}${mohid_filename}".tmp "${mohid_data_folder}${mohid_filename}"
    
    fi
    
    if [ $6 == 1 ]; then
        mohid_filename="RunOff_Properties_1.dat"
        if [ $8 == 0 ]; then
            perl -pe "s?CONTINUOUS                : 0?CONTINUOUS                : 1?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
        else
            perl -pe "s?CONTINUOUS                : 1?CONTINUOUS                : 0?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
        fi
        rm "${mohid_data_folder}${mohid_filename}"
        mv "${mohid_data_folder}${mohid_filename}".tmp "${mohid_data_folder}${mohid_filename}"
    
    fi
    
    if [ $7 == 1 ]; then
        mohid_filename="PorousMedia_Properties_1.dat"
        if [ $8 == 0 ]; then
            perl -pe "s?CONTINUOUS                : 0?CONTINUOUS                : 1?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
        else
            perl -pe "s?CONTINUOUS                : 1?CONTINUOUS                : 0?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
        fi
        rm "${mohid_data_folder}${mohid_filename}"
        mv "${mohid_data_folder}${mohid_filename}".tmp "${mohid_data_folder}${mohid_filename}"
    
    fi

    mohid_filename="Basin_1.dat"
    if [ $8 == 0 ]; then
        perl -pe "s?CONTINUOUS                : 0?CONTINUOUS                : 1?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
    else
        perl -pe "s?CONTINUOUS                : 1?CONTINUOUS                : 0?g" "${mohid_data_folder}${mohid_filename}" > "${mohid_data_folder}${mohid_filename}".tmp
    fi
    rm "${mohid_data_folder}${mohid_filename}"
    mv "${mohid_data_folder}${mohid_filename}".tmp "${mohid_data_folder}${mohid_filename}"
    
    }
    
CHANGE_NOMFICH(){
    
    #Change RUNOFF_FIN in nomfich file
    if [ $1 == 1 ]; then
        echo "RUNOFF_INI                : ${mohid_res_folder}/RunOff_1.fin" >> "nomfich.dat"
    fi
    
    #Change RUNOFF_PROP_FIN in nomfich file
    if [ $6 == 1 ]; then
        echo "RUNOFF_PROP_INI           : ${mohid_res_folder}/RunOff_Properties_1.fin" >> "nomfich.dat"
    fi
    
    #Change DRAINAGE_NETWORK_FIN in nomfich file
    if [ $2 == 1 ]; then
        echo "DRAINAGE_NETWORK_INI      : ${mohid_res_folder}/DrainageNetwork_1.fin" >> "nomfich.dat"
    fi
    
    #Change POROUS_MEDIA_FIN in nomfich file
    if [ $3 == 1 ]; then
        echo "POROUS_INI                : ${mohid_res_folder}/PorousMedia_1.fin" >> "nomfich.dat"
    fi
    
    #Change POROUS_PROP_FIN in nomfich file
    if [ $7 == 1 ]; then
        echo "POROUS_PROP_INI           : ${mohid_res_folder}/PorousMedia_Properties_1.fin" >> "nomfich.dat"
    fi
    
    #Change VEGETATION_FIN in nomfich file
    if [ $4 == 1 ]; then
        echo "VEGETATION_INI            : ${mohid_res_folder}/Vegetation_1.fin" >> "nomfich.dat"
    fi
    
    #Change RESERVOIRS_FIN in nomfich file
    if [ $5 == 1 ]; then
        echo "RESERVOIRS_INI            : ${mohid_res_folder}/Reservoirs_1.fin" >> "nomfich.dat"
    fi

    echo "BASIN_INI                 : ${mohid_res_folder}/Basin_1.fin" >> "nomfich.dat"
    
    }

GET_BOUNDARRY_LAI(){

    i=1
    d="${1} ${2} ${3}"
    while read line; do
        if [[ $i == 1 ]]; then
            true
        elif [[ $line == *"${d}"* ]]; then
            echo "<beginproperty>" >> "${mohid_data_folder}/Vegetation_1.dat"
            echo "NAME                     : boundary leaf area index" >> "${mohid_data_folder}/Vegetation_1.dat"
            echo "UNITS                    : m2/m2" >> "${mohid_data_folder}/Vegetation_1.dat"
            echo "HDF_FIELD_NAME            : leaf area index" >> "${mohid_data_folder}/Vegetation_1.dat"
            echo "DESCRIPTION              : boundary lead area index" >> "${mohid_data_folder}/Vegetation_1.dat"
            echo "EVOLUTION                : 1" >> "${mohid_data_folder}/Vegetation_1.dat"
            echo "OLD                      : 0" >> "${mohid_data_folder}/Vegetation_1.dat"
            echo "FILE_IN_TIME             : TIMESERIE" >> "${mohid_data_folder}/Vegetation_1.dat"
            echo "FILENAME                 : ${lai_file}" >> "${mohid_data_folder}/Vegetation_1.dat"
            echo "DATA_COLUMN              : 5" >> "${mohid_data_folder}/Vegetation_1.dat"
            echo "DEFAULTVALUE             : 1." >> "${mohid_data_folder}/Vegetation_1.dat"
            echo "REMAIN_CONSTANT          : 0" >> "${mohid_data_folder}/Vegetation_1.dat"
            echo "TIME_SERIE               : 0" >> "${mohid_data_folder}/Vegetation_1.dat"
            echo "OUTPUT_HDF               : 0" >> "${mohid_data_folder}/Vegetation_1.dat"
            echo "<endproperty>" >> "${mohid_data_folder}/Vegetation_1.dat"
            export lai_boundary_block_exists=1
        fi
        i=$((i+1))
    done < ${lai_file}
}

DELETE_BOUNDARY_LAI_BLOCK(){
    for i in {1..15}; do
        sed '$d' "${mohid_data_folder}/Vegetation_1.dat" > "${mohid_data_folder}/Vegetation_1.dat".tmp
        rm "${mohid_data_folder}/Vegetation_1.dat"
        mv "${mohid_data_folder}/Vegetation_1.dat".tmp "${mohid_data_folder}/Vegetation_1.dat"
    done
}

CHANGE_TEMPLATE_JOINTIMESERIE(){

    #Insert dates
    start_day=$(date -d "${1} 00:00:00" "+%Y %m %d %H %M %S")
    end_day=$(date -d "${2} 00:00:00" "+%Y %m %d %H %M %S")
    
    perl -pe "s?begin_date?${start_day}?" ${config_file_temp_joinTimeSerie}    > "${config_file_joinTimeSerie}.tmp"
    rm "${config_file_joinTimeSerie}"
    mv "${config_file_joinTimeSerie}.tmp" "${config_file_joinTimeSerie}"
    
    perl -pe "s?end_date?${end_day}?" ${config_file_joinTimeSerie}    > "${config_file_joinTimeSerie}.tmp"
    rm "${config_file_joinTimeSerie}"
    mv "${config_file_joinTimeSerie}.tmp" "${config_file_joinTimeSerie}"
    
    #Insert folders - TIMESERIES_PATH
    perl -pe "s?timeseries_to_join?${project_path}${join_timeserie_folder}?" ${config_file_joinTimeSerie}    > "${config_file_joinTimeSerie}.tmp"
    rm "${config_file_joinTimeSerie}"
    mv "${config_file_joinTimeSerie}.tmp" "${config_file_joinTimeSerie}"

}

#--------------------------------------------------------------#

#Make a copy of the correct file Nomfich from data folder to exe folder
if [ $CONTINUOUS = 0 ]; then
    cp "${nomfich_file}" "${mohid_exe}/nomfich.dat"
else
    continue
fi

#Transformation to compare dates
begin_date_s=$(date -d "$begin_date" +%s)
end_date_s=$(date -d "$end_date" +%s)
date1=$(date -d ${begin_date} "+%Y%m%d")
date1_s=${begin_date_s}

VERIFY_ACTIVE_MODULES

while [ $date1_s -lt $end_date_s ]; do

    echo
        echo "#######################>     $date1     <#######################"
    echo
    
    #Manage dates
    start_day=$(date -d "${date1} 00:00:00" "+%Y %m %d %H %M %S")
    
    date2=$(date -d "${date1}+1 days" "+%Y%m%d")
    
    end_day=$(date -d "${date2} 00:00:00" "+%Y %m %d %H %M %S")
    
    #Verify LAI
    year=$(date -d "${date1}" "+%Y")
    month=$(date -d "${date1}" "+%m")
    day=$(date -d "${date1}" "+%d")
    export lai_boundary_block_exists=0
    GET_BOUNDARRY_LAI $year $month $day
    
    
    #Write start_day and end_day in Model.dat file
    perl -pe "s?begin_date?${start_day}?" ${model_file_template}    > "${model_file_template}.tmp"
    rm "${model_file}"
    mv "${model_file_template}.tmp" "${model_file}"
    
    perl -pe "s?end_date?${end_day}?" ${model_file}    > "${model_file}.tmp"
    rm "${model_file}"
    mv "${model_file}.tmp" "${model_file}"
    
    cd ${mohid_exe}
    #Run MOHIDLand
    ./MohidLand.exe
    
    # Delete LAI block if it exists
    if [ $lai_boundary_block_exists == 1 ]; then
        DELETE_BOUNDARY_LAI_BLOCK
    fi
    
    #Copy the results to the backup results folder    
    #TimeSeries
    folder_name=$(date -d "${date1}" "+%Y-%m-%d")"_"$(date -d "${date2}" "+%Y-%m-%d")
    if ! [ -d ${results_timeseries_folder}${folder_name} ]; then
        mkdir ${results_timeseries_folder}${folder_name}
    fi
    cp -R "${mohid_res_folder}Run1/." "${results_timeseries_folder}${folder_name}"
    
    #Activate the continuous keywords and add the path to fin files to nomfich
    if [ $CONTINUOUS = 0 ]; then
    
        CHANGE_CONTINUOUS $run_off_is_active $drainage_net_is_active $porous_media_is_active $vegetation_is_active $reservoirs_is_active $run_off_prop_is_active $porous_media_prop_is_active $CONTINUOUS

        CONTINUOUS=1
        
    fi
        
    if [ $CONTINUOUS = 1 ]; then
    
        cp ${nomfich_file} nomfich.dat
    
    fi
    
    CHANGE_NOMFICH  $run_off_is_active $drainage_net_is_active $porous_media_is_active $vegetation_is_active $reservoirs_is_active $run_off_prop_is_active $porous_media_prop_is_active
    
    #Next date
    date1=$(date -d "${date2}" "+%Y%m%d")
    date1_s=$(date -d $date1 +%s)

done

#Clear nomfich file and turn Contiuous to 0
cp ${nomfich_file} nomfich.dat
CHANGE_CONTINUOUS $run_off_is_active $drainage_net_is_active $porous_media_is_active $vegetation_is_active $reservoirs_is_active $run_off_prop_is_active $porous_media_prop_is_active $CONTINUOUS

#Join time series script
CHANGE_TEMPLATE_JOINTIMESERIE $begin_date $end_date
cd ${joinTimeSerie_script_folder}
perl joinTimeSeries.pl -c=${config_file_joinTimeSerie}

#Manage folders
cd ${project_path}
cp -R Output/* ${join_timeserie_folder}
rm -r Output
rm -r Output1
rm -r Output2

#Add <EndTimeSerie> string to file
cd ${project_path}${join_timeserie_folder}
srvg_file=`readlink -e *.srvg`
echo ${srvg_file}
echo "<EndTimeSerie>" >> ${srvg_file}

