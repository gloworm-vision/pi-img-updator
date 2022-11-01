PI_BASE_IMG_TAG=023434d-photonvision-v2021.1.3
PHOTONVISION_RELEASE_TAG=v2023.1.1-beta-5
VENDOR_PREFIX=Gloworm
VENDOR_RELEASE=${RELEASE_VERSION}

# Install dependencies
sudo apt install unzip zip sed

# Download new jar from photonvision main repo
curl -sk https://api.github.com/repos/photonvision/photonvision/releases/tags/${PHOTONVISION_RELEASE_TAG} | grep "browser_download_url.*photonvision-.*raspi\.jar" | cut -d : -f 2,3 | tr -d '"' | wget -i -
JAR_FILE_NAME=$(realpath $(ls | grep photonvision-v.*\.jar))

# Download base image from pigen repo
curl -sk https://api.github.com/repos/gloworm-vision/pi-gen/releases/tags/${PI_BASE_IMG_TAG} | grep "browser_download_url.*zip" | cut -d : -f 2,3 | tr -d '"' | wget -i -
IMG_FILE_NAME=$(realpath $(ls | grep Gloworm-lite*.zip))

# Config files should be in this repo
HW_CFG_FILE_NAME=$(realpath $(find . -name hardwareConfig.json))

# Unzip and mount the image to be updated
unzip $IMG_FILE_NAME
IMAGE_FILE=$(ls | grep *.img)
TMP=$(mktemp -d)
LOOP=$(sudo losetup --show -fP "${IMAGE_FILE}")
sudo mount ${LOOP}p2 $TMP
pushd .

# Copy in the new .jar
cd $TMP/opt/photonvision
sudo cp $JAR_FILE_NAME photonvision.jar

# Copy in custom hardware configuration 
cd photonvision_config
sudo cp ${HW_CFG_FILE_NAME} hardwareConfig.json

# Update hardware configuration in place to indicate what release this was
sudo sed -i 's/VENDOR_RELEASE/'"${VENDOR_RELEASE}"'/g' hardwareConfig.json

# Cleanup
popd
sudo umount ${TMP}
sudo rmdir ${TMP}
NEW_IMAGE=$(basename "${VENDOR_PREFIX}-${VENDOR_RELEASE}.img")
mv $IMAGE_FILE $NEW_IMAGE
zip -r $(basename "${VENDOR_PREFIX}-${VENDOR_RELEASE}-image.zip") $NEW_IMAGE
ls
rm $NEW_IMAGE
rm $JAR_FILE_NAME
rm $IMG_FILE_NAME

# make some release notes
touch release_notes.txt
echo "# PhotonVision Raspberry Pi Image for Gloworm ${VENDOR_RELEASE}" >> release_notes.txt
echo "Built From:" >> release_notes.txt
echo "  * PhotonVision .jar version ${PHOTONVISION_RELEASE_TAG}" >> release_notes.txt
echo "  * Gloworm base Raspberry Pi image version ${PI_BASE_IMG_TAG}" >> release_notes.txt
echo "  * Gloworm hardware support file from ${VENDOR_RELEASE}" >> release_notes.txt
echo "" >> release_notes.txt

