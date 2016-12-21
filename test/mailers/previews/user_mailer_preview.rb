class UserMailerPreview < ActionMailer::Preview

  def email_verification
    UserMailer.email_verification 1
  end

  def password_recovery
    UserMailer.password_recovery 1
  end

end
