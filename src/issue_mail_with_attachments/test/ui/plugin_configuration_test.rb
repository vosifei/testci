require File.expand_path('../../../../../test/ui/base', __FILE__)

# Page object of list of plugins page
class ListOfPluginsPage < SitePrism::Page
  set_url '/admin/plugins'
  element :configure_plugin_issue_mail_att, :xpath, "//a[contains(@href,'/settings/plugin/issue_mail_with_attachment')]"
end

# Page object of issue mail with attachment plugin setting page
class IssueMailAttPluginSettingPage < SitePrism::Page
  DEFAULT_edit_mail_subject = '[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}'
  DEFAULT_edit_mail_subject_wo_status = '[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] #{issue.subject}'
  DEFAULT_edit_mail_subject_4_attachment = '[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] |att| '
  
  set_url '/settings/plugin/issue_mail_with_attachments'
  element :chk_att_enabled, "input[name='settings[enable_mail_attachments]']"
  element :chk_attach_all, "input[name='settings[attach_all_to_notification]']"
  element :chk_prj_ctl_enabled, "input[name='settings[enable_project_level_control]']"
  element :edit_cf_name_for_issue, "input[name='settings[field_name_to_enable_att]']"
  
  element :edit_mail_subject, "input[name='settings[mail_subject]']"
  element :edit_mail_subject_wo_status, "input[name='settings[mail_subject_wo_status]']"
  element :edit_mail_subject_4_attachment, "input[name='settings[mail_subject_4_attachment]']"
  
  element :btn_apply, "input[name='commit']"
  
end

class Redmine::UiTest::IssuesTest < Redmine::UiTest::Base
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles,
           :trackers, :projects_trackers, :enabled_modules, :issue_statuses, :issues,
           :enumerations, :custom_fields, :custom_values, :custom_fields_trackers,
           :watchers, :journals, :journal_details

  def open_plugin_setting_page
    Setting.clear_cache
    log_user('admin', 'admin')
    visit '/'
    
    plugin_list_page = ListOfPluginsPage.new
    plugin_list_page.load
    assert_equal plugin_list_page.url, plugin_list_page.current_path
    plugin_list_page.configure_plugin_issue_mail_att.click
  end
  
  def test_preserve_default_setting_values
    open_plugin_setting_page
    pp = IssueMailAttPluginSettingPage.new
    assert_equal pp.url, pp.current_path

    #chk default values
    assert_equal true, pp.chk_att_enabled.checked?
    assert_equal false, pp.chk_attach_all.checked?
    assert_equal false, pp.chk_prj_ctl_enabled.checked?
    assert_equal "", pp.edit_cf_name_for_issue.value
    assert_equal IssueMailAttPluginSettingPage::DEFAULT_edit_mail_subject, pp.edit_mail_subject.value
    assert_equal IssueMailAttPluginSettingPage::DEFAULT_edit_mail_subject_wo_status, pp.edit_mail_subject_wo_status.value
    assert_equal IssueMailAttPluginSettingPage::DEFAULT_edit_mail_subject_4_attachment, pp.edit_mail_subject_4_attachment.value
    
    begin
      pp.btn_apply.click
      #preserve same values after applying
      assert_equal true, pp.chk_att_enabled.checked?
      assert_equal false, pp.chk_attach_all.checked?
      assert_equal false, pp.chk_prj_ctl_enabled.checked?
      assert_equal "", pp.edit_cf_name_for_issue.value
      assert_equal IssueMailAttPluginSettingPage::DEFAULT_edit_mail_subject, pp.edit_mail_subject.value
      assert_equal IssueMailAttPluginSettingPage::DEFAULT_edit_mail_subject_wo_status, pp.edit_mail_subject_wo_status.value
      assert_equal IssueMailAttPluginSettingPage::DEFAULT_edit_mail_subject_4_attachment, pp.edit_mail_subject_4_attachment.value
    ensure
      Setting.find_by(name: :plugin_issue_mail_with_attachments).destroy
      Setting.clear_cache
    end
  end
  
  def test_preserve_new_setting_values
    open_plugin_setting_page
    pp = IssueMailAttPluginSettingPage.new
    assert_equal pp.url, pp.current_path
    #chk default values
    assert_equal true, pp.chk_att_enabled.checked?
    assert_equal false, pp.chk_attach_all.checked?
    assert_equal false, pp.chk_prj_ctl_enabled.checked?
    assert_equal "", pp.edit_cf_name_for_issue.value
    assert_equal IssueMailAttPluginSettingPage::DEFAULT_edit_mail_subject, pp.edit_mail_subject.value
    assert_equal IssueMailAttPluginSettingPage::DEFAULT_edit_mail_subject_wo_status, pp.edit_mail_subject_wo_status.value
    assert_equal IssueMailAttPluginSettingPage::DEFAULT_edit_mail_subject_4_attachment, pp.edit_mail_subject_4_attachment.value

    pp.chk_att_enabled.set(false)
    pp.chk_attach_all.set(true)
    pp.chk_prj_ctl_enabled.set(true)
    pp.edit_cf_name_for_issue.set("aaaa")
    pp.edit_mail_subject.set("bbbb")
    pp.edit_mail_subject_wo_status.set("cccc")
    pp.edit_mail_subject_4_attachment.set("dddd")

    begin
      pp.btn_apply.click
      #preserve changed values after applying
      assert_equal false, pp.chk_att_enabled.checked?
      assert_equal true, pp.chk_attach_all.checked?
      assert_equal true, pp.chk_prj_ctl_enabled.checked?
      assert_equal "aaaa", pp.edit_cf_name_for_issue.value
      assert_equal "bbbb", pp.edit_mail_subject.value
      assert_equal "cccc", pp.edit_mail_subject_wo_status.value
      assert_equal "dddd", pp.edit_mail_subject_4_attachment.value
      
#      Setting.clear_cache
#      assert_equal nil, Setting.plugin_issue_mail_with_attachments[:enable_mail_attachments]
#      assert_equal 'true', Setting.plugin_issue_mail_with_attachments[:attach_all_to_notification]
#      assert_equal 'true', Setting.plugin_issue_mail_with_attachments[:enable_project_level_control]
#      assert_equal "aaaa", Setting.plugin_issue_mail_with_attachments[:field_name_to_enable_att]
#      assert_equal "bbbb", Setting.plugin_issue_mail_with_attachments[:mail_subject]
#      assert_equal "cccc", Setting.plugin_issue_mail_with_attachments[:mail_subject_wo_status]
#      assert_equal "dddd", Setting.plugin_issue_mail_with_attachments[:mail_subject_4_attachment]
      
    ensure
      Setting.find_by(name: :plugin_issue_mail_with_attachments).destroy
      Setting.clear_cache
    end
  end
end