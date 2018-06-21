#!/usr/bin/env bash



DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd ${DIR}


source ./conf.env



cp ./var-lib-jenkins.mount /etc/systemd/system
systemctl start var-lib-jenkins.mount
sleep 5
systemctl is-active --quiet var-lib-jenkins.mount
if [ $? -ne 0 ]; then
    echo " [ERR] Mounting gluster brick to provide JENKINS_HOME failed."
    exit 1;
fi

# NOTE: handling case where GlusterFS brick already contains Jenkins setup
if [ "$(ls -A ${JENKINS_HOME_PATH})" ]; then
    echo " [WARN] JENKINS_HOME already contains configuration. Skipping..."
    systemctl stop var-lib-jenkins.mount
    exit 0
fi

chown -R "${JENKINS_USER_NAME}:${JENKINS_USER_NAME}" "${JENKINS_HOME_PATH}"


sed -i \
    -e 's/JENKINS_JNLP_PORT/'"${JENKINS_JNLP_PORT}"'/g' \
    ./config.xml_template
cp ./config.xml_template "${JENKINS_HOME_PATH}/config.xml"

escapedJenkinsURL=$(printf '%s\n' "${JENKINS_URL}" | sed 's/[\&/]/\\&/g')
sed -i \
    -e 's/JENKINS_URL/'"${escapedJenkinsURL}"'/g' \
    ./jenkins.model.JenkinsLocationConfiguration.xml_template
cp ./jenkins.model.JenkinsLocationConfiguration.xml_template "${JENKINS_HOME_PATH}/jenkins.model.JenkinsLocationConfiguration.xml"

cp /etc/sysconfig/jenkins /etc/sysconfig/jenkins.default
sed -i \
    -e '/JENKINS_ARGS=/c\JENKINS_ARGS="-Djenkins.install.runSetupWizard=false"' \
    /etc/sysconfig/jenkins
chown -R "${JENKINS_USER_NAME}:${JENKINS_USER_NAME}" "${JENKINS_HOME_PATH}"


# starting jenkins for the first time
systemctl start jenkins
sleep 20


curl --output ./jenkins-cli.jar \
     --location \
     --silent \
     "http://localhost:${JENKINS_WEB_PORT}/jnlpJars/jenkins-cli.jar"

java -jar ./jenkins-cli.jar \
     -s "http://localhost:${JENKINS_WEB_PORT}/" \
     create-job example < ./example-job.xml

while read plugin; do
    java -jar ./jenkins-cli.jar \
         -s "http://localhost:${JENKINS_WEB_PORT}/" \
         install-plugin "${plugin}"
done < "./plugin-list.txt"

java -jar ./jenkins-cli.jar \
     -s "http://localhost:${JENKINS_WEB_PORT}/" \
     restart && sleep 15


systemctl stop jenkins && systemctl stop var-lib-jenkins.mount
