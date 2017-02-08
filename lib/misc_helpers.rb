def ep_developer?(user)
  user && EP_DEVELOPERS.member?(user.email)
end
