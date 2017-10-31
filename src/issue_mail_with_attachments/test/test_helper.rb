 Coveralls configuration
require 'simplecov'
require 'coveralls'
SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
   add_filter do |source_file|
     !source_file.filename.include? "/plugins/"
   end
   add_filter '/lib/plugins/'
   add_filter '/db/'
end
Coveralls.wear!('rails')

# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

  
  def assert_sent_with_dedicated_mails(num_att_mails=3)
    assert_equal num_att_mails +1, ActionMailer::Base.deliveries.size
    (1..(num_att_mails)).each do |r|
      assert_equal 1, ActionMailer::Base.deliveries[-r].attachments.size
    end
    assert_equal 0, ActionMailer::Base.deliveries[-(num_att_mails +1)].attachments.size
  end
  
  def assert_sent_with_attach_all()
      assert_equal 1, ActionMailer::Base.deliveries.size
      assert_equal 3, ActionMailer::Base.deliveries.last.attachments.size
  end

  def assert_sent_with_no_attachments()
      assert_equal 1, ActionMailer::Base.deliveries.size
      assert_equal 0, ActionMailer::Base.deliveries.last.attachments.size
  end
  
  def plugin_settings_init(raw_settings)
    if Redmine::VERSION::MAJOR == 2
      return HashWithIndifferentAccess.new(raw_settings)
    else
      return ActionController::Parameters.new(raw_settings)
    end
  end
