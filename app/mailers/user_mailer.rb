class UserMailer < ActionMailer::Base

  def email_verification email_id
    @email = EmailAddress.find email_id
    @user = @email.user
    @code = @email.generate_verification_code
    mail to: @email.email, subject: '101DX Email Address Verification Request'
  end

  def password_recovery user_id
    @user = User.find user_id
    @code = @user.generate_password_reset_code
    mail to: @user.email.email, subject: '101DX Password Recovery Request'
  end

end
