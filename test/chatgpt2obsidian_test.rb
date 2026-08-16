require "minitest/autorun"

load File.expand_path("../chatgpt2obsidian", __dir__)

class ChatGPT2ObsidianTest < Minitest::Test
  def setup
    @converter = ChatGPT2Obsidian.new
  end

  def test_replace_codes_resolves_citation_markers_without_offsets
    metadata = {
      content_references: [
        {
          type: "grouped_webpages",
          items: [
            {
              title: "Example",
              url: "https://example.com/source",
              refs: [
                { turn_index: 0, ref_type: "search", ref_index: 1 },
                { turn_index: 0, ref_type: "search", ref_index: 3 },
                { turn_index: 0, ref_type: "search", ref_index: 5 },
              ],
            },
          ],
        },
      ],
    }

    result = @converter.send(
      :replace_codes,
      ["Claim. \u{E200}cite\u{E202}turn0search1\u{E202}turn0search3\u{E201}"],
      metadata,
      assets: {}
    )

    assert_equal ["Claim. \\[[Example](https://example.com/source)\\]"], result
  end

  def test_replace_codes_removes_unresolvable_citation_markers
    result = @converter.send(
      :replace_codes,
      [
        "Claim. \u{E200}cite\u{E202}turn0search1\u{E201}",
        "Claim without payload. \u{E200}cite\u{E201}",
      ],
      {},
      assets: {}
    )

    assert_equal ["Claim.", "Claim without payload."], result
  end

  def test_replace_codes_warns_about_and_removes_unknown_reference_markers
    @converter.instance_variable_set(:@current_conversation_title, "Conversation")

    result = nil
    assert_output(nil, /Unsupported content reference marker `embed`: "Conversation"/) do
      result = @converter.send(
        :replace_codes,
        ["Text. \u{E200}embed\u{E202}payload\u{E201}"],
        {},
        assets: {}
      )
    end

    assert_equal ["Text."], result
  end

  def test_replace_codes_warns_about_and_removes_simple_reference_markers
    @converter.instance_variable_set(:@current_conversation_title, "Conversation")
    result = nil

    assert_output(nil, /Unsupported content reference marker `map`: "Conversation"/) do
      result = @converter.send(
        :replace_codes,
        ["Text. \u{E200}map\u{E201}"],
        {},
        assets: {}
      )
    end

    assert_equal ["Text."], result
  end

  def test_replace_codes_warns_about_and_removes_unterminated_reference_markers
    @converter.instance_variable_set(:@current_conversation_title, "Conversation")
    result = nil

    assert_output(nil, /Unterminated content reference marker `entity`: "Conversation"/) do
      result = @converter.send(
        :replace_codes,
        ["Text. \u{E200}entity\u{E202}[\"software\", \"RCS\", \""],
        {},
        assets: {}
      )
    end

    assert_equal ["Text."], result
  end
end
