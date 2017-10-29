# aaaaaaaaaaaaa sample_model_test.rb - test
require File.expand_path('../../test_helper', __FILE__)

class MailPatchTest < ActiveSupport::TestCase
  include Redmine::I18n
#  include Rails::Dom::Testing::Assertions

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
#    ActionMailer::Base.deliveries.clear
#    Setting.host_name = 'mydomain.foo'
#    Setting.protocol = 'http'
#    Setting.plain_text_mail = '0'
#    Setting.default_language = 'en'
#    User.current = nil
  end
  
  def generate_issue_with_attachment_001()
    att = Attachment.new(
                     :file => uploaded_test_file("testfile.txt", "text/plain"),
                     :author_id => 3
                   )
    atts = [att]
    assert att.save
    issue = Issue.new(:project_id => 1, :tracker_id => 1,
                      :author_id => 3, :status_id => 1,
                      :priority => IssuePriority.all.first,
                      :subject => 'test_create', :estimated_hours => '1:30',
                      :attachments => atts
    )
    return issue, atts
  end
  def generate_issue_with_attachment_001()
    atts = []
    att = Attachment.new(
                     :file => uploaded_test_file("testfile.txt", "text/plain"),
                     :author_id => 3
                   )
    assert att.save
    atts << att
    
    att = Attachment.new(
                     :file => uploaded_test_file("2010/11/101123161450_testfile_1.png", "image/png"),
                     :author_id => 3
                   )
    assert att.save
    atts << att
    
    att = Attachment.new(
                     :file => uploaded_test_file("japanese-utf-8.txt", "text/plain"),
                     :author_id => 3
                   )
    assert att.save
    atts << att

    issue = Issue.new(:project_id => 1, :tracker_id => 1,
                      :author_id => 3, :status_id => 1,
                      :priority => IssuePriority.all.first,
                      :subject => 'test_create', :estimated_hours => '1:30',
                      :attachments => atts
    )
    return issue, atts
  end
  
  def settings_init(raw_settings)
    if Redmine::VERSION::MAJOR == 2
      return HashWithIndifferentAccess.new(raw_settings)
    else
      return ActionController::Parameters.new(raw_settings)
    end
  end

  def test_add__att_nabled_true__attach_all_false
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false'
    })
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_equal 4, ActionMailer::Base.deliveries.size
      mail = ActionMailer::Base.deliveries[-1]
      assert_equal 1, mail.attachments.size
      mail = ActionMailer::Base.deliveries[-2]
      assert_equal 1, mail.attachments.size
      mail = ActionMailer::Base.deliveries[-3]
      assert_equal 1, mail.attachments.size
      mail = ActionMailer::Base.deliveries[-4]
      assert_equal 0, mail.attachments.size
    end
  end

  def test_add__att_nabled_true__attach_all_true
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'true'
    })
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_equal 1, ActionMailer::Base.deliveries.size
      mail = ActionMailer::Base.deliveries.last
      assert_equal 3, mail.attachments.size
    end
  end

  def test_add__att_nabled_false__att_all_false
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'false',
      :attach_all_to_notification => 'false'
    })
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_equal 1, ActionMailer::Base.deliveries.size
      mail = ActionMailer::Base.deliveries[-1]
      assert_equal 0, mail.attachments.size
    end
  end

  def test_add__att_nabled_false__att_all_true
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'false',
      :attach_all_to_notification => 'true'
    })
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_equal 1, ActionMailer::Base.deliveries.size
      mail = ActionMailer::Base.deliveries[-1]
      assert_equal 0, mail.attachments.size
    end
  end

  def test_add__att_nabled_true__att_all_false__prj_lve_true__prj_disabled
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :enable_project_level_control => 'true'
    })
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_equal 1, ActionMailer::Base.deliveries.size
      mail = ActionMailer::Base.deliveries[-1]
      assert_equal 0, mail.attachments.size
    end
  end

  def test_add__att_nabled_true__att_all_false__prj_lve_true__prj_enabled
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :enable_project_level_control => 'true'
    })
    
    # enable project module of plugin
    pj = Project.find(1)
    pj.enable_module!(:issue_mail_with_attachments_plugin)
    pj.save
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_equal 4, ActionMailer::Base.deliveries.size
      mail = ActionMailer::Base.deliveries[-1]
      assert_equal 1, mail.attachments.size
      mail = ActionMailer::Base.deliveries[-2]
      assert_equal 1, mail.attachments.size
      mail = ActionMailer::Base.deliveries[-3]
      assert_equal 1, mail.attachments.size
      mail = ActionMailer::Base.deliveries[-4]
      assert_equal 0, mail.attachments.size
    end
  end

  def test_add__att_nabled_true__att_all_true__prj_lve_true__prj_disabled
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'true',
      :enable_project_level_control => 'true'
    })
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_equal 1, ActionMailer::Base.deliveries.size
      mail = ActionMailer::Base.deliveries[-1]
      assert_equal 0, mail.attachments.size
    end
  end

  def test_add__att_nabled_true__att_all_true__prj_lve_true__prj_enabled
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'true',
      :enable_project_level_control => 'true'
    })
    
    # enable project module of plugin
    pj = Project.find(1)
    pj.enable_module!(:issue_mail_with_attachments_plugin)
    pj.save
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_equal 1, ActionMailer::Base.deliveries.size
      mail = ActionMailer::Base.deliveries.last
      assert_equal 3, mail.attachments.size
    end
  end
  
#  def test_add__att_nabled_true__att_all_false__prj_lve_true__prj_enabled
#    ActionMailer::Base.deliveries.clear
#    issue, = generate_issue_with_attachment_001
#    
#    plugin_settings = settings_init({
#      :enable_mail_attachments => 'true',
#      :attach_all_to_notification => 'false',
#      :enable_project_level_control => 'false',
#      :field_name_to_enable_att => 'aField'
#    })
#    
#    cf = IssueCustomField.new(:name => 'regexp', :field_format => 'text', :regexp => '[a-z0-9')
#    
#    # enable project module of plugin
#    pj = Project.find(1)
#    pj.enable_module!(:issue_mail_with_attachments_plugin)
#    pj.save
#    
#    with_settings( {:notified_events => %w(issue_added issue_updated),
#      :plugin_issue_mail_with_attachments => plugin_settings
#    }) do
#      assert issue.save
#      assert_equal 1, ActionMailer::Base.deliveries.size
#      mail = ActionMailer::Base.deliveries.last
#      assert_equal 3, mail.attachments.size
#    end
#  end
  
  
  
  
end
