# Configure the Jenkins CIServer adapter
Houston::Ci.config.ci_server :jenkins do
  host "ci.cphepdev.com"
  port 443
  username ENV["HOUSTON_JENKINS_USERNAME"]
  password ENV["HOUSTON_JENKINS_PASSWORD"]
end
