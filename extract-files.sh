#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=cannon
VENDOR=xiaomi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
    vendor/lib64/hw/fingerprint.fpc.default.so)
        sed -i "s|\xDD\xB0\x01\x94|\x1F\x20\x03\xD5|g;s|\xC8\xB0\x01\x94|\x1F\x20\x03\xD5|g" "${2}"
        ;;
    vendor/lib64/libgf_hal.so)
        sed -i "s|\xBC\x9B\x00\x94|\x1F\x20\x03\xD5|g;s|\x9F\x9B\x00\x94|\x1F\x20\x03\xD5|g" "${2}"
        ;;
    vendor/lib64/libmtkcam_featurepolicy.so)
        sed -i "s|\xE8\x87\x40\xB9|\x28\x02\x80\x52|g" "${2}"
        ;;
    vendor/etc/init/vendor.mediatek.hardware.mtkpower@1.0-service.rc)
        echo "$(cat ${2}) input" > "${2}"
        ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
