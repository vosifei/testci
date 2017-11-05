require File.expand_path('../../../../../test/ui/base', __FILE__)

class Redmine::UiTest::IssuesTest < Redmine::UiTest::Base
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles,
           :trackers, :projects_trackers, :enabled_modules, :issue_statuses, :issues,
           :enumerations, :custom_fields, :custom_values, :custom_fields_trackers,
           :watchers, :journals, :journal_details

  def test_create_issue
    log_user('jsmith', 'jsmith')
    visit '/projects/ecookbook/issues/new'
    p current_path
    sleep(10)
#    within('form#issue-form') do
#      select 'Bug', :from => 'Tracker'
#      select 'Low', :from => 'Priority'
#      fill_in 'Subject', :with => 'new test issue'
#      fill_in 'Description', :with => 'new issue'
#      select '0 %', :from => 'Done'
#      fill_in 'Due date', :with => ''
#      fill_in 'Searchable field', :with => 'Value for field 2'
#      # click_button 'Create' would match both 'Create' and 'Create and continue' buttons
#      find('input[name=commit]').click
#    end
#
#    # find created issue
#    issue = Issue.find_by_subject("new test issue")
#    assert_kind_of Issue, issue
#
#    # check redirection
#    find 'div#flash_notice', :visible => true, :text => "Issue \##{issue.id} created."
#    assert_equal issue_path(:id => issue), current_path
#
#    # check issue attributes
#    assert_equal 'jsmith', issue.author.login
#    assert_equal 1, issue.project.id
#    assert_equal IssueStatus.find_by_name('New'), issue.status 
#    assert_equal Tracker.find_by_name('Bug'), issue.tracker
#    assert_equal IssuePriority.find_by_name('Low'), issue.priority
#    assert_equal 'Value for field 2', issue.custom_field_value(CustomField.find_by_name('Searchable field'))
  end
end