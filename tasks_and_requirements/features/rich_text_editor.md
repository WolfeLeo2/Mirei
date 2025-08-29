# ✍️ Feature: Rich Text Editor for Journaling

**Status:** 🟢 Ready  
**Priority:** P2 - Important  
**Effort:** 1 week  
**Impact:** High

## 📋 Overview

Replace the basic text input with a comprehensive rich text editor that supports formatting, markdown, media embedding, and advanced journaling features.

## 🎯 User Stories

### Primary Users: Journal Writers

- **As a user**, I want to format my journal entries with bold, italic, and headings so that I can emphasize important thoughts
- **As a user**, I want to add bullet points and numbered lists so that I can organize my thoughts clearly
- **As a user**, I want to embed images inline with text so that I can create rich, visual journal entries
- **As a user**, I want markdown support so that I can quickly format text using familiar syntax

### Secondary Users: Power Users

- **As a power user**, I want to create custom templates so that I can standardize my journaling approach
- **As a power user**, I want to use hashtags and @mentions so that I can tag and categorize my entries
- **As a power user**, I want to insert tables and code blocks so that I can document structured information

## 🔧 Technical Requirements

### Core Functionality

```dart
class RichTextEditor extends StatefulWidget {
  final String? initialContent;
  final Function(String content) onContentChanged;
  final bool enableMarkdown;
  final bool enableMediaEmbedding;
  final List<EditorTool> enabledTools;

  const RichTextEditor({
    Key? key,
    this.initialContent,
    required this.onContentChanged,
    this.enableMarkdown = true,
    this.enableMediaEmbedding = true,
    this.enabledTools = const [
      EditorTool.bold,
      EditorTool.italic,
      EditorTool.heading,
      EditorTool.bulletList,
      EditorTool.numberedList,
      EditorTool.link,
      EditorTool.image,
    ],
  }) : super(key: key);
}
```

### Supported Formatting

- **Text Styling**: Bold, Italic, Underline, Strikethrough
- **Headings**: H1, H2, H3 for organizing content
- **Lists**: Bullet points, numbered lists, checklists
- **Links**: Clickable URLs and email addresses
- **Media**: Inline images, audio recordings
- **Code**: Inline code and code blocks
- **Quotes**: Block quotes for highlighting text
- **Tables**: Simple table creation and editing

### Markdown Support

````markdown
# Heading 1

## Heading 2

### Heading 3

**Bold text** and _italic text_
~~Strikethrough text~~

- Bullet point 1
- Bullet point 2

1. Numbered item 1
2. Numbered item 2

