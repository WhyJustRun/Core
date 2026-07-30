# Short-lived signed tokens that carry a signed-in apex session over to a club
# domain (cookies cannot span the different domains). The token is bound to
# the destination host so one leaked from logs or a referrer cannot be
# replayed on another club's domain.
class SsoToken
  EXPIRY = 60.seconds

  def self.generate(user, host)
    verifier.generate({ 'user_id' => user.id, 'host' => host },
                      expires_in: EXPIRY, purpose: :clubsite_sso)
  end

  # Returns the payload hash, or nil when invalid or expired
  def self.verify(token)
    verifier.verified(token, purpose: :clubsite_sso)
  end

  def self.verifier
    Rails.application.message_verifier(:clubsite_sso)
  end
end
