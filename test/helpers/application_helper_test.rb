# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  setup do
    @user = create(:user)
    sign_in @user
  end

  def current_user; @user; end

  test "markdown" do
    raw = "Hello **world**, this is a __test__."
    html = "<p>Hello <strong>world</strong>, this is a <strong>test</strong>.</p>"
    assert_equal html, markdown(raw)
  end

  test "markdown with :public" do
    stub_method = Proc.new do |body, opts|
      opts[:public] ? "Render public" : body
    end

    BlueDoc::HTML.stub(:render, stub_method) do
      assert_equal "Render public", markdown("Hello world", public: true)
      assert_equal "Hello world", markdown("Hello world")
    end
  end

  test "sanitize markdown" do
    assert_sanitize_markdown " foo", "<script>alert()</script> foo"
    assert_sanitize_markdown " foo", "<style>.body {}</style> foo"
  end

  test "icon_tag" do
    html = icon_tag("times", label: "Close", class: "search")
    assert_equal %(<i class="fas fa-times search"></i> <span>Close</span>), html
  end

  test "timeago" do
    t = Time.now

    html = timeago(t)
    assert_equal %(<span class="timeago" datetime="#{t.iso8601}" title="#{t.iso8601}">#{l t, format: :short}</span>), html

    t = 1.month.ago
    html = timeago(t)
    assert_equal %(<span class="time" title="#{t.iso8601}">#{l t, format: :short}</span>), html

    assert_equal "", timeago(nil)
  end

  test "action_button_tag with Repository" do
    repo = create(:repository)
    assert_equal "", action_button_tag(nil, :watch)
    @user.unwatch_repository(repo)
    html = action_button_tag(repo, :watch, icon: "eye", with_count: true)
    assert_action_button html, repo, :watch, text: "Watch", label: "Watch", undo_label: "Unwatch", icon: "eye", method: :post, with_count: true

    @user.watch_repository(repo)
    html = action_button_tag(repo, :watch, icon: "eye", with_count: true)
    assert_action_button html, repo, :watch, text: "Unwatch", label: "Watch", undo_label: "Unwatch", icon: "eye", method: :delete, with_count: true

    repo1 = create(:repository)
    html = action_button_tag(repo1, :star, label: "Do Star", undo_label: "Undo Star", icon: "star", with_count: true)
    assert_action_button html, repo1, :star, text: "Do Star", label: "Do Star", undo_label: "Undo Star", icon: "star", method: :post, with_count: true
  end

  test "action_button_tag with Repository and without_count" do
    repo = create(:repository)
    html = action_button_tag(repo, :watch, icon: "eye", undo: true)
    assert_action_button html, repo, :watch, text: "Unwatch", label: "Watch", undo_label: "Unwatch", icon: "eye", method: :delete, with_count: false

    html = action_button_tag(repo, :star, undo: true)
    assert_action_button html, repo, :star, text: "Unstar", label: "Star", undo_label: "Unstar", icon: "star", method: :delete, with_count: false
  end

  test "action_button_tag with Doc" do
    doc = create(:doc)
    assert_equal "", action_button_tag(nil, :watch)
    html = action_button_tag(doc, :star, icon: "star", class: "btn")
    assert_action_button html, doc, :star, text: "Star", label: "Star", undo_label: "Unstar", icon: "star", method: :post, with_count: false, class: "btn"

    @user.star_doc(doc)
    html = action_button_tag(doc, :star, icon: "star")
    assert_action_button html, doc, :star, text: "Unstar", label: "Star", undo_label: "Unstar", icon: "star", method: :delete, with_count: false
  end

  test "form_group" do
    user = build(:user, slug: "")
    user.valid?
    html = form_for(user) do |f|
      form_group(f, :slug) do
        content_tag(:div, "input field")
      end
    end

    expected = <<~HTML
    <form class="new_user" id="new_user" action="/" accept-charset="UTF-8" method="post">
      <div class="form-group has-error">
        <div class="field_with_errors">
          <label class="control-label" for="user_slug">Username</label>
        </div>
        <div>input field</div>
        <div class="form-error">Username is invalid</div>
      </div>
    </form>
    HTML

    assert_html_equal expected, html

    # without label
    expected = <<~HTML
    <form class="new_user" id="new_user" action="/" accept-charset="UTF-8" method="post">
      <div class="foo bar has-error">
        <div>input field</div>
        <div class="form-error">Username is invalid</div>
      </div>
    </form>
    HTML
    html = form_for(user) do |f|
      form_group(f, :slug, label: false, class: "foo bar") do
        content_tag(:div, "input field")
      end
    end
    assert_html_equal expected, html
  end

  private

    def assert_action_button(html, target, action_type, opts = {})
      text = opts[:text]
      label = opts[:label]
      undo_label = opts[:undo_label]
      icon = opts[:icon]
      method = opts[:method]
      with_count = opts[:with_count]

      action_count = "#{action_type.to_s.pluralize}_count"

      icon_html = raw(icon_tag(icon, label: text))

      count_html = ""
      if with_count
        count_html = raw(%(<i class="social-count" >#{target.send(action_count)}</i>))
      end
      btn_class = opts[:class] || "btn btn-sm"
      btn_class += " btn-with-count" if with_count

      url = target.to_path("/action?action_type=#{action_type}")

      expected = <<~TEXT
        <span class="#{target.class.name.underscore}-#{target.id}-#{action_type}-button action-button">
        <a data-method="#{method}" data-label="#{label}" data-undo-label="#{undo_label}" data-remote="true" data-disable="true" class="#{btn_class}" href="#{url}">
        #{icon_html}
        #{count_html}
        </a>
        </span>
       TEXT
      assert_equal expected.gsub(/\n/, ""), html
    end

    def assert_sanitize_markdown(excepted, raw)
      assert_equal excepted, markdown(raw)
    end
end
