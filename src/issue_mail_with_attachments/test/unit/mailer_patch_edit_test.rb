
require File.expand_path('../../test_helper', __FILE__)

class MailPatchEditTest < ActiveSupport::TestCase
  include Redmine::I18n
  include Rails::Dom::Testing::Assertions

  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles,
           :groups_users,
           :trackers, :projects_trackers,
           :enabled_modules,
           :versions,
           :issue_statuses, :issue_categories, :issue_relations, :workflows,
           :enumerations,
           :issues, :journals, :journal_details,
           :custom_fields, :custom_fields_projects, :custom_fields_trackers, :custom_values,
           :time_entries

  def setup
  end
  
  def test_create_should_send_email_notification
    ActionMailer::Base.deliveries.clear
    issue = Issue.first
    user = User.first
    journal = issue.init_journal(user, issue)
    
    

    assert journal.save
    assert_equal 1, ActionMailer::Base.deliveries.size
  end
  
  
  
end
