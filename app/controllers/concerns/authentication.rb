module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  private

  def require_authentication
    resume_session || redirect_to(new_session_path)
  end

  def resume_session
    if (session = find_session_by_cookie)
      Current.session = session
      Current.account = session.manager.account
    end
  end

  def find_session_by_cookie
    Session.find_by(token: cookies.signed[:session_token]) if cookies.signed[:session_token]
  end

  def start_session(manager)
    session = manager.sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    cookies.signed[:session_token] = {
      value: session.token,
      httponly: true,
      same_site: :lax,
      secure: Rails.env.production?,
      expires: 30.days.from_now
    }
    session
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(:session_token)
  end

  def authenticated?
    Current.session.present?
  end
end