[Link text](https://example.com)
![Image alt text](image_url)

> Block quote text

`Inline code`

```code
Code block
```
````

````

## 🎨 User Interface Design

### Toolbar Design
```dart
class EditorToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Text formatting tools
          ToolbarButton(icon: Icons.format_bold, onPressed: _toggleBold),
          ToolbarButton(icon: Icons.format_italic, onPressed: _toggleItalic),

          // Structure tools
          ToolbarButton(icon: Icons.format_list_bulleted, onPressed: _addBulletList),
          ToolbarButton(icon: Icons.format_list_numbered, onPressed: _addNumberedList),

          // Media tools
          ToolbarButton(icon: Icons.image, onPressed: _insertImage),
          ToolbarButton(icon: Icons.link, onPressed: _insertLink),

          // Advanced tools
          ToolbarButton(icon: Icons.format_quote, onPressed: _insertQuote),
          ToolbarButton(icon: Icons.table_chart, onPressed: _insertTable),
        ],
      ),
    );
  }
}
````

### Editor Layout

- **Floating Toolbar**: Appears when text is selected
- **Fixed Toolbar**: Always visible at bottom for quick access
- **Context Menu**: Right-click options for power users
- **Markdown Preview**: Toggle between edit and preview modes

## 📦 Implementation Plan

### Week 1: Days 1-2 - Core Editor

- [ ] Set up flutter_quill package
- [ ] Implement basic text editing
- [ ] Add bold, italic, underline formatting
- [ ] Create custom toolbar

### Week 1: Days 3-4 - Advanced Formatting

- [ ] Add heading support (H1, H2, H3)
- [ ] Implement bullet and numbered lists
- [ ] Add block quote functionality
- [ ] Create link insertion dialog

### Week 1: Days 5-7 - Media & Polish

- [ ] Integrate image embedding
- [ ] Add markdown preview mode
- [ ] Implement undo/redo functionality
- [ ] Polish UI and animations

## 🔌 Dependencies

### Required Packages

```yaml
dependencies:
  flutter_quill: ^10.8.6 # Rich text editor
  flutter_quill_extensions: ^10.8.6 # Additional features
  markdown: ^7.2.2 # Markdown parsing
  html: ^0.15.6 # HTML rendering
  image_picker: ^1.2.0 # Image selection (already included)
  url_launcher: ^6.3.0 # Link handling (already included)
```

### Integration Points

- **Image Service**: Integrate with existing image handling
- **File Storage**: Use existing file management system
- **Database**: Store formatted content in Realm
- **Sync Service**: Ensure rich content syncs properly

## 📊 Expected Benefits

### User Experience Benefits

- **80% richer content**: Users create more detailed, formatted entries
- **60% faster writing**: Toolbar shortcuts speed up formatting
- **90% better organization**: Headings and lists improve structure
- **100% visual appeal**: Rich formatting makes entries more engaging

### Engagement Benefits

- **40% longer sessions**: Users spend more time crafting entries
- **25% more frequent use**: Better tools encourage regular journaling
- **50% higher retention**: Rich content creation increases attachment
- **35% more sharing**: Well-formatted entries more likely to be shared

### Technical Benefits

- **Standardized formatting**: Consistent rich text across app
- **Future-proof content**: Structured data enables new features
- **Better search**: Formatted content improves search relevance
- **Export quality**: Rich text exports beautifully to PDF/HTML

## 🧪 Testing Strategy

### Unit Tests

```dart
void main() {
  group('RichTextEditor', () {
    testWidgets('applies bold formatting', (tester) async {
      // Test bold toggle functionality
    });

    testWidgets('creates bullet lists', (tester) async {
      // Test list creation
    });

    testWidgets('embeds images correctly', (tester) async {
      // Test image embedding
    });
  });
}
```

### Integration Tests

- [ ] Test with existing journal entry creation flow
- [ ] Verify database storage of rich content
- [ ] Test sync with cloud storage
- [ ] Validate export functionality

### User Acceptance Tests

- [ ] Users can format text without confusion
- [ ] Toolbar is intuitive and responsive
- [ ] Rich content displays correctly in entry list
- [ ] Performance remains smooth with large documents

## 🚨 Potential Challenges & Solutions

### Challenge: Performance with Large Documents

**Solution:**

- Implement virtual scrolling for long documents
- Lazy load images and media
- Optimize re-rendering with proper widget keys

### Challenge: Markdown Compatibility

**Solution:**

- Use standard markdown syntax
- Provide clear documentation
- Add markdown cheat sheet in help

### Challenge: Mobile Keyboard Interactions

**Solution:**

- Custom toolbar above keyboard
- Gesture-based shortcuts
- Context-sensitive tool visibility

### Challenge: Content Migration

**Solution:**

```dart
class ContentMigrationService {
  Future<void> migrateExistingEntries() async {
    final entries = await _dbHelper.getAllJournalEntries();
    for (final entry in entries) {
      if (!entry.hasRichContent) {
        entry.content = _convertPlainTextToRich(entry.content);
        entry.hasRichContent = true;
        await _dbHelper.updateJournalEntry(entry);
      }
    }
  }
}
```

## 📈 Success Metrics

### Adoption Metrics

- **Feature Usage**: 80% of new entries use rich formatting
- **Tool Popularity**: Track most-used formatting tools
- **Content Length**: 50% increase in average entry length
- **User Satisfaction**: 4.5+ rating for editor experience

### Performance Metrics

- **Load Time**: Editor opens in < 1 second
- **Typing Latency**: < 16ms response time
- **Memory Usage**: < 50MB for large documents
- **Crash Rate**: < 0.01% related to editor

### Business Metrics

- **Session Duration**: +60% increase in writing sessions
- **User Retention**: +30% improvement in weekly retention
- **App Store Rating**: Positive mentions of editor in reviews
- **Support Tickets**: < 5% related to editor issues

## 🎉 Success Criteria

### Technical Success

- [ ] All formatting tools work reliably
- [ ] Rich content saves and loads correctly
- [ ] Editor performs smoothly on all devices
- [ ] Markdown import/export works perfectly

### User Success

- [ ] Users create visually appealing entries
- [ ] Formatting tools are discovered and used
- [ ] Writing experience feels natural and intuitive
- [ ] Rich content enhances journal review experience

### Business Success

- [ ] Increased user engagement and retention
- [ ] Positive user feedback and reviews
- [ ] Reduced support burden
- [ ] Foundation for advanced features

---

## 📝 Notes

- **High Impact Feature**: Transforms basic journaling into rich content creation
- **Foundation for Future**: Enables templates, sharing, and advanced features
- **Competitive Advantage**: Sets Mirei apart from basic journaling apps
- **User Delight**: Significantly improves writing experience

---

**Estimated Time:** 1 week  
**Difficulty:** Medium  
**Dependencies:** Image service, database updates  
**Enables:** Template system, sharing features, export improvements
