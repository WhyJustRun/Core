class UserMailer < ActionMailer::Base
  default :from => 'noreply@transactional.whyjustrun.ca'

  def send_message_email(sender, receiver, message)
    @sender = sender
    @receiver = receiver
    @message = message
    mail(to: receiver.email,
         reply_to: sender.email,
         subject: "Message from #{sender.name}")
  end
end
