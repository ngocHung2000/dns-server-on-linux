#!/bin/bash

RESULT=/scripting-pipeline/date_last_modified
FILENAME_EXISTS=("/scripting-pipeline/output.txt" "/scripting-pipeline/script.sh" "/scripting-pipeline/data.txt","/scripting-pipeline/run.sh","/scripting-pipeline/${RESULT}.txt")

if [ -z "$1" ] 
then
  FOLDER_NAME="lastmodified-bar"
else
  # Use provided value
  FOLDER_NAME="$1"
fi

if [ ! -f /$FOLDER_NAME ] 
then
  rm -rf /$FOLDER_NAME
fi

mkdir -p /$FOLDER_NAME
cd /$FOLDER_NAME

for filename in "${FILENAME_EXISTS[@]}"; do
    if [ -e "$filename" ]; then
        echo "File $filename exists. Removing..."
        rm "$filename"
        echo "File $filename removed."
    else
        echo "File $filename does not exist."
    fi
done

oc get IntegrationRuntime -A --no-headers | awk '{print $1 " " $2}' > common.txt

while read line
do
  NAMESPACE=$( echo $line | cut -d ' ' -f 1 )
  INSTANCE=$( echo $line | cut -d ' ' -f 2 )
  OUTPUT=$( oc get secret -n $NAMESPACE ${INSTANCE}-ir -o json | jq -r '.data.adminusers' | base64 -d )
  POD_NAME=$( oc get po -n $NAMESPACE | grep $INSTANCE | head -n 1 | awk '{print $1}' )
  
  printf '%s %s %s\n' "$NAMESPACE" "$POD_NAME" "$OUTPUT " >> output.txt
done < common.txt

while read line
do
  NAMESPACE=$( echo $line | cut -d ' ' -f 1 )
  POD_NAME=$( echo $line | cut -d ' ' -f 2 )
  USER=$( echo $line | cut -d ' ' -f 3 )
  PASSWD=$( echo $line | cut -d ' ' -f 4 )
  
  echo "oc -n $NAMESPACE rsh $POD_NAME curl --cert /home/aceuser/adminssl/tls.crt.pem --key /home/aceuser/adminssl/tls.key.pem -k -X GET https://localhost:7600/apiv2/applications -u ${USER}:${PASSWD} | jq -r  '.children[].uri' | while read name; do printf '%s %s %s %s %s\n' \$name $NAMESPACE $POD_NAME $USER $PASSWD >> data.txt; done;" >> script.sh
  echo "oc -n $NAMESPACE rsh $POD_NAME curl --cert /home/aceuser/adminssl/tls.crt.pem --key /home/aceuser/adminssl/tls.key.pem -k -X GET https://localhost:7600/apiv2/policies -u ${USER}:${PASSWD} | jq -r  '.children[].uri' | while read name; do printf '%s %s %s %s %s\n' \$name $NAMESPACE $POD_NAME $USER $PASSWD >> data.txt; done;" >> script.sh
  echo "oc -n $NAMESPACE rsh $POD_NAME curl --cert /home/aceuser/adminssl/tls.crt.pem --key /home/aceuser/adminssl/tls.key.pem -k -X GET https://localhost:7600/apiv2/shared-libraries -u ${USER}:${PASSWD} | jq -r  '.children[].uri' | while read name; do printf '%s %s %s %s %s\n' \$name $NAMESPACE $POD_NAME $USER $PASSWD >> data.txt; done;" >> script.sh
done < output.txt

chmod +x script.sh
bash script.sh

if [ -e /$FOLDER_NAME/$RESULT.txt ]
then
  rm -rf /$FOLDER_NAME/$RESULT.txt
fi

while read line
do
  URI=$( echo $line | cut -d ' ' -f 1 )
  NAMESPACE=$( echo $line | cut -d ' ' -f 2 )
  POD_NAME=$( echo $line | cut -d ' ' -f 3 )
  USER=$( echo $line | cut -d ' ' -f 4 )
  PASSWD=$( echo $line | cut -d ' ' -f 5 )
  
  echo "oc -n $NAMESPACE rsh $POD_NAME curl --cert /home/aceuser/adminssl/tls.crt.pem --key /home/aceuser/adminssl/tls.key.pem -k -X GET https://localhost:7600${URI} -u ${USER}:${PASSWD} | jq -rc '.descriptiveProperties.lastModified + \" \" + (.name | tostring ) + \" \" + \"$NAMESPACE\" + \" \" + \"$POD_NAME\"' >> $RESULT.txt" >> run.sh
done < data.txt

chmod +x run.sh
bash run.sh

cp $RESULT.txt $RESULT-$(date '+%Y.%m.%d_%H_%M_%S').txt


printf "\n===================== Please check result at: /%s/%s-$(date '+%Y.%m.%d_%H_%M_%S').txt =============================\n" $FOLDER_NAME $RESULT