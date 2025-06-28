# ChatGPT to Obsidian Converter

This is a Ruby script that converts ChatGPT export data into Obsidian-compatible markdown files with proper frontmatter metadata and formatting.

## Features

- **Obsidian integration**: Generates files with YAML frontmatter and Obsidian syntax like [Callouts](https://help.obsidian.md/callouts)
- **Attachment handling**: Copies and links image attachments with proper file organization
- **Conversation structure**: Preserves the hierarchical structure of ChatGPT conversations
- **Duplicate prevention**: Handles filename conflicts and tracks existing files
- **Rich content support**: Processes web search results, thoughts, code blocks, app-pairing contexts, and multimedia content

## Requirements

- Ruby 3.4 or later (optional if using Docker)
- Alternatively, Docker for containerized execution

## Installation

Clone or download this repository:

```sh
git clone https://github.com/knu/chatgpt2obsidian.git
cd chatgpt2obsidian
```

## Usage

### Direct execution

```sh
./chatgpt2obsidian <input_path> <output_directory>
```

### Command-line Parameters

- `<input_path>`: ChatGPT export zip file or its extracted directory
- `<output_directory>`: Directory where converted markdown files will be saved

### Options

- `-a, --attachments-subdirectory NAME`: Specify custom attachments subdirectory name (default: "attachments")
- `-c, --created-key KEY`: Specify the frontmatter key for created timestamp (default: "created")
- `-u, --updated-key KEY`: Specify the frontmatter key for updated timestamp (default: "updated")
- `-h, --help`: Show help message

### Docker

```sh
# Basic usage with ZIP file
docker run --rm -v /path/to/chatgpt-export:/input -v /path/to/vault/subdirectory:/output akinori/chatgpt2obsidian /input/chatgpt-export.zip /output

# Basic usage with extracted directory
docker run --rm -v /path/to/chatgpt-export:/input -v /path/to/vault/subdirectory:/output akinori/chatgpt2obsidian /input /output

# With custom attachments subdirectory
docker run --rm -v /path/to/chatgpt-export:/input -v /path/to/vault/subdirectory:/output akinori/chatgpt2obsidian --attachments-subdirectory images /input/chatgpt-export.zip /output
```

### Examples

```sh
# Basic usage with ZIP file
./chatgpt2obsidian chatgpt-export.zip /path/to/vault/subdirectory

# Basic usage with extracted directory
./chatgpt2obsidian /path/to/extracted/chatgpt-export /path/to/vault/subdirectory

# With custom attachments subdirectory
./chatgpt2obsidian --attachments-subdirectory images chatgpt-export.zip /path/to/vault/subdirectory
```

## ChatGPT Export Process

1. Go to ChatGPT Settings → Data Controls → Export Data
2. Download your data when ready
3. Use the path to the downloaded ZIP file or extract it and use the path to the extracted directory as the first argument

```
/path/to/chatgpt-export
├── chat.html
├── conversations.json
├── file-id-1-image-1.png
├── file-id-2-image-2.jpg
├── ...
├── message_feedback.json
├── shared_conversations.json
└── user.json
```

## Output Structure

The script generates one markdown file per conversation from the ChatGPT export data, along with any attachments (images, files) referenced in the conversations.
The output is structured to be compatible with Obsidian's note-taking system, allowing for easy organization and retrieval of conversations.
Each markdown file is named after the conversation title, sanitized for filesystem compatibility, and includes all relevant metadata.

```
/path/to/vault/subdirectory/
├── conversation_title_1.md
├── conversation_title_2.md
├── attachments/
│   ├── file-id-1-image-1.png
│   └── file-id-2-image-2.jpg
└── ...
```

### Markdown Format

Each conversation file includes:

- **YAML frontmatter** with metadata (title, dates, conversation ID, URL)
- **Proper formatting** for user and assistant messages
- **Obsidian callouts** for search results, thoughts, code blocks, app-pairing contexts, and multimedia content
- **Linked attachments** with automatic file copying

Example output:

```markdown
---
title: "How to learn Ruby programming"
created: "2024-01-15T10:30:00+09:00"
updated: "2024-01-15T11:45:00+09:00"
conversation_id: "abc123def456"
conversation_url: "https://chat.openai.com/c/abc123def456"
---

# User
How do I get started with Ruby programming?

# ChatGPT
Ruby is a great language to start with! Here are some steps...

> [!info]- Web Search: [ruby tutorial] [programming basics]
> #### [Ruby Programming Language Official Site](https://www.ruby-lang.org/)
> Ruby is a dynamic, open source programming language...
```

## Content Type Support

The script handles various ChatGPT content types:

- **Text messages**: Standard user and assistant conversations
- **Web search results**: Formatted as Obsidian info callouts
- **Thoughts**: Internal reasoning displayed in abstract callouts
- **Images**: Automatically copied and linked
- **Web pages**: Full page content with source links
- **Code execution**: Search queries and reasoning recaps

## File Naming

- Conversation titles are sanitized for filesystem compatibility
- Special characters are replaced with underscores
- Duplicate titles get numbered suffixes (`_1`, `_2`, etc.)
- Existing files are preserved and updated in place

## Limitations

- Only processes conversations from ChatGPT exports
- Requires Ruby runtime environment (or Docker)
- Some advanced ChatGPT features may not be fully represented
- Large conversation histories may take time to process

## License

Copyright (c) 2025 Akinori Musha.

Licensed under the 2-clause BSD license.  See `LICENSE` for details.

Visit [GitHub Repository](https://github.com/knu/chatgpt2obsidian) for the latest information.

Please feel free to submit issues, feature requests, or pull requests.
