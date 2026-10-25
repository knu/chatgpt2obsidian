require "minitest/autorun"

load File.expand_path("../chatgpt2obsidian", __dir__)

class ChatGPT2ObsidianTest < Minitest::Test
  def setup
    @converter = ChatGPT2Obsidian.new
  end

  def test_replace_codes_resolves_citation_markers_without_offsets
    metadata = {
      content_references: [
        { type: "hidden", alt: nil },
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
    result = nil
    assert_output(nil, /Unresolved web citation/) do
      result = @converter.send(
        :replace_codes,
        [
          "Claim. \u{E200}cite\u{E202}turn0search1\u{E201}",
          "Claim without payload. \u{E200}cite\u{E201}",
        ],
        {},
        assets: {}
      )
    end

    assert_equal ["Claim.", "Claim without payload."], result
  end

  def test_citations_use_their_own_metadata_when_reference_ids_conflict
    metadata = { content_references: %w[first second].map { |name|
      { type: "grouped_webpages", items: [{
        title: name, url: "https://example.com/#{name}",
        refs: [{ turn_index: 0, ref_type: "search", ref_index: 0 }],
      }] }
    } }

    assert_equal %w[first second].map { "\\[[#{it}](https://example.com/#{it})\\]" }, @converter.send(
      :replace_codes, ["citeturn0search0", "citeturn0search0"], metadata, assets: {}
    )
  end

  def test_citations_use_saved_links_when_marker_ids_do_not_match
    metadata = { content_references: [
      { type: "grouped_webpages", items: [{ title: "Source", url: "https://example.com" }] },
      { type: "grouped_webpages", alt: "[Saved](https://example.com/saved)" },
    ] }

    assert_equal ["\\[[Source](https://example.com)\\] [Saved](https://example.com/saved)"], @converter.send(
      :replace_codes, ["citeturn999search0 citeturn999search1"], metadata, assets: {}
    )
  end

  def test_replace_codes_preserves_offsetless_references_in_order_across_parts
    metadata = {
      content_references: [
        { type: "entity", alt: "人物A" },
        { type: "hidden", alt: nil },
        { type: "url", alt: "[Example](https://example.com)" },
        { type: "alt_text", alt: "人物B" },
        { type: "image_group", alt: "![Image](https://example.com/image.png)" },
      ],
    }

    result = @converter.send(
      :replace_codes,
      [
        "区長はentity[\"person\",\"人物A\",0]です。entity_metadata[] urlExampleturn0search0",
        "後任はentity[\"person\",\"人物B\",0]です。\nimage_group{}",
      ],
      metadata,
      assets: {}
    )

    assert_equal [
      "区長は人物Aです。 [Example](https://example.com)",
      "後任は人物Bです。\n![Image](https://example.com/image.png)",
    ], result
  end

  def test_replace_codes_preserves_offsetless_file_citations
    @converter.instance_variable_set(:@attachments_subdirectory, "attachments")
    metadata = { content_references: [{ type: "file", name: "Report.pdf", id: "file-report" }] }

    assert_equal ["Source. 📎 **Report.pdf**"], @converter.send(
      :replace_codes, ["Source. fileciteturn0file0"], metadata, assets: {}
    )
  end

  def test_replace_codes_keeps_widget_data_and_suppresses_hidden_markers
    metadata = { content_references: [
      { type: "client_defined_widget", alt: nil },
      { type: "hidden", alt: nil },
    ] }
    result = @converter.send(
      :replace_codes,
      ["genui{\"chart\":{\"data\":[1,2]}}\nText. memcite"],
      metadata, assets: {}
    ).first

    assert_includes result, "```json\n"
    assert_includes result, '"chart"'
    refute_match(/[\u{E200}-\u{E202}]/, result)
    assert_match(/Text\.\z/, result)
  end

  def test_replace_codes_retains_legacy_offset_references
    metadata = { content_references: [
      { type: "entity", start_idx: 0, end_idx: 6, alt: "First" },
      { type: "entity", alt: "Second" },
    ] }

    assert_equal ["First Second"], @converter.send(
      :replace_codes, ["legacy entity[]"], metadata, assets: {}
    )
  end

  def test_replace_codes_matches_alternate_types_and_hidden_references
    metadata = { content_references: [
      { type: "alt_text", alt: "[Docs](https://example.com)" },
      { type: "hidden", alt: nil },
      { type: "hidden", alt: nil },
      { type: "product_entity", alt: "Stand" },
    ] }

    assert_output(nil, /Unresolved web citation/) do
      assert_equal ["[Docs](https://example.com) Stand"], @converter.send(
        :replace_codes,
        ["urlDocshttps://example.com citeturn0search0 fileciteturn0file0 entity[]"],
        metadata, assets: {}
      )
    end
  end

  def test_replace_codes_renders_images_without_alternative_text
    metadata = { content_references: [
      { type: "image_group", alt: nil, images: [
        { image_result: {
          content_url: "https://example.com/full.png",
          thumbnail_url: "https://example.com/thumb.png",
          title: "Image", thumbnail_size: { width: 100, height: 80 },
        } },
      ] },
    ] }
    result = @converter.send(:replace_codes, ["image_group{}"], metadata, assets: {}).first

    assert_includes result, "https://example.com/thumb.png"
    assert_includes result, "https://example.com/full.png"
  end

  def test_replace_codes_keeps_maps_from_separate_messages
    @converter.instance_variable_set(:@current_target, "Conversation.md")
    @converter.instance_variable_set(:@current_conversation_title, "Conversation")
    @converter.instance_variable_set(:@current_map_exports, {})

    %w[First Second].each do |name|
      metadata = { content_references: [
        { type: "map", entities: [{ name:, latitude: 35.0, longitude: 139.0 }] },
      ] }
      result = @converter.send(:replace_codes, ["map"], metadata, assets: {}).first
      assert_includes result, "```base"
    end

    exports = @converter.instance_variable_get(:@current_map_exports)
    assert_equal %w[First Second], exports.values.map { it[:places].first[:name] }
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
