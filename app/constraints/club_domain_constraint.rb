# Routes inside this constraint serve club websites: any host other than the
# apex (Settings.host) is assumed to be a club domain. Club lookup happens in
# Clubsite::BaseController so routing stays free of database access.
class ClubDomainConstraint
  def matches?(request)
    # Settings.host may be configured with or without a port (e.g. localhost:3000)
    apex = Settings.host
    request.host != apex && request.host_with_port != apex
  end
end
