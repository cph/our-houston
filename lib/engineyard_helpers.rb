def list_engineyard_vms_that_need_patches
  engineyard = Mechanize.new
  page = engineyard.get "https://login.engineyard.com/login"

  Rails.logger.debug "\e[34mLogging in to EngineYard...\e[0m"
  if page.title.strip =~ /Engine Yard:\s+Log In or Sign Up/
    form = page.form_with(id: "login-form")
    form["email"] = ENV["HOUSTON_ENGINEYARD_EMAIL"]
    form["password"] = ENV["HOUSTON_ENGINEYARD_PASSWORD"]
    page = form.submit
  end

  apps_page_title = "Engine Yard Cloud — Apps"
  unless page.title.strip == apps_page_title
    return "I'm sorry... I was trying to see which EngineYard VMs had unapplied patches; but I got confused.\nI'm on the page *#{page.title.strip}*; but I expected to be on the page *#{apps_page_title}*"
  end

  environments = page.links.select { |link| link.href =~ /\/app_deployments\/\d+\/environment$/ }
  environments_that_have_unapplied_patches = environments.select do |environment|
    url = "https://cloud.engineyard.com/#{environment.href}/upgrade"
    Rails.logger.debug "\e[34mChecking [#{environment.text}](#{url})...\e[0m"
    page = engineyard.get url
    page.search(".release_name").count > 0
  end

  if environments_that_have_unapplied_patches.none?
    return "Hey! No EngineYard VMs have unapplied patches. :shipit:"
  end

  message = "Looks like these EngineYard VMs have unapplied patches:\n"
  environments_that_have_unapplied_patches.each do |environment|
    message << "    - #{slack_link_to environment.text, "https://cloud.engineyard.com/#{environment.href}/upgrade"}\n"
  end
  message
end
