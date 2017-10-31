
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
           :time_entries,
           :attachments

  def setup
  end
  
  def generate_data_with_attachment_001(num=3)
    issue = Issue.find(3)
    user = User.first
    
    att_files = [
      ["testfile.txt", "text/plain"],
      ["2010/11/101123161450_testfile_1.png", "image/png"],
      ["japanese-utf-8.txt", "text/plain"]
      ]

    journals = []
    atts = []
    (0..num -1).each do |idx|
      att = Attachment.new(
                       :file => uploaded_test_file(att_files[idx][0], att_files[idx][1]),
                       :author_id => 3
                     )
      assert att.save
      atts << att
      journal = issue.init_journal(user, issue)
      journal.journalize_attachment(att, :added)
      journals << journal
    end

    return issue, journals, atts
  end
  
  def test__att_enabled_true__attach_all_false
    ActionMailer::Base.deliveries.clear
    issue, = generate_data_with_attachment_001 1
    
    plugin_settings = plugin_settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false'
    })
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_dedicated_mails 1
    end
  end

  def test__att_enabled_true__attach_all_true
    ActionMailer::Base.deliveries.clear
    issue, = generate_data_with_attachment_001
    
    plugin_settings = plugin_settings_init({
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

  def test__att_enabled_false__att_all_false
    ActionMailer::Base.deliveries.clear
    issue, = generate_data_with_attachment_001
    
    plugin_settings = plugin_settings_init({
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

  def test__att_enabled_false__att_all_true
    ActionMailer::Base.deliveries.clear
    issue, = generate_data_with_attachment_001
    
    plugin_settings = plugin_settings_init({
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

  def test__att_enabled_true__att_all_false__prj_lve_true__prj_disabled
    ActionMailer::Base.deliveries.clear
    issue, = generate_data_with_attachment_001
    
    plugin_settings = plugin_settings_init({
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

  def test__att_enabled_true__att_all_false__prj_lve_true__prj_enabled
    ActionMailer::Base.deliveries.clear
    issue, = generate_data_with_attachment_001 2
    
    plugin_settings = plugin_settings_init({
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
      assert_sent_with_dedicated_mails 2
    end
  end

  def test__att_enabled_true__att_all_true__prj_lve_true__prj_disabled
    ActionMailer::Base.deliveries.clear
    issue, = generate_data_with_attachment_001
    
    plugin_settings = plugin_settings_init({
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

  def test__att_enabled_true__att_all_true__prj_lve_true__prj_enabled
    ActionMailer::Base.deliveries.clear
    issue, = generate_data_with_attachment_001
    
    plugin_settings = plugin_settings_init({
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
  
  def test__att_enabled_true__att_all_false__cf_enabled__cv_1
    ActionMailer::Base.deliveries.clear
    cf = IssueCustomField.generate!(:name => 'aTestField', :field_format => 'bool')
    cf.save
    issue, = generate_data_with_attachment_001 3
    
    plugin_settings = plugin_settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :field_name_to_enable_att => 'aTestField'
    })
    
    issue.custom_field_values = { cf.id => 1 }
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_dedicated_mails 3
    end
  end
  
  def test__att_enabled_true__att_all_false__cf_enabled__cv_0
    ActionMailer::Base.deliveries.clear
    cf = IssueCustomField.generate!(:name => 'aTestField', :field_format => 'bool')
    cf.save
    issue, = generate_data_with_attachment_001
    
    plugin_settings = plugin_settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :field_name_to_enable_att => 'aTestField'
    })
    
    issue.custom_field_values = { cf.id => 0 }
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_no_attachments
    end
  end

  
  def test__att_enabled_true__att_all_false__cf_enabled__cv_default
    ActionMailer::Base.deliveries.clear
    cf = IssueCustomField.generate!(:name => 'aTestField', :field_format => 'bool')
    cf.save
    issue, = generate_data_with_attachment_001
    
    plugin_settings = plugin_settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :field_name_to_enable_att => 'aTestField'
    })
    
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_no_attachments
    end
  end
  
  def test__att_enabled_true__att_all_false__cf_enabled__cv_not_defined
    ActionMailer::Base.deliveries.clear
    issue, = generate_data_with_attachment_001 1
    
    plugin_settings = plugin_settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :field_name_to_enable_att => 'aTestField'
    })
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_dedicated_mails 1
    end
  end
  
  def test__att_enabled_true__att_all_false__prj_lve_true__prj_enabled__cf_enabled__cv_1
    ActionMailer::Base.deliveries.clear
    cf = IssueCustomField.generate!(:name => 'aTestField', :field_format => 'bool')
    cf.save
    issue, = generate_data_with_attachment_001 2
    
    plugin_settings = plugin_settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :enable_project_level_control => 'true',
      :field_name_to_enable_att => 'aTestField'
    })
    
    # enable project module of plugin
    pj = Project.find(1)
    pj.enable_module!(:issue_mail_with_attachments_plugin)
    pj.save
    
    issue.custom_field_values = { cf.id => 1 }
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_dedicated_mails 2
    end
  end
  
  def test__att_enabled_true__att_all_false__prj_lve_true__prj_disabled__cf_enabled__cv_1
    ActionMailer::Base.deliveries.clear
    cf = IssueCustomField.generate!(:name => 'aTestField', :field_format => 'bool')
    cf.save
    issue, = generate_data_with_attachment_001
    
    plugin_settings = plugin_settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :enable_project_level_control => 'true',
      :field_name_to_enable_att => 'aTestField'
    })
    
    issue.custom_field_values = { cf.id => 1 }
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_no_attachments
    end
  end
  
  def test__att_enabled_true__att_all_false__prj_lve_true__prj_enabled__cf_enabled__cv_0
    ActionMailer::Base.deliveries.clear
    cf = IssueCustomField.generate!(:name => 'aTestField', :field_format => 'bool')
    cf.save
    issue, = generate_data_with_attachment_001
    
    plugin_settings = plugin_settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :enable_project_level_control => 'true',
      :field_name_to_enable_att => 'aTestField'
    })
    
    # enable project module of plugin
    pj = Project.find(1)
    pj.enable_module!(:issue_mail_with_attachments_plugin)
    pj.save
    
    issue.custom_field_values = { cf.id => 0 }
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_no_attachments
    end
  end
  
  def test__att_enabled_true__att_all_true__prj_lve_true__prj_enabled__cf_enabled__cv_1
    ActionMailer::Base.deliveries.clear
    cf = IssueCustomField.generate!(:name => 'aTestField', :field_format => 'bool')
    cf.save
    issue, = generate_data_with_attachment_001
    
    plugin_settings = plugin_settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'true',
      :enable_project_level_control => 'true',
      :field_name_to_enable_att => 'aTestField'
    })
    
    # enable project module of plugin
    pj = Project.find(1)
    pj.enable_module!(:issue_mail_with_attachments_plugin)
    pj.save
    
    issue.custom_field_values = { cf.id => 1 }
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_attach_all
    end
  end
  
  def test__att_enabled_false__att_all_false__prj_lve_true__prj_enabled__cf_enabled__cv_1
    ActionMailer::Base.deliveries.clear
    cf = IssueCustomField.generate!(:name => 'aTestField', :field_format => 'bool')
    cf.save
    issue, = generate_data_with_attachment_001
    
    plugin_settings = plugin_settings_init({
      :enable_mail_attachments => 'false',
      :attach_all_to_notification => 'false',
      :enable_project_level_control => 'true',
      :field_name_to_enable_att => 'aTestField'
    })
    
    # enable project module of plugin
    pj = Project.find(1)
    pj.enable_module!(:issue_mail_with_attachments_plugin)
    pj.save
    
    issue.custom_field_values = { cf.id => 1 }
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_no_attachments
    end
  end
  

  

end
