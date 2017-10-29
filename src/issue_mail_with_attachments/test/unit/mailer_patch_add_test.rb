
require File.expand_path('../../test_helper', __FILE__)

class MailPatchAddTest < ActiveSupport::TestCase
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
  
  
  def assert_sent_with_dedicated_mails(num_att_mails)
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

  def test_add__att_enabled_true__attach_all_false
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
      assert_sent_with_dedicated_mails 3
    end
  end

  def test_add__att_enabled_true__attach_all_true
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
      assert_sent_with_attach_all
    end
  end

  def test_add__att_enabled_false__att_all_false
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
      assert_sent_with_no_attachments
    end
  end

  def test_add__att_enabled_false__att_all_true
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
      assert_sent_with_no_attachments
    end
  end

  def test_add__att_enabled_true__att_all_false__prj_lve_true__prj_disabled
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
      assert_sent_with_no_attachments
    end
  end

  def test_add__att_enabled_true__att_all_false__prj_lve_true__prj_enabled
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
      assert_sent_with_dedicated_mails 3
    end
  end

  def test_add__att_enabled_true__att_all_true__prj_lve_true__prj_disabled
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
      assert_sent_with_no_attachments
    end
  end

  def test_add__att_enabled_true__att_all_true__prj_lve_true__prj_enabled
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
      assert_sent_with_attach_all
    end
  end
  
  def test_add__att_enabled_true__att_all_false__cf_enabled__cv_1
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :field_name_to_enable_att => 'aTestField'
    })
    
    cf = IssueCustomField.generate!(:name => 'aTestField', :field_format => 'bool')
    cf.save
    issue.custom_field_values = { cf.id => 1 }
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_dedicated_mails 3
    end
  end
  
  def test_add__att_enabled_true__att_all_false__cf_enabled__cv_0
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :field_name_to_enable_att => 'aTestField'
    })
    
    cf = IssueCustomField.generate!(:name => 'aTestField', :field_format => 'bool')
    cf.save
    issue.custom_field_values = { cf.id => 0 }
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_no_attachments
    end
  end

  
  def test_add__att_enabled_true__att_all_false__cf_enabled__cv_default
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :field_name_to_enable_att => 'aTestField'
    })
    
    cf = IssueCustomField.generate!(:name => 'aTestField', :field_format => 'bool')
    cf.save
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_no_attachments
    end
  end
  
  def test_add__att_enabled_true__att_all_false__cf_enabled__cv_not_defined
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :field_name_to_enable_att => 'aTestField'
    })
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_dedicated_mails 3
    end
  end
  
  def test_add__att_enabled_true__att_all_false__prj_lve_true__prj_enabled__cf_enabled__cv_1
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :enable_project_level_control => 'true',
      :field_name_to_enable_att => 'aTestField'
    })
    
    # enable project module of plugin
    pj = Project.find(1)
    pj.enable_module!(:issue_mail_with_attachments_plugin)
    pj.save
    
    cf = IssueCustomField.generate!(:name => 'aTestField', :field_format => 'bool')
    cf.save
    issue.custom_field_values = { cf.id => 1 }
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_dedicated_mails 3
    end
  end
  
  def test_add__att_enabled_true__att_all_false__prj_lve_true__prj_disabled__cf_enabled__cv_1
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :enable_project_level_control => 'true',
      :field_name_to_enable_att => 'aTestField'
    })
    
    cf = IssueCustomField.generate!(:name => 'aTestField', :field_format => 'bool')
    cf.save
    issue.custom_field_values = { cf.id => 1 }
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_no_attachments
    end
  end
  
  def test_add__att_enabled_true__att_all_false__prj_lve_true__prj_enabled__cf_enabled__cv_0
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :enable_project_level_control => 'true',
      :field_name_to_enable_att => 'aTestField'
    })
    
    # enable project module of plugin
    pj = Project.find(1)
    pj.enable_module!(:issue_mail_with_attachments_plugin)
    pj.save
    
    cf = IssueCustomField.generate!(:name => 'aTestField', :field_format => 'bool')
    cf.save
    issue.custom_field_values = { cf.id => 0 }
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_no_attachments
    end
  end
  
  def test_add__att_enabled_true__att_all_false__prj_lve_true__prj_enabled__cf_enabled__cv_1
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'true',
      :enable_project_level_control => 'true',
      :field_name_to_enable_att => 'aTestField'
    })
    
    # enable project module of plugin
    pj = Project.find(1)
    pj.enable_module!(:issue_mail_with_attachments_plugin)
    pj.save
    
    cf = IssueCustomField.generate!(:name => 'aTestField', :field_format => 'bool')
    cf.save
    issue.custom_field_values = { cf.id => 1 }
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_attach_all
    end
  end
  
  def test_add__att_enabled_false__att_all_false__prj_lve_true__prj_enabled__cf_enabled__cv_1
    ActionMailer::Base.deliveries.clear
    issue, = generate_issue_with_attachment_001
    
    plugin_settings = settings_init({
      :enable_mail_attachments => 'false',
      :attach_all_to_notification => 'false',
      :enable_project_level_control => 'true',
      :field_name_to_enable_att => 'aTestField'
    })
    
    # enable project module of plugin
    pj = Project.find(1)
    pj.enable_module!(:issue_mail_with_attachments_plugin)
    pj.save
    
    cf = IssueCustomField.generate!(:name => 'aTestField', :field_format => 'bool')
    cf.save
    issue.custom_field_values = { cf.id => 1 }
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_no_attachments
    end
  end
  

  
end
