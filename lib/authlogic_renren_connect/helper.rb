module AuthlogicRenrenConnect
  module Helper
    def authlogic_renren_login_button(user_sessions_path='/user_sessions')
      output = "<form id='connect_to_renren_form' method='post' action='#{user_sessions_path}'>\n"
      output << "<input type='hidden' name='authenticity_token' value='#{form_authenticity_token}'/>\n"
      output << "</form>\n"
      output << xn_login_button(:onlogin => "document.getElementById('connect_to_renren_form').submit();")
      output.html_safe!
    end
  end
end
